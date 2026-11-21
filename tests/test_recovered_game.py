"""Static integrity checks for the recovered text-only Final Bell source tree."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1] / "game"


class RecoveredSourceTests(unittest.TestCase):
    def test_script_inventory(self):
        scripts = list((ROOT / "scripts").rglob("*.gd"))
        self.assertEqual(len(scripts), 38)
        for src in scripts:
            self.assertGreater(src.stat().st_size, 150, src.as_posix())

    def test_project_and_main_scene(self):
        project = (ROOT / "project.godot").read_text(encoding="utf-8")
        scene = (ROOT / "scenes/main.tscn").read_text(encoding="utf-8")
        self.assertIn('run/main_scene="res://scenes/main.tscn"', project)
        self.assertIn('Game="*res://scripts/autoload/game.gd"', project)
        self.assertIn('Sfx="*res://scripts/autoload/sfx.gd"', project)
        self.assertIn('res://scripts/main.gd', scene)

    def test_preloaded_shader_sources(self):
        script = (ROOT / "scripts/visual/mixamo_rig.gd").read_text(encoding="utf-8")
        for shader in ["skin", "eye"]:
            asset = ROOT / "scripts/visual" / f"{shader}.gdshader"
            self.assertTrue(asset.is_file(), asset)
            self.assertIn(f"res://scripts/visual/{shader}.gdshader", script)
        for name in ["rope", "sharpen"]:
            self.assertTrue((ROOT / "scripts/visual" / f"{name}.gdshader").is_file())

    def test_critical_gameplay_components_present(self):
        for name in ["fight/fight.gd", "fight/fighter.gd", "fight/player_controller.gd",
                     "fight/ai_controller.gd", "fight/judges.gd", "data/career.gd",
                     "visual/mixamo_rig.gd", "visual/procedural_rig.gd"]:
            self.assertTrue((ROOT/"scripts"/name).is_file(), name)

    def test_compiled_code_not_committed(self):
        self.assertFalse(list(ROOT.rglob("*.gdc")))
        self.assertFalse(list(ROOT.rglob("*.scn")))
        self.assertFalse(list(ROOT.rglob("*.ctex")))

    def test_binary_media_are_explicitly_outside_text_tree(self):
        self.assertFalse(list(ROOT.rglob("*.pck")))
        self.assertFalse(list(ROOT.rglob("*.exe")))
        self.assertIn("not", (ROOT/"README_RECOVERY.md").read_text(encoding="utf-8").lower())


if __name__ == "__main__":
    unittest.main()
