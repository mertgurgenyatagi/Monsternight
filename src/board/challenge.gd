class_name Challenge
extends Node2D
## The challenge a minigame space asks for, drawn on the HUD's layer (so a child of `Hud`, whose
## coordinates are the screen's). A paper banner drops in under the strip and the valid portraits
## bob: the challenger clicks an opponent. Then three stake cards fan out under that portrait, and a
## click slaps one down. One 20 s candle burns for both steps together. When it goes out, a valid
## opponent and then a valid stake are picked at random, with a shake and a beat so it's clear
## nobody clicked. When the only stake the opponent allows is a swap, a "Walk away" button sits under
## the cards, and the challenger can end the space with nothing taken.

## The step is decided: by a click (true), or because the candle went out (false).
signal _decided(by_click: bool)

const SECONDS := 20.0
const BANNER_AT := Vector2(960, 345)
const BANNER_SIZE := Vector2(560, 66)
const CANDLE_AT := Vector2(1330, 505) # the candle's base, by the banner's right corner
const CANDLE_SCALE := 0.4
const CARD_Y := 600.0
const CARD_STEP := 206.0
const CARD_SCALE := 0.47 # card.png is 400 x 560
const CARD_TURN := [-7.0, 0.0, 7.0] # degrees
const CARD_FIT := 330.0 # the fan's middle stays this far from the screen's sides
const ICON_SIZE := 96.0
const STAKES := ["gold", "blood", "swap"]
const WALK := "walk" # the stake that means no duel
const WALK_Y := 835.0
const WALK_SIZE := Vector2(320, 80)
const ICONS := {
	"gold": preload("res://assets/art/icons/coin.png"),
	"blood": preload("res://assets/art/icons/blood.png"),
	"swap": preload("res://assets/art/icons/swap.png"),
}
const TIMEOUT_BEAT := 0.3
const PICK_BEAT := 0.55
const CONFIRM_BEAT := 0.6
const DIM := Color(0.5, 0.5, 0.55)
const INK := Color("2a1a22")

var _hud: Hud
var _candle: Candle
var _banner: Node2D
var _banner_label: Label
var _opponent := {}
var _stake := ""
var _timed_out := false
var _cards := {} # stake -> its card (a Node2D)
var _valid: Array[String] = []
var _cards_open := false
var _walk_button: PaperButton
var _online := false # the host decides; the candle here is only for show
var _mine := true # this copy's player is the challenger
var _acted := false # this copy has already shown the click it made
var _began := 0 # when the step began, in ticks, for the 20 s both steps share


func _ready() -> void:
	_banner = Node2D.new()
	_banner.visible = false
	_banner.position = BANNER_AT
	add_child(_banner)
	var texture := preload("res://assets/art/ui/panel.png")
	var paper := Sprite2D.new()
	paper.texture = texture
	paper.scale = BANNER_SIZE / texture.get_size()
	_banner.add_child(paper)
	PaperShadow.add(paper)
	_banner_label = Label.new()
	_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_label.size = BANNER_SIZE
	_banner_label.position = -BANNER_SIZE / 2
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_override("font", preload("res://assets/fonts/display.ttf"))
	_banner_label.add_theme_font_size_override("font_size", 34)
	_banner_label.add_theme_color_override("font_color", INK)
	_banner.add_child(_banner_label)
	_candle = Candle.new()
	_candle.scale = Vector2.ONE * CANDLE_SCALE
	_candle.set_meta("rest_scale", _candle.scale)
	_candle.visible = false
	add_child(_candle)


## Asks `challenger` for an opponent and a stake. Gives `{opponent, stake}` (the opponent's player
## dictionary and "gold", "blood" or "swap"), always: a timeout picks for them. Gives an empty
## dictionary at once when there is nobody to duel. The stake is "walk" when the challenger walks away.
func ask(challenger: Dictionary) -> Dictionary:
	_hud = get_parent()
	var options := Match.opponents(challenger)
	if options.is_empty():
		return {}
	_timed_out = false
	_stake = ""
	_online = Online.active
	_mine = Online.is_mine(challenger) if _online else true
	_acted = false
	_began = Time.get_ticks_msec()
	_banner_label.text = tr("CHALLENGE_OPPONENT")
	_banner.visible = true
	_banner.set_meta("rest_position", BANNER_AT)
	_banner.rotation = 0.0
	PaperMotion.drop_in(_banner, 320.0, 0.5)
	await get_tree().create_timer(0.55, false).timeout
	_candle.position = CANDLE_AT
	_candle.rotation = 0.0
	_candle.set_meta("rest_position", CANDLE_AT)
	_candle.visible = true
	PaperMotion.pop_in(_candle)
	_candle.start(SECONDS)
	if not _online:
		_candle.timed_out.connect(_on_timed_out)

	# Step 1: the opponent.
	var by_click: bool
	if _online:
		var names: Array = options.map(func(p: Dictionary) -> String: return p.name)
		if _mine:
			_hud.set_pickable(options)
			_hud.portrait_clicked.connect(_on_portrait)
		var answer := await Online.decide("opponent", challenger, SECONDS,
				func() -> String: return names.pick_random(),
				func(v: Variant) -> bool: return v is String and v in names)
		if _mine:
			_hud.portrait_clicked.disconnect(_on_portrait)
		_opponent = options[names.find(answer.value)]
		by_click = not answer.auto
		_timed_out = answer.auto
		if by_click and not _acted:
			Sound.play("ui_click")
			_hud.set_lit(_opponent, true)
	else:
		_hud.set_pickable(options)
		_hud.portrait_clicked.connect(_on_portrait)
		by_click = await _decided
		_hud.portrait_clicked.disconnect(_on_portrait)
	if not by_click:
		_hud.shake(options)
		await get_tree().create_timer(TIMEOUT_BEAT, false).timeout
		if not _online:
			_opponent = options.pick_random()
		_hud.set_lit(_opponent, true)
		await get_tree().create_timer(PICK_BEAT, false).timeout
	_hud.clear_pickable()

	# Step 2: the stake.
	PaperMotion.flip(_banner, func() -> void: _banner_label.text = tr("CHALLENGE_STAKE"))
	_valid = Match.stakes(challenger, _opponent)
	var nothing := _valid.is_empty()
	if _valid == ["swap"]:
		_valid.append(WALK)
	if nothing:
		_valid = [WALK]
		PaperMotion.flip(_banner, func() -> void: _banner_label.text = tr("CHALLENGE_NOTHING"))
		await get_tree().create_timer(1.0, false).timeout
		_stake = WALK
	else:
		_make_cards(_hud.portrait_at(_opponent))
		for player: Dictionary in [challenger, _opponent]:
			if Match.blood_is_safe(player) and "blood" not in _valid:
				# Death can't be bled at 1 blood: the pop sits under their portrait, which shrugs.
				PowerPop.show_over(self, _hud.portrait_at(player) + Vector2(0, 150), tr("POP_SAFE"))
				PaperMotion.tilt(_hud.portrait_node(player), 6.0)
		await get_tree().create_timer(0.7, false).timeout
		if _online:
			_acted = false
			_cards_open = _mine and not _timed_out
			var left := 0.0 if _timed_out else maxf(SECONDS - (Time.get_ticks_msec() - _began) / 1000.0, 0.0)
			var valid := _valid.duplicate()
			var answer := await Online.decide("stake", challenger, left,
					func() -> String: return valid.pick_random(),
					func(v: Variant) -> bool: return v is String and v in valid)
			_cards_open = false
			_stake = answer.value
			if answer.auto:
				for stake in _valid:
					PaperMotion.shake(_walk_button if stake == WALK else _cards[stake])
				await get_tree().create_timer(TIMEOUT_BEAT, false).timeout
			if not _acted or answer.auto:
				if _stake == WALK:
					_walk_away()
				else:
					_slam(_stake)
		else:
			if not _timed_out:
				_cards_open = true
				await _decided
				_cards_open = false
			if _stake == "":
				for stake in _valid:
					PaperMotion.shake(_walk_button if stake == WALK else _cards[stake])
				await get_tree().create_timer(TIMEOUT_BEAT, false).timeout
				_stake = _valid.pick_random()
				if _stake == WALK:
					_walk_away()
				else:
					_slam(_stake)
	if not _online:
		_candle.timed_out.disconnect(_on_timed_out)
	_candle.stop()
	await PaperMotion.lift_away(_candle, 500.0, 0.4).finished
	_candle.visible = false
	await get_tree().create_timer(CONFIRM_BEAT, false).timeout
	var result := {"opponent": _opponent, "stake": _stake}
	_finish()
	return result


func _make_cards(from: Vector2) -> void:
	var x0 := clampf(from.x, CARD_FIT, 1920.0 - CARD_FIT)
	for i in STAKES.size():
		var stake: String = STAKES[i]
		var card := Node2D.new()
		var rest := Vector2(x0 + (i - 1) * CARD_STEP, CARD_Y + absf(i - 1) * 14.0)
		card.position = from
		card.set_meta("rest_position", rest)
		card.set_meta("rest_scale", Vector2.ONE)
		add_child(card)
		var face := Node2D.new()
		face.rotation_degrees = CARD_TURN[i]
		card.add_child(face)
		var paper := Sprite2D.new()
		paper.texture = preload("res://assets/art/ui/card.png")
		paper.scale = Vector2.ONE * CARD_SCALE
		face.add_child(paper)
		PaperShadow.add(paper)
		var icon := Sprite2D.new()
		icon.texture = ICONS[stake]
		icon.scale = Vector2.ONE * ICON_SIZE / icon.texture.get_height()
		icon.position = Vector2(0, -52)
		face.add_child(icon)
		var line := Label.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.text = tr("STAKE_" + stake.to_upper())
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.size = Vector2(140, 80)
		line.position = Vector2(-70, 16)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.add_theme_font_override("font", preload("res://assets/fonts/display.ttf"))
		line.add_theme_font_size_override("font_size", 28)
		line.add_theme_color_override("font_color", INK)
		face.add_child(line)
		if stake not in _valid:
			face.modulate = DIM
		var area := Area2D.new()
		var shape := CollisionShape2D.new()
		shape.shape = RectangleShape2D.new()
		shape.shape.size = paper.texture.get_size() * CARD_SCALE
		area.add_child(shape)
		area.input_event.connect(_on_card_input.bind(stake))
		area.mouse_entered.connect(_on_card_hover.bind(stake, true))
		area.mouse_exited.connect(_on_card_hover.bind(stake, false))
		face.add_child(area)
		_cards[stake] = card
		card.scale = Vector2.ZERO
		var tween := card.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "position", rest, 0.45).set_delay(i * 0.12)
		tween.tween_property(card, "scale", Vector2.ONE, 0.45).set_delay(i * 0.12)
	if WALK in _valid:
		_walk_button = PaperButton.new()
		_walk_button.text = "CHALLENGE_WALK"
		_walk_button.size = WALK_SIZE
		_walk_button.position = Vector2(x0, WALK_Y) - WALK_SIZE / 2
		_walk_button.pressed.connect(_on_walk)
		add_child(_walk_button)
		_walk_button.enter(0.5)


func _on_portrait(player: Dictionary) -> void:
	_opponent = player
	_hud.set_lit(player, true)
	if _online:
		_acted = true
		Sound.play("ui_click")
		Online.submit(player.name)
	else:
		_decided.emit(true)


func _on_timed_out() -> void:
	_timed_out = true
	_decided.emit(false)


func _on_walk() -> void:
	if not _cards_open:
		return
	_cards_open = false
	_stake = WALK
	_walk_away()
	if _online:
		_acted = true
		Online.submit(WALK)
	else:
		_decided.emit(true)


func _on_card_hover(stake: String, over: bool) -> void:
	if not _cards_open or stake not in _valid:
		return
	if over:
		Sound.play("ui_hover")
	PaperMotion.lift(_cards[stake], over)


func _on_card_input(_viewport: Node, event: InputEvent, _shape: int, stake: String) -> void:
	if not _cards_open or not event is InputEventMouseButton or not event.pressed \
			or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if stake in _valid:
		_cards_open = false
		_stake = stake
		_slam(stake)
		if _online:
			_acted = true
			Online.submit(stake)
		else:
			_decided.emit(true)
	else:
		Sound.play("ui_denied")
		PaperMotion.shake(_cards[stake])


# The card is slapped down on the page with a thud, and the others fall away.
func _slam(stake: String) -> void:
	Sound.play("card_slam")
	var card: Node2D = _cards[stake]
	card.get_child(0).modulate = Color.WHITE
	var tween := card.create_tween()
	tween.tween_property(card, "scale", Vector2.ONE * 1.3, 0.0)
	tween.tween_property(card, "scale", Vector2.ONE * 0.94, 0.1) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		PaperMotion.squash(card)
		var glow := Glow.new(Color(1.0, 0.85, 0.5, 0.5), 150.0)
		glow.show_behind_parent = true
		card.add_child(glow)
		glow.flare())
	for other: String in _cards:
		if other != stake:
			var node: Node2D = _cards[other]
			PaperMotion.lift_away(node, 260.0, 0.35)
			node.create_tween().tween_property(node, "modulate:a", 0.0, 0.3)


# The cards lift away unchosen and the button goes with them.
func _walk_away() -> void:
	for stake: String in _cards:
		var node: Node2D = _cards[stake]
		PaperMotion.lift_away(node, 260.0, 0.35)
		node.create_tween().tween_property(node, "modulate:a", 0.0, 0.3)


# Everything folds away, and the chosen portrait lets go of its light.
func _finish() -> void:
	_hud.set_lit(_opponent, false)
	PaperMotion.lift_away(_banner, 300.0, 0.4)
	if _stake == WALK:
		if _walk_button:
			await _walk_button.leave().finished
		else:
			await get_tree().create_timer(0.4, false).timeout
	else:
		if _walk_button:
			_walk_button.leave()
		await PaperMotion.pop_out(_cards[_stake]).finished
	for stake: String in _cards:
		_cards[stake].queue_free()
	_cards.clear()
	if _walk_button:
		_walk_button.queue_free()
		_walk_button = null
	_banner.visible = false
