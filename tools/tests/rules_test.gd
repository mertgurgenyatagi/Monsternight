extends Node
## Part 47's rules, headless: godot --headless res://tools/tests/rules_test.tscn
## Every stake case for coins and blood on both sides (Death, Cthulhu, Frankenstein included) keeps
## coins and blood conserved, except where Frankenstein's Monster loses as the challenger.

var failed := 0
var checked := 0


func _ready() -> void:
	Match.start(["A", "B", "C"] as Array[String])
	_dice()
	_stakes()
	_turns()
	print("rules_test: %d cases, " % checked, "FAILED %d" % failed if failed else "all passed")
	get_tree().quit(1 if failed else 0)


func _dice() -> void:
	var low := 99
	var high := 0
	for i in 500:
		var d := Match.roll()
		low = mini(low, d[0] + d[1])
		high = maxi(high, d[0] + d[1])
		_ok(d[0] >= 1 and d[0] <= 6 and d[1] >= 1 and d[1] <= 6, "a die is 1 to 6")
	_ok(low >= 2 and high <= 12, "the sum is 2 to 12")
	var forced := Match.roll([3, 6])
	_ok(forced == [3, 6], "forced faces are used")
	var from_json := Match.roll([4.0, 5.0])
	_ok(from_json == [4, 5], "faces that went through JSON are used")
	_ok(Match.roll([0, 9]) != [0, 9], "bad faces are ignored")
	Match.players[0].monster = "wolfman"
	_ok(Match.roll_bonus(Match.players[0]) == 2, "Wolf Man adds 2")
	Match.players[0].monster = ""


func _turns() -> void:
	_ok(Match.TURNS_BY_LOBBY == {3: 11, 4: 10, 5: 9, 6: 8, 7: 8, 8: 7}, "turns by lobby")
	_ok(Duel.swap_wins({"monster": ""}, "swap") == 2, "a swap needs 2 wins")
	_ok(Duel.swap_wins({"monster": "dorian"}, "swap") == 1, "Dorian needs 1")


func _stakes() -> void:
	var monsters := ["", "death", "cthulhu", "frankenstein"]
	for mc in monsters:
		for mo in monsters:
			if mc == mo and mc != "":
				continue
			for bc in range(1, 5):
				for bo in range(1, 5):
					for cc in 2:
						for co in 2:
							for same in 2:
								_case(mc, mo, bc, bo, cc, co, same == 1)


func _make(monster: String, blood: int, coins: int, space: String) -> Dictionary:
	var p := {"name": "x", "monster": monster, "blood": blood, "coins": coins, "space": space,
			"finished": false, "duels_started": 0, "challenged": 0, "duels_won": 0}
	if blood > Match.max_blood(p) or blood < Match.min_blood(p):
		return {}
	return p


func _case(mc: String, mo: String, bc: int, bo: int, cc: int, co: int, same: bool) -> void:
	var probe_c := _make(mc, bc, cc, "a")
	var probe_o := _make(mo, bo, co, "a" if same else "b")
	if probe_c.is_empty() or probe_o.is_empty():
		return
	var offered := Match.stakes(probe_c, probe_o)
	for stake in offered:
		for challenger_wins in [true, false]:
			var c := _make(mc, bc, cc, "a")
			var o := _make(mo, bo, co, "a" if same else "b")
			var winner := c if challenger_wins else o
			var loser := o if challenger_wins else c
			var coins_before: int = c.coins + o.coins
			var blood_before: int = c.blood + o.blood
			var r := Match.duel_result(winner, loser, c, stake)
			checked += 1
			var label := "%s/%s b%d/%d c%d/%d %s %s wins" % [mc, mo, bc, bo, cc, co, stake, "ch" if challenger_wins else "op"]
			var frank_free: bool = not challenger_wins and mc == "frankenstein"
			if frank_free:
				_ok(c.coins + o.coins == coins_before and c.blood + o.blood == blood_before, "free: " + label)
				continue
			_ok(c.coins + o.coins == coins_before, "coins conserved: " + label)
			_ok(c.blood + o.blood == blood_before, "blood conserved: " + label)
			if stake == "gold":
				_ok(r.coins == 1, "the loser really paid: " + label)
			if stake == "blood":
				_ok(r.blood == 1 and r.gain == 1, "blood drained and gained: " + label)
				_ok(not (r.died and loser.coins > 0), "no death match with coins: " + label)
				_ok(winner.blood <= Match.max_blood(winner), "cap held: " + label)
				_ok(not (loser.monster == "death" and r.died), "Death never kills nor dies: " + label)
				_ok(loser.blood >= Match.min_blood(loser), "floor held: " + label)


func _ok(cond: bool, what: String) -> void:
	if not cond:
		failed += 1
		print("FAIL ", what)
