extends Control

@onready var summary_label: Label = $ScrollContainer/VBox/summary_label
@onready var incidents_label: RichTextLabel = $ScrollContainer/VBox/incidents_label
@onready var crises_container: VBoxContainer = $ScrollContainer/VBox/crises_container
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
		text += "%s\n" % GameState.incident_display_text(inc)
		if not inc.get("reaction", "") == "":
			text += "[color=#7f8fa6]Crew note: %s[/color]\n" % inc.get("reaction", "")
		text += "\n"
	incidents_label.text = text
	_populate_crises()

func _populate_crises():
	for child in crises_container.get_children():
		child.queue_free()
	if GameState.active_crises.is_empty():
		var none := Label.new()
		none.text = "No active crises. The building is (relatively) quiet."
		none.add_theme_font_size_override("font_size", 14)
		crises_container.add_child(none)
		return
	for c in GameState.active_crises:
		var cd: Dictionary = c as Dictionary
		var line := Label.new()
		line.text = "%s — %d days left. Resolve: $%d, or send a response team (someone may not come back whole)." % [
			cd.get("name", "?"), int(ceil(float(cd.get("days_left", 0.0)))),
			int(cd.get("resolve_cost", 0))
		]
		line.add_theme_font_size_override("font_size", 14)
		line.autowrap_mode = 2
		crises_container.add_child(line)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var pay_btn := Button.new()
		pay_btn.text = "Pay $%d" % int(cd.get("resolve_cost", 0))
		pay_btn.pressed.connect(_on_resolve.bind(cd.get("id", ""), "pay"))
		row.add_child(pay_btn)
		var team_btn := Button.new()
		team_btn.text = "Send response team"
		team_btn.pressed.connect(_on_resolve.bind(cd.get("id", ""), "team"))
		row.add_child(team_btn)
		crises_container.add_child(row)

func _on_resolve(crisis_id: String, method: String):
	var res: Dictionary = GameState.resolve_crisis(crisis_id, method)
	if not res.get("ok", false):
		summary_label.text = "Cannot resolve (%s)." % res.get("reason", "?")
	else:
		summary_label.text = res.get("detail", "Resolved.")
	_refresh()

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
