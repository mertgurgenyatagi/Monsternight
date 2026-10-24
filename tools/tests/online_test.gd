extends SceneTree
## Headless check of the online decisions (src/net/online.gd). Run from the repository root:
## Godot --headless -s tools/tests/online_test.gd
## The host and the client sides are both played in this one process by feeding `Online` the
## messages the relay would carry.

var _ran := false
var _fails := 0


func _process(_delta: float) -> bool:
	if not _ran:
		_ran = true
		_run()
	return false


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		_fails += 1


func _run() -> void:
	var online: Node = root.get_node("Online")
	var net: Node = root.get_node("Net")
	net.id_by_name = {"Ann": 1, "Bob": 2, "Cy": 3}
	var ann := {"name": "Ann"}
	var bob := {"name": "Bob"}

	# --- the host's side ---
	net.is_host = true
	net.my_id = 1
	online.begin(1)
	# The host's own player answers.
	_later(func() -> void: online.submit("x"), 0.05)
	var r: Dictionary = await online.decide("pick", ann, 1.0, func() -> String: return "auto")
	_check(r.value == "x" and not r.auto, "the host's own answer counts")
	# Bob answers from his own copy.
	_later(func() -> void: online._on_received(2, "submit", {"seq": 2, "kind": "pick", "value": "b"}), 0.05)
	r = await online.decide("pick", bob, 1.0, func() -> String: return "auto")
	_check(r.value == "b" and not r.auto, "a remote player's answer counts")
	# Ann tries to answer for Bob, and a wrong kind; the timer plays instead.
	_later(func() -> void: online._on_received(1, "submit", {"seq": 3, "kind": "pick", "value": "evil"}), 0.05)
	var t := Time.get_ticks_msec()
	r = await online.decide("pick", bob, 0.3, func() -> String: return "auto")
	_check(r.value == "auto" and r.auto, "an answer from the wrong player is ignored, the timer picks")
	_check(Time.get_ticks_msec() - t >= 1200, "a remote player gets a second of grace")
	_later(func() -> void: online._on_received(2, "submit", {"seq": 4, "kind": "other", "value": "z"}), 0.05)
	r = await online.decide("pick", bob, 0.2, func() -> String: return "auto")
	_check(r.auto, "an answer for the wrong decision is ignored")
	# A value the rules refuse.
	_later(func() -> void: online._on_received(2, "submit", {"seq": 5, "kind": "pick", "value": 9}), 0.05)
	r = await online.decide("pick", bob, 0.2, func() -> String: return "auto",
			func(v: Variant) -> bool: return v == 1)
	_check(r.auto, "a value the rules refuse is ignored")
	# Zero seconds is immediate, and settle fills the value.
	r = await online.decide("roll", ann, 0.0, func() -> Dictionary: return {},
			Callable(), func(_v: Variant) -> Dictionary: return {"face": 4})
	_check(r.auto and r.value.face == 4, "zero seconds picks at once; settle adds the face")
	# An answer that came before the host got there waits for it.
	online._on_received(2, "submit", {"seq": 7, "kind": "pick", "value": "early"})
	r = await online.decide("pick", ann, 0.0, func() -> String: return "auto")  # seq 7, but Ann's
	_check(r.auto, "an early answer is kept for its own decision only")

	# --- a client's side ---
	net.is_host = false
	net.my_id = 3
	online.begin(1)
	online._on_received(1, "decided", {"seq": 1, "kind": "roll", "value": {"face": 6}, "auto": false})
	r = await online.decide("roll", ann, 5.0, func() -> Dictionary: return {})
	_check(r.value.face == 6 and not r.auto, "a result that arrived early is used")
	_later(func() -> void: online._on_received(1, "decided", {"seq": 2, "kind": "pick", "value": "m", "auto": true}), 0.05)
	r = await online.decide("pick", ann, 5.0, func() -> String: return "no")
	_check(r.value == "m" and r.auto, "the client waits for the host's result")
	_check(not online.is_mine(ann) and online.is_mine({"name": "Cy"}), "is_mine follows the seat's peer id")
	_check(not online.can_submit(), "no answer is open between decisions")
	# JSON round trip of a result.
	var text: String = net.encode(0, "decided", {"seq": 9, "kind": "roll", "value": {"face": 3}, "auto": true})
	var back: Dictionary = net.decode(JSON.stringify({"t": "msg", "from": 1, "data": JSON.parse_string(text).data}))
	_check(back.kind == "decided" and int(back.payload.value.face) == 3, "a result survives the JSON trip")


	# --- the host leaves ---
	online.begin(1)
	var seen: Array = []
	online.presence_changed.connect(func(n: String, st: String) -> void: seen.append([n, st]))
	var cy := {"name": "Cy"}
	_later(func() -> void:
		online.submit("v") # Cy's answer goes to the old host...
		net.is_host = true # ...which leaves, and the relay names Cy
		online._on_host_changed(3), 0.05)
	t = Time.get_ticks_msec()
	r = await online.decide("pick", cy, 5.0, func() -> String: return "auto")
	_check(r.value == "v" and not r.auto and Time.get_ticks_msec() - t < 1000,
			"an answer sent to a host that left is given again to the new host")
	_check(online.host_id == 3, "everyone follows the new host id")
	# --- a new host takes over a decision nobody has answered ---
	net.is_host = false
	online.begin(1)
	_later(func() -> void:
		net.is_host = true
		online._on_host_changed(3), 0.05)
	t = Time.get_ticks_msec()
	r = await online.decide("pick", ann, 0.3, func() -> String: return "auto")
	_check(r.auto and Time.get_ticks_msec() - t >= 2000, "the new host times the open decision (at least 2 s)")
	# --- dropped and away players ---
	online.begin(3)
	seen.clear()
	online._on_peer_left(2)
	_check(online.status("Bob") == "dropped" and seen == [["Bob", "dropped"]], "a peer that left is dropped")
	t = Time.get_ticks_msec()
	r = await online.decide("roll", bob, 20.0, func() -> Dictionary: return {})
	var took := Time.get_ticks_msec() - t
	_check(r.auto and took < 1600, "a dropped player's roll takes the short timer, no grace (%d ms)" % took)
	seen.clear()
	for i in 3:
		online._note_choice("Dan", true, true)
	_check(online.status("Dan") == "away" and seen == [["Dan", "away"]], "three automatic choices in a row make a player away")
	online._note_choice("Dan", true, false)
	_check(online.status("Dan") == "" and seen.back() == ["Dan", ""], "an answer clears away")
	online._note_choice("Eve", false, true)
	online._note_choice("Eve", false, true)
	online._note_choice("Eve", false, true)
	_check(online.status("Eve") == "", "decisions that need no answer do not count")

	# --- the log and catching up ---
	net.is_host = true
	net.my_id = 1
	online.begin(1, 77)
	await online.decide("roll", ann, 0.0, func() -> Dictionary: return {},
			Callable(), func(_v: Variant) -> Dictionary: return {"face": 5})
	await online.decide("branch", bob, 0.0, func() -> int: return 1)
	online.log_mini(0)
	online.log_mini(-1)
	online.log_mini(1)
	var kept: Array = JSON.parse_string(JSON.stringify(online._log)) # as a rejoiner receives it
	_check(kept.size() == 5 and kept[0].kind == "roll" and kept[2].k == "m", "the host keeps every decision and verdict")
	# A rejoiner's copy: not the host, and every logged decision comes back at once.
	net.is_host = false
	net.my_id = 9
	online.begin(1, 77)
	for entry: Dictionary in kept:
		if entry.k == "d":
			online._replay[int(entry.seq)] = {"k": "d", "seq": int(entry.seq), "kind": str(entry.kind),
					"value": entry.value, "auto": bool(entry.auto)}
		else:
			online._replay_minis.append(int(entry.winner))
	online.catching_up = true
	t = Time.get_ticks_msec()
	r = await online.decide("roll", ann, 20.0, func() -> Dictionary: return {})
	_check(int(r.value.face) == 5 and r.auto and Time.get_ticks_msec() - t < 200, "a logged decision is answered at once")
	_check(online.take_mini() == 0, "the first logged verdict comes back")
	_check(online.take_mini() == -1 and online.take_mini() == 1, "draws and later verdicts follow in order")
	_check(online.catching_up and online.take_mini() == null and not online.catching_up,
			"a spent verdict log ends the catch-up (the round is live)")
	_check(online._log.size() == 4, "the rejoiner replays into its own log")

	online.stop()
	print("FAILS: ", _fails)
	quit(1 if _fails else 0)


func _later(call: Callable, seconds: float) -> void:
	await create_timer(seconds).timeout
	call.call()
