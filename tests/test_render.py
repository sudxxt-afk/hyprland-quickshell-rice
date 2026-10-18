"""Тесты рендерера палитры: замена блоков по маркерам, шаблоны, загрузка палитры."""

import pathlib
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from theme import render  # noqa: E402


class ApplyBlockTests(unittest.TestCase):
    """Замена тела между маркерами."""

    def test_replaces_marked_block(self):
        text = "head\n# palette:begin\nold\n# palette:end\ntail\n"
        out = render.apply_block(text, "# palette:begin", "# palette:end", "new1\nnew2")
        self.assertEqual(out, "head\n# palette:begin\nnew1\nnew2\n# palette:end\ntail\n")

    def test_preserves_text_outside_markers(self):
        text = "важное\n# b\nold\n# e\nтоже важное\n"
        out = render.apply_block(text, "# b", "# e", "new")
        self.assertEqual(out, "важное\n# b\nnew\n# e\nтоже важное\n")

    def test_missing_marker_raises(self):
        with self.assertRaises(render.MarkerError):
            render.apply_block("нет маркеров\n", "# b", "# e", "new")

    def test_double_marker_raises(self):
        text = "# b\nold\n# e\n# b\nold\n# e\n"
        with self.assertRaises(render.MarkerError):
            render.apply_block(text, "# b", "# e", "new")

    def test_idempotent(self):
        text = "# b\nold\n# e\ntail\n"
        once = render.apply_block(text, "# b", "# e", "new1\nnew2")
        twice = render.apply_block(once, "# b", "# e", "new1\nnew2")
        self.assertEqual(once, twice)


class TemplateTests(unittest.TestCase):
    """Подстановка токенов в шаблон."""

    def test_template_substitution(self):
        pal = render.Palette(
            colors={"base": "#1e1e2e", "text": "#cdd6f4"},
            fonts={"ui": "JetBrains Mono", "ui_size": "11"},
            geometry={"margin": "16"},
        )
        self.assertEqual(
            render.apply_template("bg={{ base }} fg={{ text }} size={{ ui_size }}", pal),
            "bg=#1e1e2e fg=#cdd6f4 size=11",
        )

    def test_unknown_token_raises(self):
        pal = render.Palette(colors={}, fonts={}, geometry={})
        with self.assertRaises(render.PaletteError):
            render.apply_template("{{ нет-такого }}", pal)


class LoadPaletteTests(unittest.TestCase):
    """Загрузка настоящей палитры из репозитория."""

    def test_loads_repo_palette(self):
        pal = render.load_palette(ROOT / "theme" / "palette.toml")
        self.assertEqual(pal.colors["base"], "#1e1e2e")
        self.assertEqual(pal.colors["mauve"], "#cba6f7")
        self.assertEqual(pal.fonts["terminal"], "CozetteVector")
        self.assertEqual(pal.geometry["screen_w"], "1920")

    def test_unknown_token_in_palette_raises(self):
        import tempfile

        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "palette.toml"
            path.write_text('[palette]\nbase = "#1e1e2e"\nnope = "#000000"\n')
            with self.assertRaises(render.PaletteError):
                render.load_palette(path)

    def test_malformed_palette_raises(self):
        import tempfile

        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "palette.toml"
            path.write_text("[palette]\nbase = без кавычек\n")
            with self.assertRaises(render.PaletteError):
                render.load_palette(path)


if __name__ == "__main__":
    unittest.main()
