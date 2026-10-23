class_name PaperShadow
## The one soft shadow every paper piece casts: a darkened, blurred copy of the piece,
## drawn behind it and offset down and to the right, as if lifted off the page.

const OFFSET := Vector2(7, 10)
const SHADER := preload("res://src/paper/shadow.gdshader")

static var _material: ShaderMaterial


## Gives the piece its shadow, a child named "Shadow". Works on Sprite2D, NinePatchRect and
## Buttons styled with a texture.
static func add(piece: CanvasItem) -> CanvasItem:
	var shadow: CanvasItem
	if piece is Sprite2D:
		var sprite := Sprite2D.new()
		sprite.texture = piece.texture
		sprite.centered = piece.centered
		sprite.offset = piece.offset
		sprite.flip_h = piece.flip_h
		sprite.flip_v = piece.flip_v
		shadow = sprite
	elif piece is NinePatchRect:
		shadow = _nine_patch(piece.texture, piece.patch_margin_left, piece.patch_margin_top,
				piece.patch_margin_right, piece.patch_margin_bottom)
	elif piece is Button:
		var style := piece.get_theme_stylebox("normal") as StyleBoxTexture
		shadow = _nine_patch(style.texture, style.texture_margin_left, style.texture_margin_top,
				style.texture_margin_right, style.texture_margin_bottom)
	else:
		push_error("PaperShadow can't shadow a %s" % piece.get_class())
		return null
	if not piece.has_meta("rest_scale"):
		piece.set_meta("rest_scale", piece.scale)
	shadow.name = "Shadow"
	shadow.show_behind_parent = true
	shadow.material = _shared_material()
	piece.add_child(shadow)
	piece.move_child(shadow, 0)
	place(piece, 0.0)
	return shadow


## Where the shadow sits for a piece raised by `lift` pixels. The piece rises, so its shadow
## falls further away. Pieces scaled at rest keep the same on-screen offset.
static func offset_for(piece: CanvasItem, lift: float) -> Vector2:
	var rest_scale: Vector2 = piece.get_meta("rest_scale", piece.scale)
	var screen := OFFSET + Vector2(lift * 0.5, lift * 1.5)
	return screen / Vector2(maxf(absf(rest_scale.x), 0.01), maxf(absf(rest_scale.y), 0.01))


static func place(piece: CanvasItem, lift: float) -> void:
	var shadow := piece.get_node_or_null("Shadow")
	if shadow:
		shadow.position = offset_for(piece, lift)


static func _nine_patch(texture: Texture2D, left: int, top: int, right: int, bottom: int) -> NinePatchRect:
	var patch := NinePatchRect.new()
	patch.texture = texture
	patch.patch_margin_left = left
	patch.patch_margin_top = top
	patch.patch_margin_right = right
	patch.patch_margin_bottom = bottom
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.set_anchors_preset(Control.PRESET_FULL_RECT)
	return patch


static func _shared_material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
	return _material
