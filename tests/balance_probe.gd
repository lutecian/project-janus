extends Node

# Dev-only balance probe (headless): simulates playstyles per difficulty and
# reports outcome/days/economy. NOT part of the pass/fail suite.
# Run: godot --headless --nomt --path <repo> res://tests/balance_probe.tscn

var _exp_def := {}
var _sci := {}

func _ready():
	var exps: Array = GameState.load_experiment_definitions()
	for e in exps:
		if (e as Dictionary).get("id", "") == "EXP_HEATING":
			_exp_def = (e as Dictionary).duplicate()
	_run_all()
	get_tree().quit()

func _run_all():
	_probe("easy-pure", "easy", 100, false, false, false)
	_probe("normal-pure", "normal", 1234, false, false, false)
	_probe("hard-pure", "hard", 200, false, false, false)
	_probe("normal-contracts", "normal", 1234, true, false, false)
	_probe("normal-systems", "normal", 1234, true, true, false)
	_probe("hard-systems", "hard", 200, true, true, true)
	_probe("hard-systems-b", "hard", 777, true, true, true)
	_probe_skilled("hard-skilled", "hard", 200)
	_probe_skilled("hard-skilled-b", "hard", 777)

func _probe(tag: String, difficulty_id: String, seed: int, use_contracts: bool, use_acq: bool, use_esp: bool):
	GameState.initialize_new_campaign({"name": "Probe " + tag}, difficulty_id, seed)
	GameState.select_artifact(0)
	_sci = GameState.scientists[0]
	var cost: int = GameState._get_experiment_cost("EXP_HEATING")
	var bailouts := 0
	var sabotages := 0
	var days := 0.0
	while days < 300 and not GameState.is_game_over():
		if use_contracts and not GameState.pending_offer.is_empty() and GameState.active_contract.is_empty():
			GameState.accept_contract()
		if use_acq:
			_try_buy_cheapest()
		if use_esp:
			if GameState.esp_risk < 40.0:
				var res: Dictionary = GameState.perform_espionage_op("OP_SABOTAGE", "RIV_HELIOS")
				if res.get("ok", false) and res.get("success", false):
					sabotages += 1
		if int(GameState.budget.get("funds", 0)) < cost:
			GameState.budget["funds"] = int(GameState.budget.get("funds", 0)) + 200
			bailouts += 1
		GameState.run_experiment(_exp_def, _sci)
		days = GameState.elapsed_days
	var go: Dictionary = GameState.game_over
	print("PROBE %s: %s type=%s days=%.0f player=%.1f helios=%.1f funds=%d bailouts=%d contracts=%d owned=%d sabotages=%d risk=%.0f" % [
		tag,
		"WIN" if go.get("won", false) else "LOSE",
		go.get("type", go.get("reason", "?")),
		days,
		GameState.get_player_market(),
		GameState.get_rival_market("RIV_HELIOS"),
		int(GameState.budget.get("funds", 0)),
		bailouts,
		GameState.completed_contracts.size(),
		GameState.owned_companies.size(),
		sabotages,
		GameState.esp_risk
	])

func _probe_skilled(tag: String, difficulty_id: String, seed: int):
	GameState.initialize_new_campaign({"name": "Probe " + tag}, difficulty_id, seed)
	GameState.select_artifact(0)
	_sci = GameState.scientists[0]
	var cost: int = GameState._get_experiment_cost("EXP_HEATING")
	var bailouts := 0
	var ops := 0
	var buys := 0
	var days := 0.0
	while days < 300 and not GameState.is_game_over():
		if not GameState.pending_offer.is_empty() and GameState.active_contract.is_empty():
			GameState.accept_contract()
		_rotate_artifact()
		_dd_and_buy()
		if GameState.owned_companies.size() > buys:
			buys = GameState.owned_companies.size()
		var helios_active: bool = GameState.get_rival_market("RIV_HELIOS") > 0.0
		if helios_active and GameState.esp_risk < 30.0:
			var ex: Dictionary = GameState.perform_espionage_op("OP_EXPOSE", "RIV_HELIOS")
			if ex.get("ok", false):
				ops += 1
		elif helios_active and GameState.esp_risk < 50.0:
			var sb: Dictionary = GameState.perform_espionage_op("OP_SABOTAGE", "RIV_HELIOS")
			if sb.get("ok", false):
				ops += 1
		if int(GameState.budget.get("funds", 0)) < cost:
			GameState.budget["funds"] = int(GameState.budget.get("funds", 0)) + 200
			bailouts += 1
		GameState.run_experiment(_exp_def, _sci)
		days = GameState.elapsed_days
	var go: Dictionary = GameState.game_over
	print("PROBE %s: %s type=%s days=%.0f player=%.1f helios=%.1f funds=%d bailouts=%d contracts=%d owned=%d ops=%d risk=%.0f" % [
		tag,
		"WIN" if go.get("won", false) else "LOSE",
		go.get("type", go.get("reason", "?")),
		days,
		GameState.get_player_market(),
		GameState.get_rival_market("RIV_HELIOS"),
		int(GameState.budget.get("funds", 0)),
		bailouts,
		GameState.completed_contracts.size(),
		GameState.owned_companies.size(),
		ops,
		GameState.esp_risk
	])

func _rotate_artifact():
	if GameState.knowledge.get("state", "") != "confirmed":
		return
	for i in range(GameState.available_artifacts.size()):
		if i == GameState.selected_artifact_index:
			continue
		var aid: String = (GameState.available_artifacts[i] as Dictionary).get("id", "")
		var saved: Dictionary = GameState.per_artifact_data.get(aid, {})
		var st: String = (saved.get("discovery", {}) as Dictionary).get("state", "unknown")
		if st != "confirmed":
			GameState.select_artifact(i)
			return

func _dd_and_buy():
	for o in GameState.company_offers:
		var od: Dictionary = o as Dictionary
		if od.get("status", "") != "offered" or int(od.get("dd_level", 0)) > 0:
			continue
		if int(GameState.budget.get("funds", 0)) >= 1000:
			GameState.perform_due_diligence(od.get("id", ""))
	var best: Dictionary = {}
	var best_price := 1 << 30
	for o in GameState.company_offers:
		var od2: Dictionary = o as Dictionary
		if od2.get("status", "") != "offered" or int(od2.get("dd_level", 0)) < 1:
			continue
		var price2: int = int(od2.get("listed_price", 0))
		var est: float = float(od2.get("dd_estimate", 0.0))
		if price2 <= est * 1.05 and price2 < best_price:
			best_price = price2
			best = od2
	if best.is_empty():
		return
	if int(GameState.budget.get("funds", 0)) >= best_price:
		GameState.acquire_company(best.get("id", ""))

func _try_buy_cheapest():
	var best: Dictionary = {}
	var best_price := 1 << 30
	for o in GameState.company_offers:
		var od: Dictionary = o as Dictionary
		if od.get("status", "") != "offered":
			continue
		var price: int = int(od.get("listed_price", 0))
		if price < best_price:
			best_price = price
			best = od
	if best.is_empty():
		return
	if int(GameState.budget.get("funds", 0)) >= best_price:
		GameState.acquire_company(best.get("id", ""))
