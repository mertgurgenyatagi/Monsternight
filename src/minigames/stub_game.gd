class_name StubGame
extends Minigame
## A throwaway game to prove the frame end to end: two paper squares on a table, one flag in the middle,
## and whoever touches it first wins. Parts 34 to 37 replace it kind by kind.

const SPEED := 520.0
const SQUARE := 70.0
const FLAG_RADIUS := 46.0
const INK := Color("2a1a22")
const TABLE := Color("5b3a52")

var _at: Array[Vector2] = []
var _flag := Vector2.ZERO


func setup(left: Dictionary, right: Dictionary, challenger: int, edge_value: float) -> void:
	super(left, right, challenger, edge_value)
	_at = [TABLE_CENTER + Vector2(-TABLE_SIZE.x / 2.0 + 120.0, 0), TABLE_CENTER + Vector2(TABLE_SIZE.x / 2.0 - 120.0, 0)]
	_flag = TABLE_CENTER + Vector2(0, -140)


func controls() -> Array:
	return [[["up", "left", "down", "right"], "KEYS_MOVE"]]


func _physics_process(delta: float) -> void:
	if not active:
		return
	for side in 2:
		_at[side] += MinigameInput.direction(side) * SPEED * delta
		_at[side] = _at[side].clamp(TABLE_CENTER - TABLE_SIZE / 2.0, TABLE_CENTER + TABLE_SIZE / 2.0)
	queue_redraw()
	var hit: Array[int] = []
	for side in 2:
		if _at[side].distance_to(_flag) < FLAG_RADIUS + SQUARE / 2.0:
			hit.append(side)
	if hit.size() == 2:
		finish(DRAW)
	elif hit.size() == 1:
		finish(hit[0])


func _draw() -> void:
	var rect := Rect2(TABLE_CENTER - TABLE_SIZE / 2.0, TABLE_SIZE)
	draw_rect(Rect2(rect.position + Vector2(8, 10), rect.size), Color(0, 0, 0, 0.35))
	draw_rect(rect, INK)
	draw_rect(rect.grow(-10.0), TABLE)
	# the flag: a pole and a cream triangle
	draw_line(_flag + Vector2(0, 40), _flag + Vector2(0, -50), INK, 8.0)
	draw_colored_polygon(PackedVector2Array([_flag + Vector2(0, -50), _flag + Vector2(54, -30), _flag + Vector2(0, -10)]),
			Color("fbe9d0"))
	for side in 2:
		if _at.size() == 2:
			var box := Rect2(_at[side] - Vector2.ONE * SQUARE / 2.0, Vector2.ONE * SQUARE)
			draw_rect(box.grow(6.0), INK)
			draw_rect(box, color_of(side))
