extends Control

# Animated horizontal bar chart: player + rivals market share, no assets.
var entries: Array = []
var _shown: Dictionary = {}

const BAR_COLORS := {
	"PLAYER": Color(0.2, 0.84, 1.0),
	"RIV_HELIOS": Color(1.0, 0.35, 0.3),
	"RIV_BERMANT": Color(0.5, 0.7, 1.0),
	"RIV_NORTHWIND": Color(0.4, 1.0, 0.6),
	"RIV_VANTAGE": Color(1.0, 0.8, 0.2),
	"RIV_SOLENNE": Color(0.7, 0.5, 1.0),
	"RIV_KITEZH": Color(1.0, 0.5, 0.8),
}

func set_entries(rows: Array):
	entries = rows
	for row in entries:
		var rid: String = (row as Dictionary).get("id", "?")
		if not _shown.has(rid):
			_shown[rid] = 0.0
	custom_minimum_size = Vector2(0, entries.size() * 26.0 + 8.0)
	queue_redraw()

func _process(delta):
	var dirty := false
	for row in entries:
		var rid: String = (row as Dictionary).get("id", "?")
		var target: float = float((row as Dictionary).get("share", 0.0))
		var cur: float = float(_shown.get(rid, 0.0))
		if absf(cur - target) > 0.05:
			_shown[rid] = lerpf(cur, target, minf(delta * 2.0, 1.0))
			dirty = true
	if dirty:
		queue_redraw()

func _draw():
	var row_h := 26.0
	var max_share := 5.0
	for row in entries:
		max_share = maxf(max_share, float((row as Dictionary).get("share", 0.0)))
	var y := 4.0
	for row in entries:
		var rd: Dictionary = row as Dictionary
		var rid: String = rd.get("id", "?")
		var val: float = float(_shown.get(rid, 0.0))
		var frac: float = clampf(val / max_share, 0.0, 1.0)
		var w: float = (size.x - 220.0) * frac
		var col: Color = BAR_COLORS.get(rid, Color(0.6, 0.6, 0.6))
		draw_string(ThemeDB.fallback_font, Vector2(0, y + 18), rd.get("name", "?").left(24), HORIZONTAL_ALIGNMENT_LEFT, 200, 14, Color(0.85, 0.87, 0.9))
		draw_rect(Rect2(210, y, size.x - 220.0, 20), Color(1, 1, 1, 0.08))
		draw_rect(Rect2(210, y, maxf(w, 2.0), 20), col)
		draw_rect(Rect2(210, y, maxf(w, 2.0), 6), Color(1, 1, 1, 0.25))
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 60.0, y + 18), "%.1f" % val, HORIZONTAL_ALIGNMENT_LEFT, 60, 14, Color.WHITE)
		y += row_h
