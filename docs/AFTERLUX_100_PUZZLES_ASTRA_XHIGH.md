# AFTERLUX: 100問の選定記録

GPT-6 Astra / xhighによる候補評価。元の20問を導入に残し、検証済み700候補から80問を追加。
PARは独立ソルバーで再確認し、最短解が一意、かつ解答中に同一SHOTの反復がないことを検証。
選定時点（2026-09-29）では人の試遊は未実施だった。その後、2026-10-28にStage 040まで試遊した所感を[中間レポート](AFTERLUX_HUMAN_PLAYTEST_REPORT_v0.2.md)に記録した。Stage 041–100は未試遊のため、体感難易度と楽しさは引き続き編集上の見立てとして扱う。

候補プール seed: 20260929 / 700問。追加80問のうち、複数DOTをまとめる問題は44問、同一SHOT内でDOTが影を受けない働きを使う問題は30問、PAR+1手でも解ける問題は47問、5×5盤面は26問。PAR分布: {2: 9, 3: 35, 4: 26, 5: 10}。
元の生成ティアだけでは難易度を表せず、選定された単独DOTだけの問題数も章により偏る: {'aha': 1, 'crossings': 7, 'grouping': 0, 'four_lights': 9, 'hard_logic': 7, 'large_board': 5, 'mastery': 5}。章名は攻略保証ではなく、目標の形や考え方を探る入口として扱う。

## 配置

| 問題 | テーマ | Astraが選んだ理由 | PAR | 盤面 |
|---:|---|---|---:|---:|
| 021 | A Place for Quiet | C1 shields C4's upward beam; C4's sideways shot supplies the separate two-cell bar. | 2 | 4×4 |
| 022 | Between the Rays | The same adjacent pair makes vertical traces and a doubled horizontal trace while keeping B2 clear. | 2 | 4×4 |
| 023 | An Empty Step | B2's required 1 forbids grouping the upward shots; the right arm adds a clean directional change. | 3 | 4×4 |
| 024 | The Missing Number | Equal upper traces and unequal lower traces identify shared and solo layers. | 3 | 4×4 |
| 025 | A Narrow Silence | The 2-0-2-1 row requires shielding B1; the lower bar anchors the other direction. | 2 | 4×4 |
| 026 | Something Left Out | B4 receives one layer while being protected in another, distinguishing solo from grouped shots. | 3 | 4×4 |
| 027 | The Gentle Gap | A zero at D3 and a 3 beneath it force a protected double layer plus a solo layer. | 3 | 4×4 |
| 028 | Before the Shadow | Unequal vertical stripes and the doubled bottom tip require different groupings for the two directions. | 3 | 4×4 |
| 029 | Still a Little Room | Unequal lower counts identify two vertical pairs; the isolated 2 fixes the horizontal pair. | 3 | 4×4 |
| 030 | Where Light Pauses | The upper 2 and middle zero constrain the aligned southern group; the left column needs another layer. | 3 | 4×4 |
| 031 | Meet Me in the Middle | The centre 2 needs perpendicular rays from other sockets; its own socket cannot light itself. | 2 | 4×4 |
| 032 | A Second Approach | The lower crossing is 2 while the upper bar stays 1, exposing the vertical layer. | 3 | 4×4 |
| 033 | The Corner Between | A stepped outline makes the corner 2 readable as a crossing; neighbouring 1s fix ray lengths. | 3 | 4×4 |
| 034 | A Crossing, Twice | A vertical spine passes through only one horizontal bar, creating a decisive 2. | 3 | 4×4 |
| 035 | A Quiet Intersection | Two aligned 2s reveal one vertical ray shared by two horizontal layers. | 3 | 4×4 |
| 036 | From Here and There | The two crossings have unequal horizontal extents, demanding distinct sources. | 3 | 4×4 |
| 037 | The Other Row | The complete top edge includes a socket lit from below; the side 2 identifies the third direction. | 3 | 4×4 |
| 038 | Parallel Thoughts | A solo horizontal layer supplies the extra left contribution while two differently directed groups explain the shape. | 3 | 4×4 |
| 039 | Almost Together | The protected A3 zero and unequal bottom counts force three different pairs in a compact target. | 3 | 4×4 |
| 040 | A Meeting of Shadows | The 3-1-2 column encodes partial protection; the lower staircase fixes the opposite-direction pair. | 3 | 4×4 |
| 041 | Together, Not Twice | Opposite directions reuse A2 while keeping it zero and creating different layers above and below. | 2 | 4×4 |
| 042 | The Split Decision | Two groups share D2; the central 2 reveals their crossing and the clear third row constrains direction. | 2 | 4×4 |
| 043 | Paired in Silence | A triple group protects C3 yet doubles C4; the horizontal pair supplies the left staircase. | 2 | 4×4 |
| 044 | One More Together | Two shots explain a stepped block through three crossings, with a three-DOT horizontal layer enabling compression. | 2 | 4×4 |
| 045 | In Two Movements | B2's 1 within a 3-1-2 row means protection occurs in only one horizontal group. | 3 | 4×4 |
| 046 | The Grouping Problem | Adding B4 increases the upper stripe without lighting the protected B3 socket. | 3 | 4×4 |
| 047 | A Shared Beginning | The triple group extends the top bar while D2 stays protected during both horizontal shots. | 3 | 4×4 |
| 048 | Split the Difference | Two triple groups create different holes in adjacent columns; the bottom 3 records unequal overlap. | 2 | 4×4 |
| 049 | An Unexpected Pair | The central crossing resolves an upward pair and solo leftward ray; two lower bars then compress together. | 3 | 4×4 |
| 050 | Together or Apart | The 3-3-2 vertical profile requires protecting the final socket in one layer and lighting it in others. | 4 | 4×4 |
| 051 | North, Then Quiet | Opposite vertical rays and a bottom bar provide a readable three-direction entry with one crossing. | 3 | 4×4 |
| 052 | East of the Answer | A corner emits in two directions; a short opposing ray explains the lone 2. | 3 | 4×4 |
| 053 | A Change of Bearing | The 2 above a 1 separates horizontal contribution from the upward beam, with a distinct bottom ray. | 3 | 4×4 |
| 054 | One Cell, Four Ways | A filled socket on the horizontal bar demonstrates that protection applies only during that DOT's own shot. | 4 | 4×4 |
| 055 | The Far Edge | Three directions from C2 leave it empty; the edge ray explains the single doubled cell. | 4 | 4×4 |
| 056 | Light Comes Around | The lower 1-2-1 bar identifies the solo ray; grouped vertical layers account for the upper rectangle. | 3 | 4×4 |
| 057 | Across the Board | The full bottom row hides opposing rays; the upper 2 identifies another horizontal contribution. | 4 | 4×4 |
| 058 | The Opposite Edge | Two offset 2s require four directions, with zeros separating the horizontal levels. | 4 | 4×4 |
| 059 | Every Way Home | Two corner-like sources use all four directions, each crossing giving a distinct source clue. | 4 | 4×4 |
| 060 | Directional Thinking | A frame and central spine create three crossings; all four directions contribute through distinct shots. | 4 | 4×4 |
| 061 | Count Backwards | The right-hand 2 links an upward edge ray to a short horizontal ray; the left bars require separate sources. | 4 | 4×4 |
| 062 | The Only Way In | The bottom row splits around B4, while the top 2 links a vertical spine and horizontal ray. | 4 | 4×4 |
| 063 | A Deliberate Detour | The middle 2 and isolated lower tail distinguish plausible column sources, making zeros useful constraints. | 4 | 4×4 |
| 064 | The Sum of Small Things | The 2-2-3-1 bar combines solo and grouped horizontal shots with an opposing vertical pair. | 3 | 4×4 |
| 065 | Prove the Zero | A middle zero interrupts a column; upper and lower remnants force different pairings in opposite directions. | 4 | 4×4 |
| 066 | Narrowing the Field | Three horizontal bands and a shared vertical trace form a coherent five-layer decomposition. | 5 | 4×4 |
| 067 | First Principles | Two directional hubs decompose differently; the central 2 prevents reading the target as parallel stripes. | 5 | 4×4 |
| 068 | A Case for Patience | A staircase of 1s and 2s connects the lower horizontal ray to two separate upward sources. | 5 | 4×4 |
| 069 | Look Twice | The full top row conceals three contributions; the vertical 1-2-1 profile requires opposing directions. | 5 | 4×4 |
| 070 | Careful Arithmetic | The 1-1-3-4 top row requires partial protection and a perpendicular contribution in only three grouped shots. | 3 | 4×4 |
| 071 | An Open Horizon | The full-height 1-1-2-2-1 column exposes opposing sources; its side arm identifies the third shot. | 3 | 5×5 |
| 072 | Five Rows of Calm | A broad corner frame uses the fifth-row source meaningfully; the short left column explains its lone 2. | 3 | 5×5 |
| 073 | The Long Way Across | A low horizontal arm, crossing 2 and unequal tails give each of four rays a visible role. | 4 | 5×5 |
| 074 | More Room to Think | The bottom crossing joins a long central trace to a short right branch, using the lower edge. | 4 | 5×5 |
| 075 | Space Between | The 2-1-2 row distinguishes overlapping horizontal rays from the vertical spine. | 4 | 5×5 |
| 076 | A Larger Silence | Three doubled horizontal bands force a cycle of different pairs; northern tips anchor the remaining direction. | 4 | 5×5 |
| 077 | A Wider Angle | The central gap needs an edge DOT as a shield; the same pair explains two horizontal bars. | 3 | 5×5 |
| 078 | The Quiet Distance | Equal long vertical traces meet unequal lower bars, exposing the extra solo horizontal layer. | 3 | 5×5 |
| 079 | Look to the Edges | Two lower columns and unequal horizontal bars distinguish a vertical group from solo-plus-group compression. | 3 | 5×5 |
| 080 | Room for One More | Three sockets generate two crossings and a local 3; every paired shot has a different visible footprint. | 3 | 5×5 |
| 081 | A Patient Light | Two narrow bands hide opposing ray lengths and one vertical contribution; six sockets create source choices. | 4 | 5×5 |
| 082 | The Hidden Decomposition | The bottom 1-2-2-3-2 profile combines opposing edge rays with unequal downward columns. | 4 | 5×5 |
| 083 | Three Lines Meet | The quiet upper column constrains the lower 2 and 3, yielding five distinct layers in a narrow shape. | 5 | 5×5 |
| 084 | A Subtle Difference | Three crossings form a ladder; the 1-2-3-2-1 column explains opposing vertical sources. | 5 | 5×5 |
| 085 | Every Shot Matters | Two separated hubs use all four directions; the crossings determine which hub supplies each arm. | 5 | 5×5 |
| 086 | A Measured Shadow | A stepped upper block and split lower tails link four layers, requiring both solo and grouped southern shots. | 4 | 5×5 |
| 087 | The Last Direction | The 2-1-4-4-3 column needs different endpoints protected in different shots; the edge tail fixes the auxiliary DOT. | 3 | 5×5 |
| 088 | A Study in Restraint | A completely clear middle row coexists with a lower 1-3-1 bar, forcing protection and a crossing. | 3 | 5×5 |
| 089 | Nothing by Chance | Opposing triple groups form unequal lower bands; the central upward ray explains the remaining counts. | 4 | 5×5 |
| 090 | Shadows in Balance | Horizontal and vertical groups protect intersecting holes; sparse 3s and 2s resolve the three-shot synthesis. | 3 | 5×5 |
| 091 | The Light We Learned | Two protected holes, a crossing and an unequal bottom band make four layers reconstructible on 4×4. | 4 | 4×4 |
| 092 | All the Ways Home | The 1-2-3-1 top edge unifies four directions and a vertical socket contribution through five distinct rays. | 5 | 4×4 |
| 093 | The Longest Quiet | The dense lower band becomes readable through the asymmetric 3 and partially protected A4 socket. | 4 | 4×4 |
| 094 | Everything in Its Place | Three crossings bind five distinct rays across all four directions; zeros constrain the busy centre. | 5 | 4×4 |
| 095 | The Hidden Whole | The 2-2-3-1-2 spine demands solo and grouped opposite beams plus a horizontal layer. | 4 | 5×5 |
| 096 | A Last, Little Gap | The 3-1-2-2 horizontal profile and upper 3 require different protections in perpendicular grouped shots. | 4 | 5×5 |
| 097 | Keep the Light Moving | One distant pair changes role between vertical shielding and horizontal bars, with all four directions essential. | 4 | 5×5 |
| 098 | The Shape of Together | Opposing triple groups preserve different gaps; the upper rectangle anchors the broad lower structure's decomposition. | 4 | 5×5 |
| 099 | An Answer in Layers | Five different grouped layers explain a dense stepped field, including a socket protected in only one layer. | 5 | 5×5 |
| 100 | After the Final Ray | Four groups reconcile protection in both axes, a top 3 and a quiet lower scaffold: the strongest synthesis. | 4 | 5×5 |
