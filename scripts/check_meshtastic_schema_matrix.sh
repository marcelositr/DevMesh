#!/usr/bin/env bash
set -Eeuo pipefail

TEMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TEMP_DIR"; }
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
trap cleanup EXIT

for command_name in git protoc grep cmp; do
    command -v "$command_name" >/dev/null 2>&1 || fail "Dependência ausente: $command_name."
done

# Baseline estável e release anterior. SHA completo evita confiar apenas no nome da tag.
VERSIONS=(
    "v2.7.26:da60cee584c6dc1efbb4a3809b98666505179b85"
    "v2.8.0:7b2464c9b8c1521f93852261e4123826e5b25e11"
    "master-snapshot-2026-10-12:28f4f5f5c31c0323bfb86d890a1acaff15d1c4c6"
)

check_message() {
    local version_dir="$1" version="$2" message="$3" schema="$4" input="$5"
    shift 5
    local input_file="$TEMP_DIR/input.txt"
    local decoded_file="$TEMP_DIR/decoded.txt"
    local binary_file="$TEMP_DIR/message.bin"
    local roundtrip_file="$TEMP_DIR/roundtrip.bin"

    printf '%s\n' "$input" > "$input_file"
    (cd "$version_dir" && protoc -I . --encode="meshtastic.$message" "$schema" < "$input_file" > "$binary_file") \
        || fail "$version: falha ao codificar $message."
    (cd "$version_dir" && protoc -I . --decode="meshtastic.$message" "$schema" < "$binary_file" > "$decoded_file") \
        || fail "$version: falha ao decodificar $message."

    local expected
    for expected in "$@"; do
        grep -Fq "$expected" "$decoded_file" || fail "$version: $message não contém o campo esperado: $expected"
    done

    (cd "$version_dir" && protoc -I . --encode="meshtastic.$message" "$schema" < "$decoded_file" > "$roundtrip_file") \
        || fail "$version: falha no round-trip de $message."
    cmp --silent "$binary_file" "$roundtrip_file" || fail "$version: round-trip alterou bytes de $message."
}

for version_spec in "${VERSIONS[@]}"; do
    version="${version_spec%%:*}"
    expected_commit="${version_spec#*:}"
    version_dir="$TEMP_DIR/protobufs-$version"

    git init --quiet "$version_dir"
    git -C "$version_dir" remote add origin https://github.com/meshtastic/protobufs.git
    git -C "$version_dir" fetch --quiet --depth 1 origin "$expected_commit" \
        || fail "$version: não foi possível obter o commit fixado $expected_commit."
    git -C "$version_dir" checkout --quiet --detach FETCH_HEAD
    actual_commit="$(git -C "$version_dir" rev-parse HEAD)"
    [[ "$actual_commit" == "$expected_commit" ]] || fail "$version resolve para $actual_commit, esperado $expected_commit."

    check_message "$version_dir" "$version" Position meshtastic/mesh.proto \
        $'latitude_i: 123456789\nlongitude_i: -234567890\naltitude: 321\nprecision_bits: 16' \
        'latitude_i: 123456789' 'longitude_i: -234567890' 'altitude: 321' 'precision_bits: 16'

    check_message "$version_dir" "$version" Telemetry meshtastic/telemetry.proto \
        $'device_metrics { battery_level: 87 voltage: 4.1 uptime_seconds: 900 }' \
        'device_metrics {' 'battery_level: 87' 'voltage: 4.1' 'uptime_seconds: 900'

    check_message "$version_dir" "$version" User meshtastic/mesh.proto \
        $'id: "!12345678" long_name: "Synthetic Node" short_name: "SYN"' \
        'id: "!12345678"' 'long_name: "Synthetic Node"' 'short_name: "SYN"'

    check_message "$version_dir" "$version" MapReport meshtastic/mqtt.proto \
        $'long_name: "Synthetic Node" short_name: "SYN" firmware_version: "fixture"' \
        'long_name: "Synthetic Node"' 'short_name: "SYN"' 'firmware_version: "fixture"'

    printf 'OK: %s (%s): Position, Telemetry, User e MapReport passaram encode/decode/round-trip.\n' "$version" "$actual_commit"
done

printf 'OK: matriz de compatibilidade concluída nas revisões fixadas.\n'
printf 'LIMITE: fixtures sintéticos; não comprova compatibilidade de firmware, criptografia ou entrega LoRa real.\n'
