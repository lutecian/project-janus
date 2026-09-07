extends Control

@onready var funds_label: Label = $ScrollContainer/VBox/funds_label
@onready var summary_label: Label = $ScrollContainer/VBox/summary_label
@onready var spending_label: RichTextLabel = $ScrollContainer/VBox/spending_label
@onready var funding_label: RichTextLabel = $ScrollContainer/VBox/funding_label
@onready var btn_back: Button = $ScrollContainer/VBox/ButtonRow/btn_back
@onready var debts_label: RichTextLabel = $ScrollContainer/VBox/debts_label
@onready var btn_loan_2k: Button = $ScrollContainer/VBox/LoanRow/btn_loan_2k
@onready var btn_loan_5k: Button = $ScrollContainer/VBox/LoanRow/btn_loan_5k
@onready var btn_loan_10k: Button = $ScrollContainer/VBox/LoanRow/btn_loan_10k
@onready var btn_repay: Button = $ScrollContainer/VBox/LoanRow/btn_repay

func _ready():
	btn_back.pressed.connect(_on_back)
	btn_loan_2k.pressed.connect(_on_loan.bind(2000))
	btn_loan_5k.pressed.connect(_on_loan.bind(5000))
	btn_loan_10k.pressed.connect(_on_loan.bind(10000))
	btn_repay.pressed.connect(_on_repay)
	_refresh()

func _refresh():
	var budget: Dictionary = GameState.budget
	funds_label.text = "Current Funds: $%d" % budget.get("funds", 0)
	summary_label.text = "Total Spent: $%d | Total Funding Received: $%d" % [
		budget.get("spent", 0),
		budget.get("funding_received", 0)
	]

	var data := _load_json("res://data/resources/budget.json")
	var costs: Dictionary = data.get("experiment_costs", {})

	var spending_text := ""
	var spend_by_experiment := _compute_spending_by_experiment()
	var total: int = budget.get("spent", 0)
	if total <= 0:
		spending_text = "No experiments funded yet."
	else:
		for exp_id in costs.keys():
			var cost_per: int = costs[exp_id]
			var count: int = spend_by_experiment.get(exp_id, 0)
			if count > 0:
				spending_text += "%s: %d x $%d = $%d\n" % [
					exp_id, count, cost_per, count * cost_per
				]
		spending_text += "\nTotal: $%d" % total
	spending_label.text = spending_text

	var funding_text := ""
	var intervals: Array = data.get("funding_intervals", [])
	for i in range(intervals.size()):
		var interval: Dictionary = intervals[i] as Dictionary
		var day: int = interval.get("day", 0)
		var amount: int = interval.get("amount", 0)
		var label: String = interval.get("label", "")
		var future: bool = day > GameState.elapsed_days
		var status := "PAID"
		if future:
			status = "UPCOMING (Day %d)" % day
		else:
			status = "PAID (Day %d)" % day
		funding_text += "[%s] %s — $%d\n" % [status, label, amount]
	funding_label.text = funding_text
	_refresh_debts()

func _refresh_debts():
	if GameState.debts.is_empty():
		debts_label.text = "No outstanding debts. Loans come in $2k/$5k/$10k tiers at 2%/day, due in 30 days. Overdue debts cost $150/day in collector fees."
		btn_repay.disabled = true
		return
	var lines := ""
	for i in range(GameState.debts.size()):
		var d: Dictionary = GameState.debts[i] as Dictionary
		var due_in: int = int(ceil(float(d.get("due_day", 0.0)) - GameState.elapsed_days))
		var tag := "due in %d days" % due_in
		if due_in < 0:
			tag = "OVERDUE by %d days (-$150/day)" % (-due_in)
		lines += "Debt %d: owe $%d (borrowed $%d), %s\n" % [
			i + 1, int(ceil(float(d.get("owed", 0.0)))), int(d.get("principal", 0)), tag
		]
	debts_label.text = lines
	btn_repay.disabled = false

func _on_loan(amount: int):
	GameState.request_loan(amount)
	_refresh()

func _on_repay():
	GameState.repay_debt(0)
	_refresh()

func _compute_spending_by_experiment() -> Dictionary:
	var result := {}
	for record in GameState.experiment_history:
		var rec: Dictionary = record as Dictionary
		var exp_id: String = rec.get("experiment_id", "")
		result[exp_id] = result.get(exp_id, 0) + 1
	return result

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	if json.data is Dictionary:
		return json.data as Dictionary
	return {}

func _on_back():
	get_tree().change_scene_to_file("res://scenes/laboratory/laboratory.tscn")
