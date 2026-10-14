#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROTOBUF_TAG="v2.8.0"
PROTOBUF_COMMIT="7b2464c9b8c1521f93852261e4123826e5b25e11"
CRYPTO_LOG="${1:-}"
IMAGE="${MOSQUITTO_IMAGE:-eclipse-mosquitto:2.1.2-alpine}"
RUN_ID="${GITHUB_RUN_ID:-local}"
RUN_ATTEMPT="${GITHUB_RUN_ATTEMPT:-0}"
CONTAINER_NAME="devmesh-crypto-envelope-${RUN_ID}-${RUN_ATTEMPT}"
TEMP_DIR="$(mktemp -d)"
BROKER_READY=false
cleanup() {
    if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then docker rm --force "$CONTAINER_NAME" >/dev/null; fi
    rm -rf "$TEMP_DIR"
}
fail() {
    printf 'FALHA: %s\n' "$*" >&2
    if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then docker logs "$CONTAINER_NAME" >&2 || true; fi
    exit 1
}
trap cleanup EXIT
[[ -n "$CRYPTO_LOG" && -f "$CRYPTO_LOG" ]] || fail "Informe o log de teste do firmware."
for command_name in docker git protoc python3 cmp grep; do
    command -v "$command_name" >/dev/null 2>&1 || fail "Dependência ausente: $command_name."
done
CIPHERTEXT="$(grep -Eo 'DEVMESH_CHANNEL_CTR_5_HEX=[0-9a-f]+' "$CRYPTO_LOG" | tail -n 1 | cut -d= -f2 || true)"
[[ "$CIPHERTEXT" =~ ^([0-9a-f]{2})+$ ]] || fail "Ciphertext AES-CTR do caso 5 ausente ou inválido."
git clone --quiet --depth 1 --branch "$PROTOBUF_TAG" https://github.com/meshtastic/protobufs.git "$TEMP_DIR/protobufs"
ACTUAL_COMMIT="$(git -C "$TEMP_DIR/protobufs" rev-parse HEAD)"
[[ "$ACTUAL_COMMIT" == "$PROTOBUF_COMMIT" ]] || fail "O esquema Protobuf não corresponde ao commit fixado."
python3 - "$CIPHERTEXT" "$TEMP_DIR/envelope.txt" <<'PY'
from pathlib import Path
import sys
ciphertext = bytes.fromhex(sys.argv[1])
escaped_ciphertext = "".join(f"\\x{byte:02x}" for byte in ciphertext)
message = f'''packet {{
  from: 305419896
  to: 4294967295
  channel: 0
  encrypted: "{escaped_ciphertext}"
  id: 2271560481
  hop_limit: 3
  hop_start: 3
}}
channel_id: "LongFast"
gateway_id: "!a1b2c3d4"
'''
Path(sys.argv[2]).write_text(message, encoding="utf-8")
PY
(
    cd "$TEMP_DIR/protobufs"
    protoc -I . --encode=meshtastic.ServiceEnvelope meshtastic/mqtt.proto < "$TEMP_DIR/envelope.txt" > "$TEMP_DIR/service-envelope.bin"
)
[[ -s "$TEMP_DIR/service-envelope.bin" ]] || fail "O ServiceEnvelope codificado está vazio."
(
    cd "$TEMP_DIR/protobufs"
    protoc -I . --decode=meshtastic.ServiceEnvelope meshtastic/mqtt.proto < "$TEMP_DIR/service-envelope.bin" > "$TEMP_DIR/decoded.txt"
)
grep -Fq 'channel_id: "LongFast"' "$TEMP_DIR/decoded.txt" || fail "O envelope decodificado perdeu o channel_id."
grep -Fq 'gateway_id: "!a1b2c3d4"' "$TEMP_DIR/decoded.txt" || fail "O envelope decodificado perdeu o gateway_id."
grep -Fq 'encrypted:' "$TEMP_DIR/decoded.txt" || fail "O envelope decodificado perdeu o campo encrypted."
(
    cd "$TEMP_DIR/protobufs"
    protoc -I . --encode=meshtastic.ServiceEnvelope meshtastic/mqtt.proto < "$TEMP_DIR/decoded.txt" > "$TEMP_DIR/reencoded-envelope.bin"
)
cmp --silent "$TEMP_DIR/service-envelope.bin" "$TEMP_DIR/reencoded-envelope.bin" || fail "O ciclo Protobuf decode/encode alterou os bytes do envelope."
TOPIC="msh/US/2/e/LongFast/!a1b2c3d4"
TOPIC_FILTER="msh/US/2/e/LongFast/#"
docker run --detach --name "$CONTAINER_NAME" --volume "$ROOT_DIR/tests/mosquitto/mosquitto.conf:/mosquitto/config/mosquitto.conf:ro" "$IMAGE" >/dev/null
for attempt in $(seq 1 20); do
    if docker exec "$CONTAINER_NAME" mosquitto_pub -h 127.0.0.1 -t devmesh/test/healthcheck -m ready >/dev/null 2>&1; then BROKER_READY=true; break; fi
    sleep 0.5
done
[[ "$BROKER_READY" == true ]] || fail "Mosquitto não ficou pronto dentro do prazo."
# Retained delivery removes the publish/subscribe startup race in this test only.
docker exec -i "$CONTAINER_NAME" mosquitto_pub -r -h 127.0.0.1 -t "$TOPIC" -s < "$TEMP_DIR/service-envelope.bin" || fail "Falha ao publicar o ServiceEnvelope."
OUTPUT_B="$TEMP_DIR/node-b.bin"
OUTPUT_C="$TEMP_DIR/node-c.bin"
docker exec "$CONTAINER_NAME" mosquitto_sub -h 127.0.0.1 -t "$TOPIC_FILTER" -C 1 -N -W 8 > "$OUTPUT_B" 2> "$TEMP_DIR/node-b.err" &
PID_B="$!"
docker exec "$CONTAINER_NAME" mosquitto_sub -h 127.0.0.1 -t "$TOPIC_FILTER" -C 1 -N -W 8 > "$OUTPUT_C" 2> "$TEMP_DIR/node-c.err" &
PID_C="$!"
wait "$PID_B" || fail "O nó B não recebeu o envelope no prazo."
wait "$PID_C" || fail "O nó C não recebeu o envelope no prazo."
cmp --silent "$TEMP_DIR/service-envelope.bin" "$OUTPUT_B" || fail "Os bytes recebidos pelo nó B diferem do envelope publicado."
cmp --silent "$TEMP_DIR/service-envelope.bin" "$OUTPUT_C" || fail "Os bytes recebidos pelo nó C diferem do envelope publicado."
printf 'OK: ciphertext AES-CTR emitido pelo CryptoEngine inserido no ServiceEnvelope oficial.\n'
printf 'OK: Protobuf codificado/decodificado com o esquema fixado em %s.\n' "$PROTOBUF_TAG"
printf 'OK: os nós B e C receberam exatamente os bytes do envelope publicado via MQTT.\n'
printf 'LIMITE: IDs, chave, payload e metadados são sintéticos; não valida rádio, ACL ou segurança integral.\n'
