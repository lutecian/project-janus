extends Control

@onready var funds_label: Label = $ScrollContainer/VBox/funds_label
@onready var offers_container: VBoxContainer = $ScrollContainer/VBox/offers_container
@onready var rivals_container: VBoxContainer = $ScrollContainer/VBox/rivals_container
@onready var dom_label: Label = $ScrollContainer/VBox/dom_label
@onready var owned_label: Label = $ScrollContainer/VBox/owned_label
@onready var status_label: Label = $ScrollContainer/VBox/status_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

func _ready():
	btn_back.pressed.connect(_on_back)
	EventBus.game_over.connect(_on_game_over)
	_refresh()

func _refresh():
	funds_label.text = "Funds: $%d | My Market: %.1f%% (target %.1f%%)" % [
		GameState.budget.get("funds", 0),
		GameState.get_player_market(),
		GameState.get_majority_target()
	]
	_populate_offers()
	_populate_rivals()
	_populate_owned()
	_update_domination()

func _clear(container: VBoxContainer):
	for child in container.get_children():
		child.queue_free()

func _populate_offers():
	_clear(offers_container)
	if GameState.company_offers.is_empty():
		var none := Label.new()
		none.text = "No companies on the market."
		none.add_theme_font_size_override("font_size", 14)
		offers_container.add_child(none)
		return
	for o in GameState.company_offers:
		var od: Dictionary = o as Dictionary
		var oid: String = od.get("id", "")
		var days_left: float = float(od.get("expires_day", 0.0)) - GameState.elapsed_days
		var line := Label.new()
		var techs: Array = od.get("techs", [])
		var dd_text := "no diligence yet"
		if int(od.get("dd_level", 0)) > 0:
			dd_text = "est. value $%d ±%d%%" % [
				round(float(od.get("dd_estimate", 0.0))),
				round(float(od.get("dd_error", 0.0)) * 100.0)
			]
		line.text = "%s — asking $%d (%d tech, %s) — %s" % [
			od.get("name", "?"),
			int(od.get("listed_price", 0)),
			techs.size(),
			dd_text,
			_offers_status_text(od, days_left)
		]
		line.add_theme_font_size_override("font_size", 14)
		line.autowrap_mode = 2
		offers_container.add_child(line)
		if od.get("status", "") == "offered":
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var dd_btn := Button.new()
			dd_btn.text = _dd_button_text(int(od.get("dd_level", 0)))
			dd_btn.pressed.connect(_on_dd.bind(oid))
			row.add_child(dd_btn)
			var buy_btn := Button.new()
			buy_btn.text = "Acquire ($%d)" % int(od.get("listed_price", 0))
			buy_btn.pressed.connect(_on_acquire.bind(oid))
			row.add_child(buy_btn)
			offers_container.add_child(row)

func _offers_status_text(od: Dictionary, days_left: float) -> String:
	var status: String = od.get("status", "offered")
	if status == "grabbed":
		return "lost to a rival"
	if status == "expired":
		return "offer expired"
	if days_left <= 0.0:
		return "expiring now"
	return "expires in %d days" % int(ceil(days_left))

func _dd_button_text(level: int) -> String:
	if level <= 0:
		return "Due Diligence ($%d)" % GameState.ACQ_DD_COSTS[0]
	if level == 1:
		return "Deep Dive ($%d)" % GameState.ACQ_DD_COSTS[1]
	return "Diligence MAX"

func _populate_rivals():
	_clear(rivals_container)
	for r in GameState.rivals:
		var rd: Dictionary = r as Dictionary
		var rid: String = rd.get("id", "")
		var line := Label.new()
		line.text = _rival_line(rd)
		line.add_theme_font_size_override("font_size", 14)
		line.autowrap_mode = 2
		rivals_container.add_child(line)
		if rd.get("status", "active") == "active" and not rd.get("acquired_by_player", false):
			var buy_btn := Button.new()
			buy_btn.text = "Buy Out ($%d)" % GameState.get_rival_buyout_price(rid)
			buy_btn.pressed.connect(_on_buyout.bind(rid))
			rivals_container.add_child(buy_btn)

func _rival_line(rd: Dictionary) -> String:
	var rname: String = rd.get("name", "?")
	if rd.get("acquired_by_player", false):
		return "%s — ACQUIRED (yours)" % rname
	var status: String = rd.get("status", "active")
	if status == "bankrupt":
		return "%s — BANKRUPT (out)" % rname
	if status == "exited":
		return "%s — EXITED (out)" % rname
	var crush := ""
	if GameState._rival_crushed(rd):
		crush = " — CRUSHED"
	return "%s — %.1f%%%s" % [rname, float(rd.get("share", 0)), crush]

func _populate_owned():
	if GameState.owned_companies.is_empty():
		owned_label.text = "None yet. Acquire a lab to add its research to your market share."
		return
	var parts: PackedStringArray = []
	for o in GameState.owned_companies:
		var od: Dictionary = o as Dictionary
		var remaining: Array = od.get("techs_remaining", [])
		parts.append("%s [%s] +%.2f%%/day%s" % [
			od.get("name", "?"),
			od.get("outcome", "?"),
			float(od.get("daily_research", 0.0)) * float(od.get("mult", 1.0)),
			" (%d tech in pipeline)" % remaining.size() if not remaining.is_empty() else ""
		])
	owned_label.text = "\n".join(parts)

func _update_domination():
	var prog: Dictionary = GameState.get_domination_progress()
	var bits: PackedStringArray = []
	for d in prog.get("details", []):
		var dd: Dictionary = d as Dictionary
		bits.append("%s: %s" % [dd.get("name", "?"), dd.get("how", "?")])
	dom_label.text = "DOMINATION %d/%d — %s" % [
		int(prog.get("crushed", 0)), int(prog.get("total", 0)), "; ".join(bits)
	]

func _on_dd(company_id: String):
	var res: Dictionary = GameState.perform_due_diligence(company_id)
	if res.get("ok", false):
		status_label.text = "Diligence: estimated true value $%d (±%d%%). Asking price info unchanged — decide." % [
			round(float(res.get("estimate", 0.0))), round(float(res.get("error", 0.0)) * 100.0)
		]
	else:
		status_label.text = "Diligence unavailable (%s)." % res.get("reason", "?")
	_refresh()

func _on_acquire(company_id: String):
	var res: Dictionary = GameState.acquire_company(company_id)
	if res.get("ok", false):
		status_label.text = "Acquired for $%d — the deal looks like a %s." % [
			int(res.get("price", 0)), res.get("outcome", "?")
		]
	else:
		status_label.text = "Acquisition failed (%s)." % res.get("reason", "?")
	_refresh()
	_maybe_game_over()

func _on_buyout(rival_id: String):
	var res: Dictionary = GameState.buy_out_rival(rival_id)
	if res.get("ok", false):
		status_label.text = "Rival bought out for $%d." % int(res.get("price", 0))
	else:
		status_label.text = "Buyout failed (%s)." % res.get("reason", "?")
	_refresh()
	_maybe_game_over()

func _maybe_game_over():
	if GameState.is_game_over():
		get_tree().change_scene_to_file("res://scenes/endgame/game_over.tscn")

func _on_game_over(_result: Dictionary):
	get_tree().change_scene_to_file("res://scenes/endgame/game_over.tscn")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
