class_name PlaceTag
extends Node2D
## A small paper tag over a piece that has just finished: "1st", "2nd" and so on. The first finisher's
## tag is gold, the others plain. Its origin is the tag's middle.

const SIZE := Vector2(150, 64)
const INK := Color("2a1746")
const GOLD := Color(1.0, 0.82, 0.42)
const DISPLAY := preload("res://assets/fonts/display.ttf")


func _init(place: int) -> void:
	var paper := Sprite2D.new()
	paper.texture = preload("res://assets/art/ui/panel.png")
	paper.scale = SIZE / paper.texture.get_size()
	if place == 1:
		paper.modulate = GOLD
	add_child(paper)
	PaperShadow.add(paper)
	var label := Label.new()
	label.text = tr("PLACE_%d" % place)
	label.add_theme_font_override("font", DISPLAY)
	label.add_theme_font_size_override("font_size", 44)
	label.add_theme_color_override("font_color", INK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = SIZE
	label.position = -SIZE / 2.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	rotation_degrees = -4.0
