import hashlib
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from stage_recovery import stage


def make_pck(path, entries):
    payload = b""
    index = struct.pack("<I", len(entries))
    for name, data in entries:
        raw_name = name.encode("utf-8")
        index += struct.pack("<I", len(raw_name)) + raw_name
        index += struct.pack("<QQ", len(payload), len(data))
        index += hashlib.md5(data).digest() + struct.pack("<I", 0)
        payload += data
    head = struct.pack("<6I2Q", 0x43504447, 4, 4, 7, 2, 2, 112, 112+len(payload))
    path.write_bytes(head + bytes(72) + payload + index)


class StageTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.legacy = self.root / "source.zip"
        self.pck = self.root / "game.pck"
        self.out = self.root / "work"

    def test_metadata_and_compiled_only_paths(self):
        with zipfile.ZipFile(self.legacy, "w") as z:
            z.writestr("final_bell/scripts/main.gd", "extends Node")
            z.writestr("final_bell/project.godot", "config_version=5")
        make_pck(self.pck, [
            ("scripts/main.gdc", b"GDSC"),
            ("scripts/new.gdc", b"GDSC-more"),
            (".godot/imported/boxer.scn", b"RSCC"),
        ])
        summary = stage(self.legacy, self.pck, self.out)
        self.assertEqual(summary["legacy_scripts"], 1)
        self.assertEqual(summary["compiled_scripts"], 2)
        self.assertEqual(summary["compiled_only_scripts"], ["scripts/new"])
        self.assertTrue((self.out / "legacy-source/final_bell/project.godot").exists())
        self.assertTrue((self.out / "exported-pack/scripts/new.gdc").exists())
        self.assertFalse((self.out / "exported-pack/.godot/imported/boxer.scn").exists())
        with self.assertRaises(FileExistsError):
            stage(self.legacy, self.pck, self.out)

    def test_full_extracts_binary_scene(self):
        with zipfile.ZipFile(self.legacy, "w") as z:
            z.writestr("final_bell/project.godot", "config_version=5")
        make_pck(self.pck, [(".godot/imported/boxer.scn", b"binary3d")])
        stage(self.legacy, self.pck, self.out, full=True)
        self.assertEqual((self.out/ "exported-pack/.godot/imported/boxer.scn").read_bytes(),
                         b"binary3d")

    def test_unsafe_source_path_is_rejected(self):
        with zipfile.ZipFile(self.legacy, "w") as z:
            z.writestr("../outside.txt", "oops")
        make_pck(self.pck, [("scripts/main.gdc", b"x")])
        with self.assertRaises(ValueError):
            stage(self.legacy, self.pck, self.out)
        self.assertFalse((self.root/"outside.txt").exists())


if __name__ == "__main__":
    unittest.main()
