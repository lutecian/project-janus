# CHANGELOG

## [Unreleased / 0.3.0] - planned
- Full endgame + systems roadmap committed to `ENDGAME.md` (design locked): rival ecology, market model + win/lose, multi-path graded endings + Domination, acquisitions + shrewdness, espionage, contracts + world events, difficulty, badges/titles. Phased, data-driven, additive.
- Phase 1 shipped (finite game): 4-rival field (HELIOS/Bermant/Northwind/Vantage) with daily market ticks, player market from experiments + confirmed discoveries, majority victory (46 Normal / 38 Easy / 52 Hard) vs rival-majority defeat, game-over screen, difficulty select on campaign creation, save/load of difficulty + markets + rivals + game_over. Suites: MARKET_OK + PACING_OK (active research wins ~day 32, idle loses ~day 33 on Normal).
- Phase 2 shipped (strategy layer): acquisition catalog (`data/acquisitions/companies.json`, 4 labs with hidden true values + tech portfolios + deadlines), noisy listed pricing (0.6–1.6x), 2-level due diligence ($400/$900, ±25%/±10% estimates), steal/fair/lemon classification driving subsidiary output (1.5x/1.0x/0.25x), owned-company daily research + staggered tech unlocks, expiring offers grabbed by rivals, wildcard implosions/exits, rival buyouts (share-capped market transfer), Domination ending (every rival acquired/bankrupt/exited/outgrown 2x) ranked as The Monopoly, Acquisitions screen + lab nav. Suite: ACQ_OK (pricing/DD/classify/tick/expiry/domination/save-load).
- Phase 3 shipped (meaning layer): requested-research contracts (`data/contracts/contracts.json`, one slot at a time, workdays are the cost, upfront + completion pay + side-path tech + market prestige, event-gated offers), world events (`data/events/world_events.json`, 2 seeded per campaign, rival/player/funds effects + contract unlocks, never hard-lock), espionage (`data/espionage/espionage_ops.json`, 5 ops with Risk/Cover meters, heat decay, caught → scandal incident + rival surge), Scientific victory (full confirmation + tech depth or 3-artifact collection) with tier order monopoly > researcher > market_leader, epilogue variants, 8 badges + cross-run legacy profile (`user://janus_legacy.json`, best titles by difficulty on main menu). Suites: CTR_OK + EVT_OK + ESP_OK + END_OK (tier order, badges, legacy persistence).
- Balance playtest pass (`tests/balance_probe.tscn`, 9 scripted playstyles): Easy pure wins ~day 18, Normal pure ~day 27–32, Normal systems ~day 25 and richer, Hard pure loses ~day 30–35 (must engage systems, as intended), Hard systems wins ~day 29–32 both seeds. Retuned from probe evidence: Hard rival multiplier 1.4→1.1, Hard discovery gain 11→12, Hard start budget 8000→9000, Hard espionage cost ×1.3→×1.2, domination crush bar 0.5→0.4 (keeps Market Leader distinct from Monopoly on Easy). All 11 suites still green.
- 0.4 content volume (length pass): 3 new artifacts (Choir Glass, Winter Seed, Obsidian Torus, 2 discoveries each) + 3 new techs (Resonance Amplifier, Cryo Lattice, Deep Field Probe) with centralized `TECH_KEY_MAP`, +6 contracts (12), +4 world events (11), +4 companies (8, staggered arrival day 0/12/25), +4 incidents (10). Majority targets raised for longer campaigns (Easy 38→44, Normal 46→52, Hard 52→58), funding schedule extended to day 40, subsidiary output halved against snowball, Easy gains slowed. Probe-verified: Easy ~day 24, Normal pure ~day 37 / systems ~day 26–31, Hard pure loses ~day 43, Hard systems wins both seeds ~day 29–37. All 11 suites green.
- 0.5 systems depth: facilities (`data/facilities/facilities.json`, 5 one-time builds — lab output, shielded containment, trading desk, intel cell, deep scanner — with hooks into knowledge/incidents/market/cover/DD), enemy rival ops (aggressive/wildcard rivals raid/smear/sabotage past day 10, countered by cover + shielding, reported as intel), rival consolidation (leaders absorb sub-5% rivals; absorbed counts as crushed, no domination soft-lock), continue-after-win (+15 target, resume toward Monopoly; refused on defeat/monopoly), Expert difficulty (target 62, science-locked per design). Facilities screen + lab nav + game-over continue button + Expert option. Suite: DEPTH_OK (buy/effects, op math + sabotage halving, consolidation, continue, expert lock, save/load).
- 0.6 story, action & horror (horror-forward: graphic content ON by default, toggle in Settings): artifact story arcs (`data/narrative/artifact_arcs.json`, dormant/suspected/confirmed/danger beats for all 6 artifacts, field log on artifact detail), scientist intros + per-severity incident reactions, rival directors with milestone taunts, crisis countdowns on major incidents (pay to resolve, send a response team at injury risk, or suffer expiry: -$3000 + casualties), graphic incident descriptions for all 10 existing + 4 new horror incidents (Aperture Shear, Frostbite Casualty, Choir Deafening, Critical Exposure), injury/death/trauma states (INJURED ×0.7 quality, DECEASED unassignable, First Blood badge, casualty damage on incidents). Suites: STORY_OK + ACTION_OK + GORE_OK (toggle gating, thresholds, exact quality penalty, death refusal, save/load).
- 0.7 atmosphere + security: procedural horror audio (`AudioManager` autoload, all synthesized — dark drone, tension layer, 8 stingers; volume slider now drives the bus; menu/lab/endgame hooks), death memorial overlay with fade, security stat (base 20 + garrison, dampens incidents + enemy ops), military alignment (ties from military contracts, facility/buyout discounts, Sentinel gated at 25 ties, Blacksite gated on war), Security Garrison facility, staff-wipe defeat ending (all-dead roster ends the run instead of soft-locking — found via probe). Suites: AUDIO_OK + SEC_OK. All 17 suites green.
- 0.8 acts + roster (length × density): 3 acts (`data/meta/acts.json` — Containment/Escalation/Endgame, confirmation-gated artifact unlocks, rival aggression 1.0/1.15/1.5), parallel experiments via day plans (`run_day_batch`, per-experiment lab ticks + one shared day tick), stress/fatigue economy (+4 work, -8 rest, >70 penalty), hireable roster (Lund/Osei/Petrova, signing bonuses, living cap 5, deaths free slots). Lab shows locks/candidates/act; experiment screen queues + Run Day; locked artifacts skipped in cycling. Fixed two real progression bugs found by tests: artifact switching discarded in-session confirmations, and J002/J003 IDs (`J-002`) never matched their discoveries. Retuned: normal gain 0.8. Probe: easy d25, normal pure d37 / systems d25-29, hard-systems splits, hard-skilled mixed. Suites: ACTS_OK + BATCH_OK + ROSTER_OK. All 20 suites green.
- 0.9 replay systems: run scoring (win base × difficulty + speed + badges + continued bonus; losses score on merit, stored on game_over + best-per-difficulty legacy + menu top score), seeded company subsets (4 core + 2 of 4 late, deterministic Fisher-Yates), 4 scenarios (`data/scenarios/scenarios.json` — Sandbox/Winter Seed/Corporate Sprint/Skeleton Crew with fixed seeds, start artifacts, funds/rival tweaks, roster cuts, act starts; picker on campaign creation). Fixed `confirmed_discoveries` cross-campaign leak found by tests. Retuned hard mult 1.1→1.0 after acts headwind. Probe over 4 hard seeds: 2–2 systems wins. Suite: REPLAY_OK. All 21 suites green.
- 0.10 challenges, variation & NG+: daily challenge (date seed + 1 of 4 mutators — Famine/Glass/Sprint/Bounty — with funding/casualty/target/buyout/score hooks, best-daily legacy, menu button), 2 new rivals (Solenne, Kitezh) with seeded 4-rival deal (HELIOS + 3 of 5), shuffled contract deck, NG+ (opt-in: +$1500/level funds, +5%/level rivals, +10%/level score, level from career wins, creation checkbox), batch-mode probe sims (batching halves days, densifies play — no target change needed). Suite: CHAL_OK. All 22 suites green.
- 0.11 post-absorption recovery (hidden branch): 3-day insolvency streak triggers acquisition by the leading rival (new `acquired` defeat; rival-majority/wipe stay terminal), defeat screen plays straight then reveals the memo + REPORT FOR WORK, recovery reuses all systems with an Influence objective (research/discoveries/contracts/crises/parent-ops feed it; 80 to spin out in 20 days), parent-company surveillance surcharge, strikes/purge, deadline/parent-majority dissolves, scarred restore (market 15, funds capped, -1 subsidiary/facility, 1 defection, single prize facility per acquirer), rival-specific entry risk/sabotage bonuses, DEFECTED state, local JSONL telemetry, 3 hidden badges. Probe-tuned economy (research path restores ~day 21, saboteur ~day 19 with prize). Suite: RECOVERY_OK (trigger gating, transition, influence, sabotage tracking, spinout costs, failures, determinism, save/load, telemetry, continuation). All 23 suites green.
- Playtest response + 0.12 onboarding/release: closed the day-one buyout sweep (10% standing + 7-day board cooldown, tested), fixed the `narrative_label` scene error, audio diagnostics (driver readout + self-test tone + unmute guard), first asset-free visual pass (animated market bars, shader portraits, ambient lab bg), onboarding (dynamic goals, 5-step tutorial checklist, field manual codex + Manual button), per-day rival clock fix (batching no longer speeds rivals; Expert winnable via batch, verified), 4 more badges (Speed Demon/Survivor/Tycoon/Spymaster), JSON cache, version const + menu display, release checklist, ENDGAME as-built amendments. Suites: TUT_OK. All 24 suites green, zero errors.
- 0.13 infirmary + memorial: treat injuries ($1500 to ACTIVE/50hp), ordered rest ($500, -20 stress roster-wide), memorial wall of story-logged deaths, lab nav button. Suite: MED_OK. All 25 suites green.
- Quality + domination + growth: removed dead signals/helpers, daily-overwrite guard, overtime domination probing (greedy buyouts land in recovery instead — coherent), scientist experience (+1/run, Lv6 cap, +2%/level), 3 save slots with migration. Suites: ABILITY_OK. All 27 suites green, zero errors.
- Ability audit fixes: every trait key now mechanical (stress resistance/drive on fatigue, insight/skepticism on evidence thresholds, malfunction guard on incidents, consistency on noise, risk tolerance on crit chance), new techs hooked (resonance ×1.15 acoustic/vibration, cryo halves cooling, deep probe ×1.1), generalized tech gating. Suite: ABILITY_OK. All 27 suites green, zero errors.
- 0.15 domination reality + experience + slots: overtime probe (auto-continue after market wins) shows 1–3/4 crushed — monopoly stays aspirational for deliberate play; expose-to-zero now forces exits; experience gives +2% quality/level (Lv capped 6, shown on detail screen); 3 save slots with menu cycler + legacy single-file migration. All suites green.
- 0.26 economy + crisis triangle + voices: 3 contracts (25-deck, J013-15 flavored); crisis study-resolve (+6 knowledge for +10 stress lab-wide, third button in incidents UI, C9 tests); intros/beats for Lund/Osei/Petrova with roster-filtered intro logging + hire-time intros (fixed file-iterated logging that announced unhired staff, R7 coverage); PRICING_BRIEF refreshed to 0.25 reality. Probe pillars hold (Hard systems 4/4, skilled splits, Expert batch d26). Suites 28/28.
- 0.25 content + endings + design hygiene: J016 Tallow Saint / J017 Spare Key / J018 Last Snow (18 artifacts, 34 discoveries, 18 arcs, portraits, act-3 holds all) with deliberately zero new incidents; epilogues vary by margin/depth/devourer (Polymath, Runaway/Photo, 4 absorbed voices, N9 tests); rival taunts doubled to 4 each with day-parity alternates (flavor draws no sim RNG — caught a stream perturbation mid-round); ENDGAME.md as-built amendments to date. Probe: Easy/Normal sweep, Hard pure LOSE / systems 4/4 / batch WIN, Expert batch WIN d25. Suites 28/28.
- 0.24 scenarios + endgame rivals + parent voices: SCN_DEBT (opens with a $5k loan) and SCN_STRIKE (loyalty 25, walkout looms) via new start_debt/loyalty_set scenario keys (10 scenarios, H8 tests); act-3 rival endgame moves, once each — aggressive surges + sabotages, steady compounds, publishers bless/curse, wildcards double down (A5 one-shot tests); per-acquirer recovery memos + standing parent orders in memo and goal (Q3 asserts, projection carries the fields). Facilities audit: 24-def list + map grid verified on screenshots. Probe bands best on record (Hard systems 4/4, skilled 2/2, Expert batch d26). Suites 28/28.
- 0.23 content + crises + tier-3 + honest probes: J013 Understudy / J014 Pale Engine / J015 Unbuilt-Rooms Museum (15 artifacts, 28 discoveries, 15 arcs, act-3 holds the late six), 3 incidents (29 total), steam_achievements.json mirror (17/17, hidden flags, N8 drift test); crises walkout/blackout/audit (names, expiry teeth, walkout despair spawner, team-resolve concessions, resolve priced below eating); facility tier-3 (6 builds, 6-12k, requires chains, D1c stacking); probes play sanely (DD-first buying, crisis pay-resolve, loan bridges) — bands: Easy/Normal all WIN, Hard pure LOSE / systems 3-4 + skilled 2/2, Expert batch WIN d23, others LOSE. Suites 28/28 (ACTION C8, DEPTH D1c, END N8).
- 0.22 content + tour + loans + lab scroll: J010 Glass Orchard / J011 Drowned Bell / J012 Paper Sun (12 artifacts, 22 discoveries, 12 arcs, act-3 holds the late three), 6 artifact incidents (26 total), 2 contracts (22-deck) + 2 world events; guided tour over the checklist (first-timer gate via legacy, sequential cards, $500 completion grant, Skip, saved); loan tiers $2k/$5k/$10k at 2%/day due in 30d, 3-open cap, $150/day overdue collectors, budget Debts section; lab wrapped in ScrollContainer with guide moved to top. Suites 28/28 (LOAN_OK, TUT U5), probe bands hold.
- 0.21 loyalty + rival personality: loyalty moves on death/incidents/rest/wins with resignation at zero (frees hiring, logged, unassignable); aggressive/wildcard rivals pounce on expiring offers first; publishers pay +1 prestige per confirmation; steady rivals shrug sabotage (0.75x). All suites green.
- 0.18 replay depth: weekly challenges (seed/mutator/menu/legacy mirror of dailies), 3 scenarios (Grant/Ironman/Storm with funds/roster/forced-event setups), cross-artifact day plans (queue carries artifact, locked legs skip), hostile buyout bids on subsidiaries (leader-gated, accept/decline UI). Probe bands hold. All suites green.
- 0.19 threats + variety: crisis kinds (breach -$3000/casualty, contamination staff-wide injuries, rupture -$5000), fourth enemy op (poach low-loyalty staff into DEFECTED + Turncoat badge, resisted attempts teach cover), +4 incidents, +4 contracts, +3 events. Probe bands hold. All suites green.
- 0.20 content wave: J007 Salt Choir, J008 Ledger Stone, J009 Hollow Lantern (2 discoveries each on existing tech keys, full 4-beat arcs, shader portraits), act 2 unlocks all 9, +2 contracts, +2 events, +2 incidents, Salt Air scenario. Probe bands hold. All suites green.
- 0.14 visual lab + gore + art brief: clickable facility floorplan (rooms light up, prizes CLASSIFIED, click-to-buy), pulsing red alert vignette on crises/heat/death, HP bars on roster + infirmary, incident button crisis alarm, `ART_BRIEF.md` (style-locked prompts: key art, logo, 6 artifacts, 9 staff, 6 directors, places, icons, palette). Suite: MAP_OK. All 26 suites green.
- Playtest fixes (human report): closed the day-one buyout sweep (credibility floor 10% market + 7-day board cooldown, tested), fixed the long-standing `narrative_label` scene error, added audio diagnostics (driver readout + self-test tone + unmute guard — please report the Settings readout if still silent), first visual pass with zero assets (animated market bar chart, per-artifact shader portraits, ambient lab background).

## [Unreleased / 0.2.0] - current
### Added
- Screens: Laboratory hub, Budget, Technology, Incident Reports + navigation (all return to laboratory)
- Experiment selection reachable from lab "Experiments" button
- 4 branch tech tree (Experimental Field Sensor, Thermal Containment, Gravity Sensor, Field Stabilizer)
- 4 secondary discoveries (Grav Attenuation, Energy Absorption, Grav Amplification, Grav Nullification), player-namable
- 4 new experiments (Acoustic, Laser, Vibration, Radioactive) with per-experiment unlock thresholds + tech gates
- Dangerous experiments (Radioactive) with incident risk
- Field Stabilizer technical: -50% incident severity + halves budget/days effects
- Dark science-lab theme (ThemeManager autoload): palette, root background, themed buttons/panels/inputs
- Accent-carded section panels on laboratory + experiment result screens (reusable accent_card / section_header variations)
- ObservationSimulator refactor: data-driven observation generation with `discovery_hint` tags
- Simulation-driven secondary discovery confirmation (evidence-tallied, not hardcoded counts)
- Consolidated automated test suite (scene_test_runner: ALL_SCENES_OK + LOGIC_OK + SIM_OK), theme_check, balance_sim
- Coverage tests: dangerous-experiment incident path (unmitigated + Field Stabilizer mitigated), evidence-driven suspected->confirmed discovery, save/load round-trip preserving `mitigated` flag (COVERAGE_OK)
- Windowed screenshot harness (tests/screenshot_harness) for programmatic per-screen visual verification
- Accent-carded main menu (PanelContainer with `accent_card` variation)

### Changed
- Knowledge gain formula: guaranteed base gain (no longer floored by low quality) + modest quality bonus
- Rebalanced experiment base gains + economy (verified 14-22 experiments to confirm, no bankruptcy)
- Scientist reference fixed: `selected_scientist_index`
- Narrative generation `%`-formatting crash fixed (String.format named placeholders)
- Laboratory hub cards + main menu wrapped to fill/center vertically (size_flags_vertical)

### Fixed
- `GameState.selected_scientist` -> `selected_scientist_index` bug in experiment_selection.gd
- New-campaign state leak: `initialize_new_campaign` now clears `unlocked_technologies`, `incidents`, `active_incidents` (previously carried over from a prior run)

## [0.0.1] - YYYY-MM-DD
### Added
- Phase 0: Project Foundation
  - Godot project structure
  - Main Menu
  - New Campaign
  - Campaign Creation (organization name, abbreviation, facility name, director name, emblem, color/theme, research doctrine)
  - Campaign Seed generation
  - Player Organization model
  - SaveManager with JSON persistence
  - Basic EventBus
  - Laboratory placeholder scene
  - Data loader
  - J-001 Lattice Sphere data definition
  - Three scientist definitions (Dr. Sarah Chen, Dr. Marcus Reed, Dr. Elena Vasquez)
  - HELIOS Research Authority definition
  - Basic campaign save/load round trip
  - Organization information preserved in save

### Fixed
- (none yet)

## [0.0.2] - ?
### Added
- Experimentation infrastructure
- Passive Observation, Heating, Electrical Exposure experiments
- Experiment selection UI
- Scientist assignment
- Experiment execution and results
- Knowledge progression system
- Discovery states (Unknown → Suspected → Confirmed)
- Player naming of discoveries
- First technology unlock (Experimental Field Sensor)
- HELIOS rival progress and intelligence notifications
- Procedural narrative reports

### Changed
- (none yet)

### Deprecated
- (none yet)

## [0.1.0] - ?
### Added
- Three artifacts
- Multiple discoveries
- Limited facility layout
- Research budget
- Scientist experience system
- Scientist injuries
- Basic incidents
- More HELIOS behavior
- Artifact interactions

## Unreleased - Future
- Vertical slice production
- Demo build for Steam
- Mod support architecture
- Commercial release