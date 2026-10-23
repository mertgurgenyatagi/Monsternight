class_name NameCard
extends Node2D
## One player's paper name card: a number and a name typed in ink. Its origin is its center.

signal name_changed

const SIZE := Vector2(240, 336)
const INK := Color(0.29, 0.13, 0.21)
const INK_BAD := Color(0.65, 0.08, 0.1)
const FONT_MAX := 38
const FONT_MIN := 18

var seat := 0 : set = set_seat
var text: String : get = _get_text, set = _set_text
var bad := false

var _edit: LineEdit
var _number: Label
var _pending_text := ""


func _ready() -> void:
	var face := Sprite2D.new()
	face.texture = preload("res://assets/art/ui/card.png")
	face.centered = false
	face.position = -SIZE / 2
	face.scale = SIZE / face.texture.get_size()
	add_child(face)
	PaperShadow.add(face)

	_number = Label.new()
	_number.size = Vector2(SIZE.x, 90)
	_number.position = Vector2(-SIZE.x / 2, -SIZE.y / 2 + 30)
	_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_number.add_theme_font_override("font", preload("res://assets/fonts/display.ttf"))
	_number.add_theme_font_size_override("font_size", 64)
	add_child(_number)

	_edit = LineEdit.new()
	_edit.size = Vector2(SIZE.x - 50, 64)
	_edit.position = Vector2(-_edit.size.x / 2, 20)
	_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit.max_length = Match.NAME_LENGTH
	_edit.placeholder_text = tr("PLAYER_DEFAULT") % (seat + 1)
	_edit.context_menu_enabled = false
	_edit.select_all_on_focus = true
	_edit.add_theme_stylebox_override("normal", _ink_line(INK))
	_edit.add_theme_stylebox_override("focus", _ink_line(INK))
	_edit.add_theme_color_override("caret_color", INK)
	_edit.add_theme_color_override("selection_color", Color(INK, 0.3))
	_edit.add_theme_color_override("font_placeholder_color", Color(INK, 0.4))
	_edit.add_theme_constant_override("caret_width", 3)
	_edit.text_changed.connect(_on_text_changed)
	_edit.text_submitted.connect(func(_text: String) -> void: _edit.release_focus())
	_edit.text = _pending_text
	add_child(_edit)
	_paint()


func set_seat(value: int) -> void:
	seat = value
	if _number:
		_number.text = str(seat + 1)
		_edit.placeholder_text = tr("PLAYER_DEFAULT") % (seat + 1)


## Marks the name as taken (red ink) or clears the mark.
func set_bad(value: bool) -> void:
	bad = value
	_paint()


func focus() -> void:
	_edit.grab_focus()


func _get_text() -> String:
	return _edit.text if _edit else ""


func _set_text(value: String) -> void:
	_pending_text = value
	if _edit:
		_edit.text = value
		_fit_font()


func _on_text_changed(_new_text: String) -> void:
	_fit_font()
	name_changed.emit()


func _paint() -> void:
	var ink := INK_BAD if bad else INK
	_number.text = str(seat + 1)
	_number.add_theme_color_override("font_color", ink)
	_edit.add_theme_color_override("font_color", ink)
	_edit.add_theme_color_override("font_selected_color", ink)
	_fit_font()


# A long name shrinks to stay inside the card.
func _fit_font() -> void:
	var font := _edit.get_theme_font("font")
	var size := FONT_MAX
	while size > FONT_MIN and font.get_string_size(_edit.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > _edit.size.x - 16:
		size -= 2
	_edit.add_theme_font_size_override("font_size", size)


# A hand-inked line under the name, in place of the usual box.
func _ink_line(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_bottom = 4
	style.border_color = color
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style
