class_name MinigameInput
extends RefCounted
## The seam between a minigame and whoever plays it. A game reads the two sides' keys only through
## `pressed` and `just_pressed`; side 0 is the left player and side 1 the right. On one computer the left
## side has W A S D, Q, E and R, and the right side the arrow keys, K, L and ;. The network will set
## `source` (a Callable taking a side and a key, giving whether it is held) and feed the same calls.
## An absent side reads as nothing pressed. Keys: up, left, down, right, action, special, dash.

const KEYS := ["up", "left", "down", "right", "action", "special", "dash"]
const MAPS := [
	{"up": KEY_W, "left": KEY_A, "down": KEY_S, "right": KEY_D, "action": KEY_Q, "special": KEY_E, "dash": KEY_R},
	{"up": KEY_UP, "left": KEY_LEFT, "down": KEY_DOWN, "right": KEY_RIGHT, "action": KEY_K,
			"special": KEY_L, "dash": KEY_SEMICOLON},
]
const LABELS := [
	{"up": "W", "left": "A", "down": "S", "right": "D", "action": "Q", "special": "E", "dash": "R"},
	{"up": "^", "left": "<", "down": "v", "right": ">", "action": "K", "special": "L", "dash": ";"},
]

## Replaces the keyboard when valid: `source.call(side, key) -> bool`.
static var source := Callable()
## Sides that are absent (online, a player who left): they read as nothing pressed.
static var absent: Array[int] = []

static var _stamp := -1
static var _now := {}
static var _before := {}


static func pressed(side: int, key: String) -> bool:
	_roll()
	return _now.get([side, key], false)


## True only on the physics frame the key went down.
static func just_pressed(side: int, key: String) -> bool:
	_roll()
	return _now.get([side, key], false) and not _before.get([side, key], false)


## The held direction of a side as a vector with length at most 1 (y grows downward).
static func direction(side: int) -> Vector2:
	var v := Vector2(float(pressed(side, "right")) - float(pressed(side, "left")),
			float(pressed(side, "down")) - float(pressed(side, "up")))
	return v.limit_length(1.0)


## The small label a keycap shows for this key on this side.
static func label(side: int, key: String) -> String:
	return LABELS[side][key]


# Samples all keys once per physics frame, however many times the games ask.
static func _roll() -> void:
	var frame := Engine.get_physics_frames()
	if frame == _stamp:
		return
	_stamp = frame
	_before = _now
	_now = {}
	for side in 2:
		for key in KEYS:
			var down := false
			if side not in absent:
				if source.is_valid():
					down = source.call(side, key)
				else:
					down = Input.is_physical_key_pressed(MAPS[side][key])
			_now[[side, key]] = down
