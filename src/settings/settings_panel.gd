extends CanvasLayer
## The settings overlay: a paper card set down over the screen, with the music and effects
## sliders and the fullscreen box. It depends on nothing behind it and pauses nothing. Back,
## Esc, or a click outside the card closes it.

@onready var _dim: ColorRect = $Dim
@onready var _card: NinePatchRect = $Card
@onready var _music: PaperSlider = $Card/Music
@onready var _sfx: PaperSlider = $Card/Sfx
@onready var _fullscreen: PaperToggle = $Card/Fullscreen
@onready var _back: PaperButton = $Card/Back
@onready var _language: PaperButton = $Card/Language
@onready var _in_match: Label = $Card/InMatch

const LANGUAGE_NAMES := {"en": "English", "tr": "Türkçe"}

var _closing := false


func _ready() -> void:
	PaperShadow.add(_card)
	_music.value = Settings.music
	_sfx.value = Settings.sfx
	_fullscreen.on = Settings.fullscreen
	_music.value_changed.connect(func(value: float) -> void: Settings.music = value)
	_music.released.connect(Settings.save)
	_sfx.value_changed.connect(func(value: float) -> void: Settings.sfx = value)
	_sfx.released.connect(_sample_effect)
	_fullscreen.toggled.connect(func(on: bool) -> void:
		Settings.fullscreen = on
		Settings.save())
	_back.pressed.connect(close)
	_language.pressed.connect(_next_language)
	_language.text = LANGUAGE_NAMES[Settings.language]
	_in_match.visible = not Match.players.is_empty()

	_dim.color.a = 0.0
	create_tween().tween_property(_dim, "color:a", 0.45, 0.3)
	PaperMotion.set_down(_card, func() -> void: Sound.play("card_slam", -12.0)).finished \
			.connect(func() -> void:
				_back.mouse_filter = Control.MOUSE_FILTER_STOP
				_language.mouse_filter = Control.MOUSE_FILTER_STOP)
	_back.scale = Vector2.ONE
	_language.scale = Vector2.ONE


func _input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and not _card.get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled()
		close()


## Lifts the card away and removes the panel.
func close() -> void:
	if _closing:
		return
	_closing = true
	Settings.save()
	_back.leave()
	_language.leave()
	create_tween().tween_property(_dim, "color:a", 0.0, 0.3)
	await PaperMotion.lift_away(_card).finished
	queue_free()


func _next_language() -> void:
	var languages: Array = Settings.LANGUAGES
	Settings.language = languages[(languages.find(Settings.language) + 1) % languages.size()]
	_language.text = LANGUAGE_NAMES[Settings.language]
	Settings.save()


func _sample_effect() -> void:
	Sound.play("coin_land")
	Settings.save()
