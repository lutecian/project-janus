extends Control

@onready var title_label: Label = $ScrollContainer/VBox/title_label
@onready var result_text: RichTextLabel = $ScrollContainer/VBox/result_text
@onready var skill_breakdown: RichTextLabel = $ScrollContainer/VBox/skill_breakdown
@onready var knowledge_label: Label = $ScrollContainer/VBox/knowledge_label
@onready var helios_label: Label = $ScrollContainer/VBox/helios_label
@onready var btn_continue: Button = $ScrollContainer/VBox/ButtonRow/btn_continue
@onready var btn_name_discovery: Button = $ScrollContainer/VBox/discovery_panel/btn_name_discovery
@onready var discovery_input: LineEdit = $ScrollContainer/VBox/discovery_panel/discovery_input
@onready var discovery_panel: VBoxContainer = $ScrollContainer/VBox/discovery_panel
@onready var status_label: Label = $ScrollContainer/VBox/status_label
@onready var btn_save: Button = $ScrollContainer/VBox/ButtonRow/btn_save
@onready var narrative_label: RichTextLabel = $ScrollContainer/VBox/NarrativePanel/narrative_label

func _ready():
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_name_discovery.pressed.connect(_on_name_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	discovery_panel.visible = false
	_display_results()

func _display_results():
	if GameState.experiment_history.is_empty():
		title_label.text = "No experiment data."
		return

	var last_result: Dictionary = GameState.experiment_history[-1]
	title_label.text = "EXPERIMENT RESULT: %s" % last_result.get("experiment_name", "Unknown")

	var text := ""
	text += "Lead Researcher: %s\n" % last_result.get("scientist_name", "Unknown")
	text += "Observation Quality: %.0f%%\n" % (last_result.get("quality", 0.0) * 100)
	text += "Knowledge Gained: +%d\n" % last_result.get("knowledge_gain", 0)
	text += "Day: %d\n\n" % last_result.get("day", 0)

	var observations: Array = last_result.get("observations", [])
	text += "--- OBSERVATIONS ---\n"
	for obs in observations:
		text += "  > %s\n" % obs.get("content", "Nothing notable.")
		text += "    Interpretation: %s\n" % obs.get("interpretation", "Unclear.")
		text += "    Confidence: %s\n\n" % obs.get("confidence", "low")

	result_text.text = text

	var scientist_name: String = last_result.get("scientist_name", "")
	var exp_name: String = last_result.get("experiment_name", "")
	var breakdown := "--- SKILL BREAKDOWN ---\n"
	for s in GameState.scientists:
		if (s.get("first_name", "") + " " + s.get("last_name", "")) == scientist_name:
			var skills: Dictionary = s.get("skills", {})
			var traits: Array = s.get("traits", [])
			var relevant: String = last_result.get("relevant_skill", "observation")
			breakdown += "Scientist: %s %s\n" % [s.get("first_name", "?"), s.get("last_name", "?")]
			breakdown += "  Relevant skill (%s): %d\n" % [relevant, skills.get(relevant, 0)]
			breakdown += "  Observation: %d\n" % skills.get("observation", 0)
			breakdown += "  Curiosity: %d\n" % skills.get("curiosity", 0)
			if not traits.is_empty():
				breakdown += "  Traits: %s\n" % ", ".join(traits)
			breakdown += "  Quality: %.0f%%\n" % (last_result.get("quality", 0.0) * 100)
			breakdown += "  Knowledge gain: +%d" % last_result.get("knowledge_gain", 0)
			break
	skill_breakdown.text = breakdown

	var narrative: String = last_result.get("narrative", "")
	if not narrative.is_empty():
		narrative_label.text = narrative
		narrative_label.visible = true
	else:
		narrative_label.visible = false

	var progress: int = GameState.knowledge["progress"]
	var state: String = GameState.knowledge["state"]
	knowledge_label.text = "Total Knowledge: %d%% — State: %s" % [progress, state.capitalize()]
	helios_label.text = "HELIOS Progress: %d%%" % GameState.helios["progress"]

	if GameState.discovery["state"] == "confirmed" and GameState.discovery["player_name"].is_empty():
		discovery_panel.visible = true
		status_label.text = "Discovery confirmed! Name your finding."
	elif GameState.discovery["state"] == "suspected":
		status_label.text = "Scientists suspect a phenomenon. Keep experimenting."
	else:
		status_label.text = ""

func _on_continue_pressed():
	if GameState.discovery["state"] == "confirmed" and not GameState.discovery["player_name"].is_empty():
		get_tree().change_scene_to_file("res://scenes/experiment/results/breakthrough.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/experiment/experiment_selection.tscn")

func _on_name_pressed():
	var name_text := discovery_input.text.strip_edges()
	if name_text.is_empty():
		status_label.text = "Please enter a name."
		return
	GameState.name_discovery(name_text)
	discovery_panel.visible = false
	status_label.text = "Discovery named: %s" % name_text
	SaveManager.save_game()

func _on_save_pressed():
	SaveManager.save_game()
	status_label.text = "Campaign saved."
