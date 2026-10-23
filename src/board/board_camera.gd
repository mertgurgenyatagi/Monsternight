class_name BoardCamera
extends Camera2D
## The board's side view. It only moves sideways, between the board's ends, and glides
## wherever it's sent: the intro now, the active player from part 8 on.

## Glide speed when no duration is given, in pixels a second.
const SPEED := 1800.0

var _glide: Tween


func _ready() -> void:
	limit_left = 0
	limit_right = int(BoardLayout.width())
	limit_top = 0
	limit_bottom = 1080
	position = Vector2(960, 540)


## The world x at the middle of the screen.
func center_x() -> float:
	return get_screen_center_position().x


## Glides so world x is in the middle of the screen, or as near as the board's ends allow,
## easing in and out. With no duration, it takes longer the further it goes.
func glide_to(x: float, duration := -1.0) -> Tween:
	var target := clampf(x, 960.0, BoardLayout.width() - 960.0)
	if duration < 0.0:
		duration = clampf(absf(target - position.x) / SPEED, 0.4, 2.0)
	stop()
	_glide = create_tween()
	_glide.tween_property(self, "position:x", target, duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return _glide


## Jumps straight to world x, for setting up a view.
func jump_to(x: float) -> void:
	stop()
	position.x = clampf(x, 960.0, BoardLayout.width() - 960.0)
	force_update_scroll()


## Stops a glide where it is.
func stop() -> void:
	if _glide and _glide.is_valid():
		_glide.kill()
