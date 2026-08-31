extends Node

# Realistic balance model: an actual player under pressure.
# Uses the real run_experiment API (funding, incidents, HELIOS, dangerous risk all fire).
# Policy: run the best *affordable unlocked* experiment each step; if none affordable,
# wait one day (funding grants arrive on the funding timeline). We measure time-to-confirm,
# spend, and whether the player finishes before bankruptcy.

func _ready():
	_run(0, -1, "Chen (worst physics), all artifacts rotation")
	_run(0, 0, "Chen (worst physics), J001 only")
	_run(2, 0, "Vasquez (observation spec), J001 only")
	_get_costs()
	get_tree().quit()

func _run(sci_idx: int, artifact_idx: int, desc: String):
	GameState.initialize_new_campaign({"name": "Balance Sim"})
	if artifact_idx >= 0:
		GameState.select_artifact(artifact_idx)
	GameState._rng.seed = 9000 + sci_idx
	var sci: Dictionary = GameState.scientists[sci_idx]
	var steps := 0
	var bankrupt := false
	var min_cost := 999999
	for exp in GameState.load_experiment_definitions():
		min_cost = mini(min_cost, GameState._get_experiment_cost((exp as Dictionary).get("id", "")))

	while steps < 400:
		if GameState.knowledge["state"] == "confirmed":
			break
		var best_id := ""
		var best_score := 0.0
		for exp in GameState.load_experiment_definitions():
			var e: Dictionary = exp as Dictionary
			if not GameState.is_experiment_unlocked(e.get("id", "")):
				continue
			if not GameState.can_afford_experiment(e.get("id", "")):
				continue
			var gain := float(e.get("knowledge_gain", 2))
			# Emulate "run the best thing I can reasonably afford": high-tier experiments are
			# attractive but a cost penalty prevents buying ruinously expensive ones.
			var score: float = gain * 10.0 - float(GameState._get_experiment_cost(e.get("id", ""))) / 100.0
			if score > best_score:
				best_score = score
				best_id = e.get("id", "")
		if best_id.is_empty():
			var funds_before: int = GameState.budget["funds"]
			GameState.elapsed_days += 1
			GameState._check_funding()
			if GameState.budget["funds"] == funds_before and GameState.budget["funds"] < min_cost:
				break  # permanently stuck (no further funding and broke)
			continue
		GameState.run_experiment(_exp_def(best_id), sci)
		steps += 1
		if GameState.budget["funds"] < 0:
			bankrupt = true
			break

	var outcome: String = "BANKRUPT" if bankrupt else ("confirmed" if GameState.knowledge["state"] == "confirmed" else "STUCK")
	print("== %s == | %s | exps: %d | days: %.1f | spend: $%d | funds: $%d | fundingIn: $%d | helios: %d%%" % [
		desc, outcome, steps, GameState.elapsed_days, GameState.budget["spent"],
		GameState.budget["funds"], GameState.budget["funding_received"], GameState.helios["progress"]
	])

func _get_costs():
	var parts := PackedStringArray()
	for exp in GameState.load_experiment_definitions():
		parts.append("%s=%d" % [(exp as Dictionary).get("id", "?").replace("EXP_", ""), GameState._get_experiment_cost((exp as Dictionary).get("id", ""))])
	print("COSTS: " + ", ".join(parts))

func _exp_def(id: String) -> Dictionary:
	for exp in GameState.load_experiment_definitions():
		if (exp as Dictionary).get("id", "") == id:
			return exp as Dictionary
	return {}
