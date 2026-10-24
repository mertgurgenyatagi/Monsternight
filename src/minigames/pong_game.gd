class_name PongGame
extends Minigame
## Pong on a paper table: two cardboard paddles (up and down), a crumpled-paper ball, and the first ball
## past a paddle's line loses the point, which is the game. The challenger is the left paddle. Mr. Hyde's
## edge makes the challenger's paddle `1 + edge` times as fast. Never a draw.

const TABLE_TEX := preload("res://assets/art/minigames/pong_table.png")
const PADDLE_TEX := preload("res://assets/art/minigames/paddle.png")
const BALL_TEX := preload("res://assets/art/monsters/crumpled.png")

## The playfield inside the table's cream border, in table pixels from its top left.
const FIELD := Rect2(51.0, 43.0, 1378.0, 554.0)
const PADDLE_SIZE := Vector2(30.0, 120.0)
const PADDLE_INSET := 56.0
const PADDLE_SPEED := 640.0
const BALL_RADIUS := 22.0
const SERVE_SPEED := 700.0
const SERVE_EASE := 0.4
const MAX_SPEED := 1250.0
const SPEEDUP := 1.1
const MAX_BOUNCE := deg_to_rad(52.0)
const SQUASH_TIME := 0.1
const BITS := 14
const BIT_LIFE := 0.7
const PAPER := Color("fbe9d0")

var paddle_y: Array[float] = [0.0, 0.0] # relative to the field's middle
var ball := Vector2.ZERO # relative to the field's middle
var velocity := Vector2.ZERO
var speed := SERVE_SPEED
var rally_hits := 0

var _serve_t := 0.0
var _spin := 0.0
var _squash: Array[float] = [0.0, 0.0]
var _mood: Array[float] = [0.0, 0.0] # the hop (> 0) or droop (< 0) timer after a point
var _bit_at: Array[Vector2] = []
var _bit_v: Array[Vector2] = []
var _bit_t: Array[float] = []
var _scored := -1


func setup(left: Dictionary, right: Dictionary, challenger: int, edge_value: float) -> void:
	super(left, right, challenger, edge_value)
	for i in BITS:
		_bit_at.append(Vector2.ZERO)
		_bit_v.append(Vector2.ZERO)
		_bit_t.append(0.0)
	_serve()


func controls() -> Array:
	return [[["up", "down"], "KEYS_UPDOWN"]]


func _serve() -> void:
	ball = Vector2.ZERO
	var angle := rng.randf_range(-0.4, 0.4)
	var dir := 1.0 if rng.randf() < 0.5 else -1.0
	velocity = Vector2(dir * cos(angle), sin(angle)) * SERVE_SPEED
	speed = SERVE_SPEED
	_serve_t = 0.0


## The paddle's x, relative to the field's middle.
func paddle_x(side: int) -> float:
	var half := FIELD.size.x / 2.0 - PADDLE_INSET
	return -half if side == 0 else half


func paddle_speed(side: int) -> float:
	return PADDLE_SPEED * (1.0 + (edge if side == challenger_side else 0.0))


func _physics_process(delta: float) -> void:
	if active:
		step(delta)


func get_state() -> Dictionary:
	return {"py": paddle_y.duplicate(), "ball": Minigame.pack(ball), "vel": Minigame.pack(velocity),
			"speed": speed, "hits": rally_hits, "serve": _serve_t, "scored": _scored}


func set_state(d: Dictionary) -> void:
	for i in 2:
		paddle_y[i] = float(d.py[i])
	ball = Minigame.unpack(d.ball)
	velocity = Minigame.unpack(d.vel)
	speed = float(d.speed)
	rally_hits = int(d.hits)
	_serve_t = float(d.serve)
	_scored = int(d.scored)


func blend_keys() -> Array:
	return ["py"]


func blend_pairs() -> Array:
	return [["ball", "vel"]]


## One physics step: the paddles move, the ball moves in sub-steps and may bounce, score or hit a paddle.
func step(delta: float) -> void:
	var reach := FIELD.size.y / 2.0 - PADDLE_SIZE.y / 2.0
	for side in 2:
		var dy := MinigameInput.direction(side).y
		paddle_y[side] = clampf(paddle_y[side] + dy * paddle_speed(side) * delta, -reach, reach)
	_serve_t = minf(_serve_t + delta, SERVE_EASE)
	var ease_in := smoothstep(0.0, 1.0, _serve_t / SERVE_EASE)
	var pace := velocity * ease_in
	var steps := maxi(1, ceili(pace.length() * delta / (BALL_RADIUS * 0.5)))
	var dt := delta / steps
	for i in steps:
		ball += pace * dt
		if _collide():
			return
		pace = velocity * ease_in
	_spin += velocity.x * ease_in * delta / BALL_RADIUS * 0.5
	queue_redraw()


# Returns true when the point is over.
func _collide() -> bool:
	var top := -FIELD.size.y / 2.0 + BALL_RADIUS
	if ball.y < top and velocity.y < 0.0 or ball.y > -top and velocity.y > 0.0:
		ball.y = clampf(ball.y, top, -top)
		velocity.y = -velocity.y
		Sound.play("bounce", -6.0)
	for side in 2:
		var dir := 1.0 if side == 0 else -1.0 # the way the ball leaves this paddle
		if velocity.x * dir >= 0.0:
			continue
		var face := paddle_x(side) + dir * PADDLE_SIZE.x / 2.0
		if (ball.x - face) * dir > BALL_RADIUS or (ball.x - face) * dir < -PADDLE_SIZE.x:
			continue
		if absf(ball.y - paddle_y[side]) > PADDLE_SIZE.y / 2.0 + BALL_RADIUS * 0.6:
			continue
		var rel := clampf((ball.y - paddle_y[side]) / (PADDLE_SIZE.y / 2.0 + BALL_RADIUS * 0.6), -1.0, 1.0)
		speed = minf(speed * SPEEDUP, MAX_SPEED)
		var angle := rel * MAX_BOUNCE
		velocity = Vector2(dir * cos(angle), sin(angle)) * speed
		ball.x = face + dir * BALL_RADIUS
		rally_hits += 1
		_squash[side] = SQUASH_TIME
		Sound.play("paddle_hit", -3.0, 0.9 + 0.2 * speed / MAX_SPEED)
	var line := FIELD.size.x / 2.0
	if absf(ball.x) > line:
		_score(0 if ball.x > 0.0 else 1)
		return true
	return false


func _score(side: int) -> void:
	_scored = side
	var edge_x := FIELD.size.x / 2.0 * (1.0 if side == 0 else -1.0)
	ball.x = edge_x
	for i in BITS:
		var a := randf() * TAU
		_bit_at[i] = Vector2(edge_x, ball.y)
		_bit_v[i] = Vector2(cos(a) * 0.5 - signf(edge_x) * 0.7, sin(a)) * randf_range(120.0, 300.0)
		_bit_t[i] = BIT_LIFE
	_mood[side] = 0.6
	_mood[1 - side] = -0.6
	Sound.play("bounce", -3.0, 0.7)
	finish(side)


func _process(delta: float) -> void:
	for side in 2:
		_squash[side] = maxf(_squash[side] - delta, 0.0)
		_mood[side] = move_toward(_mood[side], 0.0, delta)
	for i in _bit_t.size():
		if _bit_t[i] > 0.0:
			_bit_t[i] -= delta
			_bit_at[i] += _bit_v[i] * delta
	if _scored >= 0 or active:
		queue_redraw()


func _draw() -> void:
	var table := Rect2(TABLE_CENTER - TABLE_SIZE / 2.0, TABLE_SIZE)
	draw_texture_rect(TABLE_TEX, table, false)
	var mid := table.position + FIELD.position + FIELD.size / 2.0
	for side in 2:
		var squash := _squash[side] / SQUASH_TIME
		var hop := 0.0
		var mood := _mood[side]
		if mood > 0.0:
			hop = -sin(mood / 0.6 * PI) * 26.0
		var scale := Vector2(1.0 + 0.35 * squash, 1.0 - 0.18 * squash)
		var rot := 0.0
		if mood < 0.0:
			rot = (0.2 if side == 0 else -0.2) * (-mood / 0.6)
		var at := mid + Vector2(paddle_x(side), paddle_y[side] + hop)
		draw_set_transform(at, rot, scale)
		draw_texture_rect(PADDLE_TEX, Rect2(-PADDLE_SIZE / 2.0, PADDLE_SIZE), false, color_of(side))
	draw_set_transform(mid + ball, _spin, Vector2.ONE)
	draw_texture_rect(BALL_TEX, Rect2(Vector2.ONE * -BALL_RADIUS * 1.15, Vector2.ONE * BALL_RADIUS * 2.3), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in _bit_t.size():
		if _bit_t[i] > 0.0:
			var k := _bit_t[i] / BIT_LIFE
			var c := PAPER
			c.a = minf(1.0, k * 2.0)
			draw_set_transform(mid + _bit_at[i], _bit_v[i].x * 0.01 + i, Vector2.ONE * (0.5 + k * 0.5))
			draw_rect(Rect2(-5.0, -3.0, 10.0, 6.0), c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
