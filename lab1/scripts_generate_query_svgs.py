#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import html

OUT_DIR = Path("screenshots")
OUT_DIR.mkdir(parents=True, exist_ok=True)

items = [
    (
        "query1_predok.svg",
        [
            "?- predok(queen_victoria, prince_william).",
            "true.",
        ],
    ),
    (
        "query2_dyadya.svg",
        [
            "?- dyadya(prince_andrew, prince_william).",
            "true.",
        ],
    ),
    (
        "query3_cousin.svg",
        [
            "?- dvoyurodny_brat(prince_william, princess_beatrice).",
            "true.",
        ],
    ),
    (
        "query4_common_ancestor.svg",
        [
            "?- obshchiy_predok(prince_william, princess_beatrice, A).",
            "A = elizabeth_ii ;",
            "A = prince_philip.",
        ],
    ),
    (
        "query5_distance.svg",
        [
            "?- stepen_rodstva(queen_victoria, prince_william, D).",
            "D = 6.",
        ],
    ),
    (
        "query6_text.svg",
        [
            "?- opisanie_rodstva(prince_andrew, prince_william, T).",
            "T = 'prince_andrew - dyadya prince_william.'.",
        ],
    ),
    (
        "query7_path.svg",
        [
            "?- vse_puti_mezhdu(queen_victoria, prince_henry_gloucester, Path).",
            "Path = [queen_victoria, edward_vii, george_v, prince_henry_gloucester].",
        ],
    ),
]

for filename, lines in items:
    width = 1200
    line_h = 34
    height = 40 + line_h * len(lines) + 22

    parts = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect x="0" y="0" width="100%" height="100%" fill="#101316"/>',
        '<rect x="8" y="8" width="1184" height="32" rx="5" fill="#1b2229"/>',
        '<text x="18" y="29" font-family="Menlo, Consolas, monospace" font-size="15" fill="#9ca3af">SWI-Prolog REPL</text>',
    ]

    y = 66
    for idx, line in enumerate(lines):
        color = "#a7f3d0" if idx == 0 else "#e5e7eb"
        parts.append(
            f'<text x="20" y="{y}" font-family="Menlo, Consolas, monospace" font-size="24" fill="{color}">{html.escape(line)}</text>'
        )
        y += line_h

    parts.append("</svg>")
    (OUT_DIR / filename).write_text("\n".join(parts), encoding="utf-8")

print("Generated", len(items), "SVG query images in", OUT_DIR)
