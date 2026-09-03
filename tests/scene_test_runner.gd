extends Node

const ObservationSimulator = preload("res://scripts/simulation/observation_simulator.gd")

var _results: Array = []

func _ready():
	GameState.initialize_new_campaign({"name": "Test Org"})
	_scenes_to_test = [
		"res://scenes/main/main_menu.tscn",
		"res://scenes/campaign/campaign_creation.tscn",
		"res://scenes/laboratory/laboratory.tscn",
		"res://scenes/experiment/experiment_selection.tscn",
		"res://scenes/budget/budget.tscn",
		"res://scenes/technology/technology.tscn",
		"res://scenes/incidents/incident_reports.tscn",
		"res://scenes/experiment/artifact_detail.tscn",
		"res://scenes/experiment/scientist_detail.tscn",
		"res://scenes/experiment/helios_intel.tscn",
		"res://scenes/experiment/results/experiment_result.tscn",
		"res://scenes/experiment/results/breakthrough.tscn",
		"res://scenes/settings/settings.tscn",
		"res://scenes/endgame/game_over.tscn",
		"res://scenes/acquisitions/acquisitions.tscn"
	]
	_test_next()

func _test_logic():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Logic Test"})
	GameState.select_artifact(0)

	# --- Budget flow ---
	var start_budget: int = GameState.budget["funds"]
	if start_budget != 10000:
		push_error("starting budget should be 10000, got %d" % start_budget)
		failures += 1

	# --- Discovery / tech flow ---
	if GameState.discoveries.size() < 2:
		push_error("J001 should have 2 discoveries, got %d" % GameState.discoveries.size())
		failures += 1
	var sci: Dictionary = GameState.scientists[0]

	# Cost for radioactive should use the explicit budget entry
	if GameState._get_experiment_cost("EXP_RADIOACTIVE") != 1200:
		push_error("EXP_RADIOACTIVE cost should be 1200")
		failures += 1

	# Run expensive experiments and verify budget is deducted
	var funds_before: int = GameState.budget["funds"]
	var heating_idx: int = -1
	var all_defs: Array = GameState.load_experiment_definitions()
	for e in all_defs:
		if (e as Dictionary).get("id", "") == "EXP_HEATING":
			heating_idx = all_defs.find(e)
			break
	var heating_cost: int = GameState._get_experiment_cost("EXP_HEATING")
	GameState.incident_cooldown = 100
	for i in range(4):
		GameState.run_experiment(all_defs[heating_idx], sci)
	var expected_after: int = funds_before - heating_cost * 4 - 150 * 4
	if GameState.budget["funds"] != expected_after:
		push_error("budget should be $%d after 4 heating runs + overhead, got $%d" % [expected_after, GameState.budget["funds"]])
		failures += 1

	# Energy absorption should reach confirmed
	var ea_confirmed: bool = false
	for d in GameState.discoveries:
		if (d as Dictionary).get("discovery_id", "") == "DISC_ENERGY_ABSORPTION":
			ea_confirmed = (d as Dictionary).get("state", "") == "confirmed"
	if not ea_confirmed:
		push_error("DISC_ENERGY_ABSORPTION should be confirmed after 4 heating runs")
		failures += 1
	if not GameState.unlocked_technologies.has("TECH_THERMAL_CONTAINMENT"):
		push_error("TECH_THERMAL_CONTAINMENT should be unlocked")
		failures += 1

	# Radioactive experiment requires thermal containment + 50 knowledge.
	# Our runs kept progress below 30, so raise it past the unlock threshold.
	GameState.knowledge["progress"] = 70
	var unlocked_ids: Array = []
	for exp in GameState.get_unlocked_experiments(GameState.load_experiment_definitions()):
		unlocked_ids.append((exp as Dictionary).get("id", ""))
	if not unlocked_ids.has("EXP_RADIOACTIVE"):
		push_error("EXP_RADIOACTIVE should be unlocked with thermal containment + knowledge 70")
		failures += 1
	# With progress at 70, knowledge state becomes confirmed and all recent discoveries
	# should confirm via _update_knowledge_state (simulated by running one more experiment).
	GameState.incident_cooldown = 100
	GameState.run_experiment(all_defs[heating_idx], sci)
	var primary_confirmed: bool = GameState.discovery["state"] == "confirmed"
	if not primary_confirmed:
		push_error("primary discovery should become confirmed at knowledge 70")
		failures += 1

	# --- HELIOS flow ---
	var helios_before: int = GameState.helios["progress"]
	GameState._advance_helios()
	if GameState.helios["progress"] < helios_before:
		push_error("helios progress should not decrease")
		failures += 1

	# --- Save/load round trip ---
	var save_data: Dictionary = GameState.get_save_data()
	GameState.load_save_data(save_data)
	if not GameState.unlocked_technologies.has("TECH_THERMAL_CONTAINMENT"):
		push_error("Thermal containment lost after save/load")
		failures += 1

	# --- Incident: field stabilizer mitigation ---
	# Construct and apply an incident directly, verify stabilizer downgrades severity
	GameState.unlocked_technologies.append("TECH_FIELD_STABILIZER")
	var test_incident := {
		"id": "INC_TEST",
		"name": "Test Incident",
		"description": "Test.",
		"severity": "moderate",
		"effects": {"budget_cost": 1000, "days_lost": 2}
	}
	var funds_before_incident: int = GameState.budget["funds"]
	GameState._apply_incident(test_incident)
	var last_incident: Dictionary = GameState.incidents[GameState.incidents.size() - 1]
	if last_incident.get("severity", "") != "minor":
		push_error("field stabilizer should downgrade moderate to minor, got '%s'" % last_incident.get("severity", ""))
		failures += 1
	if not last_incident.get("mitigated", false):
		push_error("incident should be flagged as mitigated")
		failures += 1
	# budget cost halves: 1000 -> 500
	if GameState.budget["funds"] != funds_before_incident - 500:
		push_error("field stabilizer should halve budget cost (charged 500)")
		failures += 1

	if failures == 0:
		print("LOGIC_OK")
	else:
		print("%d LOGIC FAILURES" % failures)

var _scenes_to_test: Array = []
var _idx: int = 0

func _test_next():
	if _idx >= _scenes_to_test.size():
		_print_summary()
		_test_logic()
		_test_simulation()
		_test_coverage()
		_test_market()
		_test_acq()
		_test_pacing()
		get_tree().quit()
		return
	var path: String = _scenes_to_test[_idx]
	if not ResourceLoader.exists(path):
		_results.append("MISSING: " + path)
		_idx += 1
		_test_next()
		return
	var packed: PackedScene = load(path)
	if packed == null:
		_results.append("LOAD_FAIL: " + path)
		_idx += 1
		_test_next()
		return
	var instance := packed.instantiate()
	add_child(instance)
	await get_tree().process_frame
	remove_child(instance)
	instance.free()
	_results.append("OK: " + path)
	_idx += 1
	_test_next()

func _print_summary():
	var failures: int = 0
	for r in _results:
		if r.begins_with("OK"):
			print(r)
		else:
			failures += 1
			push_error(r)
	if failures == 0:
		print("ALL_SCENES_OK")
	else:
		print("%d SCENE FAILURES" % failures)

func _test_simulation():
	var sim_failures: int = 0
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 12345
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 12345
	if ObservationSimulator.generate({"result_template": "em_resonance"}, 0.8, rng_a) != ObservationSimulator.generate({"result_template": "em_resonance"}, 0.8, rng_b):
		push_error("simulator determinism failed")
		sim_failures += 1
	var templates := ["passive_observation", "heating", "electrical_exposure", "xray", "em_low", "em_mid", "em_resonance", "cooling", "acoustic", "laser", "vibration", "radioactive", "unknown_template"]
	for t in templates:
		var res: Array = ObservationSimulator.generate({"result_template": t}, 0.7, RandomNumberGenerator.new())
		if res.size() != 1:
			push_error("template '%s' should produce one observation" % t)
			sim_failures += 1
	var high: Array = ObservationSimulator.generate({"result_template": "heating"}, 1.2, RandomNumberGenerator.new())
	if (high[0] as Dictionary)["confidence"] != "high":
		push_error("quality 1.2 should yield high confidence")
		sim_failures += 1
	if sim_failures == 0:
		print("SIM_OK")
	else:
		print("%d SIM FAILURES" % sim_failures)

func _test_coverage():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Coverage Test"})
	GameState.select_artifact(0)
	var sci: Dictionary = GameState.scientists[0]

	# --- G1: Dangerous experiment incident path (isolated, NO stabilizer) ---
	# NOTE: _test_logic appends TECH_FIELD_STABILIZER to the shared GameState, and
	# initialize_new_campaign does not clear unlocked_technologies, so force-remove it here.
	GameState.unlocked_technologies.erase("TECH_FIELD_STABILIZER")
	GameState.incident_cooldown = 100  # suppress normal incident roll so only the dangerous path fires
	var incidents_before: int = GameState.incidents.size()
	GameState._rng.seed = 13  # first randf() = 0.062 -> fires under base 0.12 (no stabilizer)
	GameState._check_dangerous_experiment("EXP_RADIOACTIVE")
	var fired := false
	if GameState.incidents.size() != incidents_before + 1:
		push_error("dangerous experiment should have fired INC_EQUIPMENT_FAILURE")
		failures += 1
	else:
		var inc: Dictionary = GameState.incidents[GameState.incidents.size() - 1]
		fired = inc.get("id", "") == "INC_EQUIPMENT_FAILURE" and not inc.get("mitigated", false)
		if not fired:
			push_error("dangerous incident wrong (id=%s mitigated=%s)" % [inc.get("id", ""), inc.get("mitigated", false)])
			failures += 1

	# --- G2: Dangerous experiment with Field Stabilizer yields mitigated record ---
	GameState.unlocked_technologies.append("TECH_FIELD_STABILIZER")
	var incidents_before2: int = GameState.incidents.size()
	GameState._rng.seed = 28  # first randf() < 0.04 -> fires even under base 0.04 (with stabilizer)
	GameState._check_dangerous_experiment("EXP_RADIOACTIVE")
	if GameState.incidents.size() != incidents_before2 + 1:
		push_error("dangerous experiment should have fired again with stabilizer")
		failures += 1
	else:
		var inc2: Dictionary = GameState.incidents[GameState.incidents.size() - 1]
		if not inc2.get("mitigated", false):
			push_error("stabilizer-mitigated incident should be flagged mitigated")
			failures += 1

	# --- G3: Evidence-driven secondary discovery (suspected -> confirmed) ---
	# Build a fresh campaign so discovery state is clean.
	GameState.initialize_new_campaign({"name": "Coverage Ev"})
	GameState.select_artifact(0)
	var ea_disc := {}
	for d in GameState.discoveries:
		var dd: Dictionary = d as Dictionary
		if dd.get("discovery_id", "") == "DISC_ENERGY_ABSORPTION":
			ea_disc = dd
	if ea_disc.is_empty():
		push_error("J001 should include DISC_ENERGY_ABSORPTION")
		failures += 1
	else:
		# 2 evidence observations -> suspected
		GameState.knowledge["observations"] = [
			{"content": "a", "type": "active", "confidence": "medium", "discovery_hint": "energy_absorption"},
			{"content": "b", "type": "active", "confidence": "low", "discovery_hint": "energy_absorption"}
		]
		GameState._check_secondary_discoveries("EXP_HEATING")
		if ea_disc.get("state", "") != "suspected":
			push_error("2 evidence observations should promote to suspected, got '%s'" % ea_disc.get("state", ""))
			failures += 1
		# Add 2 more evidence (total 4) -> confirmed
		GameState.knowledge["observations"].append({"content": "c", "type": "passive", "confidence": "high", "discovery_hint": "energy_absorption"})
		GameState.knowledge["observations"].append({"content": "d", "type": "active", "confidence": "medium", "discovery_hint": "energy_absorption"})
		GameState._check_secondary_discoveries("EXP_HEATING")
		if ea_disc.get("state", "") != "confirmed":
			push_error("4 evidence observations should confirm, got '%s'" % ea_disc.get("state", ""))
			failures += 1
		if not GameState.unlocked_technologies.has("TECH_THERMAL_CONTAINMENT"):
			push_error("confirming energy absorption should unlock thermal containment")
			failures += 1

	# --- G4: Save/load preserves the mitigated flag ---
	# Build an incident record through the real pathway and round-trip it.
	GameState.initialize_new_campaign({"name": "Coverage SaveLoad"})
	GameState.select_artifact(0)
	GameState.unlocked_technologies.append("TECH_FIELD_STABILIZER")
	var test_inc := {
		"id": "INC_TEST", "name": "Test", "description": "d",
		"severity": "moderate", "effects": {"budget_cost": 1000, "days_lost": 2}
	}
	GameState._apply_incident(test_inc)
	if not GameState.incidents[0].get("mitigated", false):
		push_error("pre-save incident should be mitigated")
		failures += 1
	var save := GameState.get_save_data()
	GameState.load_save_data(save)
	if not GameState.incidents[0].get("mitigated", false):
		push_error("mitigated flag lost after save/load")
		failures += 1

	if failures == 0:
		print("COVERAGE_OK")
	else:
		print("%d COVERAGE FAILURES" % failures)

func _test_market():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Market Test"}, "normal")
	GameState.select_artifact(0)

	# --- M1: Rival field spawns deterministically ---
	var rival_ids: Array = []
	for r in GameState.rivals:
		rival_ids.append((r as Dictionary).get("id", ""))
	if not rival_ids.has("RIV_HELIOS"):
		push_error("market: HELIOS rival missing from field")
		failures += 1
	if rival_ids.size() != 4:
		push_error("market: expected 4 rivals, got %d" % rival_ids.size())
		failures += 1
	if absf(GameState.get_rival_market("RIV_HELIOS") - 12.0) > 0.001:
		push_error("market: HELIOS normal start share should be 12, got %f" % GameState.get_rival_market("RIV_HELIOS"))
		failures += 1
	if absf(GameState.get_majority_target() - 46.0) > 0.001:
		push_error("market: normal majority target should be 46, got %f" % GameState.get_majority_target())
		failures += 1

	# --- M2: Player experiment tick adds a small share and rivals advance ---
	var pm_before: float = GameState.get_player_market()
	var helios_before: float = GameState.get_rival_market("RIV_HELIOS")
	GameState._rng.seed = 99
	GameState._tick_market()
	var expected_tick: float = float(GameState.difficulty.get("player_experiment_gain", 0.55))
	if absf(GameState.get_player_market() - (pm_before + expected_tick)) > 0.001:
		push_error("market: player tick wrong (%f -> %f, expected +%f)" % [pm_before, GameState.get_player_market(), expected_tick])
		failures += 1
	if GameState.get_rival_market("RIV_HELIOS") <= helios_before:
		push_error("market: rival should advance each tick")
		failures += 1

	# --- M3: Player reaches majority -> victory ---
	GameState.player_market = GameState.get_majority_target() - 0.5
	GameState._rng.seed = 5
	GameState._tick_market()
	GameState._check_market_end()
	if not GameState.is_game_over():
		push_error("market: player majority should end the game")
		failures += 1
	elif not GameState.game_over.get("won", false):
		push_error("market: player majority should be a win, got %s" % GameState.game_over.get("reason", "?"))
		failures += 1

	# --- M4: A rival reaches majority -> defeat ---
	GameState.initialize_new_campaign({"name": "Market Test 2"}, "normal")
	for r in GameState.rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("id", "") == "RIV_HELIOS":
			rd["share"] = GameState.get_majority_target() + 0.5
	GameState.player_market = 5.0
	GameState._check_market_end()
	if not GameState.is_game_over():
		push_error("market: rival majority should end the game")
		failures += 1
	elif GameState.game_over.get("won", true):
		push_error("market: rival majority should be a loss")
		failures += 1

	# --- M5: Save/load preserves difficulty, market, rivals, game_over ---
	GameState.initialize_new_campaign({"name": "Market Test 3"}, "hard")
	GameState.player_market = 30.5
	var save := GameState.get_save_data()
	GameState.load_save_data(save)
	if GameState.difficulty.get("id", "") != "hard":
		push_error("market: difficulty not preserved after save/load")
		failures += 1
	if absf(GameState.get_player_market() - 30.5) > 0.001:
		push_error("market: player_market not preserved after save/load (%f)" % GameState.get_player_market())
		failures += 1
	if GameState.rivals.size() != 4:
		push_error("market: rivals not preserved after save/load")
		failures += 1
	if absf(GameState.get_majority_target() - 52.0) > 0.001:
		push_error("market: hard majority target not 52 after load, got %f" % GameState.get_majority_target())
		failures += 1

	if failures == 0:
		print("MARKET_OK")
	else:
		print("%d MARKET FAILURES" % failures)

func _test_acq():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Acq Test"}, "normal")
	GameState.select_artifact(0)

	# --- A1: Offers spawn with noisy pricing inside the 0.6..1.6 band ---
	if GameState.company_offers.size() != 4:
		push_error("acq: expected 4 company offers, got %d" % GameState.company_offers.size())
		failures += 1
	for o in GameState.company_offers:
		var od: Dictionary = o as Dictionary
		var true_value: float = float(od.get("true_value", 0.0))
		var ratio: float = float(od.get("listed_price", 0)) / maxf(true_value, 1.0)
		if ratio < 0.59 or ratio > 1.61:
			push_error("acq: %s listed/true ratio %.2f outside noise band" % [od.get("id", "?"), ratio])
			failures += 1

	# --- A2: Due diligence reveals an error-bounded estimate ---
	GameState.budget["funds"] = 20000
	var first_id: String = (GameState.company_offers[0] as Dictionary).get("id", "")
	var dd1: Dictionary = GameState.perform_due_diligence(first_id)
	if not dd1.get("ok", false):
		push_error("acq: level-1 diligence should succeed")
		failures += 1
	else:
		var t1: float = float((GameState.company_offers[0] as Dictionary).get("true_value", 0.0))
		if absf(float(dd1.get("estimate", 0.0)) - t1) > 0.26 * t1:
			push_error("acq: level-1 estimate outside ±25% bound")
			failures += 1
	var dd2: Dictionary = GameState.perform_due_diligence(first_id)
	if not dd2.get("ok", false):
		push_error("acq: level-2 diligence should succeed")
		failures += 1
	else:
		var t2: float = float((GameState.company_offers[0] as Dictionary).get("true_value", 0.0))
		if absf(float(dd2.get("estimate", 0.0)) - t2) > 0.11 * t2:
			push_error("acq: level-2 estimate outside ±10% bound")
			failures += 1

	# --- A3: Steal / fair / lemon classification ---
	GameState.initialize_new_campaign({"name": "Acq Classify"}, "normal")
	GameState.select_artifact(0)
	GameState.budget["funds"] = 50000
	var steal_offer: Dictionary = GameState.company_offers[0]
	steal_offer["listed_price"] = int(float(steal_offer.get("true_value", 0.0)) * 0.5)
	var r_steal: Dictionary = GameState.acquire_company(steal_offer.get("id", ""))
	if not r_steal.get("ok", false) or r_steal.get("outcome", "") != "steal":
		push_error("acq: half-price deal should classify as steal, got %s" % r_steal)
		failures += 1
	var fair_offer: Dictionary = GameState.company_offers[0]
	fair_offer["listed_price"] = int(fair_offer.get("true_value", 0.0))
	var r_fair: Dictionary = GameState.acquire_company(fair_offer.get("id", ""))
	if not r_fair.get("ok", false) or r_fair.get("outcome", "") != "fair":
		push_error("acq: true-price deal should classify as fair, got %s" % r_fair)
		failures += 1
	var lemon_offer: Dictionary = GameState.company_offers[0]
	lemon_offer["listed_price"] = int(float(lemon_offer.get("true_value", 0.0)) * 1.5)
	var r_lemon: Dictionary = GameState.acquire_company(lemon_offer.get("id", ""))
	if not r_lemon.get("ok", false) or r_lemon.get("outcome", "") != "lemon":
		push_error("acq: 1.5x-price deal should classify as lemon, got %s" % r_lemon)
		failures += 1

	# --- A4: Owned research ticks market; portfolio tech unlocks on buy ---
	var pm_before: float = GameState.get_player_market()
	GameState._tick_owned_companies()
	if GameState.get_player_market() <= pm_before:
		push_error("acq: owned subsidiaries should add market each tick")
		failures += 1
	if not GameState.unlocked_technologies.has("TECH_EXPERIMENTAL_FIELD_SENSOR"):
		push_error("acq: acquiring Qvantic should unlock the field sensor tech")
		failures += 1

	# --- A5: Past-deadline offers expire or get grabbed ---
	var exp_offer: Dictionary = GameState.company_offers[0]
	exp_offer["expires_day"] = GameState.elapsed_days - 1.0
	GameState._rng.seed = 7
	GameState._tick_company_offers()
	var fate: String = exp_offer.get("status", "offered")
	if fate != "expired" and fate != "grabbed":
		push_error("acq: past-deadline offer should close, got '%s'" % fate)
		failures += 1

	# --- A6: Crushing every rival ends the game as a Monopoly ---
	GameState.initialize_new_campaign({"name": "Acq Domination"}, "normal")
	GameState.select_artifact(0)
	GameState.player_market = 20.0
	for r in GameState.rivals:
		var rd: Dictionary = r as Dictionary
		match rd.get("id", ""):
			"RIV_HELIOS":
				rd["acquired_by_player"] = true
				rd["status"] = "acquired"
				rd["share"] = 0.0
			"RIV_BERMANT":
				rd["status"] = "exited"
				rd["share"] = 0.0
			_:
				rd["share"] = 0.1
	GameState._check_market_end()
	if not GameState.is_game_over():
		push_error("acq: crushing all rivals should end the game")
		failures += 1
	elif not GameState.game_over.get("won", false):
		push_error("acq: domination should be a win")
		failures += 1
	elif GameState.game_over.get("type", "") != "monopoly":
		push_error("acq: domination should rank as monopoly, got '%s'" % GameState.game_over.get("type", "?"))
		failures += 1

	# --- A7: Save/load preserves offers, owned, and domination-relevant rival flags ---
	GameState.initialize_new_campaign({"name": "Acq SaveLoad"}, "hard")
	GameState.budget["funds"] = 50000
	var buy_id: String = (GameState.company_offers[1] as Dictionary).get("id", "")
	GameState.acquire_company(buy_id)
	var save := GameState.get_save_data()
	GameState.load_save_data(save)
	if GameState.owned_companies.size() != 1:
		push_error("acq: owned company lost after save/load")
		failures += 1
	if GameState.company_offers.size() != 3:
		push_error("acq: offers not preserved after save/load (got %d)" % GameState.company_offers.size())
		failures += 1

	if failures == 0:
		print("ACQ_OK")
	else:
		print("%d ACQ FAILURES" % failures)

func _test_pacing():
	var failures: int = 0
	var exps: Array = GameState.load_experiment_definitions()
	var exp_def := {}
	for e in exps:
		if (e as Dictionary).get("id", "") == "EXP_HEATING":
			exp_def = e as Dictionary

	# Active player: runs experiments until the game ends (cap 300 days).
	var active_days: float = 0.0
	GameState.initialize_new_campaign({"name": "Pacing Active"}, "normal")
	GameState.select_artifact(0)
	var sci: Dictionary = GameState.scientists[0]
	while active_days < 300 and not GameState.is_game_over():
		if GameState.budget["funds"] < GameState._get_experiment_cost("EXP_HEATING"):
			GameState.budget["funds"] += 200
		GameState.run_experiment(exp_def, sci)
		active_days = GameState.elapsed_days
	if not GameState.game_over.get("won", false):
		push_error("pacing: active research player should win, got game_over=%s at day %.0f" % [GameState.game_over, active_days])
		failures += 1
	if GameState.get_player_market() < GameState.get_majority_target():
		push_error("pacing: active player market %.1f below target %.1f at win" % [GameState.get_player_market(), GameState.get_majority_target()])
		failures += 1

	# Passive player: idle, just advance the clock so rivals/HELIOS race alone.
	var passive_days: float = 0.0
	GameState.initialize_new_campaign({"name": "Pacing Passive"}, "normal")
	GameState.select_artifact(0)
	while passive_days < 400 and not GameState.is_game_over():
		GameState._tick_market()
		GameState._advance_helios()
		GameState._check_market_end()
		passive_days += 1.0
	if GameState.game_over.get("won", true):
		push_error("pacing: idle player should eventually lose to the rival field, got game_over=%s at day %.0f" % [GameState.game_over, passive_days])
		failures += 1

	if failures == 0:
		print("PACING_OK")
	else:
		print("%d PACING FAILURES" % failures)
