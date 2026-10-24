class_name ProgressTrack
extends Node2D
## A slim paper track under the HUD's portraits: the whole road from the start to the gate, with a
## dot in each monster's color for how far along it is. The dots follow the pieces on the board, and
## the active player's dot is a little bigger. The origin is the track's middle.

const LENGTH := 800.0
const THICKNESS := 20.0
const DOT := 9.0 # a dot's radius
const ACTIVE_DOT := 12.0
const INK := Color("1a1022")
const PAPER := Color("f4e7c8")
const FOLLOW := 12.0 # how quickly a dot closes the gap to its piece, a second

var _pieces := {} # monster id -> the piece it follows
var _colors := {} # monster id -> its color
var _order: Array[String] = []
var _at := {} # monster id -> its dot's fraction of the road, 0 to 1
var _active := ""
var _start_x := 0.0
var _gate_x := 1.0


func _ready() -> void:
	_start_x = BoardPath.start().pos.x
	_gate_x = BoardPath.finish().pos.x


## The dots follow these pieces (monster id -> piece), in this order of players.
func follow(players: Array, pieces: Dictionary) -> void:
	for player in players:
		var id: String = player.monster
		_order.append(id)
		_pieces[id] = pieces[id]
		_colors[id] = Monsters.color(id)
		_at[id] = _fraction(pieces[id])
	queue_redraw()


func set_active(id: String) -> void:
	_active = id
	queue_redraw()


func _process(delta: float) -> void:
	var blend := 1.0 - exp(-FOLLOW * delta)
	for id in _order:
		_at[id] = lerpf(_at[id], _fraction(_pieces[id]), blend)
	queue_redraw()


func _fraction(piece: Node2D) -> float:
	return clampf(inverse_lerp(_start_x, _gate_x, piece.position.x), 0.0, 1.0)


func _draw() -> void:
	var half := LENGTH / 2.0
	var box := StyleBoxFlat.new()
	box.bg_color = Color(INK, 0.9)
	box.border_color = Color(PAPER, 0.8)
	box.set_border_width_all(2)
	box.set_corner_radius_all(int(THICKNESS / 2.0))
	draw_style_box(box, Rect2(-half - 14.0, -THICKNESS / 2.0, LENGTH + 28.0, THICKNESS))
	# The active player's dot is drawn last, over the rest.
	var drawn := _order.duplicate()
	if _active in drawn:
		drawn.erase(_active)
		drawn.append(_active)
	for id: String in drawn:
		var radius := ACTIVE_DOT if id == _active else DOT
		# Dots on the same spot stand a little apart, up and down, so every one shows.
		var at := Vector2(lerpf(-half, half, _at[id]), (_order.find(id) % 3 - 1) * 7.0)
		draw_circle(at, radius + 2.5, PAPER)
		draw_circle(at, radius, _colors[id])
