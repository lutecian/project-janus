extends Control

@onready var org_label: Label = $MarginContainer/VBox/header_row/org_label
@onready var day_budget_label: Label = $MarginContainer/VBox/header_row/day_budget_label
@onready var artifact_container: VBoxContainer = $MarginContainer/VBox/artifacts_panel/artifacts_vbox/artifact_container
@onready var scientist_container: VBoxContainer = $MarginContainer/VBox/scientists_panel/scientists_vbox/scientist_container
@onready var status_label: Label = $MarginContainer/VBox/status_label

@onready var btn_artifact: Button = $MarginContainer/VBox/nav_row/btn_artifact
@onready var btn_scientists: Button = $MarginContainer/VBox/nav_row/btn_scientists
@onready var btn_experiments: Button = $MarginContainer/VBox/nav_row/btn_experiments
@onready var btn_helios: Button = $MarginContainer/VBox/nav_row/btn_helios
@onready var btn_budget: Button = $MarginContainer/VBox/nav_row/btn_budget
@onready var btn_technology: Button = $MarginContainer/VBox/nav_row/btn_technology
@onready var btn_incidents: Button = $MarginContainer/VBox/nav_row/btn_incidents
@onready var btn_acquisitions: Button = $MarginContainer/VBox/nav_row2/btn_acquisitions
@onready var btn_contracts: Button = $MarginContainer/VBox/nav_row2/btn_contracts
@onready var btn_espionage: Button = $MarginContainer/VBox/nav_row2/btn_espionage
@onready var btn_facilities: Button = $MarginContainer/VBox/nav_row2/btn_facilities
@onready var btn_main_menu: Button = $MarginContainer/VBox/footer_row/btn_main_menu
@onready var btn_save: Button = $MarginContainer/VBox/footer_row/btn_save
@onready var memorial_overlay: PanelContainer = $MemorialOverlay
@onready var memorial_title: Label = $MemorialOverlay/MemorialVBox/memorial_title
@onready var memorial_text: Label = $MemorialOverlay/MemorialVBox/memorial_text
@onready var btn_memorial_continue: Button = $MemorialOverlay/MemorialVBox/btn_memorial_continue

func _ready():
	btn_artifact.pressed.connect(_go.bind("res://scenes/experiment/artifact_detail.tscn"))
	btn_scientists.pressed.connect(_go.bind("res://scenes/experiment/scientist_detail.tscn"))
	btn_experiments.pressed.connect(_go.bind("res://scenes/experiment/experiment_selection.tscn"))
	btn_helios.pressed.connect(_go.bind("res://scenes/experiment/helios_intel.tscn"))
	btn_budget.pressed.connect(_go.bind("res://scenes/budget/budget.tscn"))
	btn_technology.pressed.connect(_go.bind("res://scenes/technology/technology.tscn"))
	btn_incidents.pressed.connect(_go.bind("res://scenes/incidents/incident_reports.tscn"))
	btn_acquisitions.pressed.connect(_go.bind("res://scenes/acquisitions/acquisitions.tscn"))
	btn_contracts.pressed.connect(_go.bind("res://scenes/contracts/contracts.tscn"))
	btn_espionage.pressed.connect(_go.bind("res://scenes/espionage/espionage.tscn"))
	btn_facilities.pressed.connect(_go.bind("res://scenes/facilities/facilities.tscn"))
	btn_main_menu.pressed.connect(_on_main_menu)
	btn_save.pressed.connect(_on_save)
	btn_memorial_continue.pressed.connect(_on_memorial_continue)
	EventBus.game_over.connect(_on_game_over)
	EventBus.market_updated.connect(_on_market_updated)
	EventBus.scientist_died.connect(_on_scientist_died)
	AudioManager.start_music("lab")
	_refresh_ui()
	_maybe_memorial()

func _process(_delta):
	var dread: bool = not GameState.active_crises.is_empty() or GameState.esp_risk >= 50.0
	AudioManager.set_tension(dread)

func _maybe_memorial():
	if GameState.pending_memorial.is_empty():
		return
	_show_memorial(GameState.pending_memorial)

func _on_scientist_died(dead_name: String):
	_show_memorial_by_name(dead_name)

func _show_memorial(sci_id: String):
	memorial_title.text = "KIA: %s" % GameState._scientist_name(sci_id)
	memorial_text.text = "The work continues because it must. Their notebook is sealed into the archive."
	_show_memorial_overlay()

func _show_memorial_by_name(dead_name: String):
	memorial_title.text = "KIA: %s" % dead_name
	memorial_text.text = "The work continues because it must. Their notebook is sealed into the archive."
	_show_memorial_overlay()

func _show_memorial_overlay():
	memorial_overlay.visible = true
	memorial_overlay.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(memorial_overlay, "modulate:a", 1.0, 1.2)

func _on_memorial_continue():
	GameState.pending_memorial = ""
	memorial_overlay.visible = false

func _refresh_ui():
	org_label.text = GameState.organization.get("name", "Unknown Organization")
	var event_text := ""
	if not GameState.active_event.is_empty():
		event_text = " | EVENT: %s" % GameState.active_event.get("name", "?")
	day_budget_label.text = "Day %d | $%d | My Market: %.1f%%%s" % [
		GameState.elapsed_days, GameState.budget.get("funds", 0), GameState.get_player_market(), event_text
	]
	_populate_artifacts()
	_populate_scientists()

func _on_market_updated(_player_market: float, _rivals: Array):
	_populate_artifacts()

func _on_game_over(_result: Dictionary):
	get_tree().change_scene_to_file("res://scenes/endgame/game_over.tscn")

func _populate_artifacts():
	for child in artifact_container.get_children():
		child.queue_free()

	for i in range(GameState.available_artifacts.size()):
		var art: Dictionary = GameState.available_artifacts[i]
		var label := Label.new()
		var status := ""
		var matched: bool = art.get("id", "") == GameState.artifact.get("id", "")
		if matched:
			status = " (SELECTED)"
		label.text = "OBJECT %s — %s%s" % [art.get("id", "?"), art.get("display_name", "?"), status]
		label.add_theme_font_size_override("font_size", 15)
		artifact_container.add_child(label)

func _populate_scientists():
	for child in scientist_container.get_children():
		child.queue_free()

	for s in GameState.scientists:
		var sci: Dictionary = s as Dictionary
		var label := Label.new()
		var skills: Dictionary = sci.get("skills", {})
		var condition := ""
		if sci.get("status", "ACTIVE") == "DECEASED":
			condition = " [DECEASED]"
		elif sci.get("status", "ACTIVE") == "INJURED":
			condition = " [INJURED, HP %d]" % int(sci.get("health", 0))
		label.text = "%s %s — %s | '%s' [P:%s O:%s C:%s]%s" % [
			sci.get("first_name", "?"),
			sci.get("last_name", "?"),
			sci.get("primary_specialty", "unknown").replace("_", " ").capitalize(),
			", ".join(sci.get("traits", [])),
			skills.get("physics", 0),
			skills.get("observation", 0),
			skills.get("curiosity", 0),
			condition
		]
		label.add_theme_font_size_override("font_size", 14)
		scientist_container.add_child(label)

func _on_main_menu():
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _on_save():
	SaveManager.save_game()
	status_label.text = "Campaign saved."

func _go(path: String):
	get_tree().change_scene_to_file(path)
