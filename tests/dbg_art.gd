extends Node

func _ready():
	_setup.call_deferred()

func _setup():
	GameState.initialize_new_campaign({"name": "Art Debug"})
	var pack: PackedScene = load("res://scenes/main/main_menu.tscn")
	var inst: Node = pack.instantiate()
	get_tree().root.add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	for path in ["Card", "Card/VBox", "Card/VBox/logo_rect", "Card/VBox/title_label"]:
		var c: Control = inst.get_node(path) as Control
		print("DBG %s pos=%s size=%s vis=%s" % [path, c.position, c.size, c.visible])
	var vbox: BoxContainer = inst.get_node("Card/VBox") as BoxContainer
	print("DBG vbox alignment=%d" % vbox.alignment)
	get_tree().quit()
