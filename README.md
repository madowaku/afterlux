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

Core Rule v0.1 and the first 20 tutorial stages are being formalized.

Target implementation: **Godot 4.7** on Windows 11, with Android/mobile as the primary platform.

## Vocabulary

- **DOT**: the black circular piece placed before a SHOT.
- **SOCKET**: a cell where a DOT may be placed.
- **SHOT**: one placement state plus one light firing.
- **TARGET**: required final shadow count per cell.
- **PAR**: verified minimum number of SHOTs.
