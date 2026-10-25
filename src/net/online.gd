extends Node
## Online play's decisions. Every copy of a started match runs the same board code on the same
## `Match`, so the only things that must come from one place are the choices: the die's face, a
## path, an opponent and a stake, a monster, a question. The host is that place. A decision
## is one `decide` call, made at the same point of the code on every copy and numbered by a counter
## that therefore agrees: the player it belongs to may `submit` a value (their copy sends it to the
## host), the host checks it against the rules, and its timer picks a random valid choice when the
## time runs out. The host then broadcasts the result and every copy goes on with it. Copies never
## recompute a choice, so they cannot drift apart. Off the web, in "Same screen" mode, `active` is
## false and nothing here is used.

## Something arrived (a submission for the host, a result for the others).
signal _arrived

## A player's standing changed: `state` is "" (back to normal), "dropped" (their connection left) or
## "away" (three automatic choices in a row). `name` is the player's.
signal presence_changed(name: String, state: String)
## The host left and this copy is the host now.
signal became_host
## A dropped player came back (their copy has caught up or is catching up).
signal rejoined(name: String)
## The socket is gone for good: the room is closed to this copy.
signal room_lost
## A rejoin did not work: `reason` is "missing", "full", "closed" or "held".
signal rejoin_failed(reason: String)
## The host says the duelist on `side` of the Shot in the Dark of decision `seq` has locked in
## (never the number).
signal shot_status(seq: int, side: int)

## Extra seconds the host waits for a remote player's answer, for the trip over the relay.
const GRACE := 1.0

## Automatic choices in a row before a player is marked away.
const AWAY_AFTER := 3
## The most seconds the host gives a dropped or away player, by kind of decision.
const SHORT_SECONDS := {"roll": 1.0, "branch": 2.0, "opponent": 3.0, "stake": 3.0, "monster": 3.0}
## The least a new host gives the decision it takes over, so the answer the old host's copy had
## already sent can reach it.
const TAKEOVER_MIN := 2.0
## Seconds the host still waits for a Shot in the Dark answer from a duelist who is dropped or away,
## once the present duelist has locked.
const SHOT_DROP_GRACE := 3.0
## How fast a rejoining copy replays the decisions it missed (the engine's time scale).
const CATCH_UP_SPEED := 12.0
## A rejoin asks again this often, this many times, before giving up.
const REJOIN_WAIT := 2.5
const REJOIN_TRIES := 4

## True while a match started from an online lobby is on.
var active := false
## The host's peer id.
var host_id := 0
## A test bot: this copy answers its own decisions by itself, a moment after they open.
var bot := false

var _seq := 0
var _results := {} # seq -> {kind, value, auto}, waiting for a copy to reach its decide
var _submits := {} # seq -> {from, kind, value}, waiting for the host to reach its decide
var _open := {} # the decision this copy is on: {seq, kind, name, sent, value, start, seconds}
var _dropped := {} # player name -> true, once their connection left
var _autos := {} # player name -> automatic choices in a row
var _away := {} # player name -> true
var _log: Array = [] # every decision and Shot in the Dark so far, in order: a rejoiner replays it
var _replay := {} # while catching up: seq -> the logged decision or shot
var _shot := {} # the Shot in the Dark this copy is on: {seq, names, seconds, start, mine}
var _shot_locks := {} # host: seq -> the locks that came in, [{from, side, value}]
var _shot_results := {} # seq -> {a, b}, the host's reveal waiting for a copy to reach its shot
var _shot_marks := {} # seq -> [bool, bool], who the host said has locked
var _replay_total := 0
var _replay_done := 0
var _rejoin_name := ""
var _rejoin_tries := 0
var _rejoin_id := 0 # counts attempts, so a stale wait does nothing
var _curtain: CatchUpCurtain

## True while this copy replays what it missed, at speed and without sound, behind the curtain.
var catching_up := false


func _ready() -> void:
	Net.received.connect(_on_received)
	Net.peer_left.connect(_on_peer_left)
	Net.host_changed.connect(_on_host_changed)
	Net.connected.connect(_on_connected)
	Net.refused.connect(_on_refused)
	Net.disconnected.connect(_on_disconnected)
	bot = Net.debug_value("bot") not in ["", "0"]


## Begins online play for the match the lobby has just started.
func begin(host: int, seed := 0, names: Array = []) -> void:
	active = true
	host_id = host
	match_seed = seed
	match_names = names
	_seq = 0
	_results.clear()
	_submits.clear()
	_open = {}
	_dropped.clear()
	_autos.clear()
	_away.clear()
	_log.clear()
	_replay.clear()
	_shot = {}
	_shot_locks.clear()
	_shot_results.clear()
	_shot_marks.clear()
	_remember()


## Set before going back to the lobby after a match, so the lobby keeps the room and its seats.
var back_to_room := false


## Leaves the match and the room for good: the others see a dropped player.
func leave_match() -> void:
	Match.reset()
	stop()
	Net.leave()


## Back to local play.
func stop() -> void:
	_end_catch_up()
	_rejoin_name = ""
	_forget()
	active = false
	_open = {}
	_results.clear()
	_submits.clear()
	_shot = {}
	_arrived.emit()


## "dropped" for a player whose connection left, "away" for one who has let the timers play three
## choices in a row, otherwise "".
func status(player_name: String) -> String:
	if _dropped.has(player_name):
		return "dropped"
	return "away" if _away.has(player_name) else ""


## True when this copy is the one that decides for `player`. Always true in local play.
func is_mine(player: Dictionary) -> bool:
	return not active or int(Net.id_by_name.get(player.name, -1)) == Net.my_id


## True while this copy has a decision open for a player it plays for and has not answered it.
func can_submit() -> bool:
	return active and not _open.is_empty() and not _open.sent


## The player's answer to the decision that is open, from the choice UI. The host answers itself
## directly; everyone else sends it to the host. Only the first answer counts.
func submit(value: Variant) -> void:
	if not can_submit():
		return
	_open.sent = true
	_open.value = value
	if Net.is_host:
		_submits[_open.seq] = {"from": Net.my_id, "kind": _open.kind, "value": value}
		_arrived.emit()
	else:
		Net.send(host_id, "submit", {"seq": _open.seq, "kind": _open.kind, "value": value})


## One decision, `kind`, belonging to `player`. Call it at the same point on every copy. Gives
## `{value, auto}`, `auto` meaning the time ran out (or `seconds` was 0) and the host chose.
## `auto` gives the random valid value, `valid` says whether a submitted value is allowed, and
## `settle` turns the chosen value into the one that is broadcast (for example adding the die's
## face). The last three only run on the host.
func decide(kind: String, player: Dictionary, seconds: float, auto: Callable,
		valid := Callable(), settle := Callable()) -> Dictionary:
	_seq += 1
	var seq := _seq
	if catching_up:
		if _replay.has(seq) and _replay[seq].k == "d":
			return _replayed(seq, kind, player, seconds)
		_end_catch_up() # the log has run out: this decision is live
	_open = {"seq": seq, "kind": kind, "name": player.name, "sent": not is_mine(player),
			"start": Time.get_ticks_msec(), "seconds": seconds}
	var result: Dictionary
	var promoted := false
	if not Net.is_host:
		while not _results.has(seq) and not Net.is_host:
			if not active:
				return {"value": null, "auto": true}
			await _arrived
		promoted = Net.is_host and not _results.has(seq)
	if Net.is_host:
		var left := seconds
		if promoted and seconds > 0.0: # took over a decision that is already running
			left = maxf(seconds - (Time.get_ticks_msec() - _open.start) / 1000.0, TAKEOVER_MIN)
		result = await _host_decides(seq, kind, player, left, auto, valid, settle)
		Net.broadcast("decided", {"seq": seq, "kind": kind, "value": result.value, "auto": result.auto})
	else:
		result = _results[seq]
		_results.erase(seq)
		if result.kind != kind:
			push_error("Online: decision %d is %s here and %s on the host" % [seq, kind, result.kind])
	_open = {}
	_log.append({"k": "d", "seq": seq, "kind": kind, "value": result.value, "auto": result.auto})
	_note_choice(player.name, seconds > 0.0, result.auto)
	return {"value": result.value, "auto": result.auto}


func _host_decides(seq: int, kind: String, player: Dictionary, seconds: float, auto: Callable,
		valid: Callable, settle: Callable) -> Dictionary:
	if SHORT_SECONDS.has(kind) and status(player.name) != "":
		seconds = minf(seconds, SHORT_SECONDS[kind])
	var wait := seconds + (0.0 if is_mine(player) or status(player.name) != "" else GRACE)
	var deadline := Time.get_ticks_msec() + wait * 1000.0
	if bot and is_mine(player) and seconds > 0.0:
		_bot_answers(seq, kind, auto)
	var chosen: Dictionary = {}
	while chosen.is_empty():
		if _submits.has(seq):
			var sent: Dictionary = _submits[seq]
			_submits.erase(seq)
			if _acceptable(sent, kind, player, valid):
				chosen = {"value": sent.value, "auto": false}
				continue
		if seconds <= 0.0 or Time.get_ticks_msec() >= deadline or not active:
			chosen = {"value": auto.call(), "auto": true}
			continue
		await get_tree().process_frame
	if settle.is_valid():
		chosen.value = settle.call(chosen.value)
	return chosen


# A submission counts when it came from the player's own copy, for this very decision, and the
# rules allow its value.
func _acceptable(sent: Dictionary, kind: String, player: Dictionary, valid: Callable) -> bool:
	if sent.kind != kind or int(sent.from) != int(Net.id_by_name.get(player.name, -1)):
		return false
	return not valid.is_valid() or valid.call(sent.value)


# A test copy answers by itself after a short pause, with what the timer would have picked.
func _bot_answers(seq: int, kind: String, auto: Callable) -> void:
	await get_tree().create_timer(0.8, false).timeout
	if _open.get("seq", 0) == seq and can_submit():
		print("Bot answers ", kind)
		submit(auto.call())


# Counts the player's automatic choices in a row; the same on every copy, because every copy sees
# the same results.
func _note_choice(player_name: String, counts: bool, auto: bool) -> void:
	if not counts:
		return
	if not auto:
		_autos[player_name] = 0
		if _away.erase(player_name) and not _dropped.has(player_name) and not catching_up:
			presence_changed.emit(player_name, "")
		return
	_autos[player_name] = int(_autos.get(player_name, 0)) + 1
	if _autos[player_name] >= AWAY_AFTER and not _away.has(player_name):
		_away[player_name] = true
		if not _dropped.has(player_name) and not catching_up:
			presence_changed.emit(player_name, "away")


## The seed of the match the lobby started, which a rejoiner needs to start the same one.
var match_seed := 0
## The names as the lobby gave them to `Match.start` (the match shuffles its own order from them).
var match_names: Array = []


## One Shot in the Dark: both duelists (`sides`, the challenger first) type a number in secret for
## `seconds`. Call it at the same point on every copy. A duelist's copy sends the lock only to the host
## (`shot_lock`), the host tells everyone who has locked (`shot_status`, no number) and, when both have
## or the clock and its grace run out, sends the reveal (`shot_reveal`) that every copy gets back here as
## `{a, b}` (a number, or null for no answer). A dropped or away duelist does not hold the host up
## for more than `SHOT_DROP_GRACE`.
func shot(sides: Array[Dictionary], seconds: float) -> Dictionary:
	_seq += 1
	var seq := _seq
	if catching_up:
		if _replay.has(seq) and _replay[seq].k == "s":
			return _replayed_shot(seq, sides)
		_end_catch_up()
	_shot = {"seq": seq, "names": [sides[0].name, sides[1].name], "seconds": seconds,
			"start": Time.get_ticks_msec(), "mine": [null, null]}
	var result := {}
	var promoted := false
	if not Net.is_host:
		while not _shot_results.has(seq) and not Net.is_host:
			if not active:
				_shot = {}
				return {"a": null, "b": null}
			await _arrived
		promoted = Net.is_host and not _shot_results.has(seq)
	if Net.is_host:
		var left := seconds
		if promoted:
			left = maxf(seconds - (Time.get_ticks_msec() - _shot.start) / 1000.0, TAKEOVER_MIN)
		result = await _host_shot(seq, sides, left)
		Net.broadcast("shot_reveal", {"seq": seq, "a": result.a, "b": result.b})
	else:
		result = _shot_results[seq]
		_shot_results.erase(seq)
	_shot = {}
	_shot_locks.erase(seq)
	_shot_marks.erase(seq)
	_log.append({"k": "s", "seq": seq, "a": result.a, "b": result.b})
	_note_shot(sides, result)
	return {"a": result.a, "b": result.b}


## What the host tells everyone when a duelist locks: who, never the number.
static func shot_status_payload(seq: int, side: int) -> Dictionary:
	return {"seq": seq, "side": side}


## This copy's duelist on `side` locks in `value`. Only the host learns it.
func shot_lock(side: int, value: float) -> void:
	if _shot.is_empty() or _shot.mine[side] != null:
		return
	_shot.mine[side] = value
	_send_lock(side, value)


## True once the host has said (or this copy knows) that `side` of the open shot has locked.
func shot_marked(side: int) -> bool:
	return not _shot.is_empty() and _shot_marks.get(_shot.seq, [false, false])[side]


func _send_lock(side: int, value: float) -> void:
	if Net.is_host:
		_add_lock({"from": Net.my_id, "seq": _shot.seq, "side": side, "value": value})
	else:
		Net.send(host_id, "shot_lock", {"seq": _shot.seq, "side": side, "value": value})


func _add_lock(entry: Dictionary) -> void:
	var seq := int(entry.seq)
	entry.erase("seq")
	if not _shot_locks.has(seq):
		_shot_locks[seq] = []
	_shot_locks[seq].append(entry)


func _mark(seq: int, side: int) -> void:
	if not _shot_marks.has(seq):
		_shot_marks[seq] = [false, false]
	if not _shot_marks[seq][side]:
		_shot_marks[seq][side] = true
		shot_status.emit(seq, side)


func _host_shot(seq: int, sides: Array[Dictionary], seconds: float) -> Dictionary:
	var values: Array = [null, null]
	var locked: Array = [false, false]
	var deadline := Time.get_ticks_msec() + (seconds + GRACE) * 1000.0
	var drop_end := -1.0
	while active:
		for entry: Dictionary in _shot_locks.get(seq, []):
			var side := int(entry.get("side", -1))
			var value: Variant = entry.get("value")
			if side < 0 or side > 1 or locked[side] or int(entry.from) != int(Net.id_by_name.get(sides[side].name, -1)):
				continue # not that duelist's own lock
			if not (value is float or value is int) or not is_finite(float(value)):
				continue
			locked[side] = true
			values[side] = float(value)
			_mark(seq, side)
			Net.broadcast("shot_status", shot_status_payload(seq, side))
		_shot_locks.erase(seq)
		if locked[0] and locked[1]:
			break
		var held := false # a present duelist has not locked yet
		for i in 2:
			if not locked[i] and status(sides[i].name) == "":
				held = true
		var now := Time.get_ticks_msec()
		if not held:
			if drop_end < 0.0:
				drop_end = now + SHOT_DROP_GRACE * 1000.0
			if now >= drop_end:
				break
		if now >= deadline:
			break
		await get_tree().process_frame
	return {"a": values[0], "b": values[1]}


# The same for everyone: each duelist's answer counts as their own choice, a missing one as automatic.
func _note_shot(sides: Array[Dictionary], result: Dictionary) -> void:
	_note_choice(sides[0].name, true, result.a == null)
	_note_choice(sides[1].name, true, result.b == null)


func _replayed_shot(seq: int, sides: Array[Dictionary]) -> Dictionary:
	var entry: Dictionary = _replay[seq]
	_replay.erase(seq)
	_log.append(entry)
	_replay_done += 1
	if _curtain:
		_curtain.progress = _replay_done / float(maxi(_replay_total, 1))
	var result := {"a": entry.a, "b": entry.b}
	_note_shot(sides, result)
	return result


# A decision answered from the log, at once.
func _replayed(seq: int, kind: String, player: Dictionary, seconds: float) -> Dictionary:
	var entry: Dictionary = _replay[seq]
	_replay.erase(seq)
	if entry.kind != kind:
		push_error("Online: decision %d is %s here and %s in the log" % [seq, kind, entry.kind])
	_open = {}
	_log.append(entry)
	_replay_done += 1
	if _curtain:
		_curtain.progress = _replay_done / float(maxi(_replay_total, 1))
	_note_choice(player.name, seconds > 0.0, bool(entry.auto))
	return {"value": entry.value, "auto": bool(entry.auto)}


# The replay is over: normal speed, sound back, the curtain opens on the live turn.
func _end_catch_up() -> void:
	if not catching_up:
		return
	catching_up = false
	Engine.time_scale = 1.0
	AudioServer.set_bus_mute(0, false)
	_replay.clear()
	if _curtain:
		_curtain.open()
		_curtain = null
	var me := _my_name()
	if me != "": # coming back clears this player's standing
		_autos[me] = 0
		_away.erase(me)
	for player_name: String in _away: # the standings held back during the replay
		if not _dropped.has(player_name):
			presence_changed.emit(player_name, "away")
	for player_name: String in _dropped:
		presence_changed.emit(player_name, "dropped")


func _my_name() -> String:
	for player_name: String in Net.id_by_name:
		if int(Net.id_by_name[player_name]) == Net.my_id:
			return player_name
	return ""


## Asks to come back to the match in room `room` as `player_name` (a reloaded tab). The host sends
## the log; `rejoin_failed` says why if it cannot.
func start_rejoin(room: String, player_name: String) -> void:
	_rejoin_name = player_name
	_rejoin_tries = 0
	_rejoin_id += 1
	if not Net.open_room(room, true):
		_give_up("closed")


## The room and name a reloaded tab can rejoin as ("" for both when there is none).
func saved_seat() -> Dictionary:
	if not OS.has_feature("web"):
		return {"room": "", "name": ""}
	var room = JavaScriptBridge.eval("sessionStorage.getItem('mn_room') || ''")
	var player_name = JavaScriptBridge.eval("sessionStorage.getItem('mn_name') || ''")
	return {"room": str(room), "name": str(player_name)}


# The tab's sessionStorage keeps the room and the name, so a reload can offer "Rejoin".
func _remember() -> void:
	var me := _my_name()
	if OS.has_feature("web") and Net.is_online() and me != "":
		JavaScriptBridge.eval("sessionStorage.setItem('mn_room', %s); sessionStorage.setItem('mn_name', %s)"
				% [JSON.stringify(Net.code), JSON.stringify(me)])


func _forget() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("sessionStorage.removeItem('mn_room'); sessionStorage.removeItem('mn_name')")


func _give_up(reason: String) -> void:
	_rejoin_name = ""
	_rejoin_id += 1
	Net.leave()
	_forget()
	rejoin_failed.emit(reason)


func _on_connected() -> void:
	if _rejoin_name != "":
		_ask_to_rejoin()


# One ask, then a wait: the host may not have seen the old socket go yet, so it asks again.
func _ask_to_rejoin() -> void:
	_rejoin_tries += 1
	var attempt := _rejoin_id
	Net.broadcast("rejoin", {"name": _rejoin_name})
	await get_tree().create_timer(REJOIN_WAIT, true, false, true).timeout
	if attempt != _rejoin_id or _rejoin_name == "":
		return
	if _rejoin_tries >= REJOIN_TRIES:
		_give_up("held")
	else:
		_ask_to_rejoin()


func _on_refused(reason: String) -> void:
	if _rejoin_name != "":
		_give_up(reason)


func _on_disconnected() -> void:
	if active:
		room_lost.emit()


# The host's side of a rejoin: the name must be a player of this match whose old socket is gone.
func _host_handles_rejoin(from: int, player_name: String) -> void:
	var old := int(Net.id_by_name.get(player_name, -1))
	if old < 0 or old == Net.my_id or (old != from and old in Net.peers):
		return # the rejoiner asks again; the old socket may just not have been noticed yet
	Net.id_by_name[player_name] = from
	_dropped.erase(player_name)
	_autos[player_name] = 0
	_away.erase(player_name)
	var names := match_names
	var ids: Array = names.map(func(n: String) -> int: return int(Net.id_by_name.get(n, 0)))
	Net.broadcast("rejoined", {"name": player_name, "id": from})
	Net.send(from, "resume", {"names": names, "ids": ids, "seed": match_seed, "host": Net.my_id,
			"log": _log, "dropped": _dropped.keys()})
	presence_changed.emit(player_name, "")
	rejoined.emit(player_name)


# The host said this copy may come back: start the same match and replay the log.
func _on_resume(payload: Dictionary) -> void:
	if _rejoin_name == "" or active:
		return
	_rejoin_name = ""
	_rejoin_id += 1
	var names: Array[String] = []
	for n in payload.get("names", []):
		names.append(str(n))
	var seed := int(payload.get("seed", 0))
	if not Match.start(names, seed):
		_give_up("closed")
		return
	Net.id_by_name.clear()
	var ids: Array = payload.get("ids", [])
	for i in names.size():
		Net.id_by_name[names[i]] = int(ids[i])
	begin(int(payload.get("host", 0)), seed, names)
	for player_name in payload.get("dropped", []):
		_dropped[str(player_name)] = true
	for entry: Dictionary in payload.get("log", []):
		if entry.k == "d":
			_replay[int(entry.seq)] = {"k": "d", "seq": int(entry.seq), "kind": str(entry.kind),
					"value": entry.value, "auto": bool(entry.auto)}
		else:
			_replay[int(entry.seq)] = {"k": "s", "seq": int(entry.seq), "a": entry.a, "b": entry.b}
	_replay_total = _replay.size()
	_replay_done = 0
	if not _replay.is_empty():
		catching_up = true
		AudioServer.set_bus_mute(0, true)
		Engine.time_scale = CATCH_UP_SPEED
		_curtain = CatchUpCurtain.new()
		get_tree().root.add_child(_curtain)
	Scenes.change_to("res://src/pregame/pregame.tscn")


func _on_peer_left(id: int) -> void:
	if not active:
		return
	for player_name: String in Net.id_by_name:
		if int(Net.id_by_name[player_name]) == id and not _dropped.has(player_name):
			_dropped[player_name] = true
			presence_changed.emit(player_name, "dropped")
	_arrived.emit()


# The relay named a new host. Every copy follows it; if it is this one, the decision that is open
# becomes this copy's to time, and answers that went to the old host are given again.
func _on_host_changed(id: int) -> void:
	if not active:
		return
	host_id = id
	if not _open.is_empty() and _open.sent and _open.has("value") and is_mine({"name": _open.name}):
		if Net.is_host:
			_submits[_open.seq] = {"from": Net.my_id, "kind": _open.kind, "value": _open.value}
		else:
			Net.send(host_id, "submit", {"seq": _open.seq, "kind": _open.kind, "value": _open.value})
	if not _shot.is_empty(): # the answers that went to the old host are given again
		for side in 2:
			if _shot.mine[side] != null:
				_send_lock(side, _shot.mine[side])
	if Net.is_host:
		became_host.emit()
	_arrived.emit()


func _on_received(from: int, kind: String, payload: Dictionary) -> void:
	if kind == "resume": # the one message a copy that is not in the match yet can get
		_on_resume(payload)
		return
	if not active:
		return
	match kind:
		"rejoin":
			if Net.is_host:
				_host_handles_rejoin(from, str(payload.get("name", "")))
		"rejoined":
			var player_name := str(payload.get("name", ""))
			if from == host_id and not Net.is_host and Net.id_by_name.has(player_name):
				Net.id_by_name[player_name] = int(payload.get("id", 0))
				_dropped.erase(player_name)
				_autos[player_name] = 0
				_away.erase(player_name)
				if not catching_up:
					presence_changed.emit(player_name, "")
					rejoined.emit(player_name)
		"submit":
			if Net.is_host and not _submits.has(int(payload.get("seq", 0))):
				_submits[int(payload.get("seq", 0))] = {"from": from, "kind": str(payload.get("kind", "")),
						"value": payload.get("value")}
				_arrived.emit()
		"shot_lock":
			if Net.is_host:
				_add_lock({"from": from, "seq": int(payload.get("seq", 0)), "side": int(payload.get("side", -1)),
						"value": payload.get("value")})
		"shot_status":
			if from == host_id and not Net.is_host:
				_mark(int(payload.get("seq", 0)), clampi(int(payload.get("side", 0)), 0, 1))
		"shot_reveal":
			if from == host_id and not Net.is_host:
				var a: Variant = payload.get("a")
				var b: Variant = payload.get("b")
				_shot_results[int(payload.get("seq", 0))] = {"a": null if a == null else float(a),
						"b": null if b == null else float(b)}
				_arrived.emit()
		"decided":
			if from == host_id:
				_results[int(payload.get("seq", 0))] = {"kind": str(payload.get("kind", "")),
						"value": payload.get("value"), "auto": bool(payload.get("auto", false))}
				_arrived.emit()
