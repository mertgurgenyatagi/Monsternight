class_name HudPortrait
extends Node2D
## One player's paper portrait on the HUD strip: the monster's framed face, the name, three blood
## drops and the coin count. Its origin is the middle of its top edge, where it hangs from, so
## its sway swings about that point.

const WIDTH := 184.0
const FRAME_CENTER := Vector2(0, 76)
const FRAME_SIZE := 118.0 # on screen; portrait_frame.png is 300
const PORTRAIT_FIT := 0.83 # the portrait against the frame, as on the pregame's cards
const NAME_Y := 138.0
const ROW_Y := 192.0
const DROP_SIZE := 28.0 # blood.png is 128
const DROP_STEP := 27.0
const DROP_X := -78.0 # the first drop's middle
const DROP_TIGHT_SIZE := 24.0 # with a fourth drop
const DROP_TIGHT_STEP := 22.0
const DROP_TIGHT_X := -84.0
const COIN_X := 22.0
const COIN_SIZE := 30.0 # coin.png is 256
const INK := Color("f4e7c8")
const OUTLINE := Color("1a1022")
const EMPTY := Color(0.16, 0.1, 0.12, 0.6) # a lost drop: the same drop, darkened and faded
const ACTIVE_DROP := 16.0
const COIN_TIME := 1.0 # no count takes longer than this
const COIN_TICK := 0.14
const GREY_TIME := 0.5

## The portrait was clicked while it is pickable and valid.
signal picked
## The portrait was clicked while it is pickable but not a valid choice.
signal denied
## The portrait was clicked while no choice is open: the HUD shows its power card.
signal inspected

const DIM := Color(0.5, 0.5, 0.55)
const BOB := 5.0
const BOB_TIME := 0.5

## The player's dictionary in `Match.players`.
var player: Dictionary
var active := false
var finished := false
## While a choice is open: "" (not a choice), "valid" or "denied".
var pickable := ""

var _color: Color
var _frame: Sprite2D
var _portrait: Sprite2D
var _name: Label
var _drops: Array[Sprite2D] = []
var _coin: Sprite2D
var _count: Label
var _shown_blood: int
var _shown_coins: int
var _ticking := false
var _grey: ShaderMaterial
var _area: Area2D
var _bob: Tween
var _lit := false
var _glow: Glow
var _presence: Label


func _init(for_player := {}) -> void:
	player = for_player


func _ready() -> void:
	_color = Monsters.color(player.monster)
	_shown_blood = player.blood
	_shown_coins = player.coins
	_frame = Sprite2D.new()
	_frame.texture = preload("res://assets/art/ui/portrait_frame.png")
	_frame.position = FRAME_CENTER
	_frame.scale = Vector2.ONE * FRAME_SIZE / 300.0
	_frame.self_modulate = _resting_color()
	add_child(_frame)
	PaperShadow.add(_frame)
	_portrait = Sprite2D.new()
	_portrait.texture = Monsters.portrait(player.monster)
	_portrait.position = FRAME_CENTER
	_portrait.scale = Vector2.ONE * FRAME_SIZE / 300.0 * PORTRAIT_FIT * 300.0 / _portrait.texture.get_width()
	_grey = ShaderMaterial.new()
	_grey.shader = preload("res://src/pregame/grey.gdshader")
	_portrait.material = _grey
	add_child(_portrait)

	_name = Label.new()
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name.text = player.name
	_name.size = Vector2(WIDTH, 30)
	_name.position = Vector2(-WIDTH / 2, NAME_Y)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_color_override("font_color", INK)
	_name.add_theme_color_override("font_outline_color", OUTLINE)
	_name.add_theme_constant_override("outline_size", 6)
	_name.add_theme_font_size_override("font_size", _fitting_size())
	add_child(_name)

	# A fourth drop (Cthulhu's) squeezes in beside the coin, so every drop is a little smaller and closer.
	var cap := Match.max_blood(player)
	var tight := cap > Match.MAX_BLOOD
	var drop_size := DROP_TIGHT_SIZE if tight else DROP_SIZE
	var drop_step := DROP_TIGHT_STEP if tight else DROP_STEP
	var drop_x := DROP_TIGHT_X if tight else DROP_X
	var drop_scale := Vector2.ONE * drop_size / 128.0
	for i in cap:
		var drop := Sprite2D.new()
		drop.texture = preload("res://assets/art/icons/blood.png")
		drop.position = Vector2(drop_x + i * drop_step, ROW_Y)
		drop.scale = drop_scale
		drop.set_meta("rest_scale", drop_scale)
		drop.self_modulate = Color.WHITE if i < _shown_blood else EMPTY
		add_child(drop)
		_drops.append(drop)
	_coin = Sprite2D.new()
	_coin.texture = preload("res://assets/art/icons/coin.png")
	_coin.position = Vector2(COIN_X, ROW_Y)
	_coin.scale = Vector2.ONE * COIN_SIZE / 256.0
	_coin.set_meta("rest_scale", _coin.scale)
	add_child(_coin)
	_count = Label.new()
	_count.size = Vector2(60, 36)
	_count.position = Vector2(COIN_X + 18, ROW_Y - 20)
	_count.add_theme_font_override("font", preload("res://assets/fonts/display.ttf"))
	_count.add_theme_font_size_override("font_size", 32)
	_count.add_theme_color_override("font_color", INK)
	_count.add_theme_color_override("font_outline_color", OUTLINE)
	_count.add_theme_constant_override("outline_size", 6)
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count.text = str(_shown_coins)
	add_child(_count)
	_area = Area2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(FRAME_SIZE, FRAME_SIZE)
	shape.position = FRAME_CENTER
	_area.add_child(shape)
	_area.input_pickable = true
	_area.input_event.connect(_on_input)
	_area.mouse_entered.connect(_on_mouse_entered)
	_area.mouse_exited.connect(_on_mouse_exited)
	add_child(_area)
	start_sway()


## Hangs and sways very slightly, out of step with the others.
func start_sway() -> void:
	PaperMotion.sway(self, randf_range(0.5, 0.9), randf_range(4.0, 6.0)).custom_step(randf_range(0.0, 3.0))


## Raises this portrait's frame colour and drops it lower than the rest, or lets it back up.
func set_active(on: bool) -> void:
	active = on
	var rest: Vector2 = get_meta("rest_position", position)
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", rest.y + (ACTIVE_DROP if on else 0.0), 0.35)
	tween.tween_property(_frame, "self_modulate", _resting_color(), 0.3)
	tween.tween_property(self, "scale", Vector2.ONE * (1.06 if on else 1.0), 0.35)
	if on:
		PaperMotion.sway_stop(self)
	else:
		start_sway()


## Shows the player's blood as `Match` has it now: a lost drop falls off and leaves its outline,
## a gained one pops back in, `gap` seconds after the one before.
func show_blood(gap := 0.0) -> void:
	var target: int = player.blood
	while _shown_blood > target:
		_shown_blood -= 1
		_lose_drop(_drops[_shown_blood])
	while _shown_blood < target:
		var drop := _drops[_shown_blood]
		_shown_blood += 1
		Sound.play("blood_gain")
		drop.self_modulate = Color.WHITE
		PaperMotion.pop_in(drop)


## Ticks the coin count one coin at a time to what `Match` has now, or, with `at_once`, jumps there
## with a single tick, for a count that is wiped out.
func show_coins(at_once := false) -> void:
	if at_once and not _ticking and _shown_coins != player.coins:
		_shown_coins = player.coins
		_count.text = str(_shown_coins)
		Sound.play("coin_gain" if _shown_coins > 0 else "coin_lose")
		PaperMotion.squash(_coin)
		return
	if _ticking:
		return # the running loop reads the new target
	_ticking = true
	while _shown_coins != player.coins:
		var step := signi(player.coins - _shown_coins)
		var left := absi(player.coins - _shown_coins)
		_shown_coins += step
		_count.text = str(_shown_coins)
		Sound.play("coin_gain" if step > 0 else "coin_lose")
		PaperMotion.squash(_coin)
		await get_tree().create_timer(minf(COIN_TICK, COIN_TIME / left), false).timeout
	_ticking = false


## Opens or closes this portrait as a choice. "valid" bobs, lights its frame and lifts on hover and
## gives `picked` on a click; "denied" greys out and gives `denied` on a click; "" closes it again.
func set_pickable(mode: String) -> void:
	if mode == pickable:
		return
	pickable = mode
	if _bob and _bob.is_valid():
		_bob.kill()
	_set_bob(0.0)
	if get_meta("raised", false):
		PaperMotion.lift(self, false)
	create_tween().tween_property(self, "modulate", DIM if mode == "denied" else Color.WHITE, 0.25)
	if mode == "valid":
		if not active:
			PaperMotion.sway_stop(self)
		_bob = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_bob.tween_method(_set_bob, 0.0, 1.0, BOB_TIME)
		_bob.tween_method(_set_bob, 1.0, 0.0, BOB_TIME)
		_bob.custom_step(randf_range(0.0, BOB_TIME))
	elif mode == "" and not active:
		start_sway()
	create_tween().tween_property(_frame, "self_modulate", _resting_color(), 0.25)


## Keeps the frame lit, with a glow behind it, as the chosen one; or lets it go.
func set_lit(on: bool) -> void:
	if on == _lit:
		return
	_lit = on
	create_tween().tween_property(_frame, "self_modulate", _resting_color(), 0.25)
	if on:
		_glow = Glow.new(Color(1.0, 0.85, 0.5, 0.55), 100.0)
		_glow.position = FRAME_CENTER
		add_child(_glow)
		move_child(_glow, 0)
		_glow.pulse(0.3, 0.6, 0.8)
	elif _glow:
		_glow.queue_free()
		_glow = null


## Plants the finished flag on the portrait's corner and greys the portrait a little.
func set_finished() -> void:
	if finished:
		return
	finished = true
	var flag := Flag.new()
	flag.position = FRAME_CENTER + Vector2(FRAME_SIZE * 0.5 - 8, FRAME_SIZE * 0.5 + 6)
	flag.scale = Vector2.ONE * 0.6
	add_child(flag)
	PaperMotion.pop_in(flag)
	var tween := create_tween().set_parallel()
	tween.tween_method(func(amount: float) -> void:
			_grey.set_shader_parameter("amount", amount), 0.0, 0.7, GREY_TIME)
	tween.tween_property(_frame, "self_modulate", _resting_color(), GREY_TIME)
	tween.tween_property(_name, "modulate", Color(0.7, 0.7, 0.7), GREY_TIME)


## Greys the portrait to stone while the player misses a turn (Medusa), or lets the colour back.
func set_stone(on: bool) -> void:
	if finished:
		return
	var from = _grey.get_shader_parameter("amount")
	create_tween().tween_method(func(amount: float) -> void:
			_grey.set_shader_parameter("amount", amount), 0.0 if from == null else float(from),
			0.95 if on else 0.0, GREY_TIME)


## Online: dims the whole portrait with a small word on the frame for a player whose connection is
## gone ("dropped") or who lets the timers play ("away"); "" brings them back. It is a dim, not
## Medusa's stone grey.
func set_presence(state: String) -> void:
	var dim := {"dropped": Color(0.55, 0.55, 0.75, 0.6), "away": Color(0.78, 0.78, 0.78, 0.8)}
	create_tween().tween_property(self, "modulate", dim.get(state, Color.WHITE), 0.4)
	if _presence == null:
		_presence = Label.new()
		_presence.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_presence.size = Vector2(WIDTH, 30)
		_presence.position = Vector2(-WIDTH / 2, FRAME_CENTER.y + 22)
		_presence.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_presence.add_theme_font_override("font", preload("res://assets/fonts/display.ttf"))
		_presence.add_theme_font_size_override("font_size", 24)
		_presence.add_theme_color_override("font_color", Color("fbe9d0"))
		_presence.add_theme_color_override("font_outline_color", OUTLINE)
		_presence.add_theme_constant_override("outline_size", 8)
		add_child(_presence)
	_presence.text = tr({"dropped": "PRESENCE_DROPPED", "away": "PRESENCE_AWAY"}.get(state, "")) if state != "" else ""
	_presence.visible = state != ""


## Where the blood or coin counter is, on screen.
func anchor(what: String) -> Vector2:
	return to_global(_drops[1].position if what == "blood" else _coin.position)


func _resting_color() -> Color:
	var base := _color.lightened(0.25) if active else _color.darkened(0.12)
	if _lit or pickable == "valid":
		base = _color.lightened(0.45)
	if finished:
		var grey := base.get_luminance() * 0.7
		return base.lerp(Color(grey, grey, grey), 0.7)
	return base


func _set_bob(amount: float) -> void:
	var y := -BOB * amount
	_frame.position.y = FRAME_CENTER.y + y
	_portrait.position.y = FRAME_CENTER.y + y


func _on_input(_viewport: Node, event: InputEvent, _shape: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if pickable == "":
			inspected.emit()
		elif pickable == "valid":
			Sound.play("ui_click")
			PaperMotion.squash(self)
			picked.emit()
		else:
			Sound.play("ui_denied")
			PaperMotion.shake(self)
			denied.emit()


func _on_mouse_entered() -> void:
	if pickable == "valid":
		Sound.play("ui_hover")
		PaperMotion.lift(self, true)


func _on_mouse_exited() -> void:
	if pickable == "valid":
		PaperMotion.lift(self, false)


func _lose_drop(drop: Sprite2D) -> void:
	Sound.play("blood_lose")
	var falling := Sprite2D.new()
	falling.texture = drop.texture
	falling.position = drop.position
	falling.scale = drop.scale
	add_child(falling)
	var tween := falling.create_tween().set_parallel()
	tween.tween_property(falling, "position:y", drop.position.y + 110.0, 0.6) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(falling, "scale", Vector2.ONE * 0.02, 0.6)
	tween.tween_property(falling, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(falling.queue_free)
	drop.self_modulate = EMPTY
	PaperMotion.shake(self)


func _fitting_size() -> int:
	var font := _name.get_theme_font("font")
	var size := 24
	while size > 14 and font.get_string_size(_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > WIDTH - 12:
		size -= 1
	return size
