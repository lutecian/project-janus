extends Control

@onready var btn_new: Button = $VBox/btn_new_campaign
@onready var btn_load: Button = $VBox/btn_load_campaign
@onready var btn_settings: Button = $VBox/btn_settings
@onready var btn_quit: Button = $VBox/btn_quit
@onready var title_label: Label = $VBox/title_label
@onready var status_label: Label = $VBox/status_label

var _confirm_dialog: ConfirmationDialog

func _ready():
	btn_new.pressed.connect(_on_new_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_load.disabled = not SaveManager.has_save()
	title_label.text = "PROJECT JANUS"
	status_label.text = ""
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
