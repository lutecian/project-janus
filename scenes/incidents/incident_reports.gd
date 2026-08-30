extends Control

@onready var summary_label: Label = $ScrollContainer/VBox/summary_label
@onready var incidents_label: RichTextLabel = $ScrollContainer/VBox/incidents_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

const SEVERITY_COLORS := {
	"minor": Color(1.0, 0.8, 0.3),
	"moderate": Color(1.0, 0.55, 0.2),
	"severe": Color(1.0, 0.3, 0.3),
	"critical": Color(1.0, 0.1, 0.1)
}

func _ready():
	btn_back.pressed.connect(_on_back)
	_refresh()

func _refresh():
	var incidents: Array = GameState.incidents
	summary_label.text = "%d incidents on record" % incidents.size()

	if incidents.is_empty():
		incidents_label.text = "No incidents have occurred. Facilities are operating normally."
		return

	var text := ""
	for incident in incidents:
		var inc: Dictionary = incident as Dictionary
		var severity: String = inc.get("severity", "minor")
		var color: Color = SEVERITY_COLORS.get(severity, Color.WHITE)
		var sev_html: String = "[color=#%s]%s[/color]" % [color.to_html(false), severity.capitalize()]
		text += "--- DAY %d: %s (%s) ---\n" % [
			inc.get("day", 0),
			inc.get("name", "Unknown Incident"),
			sev_html
		]
		if inc.get("mitigated", false):
			text += "[color=#7f8fa6](severity reduced by Field Stabilizer)[/color]\n"
		text += "%s\n\n" % inc.get("description", "")
	incidents_label.text = text

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
