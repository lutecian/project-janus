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
		"res://scenes/acquisitions/acquisitions.tscn",
		"res://scenes/contracts/contracts.tscn",
		"res://scenes/espionage/espionage.tscn",
		"res://scenes/facilities/facilities.tscn"
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
		_test_contracts()
		_test_events()
		_test_espionage()
		_test_endings()
		_test_depth()
		_test_story()
		_test_action()
		_test_gore()
		_test_audio()
		_test_sec()
		_test_acts()
		_test_batch()
		_test_roster()
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
	if absf(GameState.get_majority_target() - 52.0) > 0.001:
		push_error("market: normal majority target should be 52, got %f" % GameState.get_majority_target())
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
	if absf(GameState.get_majority_target() - 58.0) > 0.001:
		push_error("market: hard majority target not 58 after load, got %f" % GameState.get_majority_target())
		failures += 1

	if failures == 0:
		print("MARKET_OK")
	else:
		print("%d MARKET FAILURES" % failures)

func _test_acq():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Acq Test"}, "normal")
	GameState.select_artifact(0)

	# --- A1: Opening offers spawn with noisy pricing inside the 0.6..1.6 band ---
	if GameState.company_offers.size() != 4:
		push_error("acq: expected 4 opening offers, got %d" % GameState.company_offers.size())
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

	# --- A8: Later companies arrive on schedule ---
	GameState.initialize_new_campaign({"name": "Acq Stagger"}, "normal")
	GameState.select_artifact(0)
	GameState.elapsed_days = 30.0
	GameState._tick_company_offers()
	if GameState.company_offers.size() != 8:
		push_error("acq: all 8 offers should be listed by day 30, got %d" % GameState.company_offers.size())
		failures += 1

	if failures == 0:
		print("ACQ_OK")
	else:
		print("%d ACQ FAILURES" % failures)

func _test_contracts():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Ctr Test"}, "normal")
	GameState.select_artifact(0)

	# --- C1: Deck spawns full, nothing pending yet ---
	if GameState.contract_deck.size() != 14:
		push_error("ctr: expected 14-contract deck, got %d" % GameState.contract_deck.size())
		failures += 1
	if not GameState.pending_offer.is_empty() or not GameState.active_contract.is_empty():
		push_error("ctr: should start with no pending/active contract")
		failures += 1

	# --- C2: Offer arrives once the day comes ---
	GameState.next_offer_day = 0.0
	GameState._tick_contracts()
	if GameState.pending_offer.get("id", "") != "CTR_FOOD":
		push_error("ctr: first offer should be CTR_FOOD, got '%s'" % GameState.pending_offer.get("id", "?"))
		failures += 1

	# --- C3: Accept pays upfront and occupies the single slot ---
	GameState.budget["funds"] = 5000
	var funds_before: int = GameState.budget["funds"]
	var acc: Dictionary = GameState.accept_contract()
	if not acc.get("ok", false):
		push_error("ctr: accept should succeed")
		failures += 1
	if GameState.budget["funds"] != funds_before + 800:
		push_error("ctr: upfront 800 not paid (funds %d)" % GameState.budget["funds"])
		failures += 1
	if GameState.accept_contract().get("ok", true):
		push_error("ctr: second accept should fail while slot busy")
		failures += 1

	# --- C4: Workdays complete it: pay + tech + market ---
	for i in range(4):
		GameState._tick_contracts()
	if not GameState.active_contract.is_empty():
		push_error("ctr: 4-day contract should complete after 4 ticks")
		failures += 1
	if GameState.budget["funds"] != funds_before + 800 + 1200:
		push_error("ctr: completion pay 1200 missing (funds %d)" % GameState.budget["funds"])
		failures += 1
	if not GameState.unlocked_technologies.has("TECH_THERMAL_CONTAINMENT"):
		push_error("ctr: completing CTR_FOOD should unlock thermal containment")
		failures += 1
	if not GameState.completed_contracts.has("CTR_FOOD"):
		push_error("ctr: CTR_FOOD should be recorded complete")
		failures += 1

	# --- C5: Decline reschedules ---
	GameState.next_offer_day = 0.0
	GameState._tick_contracts()
	GameState.decline_contract()
	if not GameState.pending_offer.is_empty():
		push_error("ctr: decline should clear the pending offer")
		failures += 1
	if GameState.next_offer_day <= GameState.elapsed_days:
		push_error("ctr: decline should push the next offer into the future")
		failures += 1

	# --- C6: Event-gated contracts wait for their event ---
	GameState.initialize_new_campaign({"name": "Ctr Gated"}, "normal")
	GameState.select_artifact(0)
	GameState.contract_deck = ["CTR_TRADE"]
	GameState.events_seen = []
	GameState.next_offer_day = 0.0
	GameState._tick_contracts()
	if not GameState.pending_offer.is_empty():
		push_error("ctr: gated contract should not offer before its event")
		failures += 1
	GameState.events_seen = ["EVT_TRADE"]
	GameState.next_offer_day = 0.0
	GameState._tick_contracts()
	if GameState.pending_offer.get("id", "") != "CTR_TRADE":
		push_error("ctr: gated contract should offer once its event was seen")
		failures += 1

	# --- C7: Save/load preserves deck, pending, active, completed ---
	GameState.initialize_new_campaign({"name": "Ctr SaveLoad"}, "hard")
	GameState.next_offer_day = 0.0
	GameState._tick_contracts()
	GameState.accept_contract()
	var save := GameState.get_save_data()
	GameState.load_save_data(save)
	if GameState.active_contract.get("id", "") == "":
		push_error("ctr: active contract lost after save/load")
		failures += 1
	if GameState.contract_deck.size() != 13:
		push_error("ctr: deck not preserved after save/load (got %d)" % GameState.contract_deck.size())
		failures += 1

	if failures == 0:
		print("CTR_OK")
	else:
		print("%d CTR FAILURES" % failures)

func _test_events():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Evt Test"}, "normal")
	GameState.select_artifact(0)

	# --- E1: Two events scheduled ---
	if GameState.event_schedule.size() != 2:
		push_error("evt: expected 2 scheduled events, got %d" % GameState.event_schedule.size())
		failures += 1

	# --- E2: Trigger applies grant + bonus while active ---
	var entry: Dictionary = GameState.event_schedule[0]
	entry["day"] = GameState.elapsed_days - 1.0
	var funds_before: int = GameState.budget["funds"]
	GameState._tick_events()
	if GameState.active_event.is_empty():
		push_error("evt: due event should trigger")
		failures += 1
	else:
		var edef: Dictionary = GameState._event_def(GameState.active_event.get("id", ""))
		var grant: int = int(edef.get("funds_grant", 0))
		if GameState.budget["funds"] != maxi(funds_before + grant, 0):
			push_error("evt: funds grant %d not applied" % grant)
			failures += 1
		var pm_before: float = GameState.get_player_market()
		GameState._tick_events()
		var want: float = pm_before + float(edef.get("player_bonus", 0.0))
		if absf(GameState.get_player_market() - want) > 0.001:
			push_error("evt: daily player bonus not applied")
			failures += 1
		if absf(GameState._event_rival_mult() - float(edef.get("rival_mult", 1.0))) > 0.001:
			push_error("evt: rival multiplier not applied")
			failures += 1

	# --- E3: Expiry clears the event ---
	GameState.active_event["until_day"] = GameState.elapsed_days - 1.0
	GameState._tick_events()
	if not GameState.active_event.is_empty():
		push_error("evt: past-duration event should end")
		failures += 1
	if absf(GameState._event_rival_mult() - 1.0) > 0.001:
		push_error("evt: rival multiplier should revert after event ends")
		failures += 1

	# --- E4: Save/load preserves schedule, active, seen ---
	var save := GameState.get_save_data()
	GameState.load_save_data(save)
	if GameState.events_seen.size() != 1:
		push_error("evt: seen events not preserved after save/load")
		failures += 1

	if failures == 0:
		print("EVT_OK")
	else:
		print("%d EVT FAILURES" % failures)

func _test_espionage():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Esp Test"}, "normal")
	GameState.select_artifact(0)
	GameState.budget["funds"] = 100000

	# --- S1: Ops charge funds and add heat, whatever the roll ---
	var risk_before: float = GameState.esp_risk
	var funds_before: int = GameState.budget["funds"]
	var tries := 0
	var seen_success := false
	while tries < 20 and not seen_success:
		var res: Dictionary = GameState.perform_espionage_op("OP_COUNTER")
		if not res.get("ok", false):
			push_error("esp: counter-intel should always be runnable")
			failures += 1
			break
		seen_success = bool(res.get("success", false))
		tries += 1
	if not seen_success:
		push_error("esp: counter-intel never succeeded in 20 tries (p~0.9)")
		failures += 1
	if GameState.esp_cover <= 0.0:
		push_error("esp: successful counter-intel should raise cover")
		failures += 1
	if GameState.budget["funds"] >= funds_before:
		push_error("esp: ops should cost funds")
		failures += 1

	# --- S2: Steal-tech effect unlocks a locked tech ---
	var techs_before: int = GameState.unlocked_technologies.size()
	var steal_text: String = GameState._apply_espionage_success("OP_STEAL", "")
	if GameState.unlocked_technologies.size() != techs_before + 1:
		push_error("esp: steal should unlock one tech, got '%s'" % steal_text)
		failures += 1

	# --- S3: Sabotage flags a rival; expose cuts share deterministically ---
	var sab_text: String = GameState._apply_espionage_success("OP_SABOTAGE", "RIV_HELIOS")
	var sabotaged_until := 0.0
	for r in GameState.rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("id", "") == "RIV_HELIOS":
			sabotaged_until = float(rd.get("sabotaged_until", 0.0))
	if sabotaged_until <= GameState.elapsed_days:
		push_error("esp: sabotage should slow HELIOS for 6 days, got '%s'" % sab_text)
		failures += 1
	var berm_before := 0.0
	for r in GameState.rivals:
		var rd2: Dictionary = r as Dictionary
		if rd2.get("id", "") == "RIV_BERMANT":
			berm_before = float(rd2.get("share", 0))
	GameState._apply_espionage_success("OP_EXPOSE", "RIV_BERMANT")
	var berm_after := 0.0
	for r in GameState.rivals:
		var rd3: Dictionary = r as Dictionary
		if rd3.get("id", "") == "RIV_BERMANT":
			berm_after = float(rd3.get("share", 0))
	if absf(berm_before - berm_after - 6.0) > 0.001 and not (berm_before < 6.0 and berm_after == 0.0):
		push_error("esp: expose should cut 6 share (%.1f -> %.1f)" % [berm_before, berm_after])
		failures += 1

	# --- S4: Surveillance reveals an exact company valuation ---
	var surv_text: String = GameState._apply_espionage_success("OP_SURVEY", (GameState.company_offers[0] as Dictionary).get("id", ""))
	var surveyed: Dictionary = GameState.company_offers[0]
	if int(surveyed.get("dd_level", 0)) != 2 or absf(float(surveyed.get("dd_error", 1.0))) > 0.001:
		push_error("esp: surveillance should max diligence with zero error, got '%s'" % surv_text)
		failures += 1

	# --- S5: Getting caught is a real setback ---
	GameState.esp_risk = 95.0
	var caught := false
	var tries2 := 0
	while tries2 < 20 and not caught:
		var res2: Dictionary = GameState.perform_espionage_op("OP_EXPOSE", "RIV_HELIOS")
		if ("CAUGHT" in res2.get("detail", "")):
			caught = true
		tries2 += 1
	if not caught:
		push_error("esp: max-heat ops should eventually get caught")
		failures += 1
	var saw_incident := false
	for inc in GameState.incidents:
		if (inc as Dictionary).get("id", "") == "INC_EXPOSED_OP":
			saw_incident = true
	if not saw_incident:
		push_error("esp: caught op should file an exposed-operation incident")
		failures += 1

	# --- S6: Save/load preserves risk and cover ---
	var save := GameState.get_save_data()
	GameState.load_save_data(save)
	if GameState.esp_cover <= 0.0:
		push_error("esp: cover lost after save/load")
		failures += 1

	if failures == 0:
		print("ESP_OK")
	else:
		print("%d ESP FAILURES" % failures)

func _test_endings():
	var failures: int = 0

	# --- N1: Tech depth + full confirmation wins the scientific path ---
	GameState.initialize_new_campaign({"name": "End Sci"}, "normal")
	GameState.select_artifact(0)
	for tech_id in GameState.TECH_KEY_MAP.values():
		if not GameState.unlocked_technologies.has(tech_id):
			GameState.unlocked_technologies.append(tech_id)
	GameState.discovery["state"] = "confirmed"
	for d in GameState.discoveries:
		(d as Dictionary)["state"] = "confirmed"
	GameState.player_market = 10.0
	GameState._check_market_end()
	if not GameState.is_game_over():
		push_error("end: full science should end the game")
		failures += 1
	elif GameState.game_over.get("type", "") != "researcher":
		push_error("end: full science should rank researcher, got '%s'" % GameState.game_over.get("type", "?"))
		failures += 1
	if "distinguished" not in GameState.run_badges:
		push_error("end: researcher win should award the distinguished badge")
		failures += 1

	# --- N2: Tier order is monopoly > researcher > market_leader ---
	GameState.initialize_new_campaign({"name": "End Tiers"}, "normal")
	GameState.select_artifact(0)
	for tech_id in GameState.TECH_KEY_MAP.values():
		if not GameState.unlocked_technologies.has(tech_id):
			GameState.unlocked_technologies.append(tech_id)
	GameState.discovery["state"] = "confirmed"
	for d in GameState.discoveries:
		(d as Dictionary)["state"] = "confirmed"
	GameState.player_market = GameState.get_majority_target() + 5.0
	for r in GameState.rivals:
		var rd: Dictionary = r as Dictionary
		rd["acquired_by_player"] = true
		rd["status"] = "acquired"
		rd["share"] = 0.0
	GameState._check_market_end()
	if GameState.game_over.get("type", "") != "monopoly":
		push_error("end: domination should outrank science, got '%s'" % GameState.game_over.get("type", "?"))
		failures += 1
	GameState.initialize_new_campaign({"name": "End Tiers 2"}, "normal")
	GameState.select_artifact(0)
	for tech_id in GameState.TECH_KEY_MAP.values():
		if not GameState.unlocked_technologies.has(tech_id):
			GameState.unlocked_technologies.append(tech_id)
	GameState.discovery["state"] = "confirmed"
	for d in GameState.discoveries:
		(d as Dictionary)["state"] = "confirmed"
	GameState.player_market = GameState.get_majority_target() + 5.0
	for r in GameState.rivals:
		var rd2: Dictionary = r as Dictionary
		if rd2.get("id", "") == "RIV_HELIOS":
			rd2["share"] = GameState.get_majority_target() - 6.0
	GameState._check_market_end()
	if GameState.game_over.get("type", "") != "researcher":
		push_error("end: science should outrank market, got '%s'" % GameState.game_over.get("type", "?"))
		failures += 1

	# --- N3: Legacy file records the run ---
	if not FileAccess.file_exists("user://janus_legacy.json"):
		push_error("end: legacy file should exist after wins")
		failures += 1
	else:
		var file := FileAccess.open("user://janus_legacy.json", FileAccess.READ)
		var text: String = file.get_as_text()
		file.close()
		var json := JSON.new()
		if json.parse(text) != OK:
			push_error("end: legacy file should parse as JSON")
			failures += 1
		elif not (json.data as Dictionary).get("best", {}).has("normal"):
			push_error("end: legacy best should record the normal-difficulty run")
			failures += 1

	if failures == 0:
		print("END_OK")
	else:
		print("%d END FAILURES" % failures)

func _test_depth():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Depth Test"}, "normal")
	GameState.select_artifact(0)
	GameState.budget["funds"] = 30000

	# --- D1: Facilities buy cleanly and apply effects ---
	for fid in ["FAC_LAB", "FAC_SHIELD", "FAC_DESK", "FAC_INTEL", "FAC_SCANNER"]:
		var br: Dictionary = GameState.buy_facility(fid)
		if not br.get("ok", false):
			push_error("depth: buying %s should succeed, got %s" % [fid, br])
			failures += 1
	if GameState.facilities_owned.size() != 5:
		push_error("depth: expected 5 facilities owned")
		failures += 1
	if GameState.buy_facility("FAC_LAB").get("ok", true):
		push_error("depth: re-buying a facility should fail")
		failures += 1
	if absf(GameState.esp_cover - 15.0) > 0.001:
		push_error("depth: Intel Cell should grant +15 cover, got %.1f" % GameState.esp_cover)
		failures += 1
	var first_offer: String = (GameState.company_offers[0] as Dictionary).get("id", "")
	var f_before: int = GameState.budget["funds"]
	GameState.perform_due_diligence(first_offer)
	if f_before - GameState.budget["funds"] != 200:
		push_error("depth: Deep Scanner should halve DD cost to 200")
		failures += 1
	var pm_before: float = GameState.get_player_market()
	GameState._rng.seed = 4242
	GameState._tick_market()
	if GameState.get_player_market() - pm_before < 0.9:
		push_error("depth: Trading Desk should add >=0.9 market per tick on normal")
		failures += 1

	# --- D2: Enemy-op chance math + deterministic effects ---
	var helios: Dictionary = {}
	for r in GameState.rivals:
		if (r as Dictionary).get("id", "") == "RIV_HELIOS":
			helios = r as Dictionary
	GameState.esp_cover = 100.0
	if GameState._enemy_op_chance(helios) != 0.0:
		push_error("depth: full cover should block enemy ops")
		failures += 1
	GameState.esp_cover = 0.0
	var open_chance: float = GameState._enemy_op_chance(helios)
	# 0.05 base x0.5 shield x(1 - 20/150 security) = 0.021667
	if absf(open_chance - 0.021667) > 0.0002:
		push_error("depth: shielded HELIOS op chance should be ~0.0217, got %f" % open_chance)
		failures += 1
	var funds_before: int = GameState.budget["funds"]
	GameState._apply_enemy_op(helios, "raid")
	var raid_loss: int = funds_before - GameState.budget["funds"]
	if raid_loss < 200 or raid_loss > 2000:
		push_error("depth: raid should steal 200-2000, got %d" % raid_loss)
		failures += 1
	GameState.player_market = 20.0
	GameState._apply_enemy_op(helios, "smear")
	if absf(GameState.get_player_market() - 18.0) > 0.001:
		push_error("depth: smear should cut exactly 2 market")
		failures += 1
	GameState._apply_enemy_op(helios, "sabotage")
	if GameState.player_sabotaged_until <= GameState.elapsed_days:
		push_error("depth: sabotage should slow research for 3 days")
		failures += 1
	var exps: Array = GameState.load_experiment_definitions()
	var heat := {}
	for e in exps:
		if (e as Dictionary).get("id", "") == "EXP_HEATING":
			heat = e as Dictionary
	var sci: Dictionary = GameState.scientists[0]
	GameState.initialize_new_campaign({"name": "Depth Sabotage"}, "normal")
	GameState.select_artifact(0)
	GameState.budget["funds"] = 30000
	GameState.incident_cooldown = 100
	GameState._rng.seed = 555
	GameState.run_experiment(heat, sci)
	var d_plain: int = GameState.knowledge["progress"]
	GameState.knowledge["progress"] = 0
	GameState.knowledge["observations"] = []
	GameState.knowledge["experiment_counts"] = {}
	GameState.player_sabotaged_until = GameState.elapsed_days + 3.0
	GameState._rng.seed = 555
	GameState.run_experiment(heat, sci)
	var d_sab: int = GameState.knowledge["progress"]
	# Halving within rounding: sabotaged gain doubled should not exceed the plain gain + 1.
	if d_sab * 2 > d_plain + 1:
		push_error("depth: sabotage should roughly halve knowledge gain (%d vs %d)" % [d_sab, d_plain])
		failures += 1

	# --- D3: Consolidation absorbs small rivals into the leader ---
	GameState.initialize_new_campaign({"name": "Depth Consolidate"}, "normal")
	GameState.select_artifact(0)
	var leader := {}
	var small := {}
	for r in GameState.rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("id", "") == "RIV_HELIOS":
			rd["share"] = 30.0
			leader = rd
		if rd.get("id", "") == "RIV_BERMANT":
			rd["share"] = 3.0
			small = rd
	var lead_before: float = float(leader.get("share", 0))
	GameState._consolidate_rival(small, leader)
	if small.get("status", "") != "acquired" or small.get("acquired_by_player", true):
		push_error("depth: small rival should be absorbed (not by player)")
		failures += 1
	if absf(float(leader.get("share", 0)) - (lead_before + 2.0)) > 0.001:
		push_error("depth: leader should gain +2 from absorption")
		failures += 1
	if not GameState._rival_crushed(small):
		push_error("depth: absorbed rival should count as crushed (no soft-lock)")
		failures += 1

	# --- D4: Continue-after-win raises the stakes ---
	GameState.initialize_new_campaign({"name": "Depth Continue"}, "normal")
	GameState.select_artifact(0)
	GameState.player_market = GameState.get_majority_target() + 1.0
	for r in GameState.rivals:
		var rd0: Dictionary = r as Dictionary
		if rd0.get("id", "") == "RIV_HELIOS":
			rd0["share"] = GameState.get_majority_target() - 6.0
	GameState._check_market_end()
	if GameState.game_over.get("type", "") != "market_leader":
		push_error("depth: setup should win market first")
		failures += 1
	var cont: Dictionary = GameState.continue_after_win()
	if not cont.get("ok", false):
		push_error("depth: continue should be allowed after a market win")
		failures += 1
	if GameState.is_game_over():
		push_error("depth: game should resume after continue")
		failures += 1
	if absf(GameState.get_majority_target() - 67.0) > 0.001:
		push_error("depth: target should rise +15 after continue, got %.1f" % GameState.get_majority_target())
		failures += 1
	GameState.initialize_new_campaign({"name": "Depth Continue 2"}, "normal")
	GameState.select_artifact(0)
	for r in GameState.rivals:
		var rd2: Dictionary = r as Dictionary
		rd2["share"] = GameState.get_majority_target() + 1.0
		break
	GameState._check_market_end()
	if GameState.continue_after_win().get("ok", true):
		push_error("depth: continue should be refused after a defeat")
		failures += 1

	# --- D5: Expert locks the scientific path ---
	GameState.initialize_new_campaign({"name": "Depth Expert"}, "expert")
	if absf(GameState.get_majority_target() - 62.0) > 0.001:
		push_error("depth: expert target should be 62, got %.1f" % GameState.get_majority_target())
		failures += 1
	GameState.select_artifact(0)
	for tech_id in GameState.TECH_KEY_MAP.values():
		if not GameState.unlocked_technologies.has(tech_id):
			GameState.unlocked_technologies.append(tech_id)
	GameState.discovery["state"] = "confirmed"
	for d in GameState.discoveries:
		(d as Dictionary)["state"] = "confirmed"
	GameState.player_market = 10.0
	GameState._check_market_end()
	if GameState.is_game_over():
		push_error("depth: expert should lock the scientific win (got %s)" % GameState.game_over.get("type", "?"))
		failures += 1
	GameState.player_market = 63.0
	for r in GameState.rivals:
		var rd3: Dictionary = r as Dictionary
		if rd3.get("id", "") == "RIV_HELIOS":
			rd3["share"] = 56.0
	GameState._check_market_end()
	if GameState.game_over.get("type", "") != "market_leader":
		push_error("depth: expert market win should still work")
		failures += 1

	# --- D6: Save/load preserves facilities, sabotage, continue state ---
	GameState.initialize_new_campaign({"name": "Depth SaveLoad"}, "normal")
	GameState.select_artifact(0)
	GameState.budget["funds"] = 30000
	GameState.buy_facility("FAC_DESK")
	GameState.buy_facility("FAC_SHIELD")
	GameState.player_sabotaged_until = 12.0
	GameState.continued = true
	GameState.bonus_target = 15.0
	var save := GameState.get_save_data()
	GameState.load_save_data(save)
	if not GameState.has_facility("FAC_DESK") or not GameState.has_facility("FAC_SHIELD"):
		push_error("depth: facilities lost after save/load")
		failures += 1
	if absf(GameState.player_sabotaged_until - 12.0) > 0.001:
		push_error("depth: sabotage timer lost after save/load")
		failures += 1
	if not GameState.continued or absf(GameState.bonus_target - 15.0) > 0.001:
		push_error("depth: continue state lost after save/load")
		failures += 1

	if failures == 0:
		print("DEPTH_OK")
	else:
		print("%d DEPTH FAILURES" % failures)

func _test_story():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Story Test"}, "normal")
	GameState.select_artifact(0)

	# --- T1: Scientist intros logged at campaign start ---
	var intros := 0
	for entry in GameState.story_log:
		if (entry as Dictionary).get("kind", "") == "intro":
			intros += 1
	if intros != 3:
		push_error("story: expected 3 scientist intros, got %d" % intros)
		failures += 1

	# --- T2: Dormant + suspected beats fire as knowledge grows ---
	var exps: Array = GameState.load_experiment_definitions()
	var heat := {}
	for e in exps:
		if (e as Dictionary).get("id", "") == "EXP_HEATING":
			heat = e as Dictionary
	var sci: Dictionary = GameState.scientists[0]
	GameState.budget["funds"] = 50000
	GameState.incident_cooldown = 100
	for i in range(12):
		GameState.run_experiment(heat, sci)
		if GameState.knowledge.get("state", "") == "suspected":
			break
	if not GameState.fired_beats.has("J001:dormant"):
		push_error("story: dormant beat should fire on first study")
		failures += 1
	if not GameState.fired_beats.has("J001:suspected"):
		push_error("story: suspected beat should fire at state change (state=%s)" % GameState.knowledge.get("state", "?"))
		failures += 1
	var beat_count: int = GameState.fired_beats.size()
	GameState.run_experiment(heat, sci)
	if GameState.fired_beats.size() != beat_count:
		push_error("story: beats should fire exactly once each")
		failures += 1

	# --- T3: Dangerous runs fire the danger beat ---
	GameState._rng.seed = 31
	GameState._check_dangerous_experiment("EXP_RADIOACTIVE")
	if not GameState.fired_beats.has("J001:danger"):
		push_error("story: danger beat should fire on a dangerous run")
		failures += 1

	# --- T4: Rival taunts fire at share milestones ---
	for r in GameState.rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("id", "") == "RIV_HELIOS":
			rd["share"] = 26.0
	GameState._rng.seed = 4242
	GameState._tick_market()
	var taunted := false
	for rep in GameState.intelligence_reports:
		if "Rennick" in (rep as Dictionary).get("text", ""):
			taunted = true
	if not taunted:
		push_error("story: HELIOS should taunt when crossing 25 share")
		failures += 1

	# --- T5: Save/load preserves the story log ---
	var save := GameState.get_save_data()
	GameState.load_save_data(save)
	if GameState.story_log.size() < 5:
		push_error("story: story log lost after save/load")
		failures += 1
	if not GameState.fired_beats.has("J001:danger"):
		push_error("story: fired beats lost after save/load")
		failures += 1

	if failures == 0:
		print("STORY_OK")
	else:
		print("%d STORY FAILURES" % failures)

func _test_action():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Action Test"}, "normal")
	GameState.select_artifact(0)
	GameState.budget["funds"] = 30000

	# --- C1: Major incidents spawn a crisis with a clock ---
	var major := {
		"id": "INC_TEST_MAJOR", "name": "Test Blowout", "description": "d",
		"severity": "major", "effects": {"budget_cost": 0, "days_lost": 0},
		"crisis": {"days": 5, "resolve_cost": 1500}
	}
	GameState._apply_incident(major)
	if GameState.active_crises.size() != 1:
		push_error("action: major incident should spawn a crisis")
		failures += 1
	var cid: String = (GameState.active_crises[0] as Dictionary).get("id", "")

	# --- C2: Paying resolves cleanly ---
	var f_before: int = GameState.budget["funds"]
	var r_pay: Dictionary = GameState.resolve_crisis(cid, "pay")
	if not r_pay.get("ok", false):
		push_error("action: paid resolve should succeed, got %s" % r_pay)
		failures += 1
	if GameState.budget["funds"] != f_before - 1500:
		push_error("action: paid resolve should cost exactly 1500")
		failures += 1
	if not GameState.active_crises.is_empty():
		push_error("action: resolved crisis should clear")
		failures += 1

	# --- C3: Response team resolves with risk ---
	GameState._apply_incident(major)
	var cid2: String = (GameState.active_crises[0] as Dictionary).get("id", "")
	GameState._rng.seed = 77
	var r_team: Dictionary = GameState.resolve_crisis(cid2, "team")
	if not r_team.get("ok", false):
		push_error("action: team resolve should succeed, got %s" % r_team)
		failures += 1
	if not GameState.active_crises.is_empty():
		push_error("action: team-resolved crisis should clear")
		failures += 1

	# --- C4: Ignored crises burn out badly ---
	GameState._apply_incident(major)
	var c3: Dictionary = GameState.active_crises[0]
	c3["days_left"] = 1.0
	var f_pre: int = GameState.budget["funds"]
	GameState._tick_crises()
	if not GameState.active_crises.is_empty():
		push_error("action: expired crisis should clear")
		failures += 1
	if GameState.budget["funds"] != f_pre - 3000:
		push_error("action: expired crisis should cost 3000, funds %d" % GameState.budget["funds"])
		failures += 1

	# --- C5: Save/load preserves active crises ---
	GameState._apply_incident(major)
	var save := GameState.get_save_data()
	GameState.load_save_data(save)
	if GameState.active_crises.size() != 1:
		push_error("action: active crisis lost after save/load")
		failures += 1

	if failures == 0:
		print("ACTION_OK")
	else:
		print("%d ACTION FAILURES" % failures)

func _test_gore():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Gore Test"}, "normal")
	GameState.select_artifact(0)

	# --- G1: Toggle gates the graphic text ---
	var rec := {"description": "mild", "graphic_description": "graphic"}
	GameState.gore_setting = 1
	if GameState.incident_display_text(rec) != "graphic":
		push_error("gore: forced-on should show graphic text")
		failures += 1
	GameState.gore_setting = 0
	if GameState.incident_display_text(rec) != "mild":
		push_error("gore: forced-off should show mild text")
		failures += 1
	GameState.gore_setting = -1

	# --- G2: Harm thresholds injure then kill ---
	GameState._harm_scientist("SCIENTIST_CHEN", 70, "in testing")
	var chen := {}
	for s in GameState.scientists:
		if (s as Dictionary).get("id", "") == "SCIENTIST_CHEN":
			chen = s as Dictionary
	if chen.get("status", "") != "INJURED":
		push_error("gore: 70 damage should injure Chen (hp %s)" % chen.get("health", "?"))
		failures += 1
	GameState._harm_scientist("SCIENTIST_CHEN", 30, "in testing")
	if chen.get("status", "") != "DECEASED":
		push_error("gore: lethal damage should kill Chen")
		failures += 1
	if "first_blood" not in GameState.run_badges:
		push_error("gore: first death should award first_blood")
		failures += 1

	# --- G3: The dead cannot be assigned ---
	var exps: Array = GameState.load_experiment_definitions()
	var heat := {}
	for e in exps:
		if (e as Dictionary).get("id", "") == "EXP_HEATING":
			heat = e as Dictionary
	GameState.budget["funds"] = 30000
	if not GameState.run_experiment(heat, chen).is_empty():
		push_error("gore: deceased scientist must be refused experiments")
		failures += 1

	# --- G4: Injuries measurably hurt observation quality ---
	var reed := {}
	for s in GameState.scientists:
		if (s as Dictionary).get("id", "") == "SCIENTIST_REED":
			reed = s as Dictionary
	GameState._rng.seed = 606
	var q1: float = GameState._calculate_observation_quality(heat, reed)
	reed["status"] = "INJURED"
	GameState._rng.seed = 606
	var q2: float = GameState._calculate_observation_quality(heat, reed)
	if absf(q2 - q1 * 0.7) > 0.0001:
		push_error("gore: injured quality should be exactly 0.7x (%.4f vs %.4f)" % [q2, q1])
		failures += 1
	reed["status"] = "ACTIVE"

	# --- G5: Casualties persist through save/load ---
	var save := GameState.get_save_data()
	GameState.load_save_data(save)
	var chen2 := {}
	for s in GameState.scientists:
		if (s as Dictionary).get("id", "") == "SCIENTIST_CHEN":
			chen2 = s as Dictionary
	if chen2.get("status", "") != "DECEASED" or int(chen2.get("health", 100)) != 0:
		push_error("gore: death not preserved after save/load")
		failures += 1

	# --- G6: An all-dead roster ends the run instead of hanging ---
	GameState.initialize_new_campaign({"name": "Gore Wipe"}, "normal")
	for s in GameState.scientists:
		(s as Dictionary)["status"] = "DECEASED"
	GameState.run_experiment(heat, GameState.scientists[0])
	if not GameState.is_game_over() or GameState.game_over.get("reason", "") != "staff_wipe":
		push_error("gore: an all-dead roster should end the run as staff_wipe")
		failures += 1

	if failures == 0:
		print("GORE_OK")
	else:
		print("%d GORE FAILURES" % failures)

func _test_audio():
	var failures: int = 0
	for key in ["drone", "tension", "incident", "death", "victory", "defeat", "click", "buyout", "alarm", "resolve"]:
		if not AudioManager.streams.has(key):
			push_error("audio: missing stream '%s'" % key)
			failures += 1
			continue
		var stream: AudioStreamWAV = AudioManager.streams[key]
		if stream.data.size() < 1000:
			push_error("audio: stream '%s' suspiciously short" % key)
			failures += 1
	AudioManager.start_music("menu")
	if AudioManager.current_mode != "menu":
		push_error("audio: menu mode not set")
		failures += 1
	AudioManager.start_music("lab")
	AudioManager.set_tension(true)
	AudioManager.set_tension(false)
	for key in ["click", "incident", "resolve", "buyout", "alarm", "victory", "defeat", "death"]:
		AudioManager.play_sfx(key)
	AudioManager.stop_music()
	if AudioManager.current_mode != "none":
		push_error("audio: stop should clear mode")
		failures += 1

	if failures == 0:
		print("AUDIO_OK")
	else:
		print("%d AUDIO FAILURES" % failures)

func _test_sec():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Sec Test"}, "normal")
	GameState.select_artifact(0)
	GameState.budget["funds"] = 50000

	# --- V1: Security rises with the garrison ---
	if absf(GameState.get_security() - 20.0) > 0.001:
		push_error("sec: base security should be 20, got %.1f" % GameState.get_security())
		failures += 1
	GameState.buy_facility("FAC_GARRISON")
	if absf(GameState.get_security() - 50.0) > 0.001:
		push_error("sec: garrison should raise security to 50, got %.1f" % GameState.get_security())
		failures += 1

	# --- V2: Military contracts build ties ---
	GameState.active_contract = {"id": "CTR_ARTILLERY", "days_done": 0.0, "days_required": 1.0}
	GameState._tick_contracts()
	if absf(GameState.military_ties - 25.0) > 0.001:
		push_error("sec: military completion should grant 25 ties, got %.1f" % GameState.military_ties)
		failures += 1
	if "war_contractor" not in GameState.run_badges:
		push_error("sec: military completion should award war_contractor")
		failures += 1

	# --- V3: Ties discount facilities and buyouts ---
	GameState.military_ties = 50.0
	if GameState.facility_price("FAC_LAB") != 3600:
		push_error("sec: 50 ties should discount FAC_LAB to 3600, got %d" % GameState.facility_price("FAC_LAB"))
		failures += 1
	GameState.military_ties = 75.0
	if GameState.facility_price("FAC_LAB") != 3200:
		push_error("sec: 75 ties should discount FAC_LAB to 3200, got %d" % GameState.facility_price("FAC_LAB"))
		failures += 1
	for r in GameState.rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("id", "") == "RIV_HELIOS":
			rd["share"] = 20.0
	if GameState.get_rival_buyout_price("RIV_HELIOS") != 5600:
		push_error("sec: 75 ties should discount HELIOS buyout to 5600, got %d" % GameState.get_rival_buyout_price("RIV_HELIOS"))
		failures += 1

	# --- V4: Sentinel requires earned trust ---
	GameState.initialize_new_campaign({"name": "Sec Gate"}, "normal")
	GameState.select_artifact(0)
	GameState.contract_deck = ["CTR_SENTINEL"]
	GameState.military_ties = 0.0
	GameState.next_offer_day = 0.0
	GameState._tick_contracts()
	if not GameState.pending_offer.is_empty():
		push_error("sec: sentinel should wait for 25 ties")
		failures += 1
	GameState.military_ties = 25.0
	GameState.next_offer_day = 0.0
	GameState._tick_contracts()
	if GameState.pending_offer.get("id", "") != "CTR_SENTINEL":
		push_error("sec: sentinel should offer at 25 ties")
		failures += 1

	# --- V5: Save/load preserves ties ---
	GameState.military_ties = 60.0
	var save := GameState.get_save_data()
	GameState.load_save_data(save)
	if absf(GameState.military_ties - 60.0) > 0.001:
		push_error("sec: ties lost after save/load")
		failures += 1

	if failures == 0:
		print("SEC_OK")
	else:
		print("%d SEC FAILURES" % failures)

func _confirm_current_artifact(sci: Dictionary, heat: Dictionary):
	GameState.knowledge["progress"] = 70
	GameState.run_experiment(heat, sci)

func _test_acts():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Acts Test"}, "normal")
	GameState.select_artifact(0)
	GameState.budget["funds"] = 50000
	GameState.incident_cooldown = 100
	var exps: Array = GameState.load_experiment_definitions()
	var heat := {}
	for e in exps:
		if (e as Dictionary).get("id", "") == "EXP_HEATING":
			heat = e as Dictionary
	var sci: Dictionary = GameState.scientists[0]

	# --- A1: Act 1 gates the back half ---
	if GameState.act != 1:
		push_error("acts: should start in act 1")
		failures += 1
	if not GameState.is_artifact_unlocked("J001") or GameState.is_artifact_unlocked("J004"):
		push_error("acts: act 1 should unlock J001-J003 only")
		failures += 1
	GameState.select_artifact(3)
	if GameState.selected_artifact_index != 0:
		push_error("acts: selecting a locked artifact should be refused")
		failures += 1
	if absf(GameState._act_rival_mult() - 1.0) > 0.001:
		push_error("acts: act 1 rival mult should be 1.0")
		failures += 1

	# --- A2: First confirmation advances to act 2 ---
	_confirm_current_artifact(sci, heat)
	if GameState.act != 2:
		push_error("acts: one confirmation should advance to act 2, got act %d" % GameState.act)
		failures += 1
	if not GameState.is_artifact_unlocked("J006"):
		push_error("acts: act 2 should unlock everything")
		failures += 1
	if absf(GameState._act_rival_mult() - 1.15) > 0.001:
		push_error("acts: act 2 rival mult should be 1.15")
		failures += 1

	# --- A3: Three confirmations reach endgame ---
	GameState.select_artifact(1)
	_confirm_current_artifact(sci, heat)
	GameState.select_artifact(2)
	_confirm_current_artifact(sci, heat)
	if GameState.act != 3:
		push_error("acts: three confirmations should reach act 3, got act %d" % GameState.act)
		failures += 1
	if absf(GameState._act_rival_mult() - 1.5) > 0.001:
		push_error("acts: act 3 rival mult should be 1.5")
		failures += 1

	# --- A4: Save/load preserves the act ---
	var save := GameState.get_save_data()
	GameState.load_save_data(save)
	if GameState.act != 3:
		push_error("acts: act lost after save/load")
		failures += 1

	if failures == 0:
		print("ACTS_OK")
	else:
		print("%d ACTS FAILURES" % failures)

func _test_batch():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Batch Test"}, "normal")
	GameState.select_artifact(0)
	GameState.budget["funds"] = 50000
	GameState.incident_cooldown = 100
	var exps: Array = GameState.load_experiment_definitions()
	var heat := {}
	for e in exps:
		if (e as Dictionary).get("id", "") == "EXP_HEATING":
			heat = e as Dictionary
	for s in GameState.scientists:
		(s as Dictionary)["stress"] = 50
	var cost: int = GameState._get_experiment_cost("EXP_HEATING")

	# --- B1: A day with two experiments advances one day ---
	var day_before: float = GameState.elapsed_days
	var funds_before: int = GameState.budget["funds"]
	var results: Array = GameState.run_day_batch([
		{"exp": heat, "sci": GameState.scientists[0]},
		{"exp": heat, "sci": GameState.scientists[1]}
	])
	if results.size() != 2:
		push_error("batch: expected 2 results, got %d" % results.size())
		failures += 1
	if absf(GameState.elapsed_days - (day_before + 1.0)) > 0.001:
		push_error("batch: a batched day should advance exactly 1 day")
		failures += 1
	if (results[0] as Dictionary).get("day", -1.0) != (results[1] as Dictionary).get("day", -1.0):
		push_error("batch: batched experiments should share a day stamp")
		failures += 1
	if GameState.budget["funds"] > funds_before - cost * 2:
		push_error("batch: both experiments should charge (funds %d)" % GameState.budget["funds"])
		failures += 1
	if int(GameState.scientists[0].get("stress", 0)) != 54 or int(GameState.scientists[1].get("stress", 0)) != 54:
		push_error("batch: workers should gain +4 stress")
		failures += 1
	if int(GameState.scientists[2].get("stress", 0)) != 42:
		push_error("batch: rested scientist should recover -8 stress, got %d" % GameState.scientists[2].get("stress", 0))
		failures += 1

	# --- B2: Duplicate scientists and the dead are skipped ---
	var dup: Array = GameState.run_day_batch([
		{"exp": heat, "sci": GameState.scientists[0]},
		{"exp": heat, "sci": GameState.scientists[0]}
	])
	if dup.size() != 1:
		push_error("batch: duplicate scientist should run once, got %d" % dup.size())
		failures += 1
	GameState._harm_scientist("SCIENTIST_CHEN", 200, "in testing")
	var with_dead: Array = GameState.run_day_batch([
		{"exp": heat, "sci": GameState.scientists[0]},
		{"exp": heat, "sci": GameState.scientists[1]}
	])
	if with_dead.size() != 1:
		push_error("batch: deceased scientist should be skipped, got %d" % with_dead.size())
		failures += 1

	if failures == 0:
		print("BATCH_OK")
	else:
		print("%d BATCH FAILURES" % failures)

func _test_roster():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Roster Test"}, "normal")
	GameState.select_artifact(0)
	GameState.budget["funds"] = 50000

	# --- R1: Hiring fills the roster to the cap ---
	if GameState.hire_pool.size() != 3 or GameState.scientists.size() != 3:
		push_error("roster: should start 3 rostered + 3 candidates")
		failures += 1
	var h1: Dictionary = GameState.hire_scientist("SCIENTIST_LUND")
	if not h1.get("ok", false) or GameState.scientists.size() != 4:
		push_error("roster: hiring Lund should work, got %s" % h1)
		failures += 1
	GameState.hire_scientist("SCIENTIST_OSEI")
	var h3: Dictionary = GameState.hire_scientist("SCIENTIST_PETROVA")
	if h3.get("ok", true):
		push_error("roster: hiring past the cap of 5 should fail")
		failures += 1

	# --- R2: The dead free their slot ---
	GameState._harm_scientist("SCIENTIST_REED", 200, "in testing")
	var h4: Dictionary = GameState.hire_scientist("SCIENTIST_PETROVA")
	if not h4.get("ok", false):
		push_error("roster: death should free a slot, got %s" % h4)
		failures += 1

	# --- R3: Broke hiring fails, state saves ---
	GameState.initialize_new_campaign({"name": "Roster Broke"}, "normal")
	GameState.budget["funds"] = 100
	if GameState.hire_scientist("SCIENTIST_LUND").get("ok", true):
		push_error("roster: hiring without funds should fail")
		failures += 1
	GameState.budget["funds"] = 50000
	GameState.hire_scientist("SCIENTIST_LUND")
	var save := GameState.get_save_data()
	GameState.load_save_data(save)
	if GameState.scientists.size() != 4 or GameState.hire_pool.size() != 2:
		push_error("roster: roster/pool not preserved after save/load")
		failures += 1

	if failures == 0:
		print("ROSTER_OK")
	else:
		print("%d ROSTER FAILURES" % failures)

func _test_pacing():
	var failures: int = 0
	var exps: Array = GameState.load_experiment_definitions()
	var exp_def := {}
	for e in exps:
		if (e as Dictionary).get("id", "") == "EXP_HEATING":
			exp_def = e as Dictionary

	# Active player: runs experiments until the game ends (cap 300 days).
	var active_days: float = 0.0
	GameState.initialize_new_campaign({"name": "Pacing Active"}, "normal", 1234)
	GameState.select_artifact(0)
	var sci: Dictionary = GameState.scientists[0]
	var guard := 0
	while active_days < 300 and not GameState.is_game_over() and guard < 1000:
		guard += 1
		for s in GameState.scientists:
			if (s as Dictionary).get("status", "ACTIVE") != "DECEASED":
				sci = s as Dictionary
				break
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
	GameState.initialize_new_campaign({"name": "Pacing Passive"}, "normal", 4321)
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
