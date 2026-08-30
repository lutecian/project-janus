# BALANCE DOCUMENT — PROJECT JANUS

## Knowledge Progression
- Total knowledge to confirm discovery: 70% (CONFIRMED_THRESHOLD)
- Starting knowledge: 0%
- Knowledge gain formula (game_state.gd `run_experiment`):
  `gain = base_gain + round((quality - 1.0) * base_gain * 0.5)`, guaranteed >= base_gain.
  Base gains no longer get floored by low quality.
- Experiment base gains (current data):
  | Experiment | Base gain |
  |-----------|-----------|
  | Passive Observation | 3 |
  | Heating / Cooling / Electrical | 4 |
  | X-Ray / EM Low | 3 |
  | EM Mid | 4 |
  | EM Resonance | 6 |
  | Acoustic / Laser / Vibration | 3 |
  | Radioactive (tech-gated, dangerous) | 4 |
- Tech bonus: +20% quality (Field Sensor), +10% (Gravity Sensor)

## Economy (verified via automated balance sim, seed-stable)
Four strategies simulated from a fresh campaign to confirmation:
| Strategy | Experiments | Budget ($) | Remaining ($) |
|---------|------------|-----------|---------------|
| Max-gain, Dr. Chen | 14 | 8,100 | 4,900 |
| Max-gain, Dr. Vasquez | 14 | 7,600 | 5,400 |
| Cost-efficient, Dr. Chen | 22 | 4,400 | 8,600 |
| Cost-efficient, Dr. Vasquez | 22 | 4,400 | 8,600 |

- All paths confirm at 70%+ without bankruptcy. Target pacing 14-22 experiments.
- Starting budget: $10,000. Monthly grant: +$5,000 at day 30/60/120, +$7,500 at day 90.
- Budget events: +$3,000 on discovery suspected, +$2,000 on HELIOS 60%.
- Experiment costs: Passive $200, Heating/Cooling/Electrical $400, X-Ray $600,
  EM Low $500, EM Mid $700, EM Resonance $900, Acoustic $500, Laser $650,
  Vibration $600, Radioactive $1,200.

## Scientist Skills (baseline)
| Scientist | Physics | Observation | Curiosity | Specialty |
|-----------|---------|-------------|-----------|-----------|
| Dr. Chen | 65 | 50 | 85 | Theory |
| Dr. Reed | 80 | 55 | 65 | Fieldwork |
| Dr. Vasquez | 70 | 75 | 55 | Analysis |

## Quality Formula
```
quality = (relevant_skill * 0.5 + observation * 0.3 + curiosity * 0.1) / 100
quality += trait_bonus
quality += random_variation (±15%)
```

## Critical Success / Malfunction
- Critical success: 5% + ambitious/curious trait bonus
- Malfunction: 5% - careful trait reduction
- Lucky timing: 10% - skeptical trait reduction

## HELIOS Progression
- Base advance: 1.5 per experiment, scaled by player knowledge (0.5x-1.0x)
- Cap: 100; thresholds for intel: 15, 30, 60, 90
- Stops advancing once player confirms discovery

## Experiment Unlocks
| Progress | Experiments |
|----------|-------------|
| 0% | Passive, Heating, Cooling, Electrical |
| 10% | X-Ray |
| 15% | EM Low |
| 25% | EM Mid |
| 30% | Acoustic, Laser |
| 40% | EM Resonance |
| 45% | Vibration |
| 50% | Radioactive (also requires Thermal Containment) |

## Tech Unlock (4-branch tree)
| Tech | Unlock condition | Effect |
|------|-----------------|--------|
| Experimental Field Sensor | Confirm grav attenuation | +20% observation quality |
| Thermal Containment | Confirm energy absorption | -50% incident chance, enables Radioactive |
| Gravity Sensor | Confirm grav amplification | +10% quality |
| Field Stabilizer | Confirm grav nullification | -50% incident severity (downgrade + halve costs) |

## Incidents
- Thermal Containment halves incident trigger chance.
- Field Stabilizer downgrades severity one step and halves budget/days effects.
- Dangerous experiments (Radioactive) carry a 12% incident risk (4% with Field Stabilizer).
- Incident cooldown: 5 days; max 8 per campaign.

## Secondary Discoveries (simulation-driven)
Confirmed by tallying `discovery_hint`-tagged observations, not raw experiment counts:
- Suspected: >= 2 evidence observations
- Confirmed: >= 4 evidence observations, OR >= 2 distinct experiment types
  corroborating + >= 1 high-confidence observation
- Evidence hints: energy_absorption (heating/cooling/passive), grav_attenuation
  (EM resonance), grav_amplification (EM mid), grav_nullification (EM low).
