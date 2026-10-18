"""Тесты рендерера палитры: замена блоков по маркерам, шаблоны, загрузка палитры."""

import contextlib
import io
import pathlib
import sys
import tempfile
import unittest
import unittest.mock

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


class RgbTests(unittest.TestCase):
    """Превращение цвета палитры в значения для rgba()."""

    def test_rgb_triplet(self):
        self.assertEqual(render.rgb_triplet("#1e1e2e"), "30, 30, 46")

    def test_rgb_triplet_rejects_bad_color(self):
        with self.assertRaises(render.PaletteError):
            render.rgb_triplet("синий")


class TargetsTests(unittest.TestCase):
    """Список целей рендера и его инварианты."""

    HOME = pathlib.Path.home()

    def test_targets_include_kitty_wofi_btop(self):
        paths = {str(target.path) for target in render.TARGETS}
        self.assertIn(str(self.HOME / ".config/kitty/theme.conf"), paths)
        self.assertIn(str(self.HOME / ".config/wofi/style.css"), paths)
        self.assertIn(str(self.HOME / ".config/btop/themes/catppuccin-mocha.theme"), paths)

    def test_targets_have_unique_paths(self):
        paths = [str(target.path) for target in render.TARGETS]
        self.assertEqual(len(paths), len(set(paths)), "у двух целей один путь")

    def test_block_targets_declare_markers(self):
        for target in render.TARGETS:
            if target.kind == "block":
                self.assertIsNotNone(target.markers, target.path)
                self.assertEqual(len(target.markers), 2, target.path)

    def test_template_bodies_have_no_raw_hex(self):
        palette = render.load_palette()
        for target in render.TARGETS:
            if target.kind == "template":
                body = target.body(palette)
                self.assertNotRegex(body, r"#[0-9a-fA-F]{6}", f"{target.path}: цвет в шаблоне")

    def test_wofi_body_is_palette_driven(self):
        palette = render.load_palette()
        wofi = next(t for t in render.TARGETS if str(t.path).endswith("wofi/style.css"))
        body = wofi.body(palette)
        self.assertNotRegex(body, r"#[0-9a-fA-F]{6}", "wofi: цвет хардкодом")
        resolved = render.apply_template(body, palette)
        self.assertIn(render.rgb_triplet(palette.colors["mantle"]), resolved, "wofi: фон не из палитры")
        self.assertIn(render.rgb_triplet(palette.colors["mauve"]), resolved, "wofi: акцент не из палитры")

    def test_rgb_token_is_valid_color(self):
        palette = render.load_palette()
        for name in palette.colors:
            self.assertRegex(palette.token(f"{name}.rgb"), r"^\d{1,3}, \d{1,3}, \d{1,3}$")

    def test_template_target_creates_missing_file(self):
        palette = render.load_palette()
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "new.conf"
            target = render.Target(path=path, kind="template", body=lambda _p: "fg {{ text }}\n")
            self.assertEqual(render.compute(target, palette), "fg #cdd6f4\n")

    def test_block_target_requires_existing_file(self):
        palette = render.load_palette()
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "нет.css"
            target = render.Target(
                path=path, kind="block", markers=("# b", "# e"), body=lambda _p: "x"
            )
            with self.assertRaises(render.PaletteError):
                render.render_targets([target], palette)

    def test_block_body_supports_tokens(self):
        palette = render.load_palette()
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "x.css"
            path.write_text("# b\nold\n# e\n")
            target = render.Target(
                path=path,
                kind="block",
                markers=("# b", "# e"),
                body=lambda _palette: "color: {{ mauve }};",
            )
            self.assertIn("color: #cba6f7;", render.compute(target, palette))


class MainTests(unittest.TestCase):
    """Полный прогон рендерера: запись, проверка, ошибка маркера, --only."""

    def _palette_file(self, root: pathlib.Path) -> pathlib.Path:
        path = root / "palette.toml"
        path.write_text('[palette]\nbase = "#1e1e2e"\n')
        return path

    def _run(self, targets: list[render.Target], argv: list[str]) -> int:
        """Прогон с подменённым списком целей, без шума в выводе тестов."""
        with (
            unittest.mock.patch.object(render, "TARGETS", targets),
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()),
        ):
            return render.main(argv)

    def _template(self, path: pathlib.Path) -> render.Target:
        return render.Target(
            path=path, kind="template", body=lambda _p: "bg {{ base }}\n"
        )

    def test_main_creates_template_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            target = self._template(root / "created.conf")
            code = self._run([target], ["--palette", str(self._palette_file(root))])
            self.assertEqual(code, 0)
            self.assertEqual(target.path.read_text(), "bg #1e1e2e\n")

    def test_main_check_reports_drift_without_writing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            target = self._template(root / "drifted.conf")
            target.path.write_text("bg #000000\n")
            code = self._run(
                [target], ["--palette", str(self._palette_file(root)), "--check"]
            )
            self.assertEqual(code, 2)
            self.assertEqual(target.path.read_text(), "bg #000000\n", "файл не должен меняться")

    def test_main_marker_error_writes_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            broken = render.Target(
                path=root / "broken.css",
                kind="block",
                markers=("/* b */", "/* e */"),
                body=lambda _p: "new\n",
            )
            broken.path.write_text("нет маркеров\n")
            good = render.Target(
                path=root / "good.css",
                kind="block",
                markers=("/* b */", "/* e */"),
                body=lambda _p: "new\n",
            )
            good.path.write_text("/* b */\nold\n/* e */\n")
            code = self._run([good, broken], ["--palette", str(self._palette_file(root))])
            self.assertEqual(code, 1)
            self.assertEqual(
                good.path.read_text(),
                "/* b */\nold\n/* e */\n",
                "половина правок недопустима",
            )

    def test_main_check_only_limits_targets(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            synced = self._template(root / "synced.conf")
            synced.path.write_text("bg #1e1e2e\n")
            drifted = self._template(root / "drifted.conf")
            drifted.path.write_text("bg #000000\n")
            palette_file = str(self._palette_file(root))

            only_synced = self._run(
                [synced, drifted],
                ["--palette", palette_file, "--check", "--only", str(synced.path)],
            )
            only_drifted = self._run(
                [synced, drifted],
                ["--palette", palette_file, "--check", "--only", str(drifted.path)],
            )
            self.assertEqual(only_synced, 0, "цель вне --only не должна влиять")
            self.assertEqual(only_drifted, 2)


if __name__ == "__main__":
    unittest.main()
