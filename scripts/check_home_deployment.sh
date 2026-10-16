#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${MOSQUITTO_IMAGE:-eclipse-mosquitto:2.1.2-alpine}"
TEMP_DIR="$(mktemp -d)"
PROJECT_NAME="devmesh-home-check-${GITHUB_RUN_ID:-local}-${BASHPID}"
PASSWORD="ci-only-password"
DEVMESH_MQTT_PORT="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')"
export DEVMESH_MQTT_PORT

cleanup() {
    docker compose --project-name "$PROJECT_NAME" --file "$TEMP_DIR/compose.yaml" down --volumes --remove-orphans >/dev/null 2>&1 || true
    rm -rf "$TEMP_DIR"
}

fail() {
    printf 'FALHA: %s\n' "$*" >&2
    docker compose --project-name "$PROJECT_NAME" --file "$TEMP_DIR/compose.yaml" logs mosquitto >&2 || true
    exit 1
}

trap cleanup EXIT

cp "$ROOT_DIR/deploy/home/compose.yaml" "$TEMP_DIR/compose.yaml"
cp "$ROOT_DIR/deploy/home/mosquitto.conf" "$TEMP_DIR/mosquitto.conf"
cp "$ROOT_DIR/deploy/home/aclfile" "$TEMP_DIR/aclfile"

docker run --rm --user "$(id -u):$(id -g)" \
    --entrypoint mosquitto_passwd \
    --volume "$TEMP_DIR:/mosquitto/config" \
    "$IMAGE" -b -c /mosquitto/config/passwordfile devmesh "$PASSWORD"
docker run --rm --user "$(id -u):$(id -g)" \
    --entrypoint mosquitto_passwd \
    --volume "$TEMP_DIR:/mosquitto/config" \
    "$IMAGE" -b /mosquitto/config/passwordfile probe ci-probe-password
chmod 644 "$TEMP_DIR/passwordfile"

# Usuário observador exclusivo do teste para verificar separadamente as duas direções da ACL.
cat >> "$TEMP_DIR/aclfile" <<'ACL'

user probe
topic readwrite outside-prefix/#
ACL

docker compose --project-name "$PROJECT_NAME" --file "$TEMP_DIR/compose.yaml" config --quiet
docker compose --project-name "$PROJECT_NAME" --file "$TEMP_DIR/compose.yaml" up -d

broker_exec() {
    docker compose --project-name "$PROJECT_NAME" --file "$TEMP_DIR/compose.yaml" \
        exec -T mosquitto "$@"
}

node_pub() {
    broker_exec mosquitto_pub -h 127.0.0.1 -u devmesh -P "$PASSWORD" "$@"
}

node_sub_once() {
    local topic="$1"
    local output_file="$2"
    local error_file="$3"
    broker_exec mosquitto_sub -h 127.0.0.1 -u devmesh -P "$PASSWORD" \
        -t "$topic" -C 1 -W 3 >"$output_file" 2>"$error_file"
}

BROKER_READY=false
for attempt in $(seq 1 20); do
    if node_pub -t msh/healthcheck -m ready >/dev/null 2>&1; then
        BROKER_READY=true
        break
    fi
    sleep 0.5
done
[[ "$BROKER_READY" == true ]] || fail "O broker doméstico não ficou pronto dentro do prazo."
printf 'OK: o broker iniciou e aceitou o cliente autenticado.\n'

node_pub -r -t msh/auth-check -m authenticated
AUTH_OUTPUT="$TEMP_DIR/auth-output.txt"
node_sub_once msh/auth-check "$AUTH_OUTPUT" "$TEMP_DIR/auth-error.txt" \
    || fail "O cliente autenticado não recebeu a mensagem retida."
grep --fixed-strings --line-regexp --quiet authenticated "$AUTH_OUTPUT" \
    || fail "A mensagem autenticada recebida não corresponde ao conteúdo publicado."
printf 'OK: autenticação e entrega MQTT funcionaram.\n'

set +e
broker_exec mosquitto_sub -h 127.0.0.1 -t msh/auth-check -C 1 -W 2 \
    >"$TEMP_DIR/anonymous-output.txt" 2>"$TEMP_DIR/anonymous-error.txt"
ANONYMOUS_STATUS=$?
set -e
[[ ! -s "$TEMP_DIR/anonymous-output.txt" && "$ANONYMOUS_STATUS" -ne 0 ]] \
    || fail "Um cliente anônimo recebeu uma mensagem protegida."
printf 'OK: o acesso anônimo foi recusado.\n'

set +e
broker_exec mosquitto_sub -h 127.0.0.1 -u devmesh -P wrong-ci-password \
    -t msh/auth-check -C 1 -W 2 >"$TEMP_DIR/wrong-output.txt" 2>"$TEMP_DIR/wrong-error.txt"
WRONG_PASSWORD_STATUS=$?
set -e
[[ ! -s "$TEMP_DIR/wrong-output.txt" && "$WRONG_PASSWORD_STATUS" -ne 0 ]] \
    || fail "Uma senha incorreta permitiu receber uma mensagem protegida."
printf 'OK: uma senha incorreta foi recusada.\n'

broker_exec mosquitto_pub -h 127.0.0.1 -u probe -P ci-probe-password \
    -r -t outside-prefix/read-check -m probe-readable
set +e
node_sub_once outside-prefix/read-check "$TEMP_DIR/acl-read-output.txt" "$TEMP_DIR/acl-read-error.txt"
ACL_READ_STATUS=$?
set -e
[[ ! -s "$TEMP_DIR/acl-read-output.txt" && "$ACL_READ_STATUS" -ne 0 ]] \
    || fail "O cliente devmesh leu um tópico fora do prefixo autorizado."

node_pub -r -t outside-prefix/publish-check -m must-not-be-retained >/dev/null 2>&1 || true
set +e
broker_exec mosquitto_sub -h 127.0.0.1 -u probe -P ci-probe-password \
    -t outside-prefix/publish-check -C 1 -W 3 \
    >"$TEMP_DIR/acl-publish-output.txt" 2>"$TEMP_DIR/acl-publish-error.txt"
ACL_PUBLISH_STATUS=$?
set -e
[[ ! -s "$TEMP_DIR/acl-publish-output.txt" && "$ACL_PUBLISH_STATUS" -ne 0 ]] \
    || fail "A publicação do cliente devmesh foi retida fora do prefixo autorizado."
printf 'OK: a ACL bloqueou leitura e publicação fora de msh/#.\n'
printf 'PASSOU: configuração doméstica validada com Mosquitto real em contêiner descartável.\n'
printf 'LIMITE: não valida TLS, payloads de rádio real nem prontidão para produção.\n'
