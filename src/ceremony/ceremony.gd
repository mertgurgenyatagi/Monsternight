class_name Ceremony
extends Control
## The trophy ceremony. The curtain opens on a dark stage with every player's piece in a row, then
## the trophies are handed out one kind at a time, least meaningful first (most duels won, most gold,
## second to finish, first to finish). Each round is a title card, a drumroll, and the winners
## stepping into the spotlight as the trophy flies into their count. Then the pieces rearrange by
## rank under a leaderboard. The counts are secret until a trophy lands on them.
##
## Run on its own (for a check), it makes a match of however many players come after `--` (4 by
## default), with ties; a second argument "quiet" gives a match where nobody wins anything.

const FLOOR_Y := 800.0 # where the pieces' stands rest
const SIDE := 175.0
const DIM := 0.6 # how much of its color a piece keeps while it isn't in the light
const CARD_AT := Vector2(960, 270)
const TROPHY_AT := Vector2(960, 470)
const COUNTER_Y := 112.0 # the trophy count under a piece, from the middle of its stand
const COUNTER_SIZE := 44.0
const DRUMROLL := 3.0
const BODY := preload("res://assets/fonts/body.ttf")
const DISPLAY := preload("res://assets/fonts/display.ttf")
const TROPHY := preload("res://assets/art/ui/trophy.png")
const INK := Color("2a1a22")
const CREAM := Color("fbe9d0")
const GOLD := Color(1.0, 0.82, 0.42)
const SPOT := Color(1.0, 0.86, 0.55, 0.0)

## One entry per player in the row, left to right: `{row, slot, piece, count_node, count_label,
## count, home}`. `slot` holds the piece, its name and its count, and is what moves.
var _slots: Array[Dictionary] = []
var _results: Array = []
var _stage: Node2D
var _spot: Glow
var _curtain: Curtain
var _scale := 1.0
var _board: Node2D # the leaderboard panel


func _ready() -> void:
	if Match.players.is_empty():
		_start_test_match()
	_results = Match.results()
	_build_stage()
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_curtain = Curtain.new()
	layer.add_child(_curtain)
	_run()


func _run() -> void:
	await _wait(0.6)
	Sound.play_music("ceremony")
	Sound.play("fly", -3.0)
	_curtain.move(0.08, 2.0, 0.0)
	await _wait(1.3)
	await _drop_in()
	var rounds := _rounds()
	for kind in rounds:
		await _round(kind)
	await _leaderboard()


# The four kinds of trophy, in the order they are handed out, with the slots that won each and how
# many trophies of the kind each gets. A kind nobody won is left out.
func _rounds() -> Array[Dictionary]:
	var kinds: Array[Dictionary] = [
		{"key": "duels", "title": "TROPHY_DUELS", "each": 1,
				"won": func(row: Dictionary) -> bool: return row.by.duels > 0},
		{"key": "gold", "title": "TROPHY_GOLD", "each": 1,
				"won": func(row: Dictionary) -> bool: return row.by.gold > 0},
		{"key": "second", "title": "TROPHY_SECOND", "each": 1,
				"won": func(row: Dictionary) -> bool: return row.finish == 2},
		{"key": "first", "title": "TROPHY_FIRST", "each": 2,
				"won": func(row: Dictionary) -> bool: return row.finish == 1},
	]
	var rounds: Array[Dictionary] = []
	for kind in kinds:
		var winners: Array[Dictionary] = []
		for slot in _slots:
			if kind.won.call(slot.row):
				winners.append(slot)
		if winners.is_empty():
			continue
		kind.winners = winners
		rounds.append(kind)
		print("Round: ", kind.key, " ", winners.map(func(s: Dictionary) -> String: return s.row.player.name))
	return rounds


# --- The stage -----------------------------------------------------------------------------------

func _build_stage() -> void:
	$Sky.tint(Color(0.04, 0.03, 0.1), Color(0.2, 0.08, 0.2), 0.0)
	var floor_rect := ColorRect.new()
	floor_rect.color = Color("1b1024")
	floor_rect.position = Vector2(0, FLOOR_Y - 34.0)
	floor_rect.size = Vector2(1920, 1080.0 - FLOOR_Y + 34.0)
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_rect)
	var edge := ColorRect.new()
	edge.color = Color("3a2140")
	edge.size = Vector2(1920, 8)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floor_rect.add_child(edge)

	_spot = Glow.new(SPOT, 700.0)
	_spot.position = Vector2(960, FLOOR_Y - 240.0)
	add_child(_spot)
	_stage = Node2D.new()
	add_child(_stage)

	# Finished players first, in the order they finished, then the others by rank.
	var order := _results.duplicate()
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if (a.finish > 0) != (b.finish > 0):
			return a.finish > 0
		return a.finish < b.finish if a.finish > 0 else a.rank < b.rank)
	var count := order.size()
	_scale = 1.25 if count <= 4 else (1.1 if count <= 6 else 1.0)
	var xs := _xs(count)
	for i in count:
		_slots.append(_make_slot(order[i], Vector2(xs[i], FLOOR_Y), xs[1] - xs[0] if count > 1 else 280.0))


# The x of each of `count` places in a row, centered.
func _xs(count: int) -> Array[float]:
	var gap := minf(280.0, (1920.0 - 2.0 * SIDE) / maxf(count - 1, 1))
	var xs: Array[float] = []
	for i in count:
		xs.append(960.0 + (i - (count - 1) / 2.0) * gap)
	return xs


func _make_slot(row: Dictionary, at: Vector2, width: float) -> Dictionary:
	var slot := Node2D.new()
	slot.position = at
	slot.set_meta("rest_position", at)
	slot.visible = false
	slot.modulate = Color.WHITE
	_stage.add_child(slot)

	var piece := BoardPiece.new(row.player)
	piece.scale = Vector2.ONE * _scale
	piece.set_meta("rest_scale", piece.scale)
	slot.add_child(piece)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = row.player.name
	label.clip_text = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font_size := 36
	var room := width - 14.0
	while font_size > 18 and BODY.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > room:
		font_size -= 2
	label.add_theme_font_override("font", BODY)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_color_override("font_outline_color", Color("120a1a"))
	label.add_theme_constant_override("outline_size", 8)
	label.size = Vector2(room, 48)
	label.position = Vector2(-room / 2.0, 48)
	slot.add_child(label)

	var counter := Node2D.new()
	counter.position = Vector2(0, COUNTER_Y)
	counter.set_meta("rest_scale", Vector2.ONE)
	counter.scale = Vector2.ZERO
	slot.add_child(counter)
	var icon := Sprite2D.new()
	icon.texture = TROPHY
	icon.scale = Vector2.ONE * COUNTER_SIZE / TROPHY.get_width()
	icon.position = Vector2(-26, 0)
	counter.add_child(icon)
	var number := Label.new()
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.add_theme_font_override("font", DISPLAY)
	number.add_theme_font_size_override("font_size", 44)
	number.add_theme_color_override("font_color", GOLD)
	number.add_theme_color_override("font_outline_color", Color("120a1a"))
	number.add_theme_constant_override("outline_size", 8)
	number.size = Vector2(60, 52)
	number.position = Vector2(2, -28)
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	counter.add_child(number)
	return {"row": row, "slot": slot, "piece": piece, "count_node": counter, "count_label": number,
			"count": 0}


func _drop_in() -> void:
	for i in _slots.size():
		var slot: Node2D = _slots[i].slot
		slot.visible = true
		PaperMotion.drop_in(slot, 760.0, 0.7, i * 0.12)
		_land_sound(i * 0.12 + 0.55)
		_dim(_slots[i], DIM, 0.0)
	await _wait(_slots.size() * 0.12 + 0.9)


func _land_sound(delay: float) -> void:
	await _wait(delay)
	Sound.play("hop")


# --- A round -------------------------------------------------------------------------------------

func _round(kind: Dictionary) -> void:
	var winners: Array[Dictionary] = kind.winners
	var card := PaperBanner.new(tr(kind.title))
	card.position = CARD_AT
	card.set_meta("rest_position", CARD_AT)
	card.set_meta("rest_scale", Vector2.ONE)
	add_child(card)
	PaperMotion.drop_in(card, 420.0, 0.5)
	Sound.play("card_slam", -4.0)
	_spot.aim(0.16, 800.0, Vector2(960, FLOOR_Y - 240.0), 0.6)
	await _wait(0.8)

	PaperMotion.breathe(card, 4.0, 1.1)
	Sound.play("drumroll")
	_spot.aim(0.36, 480.0, Vector2(960, FLOOR_Y - 240.0), DRUMROLL)
	await _tremble(DRUMROLL)
	await _wait(0.3)

	# The winners step into the light.
	var middle := 0.0
	var span_left := INF
	var span_right := -INF
	for slot in winners:
		middle += slot.slot.position.x / winners.size()
		span_left = minf(span_left, slot.slot.position.x)
		span_right = maxf(span_right, slot.slot.position.x)
	var radius := maxf(340.0, (span_right - span_left) / 2.0 + 260.0)
	_spot.aim(0.5, radius, Vector2(middle, FLOOR_Y - 240.0), 0.3)
	for slot in winners:
		_step(slot, true)
	for slot in _slots:
		if not winners.has(slot):
			_clap(slot)
	await _wait(0.4)

	# The trophy.
	Sound.play("trophy")
	var trophy := _trophy(TROPHY_AT, 0.9)
	var flare := Glow.new(Color(1.0, 0.8, 0.4, 0.8), 230.0)
	flare.position = TROPHY_AT
	add_child(flare)
	flare.flare(1.6, 0.12, 0.9).finished.connect(flare.queue_free)
	PaperMotion.pop_in(trophy, 0.0, 0.4)
	await _wait(0.45)
	var spin := trophy.create_tween()
	spin.tween_property(trophy, "rotation", TAU, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	spin.tween_callback(func() -> void: trophy.rotation = 0.0)
	await _wait(0.5)
	PaperMotion.squash(trophy)
	await _wait(0.3)

	# One copy for every trophy of the round, thrown one after another.
	var throws: Array[Dictionary] = []
	for slot in winners:
		for i in kind.each:
			throws.append(slot)
	for i in throws.size():
		var copy := trophy if i == 0 else _trophy(TROPHY_AT, 0.9)
		if i > 0:
			Sound.play("fly", -6.0, 1.0 + i * 0.05)
		_throw(copy, throws[i], i == 0 or not is_same(throws[i - 1], throws[i]))
		await _wait(0.2)
	await _wait(0.9)

	# Back into the dark.
	for slot in winners:
		_step(slot, false)
	_spot.aim(0.0, 700.0, Vector2(960, FLOOR_Y - 240.0), 0.6)
	await PaperMotion.lift_away(card, 500.0, 0.4).finished
	card.queue_free()
	await _wait(0.3)


func _trophy(at: Vector2, size: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = TROPHY
	sprite.position = at
	sprite.scale = Vector2.ONE * size
	sprite.set_meta("rest_position", at)
	sprite.set_meta("rest_scale", sprite.scale)
	add_child(sprite)
	PaperShadow.add(sprite)
	return sprite


# Flies a trophy copy into a player's count. Its arrival adds to the count; the winner does their
# win pose when the first copy lands.
func _throw(trophy: Sprite2D, slot: Dictionary, first: bool) -> void:
	var target: Vector2 = slot.slot.position + slot.count_node.position
	var tween := PaperMotion.fly_to(trophy, target, Vector2.ONE * COUNTER_SIZE / TROPHY.get_width(), 0.65, 0.0, 160.0)
	await tween.finished
	trophy.queue_free()
	slot.count += 1
	slot.count_label.text = "×%d" % slot.count
	if slot.count == 1:
		PaperMotion.pop_in(slot.count_node, 0.0, 0.35)
	else:
		PaperMotion.squash(slot.count_node)
	Sound.play("coin_land", -4.0, 1.3)
	if first:
		_celebrate(slot)


func _celebrate(slot: Dictionary) -> void:
	PaperMotion.hop(slot.piece, 46.0)
	Sound.play(Monsters.voice(slot.row.player.monster, "win"))


# The others clap: a quick sway, each out of step.
func _clap(slot: Dictionary) -> void:
	await _wait(randf_range(0.0, 0.3))
	PaperMotion.tilt(slot.piece, 4.0)


# A winner steps forward into the light (and the others stay dim), or back again.
func _step(slot: Dictionary, forward: bool) -> void:
	var home: Vector2 = slot.slot.get_meta("rest_position")
	_dim(slot, 1.0 if forward else DIM, 0.3)
	var size: Vector2 = Vector2.ONE * _scale * (1.12 if forward else 1.0)
	slot.piece.set_meta("rest_scale", size)
	var tween: Tween = slot.piece.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(slot.piece, "scale", size, 0.3)
	var offset := Vector2(0, 26) if forward else Vector2(0, -26)
	PaperMotion.move_to(slot.slot, home + offset, 0.3)


func _dim(slot: Dictionary, level: float, duration: float) -> void:
	var color := Color(level, level, level)
	if duration <= 0.0:
		slot.slot.modulate = color
		return
	slot.slot.create_tween().tween_property(slot.slot, "modulate", color, duration)


# The pieces' stands tremble, more and more, for `duration` seconds, and settle back.
func _tremble(duration: float) -> void:
	var phases: Array[float] = []
	for slot in _slots:
		phases.append(randf() * TAU)
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
			var amplitude := lerpf(1.0, 5.0, t)
			for i in _slots.size():
				var slot: Node2D = _slots[i].slot
				var home: Vector2 = slot.get_meta("rest_position")
				slot.position.x = home.x + sin(t * duration * 62.0 + phases[i]) * amplitude,
			0.0, 1.0, duration)
	await tween.finished
	for slot in _slots:
		var home: Vector2 = slot.slot.get_meta("rest_position")
		slot.slot.position = home


# --- The leaderboard -----------------------------------------------------------------------------

func _leaderboard() -> void:
	for slot in _slots:
		slot.piece.set_meta("rest_scale", Vector2.ONE * _scale)
		slot.piece.scale = Vector2.ONE * _scale
		if slot.row.trophies > 0:
			_dim(slot, 1.0, 0.4)
		else:
			_dim(slot, 0.72, 0.4)
			_shrug(slot)
	_spot.aim(0.0, 700.0, Vector2(960, FLOOR_Y - 240.0), 0.5)
	await _wait(0.6)

	# Rearrange by rank.
	var xs := _xs(_slots.size())
	var ranked: Array[Dictionary] = []
	for row in _results:
		for slot in _slots:
			if is_same(slot.row, row):
				ranked.append(slot)
	Sound.play("fly", -3.0)
	for i in ranked.size():
		var slot: Dictionary = ranked[i]
		var target := Vector2(xs[i], FLOOR_Y)
		if not is_equal_approx(slot.slot.position.x, target.x):
			_toss_later(slot, target, i * 0.07)
	_panel(ranked)
	await _wait(1.6 + ranked.size() * 0.07)

	# The best get their moment.
	if _results[0].trophies > 0:
		for slot in ranked:
			if slot.row.rank == 1:
				_crown(slot)
		await _wait(0.8)
	var button := PaperButton.new()
	button.text = "CEREMONY_CONTINUE"
	button.position = Vector2(760, 960)
	button.size = Vector2(400, 88)
	add_child(button)
	button.enter(0.2)
	button.pressed.connect(func() -> void:
			button.leave()
			_stats())


# --- The fun stats -------------------------------------------------------------------------------

# The leaderboard lifts away, then each stat gets a card, and then the ending.
func _stats() -> void:
	Sound.play("flip", -4.0)
	PaperMotion.lift_away(_board, 900.0, 0.5)
	await _wait(0.7)
	_board.queue_free()
	var shown := Match.stats()
	if shown.is_empty():
		await _stat_card(null)
	for stat in shown:
		await _stat_card(stat)
	_ending()


# One paper card: the stat's title, the portraits of whoever holds it, and the number counting up.
# `null` makes the card for a match where nothing happened.
func _stat_card(stat) -> void:
	var size := Vector2(940, 520)
	var at := Vector2(960, 510)
	var card := Node2D.new()
	card.position = at + Vector2(0, 900)
	card.rotation_degrees = -7.0
	card.set_meta("rest_position", at)
	card.z_index = 5
	add_child(card)
	var paper := Sprite2D.new()
	paper.texture = preload("res://assets/art/ui/panel.png")
	paper.scale = size / paper.texture.get_size()
	paper.self_modulate = Color("f0dcc0")
	card.add_child(paper)
	PaperShadow.add(paper)

	var title := _card_label(tr("STAT_QUIET") if stat == null else tr("STAT_%s_TITLE" % stat.key.to_upper()),
			DISPLAY, 64, Color("a8341c"), Vector2(size.x - 80.0, 90))
	title.position = Vector2(-size.x / 2.0 + 40.0, -size.y / 2.0 + 40.0)
	card.add_child(title)

	var portraits: Array[Sprite2D] = []
	var counter: Label
	if stat != null:
		var holders: Array = stat.players
		var room := (size.x - 100.0) / holders.size()
		var width := minf(200.0, room - 10.0)
		for i in holders.size():
			var x := (i - (holders.size() - 1) / 2.0) * room
			var portrait := Sprite2D.new()
			portrait.texture = Monsters.portrait(holders[i].monster)
			portrait.scale = Vector2.ONE * width / portrait.texture.get_width()
			portrait.position = Vector2(x, -35.0)
			portrait.set_meta("rest_position", portrait.position)
			card.add_child(portrait)
			portraits.append(portrait)
			var name_label := _card_label(holders[i].name, BODY, 30, INK, Vector2(room - 6.0, 40))
			name_label.position = Vector2(x - (room - 6.0) / 2.0, -35.0 + width / 2.0 + 8.0)
			card.add_child(name_label)
		counter = _card_label("", DISPLAY, 72, INK, Vector2(size.x - 80.0, 100))
		counter.position = Vector2(-size.x / 2.0 + 40.0, size.y / 2.0 - 135.0)
		card.add_child(counter)

	var slide := card.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	slide.tween_property(card, "position", at, 0.7)
	slide.tween_property(card, "rotation_degrees", 0.0, 0.7)
	await _wait(0.45)
	Sound.play("stat")
	await _wait(0.4)
	if stat != null:
		for portrait in portraits:
			PaperMotion.hop(portrait, 30.0)
		var key: String = "STAT_%s" % stat.key.to_upper()
		var ticks := func(n: float) -> void:
			var whole := int(round(n))
			var text := tr(key + "_ONE") if whole == 1 else tr(key)
			var changed := counter.text != text % whole
			counter.text = text % whole
			if changed and whole > 0:
				Sound.play("ui_click", -6.0, 1.0 + 0.12 * whole)
		var count := create_tween()
		count.tween_method(ticks, 0.0, float(stat.value), 0.5)
		await count.finished
		PaperMotion.squash(counter)
		print("Stat: ", stat.key, " ", stat.players.map(func(p: Dictionary) -> String: return p.name), " ", counter.text)
	else:
		print("Stat: none, a very quiet night")
	await _wait(2.2)
	await PaperMotion.lift_away(card, 900.0, 0.45).finished
	card.queue_free()
	await _wait(0.25)


func _card_label(text: String, font: Font, font_size: int, color: Color, size: Vector2) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.clip_text = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	while font_size > 18 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > size.x:
		font_size -= 2
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.size = size
	return label


# --- The ending ----------------------------------------------------------------------------------

func _ending() -> void:
	var again := PaperButton.new()
	again.text = "CEREMONY_AGAIN"
	again.position = Vector2(500, 900)
	again.size = Vector2(400, 88)
	var quit := PaperButton.new()
	quit.text = "TITLE_QUIT"
	quit.position = Vector2(1020, 900)
	quit.size = Vector2(400, 88)
	for button in [again, quit]:
		add_child(button)
	again.enter(0.2)
	quit.enter(0.4)
	again.pressed.connect(_leave.bind("res://src/setup/setup.tscn", [again, quit], true))
	quit.pressed.connect(_leave.bind("res://src/title/title.tscn", [again, quit], false))


# The music fades, the match is cleared, and the curtain closes as it did on the board before the
# scene changes under it. The title's own curtain is closed and opens, so the loop reads as a circle.
func _leave(path: String, buttons: Array, paper: bool) -> void:
	for button: PaperButton in buttons:
		button.disabled = true
		button.leave()
	Sound.play_music("")
	Sound.play_ambience("")
	Match.reset()
	Sound.play("fly", -3.0)
	await _curtain.move(1.0, 1.3, 0.0).finished
	await _wait(0.6)
	if paper:
		Scenes.change_to(path)
	else:
		get_tree().change_scene_to_file(path)


func _toss_later(slot: Dictionary, target: Vector2, delay: float) -> void:
	await _wait(delay)
	PaperMotion.toss(slot.slot, target, 1.0, 150.0, 0)


func _shrug(slot: Dictionary) -> void:
	await _wait(randf_range(0.2, 0.8))
	PaperMotion.tilt(slot.piece, 3.0)


func _crown(slot: Dictionary) -> void:
	var node: Node2D = slot.slot
	var glow := Glow.new(Color(1.0, 0.8, 0.4, 0.7), 200.0)
	glow.position = Vector2(0, -120.0 * _scale)
	node.add_child(glow)
	glow.flare(1.6, 0.12, 1.0).finished.connect(glow.queue_free)
	var crown := Sprite2D.new()
	crown.texture = TROPHY
	crown.scale = Vector2.ONE * 100.0 / TROPHY.get_width()
	crown.position = Vector2(0, -(182.0 * _scale + 90.0))
	crown.set_meta("rest_position", crown.position)
	crown.set_meta("rest_scale", crown.scale)
	node.add_child(crown)
	PaperShadow.add(crown)
	PaperMotion.pop_in(crown, 0.0, 0.5)
	PaperMotion.breathe(crown, 5.0, 1.6)
	Sound.play("trophy", -2.0)
	_celebrate(slot)


# The paper list of ranks, names and trophy counts, rising from below. Players tied share a rank.
func _panel(ranked: Array[Dictionary]) -> void:
	var rows := ranked.size()
	var size := Vector2(720, 44.0 * rows + 48.0)
	var at := Vector2(960, 175.0 + size.y / 2.0)
	var panel := Node2D.new()
	panel.position = at + Vector2(0, 900)
	panel.set_meta("rest_position", at)
	add_child(panel)
	var paper := Sprite2D.new()
	paper.texture = preload("res://assets/art/ui/panel.png")
	paper.scale = size / paper.texture.get_size()
	paper.self_modulate = Color("f0dcc0")
	panel.add_child(paper)
	PaperShadow.add(paper)
	for i in rows:
		var slot: Dictionary = ranked[i]
		var y := -size.y / 2.0 + 24.0 + 44.0 * i + 22.0
		var rank := Label.new()
		rank.text = tr("PLACE_%d" % mini(slot.row.rank, 8))
		rank.add_theme_font_override("font", DISPLAY)
		rank.add_theme_font_size_override("font_size", 36)
		rank.add_theme_color_override("font_color", Color("a8341c") if slot.row.rank == 1 else INK)
		rank.size = Vector2(110, 44)
		rank.position = Vector2(-320, y - 22)
		rank.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(rank)
		var name_label := Label.new()
		name_label.text = slot.row.player.name
		name_label.clip_text = true
		name_label.add_theme_font_override("font", BODY)
		name_label.add_theme_font_size_override("font_size", 34)
		name_label.add_theme_color_override("font_color", INK)
		name_label.size = Vector2(380, 44)
		name_label.position = Vector2(-200, y - 22)
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(name_label)
		var icon := Sprite2D.new()
		icon.texture = TROPHY
		icon.scale = Vector2.ONE * 40.0 / TROPHY.get_width()
		icon.position = Vector2(225, y)
		panel.add_child(icon)
		var count := Label.new()
		count.text = "×%d" % slot.row.trophies
		count.add_theme_font_override("font", DISPLAY)
		count.add_theme_font_size_override("font_size", 38)
		count.add_theme_color_override("font_color", INK)
		count.size = Vector2(80, 44)
		count.position = Vector2(250, y - 22)
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(count)
		print("Board: ", slot.row.rank, ". ", slot.row.player.name, " x", slot.row.trophies,
				" (shown ", slot.count, ")")
	panel.z_index = 5
	_board = panel
	var rise := panel.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rise.tween_property(panel, "position", at, 0.9).set_delay(0.3)


# --- Helpers -------------------------------------------------------------------------------------

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


# Run on its own, a match with ties: the first two players finish, the later ones tie on duels and
# gold. With "quiet" nobody wins anything.
func _start_test_match() -> void:
	var args := OS.get_cmdline_user_args()
	var count := int(args[0]) if args.size() > 0 else 4
	var quiet := args.size() > 1 and args[1] == "quiet"
	var names: Array[String] = []
	for n in ["Ayşe", "Bartholomew", "Cem", "Dracula", "Esra", "Frankenstein's Monster", "Gül", "Hasan"].slice(0, count):
		names.append(n)
	Match.start(names)
	for i in count:
		var player: Dictionary = Match.players[i]
		player.monster = Monsters.IDS[i]
		if quiet:
			continue
		player.coins = [4, 7, 7, 1, 0, 3, 2, 5][i]
		player.duels_won = [2, 0, 2, 1, 0, 0, 1, 0][i]
		player.deaths = [0, 1, 0, 1, 0, 0, 0, 0][i] # a tie
		player.duels_started = [0, 0, 0, 4, 0, 0, 0, 0][i]
		player.challenged = [0, 1, 0, 0, 0, 0, 0, 0][i] # a single holder, a count of 1
		player.spike_blood = [0, 0, 5, 0, 0, 0, 0, 0][i]
	if not quiet:
		Match.finish(Match.players[2 % count])
		Match.finish(Match.players[0])
