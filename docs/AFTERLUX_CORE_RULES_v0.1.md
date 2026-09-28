# AFTERLUX Core Rules v0.1

## 1. Board

- Rectangular grid, initially 4x4 and later 5x5+.
- Cells may be ordinary cells or **SOCKETS**.
- A SOCKET is a legal placement cell for a DOT.
- Each stage defines a non-negative integer **TARGET** for every cell.

## 2. DOT

A **DOT** is the opaque piece placed on a SOCKET before firing.

Important rule:

> During a SHOT, every cell occupied by a DOT receives 0 shadow for that SHOT, even if another DOT's shadow would otherwise pass through it.

A DOT does not stop the shadow ray. The ray continues beyond it.

## 3. SHOT

A SHOT consists of:

1. Select the allowed number of SOCKETS.
2. Place DOTs.
3. Select or use the required light direction.
4. Fire.
5. Add the resulting shadow mask to the persistent board.
6. Remove all DOTs before the next SHOT.

Initial light directions:

- N: light enters from north, shadow extends south.
- S: light enters from south, shadow extends north.
- W: light enters from west, shadow extends east.
- E: light enters from east, shadow extends west.

## 4. Shadow accumulation

Each DOT contributes +1 shadow to every downstream cell in its row/column, except cells occupied by DOTs during that SHOT.

Examples for one column, N light:

One DOT:

```
DOTS    SHADOW
●       0
.       1
.       1
.       1
```

Two DOTs in the same SHOT:

```
DOTS    SHADOW
●       0
●       0
.       2
.       2
```

The same two DOT placements split across two SHOTs can instead produce:

```
0
1
2
2
```

Therefore grouping and separating DOTs are mechanically distinct actions.

## 5. Clear condition

A stage clears when accumulated shadow values exactly match TARGET on every cell.

Overfilling a cell is invalid for an exact solution. The UI may allow experimentation and Undo, but the solved state requires equality.

## 6. PAR

**PAR** is the proven minimum number of SHOTs required to match TARGET.

- CLEAR: any valid exact solution.
- PAR: a solution using the verified minimum number of SHOTs.
- Player best is stored separately from clear state.

The intended loop is:

> Solve first. Compress later.

## 7. Stage constraints

Stages may vary using only declarative constraints:

- Available SOCKETS.
- Allowed light directions.
- Maximum or exact DOT count per SHOT.
- Fixed DOT count on specific turns.
- Fixed light direction on specific turns.
- One-use SOCKETS.
- Light-use budgets.
- Cooldown / sequencing rules.
- Board size.

These are optional families. The base game should remain deep without requiring many gimmicks.

## 8. Core puzzle families

1. FREE: choose DOTs and light freely.
2. SOLO: a correct solution requires one-DOT SHOTs.
3. STACK: a correct solution requires grouping DOTs.
4. MIX: DOT count varies by SHOT.
5. LIGHT SCRIPT: light directions are prescribed.
6. DOT SCRIPT: DOT positions are prescribed; choose light.
7. ONE USE: SOCKETS cannot be reused.
8. LIGHT BUDGET: each direction has limited uses.
9. GOLF: easy clear, harder PAR compression.
10. COOLDOWN: order itself matters.

## 9. Design principle

Difficulty should primarily come from the combinatorics of:

- SOCKET geometry,
- grouping vs splitting,
- direction choice,
- accumulated counts,
- and PAR compression.

Do not add mirrors, blockers, portals, etc. until the base system has been mined thoroughly.
