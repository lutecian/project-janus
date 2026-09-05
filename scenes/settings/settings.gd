extends Control

@onready var volume_label: Label = $VBox/VolumeLabel
@onready var volume_slider: HSlider = $VBox/VolumeSlider
@onready var fullscreen_label: Label = $VBox/FullscreenLabel
@onready var fullscreen_toggle: CheckButton = $VBox/FullscreenToggle
@onready var gore_label: Label = $VBox/GoreLabel
@onready var gore_toggle: CheckButton = $VBox/GoreToggle
@onready var audio_label: Label = $VBox/AudioLabel
@onready var btn_test_sound: Button = $VBox/btn_test_sound
@onready var sound_result: Label = $VBox/sound_result
@onready var btn_reset_save: Button = $VBox/btn_reset_save
@onready var btn_back: Button = $VBox/btn_back

func _ready():
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	gore_toggle.toggled.connect(_on_gore_toggled)
	btn_test_sound.pressed.connect(_on_test_sound)
	btn_reset_save.pressed.connect(_on_reset_save)
	btn_back.pressed.connect(_on_back)
	_load_settings()
	audio_label.text = "Audio: " + AudioManager.get_driver_info()

func _load_settings():
	var settings := ConfigFile.new()
	if settings.load("user://settings.cfg") == OK:
		var vol: float = settings.get_value("audio", "volume", 100.0)
		volume_slider.value = vol
		_update_volume_label(vol)
		var fs: bool = settings.get_value("display", "fullscreen", false)
		fullscreen_toggle.button_pressed = fs
		_apply_fullscreen(fs)
		var gore: bool = settings.get_value("content", "graphic", true)
		gore_toggle.button_pressed = gore
		_update_gore_label(gore)

func _save_settings():
	var settings := ConfigFile.new()
	settings.set_value("audio", "volume", volume_slider.value)
	settings.set_value("display", "fullscreen", fullscreen_toggle.button_pressed)
	settings.set_value("content", "graphic", gore_toggle.button_pressed)
	settings.save("user://settings.cfg")

func _on_volume_changed(value: float):
	_update_volume_label(value)
	_save_settings()

func _update_volume_label(value: float):
	volume_label.text = "Volume: %d%%" % int(value)
	AudioManager.apply_volume(value)

func _on_fullscreen_toggled(pressed: bool):
	_apply_fullscreen(pressed)
	_save_settings()

func _apply_fullscreen(pressed: bool):
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen_label.text = "Fullscreen: ON"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen_label.text = "Fullscreen: OFF"

func _on_gore_toggled(pressed: bool):
	_update_gore_label(pressed)
	_save_settings()

func _update_gore_label(pressed: bool):
	gore_label.text = "Graphic content: ON" if pressed else "Graphic content: OFF"

func _on_test_sound():
	AudioManager.play_sfx("alarm")
	AudioManager.start_music("menu")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if AudioManager.is_voice_active():
		sound_result.text = "Sound check: PLAYING (if you hear nothing, check system volume/output device)."
	else:
		sound_result.text = "Sound check: SILENT (driver reports no active voice — please report this)."

func _on_reset_save():
	SaveManager.delete_save()
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
