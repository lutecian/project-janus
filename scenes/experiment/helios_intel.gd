extends Control

@onready var title_label: Label = $ScrollContainer/VBox/title_label
@onready var helios_info: Label = $ScrollContainer/VBox/helios_info
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
	for r in ordered:
		var rd: Dictionary = r as Dictionary
		market_text += "%-28s %5.1f%%\n" % [
			rd.get("name", "?"), float(rd.get("share", 0))
		]
	helios_info.text = market_text

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

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
