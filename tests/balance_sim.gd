extends Node

func _ready():
	var scientists: Array = [0, 2]
	for si in scientists:
		_run(si, false)
		_run(si, true)
	get_tree().quit()

func _run(sci_idx: int, max_gain: bool):
	GameState.initialize_new_campaign({"name": "Balance Sim"})
	GameState.select_artifact(0)
	GameState._rng.seed = 4242 + sci_idx * 7
	var sci: Dictionary = GameState.scientists[sci_idx % GameState.scientists.size()]
	var experiments_run := 0
	var spent := 0
	for step in range(80):
		if GameState.knowledge["progress"] >= GameState.CONFIRMED_THRESHOLD:
			break
		var best_id := ""
		var best_score := 0.0
		var best_cost := 0
		for exp in GameState.load_experiment_definitions():
			var e: Dictionary = exp as Dictionary
			if not GameState.is_experiment_unlocked(e.get("id", "")):
				continue
			if not GameState.can_afford_experiment(e.get("id", "")):
				continue
			var cost := GameState._get_experiment_cost(e.get("id", ""))
			var gain := float(e.get("knowledge_gain", 2))
			var score := gain if max_gain else gain / float(cost)
			if score > best_score:
				best_score = score
				best_id = e.get("id", "")
				best_cost = cost
		if best_id.is_empty():
			break
		GameState.run_experiment(_exp_def(best_id), sci)
		experiments_run += 1
		spent += best_cost

	var strat: String = "max-gain" if max_gain else "cost-eff"
	print("== %s | scientist %s == experiments: %d | spent: $%d | left: $%d | progress: %d%% | days: %.1f" % [
		strat, sci.get("last_name", "?"), experiments_run, spent, GameState.budget["funds"], GameState.knowledge["progress"], GameState.elapsed_days
	])

func _exp_def(id: String) -> Dictionary:
	for exp in GameState.load_experiment_definitions():
		if (exp as Dictionary).get("id", "") == id:
			return exp as Dictionary
	return {}
