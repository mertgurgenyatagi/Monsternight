extends Node
## Plays every sound: effects by name, and the music and ambience loops, crossfaded.

const FADE := 1.5
const PITCH_JITTER := 0.05
const VOICES := 8
const DUCK_DB := -16.0 # how far a sting pushes the music down

## A nudge in dB for the sounds whose files sit well above or below the rest (part 23's loudness
## pass, by mean level; the files stay as they are). Untested by ear.
const TRIM := {
	"blood_gain": 1.0,
	"blood_lose": -1.0,
	"card_slam": 1.5,
	"coin_flip": 2.5,
	"coin_gain": 1.0,
	"coin_lose": 1.0,
	"countdown": -2.5,
	"countdown_go": 1.0,
	"die_land": -3.0,
	"drumroll": -2.0,
	"flip": -1.0,
	"fly": 1.0,
	"hop_1": -3.0,
	"hop_2": -3.0,
	"hop_3": -2.5,
	"respawn": -2.5,
	"spikes": 2.0,
	"stat": -1.0,
	"timer_low": 1.5,
	"timer_out": -1.0,
	"ui_click": 1.0,
	"ui_hover": -7.0,
	"voices/cthulhu_lose": -2.0,
	"voices/cthulhu_pick": -3.0,
	"voices/cthulhu_win": -3.0,
	"voices/death_lose": -2.0,
	"voices/death_win": 1.5,
	"voices/dorian_lose": 1.0,
	"voices/dorian_pick": 2.0,
	"voices/dorian_win": 2.0,
	"voices/dracula_lose": 1.0,
	"voices/dracula_win": 2.5,
	"voices/frankenstein_lose": -2.5,
	"voices/frankenstein_pick": -2.5,
	"voices/hyde_lose": -2.0,
	"voices/hyde_win": 2.0,
	"voices/medusa_pick": 1.0,
	"voices/medusa_win": 2.0,
	"voices/wolfman_lose": 1.0,
	"voices/wolfman_pick": -1.5,
}

var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _last_hop := 0
var _streams := {}
var _music: Array[AudioStreamPlayer] = []
var _ambience: Array[AudioStreamPlayer] = []
var _music_name := ""
var _ambience_name := ""
var _duck_effect: AudioEffectAmplify
var _duck_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	for i in VOICES:
		_voices.append(_player("SFX"))
	_music = [_player("Music"), _player("Music")]
	_ambience = [_player("SFX"), _player("SFX")]


# Closing the window stops every player first and quits a moment later: a stream still
# playing when the game ends is reported as leaked.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()


## Stops every sound, then quits the game.
func quit() -> void:
	for player in _voices + _music + _ambience:
		player.stop()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()


## Plays an effect from assets/audio/sfx, or from another folder if the name has one
## ("voices/dracula_pick"). Each play is pitched slightly differently, and "hop" picks one of
## the three hops, never the one before.
func play(sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	if sound == "hop":
		# Never the same hop twice in a row.
		_last_hop = (_last_hop + randi_range(0, 1)) % 3 + 1
		sound = "hop_%d" % _last_hop
	var player := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	player.stream = _stream(sound if "/" in sound else "sfx/" + sound)
	player.volume_db = volume_db + TRIM.get(sound, 0.0)
	player.pitch_scale = pitch * randf_range(1.0 - PITCH_JITTER, 1.0 + PITCH_JITTER)
	player.play()


## Plays a sting, a short piece of music, over the board's track, which ducks for `length` seconds and
## comes back. A missing file plays as silence, because the music arrives later (the music still ducks).
func sting(sound: String, length := 3.0) -> void:
	if ResourceLoader.exists(_path("sfx/" + sound)):
		play(sound)
	_duck(length)


## Crossfades to a track in assets/audio/music. Asking for the track that's already playing
## changes nothing, and "" fades the music out. A missing file plays as silence, because the
## music arrives later.
func play_music(track: String) -> void:
	if track == _music_name:
		return
	_music_name = track
	_crossfade(_music, "music/" + track if track else "")


## Crossfades to a loop in assets/audio/ambience, or fades it out with "".
func play_ambience(loop: String) -> void:
	if loop == _ambience_name:
		return
	_ambience_name = loop
	_crossfade(_ambience, "ambience/" + loop if loop else "")


# The music bus gets quieter for `length` seconds, through an effect of its own, so neither the volume
# setting nor a crossfade is in the way.
func _duck(length: float) -> void:
	if _duck_effect == null:
		_duck_effect = AudioEffectAmplify.new()
		AudioServer.add_bus_effect(AudioServer.get_bus_index("Music"), _duck_effect)
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_duck_effect, "volume_db", DUCK_DB, 0.2)
	_duck_tween.tween_interval(length)
	_duck_tween.tween_property(_duck_effect, "volume_db", 0.0, 0.8)


func _crossfade(pair: Array[AudioStreamPlayer], sound: String) -> void:
	var old := pair[0]
	var new := pair[1]
	pair.reverse()
	_fade(old, 0.0)
	if sound and ResourceLoader.exists(_path(sound)):
		var stream: AudioStreamOggVorbis = _stream(sound)
		stream.loop = true
		new.stream = stream
		new.volume_linear = 0.0
		new.play()
		_fade(new, 1.0)


func _fade(player: AudioStreamPlayer, to: float) -> void:
	if player.has_meta("fade"):
		var old: Tween = player.get_meta("fade")
		if old.is_valid():
			old.kill()
	if not player.playing:
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_linear", to, FADE)
	if to == 0.0:
		tween.tween_callback(player.stop)
	player.set_meta("fade", tween)


func _stream(sound: String) -> AudioStream:
	if sound not in _streams:
		_streams[sound] = load(_path(sound))
	return _streams[sound]


func _path(sound: String) -> String:
	return "res://assets/audio/%s.ogg" % sound


func _player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player
