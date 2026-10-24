class_name Die
extends Node2D
## The paper die. It drops in above the active piece and waits to be clicked (`clicked`), then
## tumbles and lands on the number the rules rolled. Its origin is its middle. It only shows a
## number: `Match.roll` decides it.

## The die has landed after dropping in, and takes clicks.
signal offered
## The player clicked the die while it was offered.
signal clicked
## The tumble has ended on its face.
signal settled

const SIZE := 160.0
const FACES: Array[Texture2D] = [
	preload("res://assets/art/board/die_1.png"), preload("res://assets/art/board/die_2.png"),
	preload("res://assets/art/board/die_3.png"), preload("res://assets/art/board/die_4.png"),
	preload("res://assets/art/board/die_5.png"), preload("res://assets/art/board/die_6.png"),
]
const DROP_HEIGHT := 700.0
const TOSS_HEIGHT := 170.0
const TOSS_TIME := 0.4

## False when another player rolls this die online: it is only watched.
var clickable := true

var _sprite: Sprite2D
var _area: Area2D
var _face := 1
var _frames := 0
var _roll: Tween


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = FACES[0]
	add_child(_sprite)
	PaperShadow.add(_sprite)
	_area = Area2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2.ONE * SIZE
	_area.add_child(shape)
	_area.input_pickable = false
	_area.input_event.connect(_on_input)
	_area.mouse_entered.connect(_on_hover.bind(true))
	_area.mouse_exited.connect(_on_hover.bind(false))
	add_child(_area)
	visible = false


## Sets where the die rests, in its parent's space.
func place(at: Vector2) -> void:
	position = at
	scale = Vector2.ONE / BoardCamera.ZOOM # stays the size it was before the zoom
	set_meta("rest_position", at)
	set_meta("rest_scale", scale)


## Drops in from above the screen and lands with a squash, then bobs and wobbles until it's
## clicked. Awaiting the signal waits for the landing; from then on the die takes clicks.
func offer() -> Signal:
	_offer()
	return offered


## Stops taking clicks (the click has been sent, and the host's answer is on its way).
func lock() -> void:
	_area.input_pickable = false


## A small shake: the player's time ran out, so the die rolls by itself.
func nudge() -> Tween:
	_area.input_pickable = false
	return PaperMotion.shake(self)


## Tumbles in a short arc, spinning through random faces, lands on `value`, bounces twice and
## settles. Awaiting the signal waits for the end.
func tumble(value: int) -> Signal:
	_tumble(value)
	return settled


## Pops away.
func leave() -> Tween:
	_area.input_pickable = false
	return PaperMotion.pop_out(self)


func _offer() -> void:
	await get_tree().process_frame
	scale = Vector2.ONE / BoardCamera.ZOOM
	rotation = 0.0
	_show(randi_range(1, 6))
	visible = true
	await PaperMotion.drop_in(self, DROP_HEIGHT, 0.4).finished
	Sound.play("die_land")
	PaperMotion.squash(self)
	PaperMotion.breathe(_sprite, 7.0, 2.1)
	PaperMotion.sway(_sprite, 3.5, 3.3).custom_step(randf_range(0.0, 3.3))
	_area.input_pickable = clickable
	offered.emit()


func _tumble(value: int) -> void:
	await get_tree().process_frame
	_area.input_pickable = false
	_kill_idle()
	PaperMotion.lift(self, false)
	var home: Vector2 = get_meta("rest_position")
	if _roll and _roll.is_valid():
		_roll.kill()
	_roll = create_tween()
	# A quick crouch, with the idle wobble settling out.
	_roll.tween_property(_sprite, "scale", Vector2(1.12, 0.8), 0.12) 			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_roll.parallel().tween_property(_sprite, "position", Vector2.ZERO, 0.12)
	_roll.parallel().tween_property(_sprite, "rotation", 0.0, 0.12)
	_roll.tween_callback(Sound.play.bind("die_roll"))
	_roll.tween_method(_toss.bind(home), 0.0, 1.0, TOSS_TIME)
	_roll.tween_callback(func() -> void:
			_show(value)
			Sound.play("die_land")
			position = home
			_sprite.rotation = 0.0)
	# Land flat, bounce high then low, each time squashing.
	_squash_step(Vector2(1.25, 0.7), 0.06)
	_bounce(40.0, home)
	_squash_step(Vector2(1.14, 0.84), 0.05)
	_bounce(14.0, home)
	_squash_step(Vector2(1.08, 0.9), 0.04)
	# The number pops so it reads.
	_roll.tween_property(_sprite, "scale", Vector2.ONE * 1.22, 0.07) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_roll.tween_property(_sprite, "scale", Vector2.ONE, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_roll.tween_callback(settled.emit)


func _squash_step(to: Vector2, duration: float) -> void:
	_roll.tween_property(_sprite, "scale", to, duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _bounce(height: float, home: Vector2) -> void:
	var time := 0.08 + height * 0.001
	_roll.tween_property(_sprite, "scale", Vector2(0.95, 1.06), time)
	_roll.parallel().tween_property(self, "position:y", home.y - height, time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_roll.tween_property(self, "position:y", home.y, time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_roll.parallel().tween_property(_sprite, "scale", Vector2.ONE, time)


# The flight of the toss: up and down in an arc, two full spins, and a new random face every
# other frame.
func _toss(t: float, home: Vector2) -> void:
	position = home - Vector2(0, TOSS_HEIGHT * 4.0 * t * (1.0 - t))
	_sprite.rotation = t * TAU * 2.0
	var stretch := sin(t * PI)
	_sprite.scale = Vector2(1.0 - 0.08 * stretch, 1.0 + 0.1 * stretch)
	_frames += 1
	if _frames % 2 == 0:
		var next := randi_range(1, 5)
		_show(next if next < _face else next + 1) # never the same face twice in a row


func _show(face: int) -> void:
	_face = face
	_sprite.texture = FACES[face - 1]


func _kill_idle() -> void:
	for kind in ["breathe", "sway"]:
		var key: String = "tween_" + kind
		if _sprite.has_meta(key):
			var tween: Tween = _sprite.get_meta(key)
			if tween.is_valid():
				tween.kill()


func _on_hover(over: bool) -> void:
	if over:
		if _area.input_pickable:
			Sound.play("ui_hover")
			PaperMotion.lift(self, true)
	elif get_meta("raised", false):
		PaperMotion.lift(self, false)


func _on_input(_viewport: Node, event: InputEvent, _shape: int) -> void:
	if _area.input_pickable and event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_area.input_pickable = false
		Sound.play("ui_click")
		clicked.emit()
