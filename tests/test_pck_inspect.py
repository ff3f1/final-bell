import hashlib
import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest

MODULE_PATH = Path(__file__).resolve().parents[1] / "tools" / "pck_inspect.py"
spec = importlib.util.spec_from_file_location("pck_inspect", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def make_pck(path, data, flags=2):
    payload = b""
    index = []
    for name, content in data:
        index.append((name, content, len(payload)))
        payload += content
    directory = struct.pack("<I", len(index))
    for name, content, offset in index:
        binary_name = name.encode("utf-8")
        directory += (
            struct.pack("<I", len(binary_name)) + binary_name +
            struct.pack("<QQ", offset, len(content)) +
            hashlib.md5(content).digest() + struct.pack("<I", 0)
        )
    # 40-byte header, 64-byte reserved section, and 8-byte alignment padding.
    header = struct.pack("<6I2Q", 0x43504447, 4, 4, 7, 2, flags, 112, 112+len(payload))
    path.write_bytes(header + bytes(72) + payload + directory)


class PckTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.path = Path(tmp.name) / "sample.pck"
        self.out = Path(tmp.name) / "out"

    def test_read_and_verify(self):
        make_pck(self.path, [
            ("scripts/fight/fighter.gdc", b"GDSCtest"),
            ("assets/boxers/model.scn", b"RSCC"),
        ])
        info, entries = module.read_index(self.path)
        self.assertEqual(info["godot_version"], "4.7.2")
        self.assertEqual(info["file_count"], 2)
        self.assertEqual(module.verify(self.path, entries), [])
        module.extract_metadata(self.path, entries, self.out)
        self.assertEqual((self.out/"scripts/fight/fighter.gdc").read_bytes(), b"GDSCtest")
        self.assertFalse((self.out/"assets/boxers/model.scn").exists())
        with self.assertRaises(FileExistsError):
            module.extract_metadata(self.path, entries, self.out)

    def test_bad_md5(self):
        make_pck(self.path, [("safe.gdc", b"content")])
        content = bytearray(self.path.read_bytes())
        content[112] = ord("x")
        self.path.write_bytes(content)
        _, entries = module.read_index(self.path)
        self.assertEqual(module.verify(self.path, entries), ["safe.gdc"])

    def test_path_traversal_is_rejected(self):
        make_pck(self.path, [("../unsafe.gdc", b"x")])
        with self.assertRaises(ValueError):
            module.read_index(self.path)

    def test_encrypted_index_is_rejected(self):
        make_pck(self.path, [("safe.gdc", b"x")], flags=3)
        with self.assertRaises(ValueError):
            module.read_index(self.path)

    def test_duplicate_casefold_paths_are_rejected(self):
        make_pck(self.path, [("A/x.gdc", b"x"), ("a/X.gdc", b"y")])
        with self.assertRaises(ValueError):
            module.read_index(self.path)


if __name__ == "__main__":
    unittest.main()
