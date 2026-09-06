extends Control

@onready var btn_new: Button = $Card/VBox/btn_new_campaign
@onready var btn_load: Button = $Card/VBox/btn_load_campaign
@onready var btn_settings: Button = $Card/VBox/btn_settings
@onready var btn_quit: Button = $Card/VBox/btn_quit
@onready var btn_daily: Button = $Card/VBox/btn_daily
@onready var btn_weekly: Button = $Card/VBox/btn_weekly
@onready var btn_slot_prev: Button = $Card/VBox/slot_row/btn_slot_prev
@onready var btn_slot_next: Button = $Card/VBox/slot_row/btn_slot_next
@onready var slot_label: Label = $Card/VBox/slot_row/slot_label
@onready var title_label: Label = $Card/VBox/title_label
@onready var status_label: Label = $Card/VBox/status_label
@onready var legacy_label: Label = $Card/VBox/legacy_label

var _confirm_dialog: ConfirmationDialog
var _pending_daily := false
var _pending_weekly := false

func _ready():
	btn_new.pressed.connect(_on_new_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_daily.pressed.connect(_on_daily_pressed)
	btn_weekly.pressed.connect(_on_weekly_pressed)
	btn_slot_prev.pressed.connect(_on_slot_step.bind(-1))
	btn_slot_next.pressed.connect(_on_slot_step.bind(1))
	_update_slot_ui()
	title_label.text = "PROJECT JANUS " + GameState.GAME_VERSION
	status_label.text = ""
	legacy_label.text = GameState.get_legacy_line()
	AudioManager.start_music("menu")
	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.title = "Start New Campaign"
	_confirm_dialog.dialog_text = "Starting a new campaign will overwrite your current save. Continue?"
	_confirm_dialog.confirmed.connect(_on_new_confirmed)
	add_child(_confirm_dialog)

func _on_new_pressed():
	if SaveManager.has_save():
		_confirm_dialog.popup_centered(Vector2i(400, 150))
	else:
		get_tree().change_scene_to_file("res://scenes/campaign/campaign_creation.tscn")

func _on_new_confirmed():
	SaveManager.delete_save()
	if _pending_weekly:
		_pending_weekly = false
		_start_challenge("Weekly Task Force", "WTF", GameState.weekly_seed(), true)
		return
	if _pending_daily:
		_pending_daily = false
		_start_daily()
		return
	get_tree().change_scene_to_file("res://scenes/campaign/campaign_creation.tscn")

func _on_load_pressed():
	if SaveManager.load_game():
		get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
	else:
		status_label.text = "Failed to load save file."

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/settings/settings.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_slot_step(direction: int):
	SaveManager.set_slot(SaveManager.current_slot + direction)
	_update_slot_ui()

func _update_slot_ui():
	var used := ""
	if not SaveManager.has_save():
		used = " (empty)"
	slot_label.text = "Save Slot %d%s" % [SaveManager.current_slot, used]
	btn_load.disabled = not SaveManager.has_save()

func _on_daily_pressed():
	if SaveManager.has_save():
		_pending_daily = true
		_confirm_dialog.popup_centered(Vector2i(400, 150))
		return
	_start_daily()

func _start_daily():
	_start_challenge("Daily Task Force", "DTF", GameState.daily_seed(), false)

func _on_weekly_pressed():
	if SaveManager.has_save():
		_pending_weekly = true
		_confirm_dialog.popup_centered(Vector2i(400, 150))
		return
	_start_challenge("Weekly Task Force", "WTF", GameState.weekly_seed(), true)

func _start_challenge(org_name: String, abbr: String, seed: int, weekly: bool):
	var org := {
		"name": org_name,
		"abbreviation": abbr,
		"facility_name": "Hawthorne Research Complex",
		"director_name": "Director B. Crozier"
	}
	GameState.initialize_new_campaign(org, "normal", seed)
	if weekly:
		GameState.start_weekly_challenge()
	else:
		GameState.start_daily_challenge()
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")

