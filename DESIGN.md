# DESIGN.md - PROJECT JANUS

## Core Concept
PROJECT JANUS is a single-player scientific research and facility-management simulation where the player experimentally investigates unknown artifacts without knowing their properties.

## Development Phases
- **Phase 0**: Project Foundation ✅
- **Phase 1**: JANUS 0.01 - Prove experimentation is compelling ✅
- **Phase 2**: External playtest with 10-20 people
- **Phase 3**: JANUS 0.1 - Expanded features if Phase 2 validates
- **Phase 4**: Vertical slice - 60-120 min polished gameplay
- **Phase 5**: Demo for Steam

## Key Design Principles
1. **Discovery through experimentation** - Player figures out artifact properties via experiments
2. **Wrong experiments still teach** - Even failed experiments provide observations
3. **Keep some uncertainty** - Don't explain everything immediately
4. **Catastrophe must follow rules** - Disasters feel predictable in hindsight
5. **Player forms hypotheses** - The core loop: try something → observe → hypothesize → test
6. **Never turn discovery into a progress bar** - Knowledge comes from meaningful experiments
7. **Science is procedural, not LLM-dependent**

## Current State (JANUS 0.01)
### Implemented Features
- 8 experiments: Passive Observation, Heating, Cooling, Electrical Exposure, X-Ray, EM Low, EM Mid, EM Resonance
- 3 scientists with unique skills and traits
- Knowledge progression: unknown → suspected → confirmed
- 1 discovery: DISC_GRAV_ATTENUATION (gravitational attenuation)
- Player names discovery
- HELIOS rival with own artifact and intelligence reports
- Technology unlock: Experimental Field Sensor
- Atomic save/load with schema versioning
- Settings screen (volume, fullscreen)
- Seeded RNG for deterministic simulation
- Scientist traits affect experiment quality
- Skill breakdown on results

### Not Yet Implemented
- Multiple artifacts for player
- Resource management (budget, power, personnel)
- Facility construction
- Incidents and containment
- Sound and art
- Multiple discoveries
- Scientist experience and injuries

## Acceptance Criteria - Phase 0 ✅
All 18 steps verified:
1. Launch game ✅
2. Create organization ✅
3. Begin campaign ✅
4. View J-001 ✅
5. Inspect three researchers ✅
6. Choose a researcher ✅
7. Perform an experiment ✅
8. Receive a result ✅
9. See knowledge update ✅
10. Continue experimenting ✅
11. Receive HELIOS intelligence ✅
12. Confirm a discovery ✅
13. Name that discovery ✅
14. Unlock Field Sensor ✅
15. Save ✅
16. Exit ✅
17. Reload ✅
18. See identical campaign state ✅
