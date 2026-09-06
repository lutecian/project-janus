extends Control

@onready var funds_label: Label = $ScrollContainer/VBox/funds_label
@onready var roster_container: VBoxContainer = $ScrollContainer/VBox/roster_container
@onready var btn_rest: Button = $ScrollContainer/VBox/rest_row/btn_rest
@onready var memorial_label: RichTextLabel = $ScrollContainer/VBox/memorial_label
@onready var status_label: Label = $ScrollContainer/VBox/status_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

func _ready():
	btn_rest.pressed.connect(_on_rest)
	btn_back.pressed.connect(_on_back)
	_refresh()

func _refresh():
	funds_label.text = "Funds: $%d" % GameState.budget.get("funds", 0)
	for child in roster_container.get_children():
		child.queue_free()
	for s in GameState.scientists:
		var sd: Dictionary = s as Dictionary
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var line := Label.new()
		line.text = "%s %s — %s | HP %d | Stress %d" % [
			sd.get("first_name", "?"), sd.get("last_name", "?"),
			sd.get("status", "ACTIVE"),
			int(sd.get("health", 100)), int(sd.get("stress", 0))
		]
		line.add_theme_font_size_override("font_size", 14)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(line)
		if sd.get("status", "ACTIVE") == "INJURED":
			var treat_btn := Button.new()
			treat_btn.text = "Treat ($1500)"
			treat_btn.pressed.connect(_on_treat.bind(sd.get("id", "")))
			row.add_child(treat_btn)
		roster_container.add_child(row)
	var wall := ""
	for entry in GameState.get_memorial():
		var en: Dictionary = entry as Dictionary
		wall += "--- %s (day %d) ---\n%s\n\n" % [en.get("name", "?"), en.get("day", 0), en.get("text", "")]
	if wall.is_empty():
		wall = "No names on the wall. Keep it that way."
	memorial_label.text = wall.strip_edges()

func _on_treat(sci_id: String):
	var res: Dictionary = GameState.treat_scientist(sci_id)
	if res.get("ok", false):
		status_label.text = "Treated and returned to light duty."
	else:
		status_label.text = "Cannot treat (%s)." % res.get("reason", "?")
	_refresh()

func _on_rest():
	var res: Dictionary = GameState.order_rest()
	if res.get("ok", false):
		status_label.text = "Full rest ordered. Stress -20 across the roster."
	else:
		status_label.text = "Cannot rest (%s)." % res.get("reason", "?")
	_refresh()

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
