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


## Stops a sway and eases the piece back upright.
static func sway_stop(piece: CanvasItem) -> void:
	var tween := _fresh(piece, "sway")
	tween.tween_property(piece, "rotation_degrees", 0.0, 0.3)


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


## Slides in from `from_x` (an x position off to one side) and settles with a wobble.
static func slide_in(piece: Node2D, from_x: float, delay := 0.0, duration := 0.7) -> Tween:
	var rest := _rest_position(piece)
	piece.position = Vector2(from_x, rest.y)
	piece.rotation_degrees = 10.0 * signf(from_x - rest.x)
	var tween := _fresh(piece, "move").set_parallel()
	tween.tween_property(piece, "position", rest, duration).set_delay(delay) 			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "rotation_degrees", 0.0, duration * 1.4).set_delay(delay) 			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween


## Glides to a new resting place, which becomes the piece's rest position.
static func move_to(piece: Node2D, target: Vector2, duration := 0.45) -> Tween:
	piece.set_meta("rest_position", target)
	var tween := _fresh(piece, "move").set_parallel()
	tween.tween_property(piece, "position", target, duration) 			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "rotation_degrees", 0.0, duration)
	return tween


## Turns around on its edge: squeezes to nothing, calls `at_middle` to swap the face, and opens
## again. The face swap happens while the piece is edge-on, so it never shows.
static func flip(piece: CanvasItem, at_middle := Callable(), duration := 0.32) -> Tween:
	var rest := _rest_scale(piece)
	_kill(piece, "lift")
	var tween := _fresh(piece, "scale")
	tween.tween_property(piece, "scale:x", 0.0, duration / 2) 			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if at_middle.is_valid():
		tween.tween_callback(at_middle)
	tween.tween_property(piece, "scale:x", rest.x, duration / 2) 			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


## A small jump in place: it squats, springs up, and lands with a squash.
static func hop(piece: Node2D, height := 40.0) -> Tween:
	var rest := _rest_position(piece)
	_center_pivot(piece)
	_kill(piece, "lift")
	var tween := _fresh(piece, "move")
	tween.tween_property(piece, "position:y", rest.y - height, 0.18) 			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "position:y", rest.y, 0.16) 			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: squash(piece))
	return tween


## Flies in an arc to a new resting place and size, which become the piece's rest position and
## scale. `arc` is how high the path bows above the straight line.
static func fly_to(piece: Node2D, target: Vector2, target_scale: Vector2, duration := 0.5,
		delay := 0.0, arc := 60.0) -> Tween:
	var from := piece.position
	piece.set_meta("rest_position", target)
	piece.set_meta("rest_scale", target_scale)
	_kill(piece, "lift")
	var tween := _fresh(piece, "move").set_parallel()
	tween.tween_method(func(t: float) -> void:
			piece.position = from.lerp(target, t) - Vector2(0, arc * 4.0 * t * (1.0 - t)),
			0.0, 1.0, duration).set_delay(delay) 			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(piece, "rotation_degrees", 0.0, duration).set_delay(delay)
	var scaling := _fresh(piece, "scale")
	scaling.tween_property(piece, "scale", target_scale, duration).set_delay(delay) 			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	return tween


## Hops from where it stands to `target`, which becomes its rest position: a quick crouch, a low
## arc and a squash on landing. `heavy` lands harder, with a bigger squash and a slower settle,
## for the last hop of a walk. `landed` is called as it touches down.
static func hop_to(piece: Node2D, target: Vector2, landed := Callable(), heavy := false,
		arc := 44.0) -> Tween:
	var from := piece.position
	var rest := _rest_scale(piece)
	piece.set_meta("rest_position", target)
	_kill(piece, "lift")
	_kill(piece, "scale")
	var tween := _fresh(piece, "move")
	tween.tween_property(piece, "scale", rest * Vector2(1.1, 0.8), 0.07) 			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(t: float) -> void:
			piece.position = from.lerp(target, t) - Vector2(0, arc * 4.0 * t * (1.0 - t))
			piece.scale = rest * Vector2(1.0 - 0.1 * sin(t * PI), 1.0 + 0.14 * sin(t * PI)),
			0.0, 1.0, 0.27).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if landed.is_valid():
		tween.tween_callback(landed)
	var squash_to := Vector2(1.22, 0.68) if heavy else Vector2(1.1, 0.84)
	tween.tween_property(piece, "scale", rest * squash_to, 0.06) 			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if heavy:
		tween.tween_property(piece, "scale", rest, 0.4) 				.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(piece, "scale", rest, 0.12) 				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


## Lifts out of a stack in a small arc to one side, calls `at_apex` (to move the piece to
## another height in the stack, and set its new "rest_position"), and tucks back in at its
## rest position.
static func tuck(piece: Node2D, side: Vector2, at_apex := Callable(), duration := 0.4) -> Tween:
	var home := _rest_position(piece)
	_kill(piece, "lift")
	var tween := _fresh(piece, "move")
	var out := func(t: float) -> void:
		piece.position = home.lerp(home + side, t) - Vector2(0, 26.0 * sin(t * PI * 0.5))
		piece.rotation_degrees = side.x * 0.06 * t
	tween.tween_method(out, 0.0, 1.0, duration / 2) 			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if at_apex.is_valid():
		tween.tween_callback(at_apex)
	var back := func(t: float) -> void:
		var target: Vector2 = piece.get_meta("rest_position")
		piece.position = (home + side).lerp(target, t) - Vector2(0, 26.0 * cos(t * PI * 0.5))
		piece.rotation_degrees = side.x * 0.06 * (1.0 - t)
	tween.tween_method(back, 0.0, 1.0, duration / 2) 			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tween


## Rises and sinks a few pixels from its rest position, slowly and forever, starting at a random
## point so no two keep step.
static func breathe(piece: Node2D, rise := 3.0, period := 2.6) -> Tween:
	var rest := _rest_position(piece)
	var tween := _fresh(piece, "breathe").set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(piece, "position:y", rest.y - rise, period / 2)
	tween.tween_property(piece, "position:y", rest.y, period / 2)
	tween.custom_step(randf_range(0.0, period))
	return tween


## Tips over one way, then the other, and settles: like something about to start.
static func tilt(piece: Node2D, degrees := 7.0) -> Tween:
	var tween := _fresh(piece, "tilt")
	tween.tween_property(piece, "rotation_degrees", degrees, 0.14) 			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "rotation_degrees", -degrees * 0.6, 0.16) 			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(piece, "rotation_degrees", 0.0, 0.4) 			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween


## Jerks from side to side, for "no".
static func shake(piece: CanvasItem) -> Tween:
	var rest := _rest_position(piece)
	var tween := _fresh(piece, "move")
	for dx in [-16.0, 14.0, -10.0, 6.0, 0.0]:
		tween.tween_property(piece, "position:x", rest.x + dx, 0.05)
	tween.parallel().tween_property(piece, "rotation_degrees", 0.0, 0.25)
	return tween


## Scrunches up like a sheet of paper and drops away. The piece frees itself when the move ends.
static func crumple(piece: Node2D, duration := 0.5) -> Tween:
	var rest := _rest_position(piece)
	var tween := _fresh(piece, "move").set_parallel()
	tween.tween_property(piece, "scale", Vector2(0.35, 0.3), duration * 0.6) 			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(piece, "rotation_degrees", 35.0, duration * 0.6) 			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(piece, "position", rest + Vector2(0, 60), duration) 			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(piece, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	tween.chain().tween_callback(piece.queue_free)
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
