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
const TECH_KEY_MAP := {
	"experimental_field_sensor": "TECH_EXPERIMENTAL_FIELD_SENSOR",
	"thermal_containment": "TECH_THERMAL_CONTAINMENT",
	"gravity_sensor": "TECH_GRAVITY_SENSOR",
	"field_stabilizer": "TECH_FIELD_STABILIZER",
	"resonance_amplifier": "TECH_RESONANCE_AMPLIFIER",
	"cryo_lattice": "TECH_CRYO_LATTICE",
	"deep_field_probe": "TECH_DEEP_FIELD_PROBE"
}
var company_offers: Array = []
var owned_companies: Array = []

# --- Phase 3 (0.3): contracts + world events + espionage + legacy ---
var contract_deck: Array = []
var pending_offer: Dictionary = {}
var active_contract: Dictionary = {}
var completed_contracts: Array = []
var next_offer_day: float = 0.0
var event_schedule: Array = []
var active_event: Dictionary = {}
var events_seen: Array = []
var esp_risk: float = 0.0
var esp_cover: float = 0.0
var run_badges: Array = []

# --- Phase 5 (0.5): facilities + enemy ops + continue + expert ---
var facilities_owned: Array = []
var player_sabotaged_until: float = 0.0
var continued: bool = false
var bonus_target: float = 0.0

# --- Phase 6 (0.6): story arcs + crises + horror ---
var story_log: Array = []
var fired_beats: Array = []
var active_crises: Array = []
var gore_setting: int = -1
var pending_memorial: String = ""

# --- Phase 7 (0.7): security + military alignment ---
var military_ties: float = 0.0

const DIFFICULTIES := {
	"easy": {
		"id": "easy", "display_name": "Easy",
		"majority_target": 44.0, "rival_multiplier": 0.7,
		"helios_start_share": 8.0, "helios_daily_base": 0.55,
		"player_experiment_gain": 0.75, "player_discovery_gain": 13.0,
		"player_start_budget": 12500
	},
	"normal": {
		"id": "normal", "display_name": "Normal",
		"majority_target": 52.0, "rival_multiplier": 1.0,
		"helios_start_share": 12.0, "helios_daily_base": 0.85,
		"player_experiment_gain": 0.7, "player_discovery_gain": 12.0,
		"player_start_budget": 10000
	},
	"hard": {
		"id": "hard", "display_name": "Hard",
		"majority_target": 58.0, "rival_multiplier": 1.1,
		"helios_start_share": 16.0, "helios_daily_base": 1.1,
		"player_experiment_gain": 0.6, "player_discovery_gain": 12.0,
		"player_start_budget": 9000
	},
	"expert": {
		"id": "expert", "display_name": "Expert",
		"majority_target": 62.0, "rival_multiplier": 1.35,
		"helios_start_share": 20.0, "helios_daily_base": 1.2,
		"player_experiment_gain": 0.55, "player_discovery_gain": 11.0,
		"player_start_budget": 7000,
		"science_locked": true
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

func initialize_new_campaign(org: Dictionary, difficulty_id: String = "normal", p_seed: int = -1):
	if p_seed >= 0:
		_rng.seed = p_seed
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
	contract_deck = []
	pending_offer = {}
	active_contract = {}
	completed_contracts = []
	_spawn_contracts()
	event_schedule = []
	active_event = {}
	events_seen = []
	_schedule_events()
	esp_risk = 0.0
	esp_cover = 0.0
	run_badges = []
	facilities_owned = []
	player_sabotaged_until = 0.0
	continued = false
	bonus_target = 0.0
	story_log = []
	fired_beats = []
	active_crises = []
	pending_memorial = ""
	military_ties = 0.0
	_log_scientist_intros()
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
			"implosions": 0,
			"director": rd.get("director", ""),
			"taunts": (rd.get("taunts", []) as Array).duplicate(),
			"milestones_hit": []
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
		"res://data/artifacts/j003.json",
		"res://data/artifacts/j004.json",
		"res://data/artifacts/j005.json",
		"res://data/artifacts/j006.json"
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
	if _living_scientists().is_empty():
		_staff_wipe_defeat()
		return {}
	var cost: int = _get_experiment_cost(exp_id)
	if scientist.get("status", "ACTIVE") == "DECEASED":
		push_warning("Cannot assign a deceased scientist: %s" % scientist.get("id", "?"))
		return {}
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
	if has_facility("FAC_LAB"):
		knowledge_gain += 1
	if elapsed_days < player_sabotaged_until:
		knowledge_gain = maxi(int(knowledge_gain / 2), 1)

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
	_fire_story_beats_for_state()

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
		_fire_story_beat(artifact.get("id", ""), "danger")
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
	if scientist.get("status", "ACTIVE") == "INJURED":
		quality *= 0.7

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
		award_badge("first_doubt")
		for d in discoveries:
			var d_dict: Dictionary = d as Dictionary
			if d_dict["state"] == "unknown":
				d_dict["state"] = "suspected"
		EventBus.discovery_suspected.emit(discovery["discovery_id"])

	EventBus.knowledge_updated.emit(knowledge["progress"], knowledge["state"])

func _unlock_technology_for_discovery(discovery_id: String, tech_key: String):
	var tech_id: String = TECH_KEY_MAP.get(tech_key, "")
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
		if has_facility("FAC_SHIELD"):
			chance *= 0.5
		chance *= 1.0 - get_security() / 200.0
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
		"graphic_description": incident.get("graphic_description", ""),
		"severity": base_severity,
		"day": elapsed_days,
		"mitigated": mitigated
	}
	incidents.append(record)
	var involved: String = _pick_involved_scientist()
	record["scientist_id"] = involved
	record["reaction"] = _scientist_reaction(involved, base_severity)
	if not involved.is_empty():
		for s in scientists:
			var sd0: Dictionary = s as Dictionary
			if sd0.get("id", "") == involved:
				sd0["stress"] = mini(int(sd0.get("stress", 0)) + 10, 100)
	var casualty: int = int(incident.get("casualty", 0))
	if casualty > 0 and not involved.is_empty():
		_harm_scientist(involved, casualty, "in %s" % record.get("name", "the incident"))
	_maybe_spawn_crisis(record, incident)
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
	return float(difficulty.get("majority_target", 51.0)) + bonus_target

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
	# Contracts progress on workdays; world events tick; heat cools if you lie low.
	_tick_contracts()
	_tick_events()
	esp_risk = maxf(esp_risk - 2.0, 0.0)
	if has_facility("FAC_DESK"):
		player_market += 0.25
	_tick_enemy_ops()
	_tick_consolidation()
	_tick_crises()

	# Rivals advance their market share on their own timeline.
	var lead := 0.0
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			continue
		var adv: float = float(rd.get("daily_advance", 0.5))
		if float(rd.get("sabotaged_until", 0.0)) > elapsed_days:
			adv *= 0.5
		adv *= _event_rival_mult()
		var variation: float = _rng.randf_range(-0.3, 0.5)
		var new_share: float = float(rd.get("share", 0)) + maxf(adv + variation, 0.1)
		rd["share"] = new_share
		_check_rival_taunt(rd)
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
	elif _check_scientific_win():
		game_over = {
			"won": true,
			"reason": "scientific",
			"player_market": player_market,
			"dominant_rival": _leading_rival_name(),
			"type": "researcher"
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
		_record_legacy()
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
		if float(cd.get("available_from_day", 0.0)) > elapsed_days:
			continue
		company_offers.append(_make_company_offer(cd))

func _make_company_offer(cd: Dictionary) -> Dictionary:
	var true_value: float = float(cd.get("true_value", 3000.0))
	var noise: float = _rng.randf_range(
		float(cd.get("price_noise_min", 0.6)),
		float(cd.get("price_noise_max", 1.6))
	)
	return {
		"id": cd.get("id", ""),
		"name": cd.get("name", ""),
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
	}

func _spawn_due_company_offers():
	var known := {}
	for o in company_offers:
		known[(o as Dictionary).get("id", "")] = true
	for oc in owned_companies:
		known[(oc as Dictionary).get("id", "")] = true
	var data: Dictionary = _load_json("res://data/acquisitions/companies.json")
	for cdef in data.get("companies", []):
		var cd: Dictionary = cdef as Dictionary
		if known.has(cd.get("id", "")):
			continue
		if float(cd.get("available_from_day", 0.0)) > elapsed_days:
			continue
		company_offers.append(_make_company_offer(cd))

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
	if has_facility("FAC_SCANNER"):
		cost = maxi(int(cost / 2), 1)
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
	if outcome == "steal":
		award_badge("bargain_hunter")
	if int(offer.get("dd_level", 0)) >= 2 and outcome != "lemon":
		award_badge("dd_pro")
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
	_spawn_due_company_offers()
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
			return int(ceil(float(rd.get("share", 0)) * per * _mil_discount()))
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
	return float(rd.get("share", 0)) <= player_market * 0.4

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
		elif rd.get("status", "active") == "acquired":
			how = "absorbed"
		elif rd.get("status", "active") == "bankrupt":
			how = "bankrupt"
		elif rd.get("status", "active") == "exited":
			how = "exited"
		elif float(rd.get("share", 0)) <= player_market * 0.4:
			how = "outgrown"
		if how != "contesting":
			crushed += 1
		details.append({"id": rd.get("id", ""), "name": rd.get("name", ""), "how": how})
	return {"crushed": crushed, "total": rivals.size(), "details": details}

# --- Phase 7 security + military alignment ---
func get_security() -> float:
	var sec := 20.0
	if has_facility("FAC_GARRISON"):
		sec += 30.0
	return sec

func _mil_discount() -> float:
	if military_ties >= 75.0:
		return 0.8
	if military_ties >= 50.0:
		return 0.9
	return 1.0

func facility_price(facility_id: String) -> int:
	var fdef: Dictionary = _facility_def(facility_id)
	return int(round(float(fdef.get("cost", 0)) * _mil_discount()))

# --- Phase 5 facilities: one-time builds, permanent edges ---
func _facility_def(facility_id: String) -> Dictionary:
	var data: Dictionary = _load_json("res://data/facilities/facilities.json")
	for fdef in data.get("facilities", []):
		var fd: Dictionary = fdef as Dictionary
		if fd.get("id", "") == facility_id:
			return fd
	return {}

func has_facility(facility_id: String) -> bool:
	return facility_id in facilities_owned

func buy_facility(facility_id: String) -> Dictionary:
	if has_facility(facility_id):
		return {"ok": false, "reason": "owned"}
	var fdef: Dictionary = _facility_def(facility_id)
	if fdef.is_empty():
		return {"ok": false, "reason": "no_def"}
	var cost: int = facility_price(facility_id)
	if int(budget.get("funds", 0)) < cost:
		return {"ok": false, "reason": "insufficient_funds"}
	budget["funds"] = int(budget.get("funds", 0)) - cost
	budget["spent"] = int(budget.get("spent", 0)) + cost
	facilities_owned.append(facility_id)
	if facility_id == "FAC_INTEL":
		esp_cover = minf(esp_cover + 15.0, 50.0)
		EventBus.espionage_updated.emit()
	EventBus.budget_updated.emit(budget["funds"], budget["spent"])
	return {"ok": true, "cost": cost}

# --- Phase 5 enemy ops: aggressive rivals and wildcards hit back ---
func _enemy_op_chance(rd: Dictionary) -> float:
	var disp: String = rd.get("disposition", "")
	var base := 0.0
	if disp == "aggressive":
		base = 0.05
	elif disp == "wildcard":
		base = 0.03
	if base <= 0.0:
		return 0.0
	var chance: float = base * (1.0 - esp_cover / 100.0)
	if has_facility("FAC_SHIELD"):
		chance *= 0.5
	chance *= 1.0 - get_security() / 150.0
	return chance

func _tick_enemy_ops():
	if elapsed_days < 10.0:
		return
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			continue
		var chance: float = _enemy_op_chance(rd)
		if chance <= 0.0:
			continue
		if _rng.randf() < chance:
			_apply_enemy_op(rd)

func _apply_enemy_op(rd: Dictionary, kind: String = "") -> String:
	if kind.is_empty():
		var kinds := ["raid", "smear", "sabotage"]
		kind = kinds[_rng.randi() % kinds.size()]
	var detail := ""
	if kind == "raid":
		var loss: int = clampi(int(float(budget.get("funds", 0)) * 0.08), 200, 2000)
		budget["funds"] = int(budget.get("funds", 0)) - loss
		detail = "%s raided your accounts (-$%d)." % [rd.get("name", "?"), loss]
		EventBus.budget_updated.emit(budget["funds"], budget["spent"])
	elif kind == "smear":
		player_market = maxf(player_market - 2.0, 0.0)
		detail = "%s smeared your reputation (-2%% market)." % rd.get("name", "?")
	else:
		player_sabotaged_until = elapsed_days + 3.0
		detail = "%s sabotaged your labs (research slowed 3 days)." % rd.get("name", "?")
	intelligence_reports.append({
		"day": elapsed_days,
		"threshold": -2,
		"text": detail,
		"helios_progress": helios["progress"]
	})
	EventBus.rival_op.emit(detail)
	return detail

# --- Phase 5 consolidation: big rivals eat small ones ---
func _tick_consolidation():
	var leader := {}
	var best_share := -1.0
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			continue
		if float(rd.get("share", 0)) > best_share:
			best_share = float(rd.get("share", 0))
			leader = rd
	if leader.is_empty() or best_share <= 25.0:
		return
	for r in rivals:
		var rd2: Dictionary = r as Dictionary
		if (rd2 as Dictionary).get("id", "") == (leader as Dictionary).get("id", ""):
			continue
		if rd2.get("acquired_by_player", false) or rd2.get("status", "active") != "active":
			continue
		if float(rd2.get("share", 0)) >= 5.0:
			continue
		if _rng.randf() < 0.02:
			_consolidate_rival(rd2, leader)

func _consolidate_rival(small: Dictionary, leader: Dictionary):
	small["status"] = "acquired"
	small["acquired_by_player"] = false
	small["absorbed_by"] = leader.get("id", "")
	small["share"] = 0.0
	leader["share"] = float(leader.get("share", 0)) + 2.0
	_sync_helios_rival()
	var text: String = "%s was absorbed by %s." % [small.get("name", "?"), leader.get("name", "?")]
	intelligence_reports.append({
		"day": elapsed_days, "threshold": -2, "text": text, "helios_progress": helios["progress"]
	})
	EventBus.rival_op.emit(text)

# --- Phase 5 continue-after-win: raise the stakes instead of ending ---
func continue_after_win() -> Dictionary:
	if game_over.is_empty() or not game_over.get("won", false):
		return {"ok": false, "reason": "no_win"}
	if game_over.get("type", "") == "monopoly":
		return {"ok": false, "reason": "already_top"}
	game_over = {}
	continued = true
	bonus_target += 15.0
	return {"ok": true, "new_target": get_majority_target()}

# --- Phase 6 story: arcs, beats, reactions, horror ---
func content_gore() -> bool:
	if gore_setting == 0:
		return false
	if gore_setting == 1:
		return true
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") != OK:
		return true
	return bool(cfg.get_value("content", "graphic", true))

func _log_scientist_intros():
	var data: Dictionary = _load_json("res://data/narrative/scientist_beats.json")
	for sdef in data.get("scientists", []):
		var sd: Dictionary = sdef as Dictionary
		story_log.append({
			"day": elapsed_days, "artifact_id": "", "kind": "intro",
			"title": "Personnel: %s" % _scientist_name(sd.get("id", "")),
			"text": sd.get("intro", "")
		})

func _scientist_name(sci_id: String) -> String:
	for s in scientists:
		var sd: Dictionary = s as Dictionary
		if sd.get("id", "") == sci_id:
			return "%s %s" % [sd.get("first_name", "?"), sd.get("last_name", "?")]
	return sci_id

func _fire_story_beat(artifact_id: String, kind: String):
	var key: String = "%s:%s" % [artifact_id, kind]
	if key in fired_beats:
		return
	var data: Dictionary = _load_json("res://data/narrative/artifact_arcs.json")
	for arc in data.get("arcs", []):
		var ad: Dictionary = arc as Dictionary
		if ad.get("artifact_id", "") != artifact_id:
			continue
		var beats: Dictionary = ad.get("beats", {})
		if not beats.has(kind):
			return
		var beat: Dictionary = beats[kind]
		fired_beats.append(key)
		story_log.append({
			"day": elapsed_days, "artifact_id": artifact_id, "kind": kind,
			"title": beat.get("title", ""), "text": beat.get("text", "")
		})
		EventBus.story_beat.emit(beat.get("title", ""), beat.get("text", ""))
		return

func _fire_story_beats_for_state():
	var art_id: String = artifact.get("id", "")
	if art_id.is_empty():
		return
	var total_exps := 0
	for exp_id in knowledge.get("experiment_counts", {}):
		total_exps += int(knowledge["experiment_counts"][exp_id])
	if total_exps <= 1:
		_fire_story_beat(art_id, "dormant")
	var st: String = knowledge.get("state", "unknown")
	if st == "suspected" or st == "confirmed":
		_fire_story_beat(art_id, "suspected")
	if st == "confirmed":
		_fire_story_beat(art_id, "confirmed")

func _scientist_reaction(sci_id: String, severity: String) -> String:
	var data: Dictionary = _load_json("res://data/narrative/scientist_beats.json")
	var band := "minor"
	if severity in ["major", "critical", "severe"]:
		band = "major"
	elif severity == "moderate":
		band = "moderate"
	for sdef in data.get("scientists", []):
		var sd: Dictionary = sdef as Dictionary
		if sd.get("id", "") == sci_id:
			return (sd.get("reactions", {}) as Dictionary).get(band, "")
	return ""

func _pick_involved_scientist() -> String:
	if not experiment_history.is_empty():
		var last: Dictionary = experiment_history[experiment_history.size() - 1]
		var lid: String = last.get("scientist_id", "")
		for s in scientists:
			var sd: Dictionary = s as Dictionary
			if sd.get("id", "") == lid and sd.get("status", "ACTIVE") != "DECEASED":
				return lid
	var alive: Array = []
	for s in scientists:
		if (s as Dictionary).get("status", "ACTIVE") != "DECEASED":
			alive.append((s as Dictionary).get("id", ""))
	if alive.is_empty():
		return ""
	return alive[_rng.randi() % alive.size()]

func incident_display_text(record: Dictionary) -> String:
	if content_gore() and not record.get("graphic_description", "") == "":
		return record.get("graphic_description", "")
	return record.get("description", "")

func _harm_scientist(sci_id: String, dmg: int, cause: String):
	for s in scientists:
		var sd: Dictionary = s as Dictionary
		if sd.get("id", "") != sci_id:
			continue
		sd["health"] = maxi(int(sd.get("health", 100)) - dmg, 0)
		sd["stress"] = mini(int(sd.get("stress", 0)) + 15, 100)
		if int(sd["health"]) <= 0 and sd.get("status", "ACTIVE") != "DECEASED":
			sd["status"] = "DECEASED"
			pending_memorial = sci_id
			EventBus.scientist_died.emit(_scientist_name(sci_id))
			story_log.append({
				"day": elapsed_days, "artifact_id": artifact.get("id", ""), "kind": "death",
				"title": "KIA: %s" % _scientist_name(sci_id),
				"text": "%s died %s. The memorial service is brief; the work is not. Their notebook is sealed into the archive unread — no one has the stomach yet." % [_scientist_name(sci_id), cause]
			})
			award_badge("first_blood")
		elif int(sd["health"]) <= 35 and sd.get("status", "ACTIVE") == "ACTIVE":
			sd["status"] = "INJURED"
			story_log.append({
				"day": elapsed_days, "artifact_id": artifact.get("id", ""), "kind": "injury",
				"title": "Injured: %s" % _scientist_name(sci_id),
				"text": "%s is hurt badly enough to matter (%s). They insist on light duty. Observation quality will suffer until they heal." % [_scientist_name(sci_id), cause]
			})
		return

# --- Phase 6 rival voices: directors taunt at milestones ---
func _check_rival_taunt(rd: Dictionary):
	var thresholds := [25.0, 40.0]
	var hits: Array = rd.get("milestones_hit", [])
	var share: float = float(rd.get("share", 0))
	for i in range(thresholds.size()):
		if share >= thresholds[i] and not hits.has(i):
			hits.append(i)
			rd["milestones_hit"] = hits
			var taunts: Array = rd.get("taunts", [])
			if not taunts.is_empty():
				var text: String = taunts[mini(i, taunts.size() - 1)]
				intelligence_reports.append({
					"day": elapsed_days, "threshold": -3, "text": text,
					"helios_progress": helios["progress"]
				})

# --- Phase 6 crises: major incidents demand answers on a clock ---
func _maybe_spawn_crisis(record: Dictionary, incident: Dictionary):
	var sev: String = record.get("severity", "minor")
	if not (sev in ["major", "critical", "severe"]) and not incident.has("crisis"):
		return
	var block: Dictionary = incident.get("crisis", {"days": 5, "resolve_cost": 1500})
	active_crises.append({
		"id": "%s-d%d" % [record.get("id", "CRI"), int(elapsed_days)],
		"name": "Containment Crisis: %s" % record.get("name", "Unknown"),
		"days_left": float(block.get("days", 5)),
		"resolve_cost": int(block.get("resolve_cost", 1500)),
		"incident_id": record.get("id", "")
	})

func _tick_crises():
	for c in active_crises.duplicate():
		var cd: Dictionary = c as Dictionary
		cd["days_left"] = float(cd.get("days_left", 0.0)) - 1.0
		if float(cd.get("days_left", 0.0)) > 0.0:
			continue
		active_crises.erase(cd)
		budget["funds"] = int(budget.get("funds", 0)) - 3000
		var victim: String = _pick_involved_scientist()
		if not victim.is_empty():
			_harm_scientist(victim, 30, "in the uncontained aftermath")
		intelligence_reports.append({
			"day": elapsed_days, "threshold": -2,
			"text": "UNCONTAINED: %s burned out of control. -$3000 emergency response, casualties." % cd.get("name", "?"),
			"helios_progress": helios["progress"]
		})
		EventBus.budget_updated.emit(budget["funds"], budget["spent"])

func resolve_crisis(crisis_id: String, method: String) -> Dictionary:
	for c in active_crises:
		var cd: Dictionary = c as Dictionary
		if cd.get("id", "") != crisis_id:
			continue
		if method == "pay":
			var cost: int = int(cd.get("resolve_cost", 1500))
			if int(budget.get("funds", 0)) < cost:
				return {"ok": false, "reason": "insufficient_funds"}
			budget["funds"] = int(budget.get("funds", 0)) - cost
			budget["spent"] = int(budget.get("spent", 0)) + cost
			active_crises.erase(cd)
			intelligence_reports.append({
				"day": elapsed_days, "threshold": -2,
				"text": "Contained: %s resolved with emergency funding (-$%d)." % [cd.get("name", ""), cost],
				"helios_progress": helios["progress"]
			})
			EventBus.budget_updated.emit(budget["funds"], budget["spent"])
			return {"ok": true, "detail": "Crisis contained with funding."}
		elif method == "team":
			var hurt: int = 10
			var detail := "Response team contained it with minor injuries."
			if _rng.randf() < 0.4:
				hurt = 25
				detail = "Response team mauled containing it. They held."
			var victim2: String = _pick_involved_scientist()
			if not victim2.is_empty():
				_harm_scientist(victim2, hurt, "on the response team")
			active_crises.erase(cd)
			intelligence_reports.append({
				"day": elapsed_days, "threshold": -2,
				"text": "Contained: %s. %s" % [cd.get("name", ""), detail],
				"helios_progress": helios["progress"]
			})
			return {"ok": true, "detail": detail}
		return {"ok": false, "reason": "bad_method"}
	return {"ok": false, "reason": "no_crisis"}

func _living_scientists() -> Array:
	var out := []
	for s in scientists:
		if (s as Dictionary).get("status", "ACTIVE") != "DECEASED":
			out.append(s)
	return out

func _staff_wipe_defeat():
	if not game_over.is_empty():
		return
	game_over = {
		"won": false,
		"reason": "staff_wipe",
		"player_market": player_market,
		"dominant_rival": _leading_rival_name(),
		"type": "absorbed"
	}
	_record_legacy()
	EventBus.game_over.emit(game_over)

# --- Phase 3 endings: tiered paths (monopoly > researcher > market_leader) ---
func _confirmed_artifact_count() -> int:
	var count := 0
	if discovery.get("state", "") == "confirmed":
		count += 1
	for art_id in per_artifact_data:
		var entry: Dictionary = per_artifact_data[art_id]
		var saved_disc: Dictionary = entry.get("discovery", {})
		if saved_disc.get("state", "") == "confirmed":
			count += 1
	return count

func _has_tech_depth() -> bool:
	for tech_id in TECH_KEY_MAP.values():
		if not unlocked_technologies.has(tech_id):
			return false
	return true

func _check_scientific_win() -> bool:
	if bool(difficulty.get("science_locked", false)):
		return false
	if discovery.get("state", "") != "confirmed":
		return false
	for d in discoveries:
		if (d as Dictionary).get("state", "") != "confirmed":
			return false
	if _has_tech_depth():
		return true
	return _confirmed_artifact_count() >= 3

# --- Phase 3 badges + legacy profile (persisted across runs) ---
const LEGACY_PATH := "user://janus_legacy.json"

func _badge_name(badge_id: String) -> String:
	var data: Dictionary = _load_json("res://data/meta/badges.json")
	for bdef in data.get("badges", []):
		var bd: Dictionary = bdef as Dictionary
		if bd.get("id", "") == badge_id:
			return bd.get("name", badge_id)
	return badge_id

func award_badge(badge_id: String):
	if badge_id.is_empty() or badge_id in run_badges:
		return
	run_badges.append(badge_id)
	var legacy: Dictionary = _load_legacy()
	var all_badges: Array = legacy.get("badges", [])
	if badge_id not in all_badges:
		all_badges.append(badge_id)
	legacy["badges"] = all_badges
	_persist_legacy(legacy)
	EventBus.badge_earned.emit(badge_id, _badge_name(badge_id))

func _load_legacy() -> Dictionary:
	if not FileAccess.file_exists(LEGACY_PATH):
		return {"badges": [], "best": {}}
	var file := FileAccess.open(LEGACY_PATH, FileAccess.READ)
	if not file:
		return {"badges": [], "best": {}}
	var text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return {"badges": [], "best": {}}
	return json.data

func _persist_legacy(data: Dictionary):
	var file := FileAccess.open(LEGACY_PATH, FileAccess.WRITE)
	if not file:
		push_warning("Cannot write legacy file: " + LEGACY_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func _record_legacy():
	var win_type: String = game_over.get("type", "")
	if win_type == "market_leader":
		award_badge("market_leader")
	elif win_type == "researcher":
		award_badge("distinguished")
	elif win_type == "monopoly":
		award_badge("monopoly")
		if elapsed_days < 40.0:
			award_badge("overnight_monopoly")
	var diff_id: String = difficulty.get("id", "normal")
	var legacy: Dictionary = _load_legacy()
	var best: Dictionary = legacy.get("best", {})
	var days: float = elapsed_days
	var entry: Dictionary = best.get(diff_id, {})
	if entry.is_empty() or float(entry.get("days", 1e9)) > days:
		best[diff_id] = {"type": win_type, "days": days, "title": get_run_title()}
		legacy["best"] = best
		_persist_legacy(legacy)

func get_run_title() -> String:
	var type_names := {
		"market_leader": "Market Leader",
		"researcher": "Distinguished Researcher",
		"monopoly": "The Monopoly",
		"absorbed": "Absorbed"
	}
	var diff_name: String = difficulty.get("display_name", "Normal")
	return "%s %s" % [diff_name, type_names.get(game_over.get("type", "absorbed"), "Contender")]

func get_legacy_line() -> String:
	var legacy: Dictionary = _load_legacy()
	var best: Dictionary = legacy.get("best", {})
	if best.is_empty():
		return "No completed runs yet."
	var parts: PackedStringArray = []
	for diff_id in ["easy", "normal", "hard"]:
		if best.has(diff_id):
			var e: Dictionary = best[diff_id]
			parts.append("%s: %s (day %d)" % [
				diff_id.capitalize(), e.get("title", "?"), int(e.get("days", 0))
			])
	var badges: Array = legacy.get("badges", [])
	var total: int = (_load_json("res://data/meta/badges.json") as Dictionary).get("badges", []).size()
	return "Best — %s | Badges: %d/%d" % ["; ".join(parts), badges.size(), total]

# --- Phase 3 espionage: funds + risk allocation, not click-to-win ---
func _espionage_op_def(op_id: String) -> Dictionary:
	var data: Dictionary = _load_json("res://data/espionage/espionage_ops.json")
	for odef in data.get("ops", []):
		var od: Dictionary = odef as Dictionary
		if od.get("id", "") == op_id:
			return od
	return {}

func _espionage_cost_mult() -> float:
	match difficulty.get("id", "normal"):
		"easy":
			return 0.8
		"hard":
			return 1.2
	return 1.0

func perform_espionage_op(op_id: String, target_id: String = "") -> Dictionary:
	var odef: Dictionary = _espionage_op_def(op_id)
	if odef.is_empty():
		return {"ok": false, "reason": "no_op"}
	var cost: int = int(round(float(odef.get("cost", 0)) * _espionage_cost_mult()))
	if int(budget.get("funds", 0)) < cost:
		return {"ok": false, "reason": "insufficient_funds"}
	if op_id == "OP_SURVEY" and target_id.is_empty():
		return {"ok": false, "reason": "need_target"}
	if (op_id == "OP_SABOTAGE" or op_id == "OP_EXPOSE") and target_id.is_empty():
		return {"ok": false, "reason": "need_target"}
	budget["funds"] = int(budget.get("funds", 0)) - cost
	budget["spent"] = int(budget.get("spent", 0)) + cost
	esp_risk = minf(esp_risk + float(odef.get("risk_add", 0.0)), 100.0)
	var chance: float = clampf(
		float(odef.get("base_success", 0.5)) + esp_cover / 250.0 - esp_risk / 200.0, 0.15, 0.95
	)
	var roll: float = _rng.randf()
	var success: bool = roll < chance
	var detail := ""
	if success:
		detail = _apply_espionage_success(op_id, target_id)
	else:
		esp_risk = minf(esp_risk + 10.0, 100.0)
		detail = "Op failed. Heat rises."
		if esp_risk >= 70.0 or roll > 0.97:
			detail = _espionage_caught(op_id)
	EventBus.budget_updated.emit(budget["funds"], budget["spent"])
	EventBus.espionage_updated.emit()
	return {"ok": true, "success": success, "detail": detail, "risk": esp_risk, "cover": esp_cover}

func _apply_espionage_success(op_id: String, target_id: String) -> String:
	if op_id == "OP_SURVEY":
		var offer: Dictionary = get_company_offer(target_id)
		if not offer.is_empty():
			offer["dd_level"] = 2
			offer["dd_estimate"] = float(offer.get("true_value", 0.0))
			offer["dd_error"] = 0.0
			offer["surveyed"] = true
			return "Surveillance complete: exact valuation revealed."
		for r in rivals:
			var rd: Dictionary = r as Dictionary
			if rd.get("id", "") == target_id:
				intelligence_reports.append({
					"day": elapsed_days,
					"threshold": -1,
					"text": "Surveillance: %s holds %.1f%% share (pipeline: %s)." % [
						rd.get("name", "?"), float(rd.get("share", 0)), rd.get("disposition", "?")
					],
					"helios_progress": helios["progress"]
				})
				return "Surveillance complete: rival pipeline mapped."
		return "Surveillance found nothing."
	if op_id == "OP_STEAL":
		var locked: Array = []
		for key in TECH_KEY_MAP:
			if not unlocked_technologies.has(TECH_KEY_MAP[key]):
				locked.append(key)
		if locked.is_empty():
			return "Nothing left worth stealing."
		var pick: String = locked[_rng.randi() % locked.size()]
		_unlock_technology_for_discovery("ESP_STEAL", pick)
		return "Infiltration succeeded: rival tech pulled into your tree."
	if op_id == "OP_SABOTAGE":
		for r in rivals:
			var rd: Dictionary = r as Dictionary
			if rd.get("id", "") == target_id:
				rd["sabotaged_until"] = elapsed_days + 6.0
				return "Sabotage succeeded: %s slowed for 6 days." % rd.get("name", "?")
		return "Sabotage found no target."
	if op_id == "OP_COUNTER":
		esp_cover = minf(esp_cover + 12.0, 50.0)
		esp_risk = maxf(esp_risk - 20.0, 0.0)
		return "Cover tightened. Heat burned off."
	if op_id == "OP_EXPOSE":
		for r in rivals:
			var rd: Dictionary = r as Dictionary
			if rd.get("id", "") == target_id:
				rd["share"] = maxf(float(rd.get("share", 0)) - 6.0, 0.0)
				_sync_helios_rival()
				return "Leak published: %s reputation ruined (-6%% share)." % rd.get("name", "?")
		return "Leak found no target."
	return "Op completed."

func _espionage_caught(op_id: String) -> String:
	var incident := {
		"id": "INC_EXPOSED_OP",
		"name": "Exposed Operation",
		"description": "An operation (%s) was traced back to your lab. Funding pulled, rivals emboldened." % op_id,
		"severity": "major",
		"effects": {"budget_cost": 1500, "days_lost": 1}
	}
	_apply_incident(incident)
	var best := {}
	var best_share := -1.0
	for r in rivals:
		var rd: Dictionary = r as Dictionary
		if rd.get("acquired_by_player", false) or rd.get("status", "active") != "active":
			continue
		if float(rd.get("share", 0)) > best_share:
			best_share = float(rd.get("share", 0))
			best = rd
	if not best.is_empty():
		best["share"] = float(best.get("share", 0)) + 4.0
		_sync_helios_rival()
	esp_risk = 50.0
	return "CAUGHT: operation exposed. Scandal incident, funding cut, leading rival gains."

# --- Phase 3 world events: conditional shape-changers, never hard locks ---
func _schedule_events():
	var data: Dictionary = _load_json("res://data/events/world_events.json")
	var ids: Array = []
	for edef in data.get("events", []):
		ids.append((edef as Dictionary).get("id", ""))
	ids.shuffle()
	event_schedule = []
	var picks: int = mini(2, ids.size())
	for i in range(picks):
		var day := 0.0
		if i == 0:
			day = 12.0 + _rng.randf() * 10.0
		else:
			day = 30.0 + _rng.randf() * 15.0
		event_schedule.append({"id": ids[i], "day": day})

func _event_def(event_id: String) -> Dictionary:
	var data: Dictionary = _load_json("res://data/events/world_events.json")
	for edef in data.get("events", []):
		var ed: Dictionary = edef as Dictionary
		if ed.get("id", "") == event_id:
			return ed
	return {}

func _tick_events():
	if not active_event.is_empty():
		player_market += float(active_event.get("player_bonus", 0.0))
		if elapsed_days >= float(active_event.get("until_day", 0.0)):
			EventBus.event_updated.emit(active_event.get("id", ""), "ended")
			active_event = {}
		return
	for entry in event_schedule.duplicate():
		var ed0: Dictionary = entry as Dictionary
		if elapsed_days >= float(ed0.get("day", 0.0)):
			_trigger_event(ed0.get("id", ""))
			event_schedule.erase(entry)

func _trigger_event(event_id: String):
	var edef: Dictionary = _event_def(event_id)
	if edef.is_empty():
		return
	active_event = {
		"id": event_id,
		"name": edef.get("name", "Event"),
		"rival_mult": float(edef.get("rival_mult", 1.0)),
		"player_bonus": float(edef.get("player_bonus", 0.0)),
		"until_day": elapsed_days + float(edef.get("duration_days", 8.0))
	}
	if event_id not in events_seen:
		events_seen.append(event_id)
	var grant: int = int(edef.get("funds_grant", 0))
	if grant != 0:
		budget["funds"] = maxi(int(budget.get("funds", 0)) + grant, 0)
		EventBus.budget_updated.emit(budget["funds"], budget["spent"])
	EventBus.event_updated.emit(event_id, "triggered")

func _event_rival_mult() -> float:
	if active_event.is_empty():
		return 1.0
	return float(active_event.get("rival_mult", 1.0))

# --- Phase 3 contracts: one slot at a time; workdays are the real cost ---
func _spawn_contracts():
	var data: Dictionary = _load_json("res://data/contracts/contracts.json")
	contract_deck = []
	for cdef in data.get("contracts", []):
		contract_deck.append((cdef as Dictionary).get("id", ""))
	next_offer_day = 6.0

func _contract_def(contract_id: String) -> Dictionary:
	var data: Dictionary = _load_json("res://data/contracts/contracts.json")
	for cdef in data.get("contracts", []):
		var cd: Dictionary = cdef as Dictionary
		if cd.get("id", "") == contract_id:
			return cd
	return {}

func _tick_contracts():
	if not active_contract.is_empty():
		active_contract["days_done"] = float(active_contract.get("days_done", 0.0)) + 1.0
		if float(active_contract.get("days_done", 0.0)) >= float(active_contract.get("days_required", 1.0)):
			_complete_contract()
		return
	if not pending_offer.is_empty():
		if elapsed_days >= float(pending_offer.get("expires_day", 0.0)):
			pending_offer = {}
			next_offer_day = elapsed_days + 8.0
			EventBus.contract_updated.emit()
		return
	if elapsed_days < next_offer_day or contract_deck.is_empty():
		return
	for cid in contract_deck.duplicate():
		var cdef: Dictionary = _contract_def(str(cid))
		var tag: String = cdef.get("event_tag", "")
		if float(cdef.get("min_ties", 0.0)) > military_ties:
			continue
		if tag.is_empty() or tag in events_seen:
			pending_offer = {
				"id": cdef.get("id", ""),
				"offered_day": elapsed_days,
				"expires_day": elapsed_days + 20.0
			}
			contract_deck.erase(cid)
			EventBus.contract_updated.emit()
			return
	next_offer_day = elapsed_days + 6.0

func accept_contract() -> Dictionary:
	if pending_offer.is_empty():
		return {"ok": false, "reason": "no_offer"}
	if not active_contract.is_empty():
		return {"ok": false, "reason": "slot_busy"}
	var cdef: Dictionary = _contract_def(pending_offer.get("id", ""))
	if cdef.is_empty():
		pending_offer = {}
		return {"ok": false, "reason": "no_def"}
	active_contract = {
		"id": cdef.get("id", ""),
		"days_done": 0.0,
		"days_required": float(cdef.get("days_required", 5.0))
	}
	pending_offer = {}
	budget["funds"] = int(budget.get("funds", 0)) + int(cdef.get("upfront", 0))
	EventBus.budget_updated.emit(budget["funds"], budget["spent"])
	EventBus.contract_updated.emit()
	return {"ok": true}

func decline_contract() -> Dictionary:
	if pending_offer.is_empty():
		return {"ok": false, "reason": "no_offer"}
	pending_offer = {}
	next_offer_day = elapsed_days + 8.0
	EventBus.contract_updated.emit()
	return {"ok": true}

func _complete_contract():
	var cdef: Dictionary = _contract_def(active_contract.get("id", ""))
	if cdef.is_empty():
		active_contract = {}
		return
	budget["funds"] = int(budget.get("funds", 0)) + int(cdef.get("completion_pay", 0))
	player_market += float(cdef.get("market_bonus", 0.0))
	_unlock_technology_for_discovery("CTR_%s" % cdef.get("id", ""), cdef.get("tech_key", ""))
	if bool(cdef.get("military", false)):
		award_badge("war_contractor")
		military_ties = minf(military_ties + 25.0, 100.0)
	completed_contracts.append(cdef.get("id", ""))
	active_contract = {}
	next_offer_day = elapsed_days + 10.0
	EventBus.budget_updated.emit(budget["funds"], budget["spent"])
	EventBus.contract_updated.emit()
	_check_market_end()

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
		"owned_companies": owned_companies,
		"contract_deck": contract_deck,
		"pending_offer": pending_offer,
		"active_contract": active_contract,
		"completed_contracts": completed_contracts,
		"next_offer_day": next_offer_day,
		"event_schedule": event_schedule,
		"active_event": active_event,
		"events_seen": events_seen,
		"esp_risk": esp_risk,
		"esp_cover": esp_cover,
		"run_badges": run_badges,
		"facilities_owned": facilities_owned,
		"player_sabotaged_until": player_sabotaged_until,
		"continued": continued,
		"bonus_target": bonus_target,
		"story_log": story_log,
		"fired_beats": fired_beats,
		"active_crises": active_crises,
		"pending_memorial": pending_memorial,
		"military_ties": military_ties
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
	contract_deck = data.get("contract_deck", [])
	pending_offer = data.get("pending_offer", {})
	active_contract = data.get("active_contract", {})
	completed_contracts = data.get("completed_contracts", [])
	next_offer_day = data.get("next_offer_day", 0.0)
	if contract_deck.is_empty() and pending_offer.is_empty() and active_contract.is_empty() and completed_contracts.is_empty():
		_spawn_contracts()
	event_schedule = data.get("event_schedule", [])
	active_event = data.get("active_event", {})
	events_seen = data.get("events_seen", [])
	if event_schedule.is_empty() and active_event.is_empty() and events_seen.is_empty():
		_schedule_events()
	esp_risk = data.get("esp_risk", 0.0)
	esp_cover = data.get("esp_cover", 0.0)
	run_badges = data.get("run_badges", [])
	facilities_owned = data.get("facilities_owned", [])
	player_sabotaged_until = data.get("player_sabotaged_until", 0.0)
	continued = data.get("continued", false)
	bonus_target = data.get("bonus_target", 0.0)
	story_log = data.get("story_log", [])
	fired_beats = data.get("fired_beats", [])
	active_crises = data.get("active_crises", [])
	pending_memorial = data.get("pending_memorial", "")
	military_ties = data.get("military_ties", 0.0)
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
