class_name PowerBeam
extends Node2D
## A paper wedge that shoots from a monster to someone its power reaches, so the effect can be seen
## travelling: it opens from the monster like a lantern's cone, then fades. Two layers of paper, the
## wider one paler, in the monster's own color. Everything is in `parent`'s space.

const GROW := 0.28
const FADE := 0.4
const SPREAD := 72.0 # half the base's width at the far end
const SHADOW := Vector2(7, 10)

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _color := Color.WHITE
var _grow := 0.0
var _alpha := 1.0


## Shoots a wedge of `color` from `from` to `to` and frees it once faded. `hold` is how long it
## stays fully open.
static func fire(parent: Node, from: Vector2, to: Vector2, color: Color, hold := 0.3) -> PowerBeam:
	var beam := PowerBeam.new()
	beam._from = from
	beam._to = to
	beam._color = color
	parent.add_child(beam)
	var tween := beam.create_tween()
	tween.tween_property(beam, "_grow", 1.0, GROW).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold)
	tween.tween_property(beam, "_alpha", 0.0, FADE)
	tween.tween_callback(beam.queue_free)
	tween.parallel().tween_method(func(_v: float) -> void: beam.queue_redraw(), 0.0, 1.0, GROW + hold + FADE)
	return beam


func _draw() -> void:
	var reach := (_to - _from) * _grow
	var side := (_to - _from).normalized().orthogonal()
	var spread := SPREAD * _grow
	var outer := PackedVector2Array([_from, _from + reach + side * spread, _from + reach - side * spread])
	var inner := PackedVector2Array([_from, _from + reach + side * spread * 0.5, _from + reach - side * spread * 0.5])
	draw_colored_polygon(PackedVector2Array([outer[0] + SHADOW, outer[1] + SHADOW, outer[2] + SHADOW]),
			Color(0, 0, 0, 0.25 * _alpha))
	draw_colored_polygon(outer, Color(_color, 0.45 * _alpha))
	draw_colored_polygon(inner, Color(_color.lightened(0.15), 0.75 * _alpha))
