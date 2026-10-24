extends Node
## Online play's decisions. Every copy of a started match runs the same board code on the same
## `Match`, so the only things that must come from one place are the choices: the die's face, a
## path, an opponent and a stake, a monster, a minigame's winner. The host is that place. A decision
## is one `decide` call, made at the same point of the code on every copy and numbered by a counter
## that therefore agrees: the player it belongs to may `submit` a value (their copy sends it to the
## host), the host checks it against the rules, and its timer picks a random valid choice when the
## time runs out. The host then broadcasts the result and every copy goes on with it. Copies never
## recompute a choice, so they cannot drift apart. Off the web, in "Same screen" mode, `active` is
## false and nothing here is used.

## Something arrived (a submission for the host, a result for the others).
signal _arrived

## Extra seconds the host waits for a remote player's answer, for the trip over the relay.
const GRACE := 1.0

## True while a match started from an online lobby is on.
var active := false
## The host's peer id.
var host_id := 0
## A test bot: this copy answers its own decisions by itself, a moment after they open.
var bot := false

var _seq := 0
var _results := {} # seq -> {kind, value, auto}, waiting for a copy to reach its decide
var _submits := {} # seq -> {from, kind, value}, waiting for the host to reach its decide
var _open := {} # the decision this copy is on: {seq, kind, name, sent}


func _ready() -> void:
	Net.received.connect(_on_received)
	var args := OS.get_cmdline_user_args()
	bot = "--bot" in args or Net.page_param("bot") not in ["", "0"]


## Begins online play for the match the lobby has just started.
func begin(host: int) -> void:
	active = true
	host_id = host
	_seq = 0
	_results.clear()
	_submits.clear()
	_open = {}


## Back to local play.
func stop() -> void:
	active = false
	_open = {}
	_results.clear()
	_submits.clear()
	_arrived.emit()


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
	_open = {"seq": seq, "kind": kind, "name": player.name, "sent": not is_mine(player)}
	var result: Dictionary
	if Net.is_host:
		result = await _host_decides(seq, kind, player, seconds, auto, valid, settle)
		Net.broadcast("decided", {"seq": seq, "kind": kind, "value": result.value, "auto": result.auto})
	else:
		while not _results.has(seq):
			if not active:
				return {"value": null, "auto": true}
			await _arrived
		result = _results[seq]
		_results.erase(seq)
		if result.kind != kind:
			push_error("Online: decision %d is %s here and %s on the host" % [seq, kind, result.kind])
	_open = {}
	return {"value": result.value, "auto": result.auto}


func _host_decides(seq: int, kind: String, player: Dictionary, seconds: float, auto: Callable,
		valid: Callable, settle: Callable) -> Dictionary:
	var wait := seconds + (0.0 if is_mine(player) else GRACE)
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


func _on_received(from: int, kind: String, payload: Dictionary) -> void:
	if not active:
		return
	match kind:
		"submit":
			if Net.is_host and not _submits.has(int(payload.get("seq", 0))):
				_submits[int(payload.get("seq", 0))] = {"from": from, "kind": str(payload.get("kind", "")),
						"value": payload.get("value")}
				_arrived.emit()
		"decided":
			if from == host_id:
				_results[int(payload.get("seq", 0))] = {"kind": str(payload.get("kind", "")),
						"value": payload.get("value"), "auto": bool(payload.get("auto", false))}
				_arrived.emit()
