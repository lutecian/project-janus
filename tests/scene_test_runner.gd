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

var _scenes_to_test: Array = []
var _idx: int = 0

func _test_next():
	if _idx >= _scenes_to_test.size():
		_print_summary()
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
