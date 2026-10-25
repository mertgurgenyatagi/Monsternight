extends Node
## Shot in the Dark's rules, headless: godot --headless res://tools/tests/shot_test.tscn

var failed := 0


func _ready() -> void:
	# judge
	_eq(ShotGame.judge(10.0, 20.0, 12.0), 0, "closest left")
	_eq(ShotGame.judge(10.0, 13.0, 12.0), 1, "closest right")
	_eq(ShotGame.judge(10.0, 14.0, 12.0), ShotGame.DRAW, "equal distance is a draw")
	_eq(ShotGame.judge(null, 5.0, 12.0), 1, "no answer loses")
	_eq(ShotGame.judge(5.0, null, 12.0), 0, "no answer loses (right)")
	_eq(ShotGame.judge(null, null, 12.0), ShotGame.DRAW, "two blanks")
	_eq(ShotGame.judge(8.0, 14.0, 12.0), 1, "plain: 4 off loses to 2 off")
	_eq(ShotGame.judge(8.0, 14.0, 12.0, 0), 1, "Hyde: 4 * 0.8 = 3.2 still loses to 2")
	_eq(ShotGame.judge(-300.0, -273.15 - 40.0, -273.15), 0, "negative and decimal")
	# Hyde: 10 off x0.8 = 8 beats 9 off
	_eq(ShotGame.judge(90.0, 109.0, 100.0, 0), 0, "Hyde's 10 beats 9")
	_eq(ShotGame.judge(90.0, 109.0, 100.0, -1), 1, "without Hyde 10 loses to 9")
	_eq(ShotGame.judge(90.0, 111.0, 100.0, 1), 1, "Hyde only helps as the challenger side given")
	# typing
	_eq(ShotGame.type_key("", "-"), "-", "minus first")
	_eq(ShotGame.type_key("-", "-"), "-", "second minus is refused")
	_eq(ShotGame.type_key("5", "-"), "5", "minus only first")
	_eq(ShotGame.type_key("", "."), "0.", "decimal on empty")
	_eq(ShotGame.type_key("1.5", "."), "1.5", "second decimal refused")
	_eq(ShotGame.type_key("0", "7"), "7", "no leading zero")
	_eq(ShotGame.type_key("-0", "7"), "-7", "no leading zero after minus")
	_eq(ShotGame.type_key("123456789", "1"), "123456789", "digit cap")
	_eq(ShotGame.type_key("12", "back"), "1", "backspace")
	_eq(ShotGame.type_key("", "back"), "", "backspace on empty")
	_eq(ShotGame.value_of(""), null, "blank")
	_eq(ShotGame.value_of("-"), null, "lone minus")
	_eq(ShotGame.value_of("-12.5"), -12.5, "value")
	# format
	Settings.language = "en"
	_eq(Questions.format(8848.0), "8 848", "grouping")
	_eq(Questions.format(-273.15), "−273.15", "decimal minus")
	Settings.language = "tr"
	_eq(Questions.format(40075.0), "40 075", "tr grouping")
	_eq(Questions.format(1234.5), "1 234,5", "tr decimal comma")
	Settings.language = "en"
	# questions
	Questions.load_all()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var asked := {}
	var seen := {}
	for i in 210:
		var q := Questions.pick("atlas", asked, rng)
		if seen.has(q.id):
			_fail("atlas repeated %d" % q.id)
		seen[q.id] = true
		if Questions.group_of(q) != "atlas":
			_fail("wrong group for %d" % q.id)
	var again := Questions.pick("atlas", asked, rng)
	_eq(asked.size(), 1, "a dry group starts over (%d)" % again.id)
	print("shot_test: ", "FAILED %d" % failed if failed else "all passed")
	get_tree().quit(1 if failed else 0)


func _eq(got: Variant, want: Variant, what: String) -> void:
	if got != want:
		_fail("%s: got %s, wanted %s" % [what, got, want])


func _fail(what: String) -> void:
	failed += 1
	print("FAIL ", what)
