extends Control
## Everything between setup and the board: the turn order roll, then monster select.
## The cards that settle into the turn order stay on screen and become the pickers' cards.
## `Match.roll_turn_order()` decides the order first; the animation only shows it.

const ROW_MAX := 4
const SPACING := Vector2(280, 360)
const SEATING_CENTER_Y := 545.0
const STACK_CENTER := Vector2(960, 540)
const DEAL_Y := 540.0
const DEAL_WIDTH := 1700.0
const DEAL_STEP := 260.0 # the room each card takes in the row, at full size
const STRIP_SCALE := 0.5
const STRIP_STEP := 150.0
const STRIP_Y := 105.0
const LIFTED_SCALE := 0.62 # the picker's card, lifted out of the strip
const LIFTED_DROP := 36.0
const ROW_Y := 890.0 # the middle of the monsters' stands
const ROW_STEP := 220.0
const PROMPT_Y := 330.0
const CANDLE_BASE_Y := 450.0
const CANDLE_SCALE := 0.5
const PICK_SECONDS := 30.0
const CREAM := Color("efe4cc")

signal _chosen(id: String)

@onready var _cards_root: Node2D = $Cards
@onready var _monsters_root: Node2D = $Monsters
@onready var _fly_root: Node2D = $Fly

var _cards: Array[PlayerCard] = [] # in seating order
var _stack: Array[PlayerCard] = [] # bottom to top, the same as the child order
var _pieces: Array[MonsterPiece] = [] # in the order of characters.md
var _prompt: Label
var _prompt_shown := false
var _candle: Candle
var _waiting := false # a player is picking right now


func _ready() -> void:
	Sound.play_music("title")
	if Match.players.is_empty():
		_start_test_match()
	var seating := Match.roll_turn_order()
	for i in seating.size():
		var card := PlayerCard.new(seating[i])
		_cards_root.add_child(card)
		card.position = _seat_position(i, seating.size())
		card.set_meta("rest_position", card.position)
		card.visible = false
		_cards.append(card)
	await get_tree().create_timer(0.4, false).timeout
	await _drop_in()
	await _flip_down()
	await _gather()
	await _shuffle()
	await _deal()
	await _reveal()
	await _rise_to_strip()
	await _select_monsters()
	print("Match: ", Match.players)


# Run on its own (for a check), the scene starts a match of however many players come after
# `--`, with long and short names, 4 by default.
func _start_test_match() -> void:
	var count := int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 4
	var names: Array[String] = []
	for n in ["Ayşe", "Bartholomew", "Cem", "Dracula", "Esra", "Frankenstein", "Gül", "Hasan"].slice(0, count):
		names.append(n)
	Match.start(names)


# Cards fill a row of up to four, then a second row, each row centered, as on the setup screen.
func _seat_position(i: int, count: int) -> Vector2:
	var rows := 1 if count <= ROW_MAX else 2
	var top_count := count if rows == 1 else ceili(count / 2.0)
	var row := 0 if i < top_count else 1
	var in_row := top_count if row == 0 else count - top_count
	var col := i if row == 0 else i - top_count
	return Vector2(960.0 + (col - (in_row - 1) / 2.0) * SPACING.x,
			SEATING_CENTER_Y + (row - (rows - 1) / 2.0) * SPACING.y)


func _drop_in() -> void:
	for i in _cards.size():
		_set_down_later(_cards[i], i * 0.14)
	await get_tree().create_timer(_cards.size() * 0.14 + 0.9, false).timeout


func _set_down_later(card: PlayerCard, delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	card.visible = true
	PaperMotion.set_down(card, Sound.play.bind("card_slam", -8.0))


# A quick ripple from left to right.
func _flip_down() -> void:
	for i in _cards.size():
		_flip_later(_cards[i], i * 0.09)
	await get_tree().create_timer(_cards.size() * 0.09 + 0.5, false).timeout


func _flip_later(card: PlayerCard, delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	Sound.play("flip")
	card.flip_over()


func _gather() -> void:
	for i in _cards.size():
		var card := _cards[i]
		_stack.append(card)
		_cards_root.move_child(card, i)
		PaperMotion.fly_to(card, _stack_position(i), Vector2.ONE, 0.5, i * 0.07, 40.0)
	await get_tree().create_timer(_cards.size() * 0.07 + 0.7, false).timeout


func _stack_position(index: int) -> Vector2:
	return STACK_CENTER + Vector2(0, -index * 2.0)


# A few quick passes: cards lift out of the stack in small arcs and tuck back in somewhere else,
# about 2 s in all.
func _shuffle() -> void:
	var passes := 5
	var per_pass := 3
	for p in passes:
		for k in per_pass:
			var card: PlayerCard = _stack.pick_random()
			var side := Vector2(randf_range(110.0, 150.0) * (1.0 if (p + k) % 2 == 0 else -1.0), 0)
			Sound.play("flip", -14.0)
			PaperMotion.tuck(card, side, _retuck.bind(card), 0.34)
			await get_tree().create_timer(0.12, false).timeout
		await get_tree().create_timer(0.1, false).timeout
	await get_tree().create_timer(0.45, false).timeout


func _retuck(card: PlayerCard) -> void:
	_stack.erase(card)
	var index := randi_range(0, _stack.size())
	_stack.insert(index, card)
	_cards_root.move_child(card, index)
	for i in _stack.size():
		_stack[i].set_meta("rest_position", _stack_position(i))


# The cards fly out of the stack one at a time, in turn order, to their places in the row.
func _deal() -> void:
	var count := Match.players.size()
	var scale_factor := minf(1.0, DEAL_WIDTH / (count * DEAL_STEP))
	for turn in count:
		var card := _card_for(Match.players[turn])
		_cards_root.move_child(card, _cards_root.get_child_count() - 1)
		var x := 960.0 + (turn - (count - 1) / 2.0) * DEAL_STEP * scale_factor
		PaperMotion.fly_to(card, Vector2(x, DEAL_Y), Vector2.ONE * scale_factor, 0.4, 0.0, 90.0)
		_land_later(card, 0.4)
		await get_tree().create_timer(0.26, false).timeout
	await get_tree().create_timer(0.8, false).timeout


func _land_later(card: PlayerCard, delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	Sound.play("card_slam", -8.0)
	PaperMotion.squash(card)


# One by one, first to last, with a gap between them.
func _reveal() -> void:
	for turn in Match.players.size():
		var card := _card_for(Match.players[turn])
		Sound.play("flip")
		await card.flip_over().finished
		card.show_number(turn)
		if turn == 0:
			Sound.play("hop")
			PaperMotion.hop(card)
		await get_tree().create_timer(0.55, false).timeout
	await get_tree().create_timer(1.0, false).timeout


# A smooth, staggered move: the cards shrink and rise into a strip along the top.
func _rise_to_strip() -> void:
	var count := Match.players.size()
	for turn in count:
		var card := _card_for(Match.players[turn])
		PaperMotion.fly_to(card, _strip_position(turn), Vector2.ONE * STRIP_SCALE, 0.8, turn * 0.09, 30.0)
	await get_tree().create_timer(count * 0.09 + 1.0, false).timeout


func _strip_position(turn: int) -> Vector2:
	return Vector2(960.0 + (turn - (Match.players.size() - 1) / 2.0) * STRIP_STEP, STRIP_Y)


# Monster select: the monsters drop in, then the players pick from the last in the turn order
# to the first.
func _select_monsters() -> void:
	Sound.play_music("select")
	_candle = Candle.new()
	_candle.visible = false
	_candle.scale = Vector2.ONE * CANDLE_SCALE
	_candle.set_meta("rest_scale", _candle.scale)
	_candle.timed_out.connect(_on_timed_out)
	add_child(_candle)
	_prompt = Label.new()
	_prompt.size = Vector2(1100, 70)
	_prompt.position = Vector2(960.0 - _prompt.size.x / 2, PROMPT_Y - _prompt.size.y / 2)
	_prompt.pivot_offset = _prompt.size / 2
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 54)
	_prompt.add_theme_color_override("font_color", CREAM)
	_prompt.scale = Vector2.ZERO
	_prompt.set_meta("rest_scale", Vector2.ONE)
	add_child(_prompt)
	await _drop_monsters()
	for turn in range(Match.players.size() - 1, -1, -1):
		await _pick_for(Match.players[turn], turn)
	PaperMotion.pop_out(_prompt)
	if _candle.visible:
		PaperMotion.pop_out(_candle)
	await get_tree().create_timer(1.2, false).timeout


func _drop_monsters() -> void:
	for i in Monsters.IDS.size():
		var piece := MonsterPiece.new(Monsters.IDS[i])
		piece.clicked.connect(_on_monster_clicked)
		_monsters_root.add_child(piece)
		piece.position = Vector2(960.0 + (i - (Monsters.IDS.size() - 1) / 2.0) * ROW_STEP, ROW_Y)
		piece.set_meta("rest_position", piece.position)
		piece.visible = false
		_pieces.append(piece)
		_drop_monster_later(piece, i * 0.12)
	await get_tree().create_timer(Monsters.IDS.size() * 0.12 + 1.0, false).timeout


func _drop_monster_later(piece: MonsterPiece, delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	piece.visible = true
	PaperMotion.drop_in(piece, 900.0, 0.7)
	await get_tree().create_timer(0.45, false).timeout
	Sound.play("card_slam", -12.0)
	piece.start_sway(randf_range(0.0, 2.0))


func _pick_for(player: Dictionary, turn: int) -> void:
	var card := _card_for(player)
	var free := Match.free_monsters()
	_cards_root.move_child(card, _cards_root.get_child_count() - 1)
	PaperMotion.fly_to(card, _strip_position(turn) + Vector2(0, LIFTED_DROP), Vector2.ONE * LIFTED_SCALE, 0.35, 0.0, 20.0)
	await _show_prompt(player.name, free.size() > 1)
	var id: String
	if free.size() == 1:
		# Nothing to choose: the last monster goes to the last picker after a short beat.
		await get_tree().create_timer(0.9, false).timeout
		id = free[0]
	else:
		_waiting = true
		for piece in _pieces:
			piece.enabled = not piece.taken
		_candle.start(PICK_SECONDS)
		id = await _chosen
		_waiting = false
		_candle.stop()
		for piece in _pieces:
			piece.enabled = false
	await _pick(player, card, turn, id)


# A pick, whether it came from a click, the candle running out, or the last monster being left.
func _pick(player: Dictionary, card: PlayerCard, turn: int, id: String) -> void:
	var piece := _piece_for(id)
	Match.pick_monster(player, id)
	piece.take(player.name)
	Sound.play(Monsters.voice(id, "pick"))
	Sound.play("hop", -8.0)
	PaperMotion.hop(piece)
	var fly := Sprite2D.new()
	fly.texture = Monsters.portrait(id)
	fly.position = piece.head_position()
	fly.scale = Vector2.ONE * 0.35
	_fly_root.add_child(fly)
	PaperShadow.add(fly)
	var target := card.portrait_target()
	PaperMotion.fly_to(fly, target.position, target.scale, 0.6, 0.25, 140.0)
	await get_tree().create_timer(0.85, false).timeout
	Sound.play("card_slam", -8.0)
	fly.queue_free()
	card.set_monster(id)
	PaperMotion.squash(card)
	await get_tree().create_timer(0.55, false).timeout
	PaperMotion.fly_to(card, _strip_position(turn), Vector2.ONE * STRIP_SCALE, 0.4, 0.0, 20.0)
	await get_tree().create_timer(0.6, false).timeout


# The prompt swaps with a small flip, and the candle comes along beside it.
func _show_prompt(player_name: String, with_candle: bool) -> void:
	var text := TranslationServer.translate("PICK_PROMPT") % player_name
	var font := _prompt.get_theme_font("font")
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 54).x
	var spot := Vector2(960.0 + width / 2.0 + 90.0, CANDLE_BASE_Y)
	if not _prompt_shown:
		_prompt_shown = true
		_prompt.text = text
		PaperMotion.pop_in(_prompt)
	else:
		PaperMotion.flip(_prompt, func() -> void: _prompt.text = text)
	Sound.play("flip", -10.0)
	if with_candle and not _candle.visible:
		_candle.position = spot
		_candle.set_meta("rest_position", spot)
		_candle.visible = true
		PaperMotion.pop_in(_candle)
	elif with_candle:
		PaperMotion.move_to(_candle, spot)
	elif _candle.visible:
		await PaperMotion.pop_out(_candle).finished
		_candle.visible = false
	await get_tree().create_timer(0.5, false).timeout


func _on_monster_clicked(piece: MonsterPiece) -> void:
	if _waiting and piece.enabled and not piece.taken:
		_chosen.emit(piece.id)


# The candle ran out: a random free monster is picked, as if the player had clicked it.
func _on_timed_out() -> void:
	if _waiting:
		_chosen.emit(Match.free_monsters().pick_random())


func _piece_for(id: String) -> MonsterPiece:
	for piece in _pieces:
		if piece.id == id:
			return piece
	return null


func _card_for(player: Dictionary) -> PlayerCard:
	for card in _cards:
		if card.player == player:
			return card
	return null
