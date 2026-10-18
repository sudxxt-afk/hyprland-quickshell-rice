"""Тесты сторожа палитры: посторонние цвета и следы Tokyo Night."""

import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
CHECK = ROOT / "theme" / "check.sh"


def run_check(*paths: pathlib.Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["bash", str(CHECK), *[str(p) for p in paths]],
        capture_output=True,
        text=True,
    )


class CheckShTests(unittest.TestCase):
    def test_clean_config_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            cfg = pathlib.Path(tmp) / "clean.css"
            cfg.write_text("background: #1e1e2e;\ncolor: #cba6f7;\n")
            result = run_check(pathlib.Path(tmp))
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_tokyo_night_color_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            cfg = pathlib.Path(tmp) / "starship.toml"
            cfg.write_text('style = "bg:#24283b fg:#7aa2f7"\n')
            result = run_check(pathlib.Path(tmp))
            self.assertEqual(result.returncode, 1)
            self.assertIn("starship.toml", result.stdout)

    def test_foreign_color_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            cfg = pathlib.Path(tmp) / "wofi.css"
            cfg.write_text("background: #ff00ff;\n")
            result = run_check(pathlib.Path(tmp))
            self.assertEqual(result.returncode, 1)
            self.assertIn("ff00ff", result.stdout)

    def test_tokyo_night_words_fail(self):
        with tempfile.TemporaryDirectory() as tmp:
            cfg = pathlib.Path(tmp) / "fastfetch.jsonc"
            cfg.write_text('// тема Tokyo Night Storm\n')
            result = run_check(pathlib.Path(tmp))
            self.assertEqual(result.returncode, 1)


if __name__ == "__main__":
    unittest.main()
