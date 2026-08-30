class_name ObservationSimulator
extends RefCounted

static func generate(experiment_def: Dictionary, quality: float, rng: RandomNumberGenerator) -> Array:
	var template: String = experiment_def.get("result_template", "passive_observation")
	var observations: Array = []
	var confidence := "low"
	if quality >= 1.0:
		confidence = "high"
	elif quality >= 0.5:
		confidence = "moderate"

	var content := ""
	var interpretation := ""
	var obs_type := "active"
	var extras := {}

	match template:
		"passive_observation":
			var variants := [
				"Surface remains exactly 14.0C despite ambient changes.",
				"No visible change in surface properties after 30 minutes.",
				"Object maintains identical appearance regardless of lighting angle.",
				"Acoustic sensors detect no internal vibration or resonance.",
				"Object mass reads consistently across multiple measurement attempts."
			]
			content = variants[rng.randi() % variants.size()]
			interpretation = "Thermal stability appears anomalous."
			obs_type = "passive"
		"heating":
			var variants := [
				"Large amounts of energy enter the environment but sphere temperature remains nearly constant.",
				"Infrared imaging shows no thermal gradient across the surface.",
				"Applied heat dissipates without measurable temperature increase.",
				"Object absorbs sustained heating with no visible effect."
			]
			content = variants[rng.randi() % variants.size()]
			interpretation = "Object resists conventional heating."
		"electrical_exposure":
			var deviation: float = rng.randf_range(1.0, 8.0) * quality
			var variants := [
				"Minor unexplained instrumentation deviation detected (%.1f%%)." % deviation,
				"Electromagnetic readings fluctuate during exposure (%.1f%% variance)." % deviation,
				"Nearby sensors register anomalous readings (%.1f%% shift)." % deviation,
				"Voltage measurements inconsistent with applied current (%.1f%% offset)." % deviation
			]
			content = variants[rng.randi() % variants.size()]
			interpretation = "Electrical exposure may affect local measurements."
		"xray":
			var variants := [
				"Imaging produces inconsistent internal geometry.",
				"X-ray diffraction pattern does not match any known crystal structure.",
				"Internal density map shows impossible void distribution.",
				"Radiation absorption varies unpredictably across the surface."
			]
			content = variants[rng.randi() % variants.size()]
			interpretation = "Internal structure cannot be reliably resolved."
			obs_type = "passive"
		"em_low":
			var variants := [
				"Minimal measurable effect from low-frequency EM exposure.",
				"No response detected at low frequencies.",
				"Object appears transparent to low-frequency radiation.",
				"Low-frequency exposure produces no detectable interaction."
			]
			content = variants[rng.randi() % variants.size()]
			interpretation = "No significant response detected."
			confidence = "low"
		"em_mid":
			var fluctuation: float = rng.randf_range(1.0, 4.0) * quality
			var variants := [
				"Mass sensors fluctuate during mid-frequency exposure (%.1f%% variance)." % fluctuation,
				"Gravitational readings shift slightly (%.1f%% deviation)." % fluctuation,
				"Mid-frequency bands produce measurable perturbation (%.1f%%)." % fluctuation,
				"Instrumentation shows frequency-dependent response (%.1f%%)." % fluctuation
			]
			content = variants[rng.randi() % variants.size()]
			interpretation = "Possible interaction with electromagnetic fields."
		"em_resonance":
			var weight_change: float = rng.randf_range(15.0, 45.0) * clampf(quality, 0.0, 1.0)
			var variants := [
				"Apparent measured weight decreases by %.1f%% during resonance exposure." % weight_change,
				"Gravitational sensor registers %.1f%% anomalous reduction." % weight_change,
				"Object effective mass drops %.1f%% at resonance frequency." % weight_change,
				"Peak attenuation of %.1f%% observed near 18 GHz." % weight_change
			]
			content = variants[rng.randi() % variants.size()]
			interpretation = "Electromagnetic exposure at resonance range affects gravitational measurements."
			extras["weight_decrease_pct"] = weight_change
		"cooling":
			var variants := [
				"Cooling attempt fails to reduce surface temperature below 14.0C.",
				"Cryogenic application produces no measurable thermal change.",
				"Object resists cooling efforts consistently across multiple attempts.",
				"Thermal equilibrium appears fixed at ambient baseline regardless of cooling."
			]
			content = variants[rng.randi() % variants.size()]
			interpretation = "Object maintains fixed thermal equilibrium."
		"acoustic":
			var variants := [
				"No acoustic resonance detected across the frequency range.",
				"No transmitted vibrations return at expected frequencies.",
				"Acoustic signals are absorbed almost entirely by the surface.",
				"Tone impulses produce no measurable echo or internal ring."
			]
			content = variants[rng.randi() % variants.size()]
			interpretation = "Acoustic energy is absorbed rather than reflected."
		"laser":
			var reflectance: float = rng.randf_range(1.0, 4.0) * clampf(quality, 0.2, 1.0)
			var variants := [
				"Chromatic sampling indicates zero reflectance at visible wavelengths (%.1f%% reflectivity)." % reflectance,
				"Surface reflects less than %.1f%% of incident photons." % reflectance,
				"Spectroscopy shows no emission lines matching known elements (%.1f%% reflectivity)." % reflectance,
				"Laser spot produces no measurable scattering (reflectance %.1f%%)." % reflectance
			]
			content = variants[rng.randi() % variants.size()]
			interpretation = "Surface is exceptionally absorptive at optical frequencies."
			obs_type = "passive"
			extras["reflectivity_pct"] = reflectance
		"vibration":
			var decay: float = rng.randf_range(0.3, 1.5) * quality
			var variants := [
				"Induced vibration decays anomalously fast (time constant %.1fs)." % decay,
				"Mechanical impulse returns no identifiable modal signature (%.1fs decay)." % decay,
				"Vibration analysis shows aperiodic damping (%.1fs)." % decay,
				"Structure appears overdamped beyond any known material (%.1fs)." % decay
			]
			content = variants[rng.randi() % variants.size()]
			interpretation = "Artifact absorbs mechanical energy unusually well."
		"radioactive":
			var absorption: float = rng.randf_range(40.0, 99.0) * clampf(quality, 0.2, 1.0)
			var variants := [
				"Radiation counts drop sharply near the artifact (%.1f%% absorption)." % absorption,
				"Detector shows %.1f%% attenuation within 0.5m of the object." % absorption,
				"Artifact absorbs %.1f%% of incident radiation without re-emitting." % absorption,
				"Shielding effect measured at %.1f%%." % absorption
			]
			content = variants[rng.randi() % variants.size()]
			interpretation = "Artifact absorbs ionizing radiation without measurable emission."
			extras["radiation_absorption_pct"] = absorption
		_:
			content = "Generic observation recorded."
			interpretation = "No clear anomaly detected."
			confidence = "low"
			obs_type = "generic"

	var obs := {
		"content": content,
		"interpretation": interpretation,
		"confidence": confidence,
		"type": obs_type
	}
	for key in extras:
		obs[key] = extras[key]
	observations.append(obs)

	return observations
