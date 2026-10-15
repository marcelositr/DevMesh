#!/usr/bin/env python3
"""Observe existing Meshtastic MQTT traffic without publishing or storing payloads.

The tool subscribes for a bounded period and reports aggregate metadata only.
It never prints topic names, node IDs, channel names, credentials, coordinates,
or payload bytes, and it never publishes MQTT messages.
"""

from __future__ import annotations

import argparse
import json
import os
import threading
import time
from collections import Counter

import paho.mqtt.client as mqtt
from meshtastic.protobuf import mqtt_pb2, portnums_pb2

DEFAULT_TOPIC = "msh/#"


def valid_topic_filter(topic: str) -> bool:
    if not topic or "\x00" in topic:
        return False
    levels = topic.split("/")
    for index, level in enumerate(levels):
        if "+" in level and level != "+":
            return False
        if "#" in level and (level != "#" or index != len(levels) - 1):
            return False
    return True


def classify_message(topic: str, payload: bytes) -> tuple[str, str]:
    """Return a privacy-safe family/status pair without exposing message data."""
    if topic.startswith("msh/2/e/"):
        envelope = mqtt_pb2.ServiceEnvelope()
        try:
            envelope.ParseFromString(payload)
        except (ValueError, TypeError):
            return "encrypted_topic", "invalid_protobuf"

        if not envelope.HasField("packet") or not envelope.channel_id or not envelope.gateway_id:
            return "encrypted_topic", "invalid_envelope"

        packet = envelope.packet
        if packet.encrypted:
            return "encrypted_topic", "encrypted_envelope"
        if packet.HasField("decoded"):
            try:
                portnum = portnums_pb2.PortNum.Name(packet.decoded.portnum)
            except (ValueError, KeyError):
                portnum = "UNKNOWN_PORTNUM"
            return "encrypted_topic", f"decoded_{portnum.lower()}"
        return "encrypted_topic", "packet_without_payload"

    if topic.startswith("msh/2/map/"):
        return "map_topic", "opaque_payload"
    if topic.startswith("msh/"):
        return "other_meshtastic_topic", "opaque_payload"
    return "other_topic", "opaque_payload"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1", help="Broker autorizado; padrão: 127.0.0.1.")
    parser.add_argument("--port", type=int, default=1883, help="Porta MQTT; padrão: 1883.")
    parser.add_argument("--topic", default=DEFAULT_TOPIC, help="Filtro de leitura; padrão: msh/#.")
    parser.add_argument("--seconds", type=int, default=30, help="Duração da observação (1 a 300 s).")
    parser.add_argument("--max-messages", type=int, default=500, help="Limite de mensagens (1 a 10000).")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not 1 <= args.port <= 65535:
        raise SystemExit("FALHA: porta fora do intervalo válido.")
    if not 1 <= args.seconds <= 300:
        raise SystemExit("FALHA: --seconds deve ficar entre 1 e 300.")
    if not 1 <= args.max_messages <= 10000:
        raise SystemExit("FALHA: --max-messages deve ficar entre 1 e 10000.")
    if not valid_topic_filter(args.topic):
        raise SystemExit("FALHA: filtro MQTT inválido.")

    username = os.environ.get("DEVMESH_MQTT_USERNAME")
    password = os.environ.get("DEVMESH_MQTT_PASSWORD")
    if bool(username) != bool(password):
        raise SystemExit("FALHA: configure usuário e senha juntos, ou deixe ambos ausentes.")

    topic_families: Counter[str] = Counter()
    message_statuses: Counter[str] = Counter()
    total_bytes = 0
    received = 0
    connected = threading.Event()
    subscription_ready = threading.Event()
    finished = threading.Event()
    connection_failed = threading.Event()

    client = mqtt.Client(
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
        client_id="devmesh-readonly-audit",
        protocol=mqtt.MQTTv311,
    )
    if username:
        client.username_pw_set(username, password)

    def on_connect(client, userdata, flags, reason_code, properties):
        if reason_code.is_failure:
            connection_failed.set()
            finished.set()
            return
        connected.set()
        result, _ = client.subscribe(args.topic, qos=0)
        if result != mqtt.MQTT_ERR_SUCCESS:
            connection_failed.set()
            finished.set()

    def on_subscribe(client, userdata, mid, reason_code_list, properties):
        if any(reason_code.is_failure for reason_code in reason_code_list):
            connection_failed.set()
            finished.set()
            return
        subscription_ready.set()

    def on_message(client, userdata, message):
        nonlocal total_bytes, received
        family, status = classify_message(message.topic, message.payload)
        topic_families[family] += 1
        message_statuses[status] += 1
        total_bytes += len(message.payload)
        received += 1
        if received >= args.max_messages:
            finished.set()

    client.on_connect = on_connect
    client.on_subscribe = on_subscribe
    client.on_message = on_message

    try:
        client.connect(args.host, args.port, keepalive=15)
        client.loop_start()
        deadline = time.monotonic() + args.seconds
        while time.monotonic() < deadline and not finished.wait(0.1):
            if connection_failed.is_set():
                break
        if not connected.is_set() and not connection_failed.is_set():
            connection_failed.set()
    except (OSError, mqtt.MQTTException):
        connection_failed.set()
    finally:
        try:
            client.disconnect()
        finally:
            client.loop_stop()

    result = {
        "mode": "read_only",
        "connected": connected.is_set() and not connection_failed.is_set(),
        "subscription_accepted": subscription_ready.is_set() and not connection_failed.is_set(),
        "observation_seconds_limit": args.seconds,
        "message_limit": args.max_messages,
        "messages_received": received,
        "payload_bytes_total": total_bytes,
        "topic_families": dict(sorted(topic_families.items())),
        "message_statuses": dict(sorted(message_statuses.items())),
        "payloads_saved": False,
        "mqtt_publish_performed": False,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 2 if connection_failed.is_set() else 0


if __name__ == "__main__":
    raise SystemExit(main())
