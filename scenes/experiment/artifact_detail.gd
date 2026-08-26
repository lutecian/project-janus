extends Control

@onready var title_label: Label = $ScrollContainer/VBox/title_label
@onready var desc_label: RichTextLabel = $ScrollContainer/VBox/desc_label
@onready var known_label: Label = $ScrollContainer/VBox/known_label
@onready var knowledge_state: Label = $ScrollContainer/VBox/knowledge_state
@onready var observations_label: RichTextLabel = $ScrollContainer/VBox/observations_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

func _ready():
	btn_back.pressed.connect(_on_back)
	_display_artifact()

func _display_artifact():
	title_label.text = "OBJECT %s — %s" % [
		GameState.artifact.get("id", "???"),
		GameState.artifact.get("display_name", "Unknown")
	]
	desc_label.text = GameState.artifact.get("visible_description", "")

	var known: Dictionary = GameState.artifact.get("known_initial_data", {})
	var parts: PackedStringArray = []
	for key in known:
		var val: Variant = known[key]
		parts.append("%s: %s" % [key.replace("_", " ").capitalize(), str(val)])
	known_label.text = "KNOWN PROPERTIES\n" + "\n".join(parts)

	var state: String = GameState.knowledge["state"]
	var progress: int = GameState.knowledge["progress"]
	knowledge_state.text = "Knowledge State: %s (%d%%)" % [state.capitalize(), progress]

	var obs_text := ""
	var observations: Array = GameState.knowledge["observations"]
	if observations.is_empty():
		obs_text = "No observations recorded yet."
	else:
		for i in range(observations.size()):
			var obs: Dictionary = observations[i] as Dictionary
			obs_text += "%d. [%s] %s\n   -> %s\n" % [
				i + 1,
				obs.get("confidence", "?").to_upper(),
				obs.get("content", ""),
				obs.get("interpretation", "")
			]
	observations_label.text = obs_text

func _on_back():
	get_tree().change_scene_to_file("res://scenes/experiment/experiment_selection.tscn")
