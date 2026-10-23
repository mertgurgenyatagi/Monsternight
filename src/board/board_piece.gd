class_name BoardPiece
extends MonsterFigure
## A player's monster on the board: the body on its paper stand, about 200 px tall in all, drawn
## from art with a cream outline baked in (`tools/images/make_outlines.py`) so it stands out from the
## scenery. The board moves it and `Match` decides where it stands; the piece only shows that.

## The end of a walk, after the last hop has landed.
signal walked
## The path a walking piece takes at a fork, once it's been chosen.
signal branch_chosen(id: String)

var player: Dictionary


func _init(player_: Dictionary = {}) -> void:
	super(player_.get("monster", ""))
	player = player_
	feet = Vector2(0, -3)
	body_pad = 6.0


func _ready() -> void:
	super()
	start_sway()


## Sways gently, out of step with the others. Rotates the body about its feet.
func start_sway() -> void:
	var period := randf_range(3.2, 5.0)
	PaperMotion.sway(_body, randf_range(1.0, 1.8), period).custom_step(randf_range(0.0, period))


## Stops swaying, for a walk.
func stop_sway() -> void:
	PaperMotion.sway_stop(_body)


func _stand_texture() -> Texture2D:
	return preload("res://assets/art/monsters/stand_rim.png")


func _body_texture() -> Texture2D:
	return load("res://assets/art/monsters/%s_rim.png" % id)
