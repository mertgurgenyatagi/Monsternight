class_name Candle
extends Node2D
## The timer for every decision: a candle that burns down from the top. Its origin is the
## middle of its base. `start(seconds)` lights it, `timed_out` fires when it goes out, and
## `stop()` snuffs it early. It never pauses, because the match keeps running behind Settings.

signal timed_out

const SIZE := Vector2(120, 400)
const CAP := 140.0 # the wick and the drips at the top, which never shrink
const SLICE := Rect2(0, 200, 120, 20) # a plain bit of wax, stretched to make the body
const WICK_X := 58.0
const LOW_SECONDS := 3.0

var time_left := 0.0
var duration := 1.0
var burning := false

var _fill := 0.0 # how much of the candle shows; it can pass 1 for a moment while relighting
var _relighting := false
var _warned := false
var _body: Sprite2D
var _cap: Sprite2D
var _flame: Flame
var _tween: Tween


func _ready() -> void:
	var texture := preload("res://assets/art/ui/candle.png")
	_body = Sprite2D.new()
	_body.texture = texture
	_body.centered = false
	_body.region_enabled = true
	_body.region_rect = SLICE
	add_child(_body)
	_cap = Sprite2D.new()
	_cap.texture = texture
	_cap.centered = false
	_cap.region_enabled = true
	_cap.region_rect = Rect2(0, 0, SIZE.x, CAP)
	add_child(_cap)
	_flame = Flame.new()
	add_child(_flame)
	_flame.snuff(0.0)
	_layout()


## Lights the candle for `seconds`. If it was burning, or out, it springs back to full height
## and the flame pops back on.
func start(seconds: float) -> void:
	duration = seconds
	time_left = seconds
	burning = true
	_warned = false
	_relighting = true
	_flame.light()
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "_fill", 1.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func() -> void: _relighting = false)


## Puts the candle out early, with no sound and no signal.
func stop() -> void:
	if not burning:
		return
	burning = false
	_flame.snuff()


func _process(delta: float) -> void:
	if burning:
		time_left = maxf(time_left - delta, 0.0)
		if time_left <= LOW_SECONDS and not _warned:
			_warned = true
			_flame.sputter = 1.0
			Sound.play("timer_low")
		if time_left <= 0.0:
			burning = false
			_flame.snuff()
			Sound.play("timer_out")
			timed_out.emit()
	if not _relighting and duration > 0.0:
		_fill = time_left / duration
	_layout()


# The body shrinks from its base; the cap and the flame ride down on top of it.
func _layout() -> void:
	var body_height := (SIZE.y - CAP) * maxf(_fill, 0.0)
	_body.scale = Vector2(1.0, body_height / SLICE.size.y)
	_body.position = Vector2(-SIZE.x / 2, -body_height)
	_cap.position = Vector2(-SIZE.x / 2, -body_height - CAP)
	_flame.position = Vector2(WICK_X - SIZE.x / 2, -body_height - CAP + 8.0)
