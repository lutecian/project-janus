extends Control

@onready var org_name_edit: LineEdit = $VBox/org_name_edit
@onready var org_abbr_edit: LineEdit = $VBox/org_abbr_edit
@onready var facility_edit: LineEdit = $VBox/facility_edit
@onready var director_edit: LineEdit = $VBox/director_edit
@onready var btn_begin: Button = $VBox/ButtonRow/btn_begin
@onready var btn_back: Button = $VBox/ButtonRow/btn_back
@onready var status_label: Label = $VBox/status_label

func _ready():
	btn_begin.pressed.connect(_on_begin_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	org_name_edit.text = "AEGIS Advanced Research Directorate"
	org_abbr_edit.text = "AARD"
	facility_edit.text = "Hawthorne Research Complex"
	director_edit.text = "Director B. Crozier"
	status_label.text = ""

func _on_begin_pressed():
	var org_name := org_name_edit.text.strip_edges()
	var org_abbr := org_abbr_edit.text.strip_edges()
	var fac_name := facility_edit.text.strip_edges()
	var dir_name := director_edit.text.strip_edges()

	if org_name.is_empty() or org_abbr.is_empty():
		status_label.text = "Organization name and abbreviation are required."
		return

	var org := {
		"name": org_name,
		"abbreviation": org_abbr,
		"facility_name": fac_name,
		"director_name": dir_name
	}

	GameState.initialize_new_campaign(org)
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/experiment/experiment_selection.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
