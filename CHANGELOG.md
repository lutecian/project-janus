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