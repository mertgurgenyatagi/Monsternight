class_name PaperMotion
## The shared paper moves, so every screen moves the same way. They work on any Node2D or
## Control. Add new moves here (hop, flip, crumple), never as one-off tweens in a screen.
##
## A piece's resting scale and position are remembered in its "rest_scale" and
## "rest_position" metadata the first time a move needs them.

const LIFT := 8.0 # how far a hovered piece rises, in pixels


## Falls from `height` pixels above and lands with a little bounce.
static func drop_in(piece: CanvasItem, height := 900.0, duration := 0.9, delay := 0.0) -> Tween:
	var rest := _rest_position(piece)
	piece.position = rest - Vector2(0, height)
	var tween := _fresh(piece, "move")
	tween.tween_property(piece, "position", rest, duration).set_delay(delay) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


## Sets a card down from above: it swings in slightly tilted and lands flat with a small
## bounce. `landed` is called about when it touches the page.
static func set_down(piece: CanvasItem, landed := Callable(), height := 800.0, duration := 0.6) -> Tween:
	var rest := _rest_position(piece)
	_center_pivot(piece)
	piece.position = rest - Vector2(0, height)
	piece.rotation_degrees = -6.0
	var tween := _fresh(piece, "move").set_parallel()
	tween.tween_property(piece, "position", rest, duration) 			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "rotation_degrees", 0.0, duration) 			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if landed.is_valid():
		tween.tween_callback(landed).set_delay(duration * 0.45)
	return tween


## Lifts a card off the page and away upward, the way set_down brought it.
static func lift_away(piece: CanvasItem, height := 800.0, duration := 0.4) -> Tween:
	var rest := _rest_position(piece)
	_center_pivot(piece)
	var tween := _fresh(piece, "move").set_parallel()
	tween.tween_property(piece, "position", rest - Vector2(0, height), duration) 			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(piece, "rotation_degrees", 5.0, duration) 			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	return tween


## Rocks gently from side to side, forever, like something hanging or floating.
static func sway(piece: CanvasItem, degrees := 1.5, period := 4.0) -> Tween:
	var tween := _fresh(piece, "sway").set_loops()
	tween.tween_property(piece, "rotation_degrees", degrees, period / 2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(piece, "rotation_degrees", -degrees, period / 2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween


## Grows from nothing with an overshoot and a small twist.
static func pop_in(piece: CanvasItem, delay := 0.0, duration := 0.45) -> Tween:
	var rest := _rest_scale(piece)
	_center_pivot(piece)
	piece.scale = Vector2.ZERO
	piece.rotation_degrees = -8.0
	var tween := _fresh(piece, "scale").set_parallel()
	tween.tween_property(piece, "scale", rest, duration).set_delay(delay) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "rotation_degrees", 0.0, duration).set_delay(delay) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


## Shrinks away to nothing, the way pop_in came.
static func pop_out(piece: CanvasItem, delay := 0.0, duration := 0.3) -> Tween:
	_center_pivot(piece)
	_kill(piece, "lift")
	var tween := _fresh(piece, "scale").set_parallel()
	tween.tween_property(piece, "scale", Vector2.ZERO, duration).set_delay(delay) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(piece, "rotation_degrees", 8.0, duration).set_delay(delay) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	return tween


## Raises a piece off the page (on hover) or sets it back down. Its shadow falls further away
## while it's raised.
static func lift(piece: CanvasItem, raised: bool) -> Tween:
	var rest_position := _rest_position(piece)
	var rest_scale := _rest_scale(piece)
	_center_pivot(piece)
	_kill(piece, "scale")
	piece.set_meta("raised", raised)
	var height := LIFT if raised else 0.0
	var tween := _fresh(piece, "lift").set_parallel()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "position", rest_position - Vector2(0, height), 0.2)
	tween.tween_property(piece, "scale", rest_scale * (1.05 if raised else 1.0), 0.2)
	tween.tween_property(piece, "rotation_degrees", -1.2 if raised else 0.0, 0.2)
	var shadow := piece.get_node_or_null("Shadow")
	if shadow:
		tween.tween_property(shadow, "position", PaperShadow.offset_for(piece, height), 0.2)
	return tween


## Squashes flat for a moment, as if pressed into the page, then springs back.
static func squash(piece: CanvasItem) -> Tween:
	var rest_scale := _rest_scale(piece) * (1.05 if piece.get_meta("raised", false) else 1.0)
	_center_pivot(piece)
	_kill(piece, "lift")
	var tween := _fresh(piece, "scale")
	tween.tween_property(piece, "scale", rest_scale * Vector2(1.08, 0.82), 0.06) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "scale", rest_scale, 0.35) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween


# One running tween per kind of move on a piece: a new move replaces the old one.
static func _fresh(piece: CanvasItem, kind: String) -> Tween:
	_kill(piece, kind)
	var tween := piece.create_tween()
	piece.set_meta("tween_" + kind, tween)
	return tween


static func _kill(piece: CanvasItem, kind: String) -> void:
	if piece.has_meta("tween_" + kind):
		var old: Tween = piece.get_meta("tween_" + kind)
		if old.is_valid():
			old.kill()


static func _rest_position(piece: CanvasItem) -> Vector2:
	if not piece.has_meta("rest_position"):
		piece.set_meta("rest_position", piece.position)
	return piece.get_meta("rest_position")


static func _rest_scale(piece: CanvasItem) -> Vector2:
	if not piece.has_meta("rest_scale"):
		piece.set_meta("rest_scale", piece.scale)
	return piece.get_meta("rest_scale")


static func _center_pivot(piece: CanvasItem) -> void:
	if piece is Control:
		piece.pivot_offset = piece.size / 2
