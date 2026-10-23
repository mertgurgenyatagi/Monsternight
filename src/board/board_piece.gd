class_name BoardPiece
extends MonsterFigure
## A player's monster on the board: the body on its paper stand, about 200 px tall in all, drawn
## from art with a cream outline baked in (`tools/images/make_outlines.py`) so it stands out from the
## scenery. The board moves it and `Match` decides where it stands; the piece only shows that.

## The end of a walk, after the last hop has landed.
signal walked
## The path a walking piece takes at a fork, once it's been chosen.
signal branch_chosen(id: String)

const BALL_TEXTURE := preload("res://assets/art/monsters/crumpled.png")
const BALL_SIZE := 96.0 # across, on screen

## The crumpled paper ball a dead piece turns into. It sits in the piece's origin, which is its
## feet, and shows only between `fold(true)` and `fold(false)`.
var ball: Sprite2D
var player: Dictionary


func _init(player_: Dictionary = {}) -> void:
	super(player_.get("monster", ""))
	player = player_
	feet = Vector2(0, -3)
	body_pad = 6.0


func _ready() -> void:
	super()
	ball = Sprite2D.new()
	ball.texture = BALL_TEXTURE
	ball.visible = false
	add_child(ball)
	PaperShadow.add(ball)
	start_sway()


## Sways gently, out of step with the others. Rotates the body about its feet.
func start_sway() -> void:
	var period := randf_range(3.2, 5.0)
	PaperMotion.sway(_body, randf_range(1.0, 1.8), period).custom_step(randf_range(0.0, period))


## Stops swaying, for a walk.
func stop_sway() -> void:
	PaperMotion.sway_stop(_body)


## Swaps the monster for its paper ball (`on`), or the ball for the monster. The piece must have
## been shrunk by `PaperMotion.crumple` first, with `ball_scale` as its scale; the ball is drawn
## `BALL_SIZE` across on screen and rests on the piece's feet.
func fold(on: bool, ball_scale := 0.4) -> void:
	_body.visible = not on
	_stand.visible = not on
	ball.visible = on
	if on:
		var size := BALL_SIZE / ball_scale / BALL_TEXTURE.get_width()
		ball.scale = Vector2.ONE * size
		ball.position = Vector2(0, -BALL_TEXTURE.get_height() * size / 2.0)


func _stand_texture() -> Texture2D:
	return preload("res://assets/art/monsters/stand_rim.png")


func _body_texture() -> Texture2D:
	return load("res://assets/art/monsters/%s_rim.png" % id)
