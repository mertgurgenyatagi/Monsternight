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
const COIN_X := 22.0
const COIN_SIZE := 30.0 # coin.png is 256
const INK := Color("f4e7c8")
const OUTLINE := Color("1a1022")
const EMPTY := Color(0.16, 0.1, 0.12, 0.6) # a lost drop: the same drop, darkened and faded
const ACTIVE_DROP := 16.0
const COIN_TIME := 1.0 # no count takes longer than this
const COIN_TICK := 0.14
const GREY_TIME := 0.5

## The player's dictionary in `Match.players`.
var player: Dictionary
var active := false
var finished := false

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

	var drop_scale := Vector2.ONE * DROP_SIZE / 128.0
	for i in Match.MAX_BLOOD:
		var drop := Sprite2D.new()
		drop.texture = preload("res://assets/art/icons/blood.png")
		drop.position = Vector2(DROP_X + i * DROP_STEP, ROW_Y)
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
## a gained one pops back in.
func show_blood() -> void:
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


## Ticks the coin count one coin at a time to what `Match` has now.
func show_coins() -> void:
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


## Where the blood or coin counter is, on screen.
func anchor(what: String) -> Vector2:
	return to_global(_drops[1].position if what == "blood" else _coin.position)


func _resting_color() -> Color:
	var base := _color.lightened(0.25) if active else _color.darkened(0.12)
	if finished:
		var grey := base.get_luminance() * 0.7
		return base.lerp(Color(grey, grey, grey), 0.7)
	return base


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
