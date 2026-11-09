extends Node
## Suoni del gioco: musica, ambiente, effetti e suoni posizionati nella stanza.

var _cache := {}
var _pool: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var amb: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _heart_on := false
var _heart_t := 0.0
var heart_rate := 1.1
var _music_name := "music_drone"      # musica del luogo (la foresta ha la sua)

# impostazioni audio scelte dal giocatore (0..1), salvate in user://audio.cfg
const AUDIO_CFG := "user://audio.cfg"
var audio_on := true             # interruttore generale (anche col tasto M in partita)
var master_vol := 1.0
var music_on := true
var music_vol := 0.8
var amb_vol := 0.8
var sfx_vol := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bus("Music", -9.0, false)
	_bus("Amb", -8.0, false)
	_bus("SFX", -2.0, true)
	for i in 14:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	add_child(music)
	amb = AudioStreamPlayer.new()
	amb.bus = "Amb"
	add_child(amb)
	_heart = AudioStreamPlayer.new()
	_heart.bus = "SFX"
	add_child(_heart)
	_load_settings()
	_apply_settings()


func _bus(name: String, db: float, reverb: bool) -> void:
	if AudioServer.get_bus_index(name) >= 0:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, name)
	AudioServer.set_bus_volume_db(i, db)
	AudioServer.set_bus_send(i, "Master")
	if reverb:
		var r := AudioEffectReverb.new()
		r.room_size = 0.55
		r.damping = 0.6
		r.wet = 0.18
		r.dry = 0.95
		AudioServer.add_bus_effect(i, r)


func stream(name: String) -> AudioStream:
	if not _cache.has(name):
		_cache[name] = load("res://audio/%s.wav" % name)
	return _cache[name]


func play(name: String, db := 0.0, pitch := 1.0) -> void:
	for p in _pool:
		if not p.playing:
			p.stream = stream(name)
			p.volume_db = db
			p.pitch_scale = pitch
			p.play()
			return


## Suono che arriva da un punto preciso della stanza (per sentire chi imbroglia al buio).
func play_at(name: String, pos: Vector3, db := 0.0, parent: Node = null) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream(name)
	p.volume_db = db
	p.bus = "SFX"
	p.unit_size = 2.5
	p.pitch_scale = randf_range(0.92, 1.08)
	var host: Node = parent if parent else get_tree().current_scene
	host.add_child(p)
	p.global_position = pos
	p.play()
	p.finished.connect(p.queue_free)


## Cambia la musica secondo il luogo; si ripete senza fine.
func place_music(name: String) -> void:
	if name == _music_name:
		return
	_music_name = name
	if music_on:
		music.stream = _looped(name)
		music.play()


func _looped(name: String) -> AudioStream:
	var st := stream(name)
	if st is AudioStreamWAV and (st as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED:
		var w := (st as AudioStreamWAV).duplicate() as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
		_cache[name] = w
		return w
	return st


func start_loops() -> void:
	if music_on and not music.playing:
		music.stream = _looped(_music_name)
		music.play()
	if not amb.playing:
		amb.stream = stream("amb_cerchio")
		amb.play()


func duck_music(db: float, dur := 0.8) -> void:
	var i := AudioServer.get_bus_index("Music")
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(i, v),
			AudioServer.get_bus_volume_db(i), db, dur)


func heartbeat(on: bool, rate := 1.1) -> void:
	_heart_on = on
	heart_rate = rate
	_heart_t = 0.0


func _process(delta: float) -> void:
	if _heart_on:
		_heart_t -= delta
		if _heart_t <= 0.0:
			_heart.stream = stream("heart")
			_heart.volume_db = -4.0
			_heart.play()
			_heart_t = heart_rate


# ---------------------------------------------------------------- impostazioni

## Cambia un'impostazione audio ("audio_on", "master_vol", "music_on", "music_vol", "amb_vol", "sfx_vol") e la salva.
func set_setting(key: String, value: Variant) -> void:
	set(key, value)
	_apply_settings()
	_save_settings()


## Il volume generale e l'interruttore vanno sul canale principale (Master); l'ambiente e gli effetti sui loro canali,
## così valgono anche per i suoni dei luoghi (pioggia, vento, tuoni, lupi: prima restavano fuori dal cursore);
## la musica sul suo lettore, perché il canale Music resta libero per gli abbassamenti del gioco (duck_music).
func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, _db(master_vol))
	AudioServer.set_bus_mute(0, not audio_on or master_vol <= 0.001)
	music.volume_db = _db(music_vol)
	amb.volume_db = 0.0
	var a := AudioServer.get_bus_index("Amb")
	AudioServer.set_bus_volume_db(a, -8.0 + _db(amb_vol))
	AudioServer.set_bus_mute(a, amb_vol <= 0.001)
	var i := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(i, -2.0 + _db(sfx_vol))
	AudioServer.set_bus_mute(i, sfx_vol <= 0.001)
	if music_on and not music.playing and amb.playing:
		music.stream = _looped(_music_name)
		music.play()
	elif not music_on and music.playing:
		music.stop()


func _db(v: float) -> float:
	return -80.0 if v <= 0.001 else linear_to_db(v)


func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(AUDIO_CFG) != OK:
		return
	audio_on = bool(cf.get_value("audio", "audio_on", audio_on))
	master_vol = clampf(float(cf.get_value("audio", "master_vol", master_vol)), 0.0, 1.0)
	music_on = bool(cf.get_value("audio", "music_on", music_on))
	music_vol = clampf(float(cf.get_value("audio", "music_vol", music_vol)), 0.0, 1.0)
	amb_vol = clampf(float(cf.get_value("audio", "amb_vol", amb_vol)), 0.0, 1.0)
	sfx_vol = clampf(float(cf.get_value("audio", "sfx_vol", sfx_vol)), 0.0, 1.0)


func _save_settings() -> void:
	var cf := ConfigFile.new()
	for k in ["audio_on", "master_vol", "music_on", "music_vol", "amb_vol", "sfx_vol"]:
		cf.set_value("audio", k, get(k))
	cf.save(AUDIO_CFG)
