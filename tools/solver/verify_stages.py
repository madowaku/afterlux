from __future__ import annotations

import json
from itertools import combinations
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
STAGE_PATH = ROOT / "data" / "stages" / "tutorial_001_010.json"


def coord_to_cell(coord: str) -> tuple[int, int]:
    return ord(coord[0]) - ord("A"), int(coord[1:]) - 1


def make_mask(stage: dict, dots: tuple[tuple[int, int], ...], light: str) -> tuple[int, ...]:
    width = stage["width"]
    height = stage["height"]
    delta = [[0 for _ in range(width)] for _ in range(height)]
    dot_set = set(dots)

    step = {
        "N": (0, 1),
        "S": (0, -1),
        "W": (1, 0),
        "E": (-1, 0),
    }[light]

    for x, y in dots:
        x += step[0]
        y += step[1]
        while 0 <= x < width and 0 <= y < height:
            if (x, y) not in dot_set:
                delta[y][x] += 1
            x += step[0]
            y += step[1]

    return tuple(value for row in delta for value in row)


def target_tuple(stage: dict) -> tuple[int, ...]:
    return tuple(value for row in stage["target"] for value in row)


def shot_options(stage: dict) -> list[tuple[int, ...]]:
    sockets = [coord_to_cell(coord) for coord in stage["sockets"]]
    masks: set[tuple[int, ...]] = set()

    for dot_count in range(1, stage["max_dots_per_shot"] + 1):
        for dots in combinations(sockets, dot_count):
            for light in stage["allowed_lights"]:
                masks.add(make_mask(stage, dots, light))

    return sorted(masks)


def solve_par(stage: dict, max_depth: int = 12) -> int | None:
    target = target_tuple(stage)
    zero = tuple(0 for _ in target)
    options = shot_options(stage)
    frontier = {zero}

    for depth in range(1, max_depth + 1):
        next_frontier: set[tuple[int, ...]] = set()
        for state in frontier:
            for mask in options:
                new_state = tuple(a + b for a, b in zip(state, mask))
                if any(value > goal for value, goal in zip(new_state, target)):
                    continue
                if new_state == target:
                    return depth
                next_frontier.add(new_state)
        frontier = next_frontier
        if not frontier:
            break

    return None


def main() -> int:
    stages = json.loads(STAGE_PATH.read_text(encoding="utf-8"))
    failed = False

    for stage in stages:
        actual = solve_par(stage)
        expected = stage["par"]
        status = "OK" if actual == expected else "FAIL"
        print(f'{stage["id"]}: PAR {actual} / stored {expected} [{status}]')
        failed |= actual != expected

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
