extends Control

@onready var result_label: Label = $ScrollContainer/VBox/result_label
@onready var subtitle_label: Label = $ScrollContainer/VBox/subtitle_label
@onready var summary_label: RichTextLabel = $ScrollContainer/VBox/summary_label
@onready var btn_menu: Button = $ScrollContainer/VBox/ButtonRow/btn_menu
@onready var btn_continue: Button = $ScrollContainer/VBox/ButtonRow/btn_continue

func _ready():
	btn_menu.pressed.connect(_on_menu)
	btn_continue.pressed.connect(_on_continue)
	AudioManager.stop_music()
	_display()
	var res2: Dictionary = GameState.get_game_over()
	if res2.get("won", false):
		AudioManager.play_sfx("victory")
	else:
		AudioManager.play_sfx("defeat")
	var result: Dictionary = GameState.get_game_over()
	btn_continue.visible = bool(result.get("won", false)) and result.get("type", "") != "monopoly"

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

	if won and reason == "domination":
		result_label.text = "DOMINATION"
		result_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		subtitle_label.text = "The Monopoly — every rival acquired, bankrupt, exited, or outgrown."
		summary_label.text = "You hold %.1f%% of the market on day %d with %d confirmed discoveries.\n\nNo rival remains standing: each was bought out, collapsed, or left so far behind it no longer matters.\n\nThe field is yours." % [
			player_market, days_used, discoveries_confirmed
		]
	elif won and reason == "scientific":
		result_label.text = "DISTINGUISHED RESEARCHER"
		result_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
		subtitle_label.text = "You published the complete breakthrough."
		summary_label.text = "Full discovery set confirmed on day %d with %d confirmed discoveries and complete tech depth.\n\nThe field cites your work; %s can only follow where you led." % [
			days_used, discoveries_confirmed, dominant
		]
	elif won:
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
	summary_label.text += "\n\nTitle earned: %s\n%s" % [GameState.get_run_title(), _epilogue_text(won, reason)]

func _epilogue_text(won: bool, reason: String) -> String:
	var days_used: int = int(GameState.elapsed_days)
	if won and reason == "domination":
		if days_used < 40:
			return "Epilogue: Overnight Monopoly — the field still talks about how fast you swallowed it whole."
		return "Epilogue: Corporatist Monopoly — patient capital and patient science, and now there is only you."
	if won and reason == "scientific":
		return "Epilogue: Philanthropist Legacy — your published breakthroughs teach a generation."
	if won:
		return "Epilogue: Market Leader — the brand outlives the breakthroughs."
	if reason == "staff_wipe":
		return "Epilogue: Empty Lab — no living researcher remains to carry the work. The artifacts wait in the dark for whoever comes next."
	if GameState.discovery.get("state", "") == "confirmed":
		return "Epilogue: Scientific Martyr — you lost the market but published openly; the science survives you."
	if GameState.get_player_market() >= GameState.get_majority_target() * 0.7:
		return "Epilogue: So Close — a few more workdays might have changed everything."
	return "Epilogue: Absorbed — your labs now answer to someone else."

func _on_menu():
	SaveManager.delete_save()
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _on_continue():
	var res: Dictionary = GameState.continue_after_win()
	if res.get("ok", false):
		SaveManager.save_game()
		get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
