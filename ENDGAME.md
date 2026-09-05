# ENDGAME & SYSTEMS DESIGN — PROJECT JANUS 0.3

Status: **Design locked (agreed with author, 2026-08-31)** — roadmap for post-0.2 work.
Implementation is pending; built **data-driven and phased** so every increment stays playable and testable.

---

## 1. Design goal

Turn JANUS from a functional prototype (which presently has **no ending**) into a game with
multiple, graded, winnable/loseable outcomes — and give the player meaningful ways to affect
them. The core research fantasy stays primary; all new systems are **additive** and let the game
be won purely via research if the player chooses.

---

## 2. Rival ecology (N competitors, not just HELIOS)

Replace the single HELIOS blob with a **field of rivals**, each with a footprint and behavior:

| Actor | Archetype | Behavior |
|---|---|---|
| **HELIOS** | Corporate leader | Aggressive; buys everything; spawns with high share |
| **Regional indie labs** (e.g. *Bermant Labs*, *Northwind*) | Small research labs | Slow, focused; punch up on a research streak |
| **Wildcards** | Startups / state-backed | Unpredictable — can boom, implode, or go on sprees |

- Each rival ticks its **own research** and **market share** daily (generalize `_advance_helios` to N actors).
- Each has a **disposition** (hoards cash / acquisition sprees / publishes openly).
- Rivals can **acquire each other and you** — a live market where companies merge and vanish, feeding the Domination path.

---

## 3. Market model + win/lose conditions

- Track `player_market` and each rival's `market` share (0–100, with an implicit "rest of market" remainder).
- **Victory**: player reaches a **majority threshold** (default 51%, scaled by difficulty) before anyone else.
- **Defeat**: HELIOS (or any rival) reaches the majority threshold first.
- HELIOS daily advance is currently ~11%/campaign — far too slow to threaten. **Balance task**: retune so a lean-on-HELIOS player actually loses (sets the tension clock).
- Market share is **primary** from confirmed discoveries/breakthroughs + a small trickle from experiment quality, with acquisitions as an **accelerator capped** so you cannot buy your way to majority — you must do the science.

---

## 4. Multiple victory PATHS + graded endings (not a single 51% check)

Three win-families, each completable in isolation; the game ends at the **highest tier achieved** (optionally "keep playing" to push higher):

| Win line | How you win | Title |
|---|---|---|
| **Market** | Majority (51%+, scaled by difficulty) ahead of any rival | *Market Leader* |
| **Scientific** | Confirm a full discovery set / reach a tech depth / publish the primary breakthrough | *Distinguished Researcher* |
| **Domination** | Crush ALL rivals (each < your share OR acquired OR bankrupted/forced to exit) | *The Monopoly* |

### Domination = the strictest tier
Not "highest share." To earn The Monopoly you must, for **every** rival, reach one of:
- Acquired by you, **or**
- Bankrupted, **or**
- Driven below a tiny share and declared **exited**.

This is where acquisitions + espionage (and money) matter as a *strategy*, not a passive share check.

### Ending tier ranking (rough)
`Absorbed (lost) < Researcher (low sci) < Market Leader < Distinguished Researcher < Monopoly`
Difficulty **upgrades** the same name (Easy-Monopoly ranks below Hard-Monopoly).

---

## 5. Acquisitions (labs/companies) + shrewdness

- **Catalog** (`acquired_companies.json`): name, asking price, listed tech, listed health/valuation, plus a **hidden true quality**.
- Each owned company runs **its own research** over time (variable success) — player-owned mirror of `_advance_helios`.
- **Acquiring technologies**: companies carry a **tech portfolio** (reuse existing tech-tree keys). Acquisition unlocks their techs via `_unlock_technology_for_discovery`; their ongoing research can also surface *new* techs.
- **Shrewdness / investment quality = information asymmetry:**
  - Listed price is noisy: `true_value * (0.6..1.6)` (seeded at campaign start).
  - **Due diligence** (costs funds/time) reveals an error-bounded estimate of true value.
  - Outcomes once integrated: **steal** (below true value, performs above reported), **fair**, **lemon/overpay** (above true value, hidden problems → research stalls, drags market contribution).
  - Shrewdness = how much you invest in **info (DD), timing, discipline** — not luck.

- **Rolling offers with deadlines**; un-acted offers expire or are **grabbed by other rivals**. Money-hoarding to "buy three at once at 51%" is punished.

---

## 6. Espionage (active intel layer)

The **direct-action counterpart** to the passive intel you already have. Exchanges **funds + time + risk** for **info and sabotage**.

### Op catalog (small, pooled — `espionage_ops.json`)
| Op | Effect | Cost / risk profile |
|---|---|---|
| **Steal tech / infiltrate** | Skip a rival tech unlock or gain a discovery blueprint (reuse tech unlock path) | Expensive, moderate risk |
| **Surveillance** | Reveal true valuation + research pipeline of a target → sharpens acquisition due-diligence | Cheap, low risk |
| **Sabotage** | Slow a rival's research/market gain for N days | Costly, risky |
| **Counter-intel** | Block/hear about ops aimed at you | Maintained cost |
| **Expose / leak** | Ruin a rival's reputation (high effect toward Domination; costs YOU ethics/standing) | High cost, ethics hit |

### Shared restraint: Risk + Cover (not just money)
- **Risk meter** (per campaign): ops add risk; crossing a threshold risks **caught** → a serious incident (rival gains an edge, ethics scandal, funding cuts, possibly a world event). Risk decays via "lie low" or counter-intel.
- **Cover** (counter-intel/infrastructure): reduces enemy-op landing chance AND improves your own success.
- Result: espionage is **risk-allocation**, not "click steal repeatedly" — skill through risk management.

### Integration
- **→ Acquisitions/DD:** Surveillance directly reveals hidden values (espionage as smart-buy shortcut).
- **→ Market/Domination:** Sabotage throttles rivals; Expose + acquisition make rivals acquirable/bankrupt-able.
- **→ Tech tree:** Steal tech pulls a rival tech into your tree.
- **→ Incidents/world events:** getting caught is a first-class incident, can trigger world-event blowback.
- **→ Difficulty:** cheaper/less risky on Easy, nerfed on Hard.

---

## 7. Requested-research contracts + world events

External pressure and reason — the "why" layer that makes the player **respond to the world**.

### Contracts (governments + outside companies asking you to research specific tech)
- **Core tension**: accepting a contract **commits workdays** (the shared `elapsed_days` action budget) toward it → the real cost is **time away from your own artifact research** (the HELIOS/endgame clock).
- **Payoff**: upfront income **+** the contract's own research progress.
- **"Advance a path you're NOT on"**: contracts are tagged with a discovery/tech key — most advance a **side path you may be ignoring**, giving marginal research in a lane you're not working. Deliberate choice: broaden (income + divergent progress) vs. stay focused.
- Mirrors your "alien trade routes / wars / essential events" flavor.

### World events (conditional shape-changers, not random noise)
- **War/conflict** → military-adjacent research contracts (big income, dangerous-experiment flavored), higher incident risk, some labs convert to war work.
- **Alien trade routes open** → new artifact/intel sources, exploration/translation-tech contracts, market bonus for early adapters.
- **Economic shock / budget crisis** → reduced funding intervals, cheaper acquisitions (bargains), some rivals become acquirable/bankrupt-able.
- **Regulatory/ethics scandal** → social/incident events; publish-openly vs. hide affects title flavor.
- Rule: events **change available contracts + rival/market params**, never hard-lock progress.

### Scope guardrails
- **Data-driven**: `contracts.json` + `world_events.json`, reusing discovery/tech/budget/incident paths. No new sim.
- **One contract slot at a time** (single active occupation; then next arrives).
- **6–10 high-signal world events**, not dozens.
- **Optional in definition** — game must be winnable without engaging it. If enabled, intensity scales with difficulty.

---

## 8. Difficulty selection

Difficulty tunes **winning potential** directly:
- **Absolute win thresholds** (Market majority needs 55% on Hard vs 45% on Easy).
- **Rival aggression** (advance rate, bid ferocity in acquisitions).
- **Rival starting leverage** (HELIOS starting share: 20% Hard vs 10% Easy).
- **Your starting budget** + harshness of overhead/incidents.
- **Win-lines available** (Scientific win can be hard-locked on an Expert run so you can't research-escape).
- **Espionage/contracts** cost & risk scaling.
- **Ending tier is partly gated by difficulty** — Hard-mode Domination ranks above Easy-mode Monopoly.

---

## 9. Badges & titles (rank / replay layer)

- **Badges** = discrete achievements (e.g., *First Doubt*, *Bargain Hunter*, *Due-Diligence Pro*, *War Contractor*, *Diplomat of the Trade Routes*, *Overnight Monopoly*). Earned once; **persisted across runs** in a meta file separate from campaign saves.
- **Titles** = end-of-run rank derived from: **win line × difficulty × efficiency** (days taken, money remaining, rivals crushed, tech depth, badges earned).
- **Run score → legacy/career profile** on the main menu (best titles by difficulty) — replay hook.

---

## 10. Multiple ending variants (epilogues)

Determined by combo of: **who won** (you/HELIOS), **how far along the tech tree**, **market share at end**, and **key experiment/discovery decisions** (e.g., dangerous radioactive route vs. safe route). Flavor examples: *Philanthropist Legacy*, *Corporatist Monopoly*, *Scientific Martyr* (lost but published openly), *Shadow Conglomerate* (won via dubious acquisitions/spy).

---

## 11. How the systems bind together

- **Rival ecology** → makes Market + Domination meaningful (real competitors to overtake/crush).
- **Market/multi-path/tiered endings** → *what* you're racing for.
- **Acquisitions + shrewdness** → the *financial strategy*.
- **Espionage** → the *active, information-based* lever (sharpens DD, sabotages rivals).
- **Contracts + world events** → the *external pressure/flavor* that reshapes all of the above.
- **Difficulty + badges/titles** → the *stakes and replay rank*.

All **additive**: the game is winnable via pure research with any system untouched.

---

## 12. Implementation plan (phased, data-driven, each increment playable + tested)

### Phase 1 — make the game finite (prerequisite for everything) — SHIPPED
- Generalized **rival field** (N competitors incl. HELIOS) replacing the single-Helios advance.
- **Market-share model** (`player_market` + rival markets) with daily ticks.
- **Definite victory (majority 46 Normal / 38 Easy / 52 Hard) + defeat** condition; **end screens** wired to campaign resolution.
- **Difficulty settings** (thresholds, rival aggression, starting leverage/budget).
- Retune HELIOS/field advance so a lean-on-rivals player can actually lose.
- Verified: `MARKET_OK` (spawn/tick/victory/defeat/save-load) + `PACING_OK` (Normal: active research wins ~day 32, idle loses ~day 33). Winnable via pure research.

### Phase 2 — the strategy layer — SHIPPED
- **Acquisitions** (catalog, tech portfolios, owned-company research tick).
- **Acquisition shrewdness** (noisy pricing, due diligence, steal/fair/lemon outcomes).
- **Domination ending** (acquire/bankrupt/exit every rival).
- Verified: `ACQ_OK` (pricing band, DD bounds, steal/fair/lemon, owned tick + tech, expiry/grab, monopoly resolution, save/load). Crush bar = acquired/bankrupt/exited OR share at most half the player's (strictly harder than plain majority, so Market Leader stays distinct from The Monopoly).

### Phase 3 — the meaning layer — SHIPPED
- **Requested-research contracts** (`contracts.json`).
- **World-event layer** (`world_events.json`) + event-driven contract pools.
- **Espionage** (5-op catalog, Risk/Cover meters, caught → incident/world-event).
- **Multi-path tiered endings** (Market/Scientific/Domination) + **badges/titles** + legacy profile.
- Verified: `CTR_OK` (deck/offer/accept/workdays/complete/decline/gating/save-load) + `EVT_OK` (schedule/trigger/effects/expiry/save-load) + `ESP_OK` (costs/heat, steal/sabotage/expose/survey effects, caught setback, save-load) + `END_OK` (scientific win, monopoly > researcher > market order, badges, legacy file). Pacing re-verified deterministic (fixed seeds) after event tuning (war 1.2, boom 1.05, breakthrough 1.15).

---

## 12b. As-built amendments (measured deviations from the locked design)
- Domination crush bar is 0.4× player share, not merely "highest share" — keeps Market Leader distinct.
- Buyout market transfer capped (+4 per buyout); buyouts need 10% standing + 7-day board cooldown (closed a day-one sweep).
- Scientific win = full confirmation + all-tech depth OR 3-artifact collection (single-artifact confirms flip together, so depth/collection gate it).
- Majority targets: 44 / 52 / 58 / 62 (Easy/Normal/Hard/Expert), retuned by probe, not 51 flat.
- Rivals tick per day, not per experiment (batching would otherwise speed them up too).
- Recovery branch (0.11): insolvency → acquisition → hidden influence game; not in the original plan.
- Expert locks science; acts gate artifacts and scale aggression; contracts/companies/events deal from seeded decks.

## 13. Testing strategy

Extend the existing suite (scene_test_runner: ALL_SCENES_OK / LOGIC_OK / SIM_OK / COVERAGE_OK):
- Market math (share sources, thresholds, majority/defeat triggers) — deterministic.
- Rival-field advance determinism (N rivals, seeded).
- Acquisition pricing / DD / steal-fair-lemon classification.
- Espionage risk/cover/op-success seeded determinism + caught transition.
- Endgame resolution → each ending tier + save/load of all new campaign state.
- Contracts/world-events data integrity.

Run via:
`& "C:\Users\lutec\Downloads\Godot472\Godot_v4.7.2-stable_win64_console.exe" --headless --nomt --path "D:\Projects\project-janus" res://tests/scene_test_runner.tscn`
