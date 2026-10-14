#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${MOSQUITTO_IMAGE:-eclipse-mosquitto:2.1.2-alpine}"
RUN_ID="${GITHUB_RUN_ID:-local}"
RUN_ATTEMPT="${GITHUB_RUN_ATTEMPT:-0}"
CONTAINER_NAME="devmesh-crypto-model-${RUN_ID}-${RUN_ATTEMPT}"
TEMP_DIR="$(mktemp -d)"
BROKER_READY=false
TOPIC="msh/US/2/e/LongFast/!a1b2c3d4"
TOPIC_FILTER="msh/US/2/e/LongFast/#"
KEY_B="00112233445566778899aabbccddeeff"
KEY_C="00112233445566778899aabbccddeefe"
PACKET_ID=305419896
FROM_NODE=591751049

cleanup() {
    if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
        docker rm --force "$CONTAINER_NAME" >/dev/null
    fi
    rm -rf "$TEMP_DIR"
}

fail() {
    printf 'FALHA: %s\n' "$*" >&2
    if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
        docker logs "$CONTAINER_NAME" >&2 || true
    fi
    exit 1
}

check_ctr_reference_vector() {
    local algorithm="$1"
    local key="$2"
    local iv="$3"
    local expected="$4"
    local output="$TEMP_DIR/reference-ciphertext.bin"
    local actual

    printf 'Single block msg' > "$TEMP_DIR/reference-plaintext.bin"
    openssl enc "$algorithm" -K "$key" -iv "$iv" \
        -in "$TEMP_DIR/reference-plaintext.bin" -out "$output" \
        || fail "OpenSSL não executou o vetor de referência $algorithm."
    actual="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).read_bytes().hex())' "$output")"
    [[ "$actual" == "$expected" ]] \
        || fail "O vetor de referência $algorithm divergiu do resultado esperado."
}

trap cleanup EXIT

for command_name in docker openssl python3 cmp; do
    command -v "$command_name" >/dev/null 2>&1 || fail "Dependência ausente: $command_name."
done

# Vetores RFC 3686 usados também no teste AES-CTR do firmware Meshtastic fixado.
# Eles verificam o primitivo AES-CTR do OpenSSL, não executam o firmware.
check_ctr_reference_vector \
    -aes-256-ctr \
    "776beff2851db06f4c8a0542c8696f6c6a81af1eec96b4d37fc1d689e6c1c104" \
    "00000060db5672c97aa8f0b200000001" \
    "145ad01dbf824ec7560863dc71e3e0c0"
check_ctr_reference_vector \
    -aes-128-ctr \
    "ae6852f8121067cc4bf7a5765577f39e" \
    "00000030000000000000000000000001" \
    "e4095d4fb7a7b3792d6175a3261311b8"

# Modelo de nonce de canal: packet_id LE64 + from_node LE32 + contador LE32.
# Os valores são sintéticos e não contêm segredos reais.
NONCE="$(python3 - "$PACKET_ID" "$FROM_NODE" <<'PY'
import struct
import sys

packet_id = int(sys.argv[1])
from_node = int(sys.argv[2])
print(struct.pack("<QII", packet_id, from_node, 0).hex())
PY
)"
EXPECTED_NONCE="78563412000000008967452300000000"
[[ "$NONCE" == "$EXPECTED_NONCE" ]] || fail "A disposição de bytes do nonce diverge da referência esperada."

printf 'DevMesh privado' > "$TEMP_DIR/plaintext.bin"
openssl enc -aes-128-ctr -K "$KEY_B" -iv "$NONCE" \
    -in "$TEMP_DIR/plaintext.bin" -out "$TEMP_DIR/ciphertext.bin" \
    || fail "Não foi possível gerar o ciphertext AES-128-CTR de teste."

docker run --detach --name "$CONTAINER_NAME" \
    --volume "$ROOT_DIR/tests/mosquitto/mosquitto.conf:/mosquitto/config/mosquitto.conf:ro" \
    "$IMAGE" >/dev/null

for attempt in $(seq 1 20); do
    if docker exec "$CONTAINER_NAME" mosquitto_pub -h 127.0.0.1 \
        -t devmesh/test/healthcheck -m ready >/dev/null 2>&1; then
        BROKER_READY=true
        break
    fi
    sleep 0.5
done
[[ "$BROKER_READY" == true ]] || fail "Mosquitto não ficou pronto dentro do prazo."

docker exec -i "$CONTAINER_NAME" mosquitto_pub -r -h 127.0.0.1 \
    -t "$TOPIC" -s < "$TEMP_DIR/ciphertext.bin" \
    || fail "Falha ao publicar o ciphertext de teste."

for node in B C; do
    output="$TEMP_DIR/node-${node}.ciphertext"
    docker exec "$CONTAINER_NAME" mosquitto_sub -h 127.0.0.1 \
        -t "$TOPIC_FILTER" -C 1 -N -W 8 > "$output" \
        || fail "O nó ${node} não recebeu o ciphertext no prazo."
    cmp --silent "$TEMP_DIR/ciphertext.bin" "$output" \
        || fail "Os bytes recebidos pelo nó ${node} diferem do ciphertext publicado."
done

openssl enc -d -aes-128-ctr -K "$KEY_B" -iv "$NONCE" \
    -in "$TEMP_DIR/node-B.ciphertext" -out "$TEMP_DIR/node-B.plaintext" \
    || fail "O nó B não conseguiu decifrar com a chave correta."
cmp --silent "$TEMP_DIR/plaintext.bin" "$TEMP_DIR/node-B.plaintext" \
    || fail "O nó B não recuperou o texto original."

openssl enc -d -aes-128-ctr -K "$KEY_C" -iv "$NONCE" \
    -in "$TEMP_DIR/node-C.ciphertext" -out "$TEMP_DIR/node-C.plaintext" \
    || fail "Falha ao executar a decifragem de controle do nó C."
if cmp --silent "$TEMP_DIR/plaintext.bin" "$TEMP_DIR/node-C.plaintext"; then
    fail "O nó C recuperou o texto original usando uma chave diferente."
fi

# AES-CTR não autentica: alterar um bit do ciphertext altera o bit correspondente do plaintext.
python3 - "$TEMP_DIR/ciphertext.bin" "$TEMP_DIR/tampered-ciphertext.bin" <<'PY'
from pathlib import Path
import sys
ciphertext = bytearray(Path(sys.argv[1]).read_bytes())
ciphertext[0] ^= 0x01
Path(sys.argv[2]).write_bytes(ciphertext)
PY
openssl enc -d -aes-128-ctr -K "$KEY_B" -iv "$NONCE" -in "$TEMP_DIR/tampered-ciphertext.bin" -out "$TEMP_DIR/tampered-plaintext.bin" || fail "Falha ao demonstrar AES-CTR com ciphertext alterado."
python3 - "$TEMP_DIR/plaintext.bin" "$TEMP_DIR/tampered-plaintext.bin" <<'PY'
from pathlib import Path
import sys
original = Path(sys.argv[1]).read_bytes()
tampered = Path(sys.argv[2]).read_bytes()
expected = bytes([original[0] ^ 0x01]) + original[1:]
if tampered != expected:
    raise SystemExit("FALHA: a alteração do ciphertext não correspondeu à alteração de bit esperada.")
PY

printf 'OK: vetores AES-128/AES-256 de referência conferidos.\n'
printf 'OK: nonce de canal coincide com a disposição de bytes esperada.\n'
printf 'OK: B e C receberam os mesmos bytes cifrados pelo MQTT.\n'
printf 'OK: B recuperou o texto de teste usando a chave correta.\n'
printf 'OK: C não recuperou o texto original usando uma chave diferente.\n'
printf 'LIMITE: modelo independente; não executa CryptoEngine.cpp nem prova interoperabilidade integral com firmware.\n'
printf 'LIMITE: AES-CTR não autentica o conteúdo; este teste não comprova integridade ou autenticidade.\n'
