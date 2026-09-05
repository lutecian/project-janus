extends Control

@onready var title_label: Label = $ScrollContainer/VBox/title_label
@onready var portrait_rect: ColorRect = $ScrollContainer/VBox/portrait_rect
@onready var desc_label: RichTextLabel = $ScrollContainer/VBox/desc_label

const PORTRAIT_STYLE := {
	"J001": {"a": Color(0.2, 0.84, 1.0), "b": Color(0.02, 0.05, 0.1), "pattern": 0.0, "scale": 3.0, "speed": 0.35},
	"J002": {"a": Color(1.0, 0.55, 0.2), "b": Color(0.1, 0.03, 0.01), "pattern": 0.0, "scale": 4.0, "speed": 0.25},
	"J003": {"a": Color(0.4, 1.0, 0.6), "b": Color(0.01, 0.08, 0.03), "pattern": 0.0, "scale": 2.5, "speed": 0.2},
	"J004": {"a": Color(1.0, 0.8, 0.25), "b": Color(0.1, 0.06, 0.01), "pattern": 2.0, "scale": 3.0, "speed": 0.5},
	"J005": {"a": Color(0.6, 0.9, 1.0), "b": Color(0.02, 0.06, 0.12), "pattern": 1.0, "scale": 3.5, "speed": 0.3},
	"J006": {"a": Color(0.7, 0.4, 1.0), "b": Color(0.0, 0.0, 0.0), "pattern": 2.0, "scale": 4.0, "speed": 0.4}
}
@onready var known_label: Label = $ScrollContainer/VBox/known_label
@onready var knowledge_state: Label = $ScrollContainer/VBox/knowledge_state
@onready var discoveries_label: RichTextLabel = $ScrollContainer/VBox/discoveries_label
@onready var observations_label: RichTextLabel = $ScrollContainer/VBox/observations_label
@onready var story_label: RichTextLabel = $ScrollContainer/VBox/story_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

func _ready():
	btn_back.pressed.connect(_on_back)
	_apply_portrait()
	_display_artifact()

func _apply_portrait():
	var style: Dictionary = PORTRAIT_STYLE.get(GameState.artifact.get("id", "J001"), PORTRAIT_STYLE["J001"])
	var shader := load("res://assets/shaders/artifact_portrait.gdshader") as Shader
	if shader == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("color_a", style.get("a", Color.CYAN))
	mat.set_shader_parameter("color_b", style.get("b", Color.BLACK))
	mat.set_shader_parameter("pattern", float(style.get("pattern", 0.0)))
	mat.set_shader_parameter("scale_uv", float(style.get("scale", 3.0)))
	mat.set_shader_parameter("speed", float(style.get("speed", 0.35)))
	portrait_rect.material = mat

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

	var disc_text := ""
	var discoveries: Array = GameState.discoveries
	for d in discoveries:
		var d_dict: Dictionary = d as Dictionary
		var dname: String = d_dict.get("player_name", "")
		var dstate: String = d_dict.get("state", "unknown")
		var display: String = dname
		if display.is_empty():
			display = d_dict.get("internal_name", "??")
		var status_tag := ""
		if dstate == "confirmed":
			status_tag = "CONFIRMED"
		elif dstate == "suspected":
			status_tag = "SUSPECTED"
		else:
			status_tag = "UNCONFIRMED"
		disc_text += "%s [%s]\n" % [display, status_tag]
	if disc_text.is_empty():
		disc_text = "No phenomena identified yet."
	discoveries_label.text = disc_text

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

	var story_text := ""
	var art_id: String = GameState.artifact.get("id", "")
	for entry in GameState.story_log:
		var en: Dictionary = entry as Dictionary
		var eid: String = en.get("artifact_id", "")
		if eid != "" and eid != art_id:
			continue
		story_text += "--- DAY %d: %s ---\n%s\n\n" % [
			en.get("day", 0), en.get("title", "?"), en.get("text", "")
		]
	if story_text.is_empty():
		story_text = "No field entries yet. The story starts with the first experiment."
	story_label.text = story_text

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
