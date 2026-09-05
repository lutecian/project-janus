# Release checklist (human-required items automation cannot do)

## Playtesting (deferred until pre-release by decision)
- [ ] First-15-minutes onboarding read (tutorial + goals + codex clarity)
- [ ] Batch/day-plan UI usability (queue, run day, stress readability)
- [ ] Horror tone check (graphic text, memorial, dread audio balance)
- [ ] Audio listen on real hardware (drone mix, stinger levels, test-tone report)
- [ ] Expert + Domination achievability by a skilled human
- [ ] Recovery branch blind discovery ("wait — the game isn't over?")

## Production
- [ ] Key art: artifact portraits, scientist portraits, backgrounds, logo
- [ ] Composed music + sound design pass (procedural set is placeholder-grade)
- [ ] Trailer (30–60s) + Steam capsule art + screenshots
- [ ] Steam page + store copy (keep recovery branch unspoiled)
- [ ] Steam achievements mirror (13 in-game badges), cloud saves

## Release engineering
- [ ] Export builds (Windows first) + smoke test outside the editor
- [ ] Crash reporting hookup
- [ ] Version tags per milestone (`v0.12.0` current in `GameState.GAME_VERSION`)
- [ ] Pricing decision (see PRICING_BRIEF.md; lean $10–12 EA vs $20 full)

## Already automated (do not redo by hand)
Balance/pacing (9–13 probe sims), 20+ headless suites, screenshot verification,
save/load round-trips, determinism checks, tutorial/state assertions.
