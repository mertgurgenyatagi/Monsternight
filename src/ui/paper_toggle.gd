class_name PaperToggle
extends Control
## A paper checkbox: an ink-edged square that a flag is planted in when it's on.

signal toggled(on: bool)

const INK := Color(0.29, 0.13, 0.21)

var on := false : set = set_on

var _flag: Sprite2D


func _ready() -> void:
	custom_minimum_size = Vector2(72, 72)
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	_flag = Sprite2D.new()
	_flag.texture = preload("res://assets/art/icons/flag.png")
	_flag.position = size / 2
	_flag.scale = Vector2.ONE * 0.5
	_flag.visible = on
	add_child(_flag)
	PaperShadow.add(_flag)


## Sets the box without animating or sending `toggled`.
func set_on(value: bool) -> void:
	on = value
	if _flag:
		_flag.visible = on


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.08))
	draw_rect(Rect2(Vector2.ZERO, size).grow(-3), INK, false, 6.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		on = not on
		_flag.visible = true
		if on:
			PaperMotion.pop_in(_flag)
		else:
			PaperMotion.pop_out(_flag).finished.connect(func() -> void: _flag.visible = on)
		Sound.play("ui_click")
		toggled.emit(on)
