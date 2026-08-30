extends Control

@onready var title_label: Label = $ScrollContainer/VBox/title_label
@onready var helios_info: Label = $ScrollContainer/VBox/helios_info
@onready var reports_label: RichTextLabel = $ScrollContainer/VBox/reports_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

func _ready():
	btn_back.pressed.connect(_on_back)
	_display_intel()

func _display_intel():
	title_label.text = "HELIOS INTELLIGENCE"
	helios_info.text = "Rival Progress: %d%%\nRival Artifact: %s\nRival Discoveries: %d" % [
		GameState.helios["progress"],
		GameState.helios.get("artifact_name", "Unknown"),
		GameState.helios.get("discoveries_named", []).size()
	]

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
