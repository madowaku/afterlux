"""Turn the Astra-curated, solver-verified candidate IDs into the playable pack."""
from __future__ import annotations

import csv
import json
import sys
from collections import Counter
from pathlib import Path

from verify_stages import ROOT, coord_to_cell

POOL_PATH = ROOT / "artifacts" / "candidate_pool_for_astra.json"
SELECTION_PATH = ROOT / "data" / "stages" / "astra_selection_100.json"
STAGE_PATH = ROOT / "data" / "stages" / "tutorial_001_100.json"
WITNESS_PATH = ROOT / "tests" / "stage_solutions_001_100.json"
CSV_PATH = ROOT / "localization" / "ui.csv"

PACKS = {
    "aha": ("05 / ZERO HAS A SHAPE", "05 / 余白に気づく", "Zero has a shape", "ゼロにもかたち", "AHA"),
    "crossings": ("06 / CROSSING LIGHT", "06 / 交わる光", "Crossing light", "交わる光", "CROSSINGS"),
    "grouping": ("07 / GROUP & SPLIT", "07 / まとめる・分ける", "Group & split", "まとめる・分ける", "GROUPING"),
    "four_lights": ("08 / FOUR EDGES", "08 / 四方の光", "Four edges", "四方の光", "FOUR LIGHTS"),
    "hard_logic": ("09 / DEEPER LOGIC", "09 / 深いロジック", "Deeper logic", "深い推理", "DEEP LOGIC"),
    "large_board": ("10 / OPEN HORIZON", "10 / 広がる盤面", "Open horizon", "広がる盤面", "LARGE BOARD"),
    "mastery": ("11 / MASTERY", "11 / 熟達", "Mastery", "熟達", "MASTERY"),
}
CAPSTONE_PACK = ("12 / FINALE", "12 / 光の集大成", "Finale", "光の集大成", "CAPSTONE")

NAMES = {
    "aha": [
        ("A Place for Quiet", "静けさの場所"), ("Between the Rays", "光のあいだ"),
        ("An Empty Step", "空いた一手"), ("The Missing Number", "消えた数字"),
        ("A Narrow Silence", "細い静寂"), ("Something Left Out", "残した余白"),
        ("The Gentle Gap", "やさしい空白"), ("Before the Shadow", "影が来る前"),
        ("Still a Little Room", "まだある余地"), ("Where Light Pauses", "光の止まる場所"),
    ],
    "crossings": [
        ("Meet Me in the Middle", "真ん中で出会う"), ("A Second Approach", "もうひとつの向き"),
        ("The Corner Between", "角を曲がって"), ("A Crossing, Twice", "交差する二つの光"),
        ("A Quiet Intersection", "静かな交点"), ("From Here and There", "こちらから、あちらから"),
        ("The Other Row", "もうひとつの行"), ("Parallel Thoughts", "平行する考え"),
        ("Almost Together", "あと少しで交わる"), ("A Meeting of Shadows", "影の待ち合わせ"),
    ],
    "grouping": [
        ("Together, Not Twice", "ふたつでひとつ"), ("The Split Decision", "分けるという選択"),
        ("Paired in Silence", "静けさを分け合う"), ("One More Together", "もうひと組"),
        ("In Two Movements", "ふたつの手で"), ("The Grouping Problem", "組み合わせの妙"),
        ("A Shared Beginning", "同じ始まりから"), ("Split the Difference", "ちょうどよく分ける"),
        ("An Unexpected Pair", "思いがけない組"), ("Together or Apart", "一緒に、それとも別々"),
    ],
    "four_lights": [
        ("North, Then Quiet", "北からの余白"), ("East of the Answer", "答えの東側"),
        ("A Change of Bearing", "光路を変えて"), ("One Cell, Four Ways", "ひとマス、四つの道"),
        ("The Far Edge", "向こう側の光"), ("Light Comes Around", "巡る光"),
        ("Across the Board", "盤面を横切って"), ("The Opposite Edge", "反対側から"),
        ("Every Way Home", "四方から導く"), ("Directional Thinking", "向きを読む"),
    ],
    "hard_logic": [
        ("Count Backwards", "逆から数える"), ("The Only Way In", "唯一の入り口"),
        ("A Deliberate Detour", "回り道の理由"), ("The Sum of Small Things", "小さな影の総和"),
        ("Prove the Zero", "ゼロを証明する"), ("Narrowing the Field", "可能性をしぼる"),
        ("First Principles", "一手ずつ確かめる"), ("A Case for Patience", "じっくり考える"),
        ("Look Twice", "もう一度、盤面を"), ("Careful Arithmetic", "ていねいな足し算"),
    ],
    "large_board": [
        ("An Open Horizon", "見晴らす盤面"), ("Five Rows of Calm", "五列の静けさ"),
        ("The Long Way Across", "盤面の向こうまで"), ("More Room to Think", "広い思考の余地"),
        ("Space Between", "マスとマスのあいだ"), ("A Larger Silence", "大きな余白"),
        ("A Wider Angle", "広い視野で"), ("The Quiet Distance", "静かな距離"),
        ("Look to the Edges", "盤面の縁を読む"), ("Room for One More", "あとひとマス"),
    ],
    "mastery": [
        ("A Patient Light", "待つ光"), ("The Hidden Decomposition", "隠れた分解"),
        ("Three Lines Meet", "三本の道が出会う"), ("A Subtle Difference", "わずかな違い"),
        ("Every Shot Matters", "一手も余さず"), ("A Measured Shadow", "測られた影"),
        ("The Last Direction", "最後の向き"), ("A Study in Restraint", "抑制の一題"),
        ("Nothing by Chance", "偶然のない一手"), ("Shadows in Balance", "影の均衡"),
    ],
}
CAPSTONE_NAMES = [
    ("The Light We Learned", "学んだ光を重ねて"), ("All the Ways Home", "すべての道をたどって"),
    ("The Longest Quiet", "いちばん深い静けさ"), ("Everything in Its Place", "すべての影の居場所"),
    ("The Hidden Whole", "見えない全体像"), ("A Last, Little Gap", "最後に残る余白"),
    ("Keep the Light Moving", "光を止めずに"), ("The Shape of Together", "一緒に作るかたち"),
    ("An Answer in Layers", "影を重ねた答え"), ("After the Final Ray", "最後の光のその先"),
]

HINTS = {
    "aha": ("The empty cells are part of the pattern. Notice where a shadow must not land.", "空白も目標の一部です。影を落としてはいけない場所に注目しよう。"),
    "crossings": ("Trace the required totals along their rows and columns. Which directions can reach each one?", "目標の数字から行と列をたどろう。それぞれのマスへ届く向きは？"),
    "grouping": ("Compare putting the dots together with splitting them across shots. The zero-holes change.", "点を一緒に置く場合と、手を分ける場合を比べよう。ゼロの場所が変わります。"),
    "four_lights": ("The arrow shows shadow travel. Work back from the target to the edge light.", "矢印は影が伸びる向きです。目標から盤面の縁へさかのぼろう。"),
    "hard_logic": ("Start with a number that has few possible incoming rays. Let it narrow the choices.", "届く光が限られる数字を見つけよう。それが他の選択をしぼります。"),
    "large_board": ("Scan the five-by-five pattern before firing. A distant cell can rule out a direction.", "放つ前に5×5の模様を見渡そう。離れたマスが向きを決める手がかりです。"),
    "mastery": ("Work backwards from the most constrained cells. Every shot still follows the same simple rules.", "選択肢の少ないマスから逆向きに考えよう。ルールはいつも同じです。"),
    "capstone": ("Bring the whole toolkit together: direction, grouping, empty cells and persistent layers.", "学んだ考え方を重ねよう。光の向き、点の組、空白、残る影がすべて手がかりです。"),
}


def transformed(x: int, y: int, n: int, symmetry: int) -> tuple[int, int]:
    return (
        (x, y), (n - 1 - y, x), (n - 1 - x, n - 1 - y), (y, n - 1 - x),
        (n - 1 - x, y), (x, n - 1 - y), (y, x), (n - 1 - y, n - 1 - x),
    )[symmetry]


def canonical_signature(stage: dict) -> str:
    n, width, height = stage["width"], stage["width"], stage["height"]
    original_steps = {"N": (0, 1), "S": (0, -1), "W": (1, 0), "E": (-1, 0)}
    inverse_steps = {v: k for k, v in original_steps.items()}
    results = []
    for symmetry in range(8):
        target = [[0] * width for _ in range(height)]
        for y, row in enumerate(stage["target"]):
            for x, value in enumerate(row):
                xx, yy = transformed(x, y, n, symmetry)
                target[yy][xx] = value
        sockets = sorted(
            (chr(65 + transformed(coord_to_cell(c)[0], coord_to_cell(c)[1], n, symmetry)[0])
             + str(transformed(coord_to_cell(c)[0], coord_to_cell(c)[1], n, symmetry)[1] + 1))
            for c in stage["sockets"]
        )
        lights = []
        for light in stage["allowed_lights"]:
            dx, dy = original_steps[light]
            tx, ty = transformed(n // 2 + dx, n // 2 + dy, n, symmetry)
            cx, cy = transformed(n // 2, n // 2, n, symmetry)
            lights.append(inverse_steps[(tx - cx, ty - cy)])
        results.append(json.dumps([n, sockets, sorted(lights), stage["max_dots_per_shot"], target], separators=(",", ":")))
    return min(results)


def uses_intra_shot_protection(solution: list[dict]) -> bool:
    steps = {"N": (0, 1), "S": (0, -1), "W": (1, 0), "E": (-1, 0)}
    for shot in solution:
        cells = [coord_to_cell(coord) for coord in shot["dots"]]
        dx, dy = steps[shot["light"]]
        for index, (x, y) in enumerate(cells):
            for other_x, other_y in cells[index + 1:]:
                if (dx == 0 and x == other_x) or (dy == 0 and y == other_y):
                    return True
    return False


def main() -> int:
    if not POOL_PATH.exists():
        raise SystemExit("Run generate_stages.py first, then have Astra curate its candidate pool.")
    pool = json.loads(POOL_PATH.read_text(encoding="utf-8"))
    selection = json.loads(SELECTION_PATH.read_text(encoding="utf-8"))
    rows = selection.get("selections", selection) if isinstance(selection, dict) else selection
    if not isinstance(rows, list) or len(rows) != 80:
        raise SystemExit("Astra's manifest must contain exactly 80 new candidate selections.")
    by_id = {str(c["stage"]["id"]): c for c in pool["candidates"]}
    ids = [str(item["candidate_id"]) for item in rows]
    if len(set(ids)) != 80 or not set(ids) <= by_id.keys():
        raise SystemExit("Selections contain unknown or repeated candidate IDs.")
    tier_counts = Counter(str(r["tier"]) for r in rows if not r.get("capstone", False))
    expected_tiers = {name: 10 for name in PACKS}
    if tier_counts != expected_tiers or sum(bool(r.get("capstone")) for r in rows) != 10:
        raise SystemExit(f"Expected 10 regular selections per tier and 10 capstones, got {dict(tier_counts)}.")
    seeds = json.loads((ROOT / "data" / "stages" / "tutorial_001_020.json").read_text(encoding="utf-8"))
    seed_witnesses = json.loads((ROOT / "tests" / "stage_solutions.json").read_text(encoding="utf-8"))
    for i, stage in enumerate(seeds):
        stage["chapter_key"] = ["01 / READING LIGHT", "02 / TOGETHER & APART", "03 / HIDDEN LAYERS", "04 / EVERY DIRECTION"][i // 5]
        stage["title_key"] = [
            "First light", "A new angle", "Afterglow", "Two beginnings", "Crossing paths",
            "Better together", "The quiet space", "One at a time", "A little of both", "Less is more",
            "Read between", "Hidden layers", "Three small acts", "A different sum", "Same places",
            "Full circle", "Changing sides", "A deeper shade", "Quiet complexity", "Light, mastered",
        ][i]
        stage["hint_key"] = [
            "Tap the ring to place a DOT. Light from above casts a shadow below it.",
            "Choose where light enters. The arrow shows where the shadow travels.",
            "Shadows stay after each shot. A 2 needs two layers of shadow.",
            "Two sockets, one DOT per shot. Build one layer, then the next.",
            "Light can travel down or across. Find a place for each shadow.",
            "You can now place two DOTs before casting. Can one shot do both jobs?",
            "DOT cells receive no shadow this shot. Beyond them, shadows add up.",
            "Same sockets, a different target. What changes if you split the shots?",
            "One DOT or two? Different layers may need different groupings.",
            "Find a clear first. Then try to make the same shadows in fewer shots.",
            "Read the empty spaces, too. A zero tells you where a shadow cannot fall.",
            "Separate the target into simple layers. Which shadow belongs on its own?",
            "An aligned pair can leave a quiet space between layers.",
            "A 3 is several shadows meeting. Find the pieces of the sum.",
            "Familiar sockets, a new arrangement. Look again before casting.",
            "All four lights are available. Arrows show the direction shadows travel.",
            "Start with the cells that only one direction can reach.",
            "DOTs protect their cells while shadows continue beyond them.",
            "Small layers build a complex whole. Take your time; Undo is unlimited.",
            "Five by five. Everything you need is already in the rules.",
        ][i]
        stage["tier"] = "tutorial"
    additions = []
    witnesses = dict(seed_witnesses)
    seen = {canonical_signature(s) for s in seeds}
    regular = sorted((r for r in rows if not r.get("capstone", False)), key=lambda r: (list(PACKS).index(str(r["tier"])), int(r["order_in_tier"])))
    capstones = sorted((r for r in rows if r.get("capstone", False)), key=lambda r: int(r["order_in_tier"]))
    ordered = regular + capstones
    if len(capstones) != 10 or {int(r["order_in_tier"]) for r in capstones} != set(range(1, 11)):
        raise SystemExit("Capstone ranks must be exactly 1 through 10.")
    capstone_candidates = [by_id[str(r["candidate_id"])] for r in capstones]
    capstone_tiers = {str(r["tier"]) for r in capstones}
    capstone_large = sum(int(c["stage"]["width"]) == 5 for c in capstone_candidates)
    capstone_grouped = sum(int(c["features"]["grouped_shots"]) > 0 for c in capstone_candidates)
    if len(capstone_tiers) < 4 or capstone_large < 3 or capstone_grouped < 2:
        raise SystemExit("Capstones must span 4 source tiers, include 3 large boards and 2 grouped-shot solutions.")
    for tier in PACKS:
        entries = [r for r in regular if r["tier"] == tier]
        if {int(r["order_in_tier"]) for r in entries} != set(range(1, 11)):
            raise SystemExit(f"Ranks for tier {tier} must be exactly 1 through 10.")
    for offset, record in enumerate(ordered, 20):
        candidate = by_id[str(record["candidate_id"])]
        source = candidate["stage"]
        signature = canonical_signature(source)
        if signature in seen:
            raise SystemExit(f"Selected duplicate/symmetry of another puzzle: {record['candidate_id']}.")
        seen.add(signature)
        is_capstone = bool(record.get("capstone", False))
        tier = str(record["tier"])
        pack = CAPSTONE_PACK if is_capstone else PACKS[tier]
        pack_name = "capstone" if is_capstone else tier
        rank = int(record["order_in_tier"])
        name_pair = CAPSTONE_NAMES[rank - 1] if is_capstone else NAMES[tier][rank - 1]
        puzzle = {key: source[key] for key in ("width", "height", "sockets", "allowed_lights", "max_dots_per_shot", "target", "par")}
        puzzle.update({
            "id": f"{offset + 1:03d}", "tier": pack_name, "chapter_key": pack[0],
            "title_key": name_pair[0],
            "hint_key": HINTS[pack_name][0], "curator_reason": str(record.get("reason", "")),
        })
        additions.append(puzzle)
        solution = candidate["solution"]
        normalized_shots = [(tuple(sorted(shot["dots"])), shot["light"]) for shot in solution]
        if len(normalized_shots) != len(set(normalized_shots)):
            raise SystemExit(f"Selected witness repeats an identical shot: {record['candidate_id']}.")
        witnesses[puzzle["id"]] = solution
    final_bank = seeds + additions
    if len(final_bank) != 100 or [s["id"] for s in final_bank] != [f"{n:03d}" for n in range(1, 101)]:
        raise SystemExit("The assembled stage bank is not 001–100 in order.")
    STAGE_PATH.write_text(json.dumps(final_bank, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    WITNESS_PATH.write_text(json.dumps(witnesses, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    existing = list(csv.DictReader(CSV_PATH.open(encoding="utf-8", newline="")))
    keys = {row["keys"] for row in existing}
    generated = []
    for i in range(20):
        pack = (["01 / READING LIGHT", "02 / TOGETHER & APART", "03 / HIDDEN LAYERS", "04 / EVERY DIRECTION"][i // 5])
        generated.append({"keys": pack, "en": pack, "ja": pack})
    for en, ja, en_name, ja_name, _tag in list(PACKS.values()) + [CAPSTONE_PACK]:
        generated.extend([{"keys": en, "en": en, "ja": ja}, {"keys": en_name, "en": en_name, "ja": ja_name}])
    for tier, names in NAMES.items():
        for rank, (en_name, ja_name) in enumerate(names, 1):
            generated.append({"keys": en_name, "en": en_name, "ja": ja_name})
    for rank, (en_name, ja_name) in enumerate(CAPSTONE_NAMES, 1):
        generated.append({"keys": en_name, "en": en_name, "ja": ja_name})
    for key, (en, ja) in HINTS.items():
        generated.append({"keys": en, "en": en, "ja": ja})
    generated.append({"keys": "%d / 100 CLEARED    ·  clear    *  at PAR", "en": "%d / 100 CLEARED    ·  clear    *  at PAR", "ja": "%d / 100 クリア    · クリア    * 最短"})
    for row in generated:
        if row["keys"] not in keys:
            existing.append(row)
            keys.add(row["keys"])
    with CSV_PATH.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["keys", "en", "ja"])
        writer.writeheader()
        writer.writerows(existing)
    manifest = {"curator_model": "GPT-6 Astra", "reasoning": "xhigh", "pool_seed": pool["seed"], "pool_count": len(pool["candidates"]), "selection_count": 80, "selections": rows}
    SELECTION_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    selected_candidates = [by_id[str(record["candidate_id"])] for record in ordered]
    grouped_count = sum(int(c["features"]["grouped_shots"]) > 0 for c in selected_candidates)
    protection_count = sum(uses_intra_shot_protection(c["solution"]) for c in selected_candidates)
    above_par_count = sum(bool(c["features"]["has_easy_clear_above_par"]) for c in selected_candidates)
    large_count = sum(int(c["stage"]["width"]) == 5 for c in selected_candidates)
    par_counts = Counter(int(c["stage"]["par"]) for c in selected_candidates)
    tier_bias = {tier: sum(int(by_id[str(r["candidate_id"])]["features"]["grouped_shots"]) == 0 for r in regular if r["tier"] == tier) for tier in PACKS}
    report = [
        "# AFTERLUX: 100問の選定記録", "",
        "GPT-6 Astra / xhighによる候補評価。元の20問を導入に残し、検証済み700候補から80問を追加。",
        "PARは独立ソルバーで再確認し、最短解が一意、かつ解答中に同一SHOTの反復がないことを検証。",
        "人の試遊はまだ行っていないため、体感難易度と楽しさは編集上の見立てとして扱う。",
        "",
        f"候補プール seed: {pool['seed']} / {len(pool['candidates'])}問。追加80問のうち、複数DOTをまとめる問題は{grouped_count}問、同一SHOT内でDOTが影を受けない働きを使う問題は{protection_count}問、PAR+1手でも解ける問題は{above_par_count}問、5×5盤面は{large_count}問。PAR分布: {dict(sorted(par_counts.items()))}。",
        f"元の生成ティアだけでは難易度を表せず、選定された単独DOTだけの問題数も章により偏る: {tier_bias}。章名は攻略保証ではなく、目標の形や考え方を探る入口として扱う。",
        "",
        "## 配置", "", "| 問題 | テーマ | Astraが選んだ理由 | PAR | 盤面 |", "|---:|---|---|---:|---:|"
    ]
    for puzzle, record in zip(additions, ordered):
        reason = str(record.get("reason", "")).replace("|", "\\|")
        report.append(f"| {puzzle['id']} | {puzzle['title_key']} | {reason} | {puzzle['par']} | {puzzle['width']}×{puzzle['height']} |")
    (ROOT / "docs" / "AFTERLUX_100_PUZZLES_ASTRA_XHIGH.md").write_text("\n".join(report) + "\n", encoding="utf-8")
    print(f"Curated 100 puzzles: preserved 20 tutorial studies + {len(additions)} Astra selections.")
    print("Curriculum:", dict(Counter(s["tier"] for s in additions)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
