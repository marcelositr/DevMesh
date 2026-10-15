#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROTOBUF_TAG="v2.8.0"
PROTOBUF_COMMIT="7b2464c9b8c1521f93852261e4123826e5b25e11"
TEMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TEMP_DIR"; }
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
trap cleanup EXIT

for command_name in git protoc grep cmp; do
    command -v "$command_name" >/dev/null 2>&1 || fail "Dependência ausente: $command_name."
done

git clone --quiet --depth 1 --branch "$PROTOBUF_TAG" \
    https://github.com/meshtastic/protobufs.git "$TEMP_DIR/protobufs"
[[ "$(git -C "$TEMP_DIR/protobufs" rev-parse HEAD)" == "$PROTOBUF_COMMIT" ]] || \
    fail "A tag $PROTOBUF_TAG não aponta para o commit esperado."

PROTO_DIR="$TEMP_DIR/protobufs"
COUNT=0

check_message() {
    local message="$1" schema="$2" input="$3"
    shift 3
    local input_file="$TEMP_DIR/input.txt"
    local decoded_file="$TEMP_DIR/decoded.txt"
    local binary_file="$TEMP_DIR/message.bin"
    local roundtrip_file="$TEMP_DIR/roundtrip.bin"

    printf '%s\n' "$input" > "$input_file"
    (cd "$PROTO_DIR" && protoc -I . --encode="meshtastic.$message" "$schema" < "$input_file" > "$binary_file") \
        || fail "Falha ao codificar fixture sintético $message."
    (cd "$PROTO_DIR" && protoc -I . --decode="meshtastic.$message" "$schema" < "$binary_file" > "$decoded_file") \
        || fail "Falha ao decodificar fixture sintético $message."

    local expected
    for expected in "$@"; do
        grep -Fq "$expected" "$decoded_file" || fail "$message não contém o campo esperado: $expected"
    done

    (cd "$PROTO_DIR" && protoc -I . --encode="meshtastic.$message" "$schema" < "$decoded_file" > "$roundtrip_file") \
        || fail "Falha no round-trip de $message."
    cmp --silent "$binary_file" "$roundtrip_file" || fail "Round-trip alterou bytes do fixture $message."
    COUNT=$((COUNT + 1))
}

check_message Position meshtastic/mesh.proto $'latitude_i: 123456789\nlongitude_i: -234567890\naltitude: 321\nprecision_bits: 16' \
    'latitude_i: 123456789' 'longitude_i: -234567890' 'altitude: 321' 'precision_bits: 16'

check_message DeviceMetrics meshtastic/telemetry.proto ''

check_message Telemetry meshtastic/telemetry.proto $'time: 1700000000\ndevice_metrics { battery_level: 87 voltage: 4.1 uptime_seconds: 900 }' \
    'device_metrics {' 'battery_level: 87' 'voltage: 4.1' 'uptime_seconds: 900'

check_message Telemetry meshtastic/telemetry.proto $'environment_metrics { temperature: 22.5 relative_humidity: 48.0 barometric_pressure: 1008.2 }' \
    'environment_metrics {' 'temperature: 22.5' 'relative_humidity: 48' 'barometric_pressure: 1008.2'

check_message Telemetry meshtastic/telemetry.proto $'air_quality_metrics { pm25_standard: 12 co2: 640 }' \
    'air_quality_metrics {' 'pm25_standard: 12' 'co2: 640'

check_message User meshtastic/mesh.proto $'id: "!12345678" long_name: "Synthetic Node" short_name: "SYN" is_licensed: false' \
    'id: "!12345678"' 'long_name: "Synthetic Node"' 'short_name: "SYN"'

check_message NeighborInfo meshtastic/mesh.proto $'node_id: 305419896 last_sent_by_id: 305419896 neighbors { node_id: 591751049 snr: 7.25 }' \
    'node_id: 305419896' 'neighbors {' 'snr: 7.25'

check_message Waypoint meshtastic/mesh.proto $'id: 42 latitude_i: 123456789 longitude_i: -234567890 name: "Synthetic waypoint" description: "Fixture only"' \
    'id: 42' 'latitude_i: 123456789' 'longitude_i: -234567890' 'name: "Synthetic waypoint"'

check_message MapReport meshtastic/mqtt.proto $'long_name: "Synthetic Node" short_name: "SYN" firmware_version: "fixture" latitude_i: 123456789 longitude_i: -234567890 position_precision: 16 has_opted_report_location: true' \
    'long_name: "Synthetic Node"' 'firmware_version: "fixture"' 'latitude_i: 123456789' 'position_precision: 16' 'has_opted_report_location: true'

# In proto3, a default false boolean is omitted from text output and the wire payload.
printf '%s\n' 'long_name: "Synthetic Node"' > "$TEMP_DIR/default-map-report.txt"
(cd "$PROTO_DIR" && protoc -I . --encode=meshtastic.MapReport meshtastic/mqtt.proto < "$TEMP_DIR/default-map-report.txt" > "$TEMP_DIR/default-map-report.bin") || fail "Falha ao codificar MapReport com campos opcionais ausentes."
(cd "$PROTO_DIR" && protoc -I . --decode=meshtastic.MapReport meshtastic/mqtt.proto < "$TEMP_DIR/default-map-report.bin" > "$TEMP_DIR/default-map-report-decoded.txt") || fail "Falha ao decodificar MapReport com campos opcionais ausentes."
if grep -q 'has_opted_report_location' "$TEMP_DIR/default-map-report-decoded.txt"; then
    fail "MapReport não respeitou a omissão do booleano false padrão."
fi
COUNT=$((COUNT + 1))


# A truncated protobuf must be rejected rather than silently treated as valid.
printf '\x0a\x05\x01' > "$TEMP_DIR/malformed.bin"
if (cd "$PROTO_DIR" && protoc -I . --decode=meshtastic.Position meshtastic/mesh.proto < "$TEMP_DIR/malformed.bin" > /dev/null 2>&1); then
    fail "O parser aceitou um fixture Protobuf truncado."
fi

printf 'OK: %s fixtures sintéticos validados contra Meshtastic Protobufs %s.\n' "$COUNT" "$PROTOBUF_TAG"
printf 'OK: Position, telemetry vazia e de dispositivo/ambiente/qualidade do ar, User, NeighborInfo, Waypoint e MapReport.\n'
printf 'OK: round-trip binário e rejeição de fixture truncado.\n'
printf 'LIMITE: não valida firmware, descriptografia, política de privacidade em produção, MQTT real ou entrega LoRa.\n'
