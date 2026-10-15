import unittest

from scripts.audit_mqtt_capture import classify_message, valid_topic_filter
from meshtastic.protobuf import mqtt_pb2


class ReadOnlyMqttAuditTests(unittest.TestCase):
    def test_classifies_encrypted_envelope_without_exposing_identifiers(self):
        envelope = mqtt_pb2.ServiceEnvelope()
        envelope.channel_id = "PRIVATE_SYNTHETIC"
        envelope.gateway_id = "!deadbeef"
        envelope.packet.encrypted = b"synthetic-ciphertext"
        self.assertEqual(
            classify_message("msh/2/e/PRIVATE_SYNTHETIC/!deadbeef", envelope.SerializeToString()),
            ("encrypted_topic", "encrypted_envelope"),
        )

    def test_rejects_envelope_missing_required_metadata(self):
        envelope = mqtt_pb2.ServiceEnvelope()
        envelope.packet.encrypted = b"synthetic-ciphertext"
        self.assertEqual(
            classify_message("msh/2/e/PRIVATE_SYNTHETIC/!deadbeef", envelope.SerializeToString()),
            ("encrypted_topic", "invalid_envelope"),
        )

    def test_classifies_map_topics_as_opaque(self):
        self.assertEqual(
            classify_message("msh/2/map/region", b"synthetic-map-payload"),
            ("map_topic", "opaque_payload"),
        )

    def test_classifies_other_meshtastic_topics_as_opaque(self):
        self.assertEqual(
            classify_message("msh/2/c/LongFast/!deadbeef", b"synthetic-payload"),
            ("other_meshtastic_topic", "opaque_payload"),
        )

    def test_classifies_non_meshtastic_topics_as_opaque(self):
        self.assertEqual(
            classify_message("other/topic", b"synthetic-payload"),
            ("other_topic", "opaque_payload"),
        )

    def test_validates_mqtt_topic_filter_wildcards(self):
        for topic in ("msh/#", "msh/+/LongFast", "msh/2/e/+/+"):
            with self.subTest(topic=topic):
                self.assertTrue(valid_topic_filter(topic))
        for topic in ("", "msh/abc+", "msh/#/extra", "msh/ab#"):
            with self.subTest(topic=topic):
                self.assertFalse(valid_topic_filter(topic))


if __name__ == "__main__":
    unittest.main()
