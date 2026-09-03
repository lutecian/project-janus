extends Control

@onready var org_name_edit: LineEdit = $VBox/org_name_edit
@onready var org_abbr_edit: LineEdit = $VBox/org_abbr_edit
@onready var facility_edit: LineEdit = $VBox/facility_edit
@onready var director_edit: LineEdit = $VBox/director_edit
@onready var difficulty_option: OptionButton = $VBox/difficulty_option
@onready var scenario_option: OptionButton = $VBox/scenario_option
@onready var scenario_hint: Label = $VBox/scenario_hint

var _scenario_ids: Array = ["SCN_SANDBOX"]
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
	var order := ["easy", "normal", "hard", "expert"]
	for did in order:
		difficulty_option.add_item(GameState.DIFFICULTIES[did].get("display_name", did), order.find(did))
	difficulty_option.selected = order.find("normal")
	_scenario_ids = ["SCN_SANDBOX"]
	var scn_data: Dictionary = GameState._load_json("res://data/scenarios/scenarios.json")
	for sdef in scn_data.get("scenarios", []):
		var sid: String = (sdef as Dictionary).get("id", "")
		if sid != "" and not _scenario_ids.has(sid):
			_scenario_ids.append(sid)
	for i in range(_scenario_ids.size()):
		var sname: String = _scenario_ids[i]
		var sdef2: Dictionary = GameState._scenario_def(_scenario_ids[i])
		if not sdef2.is_empty():
			sname = sdef2.get("name", _scenario_ids[i])
		scenario_option.add_item(sname, i)
	scenario_option.selected = 0
	scenario_option.item_selected.connect(_on_scenario_selected)
	_update_scenario_hint()

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
	var difficulty_ids := ["easy", "normal", "hard", "expert"]
	var selected_id: String = difficulty_ids[difficulty_option.selected]
	var scenario_id: String = _scenario_ids[scenario_option.selected]
	var scn: Dictionary = GameState._scenario_def(scenario_id)
	var seed := -1
	if not scn.is_empty() and int(scn.get("seed", -1)) >= 0:
		seed = int(scn.get("seed", -1))
	if not scn.is_empty() and scn.get("difficulty", "") != "":
		selected_id = scn.get("difficulty", selected_id)

	GameState.initialize_new_campaign(org, selected_id, seed)
	GameState.apply_scenario(scenario_id)
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")

func _on_scenario_selected(_idx: int):
	_update_scenario_hint()

func _update_scenario_hint():
	var scenario_id: String = _scenario_ids[scenario_option.selected]
	var scn: Dictionary = GameState._scenario_def(scenario_id)
	if scn.is_empty():
		scenario_hint.text = "Sandbox: your rules."
	else:
		scenario_hint.text = scn.get("flavor", "")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
