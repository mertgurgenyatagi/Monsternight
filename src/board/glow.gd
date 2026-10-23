class_name Glow
extends Sprite2D
## A soft round glow made in the engine and added onto whatever is under it, for the village
## lamps, the castle torches and the forest mushrooms.

const SIZE := 256

static var _texture: GradientTexture2D
static var _material: CanvasItemMaterial

## How much the brightness wavers every frame, like a flame. 0 holds it steady.
var jitter := 0.0

var _strength := 1.0
var _wobble := 1.0
var _pulse: Tween
var _radius_scale: Vector2


func _init(color := Color.WHITE, radius := 128.0) -> void:
	texture = _shared_texture()
	material = _shared_material()
	self_modulate = color
	_strength = color.a
	scale = Vector2.ONE * radius / (SIZE / 2.0)
	_radius_scale = scale


func _process(_delta: float) -> void:
	if jitter > 0.0:
		_wobble = lerpf(_wobble, randf_range(1.0 - jitter, 1.0), 0.6)
	self_modulate.a = _strength * _wobble


## Now and then the glow catches a draught: it dips and recovers in a quick stutter.
func flicker(every := Vector2(3.0, 8.0)) -> void:
	await get_tree().create_timer(randf_range(0.0, every.y), false).timeout
	while is_inside_tree():
		var full := _strength
		var tween := create_tween()
		for dip in [0.35, 0.85, 0.5, 1.0]:
			tween.tween_property(self, "_strength", full * dip, randf_range(0.04, 0.1))
		await tween.finished
		await get_tree().create_timer(randf_range(every.x, every.y), false).timeout


## Swells and fades slowly, forever, starting at a random point so no two keep step.
func pulse(low: float, high: float, period: float) -> void:
	_pulse = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse.tween_property(self, "_strength", high, period / 2)
	_pulse.tween_property(self, "_strength", low, period / 2)
	_pulse.custom_step(randf_range(0.0, period))


## A sudden flare: the glow swells and brightens to full, then settles back to its pulse.
func flare(grow := 1.5, up := 0.15, down := 0.9) -> Tween:
	if _pulse and _pulse.is_valid():
		_pulse.pause()
	var before := _strength
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "_strength", 1.0, up).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", _radius_scale * grow, up).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "_strength", before, down).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "scale", _radius_scale, down).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(func() -> void:
			if _pulse and _pulse.is_valid():
				_pulse.play())
	return tween


static func _shared_texture() -> GradientTexture2D:
	if _texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.35, Color(1, 1, 1, 0.45))
		_texture = GradientTexture2D.new()
		_texture.gradient = gradient
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1.0, 0.5)
		_texture.width = SIZE
		_texture.height = SIZE
	return _texture


static func _shared_material() -> CanvasItemMaterial:
	if _material == null:
		_material = CanvasItemMaterial.new()
		_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _material
