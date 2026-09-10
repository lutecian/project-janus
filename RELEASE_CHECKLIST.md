# Release checklist (as of 0.34)

## Playtesting (deferred until pre-release by decision — still human)
- [ ] First-15-minutes onboarding read (tutorial + goals + codex clarity)
- [ ] Batch/day-plan UI usability (queue, run day, stress readability)
- [ ] Horror tone check (graphic text, memorial, dread audio balance)
- [ ] Audio listen on real hardware (drone mix, stinger levels, test-tone report)
- [ ] Expert + Domination achievability by a skilled human
- [ ] Recovery branch blind discovery ("wait — the game isn't over?")

## Production (still human)
- [ ] Key art: artifact portraits, scientist portraits, backgrounds, logo
- [ ] Composed music + sound design pass (procedural set is placeholder-grade)
- [ ] Trailer (30–60s) + Steam capsule art + screenshots
- [ ] Steam page + store copy (keep recovery branch unspoiled)
- [ ] Steam SDK wiring (mirror file ready: 20 achievements) + cloud saves

## Release engineering
- [x] Export builds (Windows x86_64, `export_presets.cfg` committed, tests excluded) + headless smoke test (boots to menu, 180 frames, exit 0)
- [ ] Crash reporting hookup
- [x] Version tags per milestone (`v0.34.0` current in `GameState.GAME_VERSION`)
- [ ] Pricing decision (see PRICING_BRIEF.md; leaning $20 full)

## Already automated (do not redo by hand)
Balance/pacing (35+ probe sims, bit-deterministic), 28 headless suites, screenshot
verification, save/load round-trips, schedule-identity determinism checks,
tutorial/state assertions.
