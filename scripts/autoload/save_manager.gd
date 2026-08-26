extends Node

const SAVE_DIR := "user://saves/"
const SAVE_FILE := "campaign.json"
const TEMP_FILE := "campaign.json.tmp"
const SCHEMA_VERSION := 1

func _ready():
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game() -> bool:
	var dir := DirAccess.open(SAVE_DIR)
	if not dir:
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		dir = DirAccess.open(SAVE_DIR)
		if not dir:
			push_error("Cannot create save directory: " + SAVE_DIR)
			return false

	var data: Dictionary = GameState.get_save_data()
	data["save_schema_version"] = SCHEMA_VERSION
	var json_string := JSON.stringify(data, "\t")

	var temp_path := SAVE_DIR.path_join(TEMP_FILE)
	var final_path := SAVE_DIR.path_join(SAVE_FILE)

	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if not file:
		push_error("Cannot open temp save file for writing: " + temp_path)
		return false
	file.store_string(json_string)
	file.close()

	if not FileAccess.file_exists(temp_path):
		push_error("Temp save file does not exist after write")
		return false

	dir.remove(final_path)
	var err := dir.rename(temp_path, final_path)
	if err != OK:
		push_error("Failed to rename temp save to final: " + final_path)
		return false

	EventBus.campaign_saved.emit()
	return true

func load_game() -> bool:
	var path := SAVE_DIR.path_join(SAVE_FILE)
	if not FileAccess.file_exists(path):
		push_warning("No save file found at: " + path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Cannot open save file for reading: " + path)
		return false
	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("Failed to parse save file: " + json.get_error_message())
		return false
	if not json.data is Dictionary:
		push_error("Save file is not a dictionary")
		return false

	var save_data: Dictionary = json.data
	var save_version: int = save_data.get("save_schema_version", 0)
	if save_version < SCHEMA_VERSION:
		save_data = _migrate_save(save_data, save_version)

	GameState.load_save_data(save_data)
	return true

func _migrate_save(data: Dictionary, from_version: int) -> Dictionary:
	if from_version == 0:
		data["save_schema_version"] = 1
		if not data.has("elapsed_days"):
			data["elapsed_days"] = 0
		if not data.has("seed"):
			data["seed"] = randi()
		push_warning("Migrated save from version 0 to 1")
	return data

func has_save() -> bool:
	var path := SAVE_DIR.path_join(SAVE_FILE)
	return FileAccess.file_exists(path)

func delete_save() -> void:
	var path := SAVE_DIR.path_join(SAVE_FILE)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
