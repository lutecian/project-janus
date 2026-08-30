extends Control

@onready var artifact_label: RichTextLabel = $ScrollContainer/VBox/artifact_label
@onready var knowledge_label: Label = $ScrollContainer/VBox/knowledge_label
@onready var scientist_container: VBoxContainer = $ScrollContainer/VBox/scientist_container
@onready var experiment_container: VBoxContainer = $ScrollContainer/VBox/experiment_container
@onready var btn_run: Button = $ScrollContainer/VBox/ButtonRow/btn_run
@onready var btn_save: Button = $ScrollContainer/VBox/ButtonRow/btn_save
@onready var btn_main_menu: Button = $ScrollContainer/VBox/ButtonRow/btn_main_menu
@onready var status_label: Label = $ScrollContainer/VBox/status_label
@onready var helios_label: Label = $ScrollContainer/VBox/helios_label
@onready var discovery_label: Label = $ScrollContainer/VBox/discovery_label
@onready var org_label: Label = $ScrollContainer/VBox/org_label
@onready var tech_label: Label = $ScrollContainer/VBox/tech_label
@onready var briefing_panel: VBoxContainer = $ScrollContainer/VBox/briefing_panel
@onready var briefing_dismiss: Button = $ScrollContainer/VBox/briefing_panel/BriefingDismiss
@onready var day_label: Label = $ScrollContainer/VBox/day_label
@onready var nav_container: HBoxContainer = $ScrollContainer/VBox/nav_container
@onready var btn_lab: Button = $ScrollContainer/VBox/nav_container/btn_lab
@onready var btn_artifact_detail: Button = $ScrollContainer/VBox/nav_container/btn_artifact_detail
@onready var btn_helios_intel: Button = $ScrollContainer/VBox/nav_container/btn_helios_intel
@onready var btn_budget: Button = $ScrollContainer/VBox/nav_container/btn_budget
@onready var btn_technology: Button = $ScrollContainer/VBox/nav_container/btn_technology
@onready var btn_incidents: Button = $ScrollContainer/VBox/nav_container/btn_incidents
@onready var artifact_name_label: Label = $ScrollContainer/VBox/artifact_selector/artifact_name_label
@onready var btn_prev_artifact: Button = $ScrollContainer/VBox/artifact_selector/btn_prev_artifact
@onready var btn_next_artifact: Button = $ScrollContainer/VBox/artifact_selector/btn_next_artifact
@onready var budget_label: Label = $ScrollContainer/VBox/budget_label

var selected_scientist_index: int = -1
var selected_experiment_id: String = ""
var experiments: Array = []
var selected_scientist_button: Button = null

func _ready():
	btn_run.pressed.connect(_on_run_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	btn_main_menu.pressed.connect(_on_menu_pressed)
	briefing_dismiss.pressed.connect(_on_briefing_dismissed)
	btn_lab.pressed.connect(_on_lab)
	btn_artifact_detail.pressed.connect(_on_artifact_detail)
	btn_helios_intel.pressed.connect(_on_helios_intel)
	btn_budget.pressed.connect(_on_budget)
	btn_technology.pressed.connect(_on_technology)
	btn_incidents.pressed.connect(_on_incidents)
	btn_prev_artifact.pressed.connect(_on_prev_artifact)
	btn_next_artifact.pressed.connect(_on_next_artifact)
	experiments = _load_experiments()
	_refresh_ui()
	EventBus.knowledge_updated.connect(_on_knowledge_updated)
	EventBus.discovery_suspected.connect(_on_discovery_suspected)
	EventBus.discovery_confirmed.connect(_on_discovery_confirmed)
	EventBus.technology_unlocked.connect(_on_tech_unlocked)
	EventBus.rival_progressed.connect(_on_rival_progressed)
	EventBus.incident_occurred.connect(_on_incident_occurred)
	EventBus.budget_updated.connect(_on_budget_updated)

func _refresh_ui():
	org_label.text = GameState.organization.get("name", "Unknown Organization")

	var total_artifacts: int = GameState.available_artifacts.size()
	artifact_name_label.text = "OBJECT %s (%d/%d)" % [
		GameState.artifact.get("id", "???"),
		GameState.selected_artifact_index + 1,
		total_artifacts
	]
	btn_prev_artifact.disabled = (GameState.selected_artifact_index <= 0)
	btn_next_artifact.disabled = (GameState.selected_artifact_index >= total_artifacts - 1)

	var known: Dictionary = GameState.artifact.get("known_initial_data", {})
	artifact_label.text = "OBJECT %s — %s\n%s\nMass: %.1f kg | Diameter: %.1f cm | Temp: %.1f C" % [
		GameState.artifact.get("id", "???"),
		GameState.artifact.get("display_name", "Unknown"),
		GameState.artifact.get("visible_description", ""),
		known.get("mass_kg", 0), known.get("diameter_cm", 0), known.get("surface_temperature_c", 0)
	]

	var progress: int = GameState.knowledge["progress"]
	var state: String = GameState.knowledge["state"]
	knowledge_label.text = "Knowledge: %d%% — State: %s | Observations: %d | Experiments: %d" % [
		progress, state.capitalize(),
		GameState.knowledge["observations"].size(),
		GameState.experiment_history.size()
	]

	helios_label.text = "HELIOS: %d%% — Artifact: %s" % [
		GameState.helios["progress"],
		GameState.helios.get("artifact_name", "Unknown")
	]

	var confirmed_names: Array = []
	for d in GameState.discoveries:
		var d_dict: Dictionary = d as Dictionary
		if d_dict.get("state", "unknown") == "confirmed":
			var dname: String = d_dict.get("player_name", "")
			if dname.is_empty():
				dname = d_dict.get("internal_name", "??")
			confirmed_names.append(dname)
	if confirmed_names.size() > 0:
		discovery_label.text = "Confirmed Phenomena: %s" % ", ".join(confirmed_names)
		discovery_label.visible = true
	else:
		discovery_label.visible = false

	var unlocked_tech_names: Array = []
	for tech_id in GameState.unlocked_technologies:
		var td := _find_tech(tech_id)
		if not td.is_empty():
			unlocked_tech_names.append(td.get("name", tech_id))
	if GameState.technology_unlocked and unlocked_tech_names.is_empty():
		unlocked_tech_names.append("Experimental Field Sensor")
	if unlocked_tech_names.size() > 0:
		tech_label.text = "Technology: %s" % ", ".join(unlocked_tech_names)
		tech_label.visible = true
	else:
		tech_label.visible = false

	day_label.text = "Day: %d" % GameState.elapsed_days
	budget_label.text = "Budget: $%d (Spent: $%d)" % [GameState.budget["funds"], GameState.budget["spent"]]

	btn_helios_intel.text = "HELIOS Intel (%d reports)" % GameState.intelligence_reports.size()

	_populate_scientists()
	_populate_experiments()
	_update_run_button()

	if GameState.experiment_history.is_empty():
		briefing_panel.visible = true
	else:
		briefing_panel.visible = false

	if GameState.discovery["state"] == "confirmed" and not GameState.discovery["player_name"].is_empty():
		get_tree().change_scene_to_file("res://scenes/experiment/results/breakthrough.tscn")

func _populate_scientists():
	for child in scientist_container.get_children():
		child.queue_free()

	for i in range(GameState.scientists.size()):
		var s: Dictionary = GameState.scientists[i]
		var hbox := HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 36)

		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = "%s %s — %s" % [
			s.get("first_name", "?"),
			s.get("last_name", "?"),
			s.get("primary_specialty", "unknown").replace("_", " ").capitalize()
		]
		btn.pressed.connect(_on_scientist_selected.bind(i))
		hbox.add_child(btn)

		var detail_btn := Button.new()
		detail_btn.custom_minimum_size = Vector2(70, 36)
		detail_btn.text = "Detail"
		detail_btn.pressed.connect(_on_scientist_detail.bind(i))
		hbox.add_child(detail_btn)

		scientist_container.add_child(hbox)

	_update_scientist_buttons()

func _populate_experiments():
	for child in experiment_container.get_children():
		child.queue_free()

	var unlocked := GameState.get_unlocked_experiments(experiments)

	for exp in experiments:
		var exp_dict: Dictionary = exp as Dictionary
		var exp_id: String = exp_dict.get("id", "")
		var is_unlocked: bool = GameState.is_experiment_unlocked(exp_id)
		var obs_count: int = GameState.knowledge["experiment_counts"].get(exp_id, 0)
		var cost: int = GameState._get_experiment_cost(exp_id)
		var affordable: bool = GameState.can_afford_experiment(exp_id)

		var btn := Button.new()
		if is_unlocked:
			btn.text = "%s (%s, +%d knowledge) [%d done] $%d" % [
				exp_dict.get("name", "?"),
				exp_dict.get("category", "?").capitalize(),
				exp_dict.get("knowledge_gain", 0),
				obs_count,
				cost
			]
			btn.disabled = not affordable
			if not affordable:
				btn.text += " [INSUFFICIENT FUNDS]"
		else:
			var threshold: int = 0
			var thresholds: Dictionary = GameState.EXPERIMENT_UNLOCK_THRESHOLDS
			if thresholds.has(exp_id):
				threshold = thresholds[exp_id]
			var requires_tech: String = exp_dict.get("requires_tech", "")
			var lock_reason := "requires %d%% knowledge" % threshold
			var per_threshold: int = exp_dict.get("unlock_threshold", 0)
			if per_threshold > threshold:
				lock_reason = "requires %d%% knowledge" % per_threshold
			if not requires_tech.is_empty() and not GameState.unlocked_technologies.has(requires_tech):
				lock_reason = "requires a technology"
			btn.text = "%s [LOCKED — %s]" % [exp_dict.get("name", "?"), lock_reason]
			btn.disabled = true

		btn.custom_minimum_size = Vector2(0, 36)
		btn.pressed.connect(_on_experiment_selected.bind(exp_id))
		experiment_container.add_child(btn)

	_update_experiment_buttons()

func _on_scientist_selected(index: int):
	GameState.selected_scientist_index = index
	_update_scientist_buttons()
	_update_run_button()

func _on_scientist_detail(index: int):
	GameState.selected_scientist_index = index
	get_tree().change_scene_to_file("res://scenes/experiment/scientist_detail.tscn")

func _on_experiment_selected(experiment_id: String):
	if not GameState.is_experiment_unlocked(experiment_id):
		return
	selected_experiment_id = experiment_id
	_update_experiment_buttons()
	_update_run_button()

func _update_scientist_buttons():
	for i in range(scientist_container.get_child_count()):
		var hbox: HBoxContainer = scientist_container.get_child(i)
		var btn: Button = hbox.get_child(0)
		btn.button_pressed = (i == selected_scientist_index)

func _update_experiment_buttons():
	for i in range(experiment_container.get_child_count()):
		var btn: Button = experiment_container.get_child(i)
		if i < experiments.size():
			var exp: Dictionary = experiments[i] as Dictionary
			btn.button_pressed = (exp.get("id", "") == selected_experiment_id)

func _update_run_button():
	btn_run.disabled = (selected_scientist_index < 0 or selected_experiment_id.is_empty())
	if btn_run.disabled:
		btn_run.text = "Select Scientist & Experiment"
	else:
		var cost: int = GameState._get_experiment_cost(selected_experiment_id)
		var affordable: bool = GameState.can_afford_experiment(selected_experiment_id)
		if affordable:
			btn_run.text = "Run Experiment ($%d)" % cost
			btn_run.disabled = false
		else:
			btn_run.text = "Insufficient Funds ($%d needed)" % cost
			btn_run.disabled = true

func _on_run_pressed():
	if selected_scientist_index < 0 or selected_experiment_id.is_empty():
		return

	var exp_def := _get_experiment_by_id(selected_experiment_id)
	var scientist: Dictionary = GameState.scientists[selected_scientist_index]
	GameState.run_experiment(exp_def, scientist)
	SaveManager.save_game()

	get_tree().change_scene_to_file("res://scenes/experiment/results/experiment_result.tscn")

func _on_save_pressed():
	SaveManager.save_game()
	status_label.text = "Campaign saved."

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _on_briefing_dismissed():
	briefing_panel.visible = false

func _on_artifact_detail():
	get_tree().change_scene_to_file("res://scenes/experiment/artifact_detail.tscn")

func _on_helios_intel():
	get_tree().change_scene_to_file("res://scenes/experiment/helios_intel.tscn")

func _on_prev_artifact():
	if GameState.selected_artifact_index > 0:
		GameState.select_artifact(GameState.selected_artifact_index - 1)
		selected_scientist_index = -1
		selected_experiment_id = ""
		_refresh_ui()

func _on_next_artifact():
	if GameState.selected_artifact_index < GameState.available_artifacts.size() - 1:
		GameState.select_artifact(GameState.selected_artifact_index + 1)
		selected_scientist_index = -1
		selected_experiment_id = ""
		_refresh_ui()

func _on_lab():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")

func _on_budget():
	get_tree().change_scene_to_file("res://scenes/budget/budget.tscn")

func _on_technology():
	get_tree().change_scene_to_file("res://scenes/technology/technology.tscn")

func _on_incidents():
	get_tree().change_scene_to_file("res://scenes/incidents/incident_reports.tscn")

func _on_knowledge_updated(_progress: int, _state: String):
	pass

func _on_discovery_suspected(_discovery_id: String):
	status_label.text = "Scientists suspect a significant phenomenon..."

func _on_discovery_confirmed(_discovery_id: String):
	status_label.text = "Discovery confirmed! Proceed to name the phenomenon."

func _on_tech_unlocked(_tech_id: String, tech_name: String):
	status_label.text = "Technology unlocked: %s" % tech_name

func _on_rival_progressed(_progress: int, message: String):
	status_label.text = "HELIOS PRESSURE: %s" % message
	status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))

func _on_incident_occurred(incident: Dictionary):
	status_label.text = "INCIDENT: %s — %s" % [incident.get("name", ""), incident.get("description", "")]
	status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_refresh_ui()

func _on_budget_updated(_funds: int, _spent: int):
	_refresh_ui()

func _load_experiments() -> Array:
	var file := FileAccess.open("res://data/experiments/experiments.json", FileAccess.READ)
	if not file:
		return []
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return []
	if json.data is Dictionary:
		return (json.data as Dictionary).get("experiments", []) as Array
	return []

func _find_tech(tech_id: String) -> Dictionary:
	var file := FileAccess.open("res://data/technologies/technologies.json", FileAccess.READ)
	if not file:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var techs: Array = (json.data as Dictionary).get("technologies", []) as Array
	for t in techs:
		var t_dict: Dictionary = t as Dictionary
		if t_dict.get("id", "") == tech_id:
			return t_dict
	return {}

func _get_experiment_by_id(id: String) -> Dictionary:
	for exp in _load_experiments():
		if exp.get("id", "") == id:
			return exp as Dictionary
	return {}
