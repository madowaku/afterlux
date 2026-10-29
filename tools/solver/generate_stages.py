"""Deterministically mine small, uniquely-solvable AFTERLUX logic puzzles."""
from __future__ import annotations

import argparse
import hashlib
import json
import random
import sys
import time
from collections import Counter
from functools import lru_cache
from itertools import combinations
from pathlib import Path

from verify_stages import count_optimal_multisets, coord_to_cell, make_mask, solve_par, target_tuple

ROOT = Path(__file__).resolve().parents[2]
DIRECTIONS = ("N", "S", "W", "E")


def enumerate_actions(stage: dict) -> list[dict]:
    sockets = [coord_to_cell(coord) for coord in stage["sockets"]]
    result = []
    for size in range(1, stage["max_dots_per_shot"] + 1):
        for dots in combinations(sockets, size):
            for light in stage["allowed_lights"]:
                mask = make_mask(stage, dots, light)
                if any(mask):
                    result.append({
                        "dots": ["%s%d" % (chr(65 + x), y + 1) for x, y in dots],
                        "light": light,
                        "mask": mask,
                        "shadow": sum(mask),
                    })
    return result


def count_and_get_unique_solution(stage: dict, target: tuple[int, ...], par: int) -> tuple[int, list[dict]]:
    actions = [a for a in enumerate_actions(stage) if all(x <= goal for x, goal in zip(a["mask"], target))]
    actions.sort(key=lambda a: (a["mask"], a["dots"], a["light"]))

    @lru_cache(maxsize=None)
    def visit(remaining: tuple[int, ...], start: int, left: int) -> int:
        if left == 0:
            return int(not any(remaining))
        if not any(remaining):
            return 0
        if left * max((a["shadow"] for a in actions[start:]), default=0) < sum(remaining):
            return 0
        total = 0
        for i in range(start, len(actions)):
            action = actions[i]
            next_state = tuple(a - b for a, b in zip(remaining, action["mask"]))
            if min(next_state) < 0:
                continue
            total += visit(next_state, i, left - 1)
            if total >= 2:
                return 2
        return total

    count = visit(target, 0, par)
    if count != 1:
        return count, []
    witness = []
    remaining, start, left = target, 0, par
    while left:
        viable = []
        for i in range(start, len(actions)):
            action = actions[i]
            next_state = tuple(a - b for a, b in zip(remaining, action["mask"]))
            if min(next_state) >= 0 and visit(next_state, i, left - 1):
                viable.append((i, next_state))
        if len(viable) != 1:
            return 0, []
        start, remaining = viable[0]
        witness.append({"dots": actions[start]["dots"], "light": actions[start]["light"]})
        left -= 1
    return count, witness


def generate_candidate(rng: random.Random, tier: dict, serial: int) -> dict | None:
    width = height = 5 if tier["size"] == 5 else 4
    socket_count = rng.randint(tier["sockets"][0], tier["sockets"][1])
    all_coords = [f"{chr(65 + x)}{y + 1}" for y in range(height) for x in range(width)]
    sockets = sorted(rng.sample(all_coords, socket_count), key=lambda c: (c[-1], c[0]))
    # Avoid dead sockets: each placement should create at least one ray.
    lights = rng.sample(list(DIRECTIONS), rng.randint(tier["directions"][0], tier["directions"][1]))
    maximum = min(socket_count, rng.randint(tier["dots"][0], tier["dots"][1]))
    base = {"id": "candidate-%06d" % serial, "width": width, "height": height, "sockets": sockets,
            "allowed_lights": sorted(lights), "max_dots_per_shot": maximum,
            "target": [[0] * width for _ in range(height)], "par": 1}
    options = enumerate_actions(base)
    if len(options) < 3:
        return None
    desired_par = rng.randint(tier["par"][0], tier["par"][1])
    witness = rng.choices(options, k=desired_par)
    target = [sum(a["mask"][i] for a in witness) for i in range(width * height)]
    if not any(target) or max(target) > tier["max_target"]:
        return None
    base["target"] = [target[y * width:(y + 1) * width] for y in range(height)]
    target_tuple_value = tuple(target)
    par = solve_par(base, max_depth=desired_par)
    if par != desired_par:
        return None
    unique_count, optimal = count_and_get_unique_solution(base, target_tuple_value, par)
    if unique_count != 1:
        return None
    # Independently compare the production reference counter.
    if count_optimal_multisets(base, par) != 1:
        return None
    base["par"] = par
    grouped = sum(len(a["dots"]) > 1 for a in optimal)
    singles = len(optimal) - grouped
    directions_used = sorted({a["light"] for a in optimal})
    target_sum = sum(target)
    density = sum(n > 0 for n in target) / (width * height)
    crosses = sum(
        1 for y in range(height) for x in range(width)
        if target[y * width + x] > 1
        and any(target[y * width + x] > 0 for _ in (0,))
    )
    # A clear one shot over PAR witnesses the player-friendly two-step arc.
    above_par_clear, _ = count_and_get_unique_solution(base, target_tuple_value, par + 1)
    has_easy_clear = above_par_clear > 0
    key = json.dumps([width, height, sockets, sorted(lights), maximum, base["target"]], separators=(",", ":"))
    signature = hashlib.sha256(key.encode()).hexdigest()[:16]
    return {
        "stage": base,
        "solution": optimal,
        "features": {
            "par": par, "shot_shadow_counts": [sum(next(a["mask"] for a in options if a["dots"] == s["dots"] and a["light"] == s["light"])) for s in optimal],
            "grouped_shots": grouped, "solo_shots": singles, "directions_used": directions_used,
            "direction_diversity": len(directions_used), "target_total": target_sum,
            "target_density": round(density, 3), "peak_target": max(target),
            "active_target_cells": sum(n > 0 for n in target), "multi_shadow_cells": sum(n > 1 for n in target),
            "socket_count": socket_count, "allowed_direction_count": len(lights),
            "max_dots": maximum, "has_easy_clear_above_par": has_easy_clear,
            "optimal_multisets": 1, "geometry_signature": signature,
        },
    }


TIERS = [
    {"key": "aha", "size": 4, "sockets": [2, 4], "directions": [1, 2], "dots": [2, 2], "par": [2, 3], "max_target": 4, "want": 120},
    {"key": "crossings", "size": 4, "sockets": [3, 5], "directions": [2, 3], "dots": [1, 2], "par": [2, 3], "max_target": 4, "want": 120},
    {"key": "grouping", "size": 4, "sockets": [3, 5], "directions": [1, 3], "dots": [2, 3], "par": [2, 4], "max_target": 5, "want": 120},
    {"key": "four_lights", "size": 4, "sockets": [3, 5], "directions": [3, 4], "dots": [1, 2], "par": [3, 4], "max_target": 5, "want": 120},
    {"key": "hard_logic", "size": 4, "sockets": [4, 6], "directions": [2, 4], "dots": [1, 3], "par": [3, 5], "max_target": 5, "want": 120},
    {"key": "large_board", "size": 5, "sockets": [3, 5], "directions": [2, 4], "dots": [1, 2], "par": [3, 4], "max_target": 4, "want": 120},
    {"key": "mastery", "size": 5, "sockets": [4, 6], "directions": [3, 4], "dots": [1, 3], "par": [3, 5], "max_target": 5, "want": 120},
]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=20260929)
    parser.add_argument("--per-tier", type=int, default=120)
    parser.add_argument("--pool", type=Path, default=ROOT / "artifacts" / "candidate_pool_for_astra.json")
    args = parser.parse_args()
    rng = random.Random(args.seed)
    seen_targets = set()
    candidates = []
    serial = accepted = 0
    last_report = time.monotonic()
    while min(Counter(c["tier"] for c in candidates).values(), default=0) < args.per_tier:
        tier_counts = Counter(c["tier"] for c in candidates)
        open_tiers = [tier for tier in TIERS if tier_counts[tier["key"]] < args.per_tier]
        tier = min(open_tiers, key=lambda t: tier_counts[t["key"]] / args.per_tier)
        serial += 1
        candidate = generate_candidate(rng, tier, serial)
        if candidate is None:
            continue
        candidate["tier"] = tier["key"]
        stage = candidate["stage"]
        # Preserve several visually distinct examples of each rule family.
        signature = json.dumps([stage["width"], stage["height"], stage["sockets"], stage["allowed_lights"], stage["max_dots_per_shot"], stage["target"]], separators=(",", ":"))
        if signature in seen_targets:
            continue
        seen_targets.add(signature)
        candidates.append(candidate)
        accepted += 1
        now = time.monotonic()
        if now - last_report > 10:
            print(f"{accepted} / {args.per_tier * len(TIERS)} uniquely solved; {serial} attempts", flush=True)
            last_report = now
    args.pool.parent.mkdir(parents=True, exist_ok=True)
    args.pool.write_text(json.dumps({"seed": args.seed, "attempts": serial, "candidates": candidates}, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {len(candidates)} solver-verified, uniquely optimal candidates from {serial} attempts: {args.pool}")
    print("By curriculum tier:", dict(Counter(c["tier"] for c in candidates)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
