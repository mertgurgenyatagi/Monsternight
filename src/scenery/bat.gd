extends Sprite2D
## A bat that flaps across the screen now and then on a wavy path, from off one side to off
## the other.

@export var heights := Vector2(280, 460)
@export var first_wait := Vector2(2.5, 5.0)
@export var wait := Vector2(7.0, 14.0)

var _flap: Tween


func _ready() -> void:
	visible = false
	PaperShadow.add(self)
	_rest_after(randf_range(first_wait.x, first_wait.y))


func _rest_after(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout
	_fly()


func _fly() -> void:
	var width := get_viewport_rect().size.x
	var rightward := randf() < 0.5
	var margin := texture.get_width() * scale.x
	var from := -margin if rightward else width + margin
	var to := width + margin if rightward else -margin
	var y := randf_range(heights.x, heights.y)
	var duration := randf_range(5.0, 7.0)
	flip_h = not rightward
	$Shadow.flip_h = flip_h
	visible = true

	_flap = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_flap.tween_property(self, "scale:y", scale.x * 0.4, 0.11)
	_flap.tween_property(self, "scale:y", scale.x, 0.13)

	var tween := create_tween()
	tween.tween_method(_glide.bind(from, to, y), 0.0, 1.0, duration)
	await tween.finished
	_flap.kill()
	visible = false
	_rest_after(randf_range(wait.x, wait.y))


func _glide(t: float, from: float, to: float, y: float) -> void:
	var wave := sin(t * TAU * 2.0)
	position = Vector2(lerpf(from, to, t), y + wave * 45.0 - t * 80.0)
	rotation = cos(t * TAU * 2.0) * 0.25 * signf(to - from)
