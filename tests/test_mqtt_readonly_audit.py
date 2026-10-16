import json
import os
import sys
import unittest
from contextlib import redirect_stdout
from io import StringIO
from unittest.mock import patch

from scripts.audit_mqtt_capture import classify_message, main, valid_topic_filter
from meshtastic.protobuf import mqtt_pb2, portnums_pb2


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

    def test_classifies_synthetic_decoded_position_by_portnum_only(self):
        envelope = mqtt_pb2.ServiceEnvelope()
        envelope.channel_id = "PRIVATE_SYNTHETIC"
        envelope.gateway_id = "!deadbeef"
        envelope.packet.decoded.portnum = portnums_pb2.PortNum.POSITION_APP
        envelope.packet.decoded.payload = b"synthetic-position-payload"

        self.assertEqual(
            classify_message("msh/2/e/PRIVATE_SYNTHETIC/!deadbeef", envelope.SerializeToString()),
            ("encrypted_topic", "decoded_position_app"),
        )

    def test_classifies_synthetic_decoded_telemetry_by_portnum_only(self):
        envelope = mqtt_pb2.ServiceEnvelope()
        envelope.channel_id = "PRIVATE_SYNTHETIC"
        envelope.gateway_id = "!deadbeef"
        envelope.packet.decoded.portnum = portnums_pb2.PortNum.TELEMETRY_APP
        envelope.packet.decoded.payload = b"synthetic-telemetry-payload"

        self.assertEqual(
            classify_message("msh/2/e/PRIVATE_SYNTHETIC/!deadbeef", envelope.SerializeToString()),
            ("encrypted_topic", "decoded_telemetry_app"),
        )

    def test_classifies_unknown_future_portnum_without_exposing_value(self):
        envelope = mqtt_pb2.ServiceEnvelope()
        envelope.channel_id = "PRIVATE_SYNTHETIC"
        envelope.gateway_id = "!deadbeef"
        envelope.packet.decoded.portnum = 65535
        envelope.packet.decoded.payload = b"synthetic-future-payload"

        self.assertEqual(
            classify_message("msh/2/e/PRIVATE_SYNTHETIC/!deadbeef", envelope.SerializeToString()),
            ("encrypted_topic", "decoded_unknown_portnum"),
        )

    def test_classifies_map_report_position_without_exposing_coordinates(self):
        envelope = mqtt_pb2.ServiceEnvelope()
        envelope.channel_id = "PRIVATE_SYNTHETIC"
        envelope.gateway_id = "!deadbeef"
        envelope.packet.decoded.portnum = portnums_pb2.PortNum.MAP_REPORT_APP

        report = mqtt_pb2.MapReport()
        report.latitude_i = 123456789
        report.longitude_i = -234567890
        envelope.packet.decoded.payload = report.SerializeToString()

        self.assertEqual(
            classify_message("msh/2/map/region", envelope.SerializeToString()),
            ("map_topic", "map_report_position_present"),
        )

    def test_classifies_map_report_without_position_values(self):
        envelope = mqtt_pb2.ServiceEnvelope()
        envelope.channel_id = "PRIVATE_SYNTHETIC"
        envelope.gateway_id = "!deadbeef"
        envelope.packet.decoded.portnum = portnums_pb2.PortNum.MAP_REPORT_APP
        envelope.packet.decoded.payload = mqtt_pb2.MapReport().SerializeToString()

        self.assertEqual(
            classify_message("msh/2/map/region", envelope.SerializeToString()),
            ("map_topic", "map_report_position_zero_or_absent"),
        )

    def test_rejects_malformed_map_report_without_exposing_payload(self):
        envelope = mqtt_pb2.ServiceEnvelope()
        envelope.channel_id = "PRIVATE_SYNTHETIC"
        envelope.gateway_id = "!deadbeef"
        envelope.packet.decoded.portnum = portnums_pb2.PortNum.MAP_REPORT_APP
        envelope.packet.decoded.payload = b"\\xff"

        self.assertEqual(
            classify_message("msh/2/map/region", envelope.SerializeToString()),
            ("map_topic", "invalid_map_report"),
        )

    def test_keeps_unrecognized_map_payload_opaque(self):
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


    def test_cli_rejects_out_of_range_limits_before_connecting(self):
        invalid_arguments = (
            ["--port", "0"],
            ["--seconds", "301"],
            ["--max-messages", "10001"],
        )
        for arguments in invalid_arguments:
            with self.subTest(arguments=arguments):
                with patch.object(sys, "argv", ["audit_mqtt_capture.py", *arguments]):
                    with self.assertRaises(SystemExit):
                        main()

    def test_cli_enables_system_ca_tls_when_requested(self):
        from scripts import audit_mqtt_capture

        class ReasonCode:
            is_failure = False

        class FakeClient:
            on_connect = None
            on_subscribe = None
            on_disconnect = None
            on_message = None

            def __init__(self):
                self.tls_enabled = False

            def tls_set(self):
                self.tls_enabled = True

            def connect(self, host, port, keepalive):
                return None

            def loop_start(self):
                self.on_connect(self, None, None, ReasonCode(), None)

            def subscribe(self, topic, qos):
                self.on_subscribe(self, None, 1, [ReasonCode()], None)
                return audit_mqtt_capture.mqtt.MQTT_ERR_SUCCESS, 1

            def disconnect(self):
                return None

            def loop_stop(self):
                return None

        fake_client = FakeClient()
        output = StringIO()
        with patch.object(sys, "argv", ["audit_mqtt_capture.py", "--tls", "--seconds", "1"]):
            with patch.object(audit_mqtt_capture.mqtt, "Client", return_value=fake_client):
                with patch.dict(os.environ, {}, clear=True):
                    with redirect_stdout(output):
                        self.assertEqual(main(), 0)

        self.assertTrue(fake_client.tls_enabled)
        self.assertTrue(json.loads(output.getvalue())["subscription_accepted"])

    def test_cli_rejects_unpaired_mqtt_credentials(self):
        credentials = {
            "DEVMESH_MQTT_USERNAME": "synthetic-user",
            "DEVMESH_MQTT_PASSWORD": "",
        }
        with patch.object(sys, "argv", ["audit_mqtt_capture.py"]):
            with patch.dict(os.environ, credentials):
                with self.assertRaisesRegex(SystemExit, "configure usuário e senha juntos"):
                    main()


    def test_cli_reports_aggregates_without_leaking_message_identifiers(self):
        from scripts import audit_mqtt_capture

        class ReasonCode:
            is_failure = False

        class Message:
            topic = "msh/2/e/PRIVATE_SYNTHETIC/!deadbeef"
            payload = mqtt_pb2.ServiceEnvelope(
                channel_id="PRIVATE_SYNTHETIC",
                gateway_id="!deadbeef",
            ).SerializeToString()

        class FakeClient:
            on_connect = None
            on_subscribe = None
            on_message = None

            def username_pw_set(self, username, password):
                raise AssertionError("unexpected credentials in this test")

            def connect(self, host, port, keepalive):
                self.connection = (host, port, keepalive)

            def loop_start(self):
                self.on_connect(self, None, None, ReasonCode(), None)
                # Simulate queued callbacks arriving after the cap is reached.
                self.on_message(self, None, Message())
                self.on_message(self, None, Message())

            def subscribe(self, topic, qos):
                self.on_subscribe(self, None, 1, [ReasonCode()], None)
                return audit_mqtt_capture.mqtt.MQTT_ERR_SUCCESS, 1

            def disconnect(self):
                return None

            def loop_stop(self):
                return None

            def publish(self, *args, **kwargs):
                raise AssertionError("audit must never publish")

        output = StringIO()
        with patch.object(sys, "argv", ["audit_mqtt_capture.py", "--seconds", "1",
                                        "--max-messages", "1"]):
            with patch.object(audit_mqtt_capture.mqtt, "Client", return_value=FakeClient()):
                with patch.dict(os.environ, {}, clear=True):
                    with redirect_stdout(output):
                        self.assertEqual(main(), 0)

        rendered = output.getvalue()
        report = json.loads(rendered)
        self.assertEqual(report["messages_received"], 1)
        self.assertEqual(report["payloads_saved"], False)
        self.assertEqual(report["mqtt_publish_performed"], False)
        self.assertNotIn("PRIVATE_SYNTHETIC", rendered)
        self.assertNotIn("deadbeef", rendered)
        self.assertNotIn("msh/2/e/", rendered)

    def test_cli_fails_when_mqtt_disconnects_unexpectedly(self):
        from scripts import audit_mqtt_capture

        class ReasonCode:
            def __init__(self, failed=False):
                self.is_failure = failed

        class FakeClient:
            on_connect = None
            on_disconnect = None
            on_subscribe = None
            on_message = None

            def connect(self, host, port, keepalive):
                return None

            def loop_start(self):
                self.on_connect(self, None, None, ReasonCode(), None)
                self.on_disconnect(self, None, None, ReasonCode(failed=True), None)

            def subscribe(self, topic, qos):
                self.on_subscribe(self, None, 1, [ReasonCode()], None)
                return audit_mqtt_capture.mqtt.MQTT_ERR_SUCCESS, 1

            def disconnect(self):
                return None

            def loop_stop(self):
                return None

            def publish(self, *args, **kwargs):
                raise AssertionError("audit must never publish")

        output = StringIO()
        with patch.object(sys, "argv", ["audit_mqtt_capture.py", "--seconds", "1"]):
            with patch.object(audit_mqtt_capture.mqtt, "Client", return_value=FakeClient()):
                with patch.dict(os.environ, {}, clear=True):
                    with redirect_stdout(output):
                        self.assertEqual(main(), 2)

        report = json.loads(output.getvalue())
        self.assertFalse(report["connected"])
        self.assertFalse(report["subscription_accepted"])
        self.assertFalse(report["mqtt_publish_performed"])


    def test_cli_fails_when_connection_drops_with_normal_reason_code(self):
        from scripts import audit_mqtt_capture

        class ReasonCode:
            def __init__(self, failed=False):
                self.is_failure = failed

        class FakeClient:
            on_connect = None
            on_disconnect = None
            on_subscribe = None
            on_message = None

            def connect(self, host, port, keepalive):
                return None

            def loop_start(self):
                self.on_connect(self, None, None, ReasonCode(), None)
                self.on_subscribe(self, None, 1, [ReasonCode()], None)
                self.on_disconnect(self, None, None, ReasonCode(), None)

            def subscribe(self, topic, qos):
                return audit_mqtt_capture.mqtt.MQTT_ERR_SUCCESS, 1

            def disconnect(self):
                return None

            def loop_stop(self):
                return None

            def publish(self, *args, **kwargs):
                raise AssertionError("audit must never publish")

        output = StringIO()
        with patch.object(sys, "argv", ["audit_mqtt_capture.py", "--seconds", "1"]):
            with patch.object(audit_mqtt_capture.mqtt, "Client", return_value=FakeClient()):
                with patch.dict(os.environ, {}, clear=True):
                    with redirect_stdout(output):
                        self.assertEqual(main(), 2)

        report = json.loads(output.getvalue())
        self.assertFalse(report["connected"])
        self.assertFalse(report["subscription_accepted"])
        self.assertFalse(report["mqtt_publish_performed"])

    def test_cli_fails_when_broker_rejects_connection(self):
        from scripts import audit_mqtt_capture

        class ReasonCode:
            is_failure = True

        class FakeClient:
            on_connect = None
            on_disconnect = None
            on_subscribe = None
            on_message = None

            def connect(self, host, port, keepalive):
                return None

            def loop_start(self):
                self.on_connect(self, None, None, ReasonCode(), None)

            def disconnect(self):
                return None

            def loop_stop(self):
                return None

            def publish(self, *args, **kwargs):
                raise AssertionError("audit must never publish")

        output = StringIO()
        with patch.object(sys, "argv", ["audit_mqtt_capture.py", "--seconds", "1"]):
            with patch.object(audit_mqtt_capture.mqtt, "Client", return_value=FakeClient()):
                with patch.dict(os.environ, {}, clear=True):
                    with redirect_stdout(output):
                        self.assertEqual(main(), 2)

        report = json.loads(output.getvalue())
        self.assertFalse(report["connected"])
        self.assertFalse(report["subscription_accepted"])

    def test_cli_fails_when_broker_rejects_subscription(self):
        from scripts import audit_mqtt_capture

        class ReasonCode:
            def __init__(self, failed=False):
                self.is_failure = failed

        class FakeClient:
            on_connect = None
            on_disconnect = None
            on_subscribe = None
            on_message = None

            def connect(self, host, port, keepalive):
                return None

            def loop_start(self):
                self.on_connect(self, None, None, ReasonCode(), None)

            def subscribe(self, topic, qos):
                self.on_subscribe(self, None, 1, [ReasonCode(failed=True)], None)
                return audit_mqtt_capture.mqtt.MQTT_ERR_SUCCESS, 1

            def disconnect(self):
                return None

            def loop_stop(self):
                return None

            def publish(self, *args, **kwargs):
                raise AssertionError("audit must never publish")

        output = StringIO()
        with patch.object(sys, "argv", ["audit_mqtt_capture.py", "--seconds", "1"]):
            with patch.object(audit_mqtt_capture.mqtt, "Client", return_value=FakeClient()):
                with patch.dict(os.environ, {}, clear=True):
                    with redirect_stdout(output):
                        self.assertEqual(main(), 2)

        report = json.loads(output.getvalue())
        self.assertTrue(report["connected"])
        self.assertFalse(report["subscription_accepted"])


    def test_cli_fails_when_local_subscribe_request_is_rejected(self):
        from scripts import audit_mqtt_capture

        class ReasonCode:
            is_failure = False

        class FakeClient:
            on_connect = None
            on_subscribe = None
            on_message = None

            def connect(self, host, port, keepalive):
                return None

            def loop_start(self):
                self.on_connect(self, None, None, ReasonCode(), None)

            def subscribe(self, topic, qos):
                return audit_mqtt_capture.mqtt.MQTT_ERR_NO_CONN, 1

            def disconnect(self):
                return None

            def loop_stop(self):
                return None

            def publish(self, *args, **kwargs):
                raise AssertionError("audit must never publish")

        output = StringIO()
        with patch.object(sys, "argv", ["audit_mqtt_capture.py", "--seconds", "1"]):
            with patch.object(audit_mqtt_capture.mqtt, "Client", return_value=FakeClient()):
                with patch.dict(os.environ, {}, clear=True):
                    with redirect_stdout(output):
                        self.assertEqual(main(), 2)

        report = json.loads(output.getvalue())
        self.assertTrue(report["connected"])
        self.assertFalse(report["subscription_accepted"])
        self.assertFalse(report["mqtt_publish_performed"])


    def test_cli_never_emits_map_report_coordinates(self):
        from scripts import audit_mqtt_capture

        class ReasonCode:
            is_failure = False

        report_payload = mqtt_pb2.MapReport(
            latitude_i=123456789,
            longitude_i=-234567890,
        ).SerializeToString()
        envelope = mqtt_pb2.ServiceEnvelope(
            channel_id="PRIVATE_SYNTHETIC",
            gateway_id="!deadbeef",
        )
        envelope.packet.decoded.portnum = portnums_pb2.PortNum.MAP_REPORT_APP
        envelope.packet.decoded.payload = report_payload

        class Message:
            topic = "msh/2/map/PRIVATE_SYNTHETIC"
            payload = envelope.SerializeToString()

        class FakeClient:
            on_connect = None
            on_subscribe = None
            on_disconnect = None
            on_message = None

            def connect(self, host, port, keepalive):
                return None

            def loop_start(self):
                self.on_connect(self, None, None, ReasonCode(), None)
                self.on_message(self, None, Message())

            def subscribe(self, topic, qos):
                self.on_subscribe(self, None, 1, [ReasonCode()], None)
                return audit_mqtt_capture.mqtt.MQTT_ERR_SUCCESS, 1

            def disconnect(self):
                return None

            def loop_stop(self):
                return None

            def publish(self, *args, **kwargs):
                raise AssertionError("audit must never publish")

        output = StringIO()
        with patch.object(sys, "argv", ["audit_mqtt_capture.py", "--seconds", "1",
                                        "--max-messages", "1", "--topic", "msh/#"]):
            with patch.object(audit_mqtt_capture.mqtt, "Client", return_value=FakeClient()):
                with patch.dict(os.environ, {}, clear=True):
                    with redirect_stdout(output):
                        self.assertEqual(main(), 0)

        rendered = output.getvalue()
        result = json.loads(rendered)
        self.assertEqual(result["messages_received"], 1)
        self.assertEqual(result["message_statuses"], {"map_report_position_present": 1})
        self.assertNotIn("123456789", rendered)
        self.assertNotIn("-234567890", rendered)
        self.assertNotIn("PRIVATE_SYNTHETIC", rendered)
        self.assertNotIn("deadbeef", rendered)


if __name__ == "__main__":
    unittest.main()
