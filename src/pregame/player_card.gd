class_name PlayerCard
extends Node2D
## One player's read-only paper card, shown through the pregame: a blank back, and a face with
## a big turn number over the name. Its origin is its center. It looks like setup's NameCard,
## which is the editable one. Part 5 adds the monster's portrait and color to the face.

const SIZE := NameCard.SIZE
const INK := NameCard.INK
const FONT_MAX := 38
const FONT_MIN := 16
const BACK_COLOR := Color("5b2a4a")

## The player's dictionary in `Match.players`.
var player: Dictionary
var face_up := true

var _front: Node2D
var _back: Sprite2D
var _number: Label
var _name: Label


func _init(for_player := {}) -> void:
	player = for_player


func _ready() -> void:
	var texture := preload("res://assets/art/ui/card.png")
	_back = Sprite2D.new()
	_back.texture = texture
	_back.centered = false
	_back.position = -SIZE / 2
	_back.scale = SIZE / texture.get_size()
	_back.self_modulate = BACK_COLOR
	add_child(_back)
	PaperShadow.add(_back)

	_front = Node2D.new()
	add_child(_front)
	_number = Label.new()
	_number.size = Vector2(SIZE.x, 90)
	_number.position = Vector2(-SIZE.x / 2, -SIZE.y / 2 + 30)
	_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_number.add_theme_font_override("font", preload("res://assets/fonts/display.ttf"))
	_number.add_theme_font_size_override("font_size", 120)
	_number.add_theme_color_override("font_color", INK)
	_number.pivot_offset = _number.size / 2
	_number.scale = Vector2.ZERO
	_number.set_meta("rest_scale", Vector2.ONE)
	_front.add_child(_number)

	_name = Label.new()
	_name.size = Vector2(SIZE.x - 40, 64)
	_name.position = Vector2(-_name.size.x / 2, 30)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.text = player.get("name", "")
	_name.add_theme_color_override("font_color", INK)
	_front.add_child(_name)
	_name.add_theme_font_size_override("font_size", _fitting_size())

	set_face_up(face_up)


## Shows the face or the blank back, instantly.
func set_face_up(up: bool) -> void:
	face_up = up
	_front.visible = up
	_back.self_modulate = Color.WHITE if up else BACK_COLOR


## Turns the card over, swapping the face at the middle of the flip.
func flip_over() -> Tween:
	return PaperMotion.flip(self, func() -> void: set_face_up(not face_up))


## Pops the turn number in on the face.
func show_number(turn: int) -> void:
	_number.text = str(turn + 1)
	PaperMotion.pop_in(_number)


# A long name shrinks to stay inside the card.
func _fitting_size() -> int:
	var font := _name.get_theme_font("font")
	var size := FONT_MAX
	while size > FONT_MIN and font.get_string_size(_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > _name.size.x - 8:
		size -= 2
	return size
