class_name MinigameFrame
extends CanvasLayer
## Everything around a minigame: a dim over the board, the VS card (two torn paper strips with the
## monsters and the stake), the keys as small paper keycaps, a 3-2-1 with a whistle, the game, and the
## result. A swap is several rounds: the challenger must win `Duel.swap_wins` of them before losing one,
## with a `DuelTally` between rounds, and a draw replays its round. `play` gives `{winner, loser, rounds}`
## for `Board.duel_end` to apply, `rounds` being who took each round (true for the challenger). It changes
## nothing on the board, and it covers every click while it is up.

const CENTER := Vector2(960, 470)
const STRIP_SIZE := Vector2(740, 250)
const STRIP_GAP := 400.0 # from the middle to each strip
const PORTRAIT_SIZE := 210.0
const TALLY_AT := Vector2(960, 915)
const SMALL_PORTRAIT := 100.0
const HUD_Y := 185.0
const DIM_ALPHA := 0.7
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
var _stage: Node2D
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


## Mr. Hyde's edge: about 0.1, only as the challenger.
static func edge_for(challenger: Dictionary) -> float:
	return 0.1 if challenger.monster == "hyde" else 0.0


## Plays the whole match on a `kind` of space and gives `{winner, loser, rounds}`. Awaiting it waits
## until the cards have lifted away. The challenger plays on the left.
func play(challenger: Dictionary, opponent: Dictionary, stake: String, kind: String) -> Dictionary:
	Sound.play_music("") # no music in minigames
	var needed := Duel.swap_wins(challenger, stake)
	var edge := edge_for(challenger)
	_root = Node2D.new()
	add_child(_root)
	_blocker = Control.new()
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.size = Vector2(1920, 1080)
	add_child(_blocker)
	var players: Array[Dictionary] = [challenger, opponent]
	create_tween().tween_property(_dim, "color:a", DIM_ALPHA, 0.3)

	var game := Minigames.for_kind(kind)
	await _vs_card(players, stake, game.controls(), needed)

	var rounds: Array[bool] = []
	while settled(rounds, needed) < 0:
		if game == null:
			game = Minigames.for_kind(kind)
		var link: MiniLink = null
		var round_seed := 0
		if Online.active:
			# Online the host picks the round's number, which every copy seeds its game with.
			var started := await Online.decide("minigame", challenger, 0.0,
					func() -> Dictionary: return {"seed": randi()})
			round_seed = int(started.value.seed)
			game.rng.seed = round_seed
			link = MiniLink.new()
		game.setup(challenger, opponent, 0, edge)
		_stage = Node2D.new()
		_root.add_child(_stage)
		_stage.add_child(game)
		if link:
			_stage.add_child(link)
			link.setup(game, players, round_seed)
		_faces_in(players)
		if needed > 1:
			PaperMotion.pop_in(_banner_round(rounds.size() + 1))
		for n in [3, 2, 1]:
			await _count(n, false)
		Sound.play("whistle")
		var side: int
		if link:
			link.begin()
			side = await link.wait_end()
		else:
			game.begin()
			side = await game.finished
		game.active = false
		Sound.play("whistle")
		if side == Minigame.DRAW:
			await _draw_banner()
		else:
			rounds.append(side == 0)
			if _tally:
				_tally.fill(0 if side == 0 else 1)
				Sound.play("ui_click", 0.0, 1.5 if side == 0 else 0.65)
			_poses(players, side)
			await get_tree().create_timer(1.1, false).timeout
		_stage.queue_free()
		game = null
		if settled(rounds, needed) < 0:
			await get_tree().create_timer(0.4, false).timeout

	var challenger_won := settled(rounds, needed) == 0
	var winner := challenger if challenger_won else opponent
	var loser := opponent if challenger_won else challenger
	await _announce(winner)
	print("Minigame ", kind, " won by ", winner.name, " (", rounds.size(), " rounds)")
	var tween := create_tween()
	tween.tween_property(_dim, "color:a", 0.0, 0.4)
	await tween.finished
	_root.queue_free()
	_blocker.queue_free()
	_faces.clear()
	_tally = null
	return {"winner": winner, "loser": loser, "rounds": rounds}


# ---- the VS card ----

func _vs_card(players: Array[Dictionary], stake: String, controls: Array, needed: int) -> void:
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

	# The keys, as paper keycaps under each strip.
	var caps: Array[Node2D] = []
	if Online.active and not (Online.is_mine(players[0]) or Online.is_mine(players[1])):
		# A spectator sees who plays, not keys.
		var names := _holder(Vector2(CENTER.x, 790))
		var names_line := _label(tr("MINI_NAMES") % [players[0].name, players[1].name], 54, CREAM, 1200.0)
		names_line.add_theme_color_override("font_outline_color", INK)
		names_line.add_theme_constant_override("outline_size", 10)
		names_line.position = Vector2(-600, -36)
		names.add_child(names_line)
		PaperMotion.pop_in(names, 0.5)
		caps.append(names)
	for i in 2:
		if Online.active and not Online.is_mine(players[i]):
			continue # online, only your own keys are shown
		var side := -1.0 if i == 0 else 1.0
		var at := Vector2(CENTER.x + side * STRIP_GAP, 780)
		var row := 0
		for line in controls:
			var cap_row := _keycaps(i, line[0], tr(line[1]))
			cap_row.position = at + Vector2(0, row * 80.0)
			cap_row.set_meta("rest_position", cap_row.position)
			caps.append(cap_row)
			PaperMotion.pop_in(cap_row, 0.5 + 0.15 * i)
			row += 1
	var get_ready := _holder(Vector2(CENTER.x, 960))
	var ready_text := _label(tr("MINI_GET_READY"), 56, CREAM, 500.0)
	ready_text.add_theme_color_override("font_outline_color", INK)
	ready_text.add_theme_constant_override("outline_size", 10)
	ready_text.position = Vector2(-250, -36)
	get_ready.add_child(ready_text)
	PaperMotion.pop_in(get_ready, 0.7)
	await get_tree().create_timer(2.2, false).timeout

	for node in strips + caps + [vs, plate, get_ready]:
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


# A row of keycaps for one side with the words after them.
func _keycaps(side: int, keys: Array, words: String) -> Node2D:
	var row := _holder(Vector2.ZERO)
	var gap := 62.0
	var width := keys.size() * gap + 260.0
	var x := -width / 2.0
	for key in keys:
		var cap := Keycap.new(MinigameInput.label(side, key))
		cap.position = Vector2(x + gap / 2.0, 0)
		row.add_child(cap)
		x += gap
	var text := _label(words, 40, CREAM, 240.0)
	text.add_theme_color_override("font_outline_color", INK)
	text.add_theme_constant_override("outline_size", 8)
	text.position = Vector2(x + 10.0, -26)
	row.add_child(text)
	return row


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


func _banner_round(n: int) -> Node2D:
	var banner := _holder(Vector2(960, HUD_Y + 22.0))
	var text := _label(tr("MINI_ROUND") % n, 52, CREAM, 500.0)
	text.add_theme_color_override("font_outline_color", INK)
	text.add_theme_constant_override("outline_size", 10)
	text.position = Vector2(-250, -42)
	banner.add_child(text)
	get_tree().create_timer(2.4, false).timeout.connect(func() -> void: PaperMotion.pop_out(banner))
	return banner


# A huge number pops at the center and tears away, with a tick.
func _count(n: int, quick: bool) -> void:
	var k := 0.6 if quick else 1.0
	Sound.play("ui_click")
	var number := _label(str(n), 380, CREAM, 400.0)
	number.add_theme_color_override("font_outline_color", INK)
	number.add_theme_constant_override("outline_size", 30)
	number.size = Vector2(400, 440)
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.position = -number.size / 2
	var holder := Node2D.new()
	holder.position = Vector2(960, 560)
	holder.add_child(number)
	_root.add_child(holder)
	holder.scale = Vector2.ONE * 2.2
	var tween := holder.create_tween()
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


func _draw_banner() -> void:
	var banner := _holder(Vector2(960, 540))
	var plate := Sprite2D.new()
	plate.texture = preload("res://assets/art/ui/panel.png")
	plate.scale = Vector2(760, 140) / plate.texture.get_size()
	banner.add_child(plate)
	PaperShadow.add(plate)
	var text := _label(tr("MINI_DRAW"), 64, INK, 700.0)
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


## A small paper keycap: a cream square with the key's letter, or a drawn arrow.
class Keycap extends Node2D:
	const SIZE := 54.0
	var _text: String
	var _label: Label

	func _init(text: String) -> void:
		_text = text
		if text not in ["^", "<", "v", ">"]:
			_label = Label.new()
			_label.text = text
			_label.add_theme_font_override("font", MinigameFrame.DISPLAY)
			_label.add_theme_font_size_override("font_size", 38)
			_label.add_theme_color_override("font_color", MinigameFrame.INK)
			_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_label.size = Vector2(SIZE, SIZE)
			_label.position = Vector2(-SIZE / 2.0, -SIZE / 2.0 - 2.0)
			add_child(_label)

	func _draw() -> void:
		var box := Rect2(-Vector2.ONE * SIZE / 2.0, Vector2.ONE * SIZE)
		draw_rect(Rect2(box.position + Vector2(3, 4), box.size), Color(0, 0, 0, 0.35))
		draw_rect(box.grow(4.0), MinigameFrame.INK)
		draw_rect(box, MinigameFrame.CREAM)
		if _label == null:
			var dir: Vector2 = {"^": Vector2.UP, "<": Vector2.LEFT, "v": Vector2.DOWN, ">": Vector2.RIGHT}[_text]
			var side := dir.orthogonal()
			draw_colored_polygon(PackedVector2Array([dir * 15.0, -dir * 11.0 + side * 13.0, -dir * 11.0 - side * 13.0]),
					MinigameFrame.INK)
