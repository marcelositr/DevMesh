#!/usr/bin/env python3
"""Add temporary AES-CTR interoperability cases to the pinned upstream test."""

from pathlib import Path
import sys

TEST_FUNCTION_ANCHOR = "void test_AES_CCM_partial_block_bounds(void)"
TEST_REGISTRATION_ANCHOR = "    RUN_TEST(test_AES_CTR);\n"

INTEROP_TEST = r"""
void test_DevMesh_AES_CTR_channel_interop(void)
{
    struct InteropCase {
        const char *plaintext;
        uint32_t fromNode;
        uint32_t packetId;
    };

    const InteropCase cases[] = {
        {"A", 0x23456789, 0x12345678},
        {"DevMesh private", 0x23456789, 0x12345679},
        {"0123456789ABCDEF", 0x10203040, 0x0a0b0c0d},
        {"payload-17-bytes!", 0xdeadbeef, 0x01020304},
        {"Longer synthetic Meshtastic payload for boundary testing.",
         0x12345678, 0x87654321},
    };

    for (size_t caseIndex = 0; caseIndex < sizeof(cases) / sizeof(cases[0]); caseIndex++) {
        CryptoEngine localCrypto;
        CryptoKey key = {};
        key.length = 16;
        HexToBytes(key.bytes, "00112233445566778899aabbccddeeff");
        localCrypto.setKey(key);

        uint8_t payload[128] = {};
        const size_t payloadLength = strlen(cases[caseIndex].plaintext);
        TEST_ASSERT_LESS_OR_EQUAL(sizeof(payload), payloadLength + 1);
        memcpy(payload, cases[caseIndex].plaintext, payloadLength);
        localCrypto.encryptPacket(
            cases[caseIndex].fromNode,
            cases[caseIndex].packetId,
            payloadLength,
            payload
        );

        printf("DEVMESH_CHANNEL_CTR_%u_HEX=", (unsigned int)(caseIndex + 1));
        for (size_t byteIndex = 0; byteIndex < payloadLength; byteIndex++) {
            printf("%02x", payload[byteIndex]);
        }
        printf("\\n");
    }
}
"""


def main() -> int:
    if len(sys.argv) != 2:
        print(
            "Uso: prepare_firmware_crypto_interop_test.py CAMINHO/test_main.cpp",
            file=sys.stderr,
        )
        return 2

    test_file = Path(sys.argv[1])
    if not test_file.is_file():
        print(f"Arquivo de teste do firmware não encontrado: {test_file}", file=sys.stderr)
        return 2

    source = test_file.read_text(encoding="utf-8")
    if source.count(TEST_FUNCTION_ANCHOR) != 1:
        print("A estrutura do teste upstream mudou; função de inserção não é única.", file=sys.stderr)
        return 1
    if source.count(TEST_REGISTRATION_ANCHOR) != 1:
        print("A estrutura do teste upstream mudou; registro do teste não é único.", file=sys.stderr)
        return 1
    if "test_DevMesh_AES_CTR_channel_interop" in source:
        print("O teste temporário já está presente; recusando duplicação.", file=sys.stderr)
        return 1

    source = source.replace(
        TEST_FUNCTION_ANCHOR,
        INTEROP_TEST + "\\n" + TEST_FUNCTION_ANCHOR,
        1,
    )
    source = source.replace(
        TEST_REGISTRATION_ANCHOR,
        TEST_REGISTRATION_ANCHOR
        + "    RUN_TEST(test_DevMesh_AES_CTR_channel_interop);\\n",
        1,
    )
    test_file.write_text(source, encoding="utf-8")
    print("Cinco casos temporários de interoperabilidade AES-CTR preparados.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
