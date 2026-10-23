extends Control
## Everything between setup and the board: the turn order roll now, monster select in part 5.
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

@onready var _cards_root: Node2D = $Cards

var _cards: Array[PlayerCard] = [] # in seating order
var _stack: Array[PlayerCard] = [] # bottom to top, the same as the child order


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
		var x := 960.0 + (turn - (count - 1) / 2.0) * STRIP_STEP
		PaperMotion.fly_to(card, Vector2(x, STRIP_Y), Vector2.ONE * STRIP_SCALE, 0.8, turn * 0.09, 30.0)
	await get_tree().create_timer(count * 0.09 + 1.0, false).timeout


func _card_for(player: Dictionary) -> PlayerCard:
	for card in _cards:
		if card.player == player:
			return card
	return null
