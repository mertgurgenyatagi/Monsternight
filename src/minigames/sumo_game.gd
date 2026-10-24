class_name SumoGame
extends Minigame
## Sumo on a paper table, seen from above: two round pieces on a round ring, pushed with the arrow keys
## (an acceleration, with friction and a speed cap). A piece whose centre leaves the ring falls and loses;
## both falling in the same physics frame is a draw. Mr. Hyde's edge makes the challenger's piece
## `1 + edge` times as heavy. The challenger is on the left.

const RING_TEX := preload("res://assets/art/minigames/sumo_ring.png")
const PIECE_TEX := preload("res://assets/art/board/space.png")
const INK := Color("2a1a22")
const TABLE := Color("5b3a52")
const PAPER := Color("fbe9d0")

const RING_RADIUS := 290.0
const PIECE_RADIUS := 52.0
const START_X := 170.0
const ACCEL := 1500.0
const FRICTION := 2.4 # per second
const MAX_SPEED := 520.0
const RESTITUTION := 0.7
const BITS := 14
const BIT_LIFE := 0.5
const FALL_TIME := 0.7

var pos: Array[Vector2] = [Vector2(-START_X, 0.0), Vector2(START_X, 0.0)]
var vel: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
## Whether each piece has gone over the edge.
var fallen: Array[bool] = [false, false]

var _fall_t: Array[float] = [0.0, 0.0]
var _squash: Array[float] = [0.0, 0.0]
var _squash_dir: Array[Vector2] = [Vector2.RIGHT, Vector2.LEFT]
var _jiggle := Vector2.ZERO
var _jiggle_v := 0.0
var _hop: Array[float] = [0.0, 0.0]
var _bit_at: Array[Vector2] = []
var _bit_v: Array[Vector2] = []
var _bit_t: Array[float] = []
var _next_bit := 0
var _bump_at := -100


func setup(left: Dictionary, right: Dictionary, challenger: int, edge_value: float) -> void:
	super(left, right, challenger, edge_value)
	for i in BITS:
		_bit_at.append(Vector2.ZERO)
		_bit_v.append(Vector2.ZERO)
		_bit_t.append(0.0)


func controls() -> Array:
	return [[["up", "left", "down", "right"], "KEYS_MOVE"]]


func mass_of(side: int) -> float:
	return 1.0 + (edge if side == challenger_side else 0.0)


func _physics_process(delta: float) -> void:
	if active:
		step(delta)


## One physics step, split so that no piece moves more than half its radius at once.
func step(delta: float) -> void:
	var fastest := MAX_SPEED
	for side in 2:
		fastest = maxf(fastest, vel[side].length())
	var subs := maxi(1, ceili(fastest * delta / (PIECE_RADIUS * 0.5)))
	var h := delta / subs
	var accel: Array[Vector2] = [MinigameInput.direction(0) * ACCEL, MinigameInput.direction(1) * ACCEL]
	for s in subs:
		for side in 2:
			vel[side] = (vel[side] + accel[side] * h) * exp(-FRICTION * h)
			vel[side] = vel[side].limit_length(MAX_SPEED * 1.6)
			pos[side] += vel[side] * h
		var hit := CirclePhysics.collide(pos[0], vel[0], PIECE_RADIUS, mass_of(0),
				pos[1], vel[1], PIECE_RADIUS, mass_of(1), RESTITUTION)
		vel[0] = hit[0]
		vel[1] = hit[1]
		pos[0] = hit[2]
		pos[1] = hit[3]
		if hit[4] > 0.0:
			_bump(hit[4], hit[5])
	# input pushes up to MAX_SPEED; only a shove may exceed it, and friction brings it back
	for side in 2:
		if vel[side].length() > MAX_SPEED and accel[side] != Vector2.ZERO:
			vel[side] = vel[side].move_toward(vel[side].normalized() * MAX_SPEED, 1200.0 * delta)
		fallen[side] = pos[side].length() > RING_RADIUS
	if fallen[0] and fallen[1]:
		_start_fall(0)
		_start_fall(1)
		finish(DRAW)
	elif fallen[0] or fallen[1]:
		var lost := 0 if fallen[0] else 1
		_start_fall(lost)
		_hop[1 - lost] = 1.0
		finish(1 - lost)


func _start_fall(side: int) -> void:
	_fall_t[side] = FALL_TIME
	Sound.play("bounce", -2.0, 0.6)


func _bump(closing: float, at: Vector2) -> void:
	var dir := (pos[1] - pos[0]).normalized()
	var strength := clampf(closing / 700.0, 0.2, 1.0)
	_squash[0] = strength
	_squash[1] = strength
	_squash_dir[0] = dir
	_squash_dir[1] = -dir
	_jiggle = dir * strength * 3.0
	_jiggle_v = 1.0
	for k in 3:
		var a := randf_range(0.0, TAU)
		_bit_at[_next_bit] = at
		_bit_v[_next_bit] = Vector2.from_angle(a) * randf_range(80.0, 200.0)
		_bit_t[_next_bit] = BIT_LIFE
		_next_bit = (_next_bit + 1) % BITS
	var now := Engine.get_physics_frames()
	if now - _bump_at > 4:
		_bump_at = now
		Sound.play("sumo_bump", linear_to_db(strength) - 2.0, randf_range(0.95, 1.05))


func _process(delta: float) -> void:
	for side in 2:
		_squash[side] = maxf(_squash[side] - delta * 5.0, 0.0)
		_fall_t[side] = maxf(_fall_t[side] - delta, 0.0)
		_hop[side] = maxf(_hop[side] - delta * 2.5, 0.0)
	_jiggle_v = maxf(_jiggle_v - delta * 6.0, 0.0)
	for i in BITS:
		if _bit_t[i] > 0.0:
			_bit_t[i] -= delta
			_bit_at[i] += _bit_v[i] * delta
	queue_redraw()


func _draw() -> void:
	var table := Rect2(TABLE_CENTER - TABLE_SIZE / 2.0, TABLE_SIZE)
	draw_rect(Rect2(table.position + Vector2(8, 10), table.size), Color(0, 0, 0, 0.35))
	draw_rect(table, INK)
	draw_rect(table.grow(-10.0), TABLE)
	var mid := TABLE_CENTER + _jiggle * sin(_jiggle_v * 20.0) * _jiggle_v
	draw_set_transform(mid, 0.0, Vector2.ONE)
	draw_texture_rect(RING_TEX, Rect2(Vector2.ONE * -RING_RADIUS * 1.04, Vector2.ONE * RING_RADIUS * 2.08), false)
	for side in 2:
		var gone := _fall_t[side] <= 0.0 and fallen[side]
		if gone:
			continue
		var k := _fall_t[side] / FALL_TIME if fallen[side] else 1.0
		var speed := vel[side].length()
		# shadow stretches with speed
		draw_set_transform(mid + pos[side] + Vector2(6, 12) * k, 0.0, Vector2(1.0 + speed / 1500.0, 0.55))
		draw_circle(Vector2.ZERO, PIECE_RADIUS * k, Color(0, 0, 0, 0.3 * k))
		# the piece tilts into its move, squashes along the impact line, shrinks and spins when it falls
		var squash := _squash[side]
		var along := _squash_dir[side]
		var tilt := clampf(vel[side].x / MAX_SPEED, -1.0, 1.0) * 0.15 + (1.0 - k) * 6.0
		var lift := -sin(_hop[side] * PI) * 26.0
		var flat := Vector2(1.0 - 0.25 * squash, 1.0 + 0.2 * squash) if absf(along.x) > absf(along.y) 				else Vector2(1.0 + 0.2 * squash, 1.0 - 0.25 * squash)
		draw_set_transform(mid + pos[side] + Vector2(0, lift), tilt, flat * k)
		var d := PIECE_RADIUS * 2.0
		draw_texture_rect(PIECE_TEX, Rect2(Vector2(-d, -d * 0.6), Vector2(d * 2.0, d * 1.2)), false, color_of(side))
		draw_texture_rect(Monsters.portrait(players[side].monster),
				Rect2(Vector2(-PIECE_RADIUS, -PIECE_RADIUS * 1.5), Vector2(PIECE_RADIUS * 2.0, PIECE_RADIUS * 2.0)), false)
	for i in BITS:
		if _bit_t[i] > 0.0:
			var f := _bit_t[i] / BIT_LIFE
			var c := PAPER
			c.a = minf(1.0, f * 2.0)
			draw_set_transform(mid + _bit_at[i], _bit_v[i].x * 0.01 + i, Vector2.ONE * (0.5 + f * 0.5))
			draw_rect(Rect2(-5.0, -3.0, 10.0, 6.0), c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
