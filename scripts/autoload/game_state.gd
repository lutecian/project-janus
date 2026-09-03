extends Node

const ObservationSimulator = preload("res://scripts/simulation/observation_simulator.gd")

var campaign_id: String = ""
var seed: int = 0
var elapsed_days: float = 0.0

# --- Phase 1 (0.3): market / rival-field / endgame state ---
var difficulty: Dictionary = {}
var player_market: float = 0.0
var rivals: Array = []
var game_over: Dictionary = {}

# --- Phase 2 (0.3): acquisitions + domination ---
const ACQ_DD_COSTS := [400, 900]
const ACQ_DD_ERROR := [0.25, 0.10]
const ACQ_EXIT_SHARE := 2.0
const ACQ_GRAB_BUMP := 2.0
const ACQ_BUYOUT_CAP := 4.0
var company_offers: Array = []
var owned_companies: Array = []

const DIFFICULTIES := {
	"easy": {
		"id": "easy", "display_name": "Easy",
		"majority_target": 38.0, "rival_multiplier": 0.7,
		"helios_start_share": 8.0, "helios_daily_base": 0.55,
		"player_experiment_gain": 0.85, "player_discovery_gain": 14.0,
		"player_start_budget": 12500
	},
	"normal": {
		"id": "normal", "display_name": "Normal",
		"majority_target": 46.0, "rival_multiplier": 1.0,
		"helios_start_share": 12.0, "helios_daily_base": 0.85,
		"player_experiment_gain": 0.7, "player_discovery_gain": 12.0,
		"player_start_budget": 10000
	},
	"hard": {
		"id": "hard", "display_name": "Hard",
		"majority_target": 52.0, "rival_multiplier": 1.4,
		"helios_start_share": 16.0, "helios_daily_base": 1.1,
		"player_experiment_gain": 0.6, "player_discovery_gain": 11.0,
		"player_start_budget": 8000
	}
}

var organization: Dictionary = {}
var artifact: Dictionary = {}
var available_artifacts: Array = []
var selected_artifact_index: int = 0
var scientists: Array = []
var knowledge: Dictionary = {
	"progress": 0,
	"state": "unknown",
	"observations": [],
	"experiment_counts": {}
}
var discovery: Dictionary = {
	"state": "unknown",
	"player_name": "",
	"discovery_id": "DISC_GRAV_ATTENUATION"
}
var discoveries: Array = []
var confirmed_discoveries: Array = []
var technology_unlocked: bool = false
var unlocked_technologies: Array = []
var helios: Dictionary = {
	"progress": 0,
	"artifact_id": "",
	"artifact_name": "",
	"thresholds_hit": [],
	"discovered_first": false,
	"discoveries_named": []
}
var experiment_history: Array = []
var intelligence_reports: Array = []
var last_intel_threshold: int = 0
var per_artifact_data: Dictionary = {}
var budget: Dictionary = {
	"funds": 10000,
	"spent": 0,
	"funding_received": 0,
	"next_funding_index": 0,
	"events_received": []
}
var incidents: Array = []
var incident_cooldown: int = 0
var active_incidents: Array = []
var selected_scientist_index: int = 0

const SEVERITY_ORDER := ["minor", "moderate", "severe", "critical"]

const SUSPECTED_THRESHOLD := 30
const CONFIRMED_THRESHOLD := 70

const HELIOS_THRESHOLDS := {
	15: 0,
	30: 1,
	60: 2,
	90: 3
}

const EXPERIMENT_UNLOCK_THRESHOLDS := {
	"EXP_PASSIVE": 0,
	"EXP_HEATING": 0,
	"EXP_COOLING": 0,
	"EXP_ELECTRICAL": 0,
	"EXP_XRAY": 10,
	"EXP_EM_LOW": 15,
	"EXP_EM_MID": 25,
	"EXP_EM_RESONANCE": 40,
	"EXP_ACOUSTIC": 30,
	"EXP_LASER": 30,
	"EXP_VIBRATION": 45,
	"EXP_RADIOACTIVE": 50
}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

const TRAIT_EFFECTS := {
	"brilliant": {"quality_bonus": 0.15, "discovery_bonus": 0.1},
	"curious": {"quality_bonus": 0.05, "discovery_bonus": 0.1},
	"careful": {"quality_bonus": 0.1, "malfunction_reduction": 0.03},
	"methodical": {"quality_bonus": 0.08, "consistency": 0.05},
	"skeptical": {"quality_bonus": 0.05, "discovery_reduction": 0.05},
	"resilient": {"stress_resistance": 0.2},
	"reckless": {"quality_bonus": -0.05, "critical_bonus": 0.1},
	"ambitious": {"quality_bonus": 0.05, "stress_increase": 0.1},
	"distracted": {"quality_bonus": -0.1},
	"loyal": {"stress_resistance": 0.15}
}

func _ready():
	pass

func initialize_new_campaign(org: Dictionary, difficulty_id: String = "normal"):
	difficulty = _resolve_difficulty(difficulty_id)
	campaign_id = _generate_id()
	seed = _rng.randi()
	elapsed_days = 0
	organization = org.duplicate(true)
	per_artifact_data = {}
	game_over = {}
	player_market = 0.0
	_load_artifact_data()
	_load_scientist_data()
	_reset_knowledge()
	_reset_discovery()
	_set_discovery_for_artifact()
	technology_unlocked = false
	_spawn_rivals()
	company_offers = []
	owned_companies = []
	_spawn_company_offers()
	helios["thresholds_hit"] = []
	helios["discovered_first"] = false
	helios["discoveries_named"] = []
	experiment_history = []
	intelligence_reports = []
	last_intel_threshold = 0
	unlocked_technologies = []
	incidents = []
	active_incidents = []
	_load_budget_data()
	budget["funds"] = int(difficulty.get("player_start_budget", budget["funds"]))
	_rng.seed = seed

func _resolve_difficulty(difficulty_id: String) -> Dictionary:
	var d: Dictionary = DIFFICULTIES.get(difficulty_id, DIFFICULTIES["normal"])
	return d.duplicate(true)

func _spawn_rivals():
	var rival_data: Dictionary = _load_json("res://data/rivals/rivals.json")
	var rival_defs: Array = rival_data.get("rivals", [])
	rivals = []
	var helios_start: float = difficulty.get("helios_start_share", 12.0)
	var idx: int = 0
	for rdef in rival_defs:
		var rd: Dictionary = rdef as Dictionary
		var rid: String = rd.get("id", "RIV_%d" % idx)
		var start_share: float = float(rd.get("start_share", 4.0))
		if rid == "RIV_HELIOS":
			start_share = helios_start
		var adv: float = float(rd.get("daily_advance", 0.5)) * float(difficulty.get("rival_multiplier", 1.0))
		rivals.append({
			"id": rid,
			"name": rd.get("name", "Rival %d" % (idx + 1)),
			"artifact_name": rd.get("artifact_name", ""),
			"daily_advance": adv,
			"disposition": rd.get("disposition", "steady"),
			"share": start_share,
			"discovery_bumps": 0,
			"acquired_by_player": false,
			"status": "active",
			"implosions": 0
		})
		idx += 1
	_sync_helios_rival()

func _sync_helios_rival():
	helios["start_share"] = difficulty.get("helios_start_share", 12.0)
	# helios["progress"] remains the abstract research-progress scale (drives intel
	# thresholds + existing UI); market share is tracked separately on each rival.
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("id", "") == "RIV_HELIOS":
			helios["market_share"] = rd.get("share", 0)
			return

func _load_budget_data():
	var data := _load_json("res://data/resources/budget.json")
	budget = {
		"funds": data.get("starting_budget", 10000),
		"spent": 0,
		"funding_received": 0,
		"next_funding_index": 0,
		"events_received": []
	}

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Cannot open JSON: " + path)
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("JSON parse error: " + path)
		return {}
	if json.data is Dictionary:
		return json.data as Dictionary
	return {}

func _load_artifact_data():
	available_artifacts = []
	var paths := [
		"res://data/artifacts/j001.json",
		"res://data/artifacts/j002.json",
		"res://data/artifacts/j003.json"
	]
	for path in paths:
		var data := _load_json(path)
		if data.size() > 0:
			available_artifacts.append(data.duplicate(true))
	if available_artifacts.is_empty():
		available_artifacts.append({"id": "J001", "display_name": "Lattice Sphere", "visible_description": "Unknown object.", "known_initial_data": {}, "hidden_physics": {}, "initial_knowledge_state": {}})
	if selected_artifact_index < available_artifacts.size():
		artifact = available_artifacts[selected_artifact_index]
	else:
		artifact = available_artifacts[0]

func select_artifact(index: int):
	if index < 0 or index >= available_artifacts.size():
		return
	var prev_id: String = artifact.get("id", "")
	if not prev_id.is_empty() and not per_artifact_data.has(prev_id):
		per_artifact_data[prev_id] = {
			"knowledge": knowledge.duplicate(true),
			"discovery": discovery.duplicate(true),
			"discoveries": discoveries.duplicate(true),
			"experiment_history": experiment_history.duplicate(),
			"intelligence_reports": intelligence_reports.duplicate()
		}
	selected_artifact_index = index
	artifact = available_artifacts[index]
	_set_discovery_for_artifact()
	var new_id: String = artifact.get("id", "")
	if per_artifact_data.has(new_id):
		var saved: Dictionary = per_artifact_data[new_id]
		knowledge = saved.get("knowledge", {"progress": 0, "state": "unknown", "observations": [], "experiment_counts": {}})
		discovery = saved.get("discovery", {"state": "unknown", "player_name": "", "discovery_id": ""})
		var saved_disc: Array = saved.get("discoveries", [])
		if saved_disc.is_empty():
			_discoveries_restore_from_saved()
		else:
			discoveries = saved_disc.duplicate(true)
		experiment_history = saved.get("experiment_history", [])
		intelligence_reports = saved.get("intelligence_reports", [])
	else:
		_reset_knowledge()
		_reset_discovery()
		experiment_history = []
		intelligence_reports = []

func _set_discovery_for_artifact():
	var art_id: String = artifact.get("id", "")
	discoveries = []
	var data := _load_json("res://data/discoveries/discoveries.json")
	var all_discoveries: Array = data.get("discoveries", [])
	for d in all_discoveries:
		var d_dict: Dictionary = d as Dictionary
		if d_dict.get("artifact_id", "") == art_id:
			discoveries.append({
				"discovery_id": d_dict.get("discovery_id", ""),
				"internal_name": d_dict.get("internal_name", ""),
				"display_name_before_naming": d_dict.get("display_name_before_naming", ""),
				"description": d_dict.get("description", ""),
				"player_namable": d_dict.get("player_namable", true),
				"technology_unlock": d_dict.get("technology_unlock", ""),
				"state": "unknown",
				"player_name": ""
			})
	if discoveries.is_empty():
		var fallback := {
			"discovery_id": "DISC_GRAV_ATTENUATION",
			"internal_name": "Local Inertial/Gravitational Attenuation",
			"display_name_before_naming": "Unclassified Field Effect",
			"description": "Artifact exhibits local gravitational attenuation.",
			"player_namable": true,
			"technology_unlock": "experimental_field_sensor",
			"state": "unknown",
			"player_name": ""
		}
		discoveries.append(fallback)
	discovery["discovery_id"] = discoveries[0].get("discovery_id", "DISC_GRAV_ATTENUATION")
	discovery["state"] = discoveries[0].get("state", "unknown")

func _discoveries_restore_from_saved():
	_set_discovery_for_artifact()
	var saved_state: String = discovery.get("state", "unknown")
	for d in discoveries:
		var d_dict: Dictionary = d as Dictionary
		d_dict["state"] = saved_state
		d_dict["player_name"] = discovery.get("player_name", "")

func _load_scientist_data():
	scientists = []
	var paths := [
		"res://data/scientists/dr_chen.json",
		"res://data/scientists/dr_reed.json",
		"res://data/scientists/dr_vasquez.json"
	]
	for path in paths:
		var data := _load_json(path)
		if data.size() > 0:
			scientists.append(data.duplicate(true))

func _assign_helios_artifact():
	var data := _load_json("res://data/rivals/helios_artifacts.json")
	var artifacts: Array = data.get("artifacts", [])
	if artifacts.is_empty():
		helios["artifact_id"] = "H003"
		helios["artifact_name"] = "Crystalline Matrix"
		return
	var idx: int = _rng.randi() % artifacts.size()
	var chosen: Dictionary = artifacts[idx] as Dictionary
	helios["artifact_id"] = chosen.get("id", "H003")
	helios["artifact_name"] = chosen.get("display_name", "Unknown")
	helios["artifact_description"] = chosen.get("description", "")

func _reset_knowledge():
	knowledge = {
		"progress": 0,
		"state": "unknown",
		"observations": [],
		"experiment_counts": {}
	}

func _reset_discovery():
	discovery = {
		"state": "unknown",
		"player_name": "",
		"discovery_id": "DISC_GRAV_ATTENUATION"
	}

func is_experiment_unlocked(experiment_id: String) -> bool:
	var threshold: int = EXPERIMENT_UNLOCK_THRESHOLDS.get(experiment_id, 999)
	if knowledge["progress"] < threshold:
		return false
	# Per-experiment unlock thresholds from data drive (Acoustic, Laser, etc.)
	var exps := load_experiment_definitions()
	for exp in exps:
		var exp_dict: Dictionary = exp as Dictionary
		if exp_dict.get("id", "") == experiment_id:
			var per_threshold: int = exp_dict.get("unlock_threshold", 0)
			if knowledge["progress"] < per_threshold:
				return false
			var requires_tech: String = exp_dict.get("requires_tech", "")
			if not requires_tech.is_empty() and not _has_technology(requires_tech):
				return false
			return true
	return false

func _has_technology(tech_id: String) -> bool:
	match tech_id:
		"TECH_THERMAL_CONTAINMENT":
			return unlocked_technologies.has("TECH_THERMAL_CONTAINMENT")
		"TECH_GRAVITY_SENSOR":
			return unlocked_technologies.has("TECH_GRAVITY_SENSOR")
		"TECH_FIELD_STABILIZER":
			return unlocked_technologies.has("TECH_FIELD_STABILIZER")
	return false

func load_experiment_definitions() -> Array:
	var data := _load_json("res://data/experiments/experiments.json")
	return data.get("experiments", [])

func get_unlocked_experiments(all_experiments: Array) -> Array:
	var unlocked: Array = []
	for exp in all_experiments:
		var exp_dict: Dictionary = exp as Dictionary
		var exp_id: String = exp_dict.get("id", "")
		if is_experiment_unlocked(exp_id):
			unlocked.append(exp)
	return unlocked

func run_experiment(experiment_def: Dictionary, scientist: Dictionary) -> Dictionary:
	var exp_id: String = experiment_def.get("id", "")
	var cost: int = _get_experiment_cost(exp_id)
	if budget["funds"] < cost:
		push_warning("Insufficient funds for experiment: %s (need %d, have %d)" % [exp_id, cost, budget["funds"]])
		return {}

	var quality := _calculate_observation_quality(experiment_def, scientist)
	var observations := _generate_observations(experiment_def, quality)
	# Knowledge gain keeps a guaranteed base so experiments always meaningfully progress,
	# with a modest quality bonus on top (base_gain + round((quality-1)*base_gain*0.5)).
	var base_gain := int(experiment_def.get("knowledge_gain", 2))
	var knowledge_gain := base_gain + int(round((quality - 1.0) * base_gain * 0.5))
	knowledge_gain = maxi(knowledge_gain, base_gain)

	for obs in observations:
		knowledge["observations"].append(obs)

	knowledge["progress"] = mini(knowledge["progress"] + knowledge_gain, 100)

	if not knowledge["experiment_counts"].has(exp_id):
		knowledge["experiment_counts"][exp_id] = 0
	knowledge["experiment_counts"][exp_id] += 1

	# Each experiment occupies a full facility workday; this lets the funding/overhead
	# economy and the day counter meaningfully advance over a campaign (previously the
	# integer day counter silently truncated fractional additions to zero).
	elapsed_days += 1.0

	_update_knowledge_state()
	_check_secondary_discoveries(exp_id)

	var exp_record := {
		"experiment_id": exp_id,
		"experiment_name": experiment_def.get("name", "Unknown"),
		"scientist_id": scientist.get("id", ""),
		"scientist_name": scientist.get("first_name", "?") + " " + scientist.get("last_name", "?"),
		"observations": observations,
		"knowledge_gain": knowledge_gain,
		"quality": quality,
		"day": elapsed_days,
		"narrative": _generate_narrative(experiment_def, scientist, observations, quality),
		"relevant_skill": experiment_def.get("required_skills", ["observation"])[0]
	}
	experiment_history.append(exp_record)

	budget["funds"] -= cost
	budget["spent"] += cost
	_apply_daily_overhead()
	_check_funding()
	_check_budget_events()
	EventBus.budget_updated.emit(budget["funds"], budget["spent"])

	_check_incidents()
	_check_dangerous_experiment(exp_id)
	_advance_helios()
	_tick_market()
	_generate_intelligence()
	_check_market_end()

	return exp_record

func _check_dangerous_experiment(exp_id: String):
	var exps := load_experiment_definitions()
	for exp in exps:
		var exp_dict: Dictionary = exp as Dictionary
		if exp_dict.get("id", "") != exp_id:
			continue
		if not exp_dict.get("dangerous", false):
			return
		# Field stabilizer mitigates the risk of high-energy experiments.
		var base_chance: float = 0.12
		if unlocked_technologies.has("TECH_FIELD_STABILIZER"):
			base_chance = 0.04
		if _rng.randf() >= base_chance:
			return
		var incident_data := _load_json("res://data/events/incidents.json")
		var possible: Array = incident_data.get("incidents", [])
		for inc in possible:
			var inc_dict: Dictionary = inc as Dictionary
			if inc_dict.get("id", "") == "INC_EQUIPMENT_FAILURE":
				_apply_incident(inc_dict)
				break

func _calculate_observation_quality(experiment_def: Dictionary, scientist: Dictionary) -> float:
	var skills: Dictionary = scientist.get("skills", {})
	var observation_skill: float = skills.get("observation", 50)
	var curiosity: float = skills.get("curiosity", 50)
	var relevant_skill: float = 0.0
	var req_skills: Array = experiment_def.get("required_skills", [])
	for skill_name in req_skills:
		var val: float = skills.get(skill_name, 0)
		if val > relevant_skill:
			relevant_skill = val

	var quality := (relevant_skill * 0.5 + observation_skill * 0.3 + curiosity * 0.1) / 100.0

	var traits: Array = scientist.get("traits", [])
	var trait_quality_bonus := 0.0
	var critical_chance := 0.05
	for trait_name in traits:
		var effect: Dictionary = TRAIT_EFFECTS.get(trait_name, {})
		trait_quality_bonus += effect.get("quality_bonus", 0.0)
		critical_chance += effect.get("critical_bonus", 0.0)
	quality += trait_quality_bonus

	var roll: float = _rng.randf()

	if roll < critical_chance:
		quality *= 1.5
	elif roll < critical_chance + 0.05:
		quality *= 0.5
	elif roll < critical_chance + 0.10:
		quality *= 1.2
	else:
		quality += _rng.randf_range(-0.15, 0.15)

	if technology_unlocked or unlocked_technologies.has("TECH_EXPERIMENTAL_FIELD_SENSOR"):
		quality *= 1.2
	if unlocked_technologies.has("TECH_GRAVITY_SENSOR"):
		quality *= 1.1

	return clampf(quality, 0.1, 2.0)

func _generate_observations(experiment_def: Dictionary, quality: float) -> Array:
	return ObservationSimulator.generate(experiment_def, quality, _rng)

func _generate_narrative(experiment_def: Dictionary, scientist: Dictionary, observations: Array, quality: float) -> String:
	var scientist_name: String = scientist.get("first_name", "?") + " " + scientist.get("last_name", "?")
	var exp_name: String = experiment_def.get("name", "experiment")
	var templates := [
		"{scientist} conducted {experiment} and recorded the following: {obs}",
		"{scientist} reported: {obs}",
		"During {experiment}, {scientist} observed: {obs}",
		"{scientist} performed {experiment}. Result: {obs}"
	]
	var template: String = templates[_rng.randi() % templates.size()]
	var obs_text: String = "No significant findings."
	if observations.size() > 0:
		var first_obs: Dictionary = observations[0] as Dictionary
		obs_text = first_obs.get("content", "No significant findings.")
	return template.format({
		"scientist": scientist_name,
		"experiment": exp_name,
		"obs": obs_text
	})

func _update_knowledge_state():
	var progress: int = knowledge["progress"]
	if progress >= CONFIRMED_THRESHOLD and knowledge["state"] != "confirmed":
		knowledge["state"] = "confirmed"
		discovery["state"] = "confirmed"
		for d in discoveries:
			var d_dict: Dictionary = d as Dictionary
			d_dict["state"] = "confirmed"
			var unlock: String = d_dict.get("technology_unlock", "")
			if not unlock.is_empty():
				_unlock_technology_for_discovery(d_dict.get("discovery_id", ""), unlock)
		_award_discovery_market()
		if not helios["discovered_first"] and helios["progress"] < 100:
			pass
		else:
			helios["discovered_first"] = true
		EventBus.discovery_confirmed.emit(discovery["discovery_id"])
	elif progress >= SUSPECTED_THRESHOLD and knowledge["state"] == "unknown":
		knowledge["state"] = "suspected"
		discovery["state"] = "suspected"
		for d in discoveries:
			var d_dict: Dictionary = d as Dictionary
			if d_dict["state"] == "unknown":
				d_dict["state"] = "suspected"
		EventBus.discovery_suspected.emit(discovery["discovery_id"])

	EventBus.knowledge_updated.emit(knowledge["progress"], knowledge["state"])

func _unlock_technology_for_discovery(discovery_id: String, tech_key: String):
	var tech_map := {
		"experimental_field_sensor": "TECH_EXPERIMENTAL_FIELD_SENSOR",
		"thermal_containment": "TECH_THERMAL_CONTAINMENT",
		"gravity_sensor": "TECH_GRAVITY_SENSOR",
		"field_stabilizer": "TECH_FIELD_STABILIZER"
	}
	var tech_id: String = tech_map.get(tech_key, "")
	if tech_id.is_empty() or tech_id in unlocked_technologies:
		return
	unlocked_technologies.append(tech_id)
	if tech_id == "TECH_EXPERIMENTAL_FIELD_SENSOR":
		technology_unlocked = true
	var tech_def := _get_technology_definition(tech_id)
	var tech_name: String = tech_def.get("name", "Unknown Technology")
	if discovery_id not in confirmed_discoveries:
		confirmed_discoveries.append(discovery_id)
	EventBus.technology_unlocked.emit(tech_id, tech_name)

func _get_technology_definition(tech_id: String) -> Dictionary:
	var data := _load_json("res://data/technologies/technologies.json")
	var techs: Array = data.get("technologies", [])
	for t in techs:
		var t_dict: Dictionary = t as Dictionary
		if t_dict.get("id", "") == tech_id:
			return t_dict
	return {}

func _check_secondary_discoveries(exp_id: String):
	# Evidence-driven (simulation-authoritative): secondary discoveries are promoted by
	# tallying the discovery_hint tags on observations accumulated during experiments.
	for d in discoveries:
		var d_dict: Dictionary = d as Dictionary
		if d_dict["state"] == "confirmed":
			continue
		var did: String = d_dict.get("discovery_id", "")
		var hint: String = _discovery_hint_for(did)
		if hint.is_empty():
			continue
		var evidence_count := 0
		var distinct_types := {}
		var high_confidence_count := 0
		for obs in knowledge["observations"]:
			var o: Dictionary = obs as Dictionary
			if o.get("discovery_hint", "") != hint:
				continue
			evidence_count += 1
			distinct_types[o.get("type", "?")] = true
			if o.get("confidence", "low") == "high":
				high_confidence_count += 1

		if d_dict["state"] == "unknown" and evidence_count >= 2:
			d_dict["state"] = "suspected"
			EventBus.discovery_suspected.emit(did)
		elif d_dict["state"] == "suspected":
			var confirmed := evidence_count >= 4
			if not confirmed and evidence_count >= 2 and distinct_types.size() >= 2 and high_confidence_count >= 1:
				confirmed = true
			if confirmed:
				d_dict["state"] = "confirmed"
				var unlock: String = d_dict.get("technology_unlock", "")
				if not unlock.is_empty():
					_unlock_technology_for_discovery(did, unlock)
				_award_discovery_market()
				EventBus.discovery_confirmed.emit(did)

func _discovery_hint_for(discovery_id: String) -> String:
	match discovery_id:
		"DISC_ENERGY_ABSORPTION":
			return "energy_absorption"
		"DISC_GRAV_ATTENUATION":
			return "grav_attenuation"
		"DISC_GRAV_AMPLIFICATION":
			return "grav_amplification"
		"DISC_GRAV_NULLIFICATION":
			return "grav_nullification"
		_:
			return ""

func name_discovery(player_name: String):
	discovery["player_name"] = player_name
	EventBus.discovery_named.emit(discovery["discovery_id"], player_name)
	if not technology_unlocked:
		technology_unlocked = true
		EventBus.technology_unlocked.emit("TECH_EXPERIMENTAL_FIELD_SENSOR", "Experimental Field Sensor")

func _get_experiment_cost(experiment_id: String) -> int:
	var data := _load_json("res://data/resources/budget.json")
	var costs: Dictionary = data.get("experiment_costs", {})
	return costs.get(experiment_id, 300)

func _apply_daily_overhead():
	# Facility running costs. The budget already charges experiment costs individually;
	# overhead is a separate daily drain from budget.json. This makes the lean budget
	# pressure the design intends actually bite over a campaign.
	var data := _load_json("res://data/resources/budget.json")
	var overhead: int = data.get("daily_overhead", 150)
	budget["funds"] -= overhead
	budget["spent"] += overhead

func _check_funding():
	var data := _load_json("res://data/resources/budget.json")
	var intervals: Array = data.get("funding_intervals", [])
	while budget["next_funding_index"] < intervals.size():
		var interval: Dictionary = intervals[budget["next_funding_index"]] as Dictionary
		if elapsed_days >= interval.get("day", 999):
			var amount: int = interval.get("amount", 0)
			budget["funds"] += amount
			budget["funding_received"] += amount
			budget["next_funding_index"] += 1
		else:
			break

func _check_budget_events():
	var data := _load_json("res://data/resources/budget.json")
	var events: Array = data.get("budget_events", [])
	for event in events:
		var event_dict: Dictionary = event as Dictionary
		var trigger: String = event_dict.get("trigger", "")
		if trigger in budget["events_received"]:
			continue
		var awarded := false
		match trigger:
			"discovery_suspected":
				if knowledge["state"] == "suspected":
					awarded = true
			"helios_60":
				if helios["progress"] >= 60:
					awarded = true
		if awarded:
			var amount: int = event_dict.get("amount", 0)
			budget["funds"] += amount
			budget["funding_received"] += amount
			budget["events_received"].append(trigger)

func can_afford_experiment(experiment_id: String) -> bool:
	return budget["funds"] >= _get_experiment_cost(experiment_id)

func _check_incidents():
	if incident_cooldown > 0:
		incident_cooldown -= 1
		return

	var data := _load_json("res://data/events/incidents.json")
	var possible: Array = data.get("incidents", [])
	var max_incidents: int = data.get("max_incidents_per_campaign", 8)
	if incidents.size() >= max_incidents:
		return

	var state_filter: String = knowledge["state"]
	for inc in possible:
		var inc_dict: Dictionary = inc as Dictionary
		var required_state: String = inc_dict.get("knowledge_state_required", "unknown")
		if state_filter != required_state and required_state != "any":
			continue
		var chance: float = inc_dict.get("trigger_chance", 0.0)
		if unlocked_technologies.has("TECH_THERMAL_CONTAINMENT"):
			chance *= 0.5
		if _rng.randf() < chance:
			_apply_incident(inc_dict)
			break

func _apply_incident(incident: Dictionary):
	var inc_id: String = incident.get("id", "")
	var base_severity: String = incident.get("severity", "minor")
	var effects: Dictionary = incident.get("effects", {}).duplicate(true)
	var mitigated := false

	var stabilizer: bool = unlocked_technologies.has("TECH_FIELD_STABILIZER")
	if stabilizer:
		mitigated = true
		effects["budget_cost"] = int(effects.get("budget_cost", 0) * 0.5)
		effects["days_lost"] = int(effects.get("days_lost", 0) * 0.5)
		effects["observation_quality_reduction"] = effects.get("observation_quality_reduction", 0.0) * 0.5
		var base_sev_index: int = SEVERITY_ORDER.find(base_severity)
		if base_sev_index > 0:
			base_severity = SEVERITY_ORDER[base_sev_index - 1]

	var record := {
		"id": inc_id,
		"name": incident.get("name", "Unknown Incident"),
		"description": incident.get("description", ""),
		"severity": base_severity,
		"day": elapsed_days,
		"mitigated": mitigated
	}
	incidents.append(record)
	budget["funds"] -= effects.get("budget_cost", 0)
	elapsed_days += effects.get("days_lost", 0)
	var discovery_bonus: float = incident.get("discovery_chance_increase", 0.0)
	if discovery_bonus > 0 and knowledge["progress"] < CONFIRMED_THRESHOLD:
		knowledge["progress"] = mini(knowledge["progress"] + int(discovery_bonus * 100), CONFIRMED_THRESHOLD)
	incident_cooldown = 5
	EventBus.incident_occurred.emit(record)

func resolve_incident(incident_id: String):
	for i in range(active_incidents.size()):
		if active_incidents[i].get("id", "") == incident_id:
			active_incidents.remove_at(i)
			EventBus.incident_resolved.emit(incident_id)
			break

func _advance_helios():
	if knowledge["state"] == "confirmed":
		return
	var base_rate := 1.5
	var variation := _rng.randf_range(-0.5, 1.0)
	var progress_factor: float = knowledge["progress"] / 100.0
	helios["progress"] = int(helios["progress"] + (base_rate + variation) * (0.5 + progress_factor * 0.5))
	helios["progress"] = maxi(helios["progress"], 0)

# --- Phase 1 market model ---
func get_majority_target() -> float:
	return float(difficulty.get("majority_target", 51.0))

func get_player_market() -> float:
	return player_market

func get_rival_market(rival_id: String) -> float:
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("id", "") == rival_id:
			return float(rd.get("share", 0))
	return 0.0

func _tick_market():
	# Player earns a small daily share from sustained lab work (not from buying).
	var player_gain: float = float(difficulty.get("player_experiment_gain", 0.55))
	player_market += player_gain

	# Owned subsidiaries contribute their (outcome-scaled) research to our share.
	_tick_owned_companies()
	# Rolling offers expire or get grabbed; wildcards can implode or exit.
	_tick_company_offers()
	_tick_rival_instability()

	# Rivals advance their market share on their own timeline.
	var lead := 0.0
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			continue
		var adv: float = float(rd.get("daily_advance", 0.5))
		var variation: float = _rng.randf_range(-0.3, 0.5)
		var new_share: float = float(rd.get("share", 0)) + maxf(adv + variation, 0.1)
		rd["share"] = new_share
		if rd.get("id", "") == "RIV_HELIOS":
			lead = new_share
	_sync_helios_rival()
	_helios_market_from_lead(lead)
	EventBus.market_updated.emit(player_market, rivals)

func _helios_market_from_lead(lead_share: float) -> void:
	helios["market_share"] = lead_share

func _award_discovery_market():
	var gain: float = float(difficulty.get("player_discovery_gain", 11.0))
	player_market += gain

func _check_market_end() -> bool:
	if not game_over.is_empty():
		return true
	var majority: float = get_majority_target()
	if _check_domination():
		game_over = {
			"won": true,
			"reason": "domination",
			"player_market": player_market,
			"dominant_rival": "",
			"type": "monopoly"
		}
	elif player_market >= majority:
		game_over = {
			"won": true,
			"reason": "market_majority",
			"player_market": player_market,
			"dominant_rival": _leading_rival_name(),
			"type": "market_leader"
		}
	elif _any_rival_majority(majority):
		game_over = {
			"won": false,
			"reason": "rival_majority",
			"player_market": player_market,
			"dominant_rival": _leading_rival_name(),
			"type": "absorbed"
		}
	if not game_over.is_empty():
		EventBus.game_over.emit(game_over)
		return true
	return false

func _any_rival_majority(majority: float) -> bool:
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			continue
		if float(rd.get("share", 0)) >= majority:
			return true
	return false

func _leading_rival_name() -> String:
	var best_name := "HELIOS Research Authority"
	var best_share := -1.0
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		var share: float = float(rd.get("share", 0))
		if share > best_share:
			best_share = share
			best_name = rd.get("name", "Rival")
	return best_name

# --- Phase 2 acquisitions + domination ---
func _spawn_company_offers():
	var data: Dictionary = _load_json("res://data/acquisitions/companies.json")
	var defs: Array = data.get("companies", [])
	company_offers = []
	for cdef in defs:
		var cd: Dictionary = cdef as Dictionary
		var true_value: float = float(cd.get("true_value", 3000.0))
		var noise: float = _rng.randf_range(
			float(cd.get("price_noise_min", 0.6)),
			float(cd.get("price_noise_max", 1.6))
		)
		company_offers.append({
			"id": cd.get("id", ""),
			"name": cd.get("name", "Company"),
			"flavor": cd.get("flavor", ""),
			"true_value": true_value,
			"listed_price": int(round(true_value * noise)),
			"techs": (cd.get("techs", []) as Array).duplicate(),
			"daily_research": float(cd.get("daily_research", 0.25)),
			"expires_day": elapsed_days + float(cd.get("deadline_days", 35)),
			"status": "offered",
			"dd_level": 0,
			"dd_estimate": 0.0,
			"dd_error": 0.0
		})

func get_company_offer(company_id: String) -> Dictionary:
	for o in company_offers:
		var od: Dictionary = o as Dictionary
		if od.get("id", "") == company_id:
			return od
	return {}

func perform_due_diligence(company_id: String) -> Dictionary:
	var offer: Dictionary = get_company_offer(company_id)
	if offer.is_empty():
		return {"ok": false, "reason": "no_offer"}
	if offer.get("status", "") != "offered":
		return {"ok": false, "reason": "not_offered"}
	var level: int = int(offer.get("dd_level", 0))
	if level >= 2:
		return {"ok": false, "reason": "max_level"}
	var cost: int = int(ACQ_DD_COSTS[level])
	if int(budget.get("funds", 0)) < cost:
		return {"ok": false, "reason": "insufficient_funds"}
	budget["funds"] = int(budget.get("funds", 0)) - cost
	budget["spent"] = int(budget.get("spent", 0)) + cost
	var err: float = float(ACQ_DD_ERROR[level])
	var true_value: float = float(offer.get("true_value", 0.0))
	var estimate: float = true_value * (1.0 + _rng.randf_range(-err, err))
	offer["dd_level"] = level + 1
	offer["dd_estimate"] = estimate
	offer["dd_error"] = err
	EventBus.budget_updated.emit(budget["funds"], budget["spent"])
	return {"ok": true, "level": level + 1, "estimate": estimate, "error": err, "cost": cost}

func _classify_deal(price_paid: float, true_value: float) -> String:
	if true_value <= 0.0:
		return "fair"
	var ratio: float = price_paid / true_value
	if ratio <= 0.85:
		return "steal"
	if ratio >= 1.20:
		return "lemon"
	return "fair"

func _deal_multiplier(outcome: String) -> float:
	if outcome == "steal":
		return 1.5
	if outcome == "lemon":
		return 0.25
	return 1.0

func acquire_company(company_id: String) -> Dictionary:
	var offer: Dictionary = get_company_offer(company_id)
	if offer.is_empty():
		return {"ok": false, "reason": "no_offer"}
	if offer.get("status", "") != "offered":
		return {"ok": false, "reason": "not_offered"}
	var price: int = int(offer.get("listed_price", 0))
	if int(budget.get("funds", 0)) < price:
		return {"ok": false, "reason": "insufficient_funds"}
	budget["funds"] = int(budget.get("funds", 0)) - price
	budget["spent"] = int(budget.get("spent", 0)) + price
	var outcome: String = _classify_deal(float(price), float(offer.get("true_value", 0.0)))
	offer["status"] = "acquired"
	offer["outcome"] = outcome
	var techs: Array = (offer.get("techs", []) as Array).duplicate()
	var owned := {
		"id": offer.get("id", ""),
		"name": offer.get("name", ""),
		"outcome": outcome,
		"mult": _deal_multiplier(outcome),
		"daily_research": float(offer.get("daily_research", 0.25)),
		"techs_remaining": techs
	}
	owned_companies.append(owned)
	_unlock_next_owned_tech(owned)
	company_offers.erase(offer)
	EventBus.budget_updated.emit(budget["funds"], budget["spent"])
	EventBus.company_acquired.emit(company_id, outcome)
	return {"ok": true, "outcome": outcome, "price": price}

func _unlock_next_owned_tech(owned: Dictionary):
	var remaining: Array = owned.get("techs_remaining", [])
	while not remaining.is_empty():
		var key: String = str(remaining[0])
		remaining.remove_at(0)
		var before: int = unlocked_technologies.size()
		_unlock_technology_for_discovery("ACQ_%s" % owned.get("id", ""), key)
		if unlocked_technologies.size() > before:
			return

func _tick_owned_companies():
	for o in owned_companies:
		var od: Dictionary = o as Dictionary
		player_market += float(od.get("daily_research", 0.25)) * float(od.get("mult", 1.0))
		if not (od.get("techs_remaining", []) as Array).is_empty():
			if _rng.randf() < 0.15:
				_unlock_next_owned_tech(od)

func _tick_company_offers():
	for o in company_offers.duplicate():
		var od: Dictionary = o as Dictionary
		if od.get("status", "") != "offered":
			continue
		if elapsed_days < float(od.get("expires_day", 0.0)):
			continue
		if _rng.randf() < 0.5:
			var grabber: Dictionary = _lowest_active_rival()
			if not grabber.is_empty():
				grabber["share"] = float(grabber.get("share", 0)) + ACQ_GRAB_BUMP
				od["status"] = "grabbed"
				od["grabbed_by"] = grabber.get("id", "")
				EventBus.offer_closed.emit(od.get("id", ""), "grabbed")
				continue
		od["status"] = "expired"
		EventBus.offer_closed.emit(od.get("id", ""), "expired")

func _lowest_active_rival() -> Dictionary:
	var best := {}
	var best_share := 1e9
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			continue
		var share: float = float(rd.get("share", 0))
		if share < best_share:
			best_share = share
			best = rd
	return best

func _tick_rival_instability():
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			continue
		if rd.get("disposition", "") != "wildcard":
			continue
		if _rng.randf() < 0.04:
			rd["share"] = float(rd.get("share", 0)) * 0.5
			rd["implosions"] = int(rd.get("implosions", 0)) + 1
			if float(rd.get("share", 0)) < ACQ_EXIT_SHARE:
				if int(rd.get("implosions", 0)) >= 2:
					rd["status"] = "bankrupt"
				else:
					rd["status"] = "exited"
				rd["share"] = 0.0

func get_rival_buyout_price(rival_id: String) -> int:
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("id", "") == rival_id:
			var per: float = 350.0
			return int(ceil(float(rd.get("share", 0)) * per))
	return 0

func buy_out_rival(rival_id: String) -> Dictionary:
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("id", "") != rival_id:
			continue
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			return {"ok": false, "reason": "not_active"}
		var price: int = get_rival_buyout_price(rival_id)
		if int(budget.get("funds", 0)) < price:
			return {"ok": false, "reason": "insufficient_funds"}
		var old_share: float = float(rd.get("share", 0))
		budget["funds"] = int(budget.get("funds", 0)) - price
		budget["spent"] = int(budget.get("spent", 0)) + price
		rd["acquired_by_player"] = true
		rd["status"] = "acquired"
		rd["share"] = 0.0
		player_market += minf(ACQ_BUYOUT_CAP, old_share * 0.15)
		_sync_helios_rival()
		EventBus.budget_updated.emit(budget["funds"], budget["spent"])
		EventBus.rival_acquired.emit(rival_id)
		_check_market_end()
		return {"ok": true, "price": price}
	return {"ok": false, "reason": "no_rival"}

func _rival_crushed(rd: Dictionary) -> bool:
	if rd.get("acquired_by_player", false):
		return true
	if rd.get("status", "active") != "active":
		return true
	return float(rd.get("share", 0)) <= player_market * 0.5

func _check_domination() -> bool:
	if rivals.is_empty():
		return false
	for r in rivals:
		if not _rival_crushed(r as Dictionary):
			return false
	return true

func get_domination_progress() -> Dictionary:
	var details: Array = []
	var crushed := 0
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		var how := "contesting"
		if rd.get("acquired_by_player", false):
			how = "acquired"
		elif rd.get("status", "active") == "bankrupt":
			how = "bankrupt"
		elif rd.get("status", "active") == "exited":
			how = "exited"
		elif float(rd.get("share", 0)) <= player_market * 0.5:
			how = "outgrown"
		if how != "contesting":
			crushed += 1
		details.append({"id": rd.get("id", ""), "name": rd.get("name", ""), "how": how})
	return {"crushed": crushed, "total": rivals.size(), "details": details}

func is_game_over() -> bool:
	return not game_over.is_empty()

func get_game_over() -> Dictionary:
	return game_over.duplicate(true)

func _generate_intelligence():
	var intel_data := _load_json("res://data/rivals/helios_intelligences.json")
	var reports: Array = intel_data.get("intelligences", [])

	for threshold in HELIOS_THRESHOLDS:
		if helios["progress"] >= threshold and threshold not in helios["thresholds_hit"]:
			helios["thresholds_hit"].append(threshold)
			var tier_idx: int = HELIOS_THRESHOLDS[threshold]
			if tier_idx < reports.size():
				var tier: Dictionary = reports[tier_idx] as Dictionary
				var tier_reports: Array = tier.get("reports", [])
				if tier_reports.size() > 0:
					var report_text: String = tier_reports[_rng.randi() % tier_reports.size()]
					var intel := {
						"day": elapsed_days,
						"threshold": threshold,
						"text": report_text,
						"helios_progress": helios["progress"]
					}
					intelligence_reports.append(intel)
					EventBus.rival_progressed.emit(helios["progress"], report_text)
			break

func get_save_data() -> Dictionary:
	_save_current_artifact_data()
	return {
		"campaign_id": campaign_id,
		"seed": seed,
		"elapsed_days": elapsed_days,
		"organization": organization,
		"artifact_id": artifact.get("id", "J001"),
		"selected_artifact_index": selected_artifact_index,
		"per_artifact_data": per_artifact_data,
		"scientists": scientists,
		"knowledge": knowledge,
		"discovery": discovery,
		"discoveries": discoveries,
		"confirmed_discoveries": confirmed_discoveries,
		"unlocked_technologies": unlocked_technologies,
		"technology_unlocked": technology_unlocked,
		"helios": helios,
		"experiment_history": experiment_history,
		"intelligence_reports": intelligence_reports,
		"last_intel_threshold": last_intel_threshold,
		"incidents": incidents,
		"incident_cooldown": incident_cooldown,
		"budget": budget,
		"difficulty": difficulty,
		"player_market": player_market,
		"rivals": rivals,
		"game_over": game_over,
		"company_offers": company_offers,
		"owned_companies": owned_companies
	}

func _save_current_artifact_data():
	var art_id: String = artifact.get("id", "")
	if not art_id.is_empty():
		per_artifact_data[art_id] = {
			"knowledge": knowledge.duplicate(true),
			"discovery": discovery.duplicate(true),
			"discoveries": discoveries.duplicate(true),
			"experiment_history": experiment_history.duplicate(),
			"intelligence_reports": intelligence_reports.duplicate()
		}

func load_save_data(data: Dictionary):
	campaign_id = data.get("campaign_id", "")
	seed = data.get("seed", 0)
	elapsed_days = data.get("elapsed_days", 0)
	organization = data.get("organization", {})
	per_artifact_data = data.get("per_artifact_data", {})
	_load_artifact_data()
	selected_artifact_index = data.get("selected_artifact_index", 0)
	if selected_artifact_index < available_artifacts.size():
		artifact = available_artifacts[selected_artifact_index]
	scientists = data.get("scientists", [])
	if scientists.is_empty():
		_load_scientist_data()
	knowledge = data.get("knowledge", {
		"progress": 0, "state": "unknown", "observations": [], "experiment_counts": {}
	})
	discovery = data.get("discovery", {
		"state": "unknown", "player_name": "", "discovery_id": "DISC_GRAV_ATTENUATION"
	})
	_set_discovery_for_artifact()
	var saved_disc: Array = data.get("discoveries", [])
	if not saved_disc.is_empty():
		discoveries = saved_disc.duplicate(true)
	else:
		_discoveries_restore_from_saved()
	confirmed_discoveries = data.get("confirmed_discoveries", [])
	unlocked_technologies = data.get("unlocked_technologies", [])
	technology_unlocked = data.get("technology_unlocked", false)
	helios = data.get("helios", {"progress": 0, "artifact_id": "", "artifact_name": "", "thresholds_hit": [], "discovered_first": false})
	if helios.get("artifact_id", "").is_empty():
		_assign_helios_artifact()
	experiment_history = data.get("experiment_history", [])
	intelligence_reports = data.get("intelligence_reports", [])
	last_intel_threshold = data.get("last_intel_threshold", 0)
	incidents = data.get("incidents", [])
	incident_cooldown = data.get("incident_cooldown", 0)
	budget = data.get("budget", {"funds": 10000, "spent": 0, "funding_received": 0, "next_funding_index": 0, "events_received": []})
	difficulty = data.get("difficulty", DIFFICULTIES["normal"])
	if difficulty.is_empty():
		difficulty = _resolve_difficulty("normal")
	player_market = data.get("player_market", 0.0)
	rivals = data.get("rivals", [])
	if rivals.is_empty():
		_spawn_rivals()
	game_over = data.get("game_over", {})
	company_offers = data.get("company_offers", [])
	owned_companies = data.get("owned_companies", [])
	if company_offers.is_empty() and owned_companies.is_empty():
		_spawn_company_offers()
	_rng.seed = seed
	EventBus.campaign_loaded.emit()

func _generate_id() -> String:
	return "%08x-%04x-%04x-%04x-%012x" % [
		_rng.randi(), _rng.randi() % 0xFFFF, _rng.randi() % 0xFFFF,
		_rng.randi() % 0xFFFF, _rng.randi() % 0xFFFFFFFFFFFF
	]

func get_scientist_display(scientist: Dictionary) -> String:
	return "%s %s (%s)" % [
		scientist.get("first_name", "?"),
		scientist.get("last_name", "?"),
		scientist.get("primary_specialty", "unknown").replace("_", " ").capitalize()
	]

func get_skills_display(scientist: Dictionary) -> String:
	var skills: Dictionary = scientist.get("skills", {})
	var parts: PackedStringArray = []
	for key in ["physics", "engineering", "observation", "curiosity"]:
		parts.append("%s: %d" % [key.capitalize(), skills.get(key, 0)])
	return " | ".join(parts)
