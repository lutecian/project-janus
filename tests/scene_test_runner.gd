extends Node

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
	if GameState.discoveries.size() < 2:
		push_error("J001 should have 2 discoveries, got %d" % GameState.discoveries.size())
		failures += 1
	var sci: Dictionary = GameState.scientists[0]
	# Run heating experiments to promote energy absorption discovery
	GameState.knowledge["progress"] = 50
	var heating_idx: int = -1
	var all_defs: Array = GameState.load_experiment_definitions()
	for e in all_defs:
		if (e as Dictionary).get("id", "") == "EXP_HEATING":
			heating_idx = all_defs.find(e)
			break
	if heating_idx >= 0:
		for i in range(4):
			GameState.run_experiment(all_defs[heating_idx], sci)
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
	# Radioactive experiment requires thermal containment -> now unlocked
	var unlocked_ids: Array = []
	for exp in GameState.get_unlocked_experiments(GameState.load_experiment_definitions()):
		unlocked_ids.append((exp as Dictionary).get("id", ""))
	if not unlocked_ids.has("EXP_RADIOACTIVE"):
		push_error("EXP_RADIOACTIVE should be unlocked with thermal containment")
		failures += 1
	var save_data: Dictionary = GameState.get_save_data()
	GameState.load_save_data(save_data)
	if not GameState.unlocked_technologies.has("TECH_THERMAL_CONTAINMENT"):
		push_error("Thermal containment lost after save/load")
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
