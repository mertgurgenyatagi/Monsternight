extends Control
## The night sky: a banded paper gradient, the paper moon, and stars twinkling out of step.
## The board tints it for each location.

const STAR := preload("res://assets/art/scenery/star.png")

@export var star_count := 30
@export var star_seed := 13
## Stars are scattered between the top of the sky and this height.
@export var star_floor := 640.0

@onready var _gradient: ColorRect = $Gradient
@onready var _moon: Sprite2D = $Moon
@onready var _stars: Node2D = $Stars
@onready var _flash: ColorRect = $Flash


func _ready() -> void:
	PaperShadow.add(_moon)
	_float(_moon)
	_scatter_stars()


## Fades the gradient to new colors.
func tint(top: Color, bottom: Color, duration := 1.5) -> void:
	var material := _gradient.material as ShaderMaterial
	var tween := create_tween().set_parallel()
	tween.tween_method(material.set_shader_parameter.bind("top_color"),
			material.get_shader_parameter("top_color"), top, duration)
	tween.tween_method(material.set_shader_parameter.bind("bottom_color"),
			material.get_shader_parameter("bottom_color"), bottom, duration)


## Lightning: the sky flashes pale twice, like a paper lamp switched on and off.
func flash() -> void:
	var tween := create_tween()
	for peak in [0.85, 0.0, 0.6, 0.0]:
		tween.tween_property(_flash, "color:a", peak, 0.04)
		tween.tween_interval(0.08)
	tween.tween_property(_flash, "color:a", 0.0, 0.3)


func _float(moon: Sprite2D) -> void:
	var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(moon, "position:y", moon.position.y - 8, 3.5)
	tween.tween_property(moon, "position:y", moon.position.y, 3.5)


func _scatter_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = star_seed
	var moon_radius := _moon.texture.get_width() * _moon.scale.x * 0.5
	var width := get_viewport_rect().size.x
	var placed: Array[Vector2] = []
	while placed.size() < star_count:
		var spot := Vector2(rng.randf_range(30, width - 30), rng.randf_range(30, star_floor))
		if spot.distance_to(_moon.position) < moon_radius + 50:
			continue
		if placed.any(func(other: Vector2) -> bool: return spot.distance_to(other) < 110):
			continue
		placed.append(spot)
		var star := Sprite2D.new()
		star.texture = STAR
		star.position = spot
		star.scale = Vector2.ONE * rng.randf_range(0.4, 0.85)
		star.rotation_degrees = rng.randf_range(-20, 20)
		_stars.add_child(star)
		PaperShadow.add(star)
		_twinkle(star, rng)


# Each star breathes at its own pace and starts at its own point, so no two keep step.
func _twinkle(star: Sprite2D, rng: RandomNumberGenerator) -> void:
	var half := rng.randf_range(0.7, 1.8)
	var rest := star.scale
	var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(star, "scale", rest * 0.65, half)
	tween.parallel().tween_property(star, "modulate", Color(0.75, 0.7, 0.85), half)
	tween.parallel().tween_property(star, "rotation_degrees", star.rotation_degrees + 12, half)
	tween.tween_property(star, "scale", rest, half)
	tween.parallel().tween_property(star, "modulate", Color.WHITE, half)
	tween.parallel().tween_property(star, "rotation_degrees", star.rotation_degrees, half)
	tween.custom_step(rng.randf_range(0.0, half * 2))
