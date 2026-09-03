extends Control

@onready var funds_label: Label = $ScrollContainer/VBox/funds_label
@onready var active_label: Label = $ScrollContainer/VBox/active_label
@onready var offer_label: Label = $ScrollContainer/VBox/offer_label
@onready var btn_accept: Button = $ScrollContainer/VBox/offer_row/btn_accept
@onready var btn_decline: Button = $ScrollContainer/VBox/offer_row/btn_decline
@onready var done_label: Label = $ScrollContainer/VBox/done_label
@onready var status_label: Label = $ScrollContainer/VBox/status_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back

func _ready():
	btn_accept.pressed.connect(_on_accept)
	btn_decline.pressed.connect(_on_decline)
	btn_back.pressed.connect(_on_back)
	EventBus.game_over.connect(_on_game_over)
	_refresh()

func _refresh():
	funds_label.text = "Funds: $%d | Day %d | Military ties: %d | Active world event: %s" % [
		GameState.budget.get("funds", 0),
		int(GameState.elapsed_days),
		int(GameState.military_ties),
		GameState.active_event.get("name", "none")
	]
	if GameState.active_contract.is_empty():
		active_label.text = "No active contract. Your full workdays go to your own research."
	else:
		var cdef: Dictionary = GameState._contract_def(GameState.active_contract.get("id", ""))
		var left: float = float(GameState.active_contract.get("days_required", 0.0)) - float(GameState.active_contract.get("days_done", 0.0))
		active_label.text = "%s for %s — %.0f workdays left.\nCompletion pays $%d + tech progress." % [
			cdef.get("title", "?"), cdef.get("issuer", "?"), left, int(cdef.get("completion_pay", 0))
		]
	if GameState.pending_offer.is_empty():
		offer_label.text = "No offers right now. The next request arrives around day %d." % int(GameState.next_offer_day)
		btn_accept.disabled = true
		btn_decline.disabled = true
	else:
		var cdef2: Dictionary = GameState._contract_def(GameState.pending_offer.get("id", ""))
		var days_left: float = float(GameState.pending_offer.get("expires_day", 0.0)) - GameState.elapsed_days
		offer_label.text = "%s\n%s\nNeeds %d workdays | $%d upfront + $%d on completion | expires in %d days" % [
			cdef2.get("title", "?"),
			"%s — %s" % [cdef2.get("issuer", "?"), cdef2.get("flavor", "")],
			int(cdef2.get("days_required", 0)),
			int(cdef2.get("upfront", 0)),
			int(cdef2.get("completion_pay", 0)),
			int(maxi(int(ceil(days_left)), 0))
		]
		var busy: bool = not GameState.active_contract.is_empty()
		btn_accept.disabled = busy
		btn_decline.disabled = false
	if GameState.completed_contracts.is_empty():
		done_label.text = "Completed: none."
	else:
		done_label.text = "Completed (%d): %s" % [
			GameState.completed_contracts.size(), ", ".join(GameState.completed_contracts)
		]

func _on_accept():
	var res: Dictionary = GameState.accept_contract()
	if res.get("ok", false):
		status_label.text = "Contract accepted. Upfront paid; each workday now also serves the client."
	else:
		status_label.text = "Cannot accept (%s)." % res.get("reason", "?")
	_refresh()
	_maybe_game_over()

func _on_decline():
	GameState.decline_contract()
	status_label.text = "Offer declined. Another request will arrive later."
	_refresh()

func _maybe_game_over():
	if GameState.is_game_over():
		get_tree().change_scene_to_file("res://scenes/endgame/game_over.tscn")

func _on_game_over(_result: Dictionary):
	get_tree().change_scene_to_file("res://scenes/endgame/game_over.tscn")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
