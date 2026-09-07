extends Control

@onready var org_label: Label = $MarginContainer/Scroll/VBox/header_row/org_label
@onready var day_budget_label: Label = $MarginContainer/Scroll/VBox/header_row/day_budget_label
@onready var artifact_container: VBoxContainer = $MarginContainer/Scroll/VBox/artifacts_panel/artifacts_vbox/artifact_container
@onready var scientist_container: VBoxContainer = $MarginContainer/Scroll/VBox/scientists_panel/scientists_vbox/scientist_container
@onready var candidates_container: VBoxContainer = $MarginContainer/Scroll/VBox/scientists_panel/scientists_vbox/candidates_container
@onready var status_label: Label = $MarginContainer/Scroll/VBox/status_label

@onready var btn_artifact: Button = $MarginContainer/Scroll/VBox/nav_row/btn_artifact
@onready var btn_scientists: Button = $MarginContainer/Scroll/VBox/nav_row/btn_scientists
@onready var btn_experiments: Button = $MarginContainer/Scroll/VBox/nav_row/btn_experiments
@onready var btn_helios: Button = $MarginContainer/Scroll/VBox/nav_row/btn_helios
@onready var btn_budget: Button = $MarginContainer/Scroll/VBox/nav_row/btn_budget
@onready var btn_technology: Button = $MarginContainer/Scroll/VBox/nav_row/btn_technology
@onready var btn_incidents: Button = $MarginContainer/Scroll/VBox/nav_row/btn_incidents
@onready var btn_acquisitions: Button = $MarginContainer/Scroll/VBox/nav_row2/btn_acquisitions
@onready var btn_contracts: Button = $MarginContainer/Scroll/VBox/nav_row2/btn_contracts
@onready var btn_espionage: Button = $MarginContainer/Scroll/VBox/nav_row2/btn_espionage
@onready var btn_facilities: Button = $MarginContainer/Scroll/VBox/nav_row2/btn_facilities
@onready var btn_infirmary: Button = $MarginContainer/Scroll/VBox/nav_row2/btn_infirmary
@onready var btn_main_menu: Button = $MarginContainer/Scroll/VBox/footer_row/btn_main_menu
@onready var btn_save: Button = $MarginContainer/Scroll/VBox/footer_row/btn_save
@onready var btn_help: Button = $MarginContainer/Scroll/VBox/footer_row/btn_help
@onready var guide_panel: PanelContainer = $MarginContainer/Scroll/VBox/guide_panel
@onready var goal_label: Label = $MarginContainer/Scroll/VBox/guide_panel/guide_vbox/goal_label
@onready var tutorial_label: Label = $MarginContainer/Scroll/VBox/guide_panel/guide_vbox/tutorial_label
@onready var btn_tour_skip: Button = $MarginContainer/Scroll/VBox/guide_panel/guide_vbox/btn_tour_skip
@onready var memorial_overlay: PanelContainer = $MemorialOverlay
@onready var memorial_title: Label = $MemorialOverlay/MemorialVBox/memorial_title
@onready var memorial_text: Label = $MemorialOverlay/MemorialVBox/memorial_text
@onready var btn_memorial_continue: Button = $MemorialOverlay/MemorialVBox/btn_memorial_continue
@onready var bg_rect: ColorRect = $BgRect
@onready var alert_rect: ColorRect = $AlertRect
var _alert_pulse := 0.0

func _apply_bg():
	var shader := load("res://assets/shaders/lab_bg.gdshader") as Shader
	if shader == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	bg_rect.material = mat

func _ready():
	_apply_bg()
	btn_artifact.pressed.connect(_go.bind("res://scenes/experiment/artifact_detail.tscn"))
	btn_scientists.pressed.connect(_go.bind("res://scenes/experiment/scientist_detail.tscn"))
	btn_experiments.pressed.connect(_go.bind("res://scenes/experiment/experiment_selection.tscn"))
	btn_helios.pressed.connect(_go.bind("res://scenes/experiment/helios_intel.tscn"))
	btn_budget.pressed.connect(_go.bind("res://scenes/budget/budget.tscn"))
	btn_technology.pressed.connect(_go.bind("res://scenes/technology/technology.tscn"))
	btn_incidents.pressed.connect(_go.bind("res://scenes/incidents/incident_reports.tscn"))
	btn_acquisitions.pressed.connect(_go.bind("res://scenes/acquisitions/acquisitions.tscn"))
	btn_contracts.pressed.connect(_go.bind("res://scenes/contracts/contracts.tscn"))
	btn_espionage.pressed.connect(_go.bind("res://scenes/espionage/espionage.tscn"))
	btn_facilities.pressed.connect(_go.bind("res://scenes/facilities/facilities.tscn"))
	btn_infirmary.pressed.connect(_go.bind("res://scenes/infirmary/infirmary.tscn"))
	btn_main_menu.pressed.connect(_on_main_menu)
	btn_save.pressed.connect(_on_save)
	btn_help.pressed.connect(_go.bind("res://scenes/help/codex.tscn"))
	btn_tour_skip.pressed.connect(_on_tour_skip)
	btn_memorial_continue.pressed.connect(_on_memorial_continue)
	EventBus.game_over.connect(_on_game_over)
	EventBus.market_updated.connect(_on_market_updated)
	EventBus.scientist_died.connect(_on_scientist_died)
	AudioManager.start_music("lab")
	_refresh_ui()
	_maybe_memorial()

func _process(delta):
	var dread: bool = not GameState.active_crises.is_empty() or GameState.esp_risk >= 50.0
	AudioManager.set_tension(dread)
	var alert: bool = dread or not GameState.pending_memorial.is_empty()
	alert_rect.visible = alert
	if alert:
		_alert_pulse += delta
		var a: float = 0.12 + 0.13 * (0.5 + 0.5 * sin(_alert_pulse * 3.0))
		alert_rect.color = Color(0.5, 0.02, 0.03, a)

func _maybe_memorial():
	if GameState.pending_memorial.is_empty():
		return
	_show_memorial(GameState.pending_memorial)

func _on_scientist_died(dead_name: String):
	_show_memorial_by_name(dead_name)

func _show_memorial(sci_id: String):
	memorial_title.text = "KIA: %s" % GameState._scientist_name(sci_id)
	memorial_text.text = "The work continues because it must. Their notebook is sealed into the archive."
	_show_memorial_overlay()

func _show_memorial_by_name(dead_name: String):
	memorial_title.text = "KIA: %s" % dead_name
	memorial_text.text = "The work continues because it must. Their notebook is sealed into the archive."
	_show_memorial_overlay()

func _show_memorial_overlay():
	memorial_overlay.visible = true
	memorial_overlay.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(memorial_overlay, "modulate:a", 1.0, 1.2)

func _on_memorial_continue():
	GameState.pending_memorial = ""
	memorial_overlay.visible = false

func _refresh_ui():
	org_label.text = GameState.organization.get("name", "Unknown Organization")
	var event_text := ""
	if not GameState.active_event.is_empty():
		event_text = " | EVENT: %s" % GameState.active_event.get("name", "?")
	if GameState.insolvent_streak > 0 and not GameState.in_recovery:
		event_text += " | INSOLVENT x%d — fund the lab or lose it" % GameState.insolvent_streak
	if GameState.debt_overdue():
		event_text += " | DEBT OVERDUE — collectors take $150/day"
	if GameState.in_recovery:
		var aname := "Unknown"
		for r in GameState.rivals:
			if (r as Dictionary).get("id", "") == GameState.acquirer_id:
				aname = (r as Dictionary).get("name", "Unknown")
		day_budget_label.text = "Day %d | IN DIVISION (%s) | Influence: %d/100 | %d days left" % [
			GameState.elapsed_days, aname,
			int(GameState.influence), int(ceil(GameState.recovery_days_left))
		]
	else:
		day_budget_label.text = "Day %d | $%d | My Market: %.1f%% | ACT %d: %s%s" % [
			GameState.elapsed_days, GameState.budget.get("funds", 0), GameState.get_player_market(),
			GameState.act, GameState.get_act_name(), event_text
		]
	_populate_artifacts()
	_populate_scientists()
	_populate_candidates()
	if GameState.active_crises.is_empty():
		btn_incidents.text = "Incidents"
		btn_incidents.remove_theme_color_override("font_color")
	else:
		btn_incidents.text = "Incidents (%d!)" % GameState.active_crises.size()
		btn_incidents.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	goal_label.text = "GOAL: " + GameState.get_current_goal()
	var card: Dictionary = GameState.get_tour_card()
	if card.is_empty():
		btn_tour_skip.visible = false
		var pending: Array = GameState.check_tutorial()
		if pending.is_empty():
			guide_panel.visible = true
			tutorial_label.visible = false
		else:
			guide_panel.visible = true
			tutorial_label.visible = true
			var lines: PackedStringArray = []
			for i in range(mini(pending.size(), 2)):
				lines.append("• " + pending[i])
			tutorial_label.text = "Next: " + "  ".join(lines)
	elif card.get("finished", false):
		btn_tour_skip.visible = false
		guide_panel.visible = true
		tutorial_label.visible = true
		tutorial_label.text = "Tour complete — $500 training grant received. The lab is yours."
	else:
		guide_panel.visible = true
		tutorial_label.visible = true
		btn_tour_skip.visible = true
		tutorial_label.text = "GUIDED TOUR (%d left): %s — %s" % [
			int(card.get("remaining", 0)), card.get("title", "?"), card.get("detail", "")
		]

func _on_tour_skip():
	GameState.dismiss_tour()
	_refresh_ui()

func _on_market_updated(_player_market: float, _rivals: Array):
	_populate_artifacts()

func _on_game_over(_result: Dictionary):
	get_tree().change_scene_to_file("res://scenes/endgame/game_over.tscn")

func _populate_artifacts():
	for child in artifact_container.get_children():
		child.queue_free()

	for i in range(GameState.available_artifacts.size()):
		var art: Dictionary = GameState.available_artifacts[i]
		var label := Label.new()
		var status := ""
		var matched: bool = art.get("id", "") == GameState.artifact.get("id", "")
		if not GameState.is_artifact_unlocked(art.get("id", "")):
			status = " (LOCKED — ACT %d)" % (GameState.act + 1)
		elif matched:
			status = " (SELECTED)"
		label.text = "OBJECT %s — %s%s" % [art.get("id", "?"), art.get("display_name", "?"), status]
		label.add_theme_font_size_override("font_size", 15)
		artifact_container.add_child(label)

func _populate_scientists():
	for child in scientist_container.get_children():
		child.queue_free()

	for s in GameState.scientists:
		var sci: Dictionary = s as Dictionary
		var label := Label.new()
		var skills: Dictionary = sci.get("skills", {})
		var condition := ""
		var hp: int = int(sci.get("health", 100))
		var filled: int = hp / 10
		var hpbar := "["
		for i in range(10):
			hpbar += "#" if i < filled else "-"
		hpbar += "]"
		if sci.get("status", "ACTIVE") == "DECEASED":
			condition = " [DECEASED]"
		elif sci.get("status", "ACTIVE") == "DEFECTED":
			condition = " [DEFECTED]"
		elif sci.get("status", "ACTIVE") == "RESIGNED":
			condition = " [RESIGNED]"
		elif sci.get("status", "ACTIVE") == "INJURED":
			condition = " [INJURED %s %d]" % [hpbar, hp]
		else:
			condition = " [%s]" % hpbar
		label.text = "%s %s — %s | '%s' [P:%s O:%s C:%s]%s" % [
			sci.get("first_name", "?"),
			sci.get("last_name", "?"),
			sci.get("primary_specialty", "unknown").replace("_", " ").capitalize(),
			", ".join(sci.get("traits", [])),
			skills.get("physics", 0),
			skills.get("observation", 0),
			skills.get("curiosity", 0),
			condition
		]
		label.add_theme_font_size_override("font_size", 14)
		scientist_container.add_child(label)

func _populate_candidates():
	for child in candidates_container.get_children():
		child.queue_free()
	if GameState.hire_pool.is_empty():
		var none := Label.new()
		none.text = "No candidates on the market."
		none.add_theme_font_size_override("font_size", 13)
		candidates_container.add_child(none)
		return
	for cid in GameState.hire_pool:
		var cdef: Dictionary = GameState._hireable_def(str(cid))
		if cdef.is_empty():
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var line := Label.new()
		line.text = "%s %s (%s, bonus $%d)\n%s" % [
			cdef.get("first_name", "?"), cdef.get("last_name", "?"),
			cdef.get("primary_specialty", "?").replace("_", " ").capitalize(),
			int(cdef.get("signing_bonus", 0)),
			cdef.get("background", "")
		]
		line.add_theme_font_size_override("font_size", 13)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(line)
		var hire_btn := Button.new()
		hire_btn.text = "Hire"
		hire_btn.pressed.connect(_on_hire.bind(cdef.get("id", "")))
		row.add_child(hire_btn)
		candidates_container.add_child(row)

func _on_hire(sci_id: String):
	var res: Dictionary = GameState.hire_scientist(sci_id)
	if res.get("ok", false):
		status_label.text = "Hired for $%d." % int(res.get("cost", 0))
	else:
		status_label.text = "Cannot hire (%s)." % res.get("reason", "?")
	_refresh_ui()

func _on_main_menu():
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _on_save():
	SaveManager.save_game()
	status_label.text = "Campaign saved."

func _go(path: String):
	get_tree().change_scene_to_file(path)
