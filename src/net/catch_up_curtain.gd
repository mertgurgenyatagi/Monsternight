class_name CatchUpCurtain
extends CanvasLayer
## Hides a rejoining copy's replay: a dark sheet over everything with "Catching up..." and a thin
## paper bar that fills as the missed decisions are replayed. `open` fades it away on the live turn.
## It ignores the engine's time scale, because the replay runs fast.

const DISPLAY := preload("res://assets/fonts/display.ttf")
const SHEET := Color("1b0f22")
const PAPER := Color("fbe9d0")
const INK := Color("2a1a22")
const BAR := Rect2(660, 640, 600, 22)

## How much of the replay is done, 0 to 1.
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		if _art:
			_art.queue_redraw()

var _art: Control
var _fade := 1.0


func _init() -> void:
	layer = 95
	_art = Control.new()
	_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art.mouse_filter = Control.MOUSE_FILTER_STOP # no clicks reach the game underneath
	_art.draw.connect(_draw_art)
	add_child(_art)


func _draw_art() -> void:
	var size := _art.get_viewport_rect().size
	var k := size.x / 1920.0
	_art.draw_rect(Rect2(Vector2.ZERO, size), Color(SHEET, _fade))
	var text := tr("CATCHING_UP")
	_art.draw_string(DISPLAY, Vector2(0, 560) * k, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, int(86 * k),
			Color(PAPER, _fade))
	var bar := Rect2(BAR.position * k, BAR.size * k)
	_art.draw_rect(bar.grow(5.0 * k), Color(INK, _fade))
	_art.draw_rect(bar, Color(PAPER, _fade * 0.25))
	_art.draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), Color(PAPER, _fade))


## Fades the curtain out and removes it.
func open() -> void:
	var tween := create_tween().set_ignore_time_scale(true)
	tween.tween_method(func(v: float) -> void:
		_fade = v
		_art.queue_redraw(), 1.0, 0.0, 0.6)
	tween.tween_callback(queue_free)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
