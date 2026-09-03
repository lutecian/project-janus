extends Control

@onready var result_label: Label = $ScrollContainer/VBox/result_label
@onready var subtitle_label: Label = $ScrollContainer/VBox/subtitle_label
@onready var summary_label: RichTextLabel = $ScrollContainer/VBox/summary_label
@onready var btn_menu: Button = $ScrollContainer/VBox/ButtonRow/btn_menu

func _ready():
	btn_menu.pressed.connect(_on_menu)
	_display()

func _display():
	var result: Dictionary = GameState.get_game_over()
	var won: bool = result.get("won", false)
	var reason: String = result.get("reason", "")
	var player_market: float = result.get("player_market", 0.0)
	var dominant: String = result.get("dominant_rival", "Unknown")
	var majority: float = GameState.get_majority_target()

	var days_used: int = int(GameState.elapsed_days)
	var discoveries_confirmed: int = GameState.confirmed_discoveries.size()
	for d in GameState.discoveries:
		if (d as Dictionary).get("state", "") == "confirmed":
			discoveries_confirmed += 1

	if won:
		result_label.text = "VICTORY"
		result_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
		subtitle_label.text = "Your organization achieved market majority."
		summary_label.text = "You reached %.1f%% of the market (target: %.1f%%) on day %d.\n\n%d confirmed discoveries. Your research reshaped the field.\n\n%s now trails behind your lead." % [
			player_market, majority, days_used, discoveries_confirmed, dominant
		]
	else:
		result_label.text = "DEFEAT"
		result_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
		subtitle_label.text = "%s reached market majority before you." % dominant
		summary_label.text = "%s captured %s%% of the market while you held only %.1f%%.\n\nYou reached %d days with %d confirmed discoveries — but it was not enough." % [
			dominant, majority, player_market, days_used, discoveries_confirmed
		]

func _on_menu():
	SaveManager.delete_save()
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
