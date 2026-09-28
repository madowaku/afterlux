# AFTERLUX Implementation Sprint v0.1

## Goal

Build the smallest playable mobile-first vertical slice that proves the AFTERLUX loop:

> place DOTs -> choose light -> SHOT -> persistent shadow updates -> exact clear -> replay for PAR

The slice is successful when Stages 001-010 can be played from start to finish and the Stage 007 -> 008 grouping AHA is readable without prose-heavy tutorials.

## Target stack

- Engine: Godot 4.7
- Language: GDScript for the first slice
- Primary viewport: portrait mobile
- Development OS: Windows 11
- Data: JSON or Godot Resources, with rules kept deterministic and engine-independent
- Solver/Generator: separate Python tooling under `tools/`

Why Godot first:
- board/UI-heavy 2D game,
- tiny runtime scope,
- fast iteration,
- Android export,
- easy deterministic logic separation,
- good fit for AI-assisted small-script development.

## Repository target structure

```
afterlux/
  project.godot
  README.md

  docs/
    AFTERLUX_CORE_RULES_v0.1.md
    STAGE_001_020_v0.1.md
    AFTERLUX_IMPLEMENTATION_SPRINT_v0.1.md

  game/
    main/
      main.tscn
      main.gd

    board/
      board_view.tscn
      board_view.gd
      cell_view.tscn
      cell_view.gd

    ui/
      stage_header.tscn
      shot_controls.tscn
      result_panel.tscn

  src/
    core/
      afterlux_rules.gd
      shot.gd
      stage_definition.gd
      stage_state.gd

    data/
      stage_loader.gd

  data/
    stages/
      tutorial_001_020.json

  tools/
    solver/
      afterlux_model.py
      solve.py
      verify_stages.py

    generator/
      generate.py
      features.py

  tests/
    core/
      test_shadow_rules.gd
```

## Architecture rule

The renderer must not calculate puzzle truth.

`src/core/` owns:
- legal DOT placement,
- SHOT mask generation,
- accumulation,
- overshoot checks,
- solved state,
- shot count.

`game/` only renders state and converts touch input into commands.

The Python solver must implement the same mathematical model independently, so generated PAR values are not trusted just because the game runtime says so.

## Minimal data model

A stage needs:

```json
{
  "id": "001",
  "width": 4,
  "height": 4,
  "sockets": ["A1"],
  "allowed_lights": ["N"],
  "max_dots_per_shot": 1,
  "target": [
    [0,0,0,0],
    [1,0,0,0],
    [1,0,0,0],
    [1,0,0,0]
  ],
  "par": 1
}
```

Future constraints should be additive fields, not hard-coded stage subclasses.

## Core API sketch

```
AfterluxRules.make_shot(stage, dot_cells, light) -> ShotResult
AfterluxRules.apply_shot(state, shot_result) -> StageState
AfterluxRules.is_solved(stage, state) -> bool
AfterluxRules.is_overshot(stage, state) -> bool
```

A `ShotResult` should contain:
- selected DOT cells,
- light direction,
- per-cell shadow delta.

This makes Undo trivial: store SHOT history and rebuild state deterministically.

## Interaction v0.1

1. Tap a SOCKET to toggle a DOT.
2. Tap one of the available edge-light buttons.
3. The board does NOT preview resulting shadows.
4. Tap FIRE.
5. Light flashes across the board.
6. DOTs vanish.
7. Shadow values animate upward / remaining target values animate downward.
8. If exact TARGET is reached, show CLEAR.
9. If SHOT count == PAR, show PAR.
10. Undo removes the latest SHOT and rebuilds accumulated shadow.

No drag controls in v0.1. Tapping must be extremely crisp.

## Board display

Each cell shows:
- current accumulated shadow visually,
- remaining target number when non-zero,
- SOCKET marker when applicable,
- DOT when selected before firing.

Recommended first readability experiment:
- cell background darkness = accumulated shadow,
- centered numeral = remaining amount,
- small ring = SOCKET,
- filled black circle = selected DOT.

Completed cells may suppress the numeral to make progress feel like the board is becoming quieter.

## Tutorial behavior

Avoid modal explanations where possible.

- 001: only one meaningful interaction.
- 002: introduce light direction buttons.
- 003: teach persistence by repetition.
- 006: allow two DOTs in one SHOT.
- 007: visually emphasize the zero-hole behavior after firing.
- 008: reuse the exact same SOCKET geometry so the player notices grouping is now wrong.
- 010: allow CLEAR above PAR, then surface "BEST 3 / PAR 2" and invite replay.

The game should teach through neighboring puzzle contrast.

## Sprint tasks

### P0: Mathematical core
- [ ] Implement coordinate conversion.
- [ ] Implement SHOT mask for N/S/W/E.
- [ ] Enforce DOT cells = 0 for that SHOT.
- [ ] Allow rays to continue through DOT cells.
- [ ] Accumulate SHOT masks.
- [ ] Detect overshoot and exact clear.
- [ ] Implement deterministic Undo rebuild.

### P0: Stage data
- [ ] Encode 001-020.
- [ ] Validate dimensions and SOCKET coordinates.
- [ ] Assert stored PAR against Python solver.

### P0: Playable UI
- [ ] 4x4/5x5 responsive board.
- [ ] SOCKET tap toggle.
- [ ] Available-light controls.
- [ ] FIRE.
- [ ] Undo / Reset.
- [ ] SHOT counter + PAR.
- [ ] clear result.

### P1: Juice
- [ ] 120-180ms light sweep.
- [ ] DOT disappearance pop.
- [ ] shadow-count increment animation.
- [ ] subtle haptic on FIRE.
- [ ] stronger haptic on PAR.
- [ ] small overshoot warning without punitive interruption.

### P1: Persistence
- [ ] stage clear state.
- [ ] best SHOT count.
- [ ] PAR badge.
- [ ] next-stage unlock.

## Acceptance tests

### Rule test A
4x1 conceptual line, A1 DOT, N light:
`[0,1,1,1]`

### Rule test B
A1 + A2 in the same N SHOT:
`[0,0,2,2]`

### Rule test C
A1:N and then A2:N as separate SHOTs:
`[0,1,2,2]`

These three tests are the mechanical fingerprint of AFTERLUX.

## v0.1 exit criteria

- Stages 001-010 playable on desktop and Android.
- No preview before FIRE.
- Undo is reliable.
- Stage 007 and 008 visibly demonstrate group-vs-split logic.
- Stage 010 can be cleared above PAR and replayed to PAR.
- Python verification reports the same PAR as stage data.
- Core rules have automated tests.

Do not build Daily, streaks, monetization, cosmetics, cloud saves, or extra optical gimmicks before this slice feels good.
