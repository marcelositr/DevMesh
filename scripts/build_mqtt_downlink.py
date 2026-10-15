#!/usr/bin/env python3
"""Build one encrypted Meshtastic MQTT downlink envelope for a private test channel.

This tool only writes a protobuf envelope to a local file. It never connects to
MQTT or transmits over LoRa. Keep channel PSKs out of command-line arguments,
logs, source control, and issue reports.
"""

from __future__ import annotations

import argparse
import base64
import getpass
import os
import re
import struct
import sys
from pathlib import Path

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from meshtastic.protobuf import mesh_pb2, mqtt_pb2, portnums_pb2

DEFAULT_PSK = base64.b64decode("1PG7OiApB1nwvP+rz05pAQ==")
PUBLIC_PRESET_CHANNELS = {
    "LongFast", "LongSlow", "LongModerate", "LongTurbo",
    "MediumFast", "MediumSlow", "ShortFast", "ShortSlow",
    "ShortTurbo", "LongMod",
}


def effective_psk(encoded: str) -> bytes:
    """Match firmware channel PSK expansion for standard AES-CTR channels."""
    try:
        raw = base64.b64decode(encoded, validate=True)
    except Exception as exc:
        raise ValueError("PSK inválida: informe uma chave em Base64.") from exc

    if len(raw) == 0:
        raise ValueError("Canal sem criptografia não é permitido neste teste.")
    if len(raw) == 1:
        index = raw[0]
        if index == 0:
            raise ValueError("PSK 0 desativa a criptografia e não é permitida.")
        key = bytearray(DEFAULT_PSK)
        key[-1] = (key[-1] + index - 1) & 0xFF
        return bytes(key)
    if len(raw) < 16:
        return raw + bytes(16 - len(raw))
    if len(raw) == 16 or len(raw) == 32:
        return raw
    if len(raw) < 32:
        return raw + bytes(32 - len(raw))
    raise ValueError("A PSK deve ter no máximo 32 bytes.")


def xor_hash(data: bytes) -> int:
    result = 0
    for byte in data:
        result ^= byte
    return result


def channel_hash(channel_name: str, key: bytes) -> int:
    return xor_hash(channel_name.encode("utf-8")) ^ xor_hash(key)


def encrypt_channel_payload(key: bytes, sender_id: int, packet_id: int, plaintext: bytes) -> bytes:
    # Firmware CryptoEngine::initNonce: packet ID (u64 LE), sender (u32 LE), 4 zero bytes.
    nonce = struct.pack("<QII", packet_id, sender_id, 0)
    cipher = Cipher(algorithms.AES(key), modes.CTR(nonce))
    encryptor = cipher.encryptor()
    return encryptor.update(plaintext) + encryptor.finalize()


def build_envelope(
    *,
    text: str,
    channel_name: str,
    psk_base64: str,
    sender_id: int,
    local_node_id: int,
    gateway_id: str,
    packet_id: int,
    hop_limit: int = 3,
) -> tuple[str, bytes]:
    if (
        not channel_name
        or "/" in channel_name
        or "+" in channel_name
        or "#" in channel_name
        or any(ord(char) < 32 or ord(char) == 127 for char in channel_name)
    ):
        raise ValueError("Nome de canal inválido para um tópico MQTT.")
    if channel_name in PUBLIC_PRESET_CHANNELS:
        raise ValueError(
            "Canal público/preset bloqueado por segurança; use um canal privado de teste."
        )
    if not 1 <= local_node_id <= 0xFFFFFFFF:
        raise ValueError("O ID local deve ser um inteiro de 32 bits diferente de zero.")
    if not 1 <= sender_id <= 0xFFFFFFFF:
        raise ValueError("O ID de origem deve ser um inteiro de 32 bits diferente de zero.")
    if sender_id == local_node_id:
        raise ValueError("O ID de origem não pode ser o ID do rádio local.")
    if not 1 <= packet_id <= 0xFFFFFFFF:
        raise ValueError("O ID do pacote deve estar entre 1 e 2^32-1.")
    if not re.fullmatch(r"![0-9a-fA-F]{8}", gateway_id):
        raise ValueError("Gateway ID deve ter o formato ! seguido de 8 dígitos hexadecimais.")
    if gateway_id.lower() == f"!{local_node_id:08x}":
        raise ValueError("O gateway ID não pode ser o ID do rádio local.")
    if not 1 <= hop_limit <= 7:
        raise ValueError("hop_limit deve estar entre 1 e 7.")
    if not text or len(text.encode("utf-8")) > 180:
        raise ValueError("A mensagem deve ter entre 1 e 180 bytes UTF-8.")

    key = effective_psk(psk_base64)
    data = mesh_pb2.Data()
    data.portnum = portnums_pb2.TEXT_MESSAGE_APP
    data.payload = text.encode("utf-8")
    ciphertext = encrypt_channel_payload(key, sender_id, packet_id, data.SerializeToString())

    packet = mesh_pb2.MeshPacket()
    setattr(packet, "from", sender_id)
    packet.to = 0xFFFFFFFF
    packet.id = packet_id
    packet.channel = channel_hash(channel_name, key)
    packet.hop_limit = hop_limit
    packet.hop_start = hop_limit
    packet.encrypted = ciphertext

    envelope = mqtt_pb2.ServiceEnvelope()
    envelope.packet.CopyFrom(packet)
    envelope.channel_id = channel_name
    envelope.gateway_id = gateway_id
    topic = f"msh/2/e/{channel_name}/{gateway_id}"
    return topic, envelope.SerializeToString()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--channel", required=True, help="Nome exato do canal privado no rádio.")
    parser.add_argument("--local-node-id", required=True, type=lambda s: int(s, 0), help="ID do rádio local, decimal ou 0xHEX.")
    parser.add_argument("--sender-id", required=True, type=lambda s: int(s, 0), help="ID sintético, decimal ou 0xHEX.")
    parser.add_argument("--gateway-id", required=True, help="Gateway sintético, por exemplo !a1b2c3d4.")
    parser.add_argument("--packet-id", required=True, type=lambda s: int(s, 0), help="ID de pacote novo, decimal ou 0xHEX.")
    parser.add_argument("--text", default="Teste MQTT downlink DevMesh", help="Texto de teste.")
    parser.add_argument("--output", required=True, type=Path, help="Arquivo local para o envelope binário.")
    args = parser.parse_args()

    encoded_key = os.environ.get("DEVMESH_CHANNEL_PSK_B64")
    if not encoded_key:
        encoded_key = getpass.getpass("PSK Base64 do canal privado (entrada oculta): ").strip()

    try:
        topic, payload = build_envelope(
            text=args.text,
            channel_name=args.channel,
            psk_base64=encoded_key,
            sender_id=args.sender_id,
            local_node_id=args.local_node_id,
            gateway_id=args.gateway_id,
            packet_id=args.packet_id,
        )
    except (ValueError, TypeError) as exc:
        print(f"FALHA: {exc}", file=sys.stderr)
        return 2

    try:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("xb") as output_file:
            output_file.write(payload)
    except FileExistsError:
        print(
            f"FALHA: o arquivo de saída já existe e não foi sobrescrito: {args.output}",
            file=sys.stderr,
        )
        return 2
    except OSError as exc:
        print(f"FALHA: não foi possível gravar o envelope: {exc}", file=sys.stderr)
        return 2

    print(f"Envelope Protobuf cifrado criado: {args.output} ({len(payload)} bytes)")
    print(f"Tópico MQTT de destino: {topic}")
    print("Nenhuma conexão MQTT ou transmissão LoRa foi iniciada.")
    print("Use apenas canal privado de teste; confirme que o ID sintético não pertence a outro nó.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
