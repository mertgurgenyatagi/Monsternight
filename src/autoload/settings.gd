extends Node
## The player's settings: music volume, effects volume and fullscreen. They are loaded from
## user://settings.cfg and applied before the first scene, and every change is applied at once
## and saved. It also opens the panel on Esc during a match.

const PATH := "user://settings.cfg"
const PANEL := preload("res://src/settings/settings_panel.tscn")
const LANGUAGES := ["en", "tr"]

var music := 1.0 : set = set_music
var sfx := 1.0 : set = set_sfx
var fullscreen := false : set = set_fullscreen
var language := "en" : set = set_language

var _panel: Node


func _ready() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		music = clampf(file.get_value("audio", "music", 1.0), 0.0, 1.0)
		sfx = clampf(file.get_value("audio", "sfx", 1.0), 0.0, 1.0)
		fullscreen = file.get_value("display", "fullscreen", false)
		language = file.get_value("display", "language", "en")
	_apply_language()
	_apply_music()
	_apply_sfx()
	_apply_fullscreen()


## Esc opens the panel in any scene while a match is on (the title has its own button). The
## panel closes itself on Esc, so this only sees the Esc that finds it closed.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not Match.players.is_empty():
		get_viewport().set_input_as_handled()
		open()


## Opens the settings panel over whatever is on screen. It touches nothing behind it and pauses
## nothing, so the match goes on under it. Asking again while it's open does nothing.
func open() -> void:
	if is_instance_valid(_panel):
		return
	_panel = PANEL.instantiate()
	get_tree().root.add_child(_panel)


func set_music(value: float) -> void:
	music = value
	_apply_music()


func set_sfx(value: float) -> void:
	sfx = value
	_apply_sfx()


func set_language(value: String) -> void:
	language = value if value in LANGUAGES else "en"
	_apply_language()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_fullscreen()


## Writes the settings to disk. The panel calls it when a change is finished.
func save() -> void:
	var file := ConfigFile.new()
	file.set_value("audio", "music", music)
	file.set_value("audio", "sfx", sfx)
	file.set_value("display", "fullscreen", fullscreen)
	file.set_value("display", "language", language)
	file.save(PATH)


func _apply_music() -> void:
	_set_bus("Music", music)


func _apply_sfx() -> void:
	_set_bus("SFX", sfx)


func _apply_language() -> void:
	TranslationServer.set_locale(language)


func _apply_fullscreen() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _set_bus(bus: String, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(volume))
		AudioServer.set_bus_mute(index, volume <= 0.001)
