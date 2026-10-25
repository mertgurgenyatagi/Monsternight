class_name SeatCard
extends Node2D
## One seat in the room: a paper card with the player's name, a gold crown for the host and a
## tick that pops when they are ready. Its origin is its center.

const SIZE := Vector2(240, 300)
const INK := Color(0.29, 0.13, 0.21)
const GREEN := Color("3f8f4a")
const GOLD := Color("e0a82e")
const DISPLAY := preload("res://assets/fonts/display.ttf")

var peer_id := 0

var _name: Label
var _tick: Polygon2D
var _crown: Polygon2D
var _ready := false


func _init(id: int) -> void:
	peer_id = id
	var face := Sprite2D.new()
	face.texture = preload("res://assets/art/ui/card.png")
	face.centered = false
	face.position = -SIZE / 2
	face.scale = SIZE / face.texture.get_size()
	add_child(face)
	PaperShadow.add(face)

	_name = Label.new()
	_name.size = Vector2(SIZE.x - 40, 80)
	_name.position = Vector2(-_name.size.x / 2, -30)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name.add_theme_font_override("font", DISPLAY)
	_name.add_theme_color_override("font_color", INK)
	add_child(_name)

	_crown = Polygon2D.new()
	_crown.polygon = PackedVector2Array([Vector2(-44, 22), Vector2(-52, -26), Vector2(-24, -4),
			Vector2(0, -38), Vector2(24, -4), Vector2(52, -26), Vector2(44, 22)])
	_crown.color = GOLD
	_crown.position = Vector2(0, -90)
	_crown.visible = false
	add_child(_crown)

	_tick = Polygon2D.new()
	_tick.polygon = PackedVector2Array([Vector2(-44, 4), Vector2(-26, -12), Vector2(-8, 8), Vector2(34, -40),
			Vector2(52, -24), Vector2(-8, 44)])
	_tick.color = GREEN
	_tick.position = Vector2(0, 85)
	_tick.scale = Vector2.ZERO
	add_child(_tick)


## Shows this name (shrunk to fit), the crown for the host, and the tick for ready. The tick pops
## and the card hops when ready turns on.
func show_seat(display_name: String, host: bool, is_ready: bool) -> void:
	_name.text = display_name
	var size := 46
	while size > 20 and DISPLAY.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > _name.size.x:
		size -= 2
	_name.add_theme_font_size_override("font_size", size)
	_crown.visible = host
	if is_ready != _ready:
		_ready = is_ready
		var tween := create_tween()
		tween.tween_property(_tick, "scale", Vector2.ONE if is_ready else Vector2.ZERO, 0.3) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if is_ready:
			Sound.play("ready")
			PaperMotion.hop(self, 24.0)
