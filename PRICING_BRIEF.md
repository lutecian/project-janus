# PROJECT JANUS — Brief for pricing & gameplay advice
Date: 2026-09-03. Engine: Godot 4.7.2 (GDScript), Windows. Single campaign-based game, no multiplayer.

## 1. What it is
A dark science-lab management sim with horror framing. You run a research facility studying anomalous artifacts: assign scientists to experiments, confirm discoveries, unlock tech, and race a field of rival labs for market majority. Win by Market majority, Scientific completion, or total Domination; lose by rival majority, staff wipe, or absorption. Text-driven UI (no 3D), procedural placeholder audio, theme-styled 2D screens.

## 2. Systems inventory (all shipped, all tested)
- Research: 12 experiments, knowledge/observation/evidence sim, discovery states, naming
- Rival field: 4 rivals (HELIOS aggressive, Bermant steady, Northwind publisher, Vantage wildcard) with share ticks, buyouts, implosions, consolidation, milestone taunts, enemy ops vs player (raid/smear/sabotage)
- Market: player share from work + discoveries + subsidiaries + contracts; difficulty-scaled majority
- Strategy: 8 acquirable companies (noisy pricing, due diligence, steal/fair/lemon, subsidiaries), 6 facilities, espionage (5 ops, Risk/Cover, caught consequences), 14 contracts (upfront + workdays + tech), 11 world events, 6 facilities incl. garrison
- Campaign structure: 3 acts (gated artifacts, escalating rival aggression), parallel experiments (day plans, up to 1/scientist/day), stress/fatigue/rest, hiring pipeline (cap 5), injuries/death/trauma, crises with countdowns
- Story/horror: per-artifact 4-beat arcs, scientist intros + incident reactions, rival directors, epilogue variants, graphic gore toggle (default ON), death memorials, badges (9) + cross-run legacy profile
- Meta: 4 difficulties (Easy/Normal/Hard/Expert, science-locked on Expert), continue-after-win (+15 target), 4 ending tiers

## 3. Content counts
6 artifacts · 10 discoveries · 7 techs · 12 experiments · 14 contracts · 11 world events · 8 companies · 14 incidents · 6 facilities · 5 espionage ops · 4 difficulties · 4 ending tiers + epilogues · 9 badges · ~17 UI screens

## 4. Measured pacing (headless bot play, optimal-ish, 9 scripted playstyles)
- Easy win ~day 24–25 · Normal pure-research win ~day 37–40 · Normal systems win ~day 25–32
- Hard pure-research loses ~day 35–43 (must engage systems, by design) · Hard systems splits by seed (~day 28–43)
- Real-time mapping ≈ 1–1.5 min/workday early, ~2 min/day late: Easy ~40 min, Normal ~1–1.5 hrs, Hard ~1.5–2.5 hrs incl. failures. Scientific/Domination runs longer (multi-artifact, buyouts).
- Full content estimate: 8–12 hrs + seeded replayability (all decks seeded; no two campaigns identical).

## 5. Quality state
- 20 automated headless suites, all green (scenes, logic, sim determinism, coverage, market, acquisitions, contracts, events, espionage, endings, depth, story, action, gore, audio, security, acts, batch, roster, pacing)
- Programmatic screenshot verification of all screens per change; balance probe rerun after every tuning change
- Known gaps: placeholder visuals (flat theme styling, no portraits/backgrounds), procedural audio never human-listened, text-heavy UI, no trailer/Steam page, no Steam achievements (badges are in-game only), no human playtest yet (deferred to pre-release)

## 6. Roadmap status
0.3 endgame, 0.4 content volume, 0.5 systems depth, 0.6 story/horror, 0.7 audio/security, 0.8 acts/roster — ALL SHIPPED. Planned next: 0.9 replay systems (seeded content subsets, scenario packs, score attack/dailies, NG+), then production pass (art, composed music, trailer) and release prep.

## 7. Questions for the pricing/gameplay model
1. Target price? (We debated $10–12 Early Access vs $20 full.)
2. Is ~1.5 hr Normal / ~10 hr completionist enough at that price, or what specifically must grow?
3. Which replay system buys the most perceived value per dev-week: scenarios, seeded subsets, score/dailies, NG+?
4. Release strategy: Early Access with 0.9, or hold for 1.0 with production pass?
5. Red flags: anything in the systems list that screams cut or rework before charging money?
