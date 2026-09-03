extends Control

@onready var funds_label: Label = $ScrollContainer/VBox/funds_label
@onready var facilities_container: VBoxContainer = $ScrollContainer/VBox/facilities_container
@onready var status_label: Label = $ScrollContainer/VBox/status_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

func _ready():
	btn_back.pressed.connect(_on_back)
	_refresh()

func _refresh():
	funds_label.text = "Funds: $%d | Security: %d | Military ties: %d" % [
		GameState.budget.get("funds", 0),
		int(GameState.get_security()),
		int(GameState.military_ties)
	]
	for child in facilities_container.get_children():
		child.queue_free()
	var data: Dictionary = GameState._load_json("res://data/facilities/facilities.json")
	for fdef in data.get("facilities", []):
		var fd: Dictionary = fdef as Dictionary
		var fid: String = fd.get("id", "")
		if bool(fd.get("prize", false)) and not GameState.has_facility(fid):
			continue
		var line := Label.new()
		var state := "OWNED" if GameState.has_facility(fid) else "$%d" % GameState.facility_price(fid)
		line.text = "%s [%s]\n%s\n%s" % [
			fd.get("name", "?"), state, fd.get("flavor", ""), fd.get("effect", "")
		]
		line.add_theme_font_size_override("font_size", 14)
		line.autowrap_mode = 2
		facilities_container.add_child(line)
		if not GameState.has_facility(fid):
			var buy_btn := Button.new()
			buy_btn.text = "Build: %s ($%d)" % [fd.get("name", "?"), GameState.facility_price(fid)]
			buy_btn.pressed.connect(_on_buy.bind(fid))
			facilities_container.add_child(buy_btn)

func _on_buy(facility_id: String):
	var res: Dictionary = GameState.buy_facility(facility_id)
	if res.get("ok", false):
		status_label.text = "Facility built for $%d." % int(res.get("cost", 0))
	else:
		status_label.text = "Cannot build (%s)." % res.get("reason", "?")
	_refresh()

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
