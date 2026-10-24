class_name TugGame
extends Minigame
## Tug of War on a paper table: a rope with a ribbon marker, one key per side. Each press pulls the marker
## a step towards that side, it creeps back to the middle, and the first time it passes a side's line that
## side wins. The challenger is on the left. Two presses in the same physics frame cancel. Mr. Hyde's edge
## makes each of the challenger's pulls `1 + edge` times as strong. Never a draw.

const ROPE_TEX := preload("res://assets/art/minigames/rope.png")
const RIBBON_TEX := preload("res://assets/art/minigames/ribbon.png")
const HINT_FONT := preload("res://assets/fonts/display.ttf")

const ROPE_LENGTH := 1300.0
const LINE_X := 400.0 # where the lines stand, from the middle
const PULL := 0.07 # of the way to a line, per press
const CREEP := 0.12 # of the way to a line, back to the middle, per second
const PAWN_X := 640.0
const PAWN_SIZE := 230.0
const SLIDE := 90.0
const BITS := 16
const BIT_LIFE := 0.6
const INK := Color("2a1a22")
const TABLE := Color("5b3a52")
const PAPER := Color("fbe9d0")

## The marker, -1 at the left line and 1 at the right line.
var marker := 0.0

var _pulse: Array[float] = [0.0, 0.0] # decays after a press
var _lean: Array[float] = [0.0, 0.0]
var _flash: Array[float] = [0.0, 0.0]
var _wiggle := 0.0
var _speed := 0.0
var _hint := 1.0
var _hint_fading := false
var _voice_at: Array[int] = [-100, -100]
var _bit_at: Array[Vector2] = []
var _bit_v: Array[Vector2] = []
var _bit_t: Array[float] = []
var _next_bit := 0
var _won := -1


func setup(left: Dictionary, right: Dictionary, challenger: int, edge_value: float) -> void:
	super(left, right, challenger, edge_value)
	for i in BITS:
		_bit_at.append(Vector2.ZERO)
		_bit_v.append(Vector2.ZERO)
		_bit_t.append(0.0)


func controls() -> Array:
	return [[["action"], "KEYS_MASH"]]


func pull_of(side: int) -> float:
	return PULL * (1.0 + (edge if side == challenger_side else 0.0))


func _physics_process(delta: float) -> void:
	if active:
		step(delta)


func get_state() -> Dictionary:
	return {"marker": marker, "won": _won}


func set_state(d: Dictionary) -> void:
	marker = float(d.marker)
	_won = int(d.won)


func blend_keys() -> Array:
	return ["marker"]


func snap_distance() -> float:
	return 0.25 # the marker runs from -1 to 1


## One physics step: the presses, the creep back, the crossing.
func step(delta: float) -> void:
	var pressed: Array[bool] = [MinigameInput.just_pressed(0, "action"), MinigameInput.just_pressed(1, "action")]
	var before := marker
	if pressed[0] != pressed[1]:
		var side := 0 if pressed[0] else 1
		marker += pull_of(side) * (-1.0 if side == 0 else 1.0)
		_pulse[side] = 1.0
		_lean[side] = 1.0
		_hint_fading = true
		_puff(side)
		var now := Engine.get_physics_frames()
		if now - _voice_at[side] > 4:
			_voice_at[side] = now
			Sound.play("rope_pull", -4.0, randf_range(0.9, 1.1))
	marker = move_toward(marker, 0.0, CREEP * delta)
	_speed = (marker - before) / maxf(delta, 0.0001)
	if absf(marker) >= 1.0:
		var side := 0 if marker < 0.0 else 1
		marker = signf(marker)
		_flash[side] = 0.5
		_won = side
		finish(side)


func _puff(side: int) -> void:
	var foot := Vector2((-1.0 if side == 0 else 1.0) * PAWN_X, 150.0) + Vector2(marker * SLIDE, 0.0)
	for k in 3:
		var a := randf_range(-0.9, 0.9)
		var away := -1.0 if side == 0 else 1.0
		_bit_at[_next_bit] = foot
		_bit_v[_next_bit] = Vector2(cos(a) * away, -absf(sin(a)) - 0.2) * randf_range(90.0, 220.0)
		_bit_t[_next_bit] = BIT_LIFE
		_next_bit = (_next_bit + 1) % BITS


func _process(delta: float) -> void:
	for side in 2:
		_pulse[side] = maxf(_pulse[side] - delta * 7.0, 0.0)
		_lean[side] = move_toward(_lean[side], 0.0, delta * 5.0)
		_flash[side] = maxf(_flash[side] - delta, 0.0)
	if _hint_fading:
		_hint = maxf(_hint - delta * 2.0, 0.0)
	_wiggle += delta * (8.0 + minf(absf(_speed), 4.0) * 8.0)
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
	var mid := TABLE_CENTER + Vector2(0, 40)
	# the two lines: a pole with a cut-paper flag in the side's color
	for side in 2:
		var dir := -1.0 if side == 0 else 1.0
		var tilt := sin(_flash[side] / 0.5 * PI * 3.0) * 0.35 * (_flash[side] / 0.5)
		draw_set_transform(mid + Vector2(dir * LINE_X, 0.0), tilt, Vector2.ONE)
		draw_line(Vector2(0, 90), Vector2(0, -120), INK, 8.0)
		var tip := -dir * 70.0
		draw_colored_polygon(PackedVector2Array([Vector2(0, -120), Vector2(tip, -92), Vector2(0, -64)]), color_of(side))
		draw_polyline(PackedVector2Array([Vector2(0, -120), Vector2(tip, -92), Vector2(0, -64), Vector2(0, -120)]), INK, 4.0)
	# the rope, pulled taut by the latest press
	var taut := 1.0 + 0.03 * maxf(_pulse[0], _pulse[1])
	var x_marker := marker * LINE_X
	draw_set_transform(mid + Vector2(marker * SLIDE * 0.0, 0.0), 0.0, Vector2(taut, 1.0))
	draw_texture_rect(ROPE_TEX, Rect2(Vector2(-ROPE_LENGTH / 2.0, -50.0), Vector2(ROPE_LENGTH, 100.0)), false)
	# the ribbon flutters with the marker's speed and wiggles after a press
	var flutter := sin(_wiggle) * (0.1 + minf(absf(_speed), 4.0) * 0.12) + sin(_wiggle * 0.5) * 0.05 * maxf(_pulse[0], _pulse[1])
	draw_set_transform(mid + Vector2(x_marker, 8.0), flutter, Vector2.ONE)
	draw_texture_rect(RIBBON_TEX, Rect2(Vector2(-70, -70), Vector2(140, 140)), false)
	# the pawns lean back as they pull, and slide with the rope
	for side in 2:
		var dir := -1.0 if side == 0 else 1.0
		var lean := (0.12 + 0.18 * _lean[side]) * (marker * dir * -0.5 + 0.5) * -dir
		var feet := mid + Vector2(dir * PAWN_X + marker * SLIDE, 150.0)
		draw_set_transform(feet, lean, Vector2(1.0 + 0.04 * _pulse[side], 1.0 - 0.04 * _pulse[side]))
		draw_texture_rect(Monsters.portrait(players[side].monster),
				Rect2(Vector2(-PAWN_SIZE / 2.0, -PAWN_SIZE), Vector2.ONE * PAWN_SIZE), false)
		if _hint > 0.0 and _won < 0:
			draw_set_transform(feet, 0.0, Vector2.ONE)
			var text := tr("MASH_HINT") % MinigameInput.label(side, "action")
			draw_string_outline(HINT_FONT, Vector2(-100, -PAWN_SIZE - 20), text, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 34, 8, Color(INK, _hint))
			draw_string(HINT_FONT, Vector2(-100, -PAWN_SIZE - 20), text, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 34, Color(PAPER, _hint))
	# dust at the feet
	for i in BITS:
		if _bit_t[i] > 0.0:
			var k := _bit_t[i] / BIT_LIFE
			var c := PAPER
			c.a = minf(1.0, k * 2.0)
			draw_set_transform(mid + _bit_at[i], _bit_v[i].x * 0.01 + i, Vector2.ONE * (0.5 + k * 0.5))
			draw_rect(Rect2(-5.0, -3.0, 10.0, 6.0), c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
