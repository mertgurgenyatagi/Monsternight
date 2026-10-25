class_name PowerCard
extends Node2D
## A paper card that hangs under a HUD portrait when it is clicked: the monster's name, its power
## in full, the player's name, blood and coins, and any status. Its origin is the middle of its top
## edge, where a paper tab points up at the portrait. It never stops the game or eats a click:
## a click elsewhere closes it and still goes through. Esc closes it too.

signal closed

const WIDTH := 460.0
const PAD := 22.0
const TOP_Y := 236.0
const TAB := 22.0
const CREAM := Color(1.0, 0.93, 0.78)
const INK := Color("2a1a22")
const SOFT := Color("5a4048")
const RED := Color("b0243a")
const DISPLAY := preload("res://assets/fonts/display.ttf")
const BODY := preload("res://assets/fonts/body.ttf")
const NAME_SIZE := 38
const POWER_SIZE := 26
const LINE_SIZE := 26

var player: Dictionary
var portrait: HudPortrait

var _closing := false


func _init(for_player := {}, for_portrait: HudPortrait = null) -> void:
	player = for_player
	portrait = for_portrait


func _ready() -> void:
	var power := tr("POWER_LONG_" + String(player.monster).to_upper())
	var power_size := BODY.get_multiline_string_size(power, HORIZONTAL_ALIGNMENT_LEFT, WIDTH - 2 * PAD, POWER_SIZE)
	var status := _status()
	var height := PAD + 46.0 + power_size.y + 14.0 + 34.0 + 34.0 + PAD
	if status != "":
		height += 38.0
	var paper := Sprite2D.new()
	paper.texture = preload("res://assets/art/ui/panel.png")
	paper.centered = false
	paper.position = Vector2(-WIDTH / 2.0, 0)
	paper.scale = Vector2(WIDTH, height) / paper.texture.get_size()
	paper.self_modulate = CREAM
	add_child(paper)
	PaperShadow.add(paper)
	var tab := Polygon2D.new()
	tab.polygon = PackedVector2Array([Vector2(-TAB, 2), Vector2(0, -TAB), Vector2(TAB, 2)])
	tab.color = CREAM
	add_child(tab)

	var y := PAD
	_add_label(Monsters.display_name(player.monster), NAME_SIZE, Monsters.color(player.monster).darkened(0.25),
			DISPLAY, y, 46.0)
	y += 46.0
	_add_label(power, POWER_SIZE, INK, BODY, y, power_size.y)
	y += power_size.y + 14.0
	_add_label(player.name, LINE_SIZE, SOFT, DISPLAY, y, 34.0)
	y += 34.0
	var blood := "%s %d/%d   %s %d" % [tr("CARD_BLOOD"), player.blood, Match.max_blood(player),
			tr("CARD_COINS"), player.coins]
	_add_label(blood, LINE_SIZE, INK, DISPLAY, y, 34.0)
	y += 34.0
	if status != "":
		y += 4.0
		_add_label(status, LINE_SIZE, RED, DISPLAY, y, 34.0)
	PaperMotion.pop_in(self)
	Sound.play("flip", -8.0)


## Closes with a pop and frees itself. `closed` fires once.
func close() -> void:
	if _closing:
		return
	_closing = true
	closed.emit()
	await PaperMotion.pop_out(self).finished
	queue_free()


# A click outside the card (and outside its portrait, which toggles it) closes it. The click is not
# marked handled, so the board gets it too.
func _input(event: InputEvent) -> void:
	if _closing or not (event is InputEventMouseButton and event.pressed):
		return
	var at: Vector2 = event.position
	if Rect2(position - Vector2(WIDTH / 2.0, 0), Vector2(WIDTH, size_y())).has_point(at):
		return
	var frame := portrait.to_global(HudPortrait.FRAME_CENTER)
	if Rect2(frame - Vector2.ONE * HudPortrait.FRAME_SIZE / 2.0, Vector2.ONE * HudPortrait.FRAME_SIZE).has_point(at):
		return
	close()


func _unhandled_input(event: InputEvent) -> void:
	if not _closing and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## The card's height on screen, from its paper.
func size_y() -> float:
	var paper := get_child(0) as Sprite2D
	return paper.texture.get_height() * paper.scale.y


# The words under the stats: stone, finished, online presence, or whose turn it is.
func _status() -> String:
	if player.finished:
		return tr("CARD_FINISHED")
	if player.stone:
		return tr("CARD_STONE")
	if Online.active:
		match Online.status(player.name):
			"dropped":
				return tr("PRESENCE_DROPPED")
			"away":
				return tr("PRESENCE_AWAY")
	if not Match.players.is_empty() and is_same(Match.players[Match.current], player):
		return tr("CARD_ACTIVE")
	return ""


func _add_label(text: String, font_size: int, color: Color, font: Font, y: float, height: float) -> void:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = Vector2(WIDTH - 2 * PAD, height)
	label.position = Vector2(-WIDTH / 2.0 + PAD, y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
