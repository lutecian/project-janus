extends Control

@onready var title_label: Label = $ScrollContainer/VBox/title_label
@onready var summary_label: RichTextLabel = $ScrollContainer/VBox/summary_label
@onready var btn_main_menu: Button = $ScrollContainer/VBox/ButtonRow/btn_main_menu
@onready var btn_continue: Button = $ScrollContainer/VBox/ButtonRow/btn_continue

func _ready():
	btn_main_menu.pressed.connect(_on_menu)
	btn_continue.pressed.connect(_on_continue)
	_display_breakthrough()

func _display_breakthrough():
	title_label.text = "BREAKTHROUGH CONFIRMED"

	var dname: String = GameState.discovery.get("player_name", "")
	if dname.is_empty():
		dname = "Unnamed Discovery"

	var total_experiments: int = GameState.experiment_history.size()
	var scientists_used: PackedStringArray = []
	for record in GameState.experiment_history:
		var rec: Dictionary = record as Dictionary
		var sname: String = rec.get("scientist_name", "")
		if sname != "" and sname not in scientists_used:
			scientists_used.append(sname)

	var helios_discovered: bool = GameState.helios.get("discovered_first", false)
	var player_won: bool = not helios_discovered or GameState.helios["progress"] < 100

	var win_text := ""
	if player_won:
		win_text = "YOUR ORGANIZATION DISCOVERED THE PHENOMENON FIRST."
	else:
		win_text = "HELIOS discovered a similar phenomenon first, but your independent confirmation validates the finding."

	summary_label.text = """%s

DISCOVERY: %s
EXPERIMENTS PERFORMED: %d
TIME ELAPSED: %d days
SCIENTISTS INVOLVED: %s
TECHNOLOGY UNLOCKED: Experimental Field Sensor (+20%% observation quality)

%s

The phenomenon has been confirmed and named. Your organization's understanding of anomalous physics has advanced significantly. Further research may reveal additional properties of OBJECT J-001.""" % [
		win_text,
		dname,
		total_experiments,
		GameState.elapsed_days,
		", ".join(scientists_used) if scientists_used.size() > 0 else "None",
		"HELIOS is now aware of your organization's capabilities." if not player_won else "HELIOS has not yet confirmed this phenomenon."
	]

func _on_menu():
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _on_continue():
	get_tree().change_scene_to_file("res://scenes/experiment/experiment_selection.tscn")
