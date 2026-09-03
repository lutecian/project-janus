extends Node

# Visual verification harness: launches windowed (so rendering actually happens),
# loads each UI screen, waits for it to settle, saves a screenshot, then quits.
# Expected usage: godot.exe --path <repo> res://tests/screenshot_harness.tscn

var shot_dir := "C:/Users/lutec/AppData/Local/Temp/opencode/shots"

var screens: Array = [
	{"path": "res://scenes/main/main_menu.tscn", "state": false},
	{"path": "res://scenes/campaign/campaign_creation.tscn", "state": false},
	{"path": "res://scenes/laboratory/laboratory.tscn", "state": true},
	{"path": "res://scenes/budget/budget.tscn", "state": true},
	{"path": "res://scenes/technology/technology.tscn", "state": true},
	{"path": "res://scenes/incidents/incident_reports.tscn", "state": true},
	{"path": "res://scenes/experiment/experiment_selection.tscn", "state": true},
	{"path": "res://scenes/experiment/scientist_detail.tscn", "state": true},
	{"path": "res://scenes/experiment/artifact_detail.tscn", "state": true},
	{"path": "res://scenes/experiment/helios_intel.tscn", "state": true},
	{"path": "res://scenes/settings/settings.tscn", "state": true},
	{"path": "res://scenes/endgame/game_over.tscn", "state": "victory"},
	{"path": "res://scenes/acquisitions/acquisitions.tscn", "state": true},
]

var _idx := 0
var _current: Node = null

func _ready():
	DirAccess.make_dir_recursive_absolute(shot_dir)
	_seed_realistic()
	_call_next.call_deferred()

func _seed_realistic():
	GameState.initialize_new_campaign({"name": "Visual Check"})
	GameState.select_artifact(0)
	GameState.seed = 777
	GameState._rng.seed = 777
	GameState.elapsed_days = 8.0
	GameState.knowledge["progress"] = 48
	GameState.knowledge["state"] = "suspected"
	GameState.knowledge["observations"] = [
		{"content": "Large amounts of energy enter the environment but sphere temperature remains nearly constant.", "type": "active", "confidence": "high", "discovery_hint": "energy_absorption"},
		{"content": "Mass fluctuates by 2.3% at low frequency.", "type": "active", "confidence": "medium", "discovery_hint": "grav_nullification"},
		{"content": "Electromagnetic exposure at resonance range affects gravitational measurements.", "type": "active", "confidence": "high", "discovery_hint": "grav_attenuation"},
		{"content": "Acoustic sensors detect no internal vibration or resonance.", "type": "passive", "confidence": "medium"},
		{"content": "Object mass reads consistently across multiple measurement attempts.", "type": "passive", "confidence": "low", "discovery_hint": "energy_absorption"}
	]
	for d in GameState.discoveries:
		(d as Dictionary)["state"] = "suspected"
	GameState.helios["progress"] = 46
	GameState.helios["artifact_name"] = "Crystalline Matrix"
	GameState.helios["thresholds_hit"] = [15, 30]
	GameState.intelligence_reports = [
		{"day": 2, "threshold": 15, "text": "Rival teams have begun low-level analysis of local artifacts.", "helios_progress": 15},
		{"day": 6, "threshold": 30, "text": "HELIOS has escalated funding; expect accelerated progress.", "helios_progress": 33}
	]
	GameState.budget["funds"] = 8750
	GameState.budget["spent"] = 11500
	GameState.budget["funding_received"] = 6500
	GameState.budget["events_received"] = ["discovery_suspected"]
	GameState.experiment_history = [
		{"experiment_id": "EXP_HEATING", "experiment_name": "Heating", "scientist_id": "chen", "scientist_name": "Sarah Chen", "observations": [], "knowledge_gain": 4, "quality": 0.62, "day": 1.0, "narrative": "Sarah Chen heated the artifact and recorded an anomalous thermal response.", "relevant_skill": "physics"},
		{"experiment_id": "EXP_EM_LOW", "experiment_name": "Electromagnetic Exposure — Low Frequency", "scientist_id": "vasquez", "scientist_name": "Elena Vasquez", "observations": [], "knowledge_gain": 3, "quality": 0.71, "day": 2.0, "narrative": "Elena Vasquez observed a low-frequency mass fluctuation.", "relevant_skill": "physics"},
		{"experiment_id": "EXP_EM_RESONANCE", "experiment_name": "Electromagnetic Exposure — Resonance Range", "scientist_id": "chen", "scientist_name": "Sarah Chen", "observations": [], "knowledge_gain": 6, "quality": 0.68, "day": 3.0, "narrative": "Resonance-range exposure altered gravitational measurements.", "relevant_skill": "physics"},
		{"experiment_id": "EXP_ACOUSTIC", "experiment_name": "Acoustic Resonance", "scientist_id": "vasquez", "scientist_name": "Elena Vasquez", "observations": [], "knowledge_gain": 3, "quality": 0.59, "day": 4.0, "narrative": "No acoustic resonance detected.", "relevant_skill": "engineering"}
	]
	GameState.incidents = [
		{"id": "INC_EQUIPMENT_FAILURE", "name": "Equipment Failure", "description": "A surge damaged the spectrometer array.", "severity": "moderate", "day": 3, "mitigated": false},
		{"id": "INC_TEST", "name": "Power Surge", "description": "A transient surge damaged instrumentation. Field Stabilizer reduced the impact.", "severity": "minor", "day": 6, "mitigated": true}
	]
	GameState.unlocked_technologies = ["TECH_THERMAL_CONTAINMENT"]
	GameState.confirmed_discoveries = []
	GameState.player_market = 34.2
	GameState._spawn_rivals()
	for r in GameState.rivals:
		if (r as Dictionary).get("id", "") == "RIV_HELIOS":
			(r as Dictionary)["share"] = 28.0
	GameState._sync_helios_rival()

func _call_next():
	if _idx >= screens.size():
		print("SHOTS_DONE -> " + shot_dir)
		get_tree().quit()
		return
	var entry: Dictionary = screens[_idx]
	if (entry.get("state") is String) and (entry.get("state") == "victory"):
		GameState.game_over = {
			"won": true, "reason": "market_majority",
			"player_market": 54.0, "dominant_rival": "HELIOS Research Authority",
			"type": "market_leader"
		}
	else:
		GameState.game_over = {}
	var pack: PackedScene = load(entry["path"])
	_current = pack.instantiate()
	get_tree().root.add_child(_current)
	await get_tree().process_frame
	await get_tree().process_frame
	_capture(_idx, entry["path"])
	_current.queue_free()
	_idx += 1
	_call_next()

func _capture(idx: int, path: String):
	var root := get_tree().root
	var img := root.get_texture().get_image()
	var name := (path.get_file().get_basename())
	var file := "%s/%02d_%s.png" % [shot_dir, idx, name]
	img.save_png(file)
	print("SHOT %s = %s" % [name, file])
