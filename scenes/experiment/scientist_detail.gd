extends Control

@onready var title_label: Label = $ScrollContainer/VBox/title_label
@onready var specialty_label: Label = $ScrollContainer/VBox/specialty_label
@onready var skills_label: Label = $ScrollContainer/VBox/skills_label
@onready var traits_label: Label = $ScrollContainer/VBox/traits_label
@onready var train_hint: Label = $ScrollContainer/VBox/train_hint
@onready var train_container: VBoxContainer = $ScrollContainer/VBox/train_container
@onready var status_label: Label = $ScrollContainer/VBox/status_label
@onready var history_label: RichTextLabel = $ScrollContainer/VBox/history_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

var scientist: Dictionary = {}

func _ready():
	btn_back.pressed.connect(_on_back)
	if GameState.selected_scientist_index >= 0 and GameState.selected_scientist_index < GameState.scientists.size():
		scientist = GameState.scientists[GameState.selected_scientist_index]
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
	status_label.text = "Status: %s | Stress: %d | Health: %d | Loyalty: %d | Experience: %d (Lv %d)" % [
		status, stress, health, loyalty, exp, GameState.scientist_level(scientist.get("id", ""))
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
	_refresh_training()

func _refresh_training():
	for child in train_container.get_children():
		child.queue_free()
	if scientist.is_empty() or not GameState._is_available(scientist):
		train_hint.text = "Training requires an available scientist."
		return
	train_hint.text = "Training costs a full day (+8 stress, +2 experience). Skills cap at %d." % GameState.TRAIN_SKILL_CAP
	var skills: Dictionary = scientist.get("skills", {})
	for skill in GameState.TRAINABLE_SKILLS:
		var cur: int = int(skills.get(skill, 0))
		var cost: int = GameState.training_cost(scientist.get("id", ""), skill)
		var btn := Button.new()
		if cur >= GameState.TRAIN_SKILL_CAP:
			btn.text = "Train %s: MAXED (%d)" % [skill.capitalize(), cur]
			btn.disabled = true
		else:
			btn.text = "Train %s: %d -> %d ($%d)" % [skill.capitalize(), cur, cur + 1, cost]
			btn.disabled = int(GameState.budget.get("funds", 0)) < cost
		btn.pressed.connect(_on_train.bind(skill))
		train_container.add_child(btn)

func _on_train(skill: String):
	var res: Dictionary = GameState.train_scientist(scientist.get("id", ""), skill)
	if not res.get("ok", false):
		train_hint.text = "Training refused (%s)." % res.get("reason", "?")
		return
	scientist = GameState.scientists[GameState.selected_scientist_index]
	_display_scientist()

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
