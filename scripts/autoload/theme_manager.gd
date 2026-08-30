extends Node

var palette := {
	"bg": Color("#0e1116"),
	"panel": Color("#151a21"),
	"panel_dark": Color("#11151b"),
	"border": Color("#26303d"),
	"border_accent": Color("#33d6ff"),
	"text": Color("#d8dee9"),
	"text_muted": Color("#7f8fa6"),
	"accent": Color("#33d6ff"),
	"teal": Color("#2ec4b6"),
	"amber": Color("#ffb347"),
	"danger": Color("#ff4d4d"),
	"success": Color("#5cb85c")
}

func _ready():
	_build_theme.call_deferred()
	_add_background.call_deferred()

func _build_theme():
	var theme := _build_theme_resource()
	var root := get_tree().root
	root.theme = theme

func _add_background():
	var root := get_tree().root
	var bg := ColorRect.new()
	bg.color = palette["bg"]
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	root.move_child(bg, 0)

func _build_theme_resource() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 15

	theme.set_color("font_color", "Label", palette["text"])
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.35))
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_constant("shadow_offset_x", "Label", 1)

	theme.set_color("font_color", "RichTextLabel", palette["text"])
	theme.set_color("default_color", "RichTextLabel", palette["text"])

	theme.set_color("font_color", "LinkButton", palette["accent"])
	theme.set_color("font_hover_color", "LinkButton", palette["border_accent"])

	# Buttons
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = palette["panel"]
	btn_normal.border_color = palette["border"]
	btn_normal.border_width_left = 1
	btn_normal.border_width_right = 1
	btn_normal.border_width_top = 1
	btn_normal.border_width_bottom = 1
	btn_normal.set_corner_radius_all(6)
	btn_normal.set_content_margin_all(8)

	var btn_hover := btn_normal.duplicate()
	btn_hover.border_color = palette["border_accent"]
	btn_hover.bg_color = Color("#1c2430")

	var btn_pressed := btn_hover.duplicate()
	btn_pressed.bg_color = Color("#1a2430")

	var btn_disabled := btn_normal.duplicate()
	btn_disabled.bg_color = Color("#13171d")
	btn_disabled.border_color = Color("#1c222b")

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("focus", "Button", btn_hover)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_color("font_color", "Button", palette["text"])
	theme.set_color("font_hover_color", "Button", Color("#ffffff"))
	theme.set_color("font_pressed_color", "Button", palette["accent"])
	theme.set_color("font_disabled_color", "Button", palette["text_muted"])

	# Panels
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = palette["panel"]
	panel_style.border_color = palette["border"]
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(10)
	theme.set_stylebox("panel", "Panel", panel_style)

	var panel_container_style := panel_style.duplicate()
	panel_container_style.set_corner_radius_all(8)
	theme.set_stylebox("panel", "PanelContainer", panel_container_style)

	# LineEdit
	var le_normal := StyleBoxFlat.new()
	le_normal.bg_color = palette["panel_dark"]
	le_normal.border_color = palette["border"]
	le_normal.border_width_left = 1
	le_normal.border_width_right = 1
	le_normal.border_width_top = 1
	le_normal.border_width_bottom = 1
	le_normal.set_corner_radius_all(5)
	le_normal.content_margin_left = 8
	le_normal.content_margin_right = 8
	le_normal.content_margin_top = 4
	le_normal.content_margin_bottom = 4
	var le_focus := le_normal.duplicate()
	le_focus.border_color = palette["accent"]
	theme.set_stylebox("normal", "LineEdit", le_normal)
	theme.set_stylebox("focus", "LineEdit", le_focus)
	theme.set_color("font_color", "LineEdit", palette["text"])
	theme.set_color("caret_color", "LineEdit", palette["accent"])

	# ScrollBar
	var sb_grabber := StyleBoxFlat.new()
	sb_grabber.bg_color = Color("#2c3540")
	sb_grabber.set_corner_radius_all(3)
	theme.set_stylebox("grabber", "VScrollBar", sb_grabber)
	theme.set_stylebox("grabber", "HScrollBar", sb_grabber)
	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color = palette["panel_dark"]
	theme.set_stylebox("bg", "VScrollBar", sb_bg)
	theme.set_stylebox("bg", "HScrollBar", sb_bg)

	# ScrollContainer no background by default; Panel used for observations
	theme.set_color("font_color", "ScrollBar", palette["text"])

	return theme