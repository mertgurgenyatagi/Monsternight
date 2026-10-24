class_name DuelTally
extends Node2D
## The swap handicap's tally under the VS: three round pips for the challenger and one for the
## opponent, each an empty paper disc that fills with its monster's color when that round is won.
## Its origin is the middle of the row.

const PIP_RADIUS := 24.0
const PIP_GAP := 62.0
const SIDE_GAP := 28.0 # extra room between the challenger's pips and the opponent's
const INK := Color("2a1a22")
const CREAM := Color("fbe9d0")

var _pips: Array[Array] = [[], []] # [the challenger's, the opponent's]
var _filled: Array[int] = [0, 0]


## `challenger_pips` and `opponent_pips` discs, which fill in the two monsters' `colors`.
func _init(challenger_pips := 3, opponent_pips := 1, colors: Array[Color] = []) -> void:
	var counts := [challenger_pips, opponent_pips]
	var total := challenger_pips + opponent_pips
	var index := 0
	for side in 2:
		for i in counts[side]:
			var pip := Pip.new()
			pip.color = colors[side]
			var x := (index - (total - 1) / 2.0) * PIP_GAP + (SIDE_GAP / 2.0 if side == 1 else -SIDE_GAP / 2.0)
			pip.position = Vector2(x, 0)
			add_child(pip)
			_pips[side].append(pip)
			index += 1


## The pips drop in one after the other.
func come_in() -> void:
	var delay := 0.0
	for side in 2:
		for pip in _pips[side]:
			PaperMotion.pop_in(pip, delay)
			delay += 0.12


## `side` (0 the challenger, 1 the opponent) took a round: its next empty pip fills.
func fill(side: int) -> void:
	var pip: Pip = _pips[side][_filled[side]]
	_filled[side] += 1
	pip.filled = true
	pip.queue_redraw()
	PaperMotion.squash(pip)


class Pip extends Node2D:
	var color := Color.WHITE
	var filled := false

	func _draw() -> void:
		draw_circle(Vector2(2, 3), PIP_RADIUS, Color(0, 0, 0, 0.35))
		draw_circle(Vector2.ZERO, PIP_RADIUS, INK)
		draw_circle(Vector2.ZERO, PIP_RADIUS - 5.0, color if filled else CREAM)
