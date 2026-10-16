#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROTOBUF_TAG="v2.8.0"
PROTOBUF_COMMIT="7b2464c9b8c1521f93852261e4123826e5b25e11"
TEMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TEMP_DIR"
}

fail() {
    printf 'FALHA: %s\n' "$*" >&2
    exit 1
}

trap cleanup EXIT

for command_name in git protoc xxd cmp grep; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        fail "Dependência ausente: $command_name."
    fi
done

git clone --quiet --depth 1 --branch "$PROTOBUF_TAG" \
    https://github.com/meshtastic/protobufs.git "$TEMP_DIR/protobufs"

ACTUAL_COMMIT="$(git -C "$TEMP_DIR/protobufs" rev-parse HEAD)"
if [[ "$ACTUAL_COMMIT" != "$PROTOBUF_COMMIT" ]]; then
    fail "A tag $PROTOBUF_TAG não aponta para o commit esperado."
fi

tr -d '[:space:]' < "$ROOT_DIR/tests/fixtures/meshtastic-service-envelope.hex" \
    | xxd -r -p > "$TEMP_DIR/service-envelope.bin"

if [[ ! -s "$TEMP_DIR/service-envelope.bin" ]]; then
    fail "O fixture binário do ServiceEnvelope está vazio."
fi

(
    cd "$TEMP_DIR/protobufs"
    protoc -I . --decode=meshtastic.ServiceEnvelope meshtastic/mqtt.proto \
        < "$TEMP_DIR/service-envelope.bin" > "$TEMP_DIR/decoded.txt"
)

for expected_field in \
    'packet {' \
    'from: 305419896' \
    'encrypted:' \
    'channel_id: "LongFast"' \
    'gateway_id: "!a1b2c3d4"'; do
    if ! grep -Fq "$expected_field" "$TEMP_DIR/decoded.txt"; then
        fail "O Protobuf decodificado não contém o campo esperado: $expected_field"
    fi
done

(
    cd "$TEMP_DIR/protobufs"
    protoc -I . --encode=meshtastic.ServiceEnvelope meshtastic/mqtt.proto \
        < "$TEMP_DIR/decoded.txt" > "$TEMP_DIR/re-encoded.bin"
)

if ! cmp --silent "$TEMP_DIR/service-envelope.bin" "$TEMP_DIR/re-encoded.bin"; then
    fail "O fixture não passou pelo ciclo de decodificação e codificação Protobuf sem alterações."
fi

printf 'OK: fixture decodificado com as definições oficiais Meshtastic %s.\n' "$PROTOBUF_TAG"
printf 'OK: ServiceEnvelope, MeshPacket, campo encrypted e metadados validados.\n'
printf 'OK: ciclo Protobuf decode/encode preservou exatamente os bytes do fixture.\n'
printf 'LIMITE: fixture sintético; não comprova criptografia real, firmware, downlink ou rádio LoRa.\n'
