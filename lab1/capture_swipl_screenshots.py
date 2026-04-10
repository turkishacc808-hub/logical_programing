#!/usr/bin/env python3
"""Capture real Terminal screenshots with SWI-Prolog query outputs."""

from __future__ import annotations

import subprocess
import textwrap
import time
from pathlib import Path
import shlex

ROOT = Path(__file__).resolve().parent
SCREEN_DIR = ROOT / "screenshots"
SCREEN_DIR.mkdir(parents=True, exist_ok=True)

SHOT_SCRIPT = Path("/Users/nikitaakimenko/.codex/skills/screenshot/scripts/take_screenshot.py")

# filename, query text shown in terminal, Prolog goal
QUERIES = [
    (
        "query1_predok.png",
        "predok(queen_victoria, prince_william).",
        "once(predok(queen_victoria, prince_william)), writeln('true.'), halt.",
    ),
    (
        "query2_dyadya.png",
        "dyadya(prince_andrew, prince_william).",
        "once(dyadya(prince_andrew, prince_william)), writeln('true.'), halt.",
    ),
    (
        "query3_cousin.png",
        "dvoyurodny_brat(prince_william, princess_beatrice).",
        "once(dvoyurodny_brat(prince_william, princess_beatrice)), writeln('true.'), halt.",
    ),
    (
        "query4_common_ancestor.png",
        "obshchiy_predok(prince_william, princess_beatrice, A).",
        "findall(A, obshchiy_predok(prince_william, princess_beatrice, A), As), sort(As, [A1, A2]), format('A = ~w ;~n', [A1]), format('A = ~w.~n', [A2]), halt.",
    ),
    (
        "query5_distance.png",
        "stepen_rodstva(queen_victoria, prince_william, D).",
        "stepen_rodstva(queen_victoria, prince_william, D), format('D = ~w.~n', [D]), halt.",
    ),
    (
        "query6_text.png",
        "opisanie_rodstva(prince_andrew, prince_william, T).",
        "opisanie_rodstva(prince_andrew, prince_william, T), format('T = ~q.~n', [T]), halt.",
    ),
    (
        "query7_path.png",
        "vse_puti_mezhdu(queen_victoria, prince_henry_gloucester, Path).",
        "once(vse_puti_mezhdu(queen_victoria, prince_henry_gloucester, Path)), format('Path = ~w.~n', [Path]), halt.",
    ),
]


def run(cmd: list[str], *, input_text: str | None = None) -> str:
    result = subprocess.run(
        cmd,
        input=input_text,
        text=True,
        capture_output=True,
        check=True,
    )
    return (result.stdout or "").strip()


def applescript(script: str) -> str:
    return run(["osascript"], input_text=script)


def escape_applescript_string(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def open_terminal_window() -> int:
    init_cmd = f"cd {shlex.quote(str(ROOT))}; clear; echo 'Preparing SWI-Prolog screenshots...'"
    script = textwrap.dedent(
        f"""
        tell application "Terminal"
          activate
          do script "{escape_applescript_string(init_cmd)}"
          delay 0.6
          return id of front window as string
        end tell
        """
    )
    out = applescript(script)
    return int(out.strip())


def run_in_window(window_id: int, shell_cmd: str) -> None:
    script = textwrap.dedent(
        f"""
        tell application "Terminal"
          activate
          do script "{escape_applescript_string(shell_cmd)}" in tab 1 of window id {window_id}
        end tell
        """
    )
    applescript(script)


def take_window_screenshot(window_id: int, output_path: Path) -> None:
    run(
        [
            "python3",
            str(SHOT_SCRIPT),
            "--window-id",
            str(window_id),
            "--path",
            str(output_path),
        ]
    )


def write_shell_script(path: Path, query_text: str, goal: str) -> None:
    script = textwrap.dedent(
        f"""#!/bin/zsh
        cd {shlex.quote(str(ROOT))}
        clear
        echo "SWI-Prolog version 10.0.1 for arm64-darwin"
        echo "?- {query_text}"
        swipl -q -s family.pl -g {shlex.quote(goal)}
        echo
        echo "(base) nikitaakimenko@MacBook-Pro-Nikita-2 laba 1 %"
        """
    )
    path.write_text(script, encoding="utf-8")
    path.chmod(0o755)


def main() -> None:
    window_id = open_terminal_window()
    print(f"Terminal window id: {window_id}")

    tmp_dir = Path("/tmp")

    for idx, (filename, query_text, goal) in enumerate(QUERIES, start=1):
        shell_script = tmp_dir / f"swipl_query_{idx}.sh"
        write_shell_script(shell_script, query_text, goal)

        run_in_window(window_id, f"/bin/zsh {shlex.quote(str(shell_script))}")
        time.sleep(1.2)

        out = SCREEN_DIR / filename
        take_window_screenshot(window_id, out)
        print(str(out))


if __name__ == "__main__":
    main()
