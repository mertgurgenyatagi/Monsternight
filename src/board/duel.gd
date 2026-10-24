class_name Duel
extends CanvasLayer
## The duel after a challenge: a dim over the board, a paper VS card with both monsters and the stake,
## a 3, 2, 1, and a coin flip that decides the winner, who is announced. It changes nothing on the
## board; `play` gives `{winner, loser, rounds}` (player dictionaries) for `Board.duel_end` to apply. The
## flips are `_decide`, and a minigame will replace it as a whole. A swap is rigged: the challenger must
## win 3 flips before the opponent wins 1, and a tally under the VS shows the rounds.

const CENTER := Vector2(960, 470)
const CARD_SCALE := 0.9 # card.png is 400 x 560
const CARD_GAP := 310.0 # from the middle to each card
const APART_GAP := 520.0 # the cards slide this far out for the countdown
const APART_SCALE := 0.7
const PORTRAIT_SIZE := 270.0
const ICONS := {
	"gold": preload("res://assets/art/icons/coin.png"),
	"blood": preload("res://assets/art/icons/blood.png"),
	"swap": preload("res://assets/art/icons/swap.png"),
}
const SWAP_ROUNDS := 3 # the flips the challenger must win in a row to win a swap
const TALLY_AT := Vector2(960, 745)
const COIN_SIZE := 150.0
const COIN_REST_Y := 600.0
const SHAKE := 6.0
const DIM_ALPHA := 0.55
const INK := Color("2a1a22")
const CREAM := Color("fbe9d0")
const GOLD := Color(1.0, 0.85, 0.5, 0.6)
const DISPLAY := preload("res://assets/fonts/display.ttf")

var _dim: ColorRect
var _root: Node2D
var _cards: Array[Node2D] = [] # [challenger's, opponent's]
var _bodies: Array[Node2D] = [] # what breathes inside each card
var _greys: Array[ShaderMaterial] = []
var _vs: Node2D
var _strip: Node2D
var _coin: Sprite2D
var _coin_scale: Vector2
var _tally: DuelTally
var _banner: Node2D


func _init() -> void:
	layer = 30


func _ready() -> void:
	# The dim sits under the HUD (layer 20), so the portraits stay bright above it.
	var under := CanvasLayer.new()
	under.layer = 15
	add_child(under)
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.size = Vector2(1920, 1080)
	under.add_child(_dim)
	_root = Node2D.new()
	add_child(_root)


## Plays the whole duel and gives `{winner, loser, rounds}`, `rounds` being who took each flip (true for
## the challenger). Awaiting it waits until the cards have lifted away.
func play(challenger: Dictionary, opponent: Dictionary, stake: String) -> Dictionary:
	Sound.play_music("duel")
	var decided := _decide(challenger, opponent, stake)
	var winner: Dictionary = decided.winner
	var loser: Dictionary = decided.loser
	var rounds: Array = decided.rounds
	var challenger_won: bool = rounds[-1]
	_build(challenger, opponent, stake)

	create_tween().tween_property(_dim, "color:a", DIM_ALPHA, 0.3)
	# The VS card slams down: one card from each side, then the VS between them.
	for i in 2:
		_slam_card(i)
		await get_tree().create_timer(0.15, false).timeout
	await get_tree().create_timer(0.3, false).timeout
	_vs.visible = true
	PaperMotion.drop_in(_vs, 500.0, 0.3)
	await get_tree().create_timer(0.2, false).timeout
	Sound.play("card_slam")
	PaperMotion.squash(_vs)
	_jolt()
	_strip.visible = true
	PaperMotion.pop_in(_strip, 0.1)
	if stake == "swap" and challenger.monster == "dorian":
		PowerPop.show_over(_root, _cards[0].position + Vector2(0, -250), tr("POP_EASY"))
	for body in _bodies:
		PaperMotion.breathe(body)
	await get_tree().create_timer(0.9, false).timeout

	# The countdown: the cards part and shrink, and a huge number fills the middle.
	PaperMotion.pop_out(_vs)
	PaperMotion.pop_out(_strip)
	for i in 2:
		_pull_apart(i)
	await get_tree().create_timer(0.6, false).timeout
	if _tally:
		_tally.visible = true
		_tally.come_in()
	for n in [3, 2, 1]:
		await _count(n)

	# The flips: a swap has several, each a quicker repeat, and each fills a pip of the tally.
	for i in rounds.size():
		if i > 0:
			PaperMotion.pop_out(_coin)
			await get_tree().create_timer(0.3, false).timeout
			for n in [2, 1]:
				await _count(n, true)
		Sound.play("countdown_go")
		await _flip(challenger, opponent, rounds[i])
		await get_tree().create_timer(0.4, false).timeout
		if _tally:
			_tally.fill(0 if rounds[i] else 1)
			Sound.play("ui_click", 0.0, 1.5 if rounds[i] else 0.65)
			await get_tree().create_timer(0.5, false).timeout

	await _announce(winner, loser, challenger_won)
	print("Duel won by ", winner.name, " (coin flip, ", rounds.size(), " rounds)")
	var tween := create_tween()
	tween.tween_property(_dim, "color:a", 0.0, 0.4)
	await tween.finished
	_root.queue_free()
	_root = Node2D.new()
	add_child(_root)
	_cards.clear()
	_bodies.clear()
	_greys.clear()
	_tally = null
	return {"winner": winner, "loser": loser, "rounds": rounds}


## Who wins: coin flips, each one even. Gold and blood are one flip. A swap goes on while the challenger
## keeps winning, until they have `SWAP_ROUNDS` wins or the opponent takes one, so the challenger wins a
## swap 1 time in 8. Gives `{winner, loser, rounds}`, `rounds` being the flips (true when the challenger
## took it); the last one decides. A minigame replaces this function as a whole.
func _decide(challenger: Dictionary, opponent: Dictionary, stake: String) -> Dictionary:
	var rounds := roll_rounds(stake, swap_wins(challenger, stake))
	var challenger_won: bool = rounds[-1]
	return {"winner": challenger if challenger_won else opponent,
			"loser": opponent if challenger_won else challenger, "rounds": rounds}


## The flips the challenger must win to win this stake: 1, except a swap, which takes `SWAP_ROUNDS`,
## or 1 for Dorian Gray as the challenger.
static func swap_wins(challenger: Dictionary, stake: String) -> int:
	if stake == "swap" and challenger.monster != "dorian":
		return SWAP_ROUNDS
	return 1


## The flips of a duel for this stake: a swap goes on while the challenger keeps winning, until they
## have `swap_wins` wins or the opponent takes one. Any other stake is one flip.
static func roll_rounds(stake: String, swap_wins := SWAP_ROUNDS) -> Array[bool]:
	var needed := swap_wins if stake == "swap" else 1
	var rounds: Array[bool] = []
	var wins := 0
	while true:
		var won := randf() < 0.5
		rounds.append(won)
		if not won:
			break
		wins += 1
		if wins >= needed:
			break
	return rounds


# Everything is built off screen or hidden, then played.
func _build(challenger: Dictionary, opponent: Dictionary, stake: String) -> void:
	for i in 2:
		var player: Dictionary = challenger if i == 0 else opponent
		var card := Node2D.new()
		var side := -1.0 if i == 0 else 1.0
		card.position = CENTER + Vector2(side * 1500.0, 0)
		card.set_meta("rest_position", CENTER + Vector2(side * CARD_GAP, 0))
		card.set_meta("rest_scale", Vector2.ONE)
		_root.add_child(card)
		var body := Node2D.new()
		card.add_child(body)
		var paper := Sprite2D.new()
		paper.texture = preload("res://assets/art/ui/card.png")
		paper.scale = Vector2.ONE * CARD_SCALE
		body.add_child(paper)
		PaperShadow.add(paper)
		var face := Sprite2D.new()
		face.texture = Monsters.portrait(player.monster)
		face.scale = Vector2.ONE * PORTRAIT_SIZE / face.texture.get_width()
		face.position = Vector2(0, -60)
		body.add_child(face)
		var grey := ShaderMaterial.new()
		grey.shader = preload("res://src/pregame/grey.gdshader")
		paper.material = grey
		face.material = grey
		grey.set_shader_parameter("amount", 0.0)
		_greys.append(grey)
		var title := _label(Monsters.display_name(player.monster), 44, Monsters.color(player.monster), 270.0)
		title.add_theme_color_override("font_outline_color", INK)
		title.add_theme_constant_override("outline_size", 8)
		title.position = Vector2(-135, 150)
		body.add_child(title)
		if i == 0:
			var tag := Node2D.new()
			tag.position = Vector2(-90, -290)
			tag.rotation_degrees = -6.0
			var paper_tag := Sprite2D.new()
			paper_tag.texture = preload("res://assets/art/ui/panel.png")
			paper_tag.scale = Vector2(190, 50) / paper_tag.texture.get_size()
			tag.add_child(paper_tag)
			PaperShadow.add(paper_tag)
			var text := _label(tr("DUEL_CHALLENGER"), 26, INK, 190.0)
			text.position = Vector2(-95, -17)
			tag.add_child(text)
			body.add_child(tag)
		_cards.append(card)
		_bodies.append(body)
		card.visible = false

	_vs = Node2D.new()
	_vs.position = CENTER
	_vs.set_meta("rest_position", CENTER)
	_vs.set_meta("rest_scale", Vector2.ONE)
	_vs.visible = false
	_root.add_child(_vs)
	var vs_text := _label(tr("DUEL_VS"), 150, CREAM, 300.0)
	vs_text.position = Vector2(-150, -110)
	vs_text.add_theme_color_override("font_outline_color", INK)
	vs_text.add_theme_constant_override("outline_size", 22)
	_vs.add_child(vs_text)

	_strip = Node2D.new()
	var strip_at := Vector2(960, 810)
	_strip.position = strip_at
	_strip.set_meta("rest_position", strip_at)
	_strip.set_meta("rest_scale", Vector2.ONE)
	_strip.visible = false
	_root.add_child(_strip)
	var plate := Sprite2D.new()
	plate.texture = preload("res://assets/art/ui/panel.png")
	plate.scale = Vector2(680, 130) / plate.texture.get_size()
	_strip.add_child(plate)
	PaperShadow.add(plate)
	var icon := Sprite2D.new()
	icon.texture = ICONS[stake]
	icon.scale = Vector2.ONE * 100.0 / icon.texture.get_height()
	icon.position = Vector2(-270, 0)
	_strip.add_child(icon)
	var line := _label(tr("STAKE_" + stake.to_upper()), 48, INK, 500.0)
	line.position = Vector2(-200, -32)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_strip.add_child(line)

	_coin = Sprite2D.new()
	_coin.texture = ICONS["gold"]
	_coin.scale = Vector2.ONE * COIN_SIZE / _coin.texture.get_height()
	_coin.visible = false
	_root.add_child(_coin)
	_coin_scale = _coin.scale
	if stake == "swap" and swap_wins(challenger, stake) > 1:
		var colors: Array[Color] = [Monsters.color(challenger.monster), Monsters.color(opponent.monster)]
		_tally = DuelTally.new(SWAP_ROUNDS, 1, colors)
		_tally.position = TALLY_AT
		_tally.visible = false
		_root.add_child(_tally)


# One card slams in from its side and tips toward the other.
func _slam_card(i: int) -> void:
	var card := _cards[i]
	var rest: Vector2 = card.get_meta("rest_position")
	card.visible = true
	var turn := 5.0 if i == 0 else -5.0
	var tween := card.create_tween().set_parallel()
	tween.tween_property(card, "position", rest, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation_degrees", turn, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func() -> void: PaperMotion.squash(card))
	get_tree().create_timer(0.2, false).timeout.connect(func() -> void: Sound.play("card_slam"))


# A tiny jolt of the whole layer, as if the page was hit.
func _jolt() -> void:
	var tween := _root.create_tween()
	for dx in [-SHAKE, SHAKE, -SHAKE * 0.5, SHAKE * 0.3, 0.0]:
		tween.tween_property(_root, "position", Vector2(dx, dx * 0.5), 0.04)


func _pull_apart(i: int) -> void:
	var card := _cards[i]
	var side := -1.0 if i == 0 else 1.0
	var target := CENTER + Vector2(side * APART_GAP, 0)
	card.set_meta("rest_position", target)
	var tween := card.create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "position", target, 0.5)
	tween.tween_property(card, "scale", Vector2.ONE * APART_SCALE, 0.5)
	tween.tween_property(card, "rotation_degrees", 0.0, 0.5)


# A huge number pops at the center, squashes and settles within 0.8 s, then tears away.
func _count(n: int, quick := false) -> void:
	var k := 0.6 if quick else 1.0 # a repeat's numbers go by faster
	Sound.play("countdown")
	var number := _label(str(n), 380, CREAM, 400.0)
	number.add_theme_color_override("font_outline_color", INK)
	number.add_theme_constant_override("outline_size", 30)
	number.size = Vector2(400, 440)
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.pivot_offset = number.size / 2
	var holder := Node2D.new()
	holder.position = CENTER + Vector2(0, 30)
	number.position = -number.size / 2
	holder.add_child(number)
	_root.add_child(holder)
	var tween := holder.create_tween()
	holder.scale = Vector2.ONE * 2.2
	tween.tween_property(holder, "scale", Vector2(0.85, 1.1), 0.14 * k).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(holder, "scale", Vector2.ONE, 0.4 * k).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	var away := holder.create_tween().set_parallel()
	away.tween_property(holder, "position", holder.position + Vector2(40, -260), 0.2 * k) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	away.tween_property(holder, "rotation_degrees", 14.0, 0.2 * k)
	away.tween_property(holder, "modulate:a", 0.0, 0.2 * k)
	await away.finished
	holder.queue_free()


# The coin is flicked up from between the cards, spins by squashing across its width, slows and lands
# on the winner's side. One face wears the challenger's color, the other the opponent's.
func _flip(challenger: Dictionary, opponent: Dictionary, challenger_won: bool) -> void:
	var faces := [Monsters.color(challenger.monster).lerp(Color.WHITE, 0.3),
			Monsters.color(opponent.monster).lerp(Color.WHITE, 0.3)]
	var base := _coin_scale
	_coin.scale = base
	_coin.rotation = 0.0
	var start := Vector2(960, COIN_REST_Y + 60.0)
	var landing := Vector2(960 + (-170.0 if challenger_won else 170.0), COIN_REST_Y)
	# An even count of half turns ends on the challenger's face.
	var halves := 12 if challenger_won else 11
	_coin.position = start
	_coin.modulate = faces[0]
	_coin.visible = true
	_coin.set_meta("rest_position", landing)
	Sound.play("coin_flip")
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
			var spin := (1.0 - pow(1.0 - t, 2.0)) * halves * PI
			var c := cos(spin)
			_coin.scale = Vector2(base.x * maxf(absf(c), 0.08), base.y)
			_coin.modulate = faces[0] if c >= 0.0 else faces[1]
			var x := lerpf(start.x, landing.x, t)
			var y := lerpf(start.y, landing.y, t) - 520.0 * 4.0 * t * (1.0 - t)
			_coin.position = Vector2(x, y),
			0.0, 1.0, 1.4).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	_coin.position = landing
	Sound.play("flip")
	await PaperMotion.bounce(_coin, 40.0).finished


func _announce(winner: Dictionary, loser: Dictionary, challenger_won: bool) -> void:
	var win_i := 0 if challenger_won else 1
	var lose_i := 1 - win_i
	var card := _cards[win_i]
	var rest: Vector2 = card.get_meta("rest_position")
	var glow := Glow.new(GOLD, 330.0)
	glow.show_behind_parent = true
	card.add_child(glow)
	glow.flare()
	var up := card.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	up.tween_property(card, "position", rest + Vector2(0, -30), 0.4)
	up.tween_property(card, "scale", Vector2.ONE * 0.84, 0.4)
	var down := _cards[lose_i].create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var side := -1.0 if lose_i == 0 else 1.0
	var lost: Node2D = _cards[lose_i]
	down.tween_property(_greys[lose_i], "shader_parameter/amount", 1.0, 0.4)
	down.tween_property(lost, "scale", Vector2.ONE * 0.62, 0.4)
	down.tween_property(lost, "rotation_degrees", side * 9.0, 0.4)
	down.tween_property(lost, "position", lost.position + Vector2(0, 30), 0.4)
	Sound.play("card_slam")

	_banner = Node2D.new()
	var at := Vector2(960, 880)
	_banner.position = at
	_banner.set_meta("rest_position", at)
	_banner.set_meta("rest_scale", Vector2.ONE)
	_root.add_child(_banner)
	var plate := Sprite2D.new()
	plate.texture = preload("res://assets/art/ui/panel.png")
	plate.scale = Vector2(680, 110) / plate.texture.get_size()
	_banner.add_child(plate)
	PaperShadow.add(plate)
	var text := _label(tr("DUEL_WINS") % Monsters.display_name(winner.monster), 52,
			Monsters.color(winner.monster), 660.0)
	text.add_theme_color_override("font_outline_color", INK)
	text.add_theme_constant_override("outline_size", 8)
	text.position = Vector2(-330, -35)
	_banner.add_child(text)
	await get_tree().create_timer(0.3, false).timeout
	PaperMotion.drop_in(_banner, 420.0, 0.4)
	await get_tree().create_timer(1.6, false).timeout
	for node in [_banner, _cards[0], _cards[1]]:
		PaperMotion.lift_away(node, 700.0, 0.4)
	PaperMotion.pop_out(_coin)
	if _tally:
		PaperMotion.pop_out(_tally)
	await get_tree().create_timer(0.4, false).timeout


func _label(text: String, size: int, color: Color, width: float) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.clip_text = true # so the text never stretches the label past its width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", DISPLAY)
	label.add_theme_color_override("font_color", color)
	while size > 14 and DISPLAY.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width - 12.0:
		size -= 2
	label.add_theme_font_size_override("font_size", size)
	label.size = Vector2(width, size * 1.3) # last, or the text's width at the old size sticks
	return label
