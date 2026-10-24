extends Node
## Headless check of the minigames over the network (src/minigames/mini_link.gd and each game's
## get_state/set_state). Run from the repository root:
## Godot --headless res://tools/tests/minigame_net_test.tscn
## (a scene rather than a -s script, so that the autoloads the games use exist)

var _fails := 0
var _keys := {} # side -> held keys, for the scripted source


func _ready() -> void:
	_run()


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		_fails += 1


func _player(name: String, monster: String) -> Dictionary:
	return {"name": name, "monster": monster}


func _game(kind: String, seed_value: int) -> Minigame:
	var game := Minigames.for_kind(kind)
	game.rng.seed = seed_value
	game.setup(_player("A", "dracula"), _player("B", "medusa"), 0, 0.0)
	game.begin()
	return game


# Held keys by side and tick, in a deterministic mix.
func _script(side: int, key: String, tick: int) -> bool:
	match key:
		"up": return (tick / 40 + side) % 3 == 0
		"down": return (tick / 55 + side) % 4 == 0
		"left": return (tick / 70 + side) % 2 == 0
		"right": return (tick / 70 + side) % 2 == 1
		"action": return tick % (6 + side) < 2
	return false


func _play(game: Minigame, ticks: int, from := 0) -> int:
	var now := [from] # lambdas copy plain variables, so the shared ones live in lists
	MinigameInput.source = func(side: int, key: String) -> bool: return _script(side, key, now[0])
	var winner := [-2]
	game.finished.connect(func(w: int) -> void: winner[0] = w)
	for t in ticks:
		now[0] = from + t
		MinigameInput._stamp = -1
		if game.stepping():
			game.step(1.0 / 60.0)
		else:
			break
	return winner[0]


func _run() -> void:
	var online: Node = get_node("/root/Online")
	var net: Node = get_node("/root/Net")
	net.id_by_name = {"A": 1, "B": 2, "Spec": 3}
	var states := {}
	for kind in ["pong", "tug_of_war", "sumo", "head_soccer"]:
		var a := _game(kind, 77)
		var b := _game(kind, 77)
		var wa := _play(a, 1500)
		var wb := _play(b, 1500)
		_check(wa == wb, "%s: two copies with the same seed and keys end the same (%d)" % [kind, wa])
		_check(JSON.stringify(a.get_state()) == JSON.stringify(b.get_state()), "%s: and in the same state" % kind)
		# the state survives JSON
		var c := _game(kind, 77)
		_play(c, 300)
		var text := JSON.stringify(c.get_state())
		var back: Dictionary = JSON.parse_string(text)
		var d := _game(kind, 77)
		d.set_state(back)
		_check(JSON.stringify(d.get_state()) == text, "%s: get_state/set_state round-trips through JSON" % kind)
		states[kind] = back
	# the seed decides Pong's serve
	var p1 := _game("pong", 1)
	var p2 := _game("pong", 1)
	var p3 := _game("pong", 2)
	_check((p1 as PongGame).velocity == (p2 as PongGame).velocity, "pong: the same seed serves the same way")
	_check((p1 as PongGame).velocity != (p3 as PongGame).velocity, "pong: another seed serves differently")

	# a copy that drifted for 2 s lands near the host after snapshots
	for kind in ["pong", "sumo", "head_soccer"]:
		var host := _game(kind, 5)
		var copy := _game(kind, 5)
		_play(host, 120)
		_play(copy, 120)
		# the copy gets different keys for two seconds
		MinigameInput.source = func(side: int, key: String) -> bool: return key == "down" and side == 1
		for t in 120:
			MinigameInput._stamp = -1
			if copy.stepping():
				copy.step(1.0 / 60.0)
		var link := MiniLink.new()
		add_child(link)
		net.is_host = false
		net.my_id = 3
		online.host_id = 1
		link.setup(copy, [_player("A", "dracula"), _player("B", "medusa")] as Array[Dictionary], 9)
		link._running = true
		link.spectator_lag = 0.0
		var target := (host.get_state() as Dictionary)
		for i in 8:
			link._glide_to({"g": target.duplicate(true), "over": false})
		var near := _gap(copy.get_state(), target, copy)
		_check(near < 6.0, "%s: a drifted copy glides to within a few pixels of the host (%.1f)" % [kind, near])
		link.free()

	# the host ignores keys from a spectator and a verdict from a non-host
	var game := _game("tug_of_war", 3)
	var host_link := MiniLink.new()
	add_child(host_link)
	net.is_host = true
	net.my_id = 1
	online.host_id = 1
	host_link.setup(game, [_player("A", "dracula"), _player("B", "medusa")] as Array[Dictionary], 4)
	host_link._running = true
	host_link._on_received(3, "mini_input", {"r": 4, "keys": 16, "t": 0})
	_check(host_link._plan[0].is_empty() and host_link._plan[1].is_empty(), "the host ignores a spectator's keys")
	host_link._on_received(2, "mini_input", {"r": 4, "keys": 16, "t": 0})
	_check(host_link._plan[1].size() == 1 and host_link._plan[1][0].tick == host_link.tick + MiniLink.LEAD,
			"the host schedules a duelist's keys a few ticks ahead")
	host_link._on_received(2, "mini_input", {"r": 99, "keys": 16, "t": 0})
	_check(host_link._plan[1].size() == 1, "keys for another round are ignored")
	host_link._on_received(2, "mini_end", {"r": 4, "winner": 1})
	_check(host_link._result == -2, "a verdict from a non-host is ignored")
	host_link.free()

	var client_game := _game("tug_of_war", 3)
	var client_link := MiniLink.new()
	add_child(client_link)
	net.is_host = false
	net.my_id = 2
	client_link.setup(client_game, [_player("A", "dracula"), _player("B", "medusa")] as Array[Dictionary], 4)
	client_link._running = true
	client_link._on_received(3, "mini_end", {"r": 4, "winner": 1})
	_check(client_link._result == -2, "a verdict from a spectator is ignored")
	client_link._on_received(1, "mini_end", {"r": 4, "winner": 1})
	_check(client_link._result == 1, "the host's verdict counts")
	_check(client_link.local_side == 1, "a duelist knows its side")
	client_link.free()
	MinigameInput.source = Callable()
	print("FAILS: ", _fails)
	get_tree().quit(1 if _fails else 0)


# The worst gap between two snapshots over the position keys.
func _gap(a: Dictionary, b: Dictionary, game: Minigame) -> float:
	var keys: Array = game.blend_keys()
	for pair in game.blend_pairs():
		keys.append(pair[0])
	var worst := 0.0
	for key in keys:
		worst = maxf(worst, MiniLink._distance(a[key], b[key]))
	return worst
