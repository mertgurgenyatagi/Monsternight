class_name Countdown
extends Node2D
## The timer for every decision: a paper tag with the seconds left as a number. Its origin is the
## tag's middle. `start(seconds)` begins, `timed_out` fires at 0, and `stop()` ends it early. It
## never pauses, because the match keeps running behind Settings. At `LOW_SECONDS` and below it
## turns red, shakes and ticks once a second.

signal timed_out

const SIZE := Vector2(132, 92)
const FONT_SIZE := 64
const LOW_SECONDS := 5
const INK := Color("2a1a22")
const RED := Color("c0282e")
const CREAM := Color(1.0, 0.93, 0.78)
const DISPLAY := preload("res://assets/fonts/display.ttf")

var time_left := 0.0
var duration := 1.0
var running := false

var _shown := -1
var _label: Label
var _paper: Sprite2D


func _ready() -> void:
	_paper = Sprite2D.new()
	_paper.texture = preload("res://assets/art/ui/panel.png")
	_paper.scale = SIZE / _paper.texture.get_size()
	_paper.self_modulate = CREAM
	add_child(_paper)
	PaperShadow.add(_paper)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.size = SIZE
	_label.position = -SIZE / 2.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", DISPLAY)
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", INK)
	add_child(_label)


## Starts counting down from `seconds`. Starting again restarts it.
func start(seconds: float) -> void:
	duration = seconds
	time_left = seconds
	running = true
	_shown = -1
	_show(ceili(seconds))


## Stops with no sound and no signal.
func stop() -> void:
	running = false


func _process(delta: float) -> void:
	if not running:
		return
	time_left = maxf(time_left - delta, 0.0)
	_show(ceili(time_left))
	if time_left <= 0.0:
		running = false
		Sound.play("timer_out")
		timed_out.emit()


# Writes the number; each new second in the low range ticks, turns red and pulses.
func _show(seconds: int) -> void:
	if seconds == _shown:
		return
	_shown = seconds
	_label.text = str(seconds)
	var low := seconds <= LOW_SECONDS
	_label.add_theme_color_override("font_color", RED if low else INK)
	if low and seconds > 0:
		Sound.play("timer_low")
		PaperMotion.squash(self)
		PaperMotion.shake(self)
