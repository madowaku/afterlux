from __future__ import annotations

import json
from itertools import combinations
from functools import lru_cache
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
STAGE_PATH = ROOT / "data" / "stages" / "tutorial_001_100.json"


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
                mask = make_mask(stage, dots, light)
                if any(mask):
                    masks.add(mask)

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


def count_optimal_multisets(stage: dict, par: int) -> int:
    """Count actual DOT/light choices; ignore only permutations of shot order.

    Unlike shot_options, keep choices with identical masks distinct: those are
    genuinely different solutions from the player's perspective.
    """
    target = target_tuple(stage)
    sockets = [coord_to_cell(coord) for coord in stage["sockets"]]
    options = []
    for count in range(1, stage["max_dots_per_shot"] + 1):
        for dots in combinations(sockets, count):
            for light in stage["allowed_lights"]:
                mask = make_mask(stage, dots, light)
                if any(mask) and all(a <= b for a, b in zip(mask, target)):
                    options.append(mask)

    @lru_cache(None)
    def visit(remaining: tuple[int, ...], start: int, shots_left: int) -> int:
        if shots_left == 0:
            return int(not any(remaining))
        total = 0
        for index in range(start, len(options)):
            mask = options[index]
            after = tuple(a - b for a, b in zip(remaining, mask))
            if min(after) >= 0:
                total += visit(after, index, shots_left - 1)
        return total

    return visit(target, 0, par)


def main() -> int:
    stages = json.loads(STAGE_PATH.read_text(encoding="utf-8"))
    solutions = json.loads((ROOT / "tests" / "stage_solutions_001_100.json").read_text(encoding="utf-8"))
    expected_ids = [f"{number:03d}" for number in range(1, 101)]
    if len(stages) != 100 or [stage.get("id") for stage in stages] != expected_ids:
        raise SystemExit("Stage bank must contain exactly IDs 001–100 in order.")
    if set(solutions) != set(expected_ids):
        raise SystemExit("Witness file must contain exactly one entry for every stage 001–100.")
    failed = False

    for stage in stages:
        actual = solve_par(stage)
        expected = stage["par"]
        unique = count_optimal_multisets(stage, expected)
        witness = [0] * (stage["width"] * stage["height"])
        for shot in solutions[stage["id"]]:
            dots = tuple(coord_to_cell(c) for c in shot["dots"])
            assert set(shot["dots"]) <= set(stage["sockets"])
            assert 0 < len(dots) <= stage["max_dots_per_shot"]
            assert len(set(dots)) == len(dots)
            assert shot["light"] in stage["allowed_lights"]
            witness = [a + b for a, b in zip(witness, make_mask(stage, dots, shot["light"]))]
        valid_witness = tuple(witness) == target_tuple(stage) and len(solutions[stage["id"]]) == expected
        passed = actual == expected and unique == 1 and valid_witness
        status = "OK" if passed else "FAIL"
        print(f'{stage["id"]}: PAR {actual} / stored {expected}, optimal multisets {unique}, witness {valid_witness} [{status}]')
        failed |= not passed

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
