class_name Curtain
extends Node2D
## The stage curtain: two halves and a valance across the top, drawn over the whole 1920 × 1080
## screen. `spread` is how much of each half still shows, 1 for closed and about 0.1 for open. The
## title screen and the ceremony both hang one, and the board closes one to end the match.

const HALF := preload("res://assets/art/ui/curtain.png")
const TOP := preload("res://assets/art/ui/curtain_top.png")
const TOP_HIDDEN := -210.0

var _halves: Array[Sprite2D] = []
var _top: Sprite2D


func _ready() -> void:
	for side in 2:
		var half := Sprite2D.new()
		half.texture = HALF
		half.centered = false
		if side == 1:
			half.position = Vector2(1920, 0)
			half.offset = Vector2(-HALF.get_width(), 0)
			half.flip_h = true
		add_child(half)
		_halves.append(half)
	_top = Sprite2D.new()
	_top.texture = TOP
	_top.centered = false
	add_child(_top)
	for piece: CanvasItem in _halves + [_top]:
		PaperShadow.add(piece)


## Sets the curtain's spread at once. `hide_top` also lifts the valance out of sight, until the next
## `move` brings it down.
func set_spread(spread: float, hide_top := false) -> void:
	for half in _halves:
		half.scale.x = maxf(spread, 0.001)
	_top.position.y = TOP_HIDDEN if hide_top else 0.0


## The halves gather toward the sides (or spread back), easing to a stop past the mark and
## settling onto it, while their hems trail behind and swing back. The rod jolts as they go.
func move(spread: float, duration: float, delay: float) -> Tween:
	var opening := spread < _halves[0].scale.x
	var past := spread + (-0.025 if opening else 0.0)
	var tween := create_tween().set_parallel()
	for half in _halves:
		var side := 1.0 if half == _halves[0] else -1.0
		var lean := 0.06 * side * (1.0 if opening else -1.0)
		tween.tween_property(half, "scale:x", past, duration).set_delay(delay) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT if opening else Tween.EASE_IN_OUT)
		tween.tween_property(half, "scale:x", spread, 0.5).set_delay(delay + duration) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(half, "skew", lean, duration * 0.5).set_delay(delay) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(half, "skew", -lean * 0.4, duration * 0.5).set_delay(delay + duration * 0.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(half, "skew", 0.0, 0.6).set_delay(delay + duration) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _top.position.y < -1.0:
		tween.tween_property(_top, "position:y", 0.0, minf(duration * 0.5, 0.7)).set_delay(delay) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(_top, "position:y", -7.0, 0.15).set_delay(delay) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(_top, "position:y", 0.0, 0.5).set_delay(delay + 0.15) \
				.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween
