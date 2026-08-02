"""Generate the Rete app icon: blue graduation-cap outline on a soft full-bleed fill.

Recreates the reference mark (pastel diagonal gradient + centered line-art
mortarboard). Writes SVG by default; also PNG when Pillow is available
(or via rsvg-convert if installed).

Deps:  pip install pillow  (optional, for PNG)
Run:   python3 generate_app_icon.py
         → ios_icon (square), android_icon (circle), mark_icon (transparent)
       python3 generate_app_icon.py [output.svg|output.png]
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_SVG = os.path.join(HERE, "rete_app_icon.svg")
DEFAULT_PNG = os.path.join(HERE, "rete_app_icon.png")
# Platform masters (1024×1024) written alongside the generic rete_app_icon.*
IOS_ICON_PNG = os.path.join(HERE, "ios_icon.png")
IOS_ICON_SVG = os.path.join(HERE, "ios_icon.svg")
ANDROID_ICON_PNG = os.path.join(HERE, "android_icon.png")
ANDROID_ICON_SVG = os.path.join(HERE, "android_icon.svg")
MARK_ICON_PNG = os.path.join(HERE, "mark_icon.png")
MARK_ICON_SVG = os.path.join(HERE, "mark_icon.svg")

# Canvas (iOS / Play Store master size)
SIZE = 1024
# Cap diamond half-width as a fraction of canvas (tighter = larger).
CAP_SCALE = 0.36

# Soft diagonal fill (top-left lavender -> bottom-right mint), a bit deeper
# for home-screen contrast under iOS's squircle mask.
GRAD_TL = (196, 204, 228)  # #C4CCE4
GRAD_BR = (186, 218, 208)  # #BADAD0
# Cap stroke (blue-700 — darker than #2563EB for a crisper silhouette)
STROKE = (29, 78, 216)  # #1D4ED8
STROKE_W = 62  # px at SIZE=1024


def _hex(rgb: tuple[int, int, int]) -> str:
    return "#%02X%02X%02X" % rgb


def _cap_geometry(cx: float, cy: float, scale: float):
    """Return diamond verts, base arc endpoints/depth, and tassel points.

    ``scale`` is the diamond half-width in pixels.
    """
    # Flat rhombus (mortarboard top), wider than tall
    hw, hh = scale, scale * 0.55
    top = (cx, cy - hh)
    right = (cx + hw, cy)
    bottom = (cx, cy + hh)
    left = (cx - hw, cy)
    diamond = [top, right, bottom, left]

    # Open U (skullcap) directly under the diamond — shoulders near the
    # bottom tip, curve dips clearly below so it reads as a cap, not a smile.
    base_w = scale * 0.50
    base_top = cy + hh * 0.92
    base_depth = scale * 0.42
    base_left = (cx - base_w, base_top)
    base_right = (cx + base_w, base_top)
    base_bottom = (cx, base_top + base_depth)

    # Tassel from the right tip: drop + short outward tick
    # Slightly shorter drop keeps the mark inside a tight circular crop.
    drop = scale * 0.62
    tick = scale * 0.14
    tassel = [right, (right[0], right[1] + drop), (right[0] + tick, right[1] + drop)]

    return diamond, base_left, base_right, base_bottom, tassel


def _diamond_d(pts) -> str:
    (t, r, b, l) = pts
    return (
        f"M {t[0]:.2f} {t[1]:.2f} "
        f"L {r[0]:.2f} {r[1]:.2f} "
        f"L {b[0]:.2f} {b[1]:.2f} "
        f"L {l[0]:.2f} {l[1]:.2f} Z"
    )


def _base_d(left, right, bottom) -> str:
    # Single cubic open U (control points pull down from the shoulders)
    k = 0.55
    cy = bottom[1]
    return (
        f"M {left[0]:.2f} {left[1]:.2f} "
        f"C {left[0]:.2f} {left[1] + (cy - left[1]) * k:.2f} "
        f"{bottom[0] - (right[0] - left[0]) * 0.25:.2f} {cy:.2f} "
        f"{bottom[0]:.2f} {cy:.2f} "
        f"C {bottom[0] + (right[0] - left[0]) * 0.25:.2f} {cy:.2f} "
        f"{right[0]:.2f} {right[1] + (cy - right[1]) * k:.2f} "
        f"{right[0]:.2f} {right[1]:.2f}"
    )


def _tassel_d(pts) -> str:
    a, b, c = pts
    return (
        f"M {a[0]:.2f} {a[1]:.2f} "
        f"L {b[0]:.2f} {b[1]:.2f} "
        f"L {c[0]:.2f} {c[1]:.2f}"
    )


def compose_svg(
    size: int = SIZE, *, background: bool = True, shape: str = "square"
) -> str:
    """Compose the icon SVG.

    ``shape`` is ``\"square\"`` (full-bleed, for iOS) or ``\"circle\"`` (soft
    circular crop with transparent corners, for Android).
    """
    if shape not in ("square", "circle"):
        raise ValueError(f"shape must be 'square' or 'circle', got {shape!r}")
    cx = cy = size / 2
    scale = size * CAP_SCALE
    cy -= size * 0.01  # optical vertical center
    diamond, bl, br, bb, tassel = _cap_geometry(cx, cy, scale)
    stroke = _hex(STROKE)
    sw = STROKE_W * (size / SIZE)
    r = size / 2

    if background:
        fill = (
            f'<circle cx="{r:.0f}" cy="{r:.0f}" r="{r:.0f}" fill="url(#bg)"/>'
            if shape == "circle"
            else f'<rect width="{size}" height="{size}" fill="url(#bg)"/>'
        )
        defs = f'''  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{_hex(GRAD_TL)}"/>
      <stop offset="1" stop-color="{_hex(GRAD_BR)}"/>
    </linearGradient>
  </defs>
  {fill}
'''
    else:
        defs = ""

    return f'''<?xml version="1.0" encoding="utf-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">
{defs}  <g fill="none" stroke="{stroke}" stroke-width="{sw:.1f}"
     stroke-linecap="round" stroke-linejoin="round">
    <path d="{_diamond_d(diamond)}"/>
    <path d="{_base_d(bl, br, bb)}"/>
    <path d="{_tassel_d(tassel)}"/>
  </g>
</svg>
'''


def write_svg(
    path: str, size: int = SIZE, *, background: bool = True, shape: str = "square"
) -> None:
    with open(path, "w") as f:
        f.write(compose_svg(size, background=background, shape=shape))


def write_png(
    path: str, size: int = SIZE, *, background: bool = True, shape: str = "square"
) -> None:
    """Rasterize via rsvg-convert if present, else Pillow."""
    rsvg = shutil.which("rsvg-convert")
    if rsvg:
        svg_tmp = path + ".__tmp.svg"
        write_svg(svg_tmp, size, background=background, shape=shape)
        try:
            subprocess.run(
                [rsvg, "-w", str(size), "-h", str(size), svg_tmp, "-o", path],
                check=True,
            )
        finally:
            os.unlink(svg_tmp)
        return

    try:
        from PIL import Image, ImageDraw
    except ImportError as e:
        raise SystemExit(
            "PNG export needs Pillow (`pip install pillow`) or rsvg-convert"
        ) from e

    # Prefer cairosvg when available for faithful SVG strokes
    try:
        import cairosvg  # type: ignore

        cairosvg.svg2png(
            bytestring=compose_svg(size, background=background, shape=shape).encode(
                "utf-8"
            ),
            write_to=path,
            output_width=size,
            output_height=size,
        )
        return
    except Exception:
        pass

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    if background:
        denom = max(size * 2 - 2, 1)
        px = img.load()
        for y in range(size):
            for x in range(size):
                t = (x + y) / denom
                rgb = tuple(
                    round(GRAD_TL[i] + (GRAD_BR[i] - GRAD_TL[i]) * t) for i in range(3)
                )
                px[x, y] = (*rgb, 255)
        if shape == "circle":
            mask = Image.new("L", (size, size), 0)
            ImageDraw.Draw(mask).ellipse([0, 0, size - 1, size - 1], fill=255)
            img.putalpha(mask)

    # Pillow does not antialias ImageDraw paths. Draw the line art at 4x and
    # downsample it so curved strokes (especially the cap base) stay smooth.
    antialias = 4
    render_size = size * antialias
    cx = cy = render_size / 2
    scale = render_size * CAP_SCALE
    cy -= render_size * 0.01
    diamond, bl, br, bb, tassel = _cap_geometry(cx, cy, scale)
    sw = max(1, round(STROKE_W * (render_size / SIZE)))
    overlay = Image.new("RGBA", (render_size, render_size), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    stroke = (*STROKE, 255)

    # Diamond outline
    od.line(diamond + [diamond[0]], fill=stroke, width=sw, joint="curve")

    # Base U — sample the same cubics as _base_d
    k = 0.55
    cy_b = bb[1]
    c1 = (bl[0], bl[1] + (cy_b - bl[1]) * k)
    c2 = (bb[0] - (br[0] - bl[0]) * 0.25, cy_b)
    c3 = (bb[0] + (br[0] - bl[0]) * 0.25, cy_b)
    c4 = (br[0], br[1] + (cy_b - br[1]) * k)

    def cubic(p0, p1, p2, p3, n=None):
        if n is None:
            n = max(24, round(render_size * 24 / SIZE))
        out = []
        for i in range(n + 1):
            t = i / n
            u = 1 - t
            x = (u**3 * p0[0] + 3 * u**2 * t * p1[0]
                 + 3 * u * t**2 * p2[0] + t**3 * p3[0])
            y = (u**3 * p0[1] + 3 * u**2 * t * p1[1]
                 + 3 * u * t**2 * p2[1] + t**3 * p3[1])
            out.append((x, y))
        return out

    base_pts = cubic(bl, c1, c2, bb) + cubic(bb, c3, c4, br)[1:]
    # Dense samples already form a smooth curve. Asking ImageDraw for a
    # rounded joint at every sample can create radial artifacts after resize.
    od.line(base_pts, fill=stroke, width=sw)
    curve_radius = sw / 2
    for x, y in base_pts:
        od.ellipse(
            [
                x - curve_radius,
                y - curve_radius,
                x + curve_radius,
                y + curve_radius,
            ],
            fill=stroke,
        )
    od.line(tassel, fill=stroke, width=sw, joint="curve")

    # Round caps at endpoints
    rcap = sw / 2
    for p in (*diamond, bl, br, tassel[0], tassel[-1]):
        od.ellipse(
            [p[0] - rcap, p[1] - rcap, p[0] + rcap, p[1] + rcap], fill=stroke
        )

    overlay = overlay.resize((size, size), Image.Resampling.LANCZOS)
    img = Image.alpha_composite(img, overlay)
    img.save(path)


def write_platform_masters() -> list[str]:
    """Write ios_icon (square), android_icon (circle), mark_icon (transparent)."""
    written: list[str] = []

    # Full-bleed square — iOS AppIcon / generic master.
    for svg_path, png_path in (
        (DEFAULT_SVG, DEFAULT_PNG),
        (IOS_ICON_SVG, IOS_ICON_PNG),
    ):
        write_svg(svg_path, background=True, shape="square")
        written.append(svg_path)
        write_png(png_path, background=True, shape="square")
        written.append(png_path)

    # Circular crop with transparent corners — Android launcher.
    write_svg(ANDROID_ICON_SVG, background=True, shape="circle")
    written.append(ANDROID_ICON_SVG)
    write_png(ANDROID_ICON_PNG, background=True, shape="circle")
    written.append(ANDROID_ICON_PNG)

    # Cap mark only — splash / adaptive foreground / in-app badge.
    write_svg(MARK_ICON_SVG, background=False)
    written.append(MARK_ICON_SVG)
    write_png(MARK_ICON_PNG, background=False)
    written.append(MARK_ICON_PNG)

    # App Store marketing icon must be opaque RGB (no alpha).
    try:
        from PIL import Image

        im = Image.open(IOS_ICON_PNG).convert("RGB")
        im.save(IOS_ICON_PNG)
    except ImportError:
        pass

    return written


def main() -> None:
    out = sys.argv[1] if len(sys.argv) > 1 else None
    if out is None:
        written = write_platform_masters()
    else:
        base, ext = os.path.splitext(out)
        ext = ext.lower()
        if ext == ".svg":
            targets = [out, base + ".png"]
        elif ext == ".png":
            targets = [base + ".svg", out]
        else:
            targets = [out + ".svg", out + ".png"]

        written = []
        for path in targets:
            if path.lower().endswith(".svg"):
                write_svg(path)
                written.append(path)
            else:
                try:
                    write_png(path)
                    written.append(path)
                except SystemExit as e:
                    print(e)

    print("wrote:\n  " + "\n  ".join(os.path.basename(p) for p in written))


if __name__ == "__main__":
    main()
