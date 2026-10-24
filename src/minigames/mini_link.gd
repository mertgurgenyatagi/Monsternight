class_name MiniLink
extends Node2D
## One online minigame round on the wire. Every copy of the game runs the same code; the host's copy is
## the truth. The two duelists play on their own keyboards: a duelist's copy applies its keys at once and
## sends them to the host (`mini_input`), the host schedules them `LEAD` ticks ahead and tells everyone
## (`mini_keys`), and each copy feeds the keys into `MinigameInput.source`, so the games read keys as they
## always did. The host sends the whole game ten times a second (`mini_state`), and the others glide to it
## (carried forward by the time it took to arrive), snapping only where they are far off. Only the host
## ends the round (`mini_end`). The link also draws the small online extras: the ping dot, the "Watching"
## tag and the "Waiting for ..." banner. Every message carries the round's `seed`, and a message for
## another round is ignored.

## The round is over: the winning side, or `Minigame.DRAW`.
signal round_ended(winner: int)

const STEP := 1.0 / 60.0
## Ticks between a key reaching the host and every copy applying it, about 50 ms.
const LEAD := 3
## Ticks between two snapshots, ten a second.
const SNAP_EVERY := 6
## How much of the way to a snapshot a copy glides at each one.
const GLIDE := 0.5
const BEAT := 0.5 # seconds between a duelist's keepalives
const SILENT := 3.0 # seconds without a keepalive before the host calls a duelist absent
const STALL := 1.5 # seconds without a snapshot before the "Waiting" banner
const INK := Color("2a1a22")
const CREAM := Color("fbe9d0")

var game: Minigame
var round_id := 0
var tick := 0
## Round-trip time to the host in milliseconds, measured by a duelist; -1 before the first answer.
var rtt := -1.0
## The side this copy plays, or -1 when it only watches.
var local_side := -1
## The one-way trip assumed for a spectator, who never measures one, in seconds.
var spectator_lag := 0.05

var _ids: Array[int] = [0, 0] # the peer behind each side
var _names: Array[String] = ["", ""]
var _host := false
var _running := false
var _mask := [0, 0]
var _plan: Array = [[], []] # per side, [{tick, keys}] waiting for their tick
var _beat := 0.0
var _heard := [0.0, 0.0] # host: seconds since a duelist's last message
var _waited := 0.0 # seconds since the last snapshot
var _result := -2 # the verdict, once it is in; -2 before
var _ended := false
var _banner := ""
var _banner_a := 0.0
var _key_index := {}


## `players` are the two duelists (the challenger first) and `seed_value` the round's number.
func setup(minigame: Minigame, players: Array[Dictionary], seed_value: int) -> void:
	game = minigame
	round_id = seed_value
	_host = Net.is_host
	for i in 2:
		_names[i] = players[i].name
		_ids[i] = int(Net.id_by_name.get(players[i].name, -1))
		if _ids[i] == Net.my_id:
			local_side = i
	for i in MinigameInput.KEYS.size():
		_key_index[MinigameInput.KEYS[i]] = i
	game.remote_judge = not _host
	game.set_physics_process(false) # this node steps the game, at the same rate on every copy
	game.finished.connect(_on_game_finished)
	MinigameInput.source = _key_down
	MinigameInput.absent = []
	Net.received.connect(_on_received)
	Net.peer_left.connect(_on_peer_left)


func _exit_tree() -> void:
	if Net.received.is_connected(_on_received):
		Net.received.disconnect(_on_received)
	if Net.peer_left.is_connected(_on_peer_left):
		Net.peer_left.disconnect(_on_peer_left)
	MinigameInput.source = Callable()
	MinigameInput.absent = []


## The countdown is over: the game begins.
func begin() -> void:
	game.begin()
	_running = true
	_waited = 0.0
	_heard = [0.0, 0.0]


## Gives the verdict, waiting for it if it has not come in yet.
func wait_end() -> int:
	if _result != -2:
		return _result
	return await round_ended


func _physics_process(delta: float) -> void:
	if not _running:
		return
	for side in 2:
		var plan: Array = _plan[side]
		while not plan.is_empty() and int(plan[0].tick) <= tick:
			if side != local_side: # a duelist's own keys are already in
				_mask[side] = int(plan[0].keys)
			plan.pop_front()
	if local_side >= 0:
		_send_keys(delta)
	if game.stepping():
		game.step(STEP)
	tick += 1
	if _host:
		if tick % SNAP_EVERY == 0 and not _ended:
			_send_state()
		_check_duelists(delta)
	else:
		_waited += delta
		if _waited > STALL and not _ended:
			_say(tr("MINI_WAITING") % _name_of(Online.host_id))
		else:
			_say("")
	_banner_a = move_toward(_banner_a, 1.0 if _banner != "" else 0.0, delta * 5.0)
	queue_redraw()


# ---- keys ----

func _key_down(side: int, key: String) -> bool:
	return (int(_mask[side]) >> int(_key_index[key])) & 1 == 1


# The bitmask of what this duelist holds: its own side's keys, or the other side's (so one keyboard
# layout is enough).
func _read_keys() -> int:
	if Online.bot:
		return _bot_keys()
	var mask := 0
	for key in MinigameInput.KEYS:
		var down: bool = false
		for map in MinigameInput.MAPS:
			down = down or Input.is_physical_key_pressed(map[key])
		if down:
			mask |= 1 << int(_key_index[key])
	return mask


# A test bot's keys: a new random mix every few ticks, and the action key mashed.
func _bot_keys() -> int:
	var mix := hash([tick / 10, local_side, round_id])
	var mask := 0
	for i in 4: # up, left, down, right
		if (mix >> i) & 1 == 1:
			mask |= 1 << i
	if (tick / 3) % 2 == 0:
		mask |= 1 << int(_key_index["action"])
	return mask


func _send_keys(delta: float) -> void:
	var mask := _read_keys() if local_side not in MinigameInput.absent else 0
	_beat += delta
	var changed := mask != int(_mask[local_side])
	if not changed and _beat < BEAT:
		return
	_beat = 0.0
	_mask[local_side] = mask
	if _host:
		if changed:
			_broadcast_keys(local_side, tick, mask)
	else:
		Net.send(Online.host_id, "mini_input", {"r": round_id, "keys": mask, "t": Time.get_ticks_msec()})


func _broadcast_keys(side: int, at: int, mask: int) -> void:
	Net.broadcast("mini_keys", {"r": round_id, "side": side, "tick": at, "keys": mask})


# ---- the host's side ----

func _send_state() -> void:
	Net.broadcast("mini_state", {"r": round_id, "tick": tick, "over": not game.stepping(), "g": game.get_state()})


func _on_game_finished(winner: int) -> void:
	if not _host or _ended:
		return
	_ended = true
	Net.broadcast("mini_state", {"r": round_id, "tick": tick, "over": true, "g": game.get_state()})
	Net.broadcast("mini_end", {"r": round_id, "winner": winner})
	_result = winner
	round_ended.emit(winner)


# A duelist who has sent nothing for a while is called absent; the game goes on with that side idle.
func _check_duelists(delta: float) -> void:
	for side in 2:
		if side == local_side or side in MinigameInput.absent:
			continue
		_heard[side] += delta
		if _heard[side] > SILENT:
			_drop(side)
			Net.broadcast("mini_absent", {"r": round_id, "side": side})


func _drop(side: int) -> void:
	if side in MinigameInput.absent:
		return
	MinigameInput.absent.append(side)
	_mask[side] = 0
	_plan[side].clear()
	Sound.play("leave")


func _on_peer_left(id: int) -> void:
	var side := _ids.find(id)
	if side >= 0 and _host and not _ended:
		_drop(side)
		Net.broadcast("mini_absent", {"r": round_id, "side": side})


func _on_received(from: int, kind: String, payload: Dictionary) -> void:
	if int(payload.get("r", 0)) != round_id:
		return
	match kind:
		"mini_input":
			if not _host:
				return
			var side := _ids.find(from)
			if side < 0 or side == local_side:
				return # a spectator's keys count for nothing
			_heard[side] = 0.0
			var at := tick + LEAD
			_plan[side].append({"tick": at, "keys": int(payload.get("keys", 0))})
			_broadcast_keys(side, at, int(payload.get("keys", 0)))
			Net.send(from, "mini_ack", {"r": round_id, "t": payload.get("t", 0)})
		"mini_keys":
			if from != Online.host_id:
				return
			var side := int(payload.get("side", -1))
			if side in [0, 1] and side != local_side:
				_plan[side].append({"tick": int(payload.get("tick", 0)), "keys": int(payload.get("keys", 0))})
		"mini_ack":
			if from == Online.host_id:
				rtt = float(Time.get_ticks_msec() - int(payload.get("t", 0)))
		"mini_state":
			if from == Online.host_id and not _host:
				_waited = 0.0
				_glide_to(payload)
		"mini_absent":
			if from == Online.host_id and not _host:
				var side := int(payload.get("side", -1))
				if side in [0, 1]:
					_drop(side)
		"mini_end":
			if from == Online.host_id and not _host and _result == -2:
				_ended = true
				game.active = false
				_result = int(payload.get("winner", Minigame.DRAW))
				round_ended.emit(_result)


# ---- the others' side ----

# Carries the snapshot forward by the one-way trip, then moves the game most of the way to it, or all
# of the way where it is far off.
func _glide_to(msg: Dictionary) -> void:
	if not _running:
		return
	var target: Dictionary = msg.g
	var ahead := maxf(rtt, 0.0) / 2000.0 if local_side >= 0 else spectator_lag
	for pair in game.blend_pairs():
		target[pair[0]] = _carry(target[pair[0]], target[pair[1]], ahead)
	var mine := game.get_state()
	var keys: Array = game.blend_keys()
	for pair in game.blend_pairs():
		keys.append(pair[0])
	var off := 0.0
	for key in keys:
		off = maxf(off, _distance(mine[key], target[key]))
	var t := GLIDE if off <= game.snap_distance() else 1.0
	for key in keys:
		target[key] = _lerp_any(mine[key], target[key], t)
	game.set_state(target)
	if not _ended:
		game.active = not bool(msg.over) # the host's word on whether the round is still on


static func _carry(pos: Variant, vel: Variant, seconds: float) -> Variant:
	if pos is Array and vel is Array:
		var out := []
		for i in pos.size():
			out.append(_carry(pos[i], vel[i], seconds))
		return out
	return float(pos) + float(vel) * seconds


static func _distance(a: Variant, b: Variant) -> float:
	if a is Array and b is Array:
		var worst := 0.0
		for i in mini(a.size(), b.size()):
			worst = maxf(worst, _distance(a[i], b[i]))
		return worst
	return absf(float(a) - float(b))


static func _lerp_any(a: Variant, b: Variant, t: float) -> Variant:
	if a is Array and b is Array:
		var out := []
		for i in mini(a.size(), b.size()):
			out.append(_lerp_any(a[i], b[i], t))
		return out
	return lerpf(float(a), float(b), t)


# ---- the small online extras ----

func _name_of(id: int) -> String:
	for key in Net.id_by_name:
		if int(Net.id_by_name[key]) == id:
			return key
	return "?"


func _say(text: String) -> void:
	_banner = text


func _draw() -> void:
	if local_side >= 0 and rtt >= 0.0 or local_side >= 0 and _host:
		var ms := 0.0 if _host else rtt
		var color := Color("5fbf6a") if ms < 80.0 else (Color("e8c547") if ms < 160.0 else Color("d9534f"))
		draw_circle(Vector2(1860, 48), 17.0, INK)
		draw_circle(Vector2(1860, 48), 12.0, color)
	if local_side < 0:
		var font: Font = MinigameFrame.DISPLAY
		var text := tr("MINI_WATCHING")
		draw_rect(Rect2(840, 22, 240, 54), INK)
		draw_rect(Rect2(844, 26, 232, 46), CREAM)
		draw_string(font, Vector2(844, 61), text, HORIZONTAL_ALIGNMENT_CENTER, 232.0, 34, INK)
	if _banner_a > 0.0 and _banner != "":
		var font: Font = MinigameFrame.DISPLAY
		draw_rect(Rect2(660, 470, 600, 100), Color(INK, _banner_a))
		draw_rect(Rect2(666, 476, 588, 88), Color(CREAM, _banner_a))
		draw_string(font, Vector2(666, 536), _banner, HORIZONTAL_ALIGNMENT_CENTER, 588.0, 40, Color(INK, _banner_a))
