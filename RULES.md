# Hexa Sort — RULES.md
_Authoritative source of truth for the Hexa Sort implementation (v2.0, 2026-10-09).
If the implementation conflicts with this document, fix the implementation._

## 1. Objective
Sort every hex tile so that each occupied tube holds exactly one color
(a full tube of 4 matching hexes). The level is won when all tubes are
either empty or full of a single color.

## 2. Setup
- Tube capacity: **4** hexes each.
- A level deal contains `C` colors × 4 hexes, shuffled, dealt round-robin
  into `C` tubes, plus `E` empty spare tubes:
  - Easy: `C` = 3 + (level−1)÷2, max 5 · `E` = 3 spare tubes
  - Medium: `C` = 3 + (level−1)÷2, max 7 · `E` = 2 spare tubes
  - Hard: `C` = 4 + (level−1)÷2, max 8 · `E` = 2 spare tubes
- There are 50 levels per difficulty; finishing a level unlocks the next.
- A deal that is already solved, or that has no legal pour, is never
  presented — it is re-dealt automatically.

## 3. Turn order
Solo puzzle: the player acts freely, one pour at a time. There is no
opponent and no turn clock. While a pour animation is running, input is
locked; the engine owns the pour and settles it on its own timer.

## 4. Legal moves
A pour from tube F to tube T is legal iff ALL hold:
1. F ≠ T, F is non-empty.
2. T has fewer than 4 hexes (room for at least one more).
3. T is empty OR the top hex of T matches the top hex of F.
4. It is not a no-op (see §5).

A legal pour moves the **entire contiguous top run** of F's top color,
up to the free space in T (e.g. F = [R, B, B, B], T = [B, B] →
moves two B's, not three, because T only has room for two).

## 5. Illegal moves
- Pouring onto a different color.
- Pouring into a full tube.
- Tapping an empty tube to lift it, or tapping anything while a pour is
  animating.
- **No-op pours**: pouring a full tube of one color into an empty tube
  changes nothing and counts as a wasted move — it is rejected with an
  invalid sound. (Same for any pour that would move zero hexes.)

## 6. Captures
Not applicable — no pieces are captured in Hexa Sort.

## 7. Special rules
- **Undo**: replays the most recent pour backwards, one hex at a time.
  Undoing reduces the move count by one. Undo is always available after
  any pour, including on a stuck board.
- **Hints**: the engine suggests one useful legal pour, preferring moves
  that complete a tube or land on a matching color. Free tier: 3 hints per
  level; PRO: unlimited.
- **Daily Challenge**: one seeded deal per calendar day (seed =
  YYYYMMDD), identical for all players. Completing it records a daily win
  and extends the streak when done on consecutive days. Replaying a
  completed daily is allowed.

## 8. Scoring
- Each completed pour = 1 move.
- **Par** = `C × 4 + E × 4`. Finishing at or under par = a clean solve.
- Best move count is recorded per difficulty + level; beating it shows a
  "new best" celebration.

## 9. Winning conditions
All tubes are empty or hold exactly 4 hexes of one color. On win the
engine enters `winning`, plays the win fanfare, then settles to `over`
and the victory dialog appears (moves, best, next/replay/menu).

## 10. Draw conditions
Not applicable. However a board can have **no legal pours while not won**
(a dead end). This is NOT a loss: Undo and Restart are always available,
the banner says so explicitly ("No moves left — Undo or Restart"), and
undoing any number of pours always recovers. Stuck states are impossible
by construction: every phase has a legal forward action.

## 11. AI strategy
Not applicable (no opponent). The hint system uses the greedy rule from
§7: prefer pours that complete a tube (dest ends full), then pours onto a
matching color, then any legal pour onto an empty tube.

## 12. Edge cases
- A deal that is instantly won → re-dealt.
- A deal with no legal opening pour → re-dealt (impossible in practice
  because spare tubes always exist, but enforced anyway).
- Pouring the last hexes out of a tube leaves it empty and usable.
- Undo with an empty history → invalid sound, no state change.
- Tapping the selected tube again deselects it.
- Backgrounding mid-pour: the engine pauses its timer; on resume the
  watchdog re-arms the current phase — the pour continues, never freezes.

## 13. Test cases
1. Deal integrity: total hexes = C×4, each color appears exactly 4 times.
2. Legal pour onto matching color moves the full contiguous run (or as
   many as fit).
3. Legal pour onto an empty tube moves the full run.
4. Pouring a full single-color tube into an empty tube is rejected.
5. Pouring onto a different color is rejected.
6. A completed tube (4 of one color) stays won; win fires only when ALL
   tubes are empty-or-complete.
7. Undo restores the exact pre-pour board and decrements moves by 1.
8. Hint never suggests an illegal pour; hintsLeft decrements (free) or
   stays infinite (PRO).
9. Stuck board (no legal pours, not won) shows the undo/restart banner
   and the stuck sound plays exactly once per dead end.
10. Killing the phase timer mid-pour (watchdog path) resumes and settles
    the pour.
