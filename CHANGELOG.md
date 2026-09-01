# CHANGELOG

## [Unreleased / 0.3.0] - planned
- Full endgame + systems roadmap committed to `ENDGAME.md` (design locked): rival ecology, market model + win/lose, multi-path graded endings + Domination, acquisitions + shrewdness, espionage, contracts + world events, difficulty, badges/titles. Phased, data-driven, additive.

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