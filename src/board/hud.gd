class_name Hud
extends CanvasLayer
## The strip of paper portraits along the top of the board, in turn order, and the turn counter
## in the corner. The rules change `Match` first, then the board tells the HUD to show it.
## It sits over the board and under Settings, and doesn't move with the camera.

## A pickable portrait was clicked (see `set_pickable`).
signal portrait_clicked(player: Dictionary)

const STEP := 184.0 # from one portrait to the next, so eight fit across 1920 px
const TOP_Y := 14.0 # where a portrait hangs from
const DROP_GAP := 0.12
const TAG_POS := Vector2(18, 16)
const TAG_SIZE := Vector2(172, 52)
const TAG_INK := Color("2a1a22")
const LAST_INK := Color("fbe9d0")
const LAST_COLOR := Color("c0282e")
const TRACK_AT := Vector2(960, 284) # under the counters, even of the active, lowered portrait

var _portraits := {} # monster id -> HudPortrait
var _tag: Node2D
var _track: ProgressTrack
var _tag_paper: Sprite2D
var _tag_label: Label
var _shown_turn := 1
var _card: PowerCard


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
		portrait.picked.connect(portrait_clicked.emit.bind(player))
		portrait.inspected.connect(_toggle_card.bind(player))
	_make_tag()
	_track = ProgressTrack.new()
	_track.position = TRACK_AT
	_track.modulate.a = 0.0
	add_child(_track)
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
	create_tween().tween_property(_track, "modulate:a", 1.0, 0.6).set_delay(i * DROP_GAP)
	_tag.visible = true
	PaperMotion.slide_in(_tag, -TAG_SIZE.x, i * DROP_GAP + 0.3, 0.6)


## The track under the portraits shows how far along each player's piece is.
func track_pieces(pieces: Dictionary) -> void:
	_track.follow(Match.players, pieces)


func set_active(player: Dictionary) -> void:
	_track.set_active(player.monster)
	for id in _portraits:
		var portrait: HudPortrait = _portraits[id]
		var on: bool = id == player.monster
		if portrait.active != on:
			portrait.set_active(on)


func set_finished(player: Dictionary) -> void:
	_portraits[player.monster].set_finished()


## Opens every portrait as a choice: the `players` are valid and bob, and the others are greyed and
## answer a click with `ui_denied`. A click on a valid one gives `portrait_clicked`.
func set_pickable(players: Array) -> void:
	for id in _portraits:
		var portrait: HudPortrait = _portraits[id]
		var valid := players.any(func(p: Dictionary) -> bool: return p.monster == id)
		portrait.set_pickable("valid" if valid else "denied")


## Closes the choice: the portraits go back to normal.
func clear_pickable() -> void:
	for id in _portraits:
		_portraits[id].set_pickable("")


## The `players`' portraits jerk from side to side, for "nobody chose".
func shake(players: Array) -> void:
	for player in players:
		PaperMotion.shake(_portraits[player.monster])


## Keeps this player's portrait lit as the chosen one, or lets it go.
func set_lit(player: Dictionary, on: bool) -> void:
	_portraits[player.monster].set_lit(on)


## Greys this player's portrait while they are stone, or lets the colour back.
func set_stone(player: Dictionary, on: bool) -> void:
	_portraits[player.monster].set_stone(on)


## Online: shows a player as dropped, away, or back ("").
func set_presence(player: Dictionary, state: String) -> void:
	_portraits[player.monster].set_presence(state)


## The player's portrait node.
func portrait_node(player: Dictionary) -> HudPortrait:
	return _portraits[player.monster]


## The screen position of a player's portrait frame.
func portrait_at(player: Dictionary) -> Vector2:
	return _portraits[player.monster].to_global(HudPortrait.FRAME_CENTER)


## The counter's number flips to turn `n`.
func set_turn(n: int) -> void:
	if n == _shown_turn:
		return
	_shown_turn = n
	Sound.play("flip")
	PaperMotion.flip(_tag, _show_turn)


## The last turn begins: the counter pops (it is already red from `set_turn`).
func last_turn() -> void:
	PaperMotion.squash(_tag)


## The portraits dim a little, for the end of the match.
func dim(duration := 1.0) -> void:
	for id in _portraits:
		create_tween().tween_property(_portraits[id], "modulate", Color(0.72, 0.7, 0.78), duration)


## With a `gap`, drops that come back appear one by one, that many seconds apart.
func show_blood(player: Dictionary, gap := 0.0) -> void:
	_portraits[player.monster].show_blood(gap)


## With `at_once`, the count jumps to the new number with one tick instead of counting down.
func show_coins(player: Dictionary, at_once := false) -> void:
	_portraits[player.monster].show_coins(at_once)


## The screen position of the player's "blood" or "coins" counter, for icons flying to it.
func anchor(player: Dictionary, what: String) -> Vector2:
	return _portraits[player.monster].anchor(what)


## The power card of the clicked portrait opens, or closes if it is that portrait's own. Only one
## card is open at a time.
func _toggle_card(player: Dictionary) -> void:
	var same := is_instance_valid(_card) and is_same(_card.player, player)
	if is_instance_valid(_card):
		_card.close()
	if same:
		return
	var portrait: HudPortrait = _portraits[player.monster]
	_card = PowerCard.new(player, portrait)
	var x := clampf(portrait.global_position.x, PowerCard.WIDTH / 2.0 + 10.0, 1920.0 - PowerCard.WIDTH / 2.0 - 10.0)
	_card.position = Vector2(x, PowerCard.TOP_Y)
	_card.set_meta("rest_position", _card.position)
	add_child(_card)
	PaperMotion.lift(portrait, true)
	_card.closed.connect(func() -> void: PaperMotion.lift(portrait, false))


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
	var last := _shown_turn >= Match.turns
	_tag_label.text = TranslationServer.translate("TURN_COUNTER") % [_shown_turn, Match.turns]
	_tag_paper.self_modulate = LAST_COLOR if last else Color.WHITE
	_tag_label.add_theme_color_override("font_color", LAST_INK if last else TAG_INK)
