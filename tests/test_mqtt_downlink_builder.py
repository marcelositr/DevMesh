import base64
import os
import subprocess
import sys
import struct
import tempfile
import unittest
from pathlib import Path

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from meshtastic.protobuf import mesh_pb2, mqtt_pb2, portnums_pb2

from scripts.build_mqtt_downlink import (
    build_envelope,
    channel_hash,
    effective_psk,
)


class DownlinkBuilderTests(unittest.TestCase):
    def setUp(self):
        self.key = b"devmesh-test-key"
        self.key_b64 = base64.b64encode(self.key).decode("ascii")
        self.local_id = 0xA35AA590

    def build(self, **overrides):
        values = {
            "text": "Teste isolado",
            "channel_name": "ITUVERAVA",
            "psk_base64": self.key_b64,
            "sender_id": 0x7F4A91C2,
            "local_node_id": self.local_id,
            "gateway_id": "!deadbeef",
            "packet_id": 0x10203040,
        }
        values.update(overrides)
        return build_envelope(**values)

    def test_builds_valid_envelope_and_decryptable_text_packet(self):
        topic, payload = self.build()
        envelope = mqtt_pb2.ServiceEnvelope()
        envelope.ParseFromString(payload)
        self.assertEqual(topic, "msh/2/e/ITUVERAVA/!deadbeef")
        self.assertEqual(envelope.channel_id, "ITUVERAVA")
        self.assertEqual(envelope.gateway_id, "!deadbeef")
        packet = envelope.packet
        self.assertEqual(getattr(packet, "from"), 0x7F4A91C2)
        self.assertEqual(packet.id, 0x10203040)
        self.assertEqual(packet.channel, channel_hash("ITUVERAVA", self.key))
        self.assertTrue(packet.HasField("encrypted"))

        nonce = struct.pack("<QII", packet.id, getattr(packet, "from"), 0)
        decryptor = Cipher(algorithms.AES(self.key), modes.CTR(nonce)).decryptor()
        plaintext = decryptor.update(packet.encrypted) + decryptor.finalize()
        data = mesh_pb2.Data()
        data.ParseFromString(plaintext)
        self.assertEqual(data.portnum, portnums_pb2.TEXT_MESSAGE_APP)
        self.assertEqual(data.payload, "Teste isolado".encode("utf-8"))

    def test_supports_custom_and_regional_root_topics(self):
        topic, _ = self.build(root_topic="msh/ANZ")
        self.assertEqual(topic, "msh/ANZ/2/e/ITUVERAVA/!deadbeef")

    def test_rejects_invalid_root_topic(self):
        for root_topic in ("", "/msh", "msh/", "msh//ANZ", "msh/+", "msh/#", "msh/ANZ\n"):
            with self.subTest(root_topic=repr(root_topic)):
                with self.assertRaisesRegex(ValueError, "Tópico raiz MQTT inválido"):
                    self.build(root_topic=root_topic)

    def test_blocks_public_preset_channel(self):
        with self.assertRaisesRegex(ValueError, "Canal público"):
            self.build(channel_name="LongFast")

    def test_rejects_short_index_or_padded_psk_for_private_channel(self):
        for raw_key in (b"\\x01", b"short-key", bytes(range(15))):
            with self.subTest(raw_length=len(raw_key)):
                encoded = base64.b64encode(raw_key).decode("ascii")
                with self.assertRaisesRegex(ValueError, "16 ou 32 bytes"):
                    self.build(psk_base64=encoded)

    def test_rejects_mqtt_wildcards_in_channel_name(self):
        for channel_name in ("PRIVATE+", "PRIVATE#"):
            with self.subTest(channel_name=channel_name):
                with self.assertRaisesRegex(ValueError, "tópico MQTT"):
                    self.build(channel_name=channel_name)

    def test_rejects_slashes_and_control_characters_in_channel_name(self):
        for channel_name in ("PRIVATE/TEST", "PRIVATE\nTEST", "PRIVATE\x7fTEST"):
            with self.subTest(channel_name=repr(channel_name)):
                with self.assertRaisesRegex(ValueError, "tópico MQTT"):
                    self.build(channel_name=channel_name)

    def test_rejects_text_over_utf8_byte_limit(self):
        with self.assertRaisesRegex(ValueError, "180 bytes UTF-8"):
            self.build(text="ç" * 91)

    def test_rejects_invalid_hop_limit(self):
        for hop_limit in (0, 8):
            with self.subTest(hop_limit=hop_limit):
                with self.assertRaisesRegex(ValueError, "hop_limit"):
                    self.build(hop_limit=hop_limit)

    def test_expands_default_psk_short_code(self):
        expanded = effective_psk("AQ==")
        self.assertEqual(len(expanded), 16)
        self.assertEqual(expanded, base64.b64decode("1PG7OiApB1nwvP+rz05pAQ=="))

    def test_rejects_disabled_encryption(self):
        with self.assertRaisesRegex(ValueError, "sem criptografia"):
            effective_psk("")

    def test_rejects_invalid_base64_psk(self):
        with self.assertRaisesRegex(ValueError, "PSK inválida"):
            effective_psk("not-base64!")

    def test_rejects_psk_longer_than_32_bytes(self):
        encoded = base64.b64encode(bytes(range(33))).decode("ascii")
        with self.assertRaisesRegex(ValueError, "no máximo 32 bytes"):
            effective_psk(encoded)

    def test_expands_psk_lengths_to_supported_aes_keys(self):
        for raw_key, expected_length in (
            (bytes(range(2)), 16),
            (bytes(range(15)), 16),
            (bytes(range(16)), 16),
            (bytes(range(17)), 32),
            (bytes(range(31)), 32),
            (bytes(range(32)), 32),
        ):
            with self.subTest(raw_length=len(raw_key)):
                encoded = base64.b64encode(raw_key).decode("ascii")
                self.assertEqual(len(effective_psk(encoded)), expected_length)

    def test_rejects_invalid_gateway_id(self):
        with self.assertRaisesRegex(ValueError, "Gateway ID"):
            self.build(gateway_id="radio-real")

    def test_rejects_sender_id_matching_local_radio(self):
        with self.assertRaisesRegex(ValueError, "não pode ser o ID do rádio local"):
            self.build(sender_id=self.local_id)

    def test_rejects_gateway_id_matching_local_radio(self):
        with self.assertRaisesRegex(ValueError, "gateway ID não pode ser o ID do rádio local"):
            self.build(gateway_id="!a35aa590")


    def test_cli_reads_sensitive_message_from_stdin(self):
        secret_text = "private synthetic payload must stay local"
        with tempfile.TemporaryDirectory() as directory:
            output_path = Path(directory) / "envelope.bin"
            env = os.environ.copy()
            env["DEVMESH_CHANNEL_PSK_B64"] = self.key_b64
            result = subprocess.run(
                [
                    sys.executable,
                    "scripts/build_mqtt_downlink.py",
                    "--channel", "PRIVATE_TEST",
                    "--local-node-id", str(self.local_id),
                    "--sender-id", "2135587861",
                    "--gateway-id", "!deadbeef",
                    "--packet-id", "270544960",
                    "--text-stdin",
                    "--output", str(output_path),
                ],
                cwd=Path(__file__).resolve().parents[1],
                env=env,
                input=secret_text + "\n",
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(output_path.is_file())
            combined_output = result.stdout + result.stderr
            self.assertNotIn(self.key_b64, combined_output)
            self.assertNotIn(secret_text, combined_output)

            envelope = mqtt_pb2.ServiceEnvelope()
            envelope.ParseFromString(output_path.read_bytes())
            packet = envelope.packet
            nonce = struct.pack("<QII", packet.id, getattr(packet, "from"), 0)
            decryptor = Cipher(algorithms.AES(self.key), modes.CTR(nonce)).decryptor()
            plaintext = decryptor.update(packet.encrypted) + decryptor.finalize()
            data = mesh_pb2.Data()
            data.ParseFromString(plaintext)
            self.assertEqual(data.payload.decode("utf-8"), secret_text)

    def test_cli_does_not_overwrite_existing_output(self):
        with tempfile.TemporaryDirectory() as directory:
            output_path = Path(directory) / "envelope.bin"
            original_content = b"preserve this file"
            output_path.write_bytes(original_content)
            env = os.environ.copy()
            env["DEVMESH_CHANNEL_PSK_B64"] = self.key_b64
            result = subprocess.run(
                [
                    sys.executable,
                    "scripts/build_mqtt_downlink.py",
                    "--channel", "PRIVATE_TEST",
                    "--local-node-id", str(self.local_id),
                    "--sender-id", "2135587861",
                    "--gateway-id", "!deadbeef",
                    "--packet-id", "270544960",
                    "--output", str(output_path),
                ],
                cwd=Path(__file__).resolve().parents[1],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 2)
            self.assertEqual(output_path.read_bytes(), original_content)
            self.assertIn("não foi sobrescrito", result.stderr)

    def test_cli_does_not_echo_invalid_key(self):
        secret_invalid_key = "!synthetic-secret-that-must-not-be-logged"
        with tempfile.TemporaryDirectory() as directory:
            env = os.environ.copy()
            env["DEVMESH_CHANNEL_PSK_B64"] = secret_invalid_key
            result = subprocess.run(
                [
                    sys.executable,
                    "scripts/build_mqtt_downlink.py",
                    "--channel", "PRIVATE_TEST",
                    "--local-node-id", str(self.local_id),
                    "--sender-id", "2135587861",
                    "--gateway-id", "!deadbeef",
                    "--packet-id", "270544960",
                    "--output", str(Path(directory) / "envelope.bin"),
                ],
                cwd=Path(__file__).resolve().parents[1],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 2)
            self.assertNotIn(secret_invalid_key, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
