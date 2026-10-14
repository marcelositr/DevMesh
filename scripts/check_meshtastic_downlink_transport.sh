#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${MOSQUITTO_IMAGE:-eclipse-mosquitto:2.1.2-alpine}"
RUN_ID="${GITHUB_RUN_ID:-local}"
RUN_ATTEMPT="${GITHUB_RUN_ATTEMPT:-0}"
CONTAINER_NAME="devmesh-mqtt-downlink-${RUN_ID}-${RUN_ATTEMPT}"
TEMP_DIR="$(mktemp -d)"
BROKER_READY=false
ROOT_TOPIC="msh/2/e"
CHANNEL="LongFast"
GATEWAY_ID="!a1b2c3d4"
DOWNLINK_TOPIC="${ROOT_TOPIC}/${CHANNEL}/${GATEWAY_ID}"
RADIO_FILTER="${ROOT_TOPIC}/${CHANNEL}/+"

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

# Replica o filtro que o firmware Meshtastic usa para downlink cifrado.
OUTPUT="$TEMP_DIR/radio-received.bin"
docker exec "$CONTAINER_NAME" mosquitto_sub -h 127.0.0.1 \
    -t "$RADIO_FILTER" -C 1 -N -W 8 > "$OUTPUT" 2>"$TEMP_DIR/subscriber.err" &
SUBSCRIBER_PID="$!"
sleep 0.5

# O fixture é sintético: testa apenas o caminho MQTT e a correspondência de tópico.
docker exec -i "$CONTAINER_NAME" mosquitto_pub -h 127.0.0.1 \
    -t "$DOWNLINK_TOPIC" -s < "$TEMP_DIR/service-envelope.bin" \
    || fail "Falha ao publicar o ServiceEnvelope sintético no tópico de downlink."

wait "$SUBSCRIBER_PID" || fail "O assinante com filtro de downlink não recebeu o envelope."
cmp --silent "$TEMP_DIR/service-envelope.bin" "$OUTPUT" \
    || fail "Os bytes recebidos diferem do ServiceEnvelope publicado."

printf 'OK: o filtro %s recebeu o envelope publicado em %s.\n' "$RADIO_FILTER" "$DOWNLINK_TOPIC"
printf 'OK: o broker preservou os bytes do ServiceEnvelope.\n'
printf 'LIMITE: simula somente broker/tópico; não valida a aceitação pelo firmware, chaves, decifragem ou transmissão LoRa.\n'
