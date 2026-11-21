import importlib.util
from pathlib import Path
import tempfile
import unittest
import zipfile

SCRIPT = Path(__file__).resolve().parents[1] / 'tools' / 'inventory.py'
spec = importlib.util.spec_from_file_location('fb_inventory', SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class InventoryTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.zip_path = self.root / 'Final Bell.zip'

    def tearDown(self):
        self.tmp.cleanup()

    def make_zip(self, entries):
        with zipfile.ZipFile(self.zip_path, 'w', zipfile.ZIP_DEFLATED) as z:
            for path, content in entries.items():
                z.writestr(path, content)

    def test_source_project_detection(self):
        self.make_zip({'Final Bell/project.godot': b'[application]\n',
                       'Final Bell/scenes/ring.tscn': b'[gd_scene]\n',
                       'Final Bell/assets/fighter.glb': b'glb'})
        result, files = module.scan(self.zip_path)
        self.assertEqual(result['project_paths'], ['Final Bell/project.godot'])
        self.assertEqual(result['counts_by_kind']['source'], 1)
        self.assertEqual(result['counts_by_kind']['asset'], 1)
        self.assertEqual(len(files), 3)
        self.assertEqual(len(result['archive_sha256']), 64)

    def test_export_detection_and_extraction(self):
        self.make_zip({'Final Bell/Final Bell.exe': b'MZ' + b'0' * 10,
                       'Final Bell/Final Bell.pck': b'GDPC' + b'1' * 20,
                       'other/readme.txt': b'ignore'})
        result, files = module.scan(self.zip_path)
        extracted = module.extract_packs(self.zip_path, files, self.root / 'out')
        self.assertEqual(len(result['pack_paths']), 2)
        self.assertEqual(len(extracted), 2)
        self.assertFalse((self.root / 'out/other/readme.txt').exists())
        self.assertEqual((self.root / 'out/Final Bell/Final Bell.pck').read_bytes()[:4], b'GDPC')
        with self.assertRaises(FileExistsError):
            module.extract_packs(self.zip_path, files, self.root / 'out')

    def test_unsafe_and_windows_case_collision(self):
        self.make_zip({'../escape.exe': b'x', '/absolute.pck': b'x',
                       'C:/drive.exe': b'x', 'folder\\bad.exe': b'x',
                       'A/Final Bell.pck': b'valid', 'a/final bell.PCK': b'clash'})
        report, members = module.scan(self.zip_path)
        self.assertEqual(len(report['unsafe_entries']), 4)
        self.assertEqual(len(report['colliding_entries']), 1)
        self.assertEqual(len(members), 1)
        module.extract_packs(self.zip_path, members, self.root / 'out')
        self.assertFalse((self.root / 'escape.exe').exists())

    def test_existing_directory_symlink_does_not_escape(self):
        self.make_zip({'folder/game.pck': b'X'})
        _, members = module.scan(self.zip_path)
        out = self.root / 'out'
        out.mkdir()
        external = self.root / 'external'
        external.mkdir()
        try:
            (out / 'folder').symlink_to(external, target_is_directory=True)
        except (OSError, NotImplementedError):
            self.skipTest('Creating directory symlinks is restricted on this system')
        with self.assertRaises(ValueError):
            module.extract_packs(self.zip_path, members, out)
        self.assertFalse((external / 'game.pck').exists())

    def test_symlink_rejected(self):
        link = zipfile.ZipInfo('linked.exe')
        link.create_system = 3
        link.external_attr = (0o120777 << 16)
        with zipfile.ZipFile(self.zip_path, 'w') as z:
            z.writestr(link, '../secret')
        result, members = module.scan(self.zip_path)
        self.assertEqual(result['unsafe_entries'], ['linked.exe'])
        self.assertEqual(members, [])

    def test_corrupt_archive_is_not_silently_accepted(self):
        self.zip_path.write_bytes(b'not a ZIP')
        with self.assertRaises(zipfile.BadZipFile):
            module.scan(self.zip_path)


if __name__ == '__main__':
    unittest.main()
