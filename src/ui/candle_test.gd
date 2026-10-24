extends Node2D
## A small test scene for the candle: it burns for 5 s, goes out, then relights, and prints
## what happens to the log. Run it with `--path . res://src/ui/candle_test.tscn`.

@onready var _candle: Candle = $Candle
var _clock := 0.0
var _round := 0
var _low_logged := false


func _ready() -> void:
	_candle.timed_out.connect(_on_out)
	_candle.start(5.0)
	print("[candle] lit for 5 s")


func _process(delta: float) -> void:
	_clock += delta
	if _candle.burning and _candle.time_left <= Candle.LOW_SECONDS and not _low_logged:
		_low_logged = true
		print("[candle] low at %.2f s in, %.2f s left" % [_clock, _candle.time_left])


func _on_out() -> void:
	print("[candle] timed_out at %.2f s" % _clock)
	_round += 1
	await get_tree().create_timer(1.5).timeout
	if _round < 2:
		_low_logged = false
		_clock = 0.0
		_candle.start(5.0)
		print("[candle] relit")
