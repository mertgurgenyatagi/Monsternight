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
## The game's own randomness, so that every copy of an online game serves the same way. Online the
## frame seeds it with the host's number before `setup`; played locally it stays random.
var rng := RandomNumberGenerator.new()
## True on an online copy that is not the host: the game plays on for show, but only the host ends it.
var remote_judge := false


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


## Ends the round. Only the first call counts. A copy that is not the host stops its own game but
## leaves the verdict to the host (`finished` is not emitted).
func finish(winner_side: int) -> void:
	if not active:
		return
	active = false
	if not remote_judge:
		finished.emit(winner_side)


## True while the online driver should keep calling `step` (a goal's aftermath keeps moving).
func stepping() -> bool:
	return active


## The game as numbers and lists of numbers only, so it goes through JSON. Overridden by each game.
func get_state() -> Dictionary:
	return {}


## Puts the game back to a `get_state` (or a blend of two).
func set_state(_state: Dictionary) -> void:
	pass


## Keys of `get_state` that hold a position (a float, or a list of floats) to glide towards a snapshot
## instead of jumping to it.
func blend_keys() -> Array:
	return []


## Pairs `[position key, velocity key]` for positions that move: the snapshot's is carried forward by
## the time it took to arrive before the copy glides towards it.
func blend_pairs() -> Array:
	return []


## How far a position may be off, in the game's own units, before a snapshot snaps instead of glides.
func snap_distance() -> float:
	return 40.0


static func pack(v: Vector2) -> Array:
	return [v.x, v.y]


static func unpack(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


static func pack_all(list: Array) -> Array:
	var out := []
	for v in list:
		out.append(pack(v))
	return out


## Fills a typed list of vectors from packed ones, in place.
static func unpack_into(list: Array, packed: Array) -> void:
	for i in mini(list.size(), packed.size()):
		list[i] = unpack(packed[i])


## The side's color, for tinting what belongs to a player.
func color_of(side: int) -> Color:
	return Monsters.color(players[side].monster)
