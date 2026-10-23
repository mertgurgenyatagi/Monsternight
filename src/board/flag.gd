class_name Flag
extends Sprite2D
## A paper flag on a pole that flutters: a small, uneven skew from the foot of the pole, like
## `Flame`'s flicker but slower. Its origin is the pole's foot. The board's finish and a
## finished player's portrait both use it.

const TEXTURE := preload("res://assets/art/icons/flag.png")
const POLE_X := 12.0 # the pole's distance from the picture's left edge

var _target := 0.0
var _wait := 0.0


func _init() -> void:
	texture = TEXTURE
	centered = false
	offset = Vector2(-POLE_X, -TEXTURE.get_height())


func _process(delta: float) -> void:
	_wait -= delta
	if _wait <= 0.0:
		_target = randf_range(-0.14, 0.14)
		_wait = randf_range(0.2, 0.5)
	skew = lerpf(skew, _target, 0.12)
