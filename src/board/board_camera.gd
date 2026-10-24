class_name BoardCamera
extends Camera2D
## The board's side view. It only moves sideways, between the board's ends, and glides
## wherever it's sent: the intro now, the active player from part 8 on, and follows a walking piece.

## Glide speed when no duration is given, in pixels a second.
const SPEED := 2800.0

## How quickly a following camera closes the gap, and its top speed in pixels a second.
const FOLLOW_RATE := 6.0
const FOLLOW_SPEED := 3200.0
## A follow starts from a standstill and takes this long to reach full pace, so it never snaps.
const FOLLOW_EASE_IN := 0.3

var _glide: Tween
var _target: Node2D
var _follow_time := 0.0


func _ready() -> void:
	limit_left = 0
	limit_right = int(BoardLayout.width())
	limit_top = 0
	limit_bottom = 1080
	position = Vector2(960, 540)


func _process(delta: float) -> void:
	if _target == null:
		return
	_follow_time += delta
	var pace := smoothstep(0.0, 1.0, _follow_time / FOLLOW_EASE_IN)
	var goal := clampf(_target.global_position.x, 960.0, BoardLayout.width() - 960.0)
	var step := (goal - position.x) * (1.0 - exp(-FOLLOW_RATE * delta)) * pace
	position.x += clampf(step, -FOLLOW_SPEED * delta, FOLLOW_SPEED * delta)


## The world x at the middle of the screen.
func center_x() -> float:
	return get_screen_center_position().x


## Glides so world x is in the middle of the screen, or as near as the board's ends allow,
## easing in and out. With no duration, it takes longer the further it goes.
func glide_to(x: float, duration := -1.0) -> Tween:
	var target := clampf(x, 960.0, BoardLayout.width() - 960.0)
	if duration < 0.0:
		duration = clampf(absf(target - position.x) / SPEED, 0.3, 1.4)
	stop()
	_glide = create_tween()
	_glide.tween_property(self, "position:x", target, duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return _glide


## Keeps this node near the middle of the screen, with a soft lag, until `stop`. It eases in, so
## it never snaps to a piece that starts walking.
func follow(node: Node2D) -> void:
	stop()
	_target = node
	_follow_time = 0.0


## Jumps straight to world x, for setting up a view.
func jump_to(x: float) -> void:
	stop()
	position.x = clampf(x, 960.0, BoardLayout.width() - 960.0)
	force_update_scroll()


## Stops a glide or a follow where it is.
func stop() -> void:
	_target = null
	if _glide and _glide.is_valid():
		_glide.kill()
