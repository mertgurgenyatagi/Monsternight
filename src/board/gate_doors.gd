class_name GateDoors
extends Node2D
## The castle gate's two doors, which swing open a little when a piece reaches the finish. It's a child
## of the gate's sprite, so its origin is the gate's foot and it's drawn in the gate's own pixels.
## Each door is a copy of half the gate's picture hinged at its outer edge, so it narrows as it
## swings; a warm light shows in the opening behind.

const TEXTURE := preload("res://assets/art/scenery/castle_gate.png")
const MIDDLE := 217.0 # where the doors meet, in the picture's pixels
const DOOR_LEFT := 74.0
const DOOR_RIGHT := 361.0
const DOOR_TOP := 88.0
const DOOR_BOTTOM := 694.0
## The doorway's outline, in the picture's pixels, to be filled with the light.
const ARCH := [Vector2(78, 690), Vector2(78, 330), Vector2(98, 235), Vector2(150, 150),
		Vector2(217, 92), Vector2(284, 150), Vector2(336, 235), Vector2(358, 330), Vector2(358, 690)]
const LIGHT := Color(1.0, 0.72, 0.32)
const OPEN_SCALE := 0.32 # how narrow a door looks when it has swung

var _doors: Array[Sprite2D] = []
var _light: Polygon2D
var _tween: Tween


func _init() -> void:
	_light = Polygon2D.new()
	_light.color = LIGHT
	_light.polygon = PackedVector2Array(ARCH.map(_local))
	_light.visible = false
	add_child(_light)
	for side in [-1.0, 1.0]:
		var door := Sprite2D.new()
		door.texture = TEXTURE
		door.centered = false
		door.region_enabled = true
		var from := DOOR_LEFT if side < 0.0 else MIDDLE
		var to := MIDDLE if side < 0.0 else DOOR_RIGHT
		door.region_rect = Rect2(from, DOOR_TOP, to - from, DOOR_BOTTOM - DOOR_TOP)
		# The door's origin is its hinge, on the outer edge.
		var hinge := from if side < 0.0 else to
		door.offset = Vector2(from - hinge, DOOR_TOP - TEXTURE.get_height())
		door.position = Vector2(hinge - TEXTURE.get_width() / 2.0, 0.0)
		add_child(door)
		_doors.append(door)


## The doors swing open, and the light shows.
func open() -> Tween:
	return _swing(OPEN_SCALE, Color(0.62, 0.52, 0.5), 0.55)


## The doors swing shut again.
func close() -> Tween:
	return _swing(1.0, Color.WHITE, 0.5)


func _swing(width: float, color: Color, duration: float) -> Tween:
	if _tween and _tween.is_valid():
		_tween.kill()
	_light.visible = true
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_BACK if width < 1.0 else Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_OUT)
	for door in _doors:
		_tween.tween_property(door, "scale:x", width, duration)
		_tween.tween_property(door, "modulate", color, duration)
	if width >= 1.0:
		_tween.chain().tween_callback(func() -> void: _light.visible = false)
	return _tween


# A point in the picture's pixels, as it lies from the gate's foot.
func _local(point: Vector2) -> Vector2:
	return point - Vector2(TEXTURE.get_width() / 2.0, TEXTURE.get_height())
