# AFTERLUX

A mobile-first daily logic puzzle about placing dots, firing light, and layering shadows until every target value is satisfied.

## Core idea

- Place one or more **DOTs** on allowed **SOCKETs**.
- Choose a light direction and fire a **SHOT**.
- DOT cells themselves receive no shadow during that SHOT.
- Shadows persist and stack across SHOTs.
- Match the target shadow values to clear the puzzle.
- Any valid clear counts, but the real challenge is reaching **PAR**, the proven minimum number of SHOTs.

## Design goals

- Pure logic first: minimal story, fast restart, daily-play friendly.
- Easy to clear gradually, hard to optimize.
- Small ruleset with deep combinatorics.
- Generator + Solver verified PAR values.
- Mobile portrait as the primary play surface.
- Keep AFTERLUX distinct from NOXSUM: this is the abstract daily-puzzle branch.

## Current status

The first 100 studies are playable with a polished portrait interface, Kenney
lighting/particles/audio/icons, Undo, per-study resume, saved personal bests,
study selection, Japanese/English switching, and sound/reduced-motion settings. CLEAR and proven-PAR results
are celebrated separately. Daily play is a design proposal, not a shipped mode.

Design direction and next experiments (Japanese):
[小さなひらめき、深い最短手](docs/AFTERLUX_DESIGN_DIRECTION_v0.2.md).
The 80 additions were selected from a solver-checked pool by GPT-6 Astra (xhigh);
the selection notes and per-puzzle rationale are in
[the curation record](docs/AFTERLUX_100_PUZZLES_ASTRA_XHIGH.md).

Target implementation: **Godot 4.7** on Windows 11, with Android/mobile as the primary platform.

Open `project.godot` in Godot and run the main scene. Tap a ring, choose the light
source (arrows show shadow travel), then CAST LIGHT. The menu opens all 100 studies.
Tab / Enter supports keyboard navigation; Ctrl+Z undoes the latest shot.
Open the info button to switch between 日本語 and English without losing the
current board or pending selections. Language preference is saved; first launch
uses Japanese on a Japanese device, and English otherwise. Noto Sans JP is bundled
under the included SIL OFL license so Japanese works without system fonts.

## Verification

```powershell
python tools/solver/verify_stages.py
& 'path/to/Godot_console.exe' --headless --path . --script tools/smoke_test.gd
& 'path/to/Godot_console.exe' --headless --path . --script tests/gameplay_flow.gd
```

Import the project once before running the GDScript tests. For a complete local
logic check with isolated test saves and captured diagnostics:

```powershell
./tools/verify.ps1 -GodotBin 'C:/Dev/Tools/Godot-4.7-stable/Godot_v4.7-stable_win64_console.exe'
```

The Python solver proves PAR, checks the documented solution, and counts optimal
SHOT multisets independently of Godot. The gameplay test exercises every study,
above-PAR clears, Undo, overshoot recovery, resume, settings and navigation.
`tests/ui_*.json` are rendered input/layout scenarios for the Godot skill's
`scenario_runner.gd`; their disposable saves and images go under `artifacts/`.

To reproduce the candidate pool and the curated bank, run
`python tools/solver/generate_stages.py --seed 20260929 --per-tier 100 --pool artifacts/candidate_pool_for_astra.json`,
then `python tools/solver/curate_stage_bank.py`. The checked-in Astra selection
manifest records the 80 candidate IDs and selection rationale.

Asset provenance and original CC0 licenses: [Kenney assets](assets/kenney/README.md).
Android export and device validation are still pending.

## Vocabulary

- **DOT**: the black circular piece placed before a SHOT.
- **SOCKET**: a cell where a DOT may be placed.
- **SHOT**: one placement state plus one light firing.
- **TARGET**: required final shadow count per cell.
- **PAR**: verified minimum number of SHOTs.
