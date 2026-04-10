#!/usr/bin/env python3
"""Fallback family tree visualization without external dependencies.

Reads family.pl facts and renders an SVG image.
"""

from __future__ import annotations

import argparse
import html
import re
from collections import defaultdict
from pathlib import Path

RE_MAN = re.compile(r"^\s*muzhchina\(([^)]+)\)\.")
RE_WOMAN = re.compile(r"^\s*zhenshchina\(([^)]+)\)\.")
RE_PARENT = re.compile(r"^\s*roditel\(([^,]+),\s*([^)]+)\)\.")
RE_BIRTH = re.compile(r"^\s*data_rozhdeniya\(([^,]+),\s*date\((\d+),")


def parse_family(path: Path):
    men = set()
    women = set()
    edges = []
    birth_year = {}

    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("%"):
            continue

        m = RE_MAN.match(line)
        if m:
            men.add(m.group(1).strip())
            continue

        w = RE_WOMAN.match(line)
        if w:
            women.add(w.group(1).strip())
            continue

        p = RE_PARENT.match(line)
        if p:
            parent = p.group(1).strip()
            child = p.group(2).strip()
            edges.append((parent, child))
            continue

        b = RE_BIRTH.match(line)
        if b:
            person = b.group(1).strip()
            year = int(b.group(2))
            birth_year[person] = year

    people = men | women | {a for a, _ in edges} | {b for _, b in edges}
    return people, men, women, edges, birth_year


def compute_generation(people, edges):
    parents_of = defaultdict(list)
    has_parent = set()
    for parent, child in edges:
        parents_of[child].append(parent)
        has_parent.add(child)

    roots = [p for p in people if p not in has_parent]
    memo = {}

    def gen(person):
        if person in memo:
            return memo[person]
        parents = parents_of.get(person, [])
        if not parents:
            memo[person] = 0
            return 0
        g = max(gen(par) + 1 for par in parents)
        memo[person] = g
        return g

    for r in roots:
        memo[r] = 0
    for p in people:
        gen(p)

    return memo


def pretty(name: str) -> str:
    return name.replace("_", " ")


def render_svg(people, men, women, edges, birth_year, generation, output: Path):
    levels = defaultdict(list)
    for person in people:
        levels[generation.get(person, 0)].append(person)

    for g in levels:
        levels[g] = sorted(levels[g])

    max_nodes = max((len(v) for v in levels.values()), default=1)
    max_gen = max(levels.keys(), default=0)

    x_step = 210
    y_step = 165
    margin = 80

    width = max(1400, margin * 2 + max_nodes * x_step)
    height = max(900, margin * 2 + (max_gen + 1) * y_step)

    pos = {}
    for g in sorted(levels.keys()):
        row = levels[g]
        row_width = (len(row) - 1) * x_step
        start_x = width / 2 - row_width / 2
        y = margin + g * y_step
        for idx, person in enumerate(row):
            x = start_x + idx * x_step
            pos[person] = (x, y)

    parts = []
    parts.append('<?xml version="1.0" encoding="UTF-8"?>')
    parts.append(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{int(width)}" height="{int(height)}" viewBox="0 0 {int(width)} {int(height)}">'
    )
    parts.append('<defs>')
    parts.append('<marker id="arrow" markerWidth="10" markerHeight="8" refX="9" refY="4" orient="auto">')
    parts.append('<polygon points="0 0, 10 4, 0 8" fill="#5f6368"/>')
    parts.append('</marker>')
    parts.append('</defs>')
    parts.append('<rect x="0" y="0" width="100%" height="100%" fill="#fafafa"/>')
    parts.append('<text x="40" y="42" font-family="DejaVu Sans, Arial" font-size="28" fill="#263238">Family Tree (British Royal Family)</text>')

    for parent, child in edges:
        if parent not in pos or child not in pos:
            continue
        x1, y1 = pos[parent]
        x2, y2 = pos[child]
        parts.append(
            f'<line x1="{x1:.1f}" y1="{y1+28:.1f}" x2="{x2:.1f}" y2="{y2-28:.1f}" stroke="#5f6368" stroke-width="1.8" marker-end="url(#arrow)" opacity="0.75"/>'
        )

    for person in sorted(people):
        x, y = pos[person]
        label = pretty(person)
        if person in birth_year:
            label = f"{label} ({birth_year[person]})"
        label = html.escape(label)

        if person in men:
            fill = "#bbdefb"
            parts.append(
                f'<rect x="{x-82:.1f}" y="{y-28:.1f}" width="164" height="56" rx="9" ry="9" fill="{fill}" stroke="#263238" stroke-width="1.1"/>'
            )
        elif person in women:
            fill = "#f8bbd0"
            parts.append(
                f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="86" ry="29" fill="{fill}" stroke="#263238" stroke-width="1.1"/>'
            )
        else:
            fill = "#cfd8dc"
            parts.append(
                f'<rect x="{x-82:.1f}" y="{y-28:.1f}" width="164" height="56" rx="9" ry="9" fill="{fill}" stroke="#263238" stroke-width="1.1"/>'
            )

        parts.append(
            f'<text x="{x:.1f}" y="{y+4:.1f}" text-anchor="middle" font-family="DejaVu Sans, Arial" font-size="12" fill="#1f2937">{label}</text>'
        )

    parts.append('</svg>')
    output.write_text("\n".join(parts), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Render family tree SVG from family.pl")
    parser.add_argument("--prolog", default="family.pl")
    parser.add_argument("--output", default="family_tree.svg")
    args = parser.parse_args()

    prolog_path = Path(args.prolog)
    output_path = Path(args.output)

    people, men, women, edges, birth_year = parse_family(prolog_path)
    generation = compute_generation(people, edges)
    render_svg(people, men, women, edges, birth_year, generation, output_path)
    print(f"Saved SVG: {output_path.resolve()}")


if __name__ == "__main__":
    main()
