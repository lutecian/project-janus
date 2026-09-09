# PROJECT JANUS — Brief for pricing & gameplay advice
Date: 2026-09-07 (refreshed; was 2026-09-03). Engine: Godot 4.7.2 (GDScript), Windows. Single campaign-based game, no multiplayer. Current version 0.25, 28 automated suites green.

## 1. What it is
A dark science-lab management sim with horror framing. You run a research facility studying anomalous artifacts: assign scientists to experiments, confirm discoveries, unlock tech, and race a field of rival labs for market majority. Win by Market majority, Scientific completion, or total Domination; lose by rival majority, staff wipe, or absorption. Text-driven UI (no 3D), procedural placeholder audio, theme-styled 2D screens.

## 2. Systems inventory (all shipped, all tested)
- Research: 12 experiments, knowledge/observation/evidence sim, discovery states, naming
- Rival field: 6 rivals (HELIOS aggressive, Bermant steady, Northwind/Solenne publishers, Vantage/Kitezh wildcards) with share ticks, buyouts, implosions, consolidation, milestone taunts (4 lines each), enemy ops vs player (raid/smear/sabotage/poach), 40-share signature moves, act-3 endgame moves
- Market: player share from work + discoveries + subsidiaries + contracts; difficulty-scaled majority (44/52/58/62)
- Strategy: 8 acquirable companies (noisy pricing, due diligence, steal/fair/lemon, subsidiaries, hostile bids), 24 facilities in 3 tiers (+6 prize rooms), espionage (6 ops incl. poach, Risk/Cover, caught consequences), 25 contracts (upfront + workdays + tech), 18 world events, loans ($2k/$5k/$10k, 2%/day, overdue collectors)
- Campaign structure: 3 acts (gated artifacts, escalating rival aggression), parallel experiments (day plans, up to 1/scientist/day), stress/fatigue/rest, hiring pipeline (cap 5, 3 ex-rival hireables), loyalty + resignations, injuries/death/trauma, 6 crisis kinds with pay/team/study resolution, guided first-timer tour
- Story/horror: per-artifact 4-beat arcs (18), scientist intros + incident reactions (6 staff), rival directors, margin/depth/devourer epilogues, graphic gore toggle (default ON), death memorials + infirmary, badges (17) + cross-run legacy profile + Steam achievement mirror
- Meta: 4 difficulties (Easy/Normal/Hard/Expert, science-locked on Expert), continue-after-win (+15 target), 4 ending tiers, 10 scenarios, daily/weekly challenges, mutators, NG+, hidden post-absorption recovery branch

## 3. Content counts
18 artifacts · 34 discoveries · 7 techs · 12 experiments · 25 contracts · 18 world events · 8 companies · 29 incidents · 24 facilities (3 tiers + prizes) · 6 espionage ops · 6 crisis kinds · 10 scenarios · 4 difficulties · 4 ending tiers + 9 epilogue variants · 17 badges · ~20 UI screens

## 4. Measured pacing (headless bot play, sane-player model: DD-first buying, crisis pay-resolve, loan bridges)
- Easy win ~day 25 · Normal pure win ~day 27–37 · Normal systems win ~day 20 · Normal batch win ~day 17
- Hard pure loses ~day 40 (must engage systems, by design) · Hard systems usually wins (~day 27–38) · Hard skilled splits
- Expert batch winnable (~day 23–28) · all other Expert styles lose ~day 30
- Real-time mapping ≈ 1–1.5 min/workday early, ~2 min/day late: Easy ~40 min, Normal ~1–1.5 hrs, Hard ~1.5–2.5 hrs incl. failures. Scientific/Domination runs longer (multi-artifact, buyouts).
- Full content estimate: 12–18 hrs + seeded replayability (all decks seeded; no two campaigns identical).

## 5. Quality state
- 28 automated headless suites, all green (scenes, logic, sim, coverage, market, acquisitions, contracts, events, espionage, endings, depth, story, action, gore, audio, security, acts, batch, roster, replay, challenges, recovery, tutorial, medical, map, ability, loans, pacing)
- Programmatic screenshot verification of all screens per change; balance probe rerun after every tuning change
- Known gaps: placeholder visuals (flat theme styling, shader portraits, no key art), procedural audio never human-listened, text-heavy UI, no trailer/Steam page, Steam SDK not yet wired (mirror file ready), no human playtest yet (deferred to pre-release)

## 6. Roadmap status
0.3 endgame through 0.25 content/systems/replay/onboarding — ALL SHIPPED (see CHANGELOG.md). Remaining before release: production pass (key art, composed music, trailer), human playtest, Steam page + SDK wiring, export smokes.

## 7. Questions for the pricing/gameplay model
1. Target price? (We debated $10–12 Early Access vs $20 full — now leaning $20 with 12–18 hr estimate.)
2. Is the horror framing a selling point or a niche filter at that price?
3. Release strategy: Early Access now, or hold for 1.0 with production pass?
4. Red flags: anything in the systems list that screams cut or rework before charging money?
