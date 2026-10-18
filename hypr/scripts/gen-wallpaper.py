#!/usr/bin/env python3
"""
Генератор обоев в стиле Catppuccin Mocha (mesh gradient + зерно).

Запуск:
    python3 ~/.config/hypr/scripts/gen-wallpaper.py [выходной-файл.png]

По умолчанию рисует 1920x1080 в ~/Pictures/Wallpapers/catppuccin-mocha.png
Крутить цвета/свечения — в блоке GLOW ниже.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

W, H = 1920, 1080
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else (
    Path.home() / "Pictures/Wallpapers/catppuccin-mocha.png"
)


def rgb(hexstr: str) -> np.ndarray:
    h = hexstr.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=float)


base = rgb("#1e1e2e")
mantle = rgb("#181825")

yy, xx = np.mgrid[0:H, 0:W].astype(float)
nx, ny = xx / W, yy / H

# ── база: мягкий вертикальный градиент mantle -> base ──────────────────
t = ny[..., None]
img = mantle * (1 - t) + base * t


# ── GLOW: цветные свечения (сердце mesh-градиента) ─────────────────────
def glow(cx: float, cy: float, radius: float, color: np.ndarray,
         strength: float, falloff: float = 2.4) -> None:
    global img
    d2 = ((nx - cx) ** 2 + (ny - cy) ** 2) / (radius ** 2)
    img += color * (np.exp(-d2 * falloff) * strength)[..., None]


glow(0.18, 0.30, 0.62, rgb("#cba6f7"), 0.42)   # mauve  — сверху-слева
glow(0.86, 0.74, 0.55, rgb("#89b4fa"), 0.38)   # blue   — снизу-справа
glow(0.74, 0.10, 0.38, rgb("#fab387"), 0.13)   # peach  — краешек сверху
glow(0.10, 0.90, 0.42, rgb("#94e2d5"), 0.14)   # teal   — краешек снизу
glow(0.50, 0.48, 1.10, rgb("#cba6f7"), 0.05)   # общий мягкий подъём

# ── виньетка: лёгкое затемнение к краям ────────────────────────────────
vx, vy = (nx - 0.5) * 2, (ny - 0.5) * 2
vignette = np.clip(1 - 0.20 * (vx ** 2 + vy ** 2), 0.78, 1.0)[..., None]
img *= vignette

# ── зерно + дизеринг (убирает бандинг на градиентах) ───────────────────
rng = np.random.default_rng(3)
img += rng.normal(0, 2.0, img.shape)
img += rng.uniform(-0.5, 0.5, img.shape)

img = np.clip(img, 0, 255).astype(np.uint8)
OUT.parent.mkdir(parents=True, exist_ok=True)
Image.fromarray(img, "RGB").save(OUT)
print(f"saved: {OUT} ({W}x{H})")
