class_name PaperSlider
extends Control
## A paper slider: an ink line with a coin to drag along it. `value` runs from 0 to 1.

signal value_changed(value: float)
signal released ## the coin was let go

const INK := Color(0.29, 0.13, 0.21)
const COIN_SCALE := 0.25
const RADIUS := 32.0 # half the coin, and how far the line is inset from the ends

var value := 1.0 : set = set_value

var _coin: Sprite2D
var _dragging := false


func _ready() -> void:
	custom_minimum_size = Vector2(480, 72)
	_coin = Sprite2D.new()
	_coin.texture = preload("res://assets/art/icons/coin.png")
	_coin.scale = Vector2.ONE * COIN_SCALE
	add_child(_coin)
	PaperShadow.add(_coin)
	_place()
	resized.connect(_place)


func set_value(new_value: float) -> void:
	value = clampf(new_value, 0.0, 1.0)
	_place()
	queue_redraw()


func _draw() -> void:
	var y := size.y / 2
	var x := RADIUS + value * (size.x - RADIUS * 2)
	draw_line(Vector2(RADIUS, y), Vector2(size.x - RADIUS, y), Color(INK, 0.35), 6.0, true)
	draw_line(Vector2(RADIUS, y), Vector2(x, y), INK, 8.0, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			PaperMotion.squash(_coin)
			_set_from(event.position.x)
		elif _dragging:
			_dragging = false
			released.emit()
	elif event is InputEventMouseMotion and _dragging:
		_set_from(event.position.x)


func _set_from(x: float) -> void:
	var old := value
	value = (x - RADIUS) / (size.x - RADIUS * 2)
	if not is_equal_approx(old, value):
		value_changed.emit(value)


func _place() -> void:
	if _coin:
		_coin.position = Vector2(RADIUS + value * (size.x - RADIUS * 2), size.y / 2)
