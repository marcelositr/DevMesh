#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${MOSQUITTO_IMAGE:-eclipse-mosquitto:2.1.2-alpine}"
CONTAINER_NAME="devmesh-mosquitto-acl-${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-0}"
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

docker run --rm --user "$(id -u):$(id -g)" --volume "$TEMP_DIR:/tmp/auth" \
    --entrypoint mosquitto_passwd "$IMAGE" -b -c /tmp/auth/passwordfile node-a node-a-test-password

for node in node-b node-c; do
    docker run --rm --user "$(id -u):$(id -g)" --volume "$TEMP_DIR:/tmp/auth" \
        --entrypoint mosquitto_passwd "$IMAGE" -b /tmp/auth/passwordfile "$node" "$node-test-password"
done
chmod 644 "$TEMP_DIR/passwordfile"

cat > "$TEMP_DIR/aclfile" <<'ACL'
user node-a
topic readwrite devmesh/public/#
topic readwrite devmesh/private/a

user node-b
topic readwrite devmesh/public/#
topic readwrite devmesh/private/a

user node-c
topic readwrite devmesh/public/#
ACL
chmod 644 "$TEMP_DIR/aclfile"

docker run --detach --name "$CONTAINER_NAME" \
    --volume "$ROOT_DIR/tests/mosquitto/mosquitto-acl.conf:/mosquitto/config/mosquitto.conf:ro" \
    --volume "$TEMP_DIR/passwordfile:/mosquitto/config/passwordfile:ro" \
    --volume "$TEMP_DIR/aclfile:/mosquitto/config/aclfile:ro" \
    "$IMAGE" >/dev/null

broker_exec() {
    docker exec "$CONTAINER_NAME" "$@"
}

node_pub() {
    local username="$1"
    local topic="$2"
    local payload="$3"
    broker_exec mosquitto_pub -h 127.0.0.1 -u "$username" \
        -P "$username-test-password" -i "$username" -t "$topic" -m "$payload"
}

node_sub_once() {
    local username="$1"
    local topic="$2"
    local output_file="$3"
    local error_file="$4"
    broker_exec mosquitto_sub -h 127.0.0.1 -u "$username" \
        -P "$username-test-password" -i "$username-subscriber" \
        -t "$topic" -C 1 -W 6 >"$output_file" 2>"$error_file"
}

for attempt in $(seq 1 20); do
    if node_pub node-a devmesh/public/healthcheck ready >/dev/null 2>&1; then
        BROKER_READY=true
        break
    fi
    sleep 0.5
done
[[ "$BROKER_READY" == true ]] || fail "Mosquitto com ACLs não ficou pronto dentro do prazo."

PUBLIC_OUTPUT="$TEMP_DIR/public-node-b.txt"
PUBLIC_NODE_C_OUTPUT="$TEMP_DIR/public-node-c.txt"
PRIVATE_OUTPUT="$TEMP_DIR/private-node-b.txt"
DENIED_OUTPUT="$TEMP_DIR/denied-node-c.txt"

node_sub_once node-b devmesh/public/check "$PUBLIC_OUTPUT" "$TEMP_DIR/public-node-b.err" &
PUBLIC_B_PID="$!"
node_sub_once node-c devmesh/public/check "$PUBLIC_NODE_C_OUTPUT" "$TEMP_DIR/public-node-c.err" &
PUBLIC_C_PID="$!"
sleep 1
node_pub node-a devmesh/public/check "public-message-from-node-a"

wait "$PUBLIC_B_PID" || fail "O nó B não recebeu a mensagem pública permitida."
wait "$PUBLIC_C_PID" || fail "O nó C não recebeu a mensagem pública permitida."
grep --fixed-strings --line-regexp --quiet "public-message-from-node-a" "$PUBLIC_OUTPUT" \
    || fail "O conteúdo público recebido pelo nó B não corresponde ao enviado."
grep --fixed-strings --line-regexp --quiet "public-message-from-node-a" "$PUBLIC_NODE_C_OUTPUT" \
    || fail "O conteúdo público recebido pelo nó C não corresponde ao enviado."
printf 'OK: nós B e C receberam a mensagem do tópico público autorizado.\n'

node_sub_once node-b devmesh/private/a "$PRIVATE_OUTPUT" "$TEMP_DIR/private-node-b.err" &
PRIVATE_B_PID="$!"
sleep 1
node_pub node-a devmesh/private/a "private-message-from-node-a"
wait "$PRIVATE_B_PID" || fail "O nó B não recebeu a mensagem privada autorizada."
grep --fixed-strings --line-regexp --quiet "private-message-from-node-a" "$PRIVATE_OUTPUT" \
    || fail "O conteúdo privado recebido pelo nó B não corresponde ao enviado."
printf 'OK: nó B recebeu a mensagem privada autorizada do nó A.\n'

if node_pub node-c devmesh/private/a "must-be-rejected" >"$TEMP_DIR/denied-publish.txt" 2>&1; then
    fail "O broker aceitou publicação do nó C no tópico privado de A/B."
fi
printf 'OK: o broker recusou publicação do nó C no tópico privado.\n'

set +e
node_sub_once node-c devmesh/private/a "$DENIED_OUTPUT" "$TEMP_DIR/denied-node-c.err" &
DENIED_PID="$!"
sleep 1
node_pub node-a devmesh/private/a "private-message-not-for-node-c"
wait "$DENIED_PID"
DENIED_STATUS=$?
set -e

[[ ! -s "$DENIED_OUTPUT" ]] || fail "O nó C recebeu conteúdo do tópico privado apesar da ACL."
[[ "$DENIED_STATUS" -ne 0 ]] || fail "A assinatura do nó C no tópico privado terminou como sucesso inesperado."
printf 'OK: o nó C não recebeu mensagens do tópico privado e a assinatura não foi autorizada.\n'
printf 'PASSOU: ACLs MQTT verificadas com três clientes e broker descartável.\n'
printf 'LIMITE: este teste não valida TLS, criptografia Meshtastic nem configuração de produção.\n'
