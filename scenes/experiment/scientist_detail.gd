extends Control

@onready var title_label: Label = $ScrollContainer/VBox/title_label
@onready var specialty_label: Label = $ScrollContainer/VBox/specialty_label
@onready var skills_label: Label = $ScrollContainer/VBox/skills_label
@onready var traits_label: Label = $ScrollContainer/VBox/traits_label
@onready var status_label: Label = $ScrollContainer/VBox/status_label
@onready var history_label: RichTextLabel = $ScrollContainer/VBox/history_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

var scientist: Dictionary = {}

func _ready():
	btn_back.pressed.connect(_on_back)
	scientist = GameState.get_meta("selected_scientist", {})
	if scientist.is_empty():
		title_label.text = "No scientist selected."
		return
	_display_scientist()

func _display_scientist():
	title_label.text = "%s %s" % [
		scientist.get("first_name", "?"),
		scientist.get("last_name", "?")
	]
	specialty_label.text = "Specialty: %s" % scientist.get("primary_specialty", "unknown").replace("_", " ").capitalize()

	var skills: Dictionary = scientist.get("skills", {})
	var skill_text := ""
	for key in ["physics", "engineering", "observation", "curiosity", "risk_tolerance"]:
		var val: int = int(skills.get(key, 0))
		var bar := ""
		var filled: int = val / 10
		for i in range(filled):
			bar += "#"
		for i in range(10 - filled):
			bar += "-"
		skill_text += "%-15s [%s] %d\n" % [key.replace("_", " ").capitalize(), bar, val]
	skills_label.text = skill_text

	var traits: Array = scientist.get("traits", [])
	var trait_text := "Traits: "
	var trait_names: PackedStringArray = []
	for t in traits:
		trait_names.append(t.capitalize())
	trait_text += ", ".join(trait_names) if trait_names.size() > 0 else "None"
	traits_label.text = trait_text

	var status: String = scientist.get("status", "ACTIVE")
	var stress: int = int(scientist.get("stress", 0))
	var health: int = int(scientist.get("health", 100))
	var loyalty: int = int(scientist.get("loyalty", 100))
	var exp: int = int(scientist.get("experience", 0))
	status_label.text = "Status: %s | Stress: %d | Health: %d | Loyalty: %d | Experience: %d" % [
		status, stress, health, loyalty, exp
	]

	var history_text := ""
	for record in GameState.experiment_history:
		var rec: Dictionary = record as Dictionary
		if rec.get("scientist_id", "") == scientist.get("id", ""):
			history_text += "Day %d: %s\n  Quality: %.0f%% | Knowledge: +%d\n\n" % [
				rec.get("day", 0),
				rec.get("experiment_name", "?"),
				rec.get("quality", 0.0) * 100,
				rec.get("knowledge_gain", 0)
			]
	if history_text.is_empty():
		history_text = "No experiment history."
	history_label.text = history_text

func _on_back():
	get_tree().change_scene_to_file("res://scenes/experiment/experiment_selection.tscn")
