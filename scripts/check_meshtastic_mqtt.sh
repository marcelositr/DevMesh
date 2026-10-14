#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${MOSQUITTO_IMAGE:-eclipse-mosquitto:2.1.2-alpine}"
RUN_ID="${GITHUB_RUN_ID:-local}"
RUN_ATTEMPT="${GITHUB_RUN_ATTEMPT:-0}"
CONTAINER_NAME="devmesh-meshtastic-mqtt-${RUN_ID}-${RUN_ATTEMPT}"
TEMP_DIR="$(mktemp -d)"
BROKER_READY=false
TOPIC="msh/US/2/e/LongFast/!a1b2c3d4"
TOPIC_FILTER="msh/US/2/e/LongFast/#"

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

trap cleanup EXIT

# Fixture sintético: ServiceEnvelope com bytes no campo encrypted.
tr -d '[:space:]' < "$ROOT_DIR/tests/fixtures/meshtastic-service-envelope.hex" \
    | xxd -r -p > "$TEMP_DIR/service-envelope.bin"
[[ -s "$TEMP_DIR/service-envelope.bin" ]] || fail "Fixture binário vazio."

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

OUTPUT_B="$TEMP_DIR/node-b.bin"
OUTPUT_C="$TEMP_DIR/node-c.bin"

# A mensagem retida remove a corrida entre a publicação e a assinatura.
docker exec -i "$CONTAINER_NAME" mosquitto_pub -r -h 127.0.0.1 \
    -t "$TOPIC" -s < "$TEMP_DIR/service-envelope.bin" \
    || fail "Falha ao publicar o fixture binário retido."

docker exec "$CONTAINER_NAME" mosquitto_sub -h 127.0.0.1 -t "$TOPIC_FILTER" \
    -C 1 -N -W 8 > "$OUTPUT_B" 2> "$TEMP_DIR/node-b.err" &
PID_B="$!"
docker exec "$CONTAINER_NAME" mosquitto_sub -h 127.0.0.1 -t "$TOPIC_FILTER" \
    -C 1 -N -W 8 > "$OUTPUT_C" 2> "$TEMP_DIR/node-c.err" &
PID_C="$!"

wait "$PID_B" || fail "O nó B não recebeu o envelope no prazo."
wait "$PID_C" || fail "O nó C não recebeu o envelope no prazo."
cmp --silent "$TEMP_DIR/service-envelope.bin" "$OUTPUT_B" \
    || fail "Os bytes recebidos pelo nó B diferem dos publicados."
cmp --silent "$TEMP_DIR/service-envelope.bin" "$OUTPUT_C" \
    || fail "Os bytes recebidos pelo nó C diferem dos publicados."

printf 'OK: os nós B e C receberam o mesmo ServiceEnvelope retido em %s.\n' "$TOPIC"
printf 'OK: o broker preservou exatamente os bytes publicados pelo nó A.\n'
printf 'LIMITE: fixture sintético; este teste não valida ACL, criptografia real, firmware ou rádio LoRa.\n'
