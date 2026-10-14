#!/usr/bin/env python3
"""Add a temporary interoperability assertion to the pinned upstream crypto test."""

from pathlib import Path
import sys

TEST_FUNCTION_ANCHOR = "void test_AES_CCM_partial_block_bounds(void)"
TEST_REGISTRATION_ANCHOR = "    RUN_TEST(test_AES_CTR);\n"

INTEROP_TEST = """
void test_DevMesh_AES_CTR_channel_interop(void)
{
    CryptoEngine localCrypto;
    CryptoKey key = {};
    key.length = 16;
    HexToBytes(key.bytes, "00112233445566778899aabbccddeeff");
    localCrypto.setKey(key);

    uint8_t payload[] = "DevMesh private";
    localCrypto.encryptPacket(0x23456789, 0x12345678, sizeof(payload) - 1, payload);

    printf("DEVMESH_CHANNEL_CTR_HEX=");
    for (size_t i = 0; i < sizeof(payload) - 1; i++) {
        printf("%02x", payload[i]);
    }
    printf("\\n");
}
"""


def main() -> int:
    if len(sys.argv) != 2:
        print("Uso: prepare_firmware_crypto_interop_test.py CAMINHO/test_main.cpp", file=sys.stderr)
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

    source = source.replace(TEST_FUNCTION_ANCHOR, INTEROP_TEST + "\n" + TEST_FUNCTION_ANCHOR, 1)
    source = source.replace(
        TEST_REGISTRATION_ANCHOR,
        TEST_REGISTRATION_ANCHOR + "    RUN_TEST(test_DevMesh_AES_CTR_channel_interop);\n",
        1,
    )
    test_file.write_text(source, encoding="utf-8")
    print("Teste temporário de interoperabilidade AES-CTR preparado.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
