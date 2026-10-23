class_name Hud
extends CanvasLayer
## The strip of paper portraits along the top of the board, in turn order, and the turn counter
## in the corner. The rules change `Match` first, then the board tells the HUD to show it.
## It sits over the board and under Settings, and doesn't move with the camera.

const STEP := 184.0 # from one portrait to the next, so eight fit across 1920 px
const TOP_Y := 14.0 # where a portrait hangs from
const DROP_GAP := 0.12
const TAG_POS := Vector2(18, 16)
const TAG_SIZE := Vector2(172, 52)
const TAG_INK := Color("2a1a22")
const LAST_INK := Color("fbe9d0")
const LAST_COLOR := Color("c0282e")

var _portraits := {} # monster id -> HudPortrait
var _tag: Node2D
var _tag_paper: Sprite2D
var _tag_label: Label
var _shown_turn := 1


func _init() -> void:
	layer = 20 # over the board, under Settings (50)


func _ready() -> void:
	var count := Match.players.size()
	var x0 := 960.0 - STEP * (count - 1) / 2.0
	for i in count:
		var player: Dictionary = Match.players[i]
		var portrait := HudPortrait.new(player)
		portrait.position = Vector2(x0 + i * STEP, TOP_Y)
		portrait.visible = false
		add_child(portrait)
		_portraits[player.monster] = portrait
	_make_tag()
	_shown_turn = Match.turn
	_show_turn()


## The portraits drop in one after another from the left, then the counter slides in.
func come_in() -> void:
	var i := 0
	for player in Match.players:
		var portrait: HudPortrait = _portraits[player.monster]
		portrait.visible = true
		PaperMotion.drop_in(portrait, 320.0, 0.6, i * DROP_GAP)
		i += 1
	_tag.visible = true
	PaperMotion.slide_in(_tag, -TAG_SIZE.x, i * DROP_GAP + 0.3, 0.6)


func set_active(player: Dictionary) -> void:
	for id in _portraits:
		var portrait: HudPortrait = _portraits[id]
		var on: bool = id == player.monster
		if portrait.active != on:
			portrait.set_active(on)


func set_finished(player: Dictionary) -> void:
	_portraits[player.monster].set_finished()


## The counter's number flips to turn `n`.
func set_turn(n: int) -> void:
	if n == _shown_turn:
		return
	_shown_turn = n
	Sound.play("flip")
	PaperMotion.flip(_tag, _show_turn)


func show_blood(player: Dictionary) -> void:
	_portraits[player.monster].show_blood()


func show_coins(player: Dictionary) -> void:
	_portraits[player.monster].show_coins()


## The screen position of the player's "blood" or "coins" counter, for icons flying to it.
func anchor(player: Dictionary, what: String) -> Vector2:
	return _portraits[player.monster].anchor(what)


func _make_tag() -> void:
	_tag = Node2D.new()
	_tag.position = TAG_POS + TAG_SIZE / 2
	_tag.visible = false
	add_child(_tag)
	var texture := preload("res://assets/art/ui/panel.png")
	_tag_paper = Sprite2D.new()
	_tag_paper.texture = texture
	_tag_paper.scale = TAG_SIZE / texture.get_size()
	_tag.add_child(_tag_paper)
	PaperShadow.add(_tag_paper)
	_tag_label = Label.new()
	_tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag_label.size = TAG_SIZE
	_tag_label.position = -TAG_SIZE / 2
	_tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tag_label.add_theme_font_override("font", preload("res://assets/fonts/display.ttf"))
	_tag_label.add_theme_font_size_override("font_size", 26)
	_tag.add_child(_tag_label)


# The tag's text, with the tag blood red on the last turn.
func _show_turn() -> void:
	var last := _shown_turn >= Match.TURNS
	_tag_label.text = TranslationServer.translate("TURN_COUNTER") % [_shown_turn, Match.TURNS]
	_tag_paper.self_modulate = LAST_COLOR if last else Color.WHITE
	_tag_label.add_theme_color_override("font_color", LAST_INK if last else TAG_INK)
