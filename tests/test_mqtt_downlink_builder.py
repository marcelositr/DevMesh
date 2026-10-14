import base64
import struct
import unittest

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

    def test_blocks_public_preset_channel(self):
        with self.assertRaisesRegex(ValueError, "Canal público"):
            self.build(channel_name="LongFast")

    def test_expands_default_psk_short_code(self):
        expanded = effective_psk("AQ==")
        self.assertEqual(len(expanded), 16)
        self.assertEqual(expanded, base64.b64decode("1PG7OiApB1nwvP+rz05pAQ=="))

    def test_rejects_disabled_encryption(self):
        with self.assertRaisesRegex(ValueError, "sem criptografia"):
            effective_psk("")

    def test_rejects_invalid_gateway_id(self):
        with self.assertRaisesRegex(ValueError, "Gateway ID"):
            self.build(gateway_id="radio-real")

    def test_rejects_sender_id_matching_local_radio(self):
        with self.assertRaisesRegex(ValueError, "não pode ser o ID do rádio local"):
            self.build(sender_id=self.local_id)

    def test_rejects_gateway_id_matching_local_radio(self):
        with self.assertRaisesRegex(ValueError, "gateway ID não pode ser o ID do rádio local"):
            self.build(gateway_id="!a35aa590")


if __name__ == "__main__":
    unittest.main()
