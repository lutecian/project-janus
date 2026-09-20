extends Control

@onready var funds_label: Label = $ScrollContainer/VBox/funds_label
@onready var facility_map: Control = $ScrollContainer/VBox/facility_map
@onready var facilities_container: VBoxContainer = $ScrollContainer/VBox/facilities_container
@onready var status_label: Label = $ScrollContainer/VBox/status_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

const ROOM_ICONS := {
	"FAC_LAB": "cyan_04",
	"FAC_SHIELD": "cyan_01",
	"FAC_DESK": "cyan_21",
	"FAC_INTEL": "cyan_13",
	"FAC_SCANNER": "cyan_03",
	"FAC_GARRISON": "cyan_02",
}
const PRIZE_ICONS := {
	"FAC_PRIZE_HEL": "gold_08",
	"FAC_PRIZE_BER": "gold_06",
	"FAC_PRIZE_NOR": "gold_05",
	"FAC_PRIZE_VAN": "gold_03",
	"FAC_PRIZE_SOL": "gold_07",
	"FAC_PRIZE_KIT": "gold_04",
}

func _ready():
	btn_back.pressed.connect(_on_back)
	facility_map.room_clicked.connect(_on_buy)
	_refresh()

func _icon_for(fid: String) -> Texture2D:
	var base := fid
	for suffix in ["_3", "_2"]:
		if base.ends_with(suffix):
			base = base.left(base.length() - suffix.length())
			break
	if ROOM_ICONS.has(base):
		return load("res://assets/art/icons/%s.png" % ROOM_ICONS[base]) as Texture2D
	if PRIZE_ICONS.has(fid):
		return load("res://assets/art/icons/%s.png" % PRIZE_ICONS[fid]) as Texture2D
	return null

func _refresh():
	funds_label.text = "Funds: $%d | Security: %d | Military ties: %d" % [
		GameState.budget.get("funds", 0),
		int(GameState.get_security()),
		int(GameState.military_ties)
	]
	var data: Dictionary = GameState._load_json("res://data/facilities/facilities.json")
	facility_map.set_facilities(data.get("facilities", []), GameState.facilities_owned)
	for child in facilities_container.get_children():
		child.queue_free()
	for fdef in data.get("facilities", []):
		var fd: Dictionary = fdef as Dictionary
		var fid: String = fd.get("id", "")
		if bool(fd.get("prize", false)) and not GameState.has_facility(fid):
			continue
		var need: String = fd.get("requires", "")
		var locked: bool = need != "" and not GameState.has_facility(need)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var icon: Texture2D = _icon_for(fid)
		if icon != null:
			var icon_rect := TextureRect.new()
			icon_rect.texture = icon
			icon_rect.custom_minimum_size = Vector2(48, 48)
			icon_rect.expand_mode = 1
			icon_rect.stretch_mode = 5
			row.add_child(icon_rect)
		var line := Label.new()
		var state := "OWNED" if GameState.has_facility(fid) else "$%d" % GameState.facility_price(fid)
		if locked:
			state += " (requires %s)" % need
		line.text = "%s [%s]\n%s\n%s" % [
			fd.get("name", "?"), state, fd.get("flavor", ""), fd.get("effect", "")
		]
		line.add_theme_font_size_override("font_size", 14)
		line.autowrap_mode = 2
		line.size_flags_horizontal = 3
		row.add_child(line)
		facilities_container.add_child(row)
		if not GameState.has_facility(fid):
			var buy_btn := Button.new()
			buy_btn.text = "Build: %s ($%d)" % [fd.get("name", "?"), GameState.facility_price(fid)]
			buy_btn.disabled = locked
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
