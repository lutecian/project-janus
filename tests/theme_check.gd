extends Node

var _failures: int = 0

func _ready():
	# Wait a couple frames so the deferred theme/background apply.
	await get_tree().process_frame
	await get_tree().process_frame

	var root := get_tree().root
	if root.theme == null:
		_fail("root theme should not be null (ThemeManager should have applied it)")
	else:
		print("root theme font_size: ", root.theme.default_font_size)
		if root.theme.has_stylebox("normal", "Button"):
			print("Button 'normal' stylebox present: OK")
		else:
			_fail("Button normal stylebox missing from theme")

	# Background ColorRect should exist at root index 0
	var bg_found := false
	for child in root.get_children():
		if child is ColorRect:
			bg_found = true
			print("Background ColorRect found at index ", child.get_index(), " color ", (child as ColorRect).color.to_html(false))
	if not bg_found:
		_fail("no background ColorRect found on root")

	# Ensure bg is behind the visible scene (a ChangeScene child) - bg index 0
	var bg_is_first: bool = root.get_children().size() > 0 and root.get_child(0) is ColorRect
	if not bg_is_first:
		_fail("background ColorRect should be the first root child (behind everything)")

	# accent_card type variation should resolve a panel stylebox
	var accent_sb: StyleBox = root.theme.get_stylebox("panel", "accent_card")
	if accent_sb == null:
		_fail("accent_card variation stylebox missing")
	else:
		print("accent_card stylebox present: OK")

	# Laboratory scene should apply the accent_card variation on its artifact panel
	var lab := load("res://scenes/laboratory/laboratory.tscn").instantiate() as Control
	root.add_child(lab)
	await get_tree().process_frame
	var artifacts_panel: PanelContainer = lab.get_node_or_null("MarginContainer/VBox/artifacts_panel")
	if artifacts_panel == null:
		_fail("artifacts_panel not found in laboratory")
	else:
		var resolved: StyleBox = artifacts_panel.get_theme_stylebox("panel")
		if resolved == null:
			_fail("artifacts_panel has no resolved panel stylebox")
		else:
			print("laboratory artifact panel resolves stylebox: ", resolved is StyleBoxFlat)
	lab.queue_free()

	if _failures == 0:
		print("THEME_OK")
	else:
		print("%d THEME FAILURES" % _failures)
	get_tree().quit()

func _fail(msg: String):
	_failures += 1
	push_error("THEME FAIL: " + msg)
