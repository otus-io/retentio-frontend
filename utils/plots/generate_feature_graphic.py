"""Generate the Google Play Store feature graphic (1024 × 500).

Layout: crisp app-icon mark (from generate_app_icon) + "Rete" + tagline on the
left; decorative card stack on the right. Output is opaque RGB PNG (Play Store
rejects transparency).

Title + tagline are rendered as SVG text via rsvg at 3× then downscaled so
glyph edges stay sharp.

Deps:  pip install pillow
       brew install librsvg
Run:   python3 generate_feature_graphic.py [output.png]
"""
from __future__ import annotations

import html
import os
import shutil
import subprocess
import sys
import tempfile
import textwrap

from PIL import Image, ImageDraw

from generate_app_icon import STROKE, write_png as write_app_icon_png, _hex

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_PNG = os.path.join(HERE, "rete_feature_graphic.png")

WIDTH = 1024
HEIGHT = 500
SCALE = 3

BG = (10, 10, 10)
TEXT = (255, 255, 255)
MUTED = (186, 196, 210)
CARD_FILL = (17, 24, 39)
CARD_EDGE = (30, 41, 59)

TITLE = "Rete"
TAGLINE = (
    "Build and refine flashcard decks together with AI quality "
    "checks and novel spaced repetition algorithm"
)

ICON_SIZE = 200
ICON_X = 36
TEXT_X = ICON_X + ICON_SIZE + 20
TAGLINE_MAX_CHARS = 38  # wrap by character count for SVG
TITLE_SIZE = 64
TAGLINE_SIZE = 22
TAGLINE_LINE_GAP = 8


def _load_crisp_icon(size: int) -> Image.Image:
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "icon.png")
        write_app_icon_png(path, size)
        return Image.open(path).convert("RGBA")


def _tagline_lines() -> list[str]:
    return textwrap.wrap(TAGLINE, width=TAGLINE_MAX_CHARS)


def _text_svg(width: int, height: int) -> str:
    """Transparent SVG with title + wrapped tagline only."""
    lines = _tagline_lines()
    line_h = TAGLINE_SIZE + TAGLINE_LINE_GAP
    block_h = TITLE_SIZE + 14 + len(lines) * line_h
    title_y = (height - block_h) // 2 + TITLE_SIZE  # SVG baseline
    tag_y0 = title_y + 14 + TAGLINE_SIZE

    tag_spans = "\n".join(
        f'  <text x="{TEXT_X}" y="{tag_y0 + i * line_h}" '
        f'font-family="Helvetica Neue, Helvetica, Arial, sans-serif" '
        f'font-size="{TAGLINE_SIZE}" font-weight="500" fill="{_hex(MUTED)}">'
        f"{html.escape(line)}</text>"
        for i, line in enumerate(lines)
    )

    return f'''<?xml version="1.0" encoding="utf-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}"
     viewBox="0 0 {width} {height}">
  <text x="{TEXT_X}" y="{title_y}"
        font-family="Helvetica Neue, Helvetica, Arial, sans-serif"
        font-size="{TITLE_SIZE}" font-weight="700" fill="{_hex(TEXT)}"
        >{html.escape(TITLE)}</text>
{tag_spans}
</svg>
'''


def _rasterize_text_layer(width: int, height: int, scale: int) -> Image.Image:
    rsvg = shutil.which("rsvg-convert")
    if not rsvg:
        raise SystemExit("rsvg-convert required (brew install librsvg)")
    hi_w, hi_h = width * scale, height * scale
    with tempfile.TemporaryDirectory() as tmp:
        svg_path = os.path.join(tmp, "text.svg")
        png_path = os.path.join(tmp, "text.png")
        # Write SVG in 1× coords; rsvg scales via -w/-h
        with open(svg_path, "w") as f:
            f.write(_text_svg(width, height))
        subprocess.run(
            [rsvg, "-w", str(hi_w), "-h", str(hi_h), svg_path, "-o", png_path],
            check=True,
        )
        return Image.open(png_path).convert("RGBA")


def _draw_card_stack(draw: ImageDraw.ImageDraw, s: int) -> None:
    cards = [
        (690, 118, 930, 318, 12),
        (710, 138, 950, 338, 12),
        (730, 158, 970, 358, 12),
    ]
    for i, (x0, y0, x1, y1, r) in enumerate(cards):
        fill = CARD_FILL if i < 2 else (22, 30, 48)
        draw.rounded_rectangle(
            [x0 * s, y0 * s, x1 * s, y1 * s],
            radius=r * s,
            fill=fill,
            outline=CARD_EDGE,
            width=max(1, 2 * s),
        )

    x0, y0, x1, y1, _ = cards[-1]
    pad = 28
    draw.rounded_rectangle(
        [(x0 + pad) * s, (y0 + 36) * s, (x1 - pad) * s, (y0 + 52) * s],
        radius=4 * s,
        fill=STROKE,
    )
    draw.rounded_rectangle(
        [(x0 + pad) * s, (y0 + 72) * s, (x0 + pad + 120) * s, (y0 + 86) * s],
        radius=4 * s,
        fill=MUTED,
    )
    draw.rounded_rectangle(
        [(x0 + pad) * s, (y0 + 100) * s, (x1 - pad - 40) * s, (y0 + 114) * s],
        radius=4 * s,
        fill=(100, 116, 139),
    )
    draw.rounded_rectangle(
        [(x0 + 14) * s, (y0 + 20) * s, (x0 + 22) * s, (y1 - 20) * s],
        radius=3 * s,
        fill=STROKE,
    )


def compose(width: int = WIDTH, height: int = HEIGHT, scale: int = SCALE) -> Image.Image:
    s = scale
    hi_w, hi_h = width * s, height * s

    base = Image.new("RGBA", (hi_w, hi_h), (*BG, 255))

    icon = _load_crisp_icon(ICON_SIZE * s)
    icon_y = (hi_h - ICON_SIZE * s) // 2
    base.paste(icon, (ICON_X * s, icon_y), icon)

    text_layer = _rasterize_text_layer(width, height, s)
    base = Image.alpha_composite(base, text_layer)

    draw = ImageDraw.Draw(base)
    _draw_card_stack(draw, s)

    return base.convert("RGB").resize((width, height), Image.Resampling.LANCZOS)


def write_png(path: str, width: int = WIDTH, height: int = HEIGHT) -> None:
    compose(width, height).save(path, format="PNG", optimize=True)


def main() -> None:
    out = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_PNG
    if not out.lower().endswith(".png"):
        out = out + ".png"
    write_png(out)
    print(f"wrote: {out} ({WIDTH}x{HEIGHT})")


if __name__ == "__main__":
    main()
