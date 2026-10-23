class_name MonsterFigure
extends Node2D
## A monster's body standing on its paper stand, each with a paper shadow. The origin is the middle
## of the stand, on the ground. Monster select's piece and the board's piece both build on this,
## and differ only in the art they draw (`_body_texture`, `_stand_texture`), the scale it's drawn
## at, and what they do with the sprites (`_make_sprite`).

var id: String
var body_scale := 1.0
var stand_scale := 1.0
## Where the body's feet touch the stand, and how far the body's art reaches below its feet (an
## outline baked into the art).
var feet := Vector2.ZERO
var body_pad := 0.0

var _body: Sprite2D
var _stand: Sprite2D


func _init(monster_id := "") -> void:
	id = monster_id


func _ready() -> void:
	_stand = _make_sprite(_stand_texture(), true)
	_stand.scale = Vector2.ONE * stand_scale
	_body = _make_sprite(_body_texture(), false)
	_body.offset = Vector2(-_body.texture.get_width() / 2.0, -(_body.texture.get_height() - body_pad))
	_body.position = feet
	_body.scale = Vector2.ONE * body_scale
	PaperShadow.add(_stand)
	PaperShadow.add(_body)


## How tall the body is as drawn.
func body_height() -> float:
	return _body.texture.get_height() * body_scale


func _stand_texture() -> Texture2D:
	return preload("res://assets/art/monsters/stand.png")


func _body_texture() -> Texture2D:
	return Monsters.body(id)


func _make_sprite(texture: Texture2D, centered: bool) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = centered
	add_child(sprite)
	return sprite
