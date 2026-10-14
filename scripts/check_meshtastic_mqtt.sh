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

# O fixture hexadecimal representa um ServiceEnvelope com um MeshPacket criptografado.
# Os bytes são derivados das definições oficiais; este teste não decodifica Protobuf.
tr -d '[:space:]' < "$ROOT_DIR/tests/fixtures/meshtastic-service-envelope.hex" \
    | xxd -r -p > "$TEMP_DIR/service-envelope.bin"

if [[ ! -s "$TEMP_DIR/service-envelope.bin" ]]; then
    fail "O fixture binário do ServiceEnvelope está vazio."
fi

docker run \
    --detach \
    --name "$CONTAINER_NAME" \
    --volume "$ROOT_DIR/tests/mosquitto/mosquitto.conf:/mosquitto/config/mosquitto.conf:ro" \
    "$IMAGE" >/dev/null

for attempt in $(seq 1 20); do
    if docker exec "$CONTAINER_NAME" mosquitto_pub \
        -h 127.0.0.1 \
        -t devmesh/test/healthcheck \
        -m ready >/dev/null 2>&1; then
        BROKER_READY=true
        break
    fi
    sleep 0.5
done

if [[ "$BROKER_READY" != true ]]; then
    fail "Mosquitto não ficou pronto dentro do prazo."
fi

OUTPUT_FILE="$TEMP_DIR/received-envelope.bin"
ERROR_FILE="$TEMP_DIR/subscriber.err"

docker exec "$CONTAINER_NAME" mosquitto_sub \
    -h 127.0.0.1 \
    -t "$TOPIC" \
    -C 1 \
    -N \
    -W 8 > "$OUTPUT_FILE" 2> "$ERROR_FILE" &
SUBSCRIBER_PID="$!"
sleep 1

docker exec -i "$CONTAINER_NAME" mosquitto_pub \
    -h 127.0.0.1 \
    -t "$TOPIC" \
    -s < "$TEMP_DIR/service-envelope.bin" \
    || fail "Não foi possível publicar o payload binário no tópico Meshtastic."

wait "$SUBSCRIBER_PID" \
    || fail "O assinante não recebeu o payload binário dentro do prazo."

if ! cmp --silent "$TEMP_DIR/service-envelope.bin" "$OUTPUT_FILE"; then
    fail "Os bytes recebidos diferem dos bytes publicados."
fi

printf 'OK: o broker preservou os bytes do fixture ServiceEnvelope no tópico %s.\n' "$TOPIC"
printf 'PASSOU: encaminhamento MQTT binário validado para um fixture compatível com o formato Meshtastic.\n'
printf 'LIMITE: não valida decodificação Protobuf, firmware, criptografia real, downlink ou rádio LoRa.\n'
