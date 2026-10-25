class_name ShotGame
extends Node2D
## Shot in the Dark, drawn in the frame's 1920 x 1080 space on a paper card: a question with a number
## for an answer, a box for each side's guess (the challenger on the left), a countdown and a paper
## keypad. Each side types its guess in secret and locks it in; the answers are revealed and the
## closest one wins. Played on one screen, the challenger types first behind a cover card, then the
## cover passes to the opponent, each with `SECONDS`. `run` plays one question and gives the winning
## side (0 the challenger, 1 the opponent) or `DRAW`. Online (`run_online`) the layout is the same for
## every copy: the two duelists type at the same time on their own computers (the keypad and a "You"
## tag only on their own side), everyone else watches the boxes get stamped, and `Online.shot` brings
## back both answers for the reveal, which every copy runs and judges alike.

const DRAW := -1
const SECONDS := 20.0
const MAX_DIGITS := 9
const HYDE_FACTOR := 0.8 # Mr. Hyde as the challenger: his distance counts this much
const LOW_SECONDS := 5
const INK := Color("2a1a22")
const CREAM := Color("fbe9d0")
const RED := Color("d83a2e")
const GREEN := Color("3f9a4f")
const DISPLAY := preload("res://assets/fonts/display.ttf")
const PANEL := preload("res://assets/art/ui/panel.png")
const CARD_AT := Vector2(960, 452)
const CARD_SIZE := Vector2(1560, 480)
const QUESTION_AT := Vector2(960, 372)
const QUESTION_WIDTH := 1400.0
const QUESTION_HEIGHT := 170.0
const BOX_SIZE := Vector2(520, 170)
const BOX_X := 480.0
const BOX_Y := 585.0
const KEY := 92.0
const KEY_GAP := 12.0
const PAD_Y := [800.0, 908.0]

var players: Array[Dictionary] = []
var question: Dictionary = {}
var group := ""
## The side whose guess counts as closer (Mr. Hyde starting the duel), or -1.
var hyde_side := -1

var _card: Node2D
var _boxes: Array[Node2D] = []
var _numbers: Array[Label] = []
var _count: Label
var _count_holder: Node2D
var _pad: Node2D
var _typing := false
var _side := 0
var _text := ""
var _locked := false
var _guesses: Array = [null, null]
var _skip := false
var _lock_button: PaperButton
var _keys: Array[PaperButton] = []
var _stamps: Array[Label] = [null, null]
var _online := false
var _mine: Array[bool] = [true, true] # the sides this computer types for
var _clock_start := -1.0 # online: when the 20 seconds began, in ticks (negative while off)
var _last_shown := -1
var _waiting: Label
var _result: Dictionary = {} # online: both answers, once the host has revealed them


func setup(left: Dictionary, right: Dictionary, asked: Dictionary, group_: String, hyde := -1) -> void:
	players = [left, right]
	group = group_
	question = asked
	hyde_side = hyde


# ---- the rules ----

## Who wins: the smaller `|guess - answer|` (a side with no guess, `null`, loses to a side with one;
## two blanks or an exact tie is a `DRAW`). Mr. Hyde's distance, on `hyde_side`, counts 0.8.
static func judge(a: Variant, b: Variant, answer: float, hyde := -1) -> int:
	if a == null and b == null:
		return DRAW
	if a == null:
		return 1
	if b == null:
		return 0
	var da := absf(float(a) - answer) * (HYDE_FACTOR if hyde == 0 else 1.0)
	var db := absf(float(b) - answer) * (HYDE_FACTOR if hyde == 1 else 1.0)
	if is_equal_approx(da, db):
		return DRAW
	return 0 if da < db else 1


## The typed text after `key` ("0" to "9", "-", ".", or "back"). An invalid key gives the text back
## unchanged. The text always uses "." and a leading "-"; `Questions.group_digits` shows it.
static func type_key(text: String, key: String) -> String:
	match key:
		"back":
			return text.substr(0, text.length() - 1)
		"-":
			return "-" if text.is_empty() else text
		".":
			if "." in text:
				return text
			return text + ("0." if text.is_empty() or text == "-" else ".")
		_:
			if text.replace("-", "").replace(".", "").length() >= MAX_DIGITS:
				return text
			if text == "0" or text == "-0":
				return text.left(text.length() - 1) + key
			return text + key


## The number typed, or null when there is none yet ("" or "-").
static func value_of(text: String) -> Variant:
	for ch in text:
		if ch >= "0" and ch <= "9":
			return text.to_float()
	return null


# ---- one question ----

## Plays one question and gives the winning side or `DRAW`. Add the game to the tree first.
func run() -> int:
	_build()
	await get_tree().create_timer(0.7, false).timeout
	for side in 2:
		await _cover(side)
		await _type_turn(side)
	return await _reveal()


## Plays one question over the relay and gives the winning side or `DRAW`, the same on every copy.
## Add the game to the tree first. The countdown is only a display: the host decides when time is up.
func run_online() -> int:
	_online = true
	_mine = [Online.is_mine(players[0]), Online.is_mine(players[1])]
	_build()
	for side in 2:
		if _mine[side]:
			_side = side
			_typing = true
			_text = ""
			_show_text()
			PaperMotion.lift(_boxes[side], true)
	Online.shot_status.connect(_on_status)
	_clock_start = Time.get_ticks_msec()
	_fetch.call() # not awaited here: the keys and the clock keep working while the shot is open
	for side in 2: # a status that arrived before this copy got here
		if Online.shot_marked(side):
			_on_status(0, side)
	if Online.bot and _typing:
		_bot_types()
	while _result.is_empty():
		await get_tree().process_frame
	var result := _result
	_clock_start = -1.0
	_typing = false
	Online.shot_status.disconnect(_on_status)
	_waiting.visible = false
	_guesses = [result.a, result.b]
	return await _reveal()


func _fetch() -> void:
	_result = await Online.shot(players, SECONDS)


func _process(_delta: float) -> void:
	if _clock_start < 0.0:
		return
	var left := SECONDS - (Time.get_ticks_msec() - _clock_start) / 1000.0
	var shown := maxi(ceili(left), 0)
	if shown != _last_shown:
		_last_shown = shown
		_tick(shown)
	if left <= 0.0 and _typing:
		Sound.play("timer_out")
		_online_lock()


# This side's guess is final: it goes to the host, and the box wears its stamp.
func _online_lock() -> void:
	_typing = false
	_guesses[_side] = value_of(_text)
	if _guesses[_side] != null:
		Online.shot_lock(_side, float(_guesses[_side]))
	_stamp(_side, _guesses[_side] != null)
	PaperMotion.lift(_boxes[_side], false)
	_update_waiting()


# The host said `side` has locked in; a side this computer types for was stamped when it locked.
func _on_status(_seq: int, side: int) -> void:
	if _stamps[side] == null and not _mine[side]:
		_stamp(side)
		PaperMotion.squash(_boxes[side])
	_update_waiting()


# "Waiting for Name" while one duelist has locked and the other, who is not this computer's, has not.
func _update_waiting() -> void:
	var locked := [_stamps[0] != null, _stamps[1] != null]
	var slow := -1
	if locked[0] != locked[1]:
		slow = 1 if locked[0] else 0
	_waiting.visible = slow >= 0 and not _mine[slow]
	if _waiting.visible:
		_waiting.text = tr("SITD_WAITING") % players[slow].name
		PaperMotion.squash(_waiting)


# A test bot types a plausible number after a few seconds and locks it.
func _bot_types() -> void:
	await get_tree().create_timer(randf_range(3.0, 8.0), false).timeout
	if _typing:
		_text = str(roundi(float(question.answer) * randf_range(0.5, 1.5)))
		_show_text()
		_press("lock")


func _build() -> void:
	_card = Node2D.new()
	_card.position = CARD_AT
	_card.set_meta("rest_position", CARD_AT)
	_card.set_meta("rest_scale", Vector2.ONE)
	add_child(_card)
	var paper := Sprite2D.new()
	paper.texture = PANEL
	paper.scale = CARD_SIZE / PANEL.get_size()
	_card.add_child(paper)
	PaperShadow.add(paper)
	PaperMotion.drop_in(_card, 700.0, 0.45)
	get_tree().create_timer(0.3, false).timeout.connect(func() -> void: Sound.play("card_slam"))

	# The category tag.
	var tag := Node2D.new()
	tag.position = Vector2(0, -190)
	_card.add_child(tag)
	var group_name := tr("SITD_GROUP_" + group.to_upper())
	var name_label := _label(group_name, 44, INK, 400.0)
	var name_width := DISPLAY.get_string_size(group_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 44).x
	var icon := Sprite2D.new()
	icon.texture = load("res://assets/art/icons/%s.png" % group)
	icon.scale = Vector2.ONE * 64.0 / icon.texture.get_height()
	icon.position = Vector2(-name_width / 2.0 - 50.0, 0)
	tag.add_child(icon)
	name_label.position = Vector2(-200, -29)
	tag.add_child(name_label)

	_question_lines()
	for side in 2:
		_box(side)
	_count_holder = Node2D.new()
	_count_holder.position = Vector2(960, BOX_Y)
	add_child(_count_holder)
	_count = _label(str(int(SECONDS)), 150, INK, 300.0)
	_count.size = Vector2(300, 200)
	_count.position = Vector2(-150, -100)
	_count_holder.add_child(_count)
	PaperMotion.pop_in(_count_holder, 0.6)
	if _online:
		_waiting = _label("", 36, INK, 700.0)
		_waiting.position = Vector2(960 - 350, 735)
		_waiting.visible = false
		add_child(_waiting)
	if not _online or _mine[0] or _mine[1]:
		_keypad()


# The question, wrapped to the card and shrunk until it fits, its lines popping in one by one.
func _question_lines() -> void:
	var words := Questions.text(question).split(" ")
	var size := 56
	var lines: Array[String] = []
	while true:
		lines = _wrap(words, size)
		if lines.size() * size * 1.2 <= QUESTION_HEIGHT or size <= 26:
			break
		size -= 2
	var top := QUESTION_AT.y - lines.size() * size * 1.2 / 2.0 - CARD_AT.y
	for i in lines.size():
		var line := _label(lines[i], size, INK, QUESTION_WIDTH + 100.0)
		line.size = Vector2(QUESTION_WIDTH + 100.0, size * 1.2)
		line.position = -line.size / 2.0
		var holder := Node2D.new() # pops about the line's middle
		holder.position = Vector2(0, top + (i + 0.5) * size * 1.2)
		holder.set_meta("rest_position", holder.position)
		holder.set_meta("rest_scale", Vector2.ONE)
		holder.add_child(line)
		_card.add_child(holder)
		PaperMotion.pop_in(holder, 0.35 + 0.1 * i)


func _wrap(words: PackedStringArray, size: int) -> Array[String]:
	var lines: Array[String] = []
	var line := ""
	for word in words:
		var tried := word if line == "" else line + " " + word
		if line != "" and DISPLAY.get_string_size(tried, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > QUESTION_WIDTH:
			lines.append(line)
			line = word
		else:
			line = tried
	lines.append(line)
	return lines


func _box(side: int) -> void:
	var at := Vector2(960 + (-1.0 if side == 0 else 1.0) * BOX_X, BOX_Y)
	var box := Node2D.new()
	box.position = at
	box.set_meta("rest_position", at)
	box.set_meta("rest_scale", Vector2.ONE)
	add_child(box)
	var paper := Sprite2D.new()
	paper.texture = PANEL
	paper.scale = BOX_SIZE / PANEL.get_size()
	box.add_child(paper)
	PaperShadow.add(paper)
	var who := _label(players[side].name, 34, Monsters.color(players[side].monster), BOX_SIZE.x - 30.0)
	who.add_theme_color_override("font_outline_color", INK)
	who.add_theme_constant_override("outline_size", 6)
	who.position = Vector2(-BOX_SIZE.x / 2.0 + 15.0, -BOX_SIZE.y / 2.0 + 8.0)
	box.add_child(who)
	var number := _label("..." if _online and not _mine[side] else "?", 80, INK, BOX_SIZE.x - 30.0)
	number.size = Vector2(BOX_SIZE.x - 30.0, 100)
	number.position = Vector2(-BOX_SIZE.x / 2.0 + 15.0, -30.0)
	number.pivot_offset = number.size / 2.0
	box.add_child(number)
	if _online and _mine[side]:
		var you := _label(tr("SITD_YOU"), 28, INK, 200.0)
		you.position = Vector2(BOX_SIZE.x / 2.0 - 215.0, BOX_SIZE.y / 2.0 - 46.0)
		box.add_child(you)
	_boxes.append(box)
	_numbers.append(number)
	PaperMotion.pop_in(box, 0.5 + 0.1 * side)


func _keypad() -> void:
	_pad = Node2D.new()
	add_child(_pad)
	var top: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
	var x0 := 960.0 - (top.size() * KEY + (top.size() - 1) * KEY_GAP) / 2.0
	for i in top.size():
		_key(top[i], top[i], Vector2(x0 + i * (KEY + KEY_GAP), PAD_Y[0]), Vector2(KEY, KEY), 0.7 + 0.03 * i)
	var wide := Vector2(KEY * 3.4, KEY)
	var row2 := 3 * (KEY + KEY_GAP) + wide.x
	var x := 960.0 - row2 / 2.0
	_key("-", Questions.MINUS, Vector2(x, PAD_Y[1]), Vector2(KEY, KEY), 0.95)
	_key(".", Questions.decimal_mark(), Vector2(x + KEY + KEY_GAP, PAD_Y[1]), Vector2(KEY, KEY), 1.0)
	_key("back", "<", Vector2(x + 2 * (KEY + KEY_GAP), PAD_Y[1]), Vector2(KEY, KEY), 1.05)
	_lock_button = _key("lock", "SITD_LOCK", Vector2(x + 3 * (KEY + KEY_GAP), PAD_Y[1]), wide, 1.1)


func _key(id: String, label: String, at: Vector2, size: Vector2, delay: float) -> PaperButton:
	var button := PaperButton.new()
	button.text = label
	button.size = size
	button.position = at
	button.add_theme_font_size_override("font_size", 44 if id.length() == 1 or id == "back" else 38)
	button.pressed.connect(_press.bind(id))
	_pad.add_child(button)
	_keys.append(button)
	button.enter(delay)
	return button


# ---- the turns ----

# The cover card: it slides across, says who types, and goes away on the player's click.
func _cover(side: int) -> void:
	var cover := Node2D.new()
	cover.position = Vector2(960, 540)
	cover.set_meta("rest_position", cover.position)
	cover.set_meta("rest_scale", Vector2.ONE)
	cover.z_index = 20
	add_child(cover)
	var paper := Sprite2D.new()
	paper.texture = PANEL
	paper.scale = Vector2(1100, 360) / PANEL.get_size()
	cover.add_child(paper)
	PaperShadow.add(paper)
	var line := _label(tr("SITD_COVER") % players[side].name, 56, Monsters.color(players[side].monster), 1000.0)
	line.add_theme_color_override("font_outline_color", INK)
	line.add_theme_constant_override("outline_size", 8)
	line.position = Vector2(-500, -120)
	cover.add_child(line)
	var ready_button := PaperButton.new()
	ready_button.text = "SITD_READY"
	ready_button.size = Vector2(360, 100)
	ready_button.position = Vector2(-180, 20)
	cover.add_child(ready_button)
	Sound.play("flip")
	PaperMotion.slide_in(cover, 2600.0 if side == 0 else -700.0)
	ready_button.enter(0.5)
	await ready_button.pressed
	Sound.play("flip")
	ready_button.leave()
	PaperMotion.lift_away(cover, 700.0, 0.4)
	await get_tree().create_timer(0.35, false).timeout
	cover.queue_free()


# One side types for `SECONDS`, or until it locks in. The box's text is the guess, shown grouped.
func _type_turn(side: int) -> void:
	_side = side
	_text = ""
	_locked = false
	_typing = true
	_show_text()
	PaperMotion.lift(_boxes[side], true)
	var start := Time.get_ticks_msec()
	var last_shown := int(SECONDS) + 1
	while not _locked:
		var left := SECONDS - (Time.get_ticks_msec() - start) / 1000.0
		if left <= 0.0:
			Sound.play("timer_out")
			break
		var shown := ceili(left)
		if shown != last_shown:
			last_shown = shown
			_tick(shown)
		await get_tree().process_frame
	_typing = false
	_guesses[side] = value_of(_text)
	_count.text = "0" if not _locked else _count.text
	_count.add_theme_color_override("font_color", INK)
	_stamp(side, _guesses[side] != null)
	PaperMotion.lift(_boxes[side], false)
	await get_tree().create_timer(0.5, false).timeout


func _tick(seconds: int) -> void:
	_count.text = str(seconds)
	if seconds <= LOW_SECONDS:
		_count.add_theme_color_override("font_color", RED)
		if seconds > 0:
			Sound.play("timer_low")
		PaperMotion.squash(_count_holder)
		PaperMotion.shake(_count_holder)
	else:
		_count.add_theme_color_override("font_color", INK)


# The box wears a stamp and hides its number until the reveal.
func _stamp(side: int, has_guess := true, quiet := false) -> void:
	var stamp := _label(tr("SITD_LOCKED") if has_guess else tr("SITD_NOTHING"), 44, RED, 300.0)
	stamp.rotation_degrees = -8.0
	stamp.position = Vector2(-150, -36)
	_boxes[side].add_child(stamp)
	_stamps[side] = stamp
	_numbers[side].text = ""
	PaperMotion.pop_in(stamp)
	if not quiet:
		Sound.play("ready")


func _show_text() -> void:
	_numbers[_side].text = Questions.group_digits(_text) if _text != "" else "?"


func _press(id: String) -> void:
	if not _typing:
		return
	if id == "lock":
		if value_of(_text) == null:
			_deny()
			return
		if _online:
			_online_lock()
		else:
			_locked = true
		return
	var typed := type_key(_text, id)
	if typed == _text:
		_deny()
		return
	_text = typed
	_show_text()
	Sound.play("ui_click", 0.0, randf_range(0.95, 1.1))
	PaperMotion.squash(_numbers[_side])


func _deny() -> void:
	Sound.play("ui_denied")
	PaperMotion.shake(_boxes[_side])


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_skip = true # a click hurries the reveal
		return
	if not (event is InputEventKey and event.pressed and _typing):
		return
	var id := ""
	match event.keycode:
		KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
			id = str(event.keycode - KEY_0)
		KEY_KP_0, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9:
			id = str(event.keycode - KEY_KP_0)
		KEY_MINUS, KEY_KP_SUBTRACT:
			id = "-"
		KEY_PERIOD, KEY_COMMA, KEY_KP_PERIOD:
			id = "."
		KEY_BACKSPACE:
			id = "back"
		KEY_ENTER, KEY_KP_ENTER:
			id = "lock"
		_:
			return
	get_viewport().set_input_as_handled()
	_press(id)


# ---- the reveal ----

func _reveal() -> int:
	_typing = false
	_skip = false
	for button in _keys:
		button.leave()
	PaperMotion.pop_out(_count_holder)
	for side in 2: # a side that never locked still shows its stamp before it turns over
		if _stamps[side] == null:
			_stamp(side, _guesses[side] != null, true)
	Sound.play("drumroll")
	await _wait(1.3)

	var answer := float(question.answer)
	var verdict := judge(_guesses[0], _guesses[1], answer, hyde_side)
	var middle := Node2D.new()
	middle.position = Vector2(960, BOX_Y)
	middle.set_meta("rest_position", middle.position)
	middle.set_meta("rest_scale", Vector2.ONE)
	add_child(middle)
	var paper := Sprite2D.new()
	paper.texture = PANEL
	paper.scale = Vector2(380, 190) / PANEL.get_size()
	middle.add_child(paper)
	PaperShadow.add(paper)
	var caption := _label(tr("SITD_ANSWER"), 30, INK, 340.0)
	caption.position = Vector2(-170, -80)
	middle.add_child(caption)
	var truth := _label(Questions.format(answer), 64, INK, 340.0)
	truth.position = Vector2(-170, -38)
	middle.add_child(truth)
	PaperMotion.drop_in(middle, 500.0, 0.3)
	await _wait(0.25)
	Sound.play("card_slam")
	PaperMotion.squash(middle)
	await _wait(0.5)

	for side in 2:
		_flip_box(side)
		await _wait(0.45)
	await _wait(0.9)

	for side in 2:
		var tag := _label(_off_text(side, answer), 36, INK, BOX_SIZE.x, true)
		tag.position = -tag.size / 2.0
		var holder := Node2D.new()
		holder.position = Vector2(_boxes[side].position.x, BOX_Y + 120.0)
		holder.set_meta("rest_position", holder.position)
		holder.set_meta("rest_scale", Vector2.ONE)
		holder.add_child(tag)
		add_child(holder)
		PaperMotion.pop_in(holder, 0.1 * side)
	await _wait(0.5)
	if verdict != DRAW:
		_ribbon(verdict)
	await _wait(0.9)
	return verdict


# The box turns over, shows the stamp-less guess, and the number counts up to it.
func _flip_box(side: int) -> void:
	var guess: Variant = _guesses[side]
	_stamps[side].queue_free()
	Sound.play("flip")
	PaperMotion.flip(_boxes[side], func() -> void:
		_numbers[side].text = "" if guess == null else Questions.format(0.0))
	if guess == null:
		return
	var tween := create_tween()
	tween.tween_interval(0.2)
	tween.tween_method(func(v: float) -> void:
		_numbers[side].text = Questions.format(v), 0.0, float(guess), 0.6) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: _numbers[side].text = Questions.format(float(guess)))


func _off_text(side: int, answer: float) -> String:
	if _guesses[side] == null:
		return tr("SITD_NO_GUESS")
	return tr("SITD_OFF_BY") % Questions.format(absf(float(_guesses[side]) - answer))


# The winner's box lifts under a green ribbon, and the loser droops.
func _ribbon(winner: int) -> void:
	var loser := 1 - winner
	PaperMotion.lift(_boxes[winner], true)
	var ribbon := Polygon2D.new()
	ribbon.polygon = PackedVector2Array([Vector2(-260, -22), Vector2(260, -22), Vector2(236, 0), Vector2(260, 22),
			Vector2(-260, 22), Vector2(-236, 0)])
	ribbon.color = GREEN
	var holder := Node2D.new()
	holder.position = _boxes[winner].position + Vector2(0, -BOX_SIZE.y / 2.0 - 20.0)
	holder.set_meta("rest_position", holder.position)
	holder.set_meta("rest_scale", Vector2.ONE)
	holder.add_child(ribbon)
	var line := _label(tr("SITD_CLOSEST"), 30, CREAM, 480.0)
	line.position = Vector2(-240, -20)
	holder.add_child(line)
	add_child(holder)
	PaperMotion.pop_in(holder)
	Sound.play("ready")
	var sag := _boxes[loser].create_tween().set_parallel()
	sag.tween_property(_boxes[loser], "modulate", Color(0.6, 0.6, 0.65), 0.3)
	sag.tween_property(_boxes[loser], "rotation_degrees", (-1.0 if loser == 1 else 1.0) * 4.0, 0.3)


# Waits `seconds`, or until a click hurries the reveal.
func _wait(seconds: float) -> void:
	var end := Time.get_ticks_msec() + seconds * 1000.0
	while Time.get_ticks_msec() < end and not _skip:
		await get_tree().process_frame


func _label(text: String, size: int, color: Color, width: float, outlined := false) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", DISPLAY)
	label.add_theme_color_override("font_color", color)
	while size > 14 and DISPLAY.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width - 12.0:
		size -= 2
	label.add_theme_font_size_override("font_size", size)
	label.size = Vector2(width, size * 1.3)
	if outlined:
		label.add_theme_color_override("font_outline_color", CREAM)
		label.add_theme_constant_override("outline_size", 10)
	return label
