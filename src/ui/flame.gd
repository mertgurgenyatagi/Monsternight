class_name Flame
extends Node2D
## A flickering paper flame. Its origin is the bottom of the flame, so it sits on a wick or a
## torch. It steps at the game's 25 FPS like everything else. Candles and torches both use it.

const SIZE := Vector2(64, 96)

## 0 for a calm flicker, up to 1 for a sputter.
var sputter := 0.0

var _sprite: Sprite2D
var _size := 1.0
var _wobble := Vector2.ZERO # the current flicker: scale change and tilt in degrees
var _tween: Tween


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/art/ui/flame.png")
	_sprite.centered = false
	_sprite.offset = Vector2(-SIZE.x / 2, -SIZE.y)
	add_child(_sprite)


func _process(_delta: float) -> void:
	var strength := 0.07 + 0.25 * sputter
	var target := Vector2(randf_range(-strength, strength), randf_range(-3.0, 3.0) * (1.0 + 3.0 * sputter))
	_wobble = _wobble.lerp(target, 0.6)
	var dip := 1.0
	if sputter > 0.0 and randf() < 0.12 * sputter:
		dip = randf_range(0.35, 0.7) # a gasp that nearly goes out
	_sprite.scale = Vector2(1.0 - _wobble.x * 0.5, 1.0 + _wobble.x) * _size * dip
	_sprite.rotation_degrees = _wobble.y


## Shrinks to nothing.
func snuff(duration := 0.35) -> void:
	_change_size(0.0, duration, Tween.TRANS_BACK, Tween.EASE_IN)


## Pops back on, with an overshoot.
func light(duration := 0.4) -> void:
	sputter = 0.0
	_change_size(1.0, duration, Tween.TRANS_BACK, Tween.EASE_OUT)


func _change_size(to: float, duration: float, trans: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "_size", to, duration).set_trans(trans).set_ease(ease_type)
