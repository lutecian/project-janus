extends Control

@onready var title_label: Label = $ScrollContainer/VBox/title_label
@onready var market_bars: Control = $ScrollContainer/VBox/market_bars
@onready var helios_info: Label = $ScrollContainer/VBox/helios_info
@onready var directors_row: HBoxContainer = $ScrollContainer/VBox/directors_row
@onready var reports_label: RichTextLabel = $ScrollContainer/VBox/reports_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

func _ready():
	btn_back.pressed.connect(_on_back)
	_display_intel()

func _display_intel():
	title_label.text = "RIVAL INTELLIGENCE"

	var market_text := "MY MARKET: %.1f%% (target %.1f%%)\n\n" % [
		GameState.get_player_market(), GameState.get_majority_target()
	]
	var ordered: Array = GameState.rivals.duplicate()
	ordered.sort_custom(func(a, b): return float(a.get("share", 0)) > float(b.get("share", 0)))
	var rows: Array = [{"id": "PLAYER", "name": "YOU", "share": GameState.get_player_market()}]
	for r in ordered:
		var rd: Dictionary = r as Dictionary
		rows.append({"id": rd.get("id", "?"), "name": rd.get("name", "?"), "share": float(rd.get("share", 0))})
	market_bars.set_entries(rows)
	for r in ordered:
		var rd: Dictionary = r as Dictionary
		market_text += "%-28s %5.1f%%\n" % [
			rd.get("name", "?"), float(rd.get("share", 0))
		]
	helios_info.text = market_text
	_populate_directors(ordered)

	var reports_text := ""
	var reports: Array = GameState.intelligence_reports
	if reports.is_empty():
		reports_text = "No intelligence reports available yet."
	else:
		for i in range(reports.size() - 1, -1, -1):
			var report: Dictionary = reports[i] as Dictionary
			reports_text += "[Day %d] PROGRESS: %d%%\n%s\n\n" % [
				report.get("day", 0),
				report.get("helios_progress", 0),
				report.get("text", "")
			]
	reports_label.text = reports_text

func _populate_directors(ordered: Array):
	for child in directors_row.get_children():
		child.queue_free()
	for r in ordered:
		var rd: Dictionary = r as Dictionary
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			continue
		var key: String = rd.get("id", "").replace("RIV_", "").to_lower()
		var tex: Texture2D = load("res://assets/art/directors/%s.png" % key) as Texture2D
		if tex == null:
			continue
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		var img := TextureRect.new()
		img.texture = tex
		img.custom_minimum_size = Vector2(96, 120)
		img.expand_mode = 1
		img.stretch_mode = 5
		cell.add_child(img)
		var name := Label.new()
		name.text = rd.get("director", rd.get("name", "?"))
		name.add_theme_font_size_override("font_size", 11)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.autowrap_mode = 2
		name.custom_minimum_size = Vector2(96, 0)
		cell.add_child(name)
		directors_row.add_child(cell)

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
