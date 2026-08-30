extends Control

@onready var tech_label: RichTextLabel = $ScrollContainer/VBox/tech_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

func _ready():
	btn_back.pressed.connect(_on_back)
	_refresh()

func _refresh():
	var data := _load_json("res://data/technologies/technologies.json")
	var techs: Array = data.get("technologies", [])
	var text := ""

	for tech in techs:
		var t: Dictionary = tech as Dictionary
		var tech_id: String = t.get("id", "")
		var unlocked: bool = _is_unlocked(tech_id, t)

		var status := "[LOCKED]"
		var color := "#888888"
		if unlocked:
			status = "[UNLOCKED]"
			color = "#4dccff"

		text += "%s %s — %s\n" % [status, t.get("name", "?"), tech_id]
		text += "  %s\n" % t.get("description", "")
		if unlocked:
			text += "  Effect: %s\n" % t.get("effect", "")
		else:
			text += "  Effect: ???\n"
			text += "  Unlock: %s\n" % _unlock_text(t)
		text += "\n"

	tech_label.text = text

func _unlock_text(tech: Dictionary) -> String:
	var disc: String = tech.get("unlock_discovery", "")
	var techs := {
		"DISC_ENERGY_ABSORPTION": "Confirm the artifact's energy absorption effect",
		"DISC_GRAV_AMPLIFICATION": "Confirm gravitational amplification",
		"DISC_GRAV_NULLIFICATION": "Confirm gravitational nullification",
		"DISC_GRAV_ATTENUATION": "Confirm gravitational attenuation"
	}
	if disc in techs:
		return techs[disc]
	return "confirm the associated discovery"

func _is_unlocked(tech_id: String, tech: Dictionary) -> bool:
	if tech_id == "TECH_EXPERIMENTAL_FIELD_SENSOR":
		return GameState.technology_unlocked or GameState.unlocked_technologies.has(tech_id)
	return GameState.unlocked_technologies.has(tech_id)

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	if json.data is Dictionary:
		return json.data as Dictionary
	return {}

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
