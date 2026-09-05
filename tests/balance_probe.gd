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
	_probe("hard-systems-c", "hard", 555, true, true, true)
	_probe("hard-systems-d", "hard", 3141, true, true, true)
	_probe_batch("normal-batch", "normal", 1234, false)
	_probe_batch("hard-batch", "hard", 200, true)
	_probe_recovery("rec-research", 4242, false)
	_probe_recovery("rec-saboteur", 4243, true)
	_probe("expert-pure", "expert", 300, false, false, false)
	_probe("expert-systems", "expert", 300, true, true, true)
	_probe_domination("domination-hard", "hard", 400)
	_probe_recovery_other("rec-bermant", 4244)
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
		_sci = _living_pick()
		if _sci.is_empty():
			print("PROBE %s: STAFF_WIPE at day %.0f" % [tag, days])
			return
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
		_sci = _living_pick()
		if _sci.is_empty():
			print("PROBE %s: STAFF_WIPE at day %.0f" % [tag, days])
			return
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

func _probe_batch(tag: String, difficulty_id: String, seed: int, use_systems: bool):
	GameState.initialize_new_campaign({"name": "Probe " + tag}, difficulty_id, seed)
	GameState.select_artifact(0)
	var cost: int = GameState._get_experiment_cost("EXP_HEATING")
	var bailouts := 0
	var days := 0.0
	while days < 300 and not GameState.is_game_over():
		var team: Array = []
		for s in GameState.scientists:
			var sd: Dictionary = s as Dictionary
			if GameState._is_available(sd) and team.size() < 2:
				team.append(sd)
		if team.is_empty():
			print("PROBE %s: STAFF_WIPE at day %.0f" % [tag, days])
			return
		if use_systems:
			if not GameState.pending_offer.is_empty() and GameState.active_contract.is_empty():
				GameState.accept_contract()
			_try_buy_cheapest()
		if int(GameState.budget.get("funds", 0)) < cost * 2:
			GameState.budget["funds"] = int(GameState.budget.get("funds", 0)) + 400
			bailouts += 1
		var pairs: Array = []
		for member in team:
			pairs.append({"exp": _exp_def, "sci": member})
		GameState.run_day_batch(pairs)
		days = GameState.elapsed_days
	var go: Dictionary = GameState.game_over
	print("PROBE %s: %s type=%s days=%.0f player=%.1f helios=%.1f funds=%d bailouts=%d" % [
		tag,
		"WIN" if go.get("won", false) else "LOSE",
		go.get("type", go.get("reason", "?")),
		days,
		GameState.get_player_market(),
		GameState.get_rival_market("RIV_HELIOS"),
		int(GameState.budget.get("funds", 0)),
		bailouts
	])

func _probe_recovery(tag: String, seed: int, saboteur: bool):
	GameState.initialize_new_campaign({"name": "Probe " + tag}, "normal", seed)
	GameState.select_artifact(0)
	GameState.budget["funds"] = -5000
	for i in range(3):
		GameState._tick_new_day([])
	if GameState.game_over.get("type", "") != "acquired":
		print("PROBE %s: NOENTRY" % tag)
		return
	var acq: String = GameState.game_over.get("acquirer", "?")
	if not GameState.report_for_work().get("ok", false):
		print("PROBE %s: NOREPORT" % tag)
		return
	var days := 0.0
	var bailouts := 0
	while days < 80 and GameState.in_recovery and not GameState.is_game_over():
		if saboteur and GameState.esp_risk < 45.0:
			GameState.perform_espionage_op("OP_SABOTAGE", GameState.acquirer_id)
		var sci := _living_pick()
		if sci.is_empty():
			break
		if int(GameState.budget.get("funds", 0)) < GameState._get_experiment_cost("EXP_HEATING"):
			GameState.budget["funds"] = int(GameState.budget.get("funds", 0)) + 200
			bailouts += 1
		GameState.run_experiment(_exp_def, sci)
		days = GameState.elapsed_days
	var outcome := "timeout"
	if not GameState.in_recovery and not GameState.is_game_over():
		outcome = "restored"
	elif GameState.is_game_over():
		outcome = str(GameState.game_over.get("reason", "?"))
	# Farm check: after a restore, keep playing pure research to the true end.
	var final := ""
	if outcome == "restored":
		while days < 160 and not GameState.is_game_over():
			var sci2 := _living_pick()
			if sci2.is_empty():
				break
			if int(GameState.budget.get("funds", 0)) < GameState._get_experiment_cost("EXP_HEATING"):
				GameState.budget["funds"] = int(GameState.budget.get("funds", 0)) + 200
				bailouts += 1
			GameState.run_experiment(_exp_def, sci2)
			days = GameState.elapsed_days
		if GameState.is_game_over():
			final = str(GameState.game_over.get("type", "?"))
	print("PROBE %s: %s acq=%s days=%.0f inf=%.0f bailouts=%d final=%s badges=%s" % [
		tag, outcome, acq, days, GameState.influence, bailouts, final, GameState.run_badges
	])

func _probe_domination(tag: String, difficulty_id: String, seed: int):
	GameState.initialize_new_campaign({"name": "Probe " + tag}, difficulty_id, seed)
	GameState.select_artifact(0)
	_sci = GameState.scientists[0]
	var bailouts := 0
	var days := 0.0
	while days < 300 and not GameState.is_game_over():
		_sci = _living_pick()
		if _sci.is_empty():
			print("PROBE %s: STAFF_WIPE at day %.0f" % [tag, days])
			return
		_try_buy_cheapest()
		_try_buyout_reserved()
		_try_expose_smallest()
		if int(GameState.budget.get("funds", 0)) < GameState._get_experiment_cost("EXP_HEATING"):
			GameState.budget["funds"] = int(GameState.budget.get("funds", 0)) + 200
			bailouts += 1
		GameState.run_experiment(_exp_def, _sci)
		days = GameState.elapsed_days
	var go: Dictionary = GameState.game_over
	var prog: Dictionary = GameState.get_domination_progress()
	print("PROBE %s: %s type=%s days=%.0f crushed=%d/%d bailouts=%d" % [
		tag,
		"WIN" if go.get("won", false) else "LOSE",
		go.get("type", go.get("reason", "?")),
		days, int(prog.get("crushed", 0)), int(prog.get("total", 0)), bailouts
	])

func _try_expose_smallest():
	if GameState.esp_risk >= 45.0:
		return
	var target := ""
	var best := 1e9
	for r in GameState.rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			continue
		if float(rd.get("share", 0)) < best:
			best = float(rd.get("share", 0))
			target = rd.get("id", "")
	if target != "":
		GameState.perform_espionage_op("OP_EXPOSE", target)

func _try_buyout_reserved():
	var best_id := ""
	var best_price := 1 << 30
	for r in GameState.rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			continue
		var price: int = GameState.get_rival_buyout_price(rd.get("id", ""))
		if price < best_price:
			best_price = price
			best_id = rd.get("id", "")
	if best_id != "" and int(GameState.budget.get("funds", 0)) >= best_price * 2:
		GameState.buy_out_rival(best_id)

func _try_buyout_cheapest():
	var best_id := ""
	var best_price := 1 << 30
	for r in GameState.rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			continue
		var price: int = GameState.get_rival_buyout_price(rd.get("id", ""))
		if price < best_price:
			best_price = price
			best_id = rd.get("id", "")
	if best_id != "" and int(GameState.budget.get("funds", 0)) >= best_price:
		GameState.buy_out_rival(best_id)

func _probe_recovery_other(tag: String, seed: int):
	GameState.initialize_new_campaign({"name": "Probe " + tag}, "normal", seed)
	GameState.select_artifact(0)
	var other := ""
	for r in GameState.rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("id", "") != "RIV_HELIOS" and rd.get("status", "active") == "active" and other == "":
			other = rd.get("id", "")
			rd["share"] = 30.0
		elif rd.get("id", "") == "RIV_HELIOS":
			rd["share"] = 10.0
	if other == "":
		print("PROBE %s: NOFIELD" % tag)
		return
	GameState.budget["funds"] = -5000
	for i in range(3):
		GameState._tick_new_day([])
	if GameState.game_over.get("acquirer", "") != other:
		print("PROBE %s: WRONGACQ %s" % [tag, GameState.game_over.get("acquirer", "?")])
		return
	if not GameState.report_for_work().get("ok", false):
		print("PROBE %s: NOREPORT" % tag)
		return
	var days := 0.0
	while days < 80 and GameState.in_recovery and not GameState.is_game_over():
		var sci := _living_pick()
		if sci.is_empty():
			break
		if int(GameState.budget.get("funds", 0)) < GameState._get_experiment_cost("EXP_HEATING"):
			GameState.budget["funds"] = int(GameState.budget.get("funds", 0)) + 200
		GameState.run_experiment(_exp_def, sci)
		days = GameState.elapsed_days
	var outcome := "timeout"
	if not GameState.in_recovery and not GameState.is_game_over():
		outcome = "restored"
	elif GameState.is_game_over():
		outcome = str(GameState.game_over.get("reason", "?"))
	var prize := ""
	for f in GameState.facilities_owned:
		if str(f).begins_with("FAC_PRIZE_"):
			prize = str(f)
	print("PROBE %s: %s acq=%s days=%.0f prize=%s" % [tag, outcome, other, days, prize])

func _living_pick() -> Dictionary:
	for s in GameState.scientists:
		var sd: Dictionary = s as Dictionary
		if GameState._is_available(sd):
			return sd
	return {}

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
