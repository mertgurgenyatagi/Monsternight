class_name MinigameFrame
extends CanvasLayer
## Everything around a Shot in the Dark: a dim over the board, the VS card (two torn paper strips with
## the monsters and the stake), the question rounds (`ShotGame`), and the result. A swap is several
## rounds: the challenger must win `Duel.swap_wins` of them before losing one, with a `DuelTally` over
## the card; a draw asks another question (three draws in a row lose it for the challenger). `play`
## gives `{winner, loser, rounds}` for `Board.duel_end` to apply, `rounds` being who took each round
## (true for the challenger). It changes nothing on the board, and it covers every click while it is up.
## Online, the host picks each round's question and `Online.shot` carries the secret answers.

const CENTER := Vector2(960, 470)
const STRIP_SIZE := Vector2(740, 250)
const STRIP_GAP := 400.0 # from the middle to each strip
const PORTRAIT_SIZE := 210.0
const TALLY_AT := Vector2(960, 150)
const SMALL_PORTRAIT := 100.0
const HUD_Y := 150.0
const DIM_ALPHA := 0.7
const MAX_DRAWS := 3 # draws in a row before the challenger loses
const INK := Color("2a1a22")
const CREAM := Color("fbe9d0")
const DISPLAY := preload("res://assets/fonts/display.ttf")
const ICONS := {
	"gold": preload("res://assets/art/icons/coin.png"),
	"blood": preload("res://assets/art/icons/blood.png"),
	"swap": preload("res://assets/art/icons/swap.png"),
}

var _dim: ColorRect
var _root: Node2D
var _blocker: Control
var _front: Node2D
var _asked_rng := RandomNumberGenerator.new()
var _faces: Array[Sprite2D] = []
var _tally: DuelTally


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


## Who wins a match of rounds: 0 the challenger, 1 the opponent, -1 not yet. `rounds` holds who took
## each round (true for the challenger); the challenger needs `needed` wins, the opponent a single one.
static func settled(rounds: Array, needed: int) -> int:
	var wins := 0
	for won in rounds:
		if not won:
			return 1
		wins += 1
	return 0 if wins >= needed else -1


## Plays the whole match on a space of question `group` and gives `{winner, loser, rounds}`. Awaiting
## it waits until the cards have lifted away. The challenger plays on the left.
func play(challenger: Dictionary, opponent: Dictionary, stake: String, group: String) -> Dictionary:
	Sound.play_music("") # no music in minigames
	var needed := Duel.swap_wins(challenger, stake)
	var hyde := 0 if challenger.monster == "hyde" else -1
	_asked_rng.randomize()
	_root = Node2D.new()
	add_child(_root)
	_blocker = Control.new()
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.size = Vector2(1920, 1080)
	add_child(_blocker)
	_front = Node2D.new() # above the blocker, so the keypad can be clicked
	add_child(_front)
	var players: Array[Dictionary] = [challenger, opponent]
	create_tween().tween_property(_dim, "color:a", DIM_ALPHA, 0.3)

	await _vs_card(players, stake, needed)

	var rounds: Array[bool] = []
	var draws := 0
	while settled(rounds, needed) < 0:
		_faces_in(players)
		var asked: Dictionary
		if Online.active:
			# The host picks the question and every copy shows it in its own language.
			var picked := await Online.decide("question", challenger, 0.0,
					func() -> int: return int(Questions.pick(group, Match.asked, _asked_rng).id))
			asked = Questions.by_id(int(picked.value))
			Match.asked[int(asked.id)] = true
		else:
			asked = Questions.pick(group, Match.asked, _asked_rng)
		var game := ShotGame.new()
		game.setup(challenger, opponent, asked, group, hyde)
		_front.add_child(game)
		var side: int
		if Online.active:
			side = await game.run_online()
		else:
			side = await game.run()
		game.queue_free()
		if side == ShotGame.DRAW:
			draws += 1
			if draws >= MAX_DRAWS:
				rounds.append(false) # the challenger loses a duel that cannot be settled
				continue
			await _plain_banner("MINI_TIE")
			continue
		draws = 0
		rounds.append(side == 0)
		if _tally:
			_tally.fill(0 if side == 0 else 1)
			Sound.play("ui_click", 0.0, 1.5 if side == 0 else 0.65)
		_poses(players, side)
		await get_tree().create_timer(1.1, false).timeout
		if settled(rounds, needed) < 0:
			await get_tree().create_timer(0.3, false).timeout

	var challenger_won := settled(rounds, needed) == 0
	var winner := challenger if challenger_won else opponent
	var loser := opponent if challenger_won else challenger
	await _announce(winner)
	print("Shot in the Dark (", group, ") won by ", winner.name, " (", rounds.size(), " rounds)")
	var tween := create_tween()
	tween.tween_property(_dim, "color:a", 0.0, 0.4)
	await tween.finished
	_root.queue_free()
	_blocker.queue_free()
	_front.queue_free()
	_faces.clear()
	_tally = null
	return {"winner": winner, "loser": loser, "rounds": rounds}


# ---- the VS card ----

func _vs_card(players: Array[Dictionary], stake: String, needed: int) -> void:
	var strips: Array[Node2D] = []
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var rest := CENTER + Vector2(side * STRIP_GAP, 0)
		var strip := _holder(rest)
		strip.position = rest + Vector2(side * 1500.0, 0)
		var body := Node2D.new()
		strip.add_child(body)
		var paper := Sprite2D.new()
		paper.texture = preload("res://assets/art/ui/panel.png")
		paper.scale = STRIP_SIZE / paper.texture.get_size()
		body.add_child(paper)
		PaperShadow.add(paper)
		var face := Sprite2D.new()
		face.texture = Monsters.portrait(players[i].monster)
		face.scale = Vector2.ONE * PORTRAIT_SIZE / face.texture.get_width()
		face.position = Vector2(-side * 220.0, 0)
		body.add_child(face)
		var title := _label(Monsters.display_name(players[i].monster), 54, Monsters.color(players[i].monster), 330.0)
		title.add_theme_color_override("font_outline_color", INK)
		title.add_theme_constant_override("outline_size", 8)
		title.position = Vector2(side * 70.0 - 165.0, -34)
		body.add_child(title)
		if i == 0:
			var tag := _label(tr("DUEL_CHALLENGER"), 28, INK, 330.0)
			tag.position = Vector2(side * 70.0 - 165.0, -88)
			body.add_child(tag)
		PaperMotion.breathe(body)
		strips.append(strip)
		var slam := strip.create_tween().set_parallel()
		slam.tween_property(strip, "position", rest, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		slam.tween_property(strip, "rotation_degrees", -3.0 if i == 0 else 3.0, 0.35) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		slam.chain().tween_callback(func() -> void: PaperMotion.squash(strip))
		get_tree().create_timer(0.25, false).timeout.connect(func() -> void: Sound.play("card_slam"))
		await get_tree().create_timer(0.15, false).timeout
	await get_tree().create_timer(0.4, false).timeout

	var vs := _holder(CENTER)
	var vs_text := _label(tr("DUEL_VS"), 150, CREAM, 300.0)
	vs_text.position = Vector2(-150, -110)
	vs_text.add_theme_color_override("font_outline_color", INK)
	vs_text.add_theme_constant_override("outline_size", 22)
	vs.add_child(vs_text)
	PaperMotion.drop_in(vs, 500.0, 0.3)
	await get_tree().create_timer(0.2, false).timeout
	Sound.play("card_slam")
	PaperMotion.squash(vs)
	var plate := _stake_plate(stake)
	PaperMotion.pop_in(plate, 0.1)
	if stake == "swap" and players[0].monster == "dorian":
		PowerPop.show_over(_root, strips[0].position + Vector2(0, -190), tr("POP_EASY"))

	await get_tree().create_timer(1.6, false).timeout

	for node in strips + [vs, plate]:
		PaperMotion.pop_out(node)
	await get_tree().create_timer(0.4, false).timeout
	if needed > 1:
		var colors: Array[Color] = [Monsters.color(players[0].monster), Monsters.color(players[1].monster)]
		_tally = DuelTally.new(needed, 1, colors)
		_tally.position = TALLY_AT
		_root.add_child(_tally)
		_tally.come_in()


func _stake_plate(stake: String) -> Node2D:
	var strip := _holder(Vector2(960, 640))
	var plate := Sprite2D.new()
	plate.texture = preload("res://assets/art/ui/panel.png")
	plate.scale = Vector2(680, 120) / plate.texture.get_size()
	strip.add_child(plate)
	PaperShadow.add(plate)
	var icon := Sprite2D.new()
	icon.texture = ICONS[stake]
	icon.scale = Vector2.ONE * 90.0 / icon.texture.get_height()
	icon.position = Vector2(-270, 0)
	strip.add_child(icon)
	var line := _label(tr("STAKE_" + stake.to_upper()), 48, INK, 500.0)
	line.position = Vector2(-200, -32)
	strip.add_child(line)
	return strip


# ---- the table ----

# The two small portraits over the table.
func _faces_in(players: Array[Dictionary]) -> void:
	if _faces.is_empty():
		for i in 2:
			var face := Sprite2D.new()
			face.texture = Monsters.portrait(players[i].monster)
			face.scale = Vector2.ONE * SMALL_PORTRAIT / face.texture.get_width()
			var side := -1.0 if i == 0 else 1.0
			face.position = Vector2(960 + side * 700.0, HUD_Y)
			face.set_meta("rest_position", face.position)
			face.set_meta("rest_scale", face.scale)
			_root.add_child(face)
			PaperShadow.add(face)
			_faces.append(face)
			PaperMotion.pop_in(face, 0.1 * i)
	else:
		for face in _faces:
			face.modulate = Color.WHITE


# A paper plate with a line of words drops in the middle, stays a moment and lifts away.
func _plain_banner(key: String) -> void:
	var banner := _holder(Vector2(960, 540))
	var plate := Sprite2D.new()
	plate.texture = preload("res://assets/art/ui/panel.png")
	plate.scale = Vector2(760, 140) / plate.texture.get_size()
	banner.add_child(plate)
	PaperShadow.add(plate)
	var text := _label(tr(key), 64, INK, 700.0)
	text.position = Vector2(-350, -42)
	banner.add_child(text)
	PaperMotion.drop_in(banner, 420.0, 0.4)
	await get_tree().create_timer(1.3, false).timeout
	PaperMotion.lift_away(banner, 700.0, 0.4)
	await get_tree().create_timer(0.4, false).timeout


# The round's winner jumps and the loser droops.
func _poses(players: Array[Dictionary], side: int) -> void:
	var winner: Sprite2D = _faces[side]
	var loser: Sprite2D = _faces[1 - side]
	Sound.play(Monsters.voice(players[side].monster, "win"))
	PaperMotion.squash(winner)
	PaperMotion.hop(winner, 70.0)
	PaperMotion.tilt(winner, 6.0)
	var tween := loser.create_tween().set_parallel()
	tween.tween_property(loser, "modulate", Color(0.55, 0.55, 0.6), 0.3)
	tween.tween_property(loser, "rotation_degrees", (-1.0 if side == 1 else 1.0) * 14.0, 0.3)
	tween.chain().tween_property(loser, "rotation_degrees", 0.0, 0.5)


func _announce(winner: Dictionary) -> void:
	var banner := _holder(Vector2(960, 1010))
	var plate := Sprite2D.new()
	plate.texture = preload("res://assets/art/ui/panel.png")
	plate.scale = Vector2(700, 120) / plate.texture.get_size()
	banner.add_child(plate)
	PaperShadow.add(plate)
	var text := _label(tr("DUEL_WINS") % Monsters.display_name(winner.monster), 56,
			Monsters.color(winner.monster), 680.0)
	text.add_theme_color_override("font_outline_color", INK)
	text.add_theme_constant_override("outline_size", 8)
	text.position = Vector2(-340, -38)
	banner.add_child(text)
	Sound.play("card_slam")
	PaperMotion.drop_in(banner, 420.0, 0.4)
	await get_tree().create_timer(1.6, false).timeout
	var leaving: Array = [banner, _tally]
	leaving.append_array(_faces)
	for node in leaving:
		if node:
			PaperMotion.lift_away(node, 700.0, 0.4)
	await get_tree().create_timer(0.4, false).timeout


# ---- helpers ----

# A node that pops and slides by its rest position and scale, added to the layer's root.
func _holder(at: Vector2) -> Node2D:
	var node := Node2D.new()
	node.position = at
	node.set_meta("rest_position", at)
	node.set_meta("rest_scale", Vector2.ONE)
	_root.add_child(node)
	return node


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
