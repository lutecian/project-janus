extends Control

@onready var org_label: Label = $MarginContainer/VBox/header_row/org_label
@onready var day_budget_label: Label = $MarginContainer/VBox/header_row/day_budget_label
@onready var artifact_container: VBoxContainer = $MarginContainer/VBox/artifact_container
@onready var scientist_container: VBoxContainer = $MarginContainer/VBox/scientist_container
@onready var status_label: Label = $MarginContainer/VBox/status_label

@onready var btn_artifact: Button = $MarginContainer/VBox/nav_row/btn_artifact
@onready var btn_scientists: Button = $MarginContainer/VBox/nav_row/btn_scientists
@onready var btn_experiments: Button = $MarginContainer/VBox/nav_row/btn_experiments
@onready var btn_helios: Button = $MarginContainer/VBox/nav_row/btn_helios
@onready var btn_budget: Button = $MarginContainer/VBox/nav_row/btn_budget
@onready var btn_technology: Button = $MarginContainer/VBox/nav_row/btn_technology
@onready var btn_incidents: Button = $MarginContainer/VBox/nav_row/btn_incidents
@onready var btn_main_menu: Button = $MarginContainer/VBox/footer_row/btn_main_menu
@onready var btn_save: Button = $MarginContainer/VBox/footer_row/btn_save

func _ready():
	btn_artifact.pressed.connect(_go.bind("res://scenes/experiment/artifact_detail.tscn"))
	btn_scientists.pressed.connect(_go.bind("res://scenes/experiment/scientist_detail.tscn"))
	btn_experiments.pressed.connect(_go.bind("res://scenes/experiment/experiment_selection.tscn"))
	btn_helios.pressed.connect(_go.bind("res://scenes/experiment/helios_intel.tscn"))
	btn_budget.pressed.connect(_go.bind("res://scenes/budget/budget.tscn"))
	btn_technology.pressed.connect(_go.bind("res://scenes/technology/technology.tscn"))
	btn_incidents.pressed.connect(_go.bind("res://scenes/incidents/incident_reports.tscn"))
	btn_main_menu.pressed.connect(_on_main_menu)
	btn_save.pressed.connect(_on_save)
	_refresh_ui()

func _refresh_ui():
	org_label.text = GameState.organization.get("name", "Unknown Organization")
	day_budget_label.text = "Day %d | $%d" % [GameState.elapsed_days, GameState.budget.get("funds", 0)]
	_populate_artifacts()
	_populate_scientists()

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
		label.text = "%s %s — %s | '%s' [P:%s O:%s C:%s]" % [
			sci.get("first_name", "?"),
			sci.get("last_name", "?"),
			sci.get("primary_specialty", "unknown").replace("_", " ").capitalize(),
			", ".join(sci.get("traits", [])),
			skills.get("physics", 0),
			skills.get("observation", 0),
			skills.get("curiosity", 0)
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
