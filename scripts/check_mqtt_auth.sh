#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${MOSQUITTO_IMAGE:-eclipse-mosquitto:2.1.2-alpine}"
RUN_ID="${GITHUB_RUN_ID:-local}"
RUN_ATTEMPT="${GITHUB_RUN_ATTEMPT:-0}"
CONTAINER_NAME="devmesh-mosquitto-auth-${RUN_ID}-${RUN_ATTEMPT}"
TEMP_DIR="$(mktemp -d)"
TEST_USERNAME="devmesh-test"
TEST_PASSWORD="devmesh-test-password"
BROKER_READY=false

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

# Gere uma credencial descartável usando a ferramenta da própria imagem.
docker run --rm \
    --volume "$TEMP_DIR:/tmp/auth" \
    --entrypoint mosquitto_passwd \
    "$IMAGE" \
    -b -c /tmp/auth/passwordfile "$TEST_USERNAME" "$TEST_PASSWORD"

docker run \
    --detach \
    --name "$CONTAINER_NAME" \
    --volume "$ROOT_DIR/tests/mosquitto/mosquitto-auth.conf:/mosquitto/config/mosquitto.conf:ro" \
    --volume "$TEMP_DIR/passwordfile:/mosquitto/config/passwordfile:ro" \
    "$IMAGE" >/dev/null

for attempt in $(seq 1 20); do
    if docker exec "$CONTAINER_NAME" mosquitto_pub \
        -h 127.0.0.1 \
        -u "$TEST_USERNAME" \
        -P "$TEST_PASSWORD" \
        -t devmesh/test/auth/healthcheck \
        -m ready >/dev/null 2>&1; then
        BROKER_READY=true
        break
    fi
    sleep 0.5
done

if [[ "$BROKER_READY" != true ]]; then
    fail "Mosquitto com autenticação não ficou pronto dentro do prazo."
fi

if docker exec "$CONTAINER_NAME" mosquitto_pub \
    -h 127.0.0.1 \
    -t devmesh/test/auth/anonymous \
    -m must-be-rejected >/dev/null 2>&1; then
    fail "O broker aceitou uma publicação anônima."
fi
printf 'OK: o broker recusou uma publicação sem credenciais.\n'

OUTPUT_FILE="$TEMP_DIR/authenticated-message.txt"
ERROR_FILE="$TEMP_DIR/subscriber.err"

docker exec "$CONTAINER_NAME" mosquitto_sub \
    -h 127.0.0.1 \
    -u "$TEST_USERNAME" \
    -P "$TEST_PASSWORD" \
    -t devmesh/test/auth/delivery \
    -C 1 \
    -W 8 >"$OUTPUT_FILE" 2>"$ERROR_FILE" &
SUBSCRIBER_PID="$!"
sleep 1

PAYLOAD="authenticated-message-from-node-a"
if ! docker exec "$CONTAINER_NAME" mosquitto_pub \
    -h 127.0.0.1 \
    -u "$TEST_USERNAME" \
    -P "$TEST_PASSWORD" \
    -t devmesh/test/auth/delivery \
    -m "$PAYLOAD"; then
    fail "O cliente autenticado não conseguiu publicar."
fi

if ! wait "$SUBSCRIBER_PID"; then
    fail "O cliente autenticado não recebeu a mensagem dentro do prazo."
fi

if ! grep --fixed-strings --line-regexp --quiet "$PAYLOAD" "$OUTPUT_FILE"; then
    fail "O payload recebido não corresponde ao conteúdo enviado."
fi

printf 'OK: clientes autenticados conseguiram publicar e receber mensagens.\n'
printf 'PASSOU: autenticação MQTT básica validada no broker descartável.\n'
printf 'LIMITE: este teste não valida ACLs, TLS, criptografia Meshtastic nem configuração de produção.\n'
