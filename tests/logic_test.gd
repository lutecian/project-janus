extends Node

func _ready():
	var failures: int = 0
	GameState.initialize_new_campaign({"name": "Logic Test"})
	GameState.select_artifact(0)
	if GameState.discoveries.size() < 2:
		push_error("J001 should have 2 discoveries, got %d" % GameState.discoveries.size())
		failures += 1
	var sci: Dictionary = GameState.scientists[0]
	var all_defs: Array = GameState.load_experiment_definitions()
	var heating_idx: int = -1
	for e in all_defs:
		if (e as Dictionary).get("id", "") == "EXP_HEATING":
			heating_idx = all_defs.find(e)
			break
	GameState.knowledge["progress"] = 50
	for i in range(4):
		GameState.run_experiment(all_defs[heating_idx], sci)
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
	var unlocked_ids: Array = []
	for exp in GameState.get_unlocked_experiments(GameState.load_experiment_definitions()):
		unlocked_ids.append((exp as Dictionary).get("id", ""))
	if not unlocked_ids.has("EXP_RADIOACTIVE"):
		push_error("EXP_RADIOACTIVE should be unlocked with thermal containment")
		failures += 1
	# Save/load round-trip preserves discoveries and tech
	var save_data: Dictionary = GameState.get_save_data()
	GameState.load_save_data(save_data)
	if not GameState.unlocked_technologies.has("TECH_THERMAL_CONTAINMENT"):
		push_error("Thermal containment lost after save/load")
		failures += 1
	var ea_after_load: bool = false
	for d in GameState.discoveries:
		if (d as Dictionary).get("discovery_id", "") == "DISC_ENERGY_ABSORPTION":
			ea_after_load = (d as Dictionary).get("state", "") == "confirmed"
	if not ea_after_load:
		push_error("Energy absorption state lost after save/load")
		failures += 1
	if failures == 0:
		print("LOGIC_OK")
	else:
		print("%d LOGIC FAILURES" % failures)
	get_tree().quit()
