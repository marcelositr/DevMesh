#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${MOSQUITTO_IMAGE:-eclipse-mosquitto:2.1.2-alpine}"
RUN_ID="${GITHUB_RUN_ID:-local}"
RUN_ATTEMPT="${GITHUB_RUN_ATTEMPT:-0}"
CONTAINER_NAME="devmesh-mosquitto-smoke-${RUN_ID}-${RUN_ATTEMPT}"
TEMP_DIR="$(mktemp -d)"
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

wait_for_subscription() {
    local subscriber_pid="$1"
    local debug_file="$2"

    for attempt in $(seq 1 40); do
        if grep --quiet --ignore-case --fixed-strings 'Subscribed (mid:' "$debug_file"; then
            return 0
        fi
        if ! kill -0 "$subscriber_pid" 2>/dev/null; then
            fail "O assinante terminou antes de confirmar a assinatura MQTT."
        fi
        sleep 0.1
    done

    fail "O assinante não recebeu confirmação SUBACK dentro do prazo."
}

subscribe_once() {
    local node_name="$1"
    local topic="$2"
    local output_file="$3"

    docker exec "$CONTAINER_NAME" mosquitto_sub \
        -d \
        -h 127.0.0.1 \
        -i "$node_name" \
        -t "$topic" \
        -C 1 \
        -W 8 >"$output_file" 2>"$TEMP_DIR/${node_name}.err" &
    SUBSCRIBER_PID="$!"
}

assert_public_delivery() {
    local topic="devmesh/test/public"
    local payload="public-message-from-node-a"
    local node_b_output="$TEMP_DIR/node-b-public.txt"
    local node_c_output="$TEMP_DIR/node-c-public.txt"
    local node_b_pid
    local node_c_pid

    subscribe_once node-b "$topic" "$node_b_output"
    node_b_pid="$SUBSCRIBER_PID"
    subscribe_once node-c "$topic" "$node_c_output"
    node_c_pid="$SUBSCRIBER_PID"
    wait_for_subscription "$node_b_pid" "$TEMP_DIR/node-b.err"
    wait_for_subscription "$node_c_pid" "$TEMP_DIR/node-c.err"

    docker exec "$CONTAINER_NAME" mosquitto_pub \
        -h 127.0.0.1 \
        -i node-a \
        -t "$topic" \
        -m "$payload"

    wait "$node_b_pid" || fail "O nó B não recebeu a mensagem pública."
    wait "$node_c_pid" || fail "O nó C não recebeu a mensagem pública."

    grep --fixed-strings --line-regexp --quiet "$payload" "$node_b_output" \
        || fail "A mensagem recebida pelo nó B não corresponde ao conteúdo enviado."
    grep --fixed-strings --line-regexp --quiet "$payload" "$node_c_output" \
        || fail "A mensagem recebida pelo nó C não corresponde ao conteúdo enviado."

    printf 'OK: os nós B e C receberam a mensagem do tópico público.\n'
}

assert_topic_routing() {
    local payload="message-for-private-topic-a"
    local node_b_output="$TEMP_DIR/node-b-private.txt"
    local node_c_output="$TEMP_DIR/node-c-other-topic.txt"
    local node_b_pid
    local node_c_pid

    subscribe_once node-b-private devmesh/test/private/a "$node_b_output"
    node_b_pid="$SUBSCRIBER_PID"
    subscribe_once node-c-other-topic devmesh/test/private/b "$node_c_output"
    node_c_pid="$SUBSCRIBER_PID"
    wait_for_subscription "$node_b_pid" "$TEMP_DIR/node-b-private.err"
    wait_for_subscription "$node_c_pid" "$TEMP_DIR/node-c-other-topic.err"

    docker exec "$CONTAINER_NAME" mosquitto_pub \
        -h 127.0.0.1 \
        -i node-a-private \
        -t devmesh/test/private/a \
        -m "$payload"

    wait "$node_b_pid" || fail "O nó B não recebeu a mensagem do tópico A."
    if wait "$node_c_pid"; then
        fail "O nó C recebeu inesperadamente uma mensagem de outro tópico."
    fi
    grep --ignore-case --quiet "timed out" "$TEMP_DIR/node-c-other-topic.err" \
        || fail "O assinante do nó C terminou por um motivo diferente do timeout esperado."

    grep --fixed-strings --line-regexp --quiet "$payload" "$node_b_output" \
        || fail "A mensagem do tópico A não corresponde ao conteúdo enviado."
    if [[ -f "$node_c_output" ]] && grep --fixed-strings --quiet "$payload" "$node_c_output"; then
        fail "A mensagem do tópico A apareceu na saída do nó C."
    fi

    printf 'OK: a mensagem do tópico A não foi entregue ao assinante do tópico B.\n'
}

printf 'Verificando broker MQTT com a imagem %s...\n' "$IMAGE"
assert_public_delivery
assert_topic_routing
printf 'PASSOU: verificações básicas de publicação, assinatura e roteamento MQTT.\n'
printf 'LIMITE: este teste não verifica criptografia Meshtastic, autenticação MQTT nem ACLs.\n'
