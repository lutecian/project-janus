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
		"res://scenes/settings/settings.tscn"
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
