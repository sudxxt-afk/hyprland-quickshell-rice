#!/usr/bin/env python3
"""Раскладывает theme/palette.toml по конфигам риса.

Два способа правки файла:

* **блок** — текст между строкой-маркером `begin` и строкой-маркером `end`
  заменяется целиком; сами маркеры остаются на месте, всё вокруг них
  сохраняется байт-в-байт;
* **шаблон** — файл целиком собирается из шаблона, `{{ токен }}` заменяется
  значением из палитры.

Маркер найден не ровно один раз — `MarkerError`, и **ничего не пишется**:
файл остаётся прежним. Поэтому нельзя «затереть» конфиг, потеряв маркер.

Запуск:
    python3 theme/render.py              # разложить палитру
    python3 theme/render.py --dry-run    # показать, что будет сделано
    python3 theme/render.py --check      # проверить, что конфиги не разъехались
                                         # (код 2 — есть расхождения)
"""

from __future__ import annotations

import argparse
import dataclasses
import os
import pathlib
import re
import sys
import tomllib
from typing import Callable, Literal

ROOT = pathlib.Path(__file__).resolve().parents[1]
PALETTE_FILE = ROOT / "theme" / "palette.toml"
HOME = pathlib.Path.home()

# Какие имена цветов допустимы в палитре. Опечатка в palette.toml
# останавливает рендер, а не превращается в невидимую правку.
KNOWN_COLORS = frozenset(
    {
        "base", "mantle", "crust",
        "surface0", "surface1", "surface2",
        "overlay0", "overlay1", "overlay2",
        "subtext0", "subtext1",
        "text", "lavender", "blue", "sapphire", "sky", "teal", "green",
        "yellow", "peach", "maroon", "red", "mauve", "pink", "flamingo",
        "rosewater",
    }
)

# Порядок токенов для рендера палитры Wayle и QML — как в палитре,
# чтобы диффы были читаемыми.
COLOR_ORDER = [
    "base", "mantle", "crust",
    "surface0", "surface1", "surface2",
    "overlay0", "overlay1", "overlay2",
    "subtext0", "subtext1",
    "text", "lavender", "blue", "sapphire", "sky", "teal", "green",
    "yellow", "peach", "maroon", "red", "mauve", "pink", "flamingo",
    "rosewater",
]


class PaletteError(Exception):
    """Палитра неполна или содержит неизвестный токен."""


class MarkerError(Exception):
    """Маркер не найден ровно один раз — писать нельзя."""


@dataclasses.dataclass(frozen=True)
class Palette:
    """Значения палитры: цвета, шрифты, геометрия."""

    colors: dict[str, str]
    fonts: dict[str, str]
    geometry: dict[str, str]

    def token(self, name: str) -> str:
        """Значение токена из любой секции.

        У цвета есть производная форма `<имя>.rgb` — тройка «R, G, B»
        для `rgba(...)`.
        """
        if name.endswith(".rgb"):
            try:
                return rgb_triplet(self.colors[name[: -len(".rgb")]])
            except KeyError as error:
                raise PaletteError(f"неизвестный цвет: {name}") from error
        for section in (self.colors, self.fonts, self.geometry):
            if name in section:
                return section[name]
        raise PaletteError(f"неизвестный токен: {name}")


@dataclasses.dataclass(frozen=True)
class Target:
    """Один файл, который рендерится из палитры."""

    path: pathlib.Path
    kind: Literal["block", "template"]
    body: Callable[[Palette], str]
    markers: tuple[str, str] | None = None


def load_palette(path: pathlib.Path = PALETTE_FILE) -> Palette:
    """Читает палитру и проверяет имена цветов."""
    try:
        with path.open("rb") as handle:
            data = tomllib.load(handle)
    except FileNotFoundError as error:
        raise PaletteError(f"нет файла палитры: {path}") from error
    except tomllib.TOMLDecodeError as error:
        raise PaletteError(f"палитра не разбирается как TOML: {error}") from error

    colors = {key: str(value) for key, value in data.get("palette", {}).items()}
    unknown = sorted(set(colors) - KNOWN_COLORS)
    if unknown:
        raise PaletteError(f"неизвестные цвета в палитре: {', '.join(unknown)}")

    fonts = {key: str(value) for key, value in data.get("fonts", {}).items()}
    geometry = {key: str(value) for key, value in data.get("geometry", {}).items()}
    return Palette(colors=colors, fonts=fonts, geometry=geometry)


def apply_block(text: str, begin: str, end: str, body: str) -> str:
    """Заменяет текст между маркерами, сохраняя сами маркеры и окружение."""
    lines = text.split("\n")
    starts = [i for i, line in enumerate(lines) if begin in line]
    ends = [i for i, line in enumerate(lines) if end in line]
    if len(starts) != 1 or len(ends) != 1:
        raise MarkerError(
            f"маркеры должны встречаться по одному разу: "
            f"'{begin}' — {len(starts)}, '{end}' — {len(ends)}"
        )
    if starts[0] >= ends[0]:
        raise MarkerError(f"маркер '{begin}' идёт после '{end}'")

    body_lines = body.split("\n")
    return "\n".join(lines[: starts[0] + 1] + body_lines + lines[ends[0] :])


def rgb_triplet(color: str) -> str:
    """`#1e1e2e` → `30, 30, 46` (для `rgba(...)`)."""
    value = color.strip().lstrip("#")
    if len(value) != 6 or any(ch not in "0123456789abcdefABCDEF" for ch in value):
        raise PaletteError(f"не цвет: {color}")
    return f"{int(value[0:2], 16)}, {int(value[2:4], 16)}, {int(value[4:6], 16)}"


TOKEN_RE = re.compile(r"\{\{\s*([^{}\s]+)\s*\}\}")


def apply_template(template: str, palette: Palette) -> str:
    """Подставляет `{{ токен }}` значениями палитры."""

    def replace(match: re.Match[str]) -> str:
        return palette.token(match.group(1))

    return TOKEN_RE.sub(replace, template)


# ── Цели рендера ────────────────────────────────────────────────────
# Task 2 — терминал, лаунчер, btop; Task 3 — starship, fastfetch, GTK;
# Task 4 — Wayle и виджеты; Task 5 — цвета композитора.
TEMPLATES = ROOT / "theme" / "templates"


def _template(name: str) -> Callable[[Palette], str]:
    """Тело цели: шаблон из theme/templates (токены подставит рендерер)."""

    def body(_palette: Palette) -> str:
        return (TEMPLATES / name).read_text()

    return body


TARGETS: list[Target] = [
    # Терминал: цвета живут в отдельном theme.conf, kitty.conf подключает его.
    Target(
        path=HOME / ".config/kitty/theme.conf",
        kind="template",
        body=_template("kitty-theme.conf.in"),
    ),
    # Лаунчер: стиль целиком в палитре, блок между маркерами.
    Target(
        path=HOME / ".config/wofi/style.css",
        kind="block",
        markers=("/* palette:begin */", "/* palette:end */"),
        body=_template("wofi-style.css.in"),
    ),
    # btop: тема отдельным файлом, btop.conf ссылается на неё по имени.
    Target(
        path=HOME / ".config/btop/themes/catppuccin-mocha.theme",
        kind="template",
        body=_template("btop-catppuccin-mocha.theme.in"),
    ),
]


def _write_atomic(path: pathlib.Path, text: str) -> None:
    """Пишет через временный файл: половинчатого конфига не бывает."""
    tmp = path.with_name(path.name + ".render-tmp")
    tmp.write_text(text)
    os.replace(tmp, path)


def compute(target: Target, palette: Palette) -> str:
    """Новый текст одного файла (без записи)."""
    if target.kind == "template":
        # Шаблонный файл рис создаёт сам: текущего содержимого не нужно.
        return apply_template(target.body(palette), palette)

    if target.markers is None:
        raise PaletteError(f"блок без маркеров: {target.path}")
    begin, end = target.markers
    body = apply_template(target.body(palette), palette)
    return apply_block(target.path.read_text(), begin, end, body)


def render_targets(targets: list[Target], palette: Palette) -> list[tuple[Target, str]]:
    """Считает новые тексты для всех целей.

    Сначала считаются все цели: ошибка маркера в одной не оставит
    половину правок записанными.
    """
    planned: list[tuple[Target, str]] = []
    for target in targets:
        if target.kind == "block" and not target.path.exists():
            raise PaletteError(
                f"нет файла цели: {target.path} (блок без файла не собрать)"
            )
        planned.append((target, compute(target, palette)))
    return planned


def _current_text(path: pathlib.Path) -> str:
    """Текущее содержимое файла; нет файла — пусто (шаблонные цели создаются)."""
    return path.read_text() if path.exists() else ""


def main(argv: list[str] | None = None) -> int:
    """Раскладывает палитру. 0 — успех, 1 — ошибка маркеров, 2 — расхождение."""
    parser = argparse.ArgumentParser(description="Рендер палитры риса")
    parser.add_argument("--palette", type=pathlib.Path, default=PALETTE_FILE)
    parser.add_argument("--dry-run", action="store_true", help="ничего не писать")
    parser.add_argument("--check", action="store_true", help="только проверить")
    parser.add_argument(
        "--only",
        nargs="+",
        type=pathlib.Path,
        default=None,
        metavar="ПУТЬ",
        help="работать только с этими целями (например, один файл)",
    )
    args = parser.parse_args(argv)

    targets = TARGETS
    if args.only:
        wanted = {path.resolve() for path in args.only}
        targets = [target for target in TARGETS if target.path.resolve() in wanted]

    try:
        palette = load_palette(args.palette)
        planned = render_targets(targets, palette)
    except (MarkerError, PaletteError) as error:
        print(f"ошибка: {error}", file=sys.stderr)
        return 1

    drifted = [
        target
        for target, new_text in planned
        if new_text != _current_text(target.path)
    ]

    if args.check:
        if drifted:
            print("палитра разъехалась с конфигами:")
            for target in drifted:
                print(f"  {target.path}")
            return 2
        print(f"палитра и конфиги совпадают ({len(planned)} целей)")
        return 0

    if args.dry_run:
        for target, _ in planned:
            print(f"будет обновлено: {target.path}")
        return 0

    # Вторая фаза: всё посчитано без ошибок, можно писать.
    for target, new_text in planned:
        if new_text != _current_text(target.path):
            _write_atomic(target.path, new_text)
            print(f"обновлено: {target.path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
