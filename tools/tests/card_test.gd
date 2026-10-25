extends Node
## Part 48, headless: godot --headless res://tools/tests/card_test.tscn
## A portrait click opens one power card, a second click closes it, another portrait's click swaps
## it, and a Countdown reaches 0 once and fires timed_out.

var failed := 0
var checked := 0
var _out := 0


func _ready() -> void:
	Match.start(["A", "B", "C"] as Array[String])
	for i in 3:
		Match.players[i].monster = Monsters.IDS[i]
	var hud := Hud.new()
	add_child(hud)
	await get_tree().process_frame
	var a: HudPortrait = hud.portrait_node(Match.players[0])
	var b: HudPortrait = hud.portrait_node(Match.players[1])
	a.inspected.emit()
	_ok(_cards(hud) == 1, "one card after a click")
	a.inspected.emit()
	await get_tree().create_timer(0.5).timeout
	_ok(_cards(hud) == 0, "the second click closes it")
	a.inspected.emit()
	b.inspected.emit()
	await get_tree().create_timer(0.5).timeout
	_ok(_cards(hud) == 1, "another portrait swaps the card")
	var card: PowerCard = hud.get_children().filter(func(n: Node) -> bool: return n is PowerCard)[0]
	_ok(card.player.monster == "medusa", "the card is Medusa's")
	for id in Monsters.IDS:
		_ok(tr("POWER_LONG_" + id.to_upper()) != "POWER_LONG_" + id.to_upper(), "long power for " + id)
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	card._unhandled_input(escape)
	await get_tree().create_timer(0.5).timeout
	_ok(_cards(hud) == 0, "Esc closes it")
	var count := Countdown.new()
	add_child(count)
	count.timed_out.connect(func() -> void: _out += 1)
	count.start(1.0)
	await get_tree().create_timer(1.4).timeout
	_ok(_out == 1 and count.time_left == 0.0 and not count.running, "the countdown ends once")
	count.start(5.0)
	count.stop()
	await get_tree().create_timer(0.3).timeout
	_ok(_out == 1 and count.time_left > 4.0, "stop is silent")
	print("card_test: %d checks, " % checked, "FAILED %d" % failed if failed else "all passed")
	get_tree().quit(1 if failed else 0)


func _cards(hud: Hud) -> int:
	return hud.get_children().filter(func(n: Node) -> bool: return n is PowerCard and not n._closing).size()


func _ok(cond: bool, what: String) -> void:
	checked += 1
	if not cond:
		failed += 1
		print("FAIL: ", what)
