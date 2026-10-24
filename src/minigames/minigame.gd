class_name Minigame
extends Node2D
## What every minigame implements. The frame calls `setup`, shows the instructions from `controls`, then
## `begin`s the game after the countdown. The game reads keys through `MinigameInput` only, draws the
## table in a 1920 x 1080 space around `TABLE_CENTER`, and emits `finished` with the winning side (0 the
## left player, who is the challenger, 1 the right), or `DRAW` to replay the round. Nothing in a game
## may depend on who is watching: it draws from its own state.

signal finished(winner_side: int)

const DRAW := -1
const TABLE_CENTER := Vector2(960, 540)
const TABLE_SIZE := Vector2(1480, 640)

var players: Array[Dictionary] = []
var challenger_side := 0
## Mr. Hyde's edge as the challenger: 0, or about 0.1 for the game to apply as it sees fit.
var edge := 0.0
var active := false


func setup(left: Dictionary, right: Dictionary, challenger: int, edge_value: float) -> void:
	players = [left, right]
	challenger_side = challenger
	edge = edge_value


## The keys the instructions show: an array of `[key ids, translation key]` lines, the same for both sides.
func controls() -> Array:
	return []


## The countdown is over: play.
func begin() -> void:
	active = true


## Ends the round. Only the first call counts.
func finish(winner_side: int) -> void:
	if not active:
		return
	active = false
	finished.emit(winner_side)


## The side's color, for tinting what belongs to a player.
func color_of(side: int) -> Color:
	return Monsters.color(players[side].monster)
