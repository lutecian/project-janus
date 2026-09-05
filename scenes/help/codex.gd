extends Control

@onready var body_label: RichTextLabel = $ScrollContainer/VBox/body_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

func _ready():
	btn_back.pressed.connect(_on_back)
	var data: Dictionary = GameState._load_json("res://data/meta/codex.json")
	var text := ""
	for section in data.get("sections", []):
		var sd: Dictionary = section as Dictionary
		text += "=== %s ===\n%s\n\n" % [sd.get("title", "?"), sd.get("body", "")]
	body_label.text = text.strip_edges()

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
