class_name TurnNote
extends Node2D
## Online, a small paper note low on the HUD that says whose move it is: "Name is rolling..." on
## everyone else's copy, and a yellow "Your turn" on the player's own. It slides in when it first
## shows and flips when its words change. It lives on the HUD, in screen coordinates.

const AT := Vector2(960, 990)
const SIZE := Vector2(620, 78)
const FONT_SIZE := 40
const INK := Color("2a1a22")
const CREAM := Color(1.0, 0.93, 0.78)
const YOURS := Color(1.0, 0.82, 0.3)

var _paper: Sprite2D
var _label: Label
var _shown := false


func _init() -> void:
	_paper = Sprite2D.new()
	_paper.texture = preload("res://assets/art/ui/panel.png")
	_paper.scale = SIZE / _paper.texture.get_size()
	add_child(_paper)
	PaperShadow.add(_paper)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.size = SIZE
	_label.position = -SIZE / 2.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.clip_text = true
	_label.add_theme_font_override("font", preload("res://assets/fonts/display.ttf"))
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", INK)
	add_child(_label)
	position = AT
	set_meta("rest_position", AT)
	set_meta("rest_scale", Vector2.ONE)
	visible = false


## Shows `text`; `yours` makes it the bright "your move" note, with the `ready` sound.
func say(text: String, yours := false) -> void:
	if _shown and _label.text == text:
		return
	var apply := func() -> void:
		_label.text = text
		_paper.self_modulate = YOURS if yours else CREAM
	if _shown:
		PaperMotion.flip(self, apply)
	else:
		_shown = true
		apply.call()
		visible = true
		PaperMotion.slide_in(self, 2300.0, 0.0, 0.5)
	if yours:
		Sound.play("ready")


## Takes the note away.
func clear() -> void:
	if not _shown:
		return
	_shown = false
	await PaperMotion.lift_away(self, 200.0, 0.3).finished
	if not _shown:
		visible = false
