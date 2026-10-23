extends Node
## Plays every sound: effects by name, and the music and ambience loops, crossfaded.

const FADE := 1.5
const PITCH_JITTER := 0.05
const VOICES := 8

var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _streams := {}
var _music: Array[AudioStreamPlayer] = []
var _ambience: Array[AudioStreamPlayer] = []
var _music_name := ""
var _ambience_name := ""


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
## the three hops.
func play(sound: String, volume_db := 0.0) -> void:
	if sound == "hop":
		sound = "hop_%d" % randi_range(1, 3)
	var player := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	player.stream = _stream(sound if "/" in sound else "sfx/" + sound)
	player.volume_db = volume_db
	player.pitch_scale = randf_range(1.0 - PITCH_JITTER, 1.0 + PITCH_JITTER)
	player.play()


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
