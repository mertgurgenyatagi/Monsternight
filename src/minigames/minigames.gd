class_name Minigames
extends RefCounted
## Which game is played on which kind of space. A kind without a game of its own plays the stub.

const GAMES := {
	"pong": preload("res://src/minigames/pong_game.gd"),
	"tug_of_war": preload("res://src/minigames/tug_game.gd"),
} # kind -> script, filled in by the parts that build the games


static func for_kind(kind: String) -> Minigame:
	if GAMES.has(kind):
		return GAMES[kind].new()
	return StubGame.new()
