extends Node

var campaign_id: String = ""
var seed: int = 0
var elapsed_days: int = 0

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
var technology_unlocked: bool = false
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
	"EXP_EM_RESONANCE": 40
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

func initialize_new_campaign(org: Dictionary):
	campaign_id = _generate_id()
	seed = _rng.randi()
	elapsed_days = 0
	organization = org.duplicate(true)
	per_artifact_data = {}
	_load_artifact_data()
	_load_scientist_data()
	_reset_knowledge()
	_reset_discovery()
	_set_discovery_for_artifact()
	technology_unlocked = false
	_assign_helios_artifact()
	helios["progress"] = 0
	helios["thresholds_hit"] = []
	helios["discovered_first"] = false
	helios["discoveries_named"] = []
	experiment_history = []
	intelligence_reports = []
	last_intel_threshold = 0
	_load_budget_data()
	_rng.seed = seed

func _load_budget_data():
	var data := _load_json("res://data/resources/budget.json")
	budget = {
		"funds": data.get("starting_budget", 10000),
		"spent": 0,
		"funding_received": 0,
		"next_funding_index": 0,
		"events_received": []
	}

var _seed: int = 0

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
			"experiment_history": experiment_history.duplicate(),
			"intelligence_reports": intelligence_reports.duplicate()
		}
	selected_artifact_index = index
	artifact = available_artifacts[index]
	var new_id: String = artifact.get("id", "")
	if per_artifact_data.has(new_id):
		var saved: Dictionary = per_artifact_data[new_id]
		knowledge = saved.get("knowledge", {"progress": 0, "state": "unknown", "observations": [], "experiment_counts": {}})
		discovery = saved.get("discovery", {"state": "unknown", "player_name": "", "discovery_id": ""})
		experiment_history = saved.get("experiment_history", [])
		intelligence_reports = saved.get("intelligence_reports", [])
	else:
		_reset_knowledge()
		_reset_discovery()
		experiment_history = []
		intelligence_reports = []
	_set_discovery_for_artifact()

func _set_discovery_for_artifact():
	var art_id: String = artifact.get("id", "")
	match art_id:
		"J001":
			discovery["discovery_id"] = "DISC_GRAV_ATTENUATION"
		"J002":
			discovery["discovery_id"] = "DISC_GRAV_AMPLIFICATION"
		"J003":
			discovery["discovery_id"] = "DISC_GRAV_NULLIFICATION"
		_:
			discovery["discovery_id"] = "DISC_GRAV_ATTENUATION"

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
	return knowledge["progress"] >= threshold

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
	var knowledge_gain := int(experiment_def.get("knowledge_gain", 2) * quality)
	knowledge_gain = maxi(knowledge_gain, 1)

	for obs in observations:
		knowledge["observations"].append(obs)

	knowledge["progress"] = mini(knowledge["progress"] + knowledge_gain, 100)

	if not knowledge["experiment_counts"].has(exp_id):
		knowledge["experiment_counts"][exp_id] = 0
	knowledge["experiment_counts"][exp_id] += 1

	elapsed_days += experiment_def.get("duration_minutes", 5) / (60 * 8)

	_update_knowledge_state()

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
	_check_funding()
	_check_budget_events()
	EventBus.budget_updated.emit(budget["funds"], budget["spent"])

	_check_incidents()
	_advance_helios()
	_generate_intelligence()

	return exp_record

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
		quality += _rng._rng.randf_range(-0.15, 0.15)

	if technology_unlocked:
		quality *= 1.2

	return clampf(quality, 0.1, 2.0)

func _generate_observations(experiment_def: Dictionary, quality: float) -> Array:
	var template: String = experiment_def.get("result_template", "passive_observation")
	var observations: Array = []
	var confidence := "low"
	if quality >= 1.0:
		confidence = "high"
	elif quality >= 0.5:
		confidence = "moderate"

	match template:
		"passive_observation":
			var variants := [
				"Surface remains exactly 14.0C despite ambient changes.",
				"No visible change in surface properties after 30 minutes.",
				"Object maintains identical appearance regardless of lighting angle.",
				"Acoustic sensors detect no internal vibration or resonance.",
				"Object mass reads consistently across multiple measurement attempts."
			]
			observations.append({
				"content": variants[_rng._rng.randi() % variants.size()],
				"interpretation": "Thermal stability appears anomalous.",
				"confidence": confidence,
				"type": "passive"
			})
		"heating":
			var variants := [
				"Large amounts of energy enter the environment but sphere temperature remains nearly constant.",
				"Infrared imaging shows no thermal gradient across the surface.",
				"Applied heat dissipates without measurable temperature increase.",
				"Object absorbs sustained heating with no visible effect."
			]
			observations.append({
				"content": variants[_rng.randi() % variants.size()],
				"interpretation": "Object resists conventional heating.",
				"confidence": confidence,
				"type": "active"
			})
		"electrical_exposure":
			var deviation: float = _rng.randf_range(1.0, 8.0) * quality
			var variants := [
				"Minor unexplained instrumentation deviation detected (%.1f%%)." % deviation,
				"Electromagnetic readings fluctuate during exposure (%.1f%% variance)." % deviation,
				"Nearby sensors register anomalous readings (%.1f%% shift)." % deviation,
				"Voltage measurements inconsistent with applied current (%.1f%% offset)." % deviation
			]
			observations.append({
				"content": variants[_rng.randi() % variants.size()],
				"interpretation": "Electrical exposure may affect local measurements.",
				"confidence": confidence,
				"type": "active"
			})
		"xray":
			var variants := [
				"Imaging produces inconsistent internal geometry.",
				"X-ray diffraction pattern does not match any known crystal structure.",
				"Internal density map shows impossible void distribution.",
				"Radiation absorption varies unpredictably across the surface."
			]
			observations.append({
				"content": variants[_rng.randi() % variants.size()],
				"interpretation": "Internal structure cannot be reliably resolved.",
				"confidence": confidence,
				"type": "passive"
			})
		"em_low":
			var variants := [
				"Minimal measurable effect from low-frequency EM exposure.",
				"No response detected at low frequencies.",
				"Object appears transparent to low-frequency radiation.",
				"Low-frequency exposure produces no detectable interaction."
			]
			observations.append({
				"content": variants[_rng.randi() % variants.size()],
				"interpretation": "No significant response detected.",
				"confidence": "low",
				"type": "active"
			})
		"em_mid":
			var fluctuation: float = _rng.randf_range(1.0, 4.0) * quality
			var variants := [
				"Mass sensors fluctuate during mid-frequency exposure (%.1f%% variance)." % fluctuation,
				"Gravitational readings shift slightly (%.1f%% deviation)." % fluctuation,
				"Mid-frequency bands produce measurable perturbation (%.1f%%)." % fluctuation,
				"Instrumentation shows frequency-dependent response (%.1f%%)." % fluctuation
			]
			observations.append({
				"content": variants[_rng.randi() % variants.size()],
				"interpretation": "Possible interaction with electromagnetic fields.",
				"confidence": confidence,
				"type": "active"
			})
		"em_resonance":
			var weight_change: float = _rng.randf_range(15.0, 45.0) * clampf(quality, 0.0, 1.0)
			var variants := [
				"Apparent measured weight decreases by %.1f%% during resonance exposure." % weight_change,
				"Gravitational sensor registers %.1f%% anomalous reduction." % weight_change,
				"Object effective mass drops %.1f%% at resonance frequency." % weight_change,
				"Peak attenuation of %.1f%% observed near 18 GHz." % weight_change
			]
			observations.append({
				"content": variants[_rng.randi() % variants.size()],
				"interpretation": "Electromagnetic exposure at resonance range affects gravitational measurements.",
				"confidence": confidence,
				"type": "active",
				"weight_decrease_pct": weight_change
			})
		"cooling":
			var variants := [
				"Cooling attempt fails to reduce surface temperature below 14.0C.",
				"Cryogenic application produces no measurable thermal change.",
				"Object resists cooling efforts consistently across multiple attempts.",
				"Thermal equilibrium appears fixed at ambient baseline regardless of cooling."
			]
			observations.append({
				"content": variants[_rng._rng.randi() % variants.size()],
				"interpretation": "Object maintains fixed thermal equilibrium.",
				"confidence": confidence,
				"type": "active"
			})
		_:
			observations.append({
				"content": "Generic observation recorded.",
				"interpretation": "No clear anomaly detected.",
				"confidence": "low",
				"type": "generic"
			})

	return observations

func _generate_narrative(experiment_def: Dictionary, scientist: Dictionary, observations: Array, quality: float) -> String:
	var scientist_name: String = scientist.get("first_name", "?") + " " + scientist.get("last_name", "?")
	var exp_name: String = experiment_def.get("name", "experiment")
	var templates := [
		"%s conducted %s and recorded the following: %s",
		"%s reported: %s",
		"During %s, %s observed: %s",
		"%s performed %s. Result: %s"
	]
	var template: String = templates[_rng.randi() % templates.size()]
	var obs_text: String = "No significant findings."
	if observations.size() > 0:
		var first_obs: Dictionary = observations[0] as Dictionary
		obs_text = first_obs.get("content", "No significant findings.")
	return template % [scientist_name, exp_name, obs_text]

func _update_knowledge_state():
	var progress: int = knowledge["progress"]
	if progress >= CONFIRMED_THRESHOLD and knowledge["state"] != "confirmed":
		knowledge["state"] = "confirmed"
		discovery["state"] = "confirmed"
		if not helios["discovered_first"] and helios["progress"] < 100:
			pass
		else:
			helios["discovered_first"] = true
		EventBus.discovery_confirmed.emit(discovery["discovery_id"])
	elif progress >= SUSPECTED_THRESHOLD and knowledge["state"] == "unknown":
		knowledge["state"] = "suspected"
		discovery["state"] = "suspected"
		EventBus.discovery_suspected.emit(discovery["discovery_id"])

	EventBus.knowledge_updated.emit(knowledge["progress"], knowledge["state"])

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
		if _rng.randf() < chance:
			_apply_incident(inc_dict)
			break

func _apply_incident(incident: Dictionary):
	var inc_id: String = incident.get("id", "")
	incidents.append({
		"id": inc_id,
		"name": incident.get("name", "Unknown Incident"),
		"description": incident.get("description", ""),
		"severity": incident.get("severity", "minor"),
		"day": elapsed_days
	})
	var effects: Dictionary = incident.get("effects", {})
	budget["funds"] -= effects.get("budget_cost", 0)
	elapsed_days += effects.get("days_lost", 0)
	var discovery_bonus: float = incident.get("discovery_chance_increase", 0.0)
	if discovery_bonus > 0 and knowledge["progress"] < CONFIRMED_THRESHOLD:
		knowledge["progress"] = mini(knowledge["progress"] + int(discovery_bonus * 100), CONFIRMED_THRESHOLD)
	incident_cooldown = 5
	EventBus.incident_occurred.emit(incident)

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
		"technology_unlocked": technology_unlocked,
		"helios": helios,
		"experiment_history": experiment_history,
		"intelligence_reports": intelligence_reports,
		"last_intel_threshold": last_intel_threshold,
		"incidents": incidents,
		"incident_cooldown": incident_cooldown,
		"budget": budget
	}

func _save_current_artifact_data():
	var art_id: String = artifact.get("id", "")
	if not art_id.is_empty():
		per_artifact_data[art_id] = {
			"knowledge": knowledge.duplicate(true),
			"discovery": discovery.duplicate(true),
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
