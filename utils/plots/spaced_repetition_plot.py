"""
Spaced Repetition vs. Forgetting Curve
---------------------------------------
The no-review path uses Ebbinghaus-style empirical retention data (interpolated
between published time points). Spaced repetition resets retention to ~100% at
each review; a growing time-scale factor stretches that curve so forgetting
slows after every successful review.

Two scenarios are plotted:
  1. No review at all (single decay curve).
  2. Spaced repetition reviews at increasing intervals (1, 3, 7, 14, 30 days),
     each review boosting stability and resetting retention to ~100%.

Generates an SVG for the guide docs (515pt × 304pt at 130% of the base 396×234 size). Requires:
  pip install matplotlib numpy

Usage:
  python spaced_repetition_plot.py
  python spaced_repetition_plot.py -o /path/to/spaced_repetition_retention.svg
"""

from __future__ import annotations

import argparse
import os
import re
from pathlib import Path

_MPL_CONFIG = Path(__file__).resolve().parent / ".matplotlib"
_MPL_CONFIG.mkdir(exist_ok=True)
os.environ.setdefault("MPLCONFIGDIR", str(_MPL_CONFIG))

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np

DEFAULT_OUTPUT = (
    Path(__file__).resolve().parents[3]
    / "retentio-webapp/public/images/guide/spaced_repetition_retention.svg"
)

# ----------------------------
# Parameters
# ----------------------------
TOTAL_DAYS = 45
STABILITY_GROWTH_FACTOR = 2.2  # stretches the forgetting curve after each review
REVIEW_DAYS = [1, 3, 7, 14, 30]  # spaced repetition schedule (increasing intervals)
# Ebbinghaus retention data (time converted to days since learning).
EBBINGHAUS_DAYS = np.array(
    [
        0,
        20 / (24 * 60),  # 20 minutes
        1 / 24,  # 1 hour
        9 / 24,  # 9 hours
        1,
        2,
        5,
        30,
        35,
        40,
    ]
)
EBBINGHAUS_RETENTION = np.array([100, 58, 45, 35, 32, 30, 25, 20, 15, 10])
FORGETTING_LABEL_DAYS = [1, 7, 14, 30]  # data labels on the no-review curve
FORGETTING_LABEL_X_OFFSETS = {1: 1.6}  # nudge crowded labels horizontally
LABEL_X_OFFSETS = {1: -0.45, 3: 0.45}  # nudge crowded day labels horizontally
PLOT_SCALE = 1.3
FIG_WIDTH_IN = 5.5 * PLOT_SCALE
FIG_HEIGHT_IN = 3.25 * PLOT_SCALE
FIG_DPI = 72
# Typography scaled with PLOT_SCALE (8/6pt base sizes at scale 1.0).
TITLE_FONTSIZE = 8 * PLOT_SCALE
AXIS_LABEL_FONTSIZE = 8 * PLOT_SCALE
TICK_FONTSIZE = 6 * PLOT_SCALE
ANNOTATION_FONTSIZE = 6 * PLOT_SCALE
LEGEND_FONTSIZE = 6 * PLOT_SCALE
LINE_WIDTH = 2 * PLOT_SCALE
MARKER_SIZE = 28 * PLOT_SCALE


def empirical_retention(t_days: np.ndarray, time_scale: float = 1.0) -> np.ndarray:
    """Interpolate Ebbinghaus retention; larger time_scale = slower forgetting."""
    scaled_t = np.asarray(t_days, dtype=float) / time_scale
    retention_pct = np.interp(
        scaled_t,
        EBBINGHAUS_DAYS,
        EBBINGHAUS_RETENTION,
        left=100.0,
        right=float(EBBINGHAUS_RETENTION[-1]),
    )
    return retention_pct / 100.0


def format_retention_label(retention_pct: float) -> str:
    if retention_pct < 0.5:
        return "0%"
    return f"{retention_pct:.0f}%"


def clean_svg_metadata(svg_path: Path) -> None:
    """Remove matplotlib-specific metadata from a saved SVG."""
    text = svg_path.read_text()
    text = re.sub(r"\s*<metadata>.*?</metadata>\s*", "\n", text, flags=re.S)
    text = text.replace("matplotlib.axis_", "axis_")
    svg_path.write_text(text)


def build_curves() -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    t = np.linspace(0, TOTAL_DAYS, 2000)

    no_review_curve = empirical_retention(t)

    spaced_curve = np.zeros_like(t)
    time_scale = 1.0
    review_points = [0] + REVIEW_DAYS + [TOTAL_DAYS]

    for i in range(len(review_points) - 1):
        start_day = review_points[i]
        end_day = review_points[i + 1]
        mask = (t >= start_day) & (t <= end_day)
        local_t = t[mask] - start_day
        spaced_curve[mask] = empirical_retention(local_t, time_scale=time_scale)
        time_scale *= STABILITY_GROWTH_FACTOR

    return t, no_review_curve, spaced_curve


def plot_spaced_repetition(output: Path) -> None:
    mpl.rcParams["svg.fonttype"] = "none"

    t, no_review_curve, spaced_curve = build_curves()

    bg_color = "#161b22"
    text_color = "#ffffff"
    grid_color = "#4a4e53"
    spine_color = "#272c32"
    no_review_color = "#ff7b72"
    spaced_color = "#58a6ff"

    fig, ax = plt.subplots(figsize=(FIG_WIDTH_IN, FIG_HEIGHT_IN), dpi=FIG_DPI)
    fig.patch.set_facecolor(bg_color)
    ax.set_facecolor(bg_color)

    ax.plot(
        t,
        no_review_curve * 100,
        color=no_review_color,
        linewidth=LINE_WIDTH,
        linestyle="--",
        label="No review (forgetting curve)",
    )
    ax.plot(
        t,
        spaced_curve * 100,
        color=spaced_color,
        linewidth=LINE_WIDTH,
        label="Spaced repetition reviews",
    )

    for day in REVIEW_DAYS:
        ax.axvline(x=day, color=grid_color, linestyle=":", alpha=0.8)
        ax.scatter(
            [day],
            [100],
            color=spaced_color,
            zorder=5,
            s=MARKER_SIZE,
            edgecolors=bg_color,
            linewidths=0.8 * PLOT_SCALE,
        )
        ax.text(
            day + LABEL_X_OFFSETS.get(day, 0),
            103,
            f"day {day}",
            ha="center",
            fontsize=ANNOTATION_FONTSIZE,
            color=text_color,
        )

    for day in FORGETTING_LABEL_DAYS:
        retention_pct = empirical_retention(np.array([day]))[0] * 100
        y_offset = -6 if retention_pct > 10 else 8
        ax.text(
            day + FORGETTING_LABEL_X_OFFSETS.get(day, 0),
            retention_pct + y_offset,
            format_retention_label(retention_pct),
            ha="center",
            va="top" if retention_pct > 10 else "bottom",
            fontsize=ANNOTATION_FONTSIZE,
            color=no_review_color,
        )

    ax.set_title(
        "Spaced Repetition vs. Natural Forgetting",
        fontsize=TITLE_FONTSIZE,
        fontweight="normal",
        color=text_color,
    )
    ax.set_xlabel(
        "Days since initial learning",
        color=text_color,
        fontsize=AXIS_LABEL_FONTSIZE,
    )
    ax.set_ylabel("Retention (%)", color=text_color, fontsize=AXIS_LABEL_FONTSIZE)
    ax.set_ylim(0, 115)
    ax.set_xlim(0, TOTAL_DAYS)
    ax.tick_params(colors=text_color, labelsize=TICK_FONTSIZE)
    for spine in ax.spines.values():
        spine.set_color(spine_color)

    legend = ax.legend(
        loc="upper center",
        bbox_to_anchor=(0.5, -0.22),
        ncol=2,
        frameon=True,
        fontsize=LEGEND_FONTSIZE,
    )
    legend.get_frame().set_facecolor(bg_color)
    legend.get_frame().set_edgecolor(grid_color)
    for txt in legend.get_texts():
        txt.set_color(text_color)

    ax.grid(True, color=grid_color, alpha=0.6)
    fig.subplots_adjust(left=0.12, right=0.98, top=0.88, bottom=0.28)

    output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output, format="svg", facecolor=bg_color)
    plt.close(fig)
    clean_svg_metadata(output)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate the spaced repetition retention chart SVG."
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Output SVG path (default: {DEFAULT_OUTPUT})",
    )
    args = parser.parse_args()
    plot_spaced_repetition(args.output)
    print(f"Saved {args.output}")


if __name__ == "__main__":
    main()
