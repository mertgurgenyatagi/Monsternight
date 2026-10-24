class_name SoccerGame
extends Minigame
## Head Soccer on a paper table, seen from the side: two big heads with little boots, a goal at each end
## and a bouncy pumpkin ball. Left and right run, up jumps, down kicks, so one hand plays it. The ball
## going under a crossbar and past a goal line wins for the other side, never a draw. Mr. Hyde's edge
## makes the challenger's head run `1 + edge` times as fast. The challenger is on the left. Positions are
## in the table's own space, with the origin in the middle of the table and y growing downward.

const GOAL_TEX := preload("res://assets/art/minigames/goal.png")
const BALL_TEX := preload("res://assets/art/minigames/ball.png")
const BOOT_TEX := preload("res://assets/art/minigames/boot.png")
const INK := Color("2a1a22")
const SKY := Color("2a2147")
const GROUND_COLOR := Color("5b3a52")
const PAPER := Color("fbe9d0")

const HALF_W := 740.0
const GROUND := 250.0 # where the boots and the ball stand
const HEAD_R := 62.0
const BOOT_SIZE := Vector2(46.0, 29.0)
const HEAD_FLOOR := GROUND - BOOT_SIZE.y * 0.7 - HEAD_R # the head's centre when standing
const BALL_R := 36.0
const GOAL_SIZE := Vector2(187.0, 280.0)
const GOAL_LINE := HALF_W - GOAL_SIZE.x - 17.0 # the post's middle, from the middle
const CROSS_TOP := GROUND - GOAL_SIZE.y
const CROSS_BOTTOM := CROSS_TOP + 28.0
const CEILING := -320.0

const GRAVITY_BALL := 1500.0
const GRAVITY_HEAD := 2600.0
const RUN := 430.0
const RUN_ACCEL := 4200.0
const JUMP := 1000.0
const HEAD_MASS := 5.0
const BALL_RESTITUTION := 0.85
const FLOOR_BOUNCE := 0.72
const WALL_BOUNCE := 0.8
const AIR_DRAG := 0.12
const ROLL_DRAG := 0.7
const MAX_BALL := 1500.0
const KICK_TIME := 0.15
const KICK_COOLDOWN := 0.4
const KICK_SPEED := 1050.0
const KICK_REACH := 50.0
const HOLD_TIME := 0.4
const STALL_TIME := 5.0
const START_X := 300.0
const BITS := 28
const BIT_LIFE := 0.55
const STARS := [Vector2(-600, -250), Vector2(-420, -160), Vector2(-200, -280), Vector2(120, -190),
		Vector2(330, -290), Vector2(540, -200), Vector2(660, -280), Vector2(-90, -60), Vector2(450, -90)]

var head: Array[Vector2] = [Vector2(-START_X, HEAD_FLOOR), Vector2(START_X, HEAD_FLOOR)]
var head_vel: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var ball := Vector2(0.0, -120.0)
var ball_vel := Vector2.ZERO
## The side that scored, or -1.
var scored := -1

var _hold := HOLD_TIME
var _rest := 0.0
var _spin := 0.0
var _ball_squash := 0.0
var _ball_squash_dir := Vector2.RIGHT
var _squash: Array[float] = [0.0, 0.0]
var _kick_t: Array[float] = [0.0, 0.0]
var _kick_cd: Array[float] = [0.0, 0.0]
var _kick_hit: Array[bool] = [false, false]
var _run_phase: Array[float] = [0.0, 0.0]
var _hop: Array[float] = [0.0, 0.0]
var _net: Array[float] = [0.0, 0.0] # jiggle of the goal at each end
var _clock := 0.0
var _sound_at := {}
var _bit_at: Array[Vector2] = []
var _bit_v: Array[Vector2] = []
var _bit_t: Array[float] = []
var _next_bit := 0


func setup(left: Dictionary, right: Dictionary, challenger: int, edge_value: float) -> void:
	super(left, right, challenger, edge_value)
	for i in BITS:
		_bit_at.append(Vector2.ZERO)
		_bit_v.append(Vector2.ZERO)
		_bit_t.append(0.0)


func controls() -> Array:
	return [[["left", "right"], "KEYS_RUN"], [["up"], "KEYS_JUMP"], [["down"], "KEYS_KICK"]]


func face_of(side: int) -> float:
	return 1.0 if side == 0 else -1.0


func run_speed(side: int) -> float:
	return RUN * (1.0 + (edge if side == challenger_side else 0.0))


func on_ground(side: int) -> bool:
	return head[side].y >= HEAD_FLOOR - 0.5


func _physics_process(delta: float) -> void:
	if active or scored >= 0:
		step(delta)


func stepping() -> bool:
	return active or scored >= 0


func get_state() -> Dictionary:
	return {"head": Minigame.pack_all(head), "head_vel": Minigame.pack_all(head_vel),
			"ball": Minigame.pack(ball), "ball_vel": Minigame.pack(ball_vel), "scored": scored,
			"hold": _hold, "rest": _rest, "kick_t": _kick_t.duplicate(), "kick_cd": _kick_cd.duplicate(),
			"kick_hit": _kick_hit.duplicate()}


func set_state(d: Dictionary) -> void:
	Minigame.unpack_into(head, d.head)
	Minigame.unpack_into(head_vel, d.head_vel)
	ball = Minigame.unpack(d.ball)
	ball_vel = Minigame.unpack(d.ball_vel)
	scored = int(d.scored)
	_hold = float(d.hold)
	_rest = float(d.rest)
	for i in 2:
		_kick_t[i] = float(d.kick_t[i])
		_kick_cd[i] = float(d.kick_cd[i])
		_kick_hit[i] = bool(d.kick_hit[i])


func blend_pairs() -> Array:
	return [["head", "head_vel"], ["ball", "ball_vel"]]


## One physics step. After a goal only the ball keeps moving.
func step(delta: float) -> void:
	if scored < 0:
		_hold = maxf(_hold - delta, 0.0)
		for side in 2:
			_kick_cd[side] = maxf(_kick_cd[side] - delta, 0.0)
			_kick_t[side] = maxf(_kick_t[side] - delta, 0.0)
			if MinigameInput.pressed(side, "down") and _kick_cd[side] <= 0.0:
				_kick_cd[side] = KICK_COOLDOWN
				_kick_t[side] = KICK_TIME
				_kick_hit[side] = false
	var fastest := maxf(ball_vel.length(), RUN)
	var subs := maxi(1, ceili(fastest * delta / (BALL_R * 0.5)))
	var h := delta / subs
	for s in subs:
		if scored < 0:
			_step_heads(h)
		if _hold <= 0.0 or scored >= 0:
			_step_ball(h)
		if scored < 0:
			_contacts()
			_check_goal()
	if scored < 0:
		var resting := ball.y >= GROUND - BALL_R - 1.0 and ball_vel.length() < 40.0
		_rest = _rest + delta if resting else 0.0
		if _rest >= STALL_TIME:
			_reserve()


func _step_heads(h: float) -> void:
	for side in 2:
		var target := MinigameInput.direction(side).x * run_speed(side)
		var v := head_vel[side]
		v.x = move_toward(v.x, target, RUN_ACCEL * h)
		v.y += GRAVITY_HEAD * h
		if MinigameInput.pressed(side, "up") and on_ground(side):
			v.y = -JUMP
			_squash[side] = -0.5
			_play("jump", -4.0, randf_range(0.95, 1.05))
		var p := head[side] + v * h
		if p.y >= HEAD_FLOOR:
			if v.y > 300.0:
				_squash[side] = clampf(v.y / 1400.0, 0.2, 0.7)
			p.y = HEAD_FLOOR
			v.y = 0.0
		var lo := -HALF_W + HEAD_R
		var hi := HALF_W - HEAD_R
		if side == 0:
			hi = 80.0
		else:
			lo = -80.0
		if p.x < lo or p.x > hi:
			p.x = clampf(p.x, lo, hi)
			v.x = 0.0
		head[side] = p
		head_vel[side] = v
		if on_ground(side):
			_run_phase[side] += absf(v.x) * h * 0.03
		if _kick_t[side] > 0.0 and not _kick_hit[side]:
			_try_kick(side)


func _foot(side: int) -> Vector2:
	return head[side] + Vector2(face_of(side) * 52.0, HEAD_R + 2.0)


func _try_kick(side: int) -> void:
	var foot := _foot(side)
	if _hold > 0.0 or foot.distance_to(ball) > KICK_REACH + BALL_R:
		return
	_kick_hit[side] = true
	var away := (ball - foot).normalized()
	var aim := Vector2(face_of(side) * 0.9, -0.55).normalized()
	var dir := (aim * 0.6 + away * 0.4).normalized()
	ball_vel = (dir * KICK_SPEED + head_vel[side] * 0.5).limit_length(MAX_BALL)
	_touch(ball - dir * BALL_R, dir, 1.0)
	_play("kick", 0.0, randf_range(0.95, 1.05))


func _step_ball(h: float) -> void:
	ball_vel.y += GRAVITY_BALL * h
	ball_vel *= exp(-AIR_DRAG * h)
	ball_vel = ball_vel.limit_length(MAX_BALL)
	ball += ball_vel * h
	_spin += ball_vel.x / BALL_R * h
	if ball.y > GROUND - BALL_R:
		ball.y = GROUND - BALL_R
		if ball_vel.y > 140.0:
			var s := clampf(ball_vel.y / 1200.0, 0.2, 1.0)
			ball_vel.y *= -FLOOR_BOUNCE
			_ball_squash = s
			_ball_squash_dir = Vector2.DOWN
			_play("bounce", linear_to_db(s) - 3.0, 0.8 + s * 0.5)
		elif ball_vel.y >= 0.0:
			ball_vel.y = 0.0
			ball_vel.x *= exp(-ROLL_DRAG * h)
	if ball.y < CEILING + BALL_R:
		ball.y = CEILING + BALL_R
		ball_vel.y = absf(ball_vel.y) * 0.6
	for side in 2:
		var bar := Rect2(Vector2(-HALF_W if side == 0 else GOAL_LINE, CROSS_TOP),
				Vector2(HALF_W - GOAL_LINE, CROSS_BOTTOM - CROSS_TOP))
		var hit := CirclePhysics.bounce_off_box(ball, ball_vel, BALL_R, bar, WALL_BOUNCE)
		ball_vel = hit[0]
		ball = hit[1]
		if hit[2] > 200.0:
			var s := clampf(hit[2] / 1000.0, 0.2, 1.0)
			_ball_squash = s
			_ball_squash_dir = Vector2.UP
			_play("bounce", linear_to_db(s) - 3.0, 1.0 + s * 0.3)
	if absf(ball.x) > HALF_W - BALL_R:
		var out := signf(ball.x)
		ball.x = out * (HALF_W - BALL_R)
		if ball_vel.x * out > 0.0:
			if ball.y > CROSS_BOTTOM:
				_net[0 if out < 0.0 else 1] = clampf(absf(ball_vel.x) / 800.0, 0.3, 1.0)
			ball_vel.x *= -WALL_BOUNCE
			_ball_squash = 0.4
			_ball_squash_dir = Vector2.RIGHT


## Head against ball, and head against head.
func _contacts() -> void:
	for side in 2:
		if _hold > 0.0:
			break
		var hit := CirclePhysics.collide(head[side], head_vel[side], HEAD_R, HEAD_MASS,
				ball, ball_vel, BALL_R, 1.0, BALL_RESTITUTION)
		head_vel[side] = hit[0]
		ball_vel = (hit[1] as Vector2).limit_length(MAX_BALL)
		head[side] = hit[2]
		ball = hit[3]
		if hit[4] > 120.0:
			var s := clampf(hit[4] / 900.0, 0.2, 1.0)
			_squash[side] = maxf(_squash[side], s * 0.6)
			_touch(hit[5], (ball - head[side]).normalized(), s)
			_play("bounce", linear_to_db(s) - 2.0, 1.0 + s * 0.3)
		head[side].y = minf(head[side].y, HEAD_FLOOR)
	var hh := CirclePhysics.collide(head[0], head_vel[0], HEAD_R, HEAD_MASS,
			head[1], head_vel[1], HEAD_R, HEAD_MASS, 0.1)
	head_vel[0] = hh[0]
	head_vel[1] = hh[1]
	head[0] = hh[2]
	head[1] = hh[3]
	for side in 2:
		head[side].y = minf(head[side].y, HEAD_FLOOR)


func _touch(at: Vector2, dir: Vector2, strength: float) -> void:
	_ball_squash = maxf(_ball_squash, strength)
	_ball_squash_dir = dir
	for k in 4:
		_bit_at[_next_bit] = at
		_bit_v[_next_bit] = Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(90.0, 230.0)
		_bit_t[_next_bit] = BIT_LIFE
		_next_bit = (_next_bit + 1) % BITS


func _check_goal() -> void:
	if ball.y < CROSS_BOTTOM:
		return
	if ball.x < -GOAL_LINE:
		_goal(1)
	elif ball.x > GOAL_LINE:
		_goal(0)


func _goal(winner: int) -> void:
	scored = winner
	_net[1 - winner] = 1.0
	_hop[winner] = 1.0
	var out := 1.0 if winner == 0 else -1.0
	for k in 12:
		_bit_at[_next_bit] = Vector2(GOAL_LINE * out, GROUND - 120.0 + randf_range(-90.0, 90.0))
		_bit_v[_next_bit] = Vector2(randf_range(-60.0, 240.0) * out, randf_range(-220.0, 60.0))
		_bit_t[_next_bit] = BIT_LIFE * 1.5
		_next_bit = (_next_bit + 1) % BITS
	finish(winner)


## A stalled ball is dropped again from the middle with a hop.
func _reserve() -> void:
	ball = Vector2(0.0, -40.0)
	ball_vel = Vector2(0.0, -500.0)
	_rest = 0.0
	_ball_squash = 0.0


func _play(sound: String, db: float, pitch: float) -> void:
	var now := Engine.get_physics_frames()
	if now - int(_sound_at.get(sound, -100)) <= 4:
		return
	_sound_at[sound] = now
	Sound.play(sound, db, pitch)


func _process(delta: float) -> void:
	_clock += delta
	_ball_squash = maxf(_ball_squash - delta * 5.0, 0.0)
	for side in 2:
		_squash[side] = move_toward(_squash[side], 0.0, delta * 4.0)
		_hop[side] = maxf(_hop[side] - delta * 2.0, 0.0)
		_net[side] = maxf(_net[side] - delta * 1.6, 0.0)
	for i in BITS:
		if _bit_t[i] > 0.0:
			_bit_t[i] -= delta
			_bit_at[i] += _bit_v[i] * delta
			_bit_v[i].y += 500.0 * delta
	queue_redraw()


func _draw() -> void:
	var table := Rect2(TABLE_CENTER - TABLE_SIZE / 2.0, TABLE_SIZE)
	draw_rect(Rect2(table.position + Vector2(8, 10), table.size), Color(0, 0, 0, 0.35))
	draw_rect(table, INK)
	draw_rect(table.grow(-10.0), SKY)
	draw_set_transform(TABLE_CENTER, 0.0, Vector2.ONE)
	for i in STARS.size():
		var twinkle := 0.55 + 0.45 * sin(_clock * 1.6 + i * 2.1)
		draw_circle(STARS[i], 3.0, Color(PAPER, twinkle))
	draw_circle(Vector2(-250, -215), 46.0, PAPER)
	draw_circle(Vector2(-232, -226), 40.0, SKY)
	draw_rect(Rect2(-HALF_W + 10.0, GROUND, TABLE_SIZE.x - 20.0, -CEILING - GROUND - 10.0), GROUND_COLOR)
	draw_rect(Rect2(-HALF_W + 10.0, GROUND - 3.0, TABLE_SIZE.x - 20.0, 6.0), PAPER)
	# the picture faces right, so the right-hand goal is mirrored, and each shakes from its post
	for side in 2:
		var jiggle := 1.0 + 0.09 * _net[side] * sin(_clock * 34.0)
		var post_x := -(HALF_W - GOAL_SIZE.x) if side == 0 else HALF_W - GOAL_SIZE.x
		var flip := 1.0 if side == 0 else -1.0
		draw_set_transform(TABLE_CENTER + Vector2(post_x, 0.0), 0.0, Vector2(flip * jiggle, 1.0))
		draw_texture_rect(GOAL_TEX, Rect2(-GOAL_SIZE.x, CROSS_TOP, GOAL_SIZE.x, GOAL_SIZE.y), false)
	for side in 2:
		_draw_head(side)
	_draw_ball()
	for i in BITS:
		if _bit_t[i] > 0.0:
			var f := _bit_t[i] / BIT_LIFE
			draw_set_transform(TABLE_CENTER + _bit_at[i], _bit_v[i].x * 0.01 + i, Vector2.ONE * (0.5 + minf(f, 1.0) * 0.5))
			draw_rect(Rect2(-5.0, -3.0, 10.0, 6.0), Color(PAPER, minf(1.0, f * 2.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_shadow(x: float, height: float, radius: float) -> void:
	var k := 1.0 - clampf(height / 320.0, 0.0, 0.65)
	draw_set_transform(TABLE_CENTER + Vector2(x, GROUND + 6.0), 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, radius * k, Color(0, 0, 0, 0.35 * k))


func _draw_head(side: int) -> void:
	var face := face_of(side)
	var p := head[side]
	_draw_shadow(p.x, HEAD_FLOOR - p.y, HEAD_R)
	var lost := scored == 1 - side
	var lift := -sin(_hop[side] * PI) * 40.0 if scored == side else 0.0
	var sink := 14.0 if lost else 0.0
	var sq := _squash[side]
	var air := clampf(-head_vel[side].y / 3500.0, -0.2, 0.2)
	var squash := Vector2(1.0 + 0.25 * sq - air, 1.0 - 0.25 * sq + air)
	var tilt := clampf(head_vel[side].x / RUN, -1.0, 1.0) * 0.12 + (-0.18 * face if lost else 0.0)
	# boots swing with the run, and the front one flings on a kick
	var kick := 0.0
	if _kick_t[side] > 0.0:
		kick = sin((1.0 - _kick_t[side] / KICK_TIME) * PI)
	for i in 2:
		var swing := sin(_run_phase[side] * PI + i * PI) * 9.0
		var base := TABLE_CENTER + p + Vector2((-22.0 + 44.0 * i) * face + swing * face,
				HEAD_R + BOOT_SIZE.y * 0.2 + lift * 0.0)
		var angle := 0.0
		if i == 1:
			base += Vector2(kick * 26.0 * face, -kick * 8.0)
			angle = -kick * 1.1 * face
		elif not on_ground(side):
			angle = 0.25 * face
		draw_set_transform(base, angle, Vector2(face, 1.0))
		draw_texture_rect(BOOT_TEX, Rect2(-BOOT_SIZE.x / 2.0, -BOOT_SIZE.y / 2.0, BOOT_SIZE.x, BOOT_SIZE.y),
				false, color_of(side))
	draw_set_transform(TABLE_CENTER + p + Vector2(0.0, lift + sink), tilt, squash)
	var d := HEAD_R * 2.2
	draw_texture_rect(Monsters.portrait(players[side].monster), Rect2(-d / 2.0, -d / 2.0, d, d), false)


func _draw_ball() -> void:
	_draw_shadow(ball.x, GROUND - BALL_R - ball.y, BALL_R)
	var a := _ball_squash_dir.angle()
	var t := Transform2D(a, TABLE_CENTER + ball)
	t = t.scaled_local(Vector2(1.0 - 0.3 * _ball_squash, 1.0 + 0.25 * _ball_squash))
	t = t.rotated_local(_spin - a)
	draw_set_transform_matrix(t)
	draw_texture_rect(BALL_TEX, Rect2(-BALL_R, -BALL_R, BALL_R * 2.0, BALL_R * 2.0), false)
