extends Control

@onready var meters_label: Label = $ScrollContainer/VBox/meters_label
@onready var funds_label: Label = $ScrollContainer/VBox/funds_label
@onready var target_option: OptionButton = $ScrollContainer/VBox/target_option
@onready var ops_container: VBoxContainer = $ScrollContainer/VBox/ops_container
@onready var status_label: Label = $ScrollContainer/VBox/status_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

var _target_ids: Array = [""]

func _ready():
	btn_back.pressed.connect(_on_back)
	EventBus.game_over.connect(_on_game_over)
	_populate_targets()
	_refresh()

func _populate_targets():
	target_option.clear()
	_target_ids = [""]
	target_option.add_item("No specific target", 0)
	var idx := 1
	for o in GameState.company_offers:
		var od: Dictionary = o as Dictionary
		if od.get("status", "") != "offered":
			continue
		target_option.add_item("LAB: " + od.get("name", "?"), idx)
		_target_ids.append(od.get("id", ""))
		idx += 1
	for r in GameState.rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			continue
		target_option.add_item("RIVAL: " + rd.get("name", "?"), idx)
		_target_ids.append(rd.get("id", ""))
		idx += 1

func _refresh():
	meters_label.text = "HEAT (risk): %.0f / 100 — caught at 70+  |  COVER: %.0f / 50\nHeat cools 2/day if you lie low." % [
		GameState.esp_risk, GameState.esp_cover
	]
	funds_label.text = "Funds: $%d" % GameState.budget.get("funds", 0)
	for child in ops_container.get_children():
		child.queue_free()
	var data: Dictionary = GameState._load_json("res://data/espionage/espionage_ops.json")
	for odef in data.get("ops", []):
		var od: Dictionary = odef as Dictionary
		var line := Label.new()
		line.text = "%s — $%d, +%d heat, needs: %s\n%s" % [
			od.get("name", "?"),
			int(round(float(od.get("cost", 0)) * GameState._espionage_cost_mult())),
			int(od.get("risk_add", 0)),
			od.get("target", "?"),
			od.get("flavor", "")
		]
		line.add_theme_font_size_override("font_size", 14)
		line.autowrap_mode = 2
		ops_container.add_child(line)
		var run_btn := Button.new()
		run_btn.text = "Run: %s" % od.get("name", "?")
		run_btn.pressed.connect(_on_run_op.bind(od.get("id", "")))
		ops_container.add_child(run_btn)

func _selected_target() -> String:
	var idx: int = target_option.selected
	if idx < 0 or idx >= _target_ids.size():
		return ""
	return _target_ids[idx]

func _on_run_op(op_id: String):
	var res: Dictionary = GameState.perform_espionage_op(op_id, _selected_target())
	if not res.get("ok", false):
		status_label.text = "Op refused (%s)." % res.get("reason", "?")
	else:
		var mark := "SUCCESS"
		if not res.get("success", false):
			mark = "FAILED"
		status_label.text = "%s — %s" % [mark, res.get("detail", "")]
	_populate_targets()
	_refresh()
	if GameState.is_game_over():
		get_tree().change_scene_to_file("res://scenes/endgame/game_over.tscn")

func _on_game_over(_result: Dictionary):
	get_tree().change_scene_to_file("res://scenes/endgame/game_over.tscn")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
