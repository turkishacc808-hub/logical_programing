#!/usr/bin/env python3
"""Visualize family tree from Prolog facts (family.pl).

Usage:
  python3 visualize_family.py --prolog family.pl --output family_tree.png
"""

from __future__ import annotations

import argparse
from collections import defaultdict
from pathlib import Path
import sys

import matplotlib

# Use a non-interactive backend so script works in headless environments.
matplotlib.use("Agg")

import matplotlib.pyplot as plt
import networkx as nx

try:
    from pyswip import Prolog
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "PySwip is not installed. Install dependencies first: "
        "pip install pyswip networkx matplotlib"
    ) from exc


def as_text(value: object) -> str:
    """Convert PySwip values to plain Python strings."""
    if isinstance(value, bytes):
        return value.decode("utf-8")
    return str(value)


def query_dicts(prolog: Prolog, query: str):
    """Return all results for a Prolog query as a list of dicts."""
    return list(prolog.query(query))


def load_graph(prolog_path: Path) -> tuple[nx.DiGraph, dict[str, int], dict[str, int]]:
    """Load people and relations from Prolog and build a directed graph."""
    prolog = Prolog()
    prolog.consult(str(prolog_path.resolve()))

    men = {as_text(row["X"]) for row in query_dicts(prolog, "muzhchina(X)")}
    women = {as_text(row["X"]) for row in query_dicts(prolog, "zhenshchina(X)")}

    edges = [
        (as_text(row["P"]), as_text(row["C"]))
        for row in query_dicts(prolog, "roditel(P,C)")
    ]

    birth_year = {
        as_text(row["P"]): int(row["Y"])
        for row in query_dicts(prolog, "data_rozhdeniya(P, date(Y,_,_))")
    }

    generation = {
        as_text(row["P"]): int(row["N"])
        for row in query_dicts(prolog, "pokolenie(P,N)")
    }

    g = nx.DiGraph()
    all_people = men | women

    for p in all_people:
        gender = "male" if p in men else "female"
        g.add_node(
            p,
            gender=gender,
            generation=generation.get(p),
            birth_year=birth_year.get(p),
        )

    for parent, child in edges:
        if parent not in g:
            g.add_node(parent, gender="unknown", generation=generation.get(parent), birth_year=birth_year.get(parent))
        if child not in g:
            g.add_node(child, gender="unknown", generation=generation.get(child), birth_year=birth_year.get(child))
        g.add_edge(parent, child)

    return g, generation, birth_year


def layered_layout(g: nx.DiGraph, generation: dict[str, int]) -> dict[str, tuple[float, float]]:
    """Deterministic top-down layout by generation number."""
    if generation:
        max_gen = max(generation.values())
    else:
        max_gen = 0

    levels: dict[int, list[str]] = defaultdict(list)
    for node in g.nodes:
        levels[generation.get(node, max_gen + 1)].append(node)

    pos: dict[str, tuple[float, float]] = {}
    x_step = 2.8
    y_step = 2.7

    for gen in sorted(levels):
        nodes = sorted(levels[gen])
        width = len(nodes) - 1
        for idx, node in enumerate(nodes):
            x = (idx - width / 2.0) * x_step
            y = -gen * y_step
            pos[node] = (x, y)

    return pos


def spring_layout(g: nx.DiGraph, seed: int) -> dict[str, tuple[float, float]]:
    """Force-directed layout fallback."""
    return nx.spring_layout(g, seed=seed, k=1.3)


def draw_graph(
    g: nx.DiGraph,
    generation: dict[str, int],
    birth_year: dict[str, int],
    output_path: Path,
    layout_name: str,
    dpi: int,
    seed: int,
) -> None:
    """Render and save tree as PNG."""
    if layout_name == "layered":
        pos = layered_layout(g, generation)
    else:
        pos = spring_layout(g, seed=seed)

    node_colors = []
    node_sizes = []
    labels = {}

    for node, attrs in g.nodes(data=True):
        gender = attrs.get("gender", "unknown")
        if gender == "male":
            node_colors.append("#90caf9")
        elif gender == "female":
            node_colors.append("#f8bbd0")
        else:
            node_colors.append("#cfd8dc")

        node_sizes.append(1800)

        pretty_name = node.replace("_", " ")
        if node in birth_year:
            labels[node] = f"{pretty_name}\n({birth_year[node]})"
        else:
            labels[node] = pretty_name

    fig_width = max(14, int(len(g.nodes) * 0.45))
    fig_height = max(10, int((max(generation.values()) + 3) * 1.8) if generation else 10)

    plt.figure(figsize=(fig_width, fig_height))
    nx.draw_networkx_edges(
        g,
        pos,
        arrows=True,
        arrowstyle="-|>",
        arrowsize=16,
        edge_color="#5f6368",
        width=1.4,
        alpha=0.7,
    )
    nx.draw_networkx_nodes(
        g,
        pos,
        node_color=node_colors,
        node_size=node_sizes,
        edgecolors="#263238",
        linewidths=0.8,
    )
    nx.draw_networkx_labels(g, pos, labels=labels, font_size=8, font_family="DejaVu Sans")

    plt.title("Family Tree from Prolog", fontsize=16)
    plt.axis("off")
    plt.tight_layout()

    output_path.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(output_path, dpi=dpi, bbox_inches="tight")
    plt.close()


def export_dot(prolog_path: Path, dot_path: Path) -> None:
    """Call Prolog predicate to export DOT."""
    prolog = Prolog()
    prolog.consult(str(prolog_path.resolve()))
    dot_path.parent.mkdir(parents=True, exist_ok=True)

    # Use PySwip interpolation (%p) to pass path safely.
    result = list(prolog.query("eksport_v_dot(%p)", str(dot_path.resolve())))
    if not result:
        raise RuntimeError("Prolog predicate eksport_v_dot/1 returned no solutions")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Visualize family tree from Prolog facts")
    parser.add_argument("--prolog", default="family.pl", help="Path to Prolog file")
    parser.add_argument("--output", default="family_tree.png", help="Path to output PNG")
    parser.add_argument(
        "--layout",
        choices=["layered", "spring"],
        default="layered",
        help="Graph layout algorithm",
    )
    parser.add_argument("--dpi", type=int, default=240, help="PNG DPI")
    parser.add_argument("--seed", type=int, default=42, help="Random seed for spring layout")
    parser.add_argument("--dot", default="", help="Optional path to DOT file export")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    prolog_path = Path(args.prolog)
    output_path = Path(args.output)

    if not prolog_path.exists():
        print(f"Error: Prolog file not found: {prolog_path}", file=sys.stderr)
        return 2

    graph, generation, birth_year = load_graph(prolog_path)
    draw_graph(
        graph,
        generation,
        birth_year,
        output_path=output_path,
        layout_name=args.layout,
        dpi=args.dpi,
        seed=args.seed,
    )

    if args.dot:
        export_dot(prolog_path, Path(args.dot))

    print(f"Saved tree image to: {output_path.resolve()}")
    if args.dot:
        print(f"Saved DOT file to: {Path(args.dot).resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
