extends Control

# Visual lab floorplan: rooms light up as facilities are built.
# Prize rooms show as CLASSIFIED until earned. Click a room to buy it.
signal room_clicked(facility_id: String)

const COLS := 4
const CELL := Vector2(190, 120)
const PAD := Vector2(10, 10)

const ROOM_COLORS := {
	"FAC_LAB": Color(0.2, 0.84, 1.0),
	"FAC_SHIELD": Color(0.4, 0.6, 1.0),
	"FAC_DESK": Color(0.4, 1.0, 0.6),
	"FAC_INTEL": Color(0.7, 0.5, 1.0),
	"FAC_SCANNER": Color(0.3, 0.9, 0.9),
	"FAC_GARRISON": Color(1.0, 0.6, 0.2),
	"FAC_LAB_2": Color(0.4, 0.95, 1.0),
	"FAC_SHIELD_2": Color(0.6, 0.75, 1.0),
	"FAC_DESK_2": Color(0.6, 1.0, 0.75),
	"FAC_INTEL_2": Color(0.85, 0.65, 1.0),
	"FAC_SCANNER_2": Color(0.5, 1.0, 1.0),
	"FAC_GARRISON_2": Color(1.0, 0.75, 0.35),
}

var _defs: Array = []
var _owned: Array = []
var _rects: Dictionary = {}
var _pulse := 0.0

func set_facilities(defs: Array, owned: Array):
	_defs = defs
	_owned = owned
	_layout()
	queue_redraw()

func _layout():
	_rects.clear()
	for i in range(_defs.size()):
		var col: int = i % COLS
		var row: int = i / COLS
		var pos := Vector2(PAD.x + col * (CELL.x + PAD.x), PAD.y + row * (CELL.y + PAD.y))
		_rects[(_defs[i] as Dictionary).get("id", "")] = Rect2(pos, CELL)
	var rows: int = (_defs.size() + COLS - 1) / COLS
	custom_minimum_size = Vector2(COLS * (CELL.x + PAD.x) + PAD.x, rows * (CELL.y + PAD.y) + PAD.y)

func room_for(facility_id: String) -> Rect2:
	return _rects.get(facility_id, Rect2())

func _process(delta):
	_pulse += delta
	queue_redraw()

func _room_state(fid: String, is_prize: bool) -> String:
	if fid in _owned:
		return "owned"
	if is_prize:
		return "classified"
	return "available"

func _draw():
	var font: Font = ThemeDB.fallback_font
	# Corridors first (behind rooms).
	var centers: Array = []
	for fid in _rects:
		centers.append(_rects[fid].get_center())
	for i in range(1, centers.size()):
		draw_line(centers[i - 1], centers[i], Color(1, 1, 1, 0.07), 6.0)
	var glow: float = 0.5 + 0.5 * sin(_pulse * 2.0)
	for i in range(_defs.size()):
		var fd: Dictionary = _defs[i]
		var fid: String = fd.get("id", "")
		var rect: Rect2 = _rects.get(fid, Rect2())
		var is_prize: bool = bool(fd.get("prize", false))
		var state: String = _room_state(fid, is_prize)
		var base: Color = ROOM_COLORS.get(fid, Color(1.0, 0.8, 0.2))
		if state == "owned":
			draw_rect(rect, Color(base.r * 0.16, base.g * 0.16, base.b * 0.16, 1.0))
			draw_rect(rect, base, false, 2.0)
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), base)
		elif state == "classified":
			draw_rect(rect, Color(0.02, 0.02, 0.03, 1.0))
			draw_rect(rect, Color(0.4, 0.1, 0.1, 0.6 + 0.4 * glow), false, 2.0)
		else:
			draw_rect(rect, Color(0.05, 0.07, 0.1, 1.0))
			draw_rect(rect, Color(base.r, base.g, base.b, 0.35), false, 1.0)
		var label := ""
		var sub := ""
		if state == "owned":
			label = fd.get("name", "?")
			sub = "ONLINE"
		elif state == "classified":
			label = "???"
			sub = "CLASSIFIED"
		else:
			label = fd.get("name", "?")
			sub = "$%d" % GameState.facility_price(fid)
		draw_string(font, rect.position + Vector2(8, 26), label.left(22), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16, 14, Color(0.9, 0.92, 0.95))
		var subcol := Color(0.5, 1, 0.6) if state == "owned" else Color(0.55, 0.6, 0.65)
		if state == "classified":
			subcol = Color(1.0, 0.4 + 0.3 * glow, 0.4)
		draw_string(font, rect.position + Vector2(8, 46), sub, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16, 12, subcol)
		var glyph := "▣"
		if is_prize:
			glyph = "⬣"
		elif state == "available":
			glyph = "▢"
		draw_string(font, rect.position + Vector2(8, rect.size.y - 12), glyph, HORIZONTAL_ALIGNMENT_LEFT, 40, 28, Color(base.r, base.g, base.b, 0.8))

func _gui_input(event):
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			for fid in _rects:
				if (_rects[fid] as Rect2).has_point(mb.position):
					room_clicked.emit(fid)
					accept_event()
					return
