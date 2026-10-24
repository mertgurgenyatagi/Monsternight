class_name PaperBanner
extends Node2D
## A wide paper banner with a line of text, for the board's announcements. Its origin is its middle,
## in screen coordinates under the HUD's portraits. `PaperMotion` drops it in and lifts it away.

const SIZE := Vector2(760, 110)
const INK := Color("2a1a22")
const RED := Color("c0282e")
const DISPLAY := preload("res://assets/fonts/display.ttf")


func _init(text: String, red := false) -> void:
	var paper := Sprite2D.new()
	paper.texture = preload("res://assets/art/ui/panel.png")
	paper.scale = SIZE / paper.texture.get_size()
	if red:
		paper.self_modulate = RED
	add_child(paper)
	PaperShadow.add(paper)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.clip_text = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var size := 56
	while size > 20 and DISPLAY.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > SIZE.x - 60.0:
		size -= 2
	label.add_theme_font_override("font", DISPLAY)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("fbe9d0") if red else INK)
	label.size = SIZE
	label.position = -SIZE / 2.0
	add_child(label)
