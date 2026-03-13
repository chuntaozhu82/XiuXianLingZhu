extends Node

# Audio Manager - 管理游戏音频

# 音量设置
var master_volume: float = 1.0
var music_volume: float = 0.6
var sfx_volume: float = 0.8

# 音频总线
var master_bus: int
var music_bus: int
var sfx_bus: int

# 当前播放的音乐
var current_music: AudioStreamPlayer

# 信号
signal volume_changed(bus_name: String, volume: float)

func _ready():
	# 获取音频总线索引
	master_bus = AudioServer.get_bus_index("Master")
	music_bus = AudioServer.get_bus_index("Music")
	sfx_bus = AudioServer.get_bus_index("SFX")
	
	print("AudioManager initialized")

# 播放背景音乐
func play_music(stream: AudioStream, loop: bool = true):
	# 停止当前音乐
	if current_music and current_music.playing:
		fade_out_music(1.0)
	
	# 创建新的音乐播放器
	current_music = AudioStreamPlayer.new()
	current_music.stream = stream
	current_music.bus = "Music"
	current_music.autoplay = true
	
	# 设置循环
	if loop:
		current_music.stream.loop = true
	
	add_child(current_music)
	
	# 淡入
	fade_in_music(1.0)

# 停止背景音乐
func stop_music():
	if current_music:
		fade_out_music(1.0)

# 音乐淡入
func fade_in_music(duration: float = 1.0):
	if current_music:
		current_music.volume_db = -40
		var tween = create_tween()
		tween.tween_property(current_music, "volume_db", 0, duration)

# 音乐淡出
func fade_out_music(duration: float = 1.0):
	if current_music:
		var tween = create_tween()
		tween.tween_property(current_music, "volume_db", -40, duration)
		tween.tween_callback(current_music.queue_free)

# 播放音效
func play_sfx(stream: AudioStream, volume_db: float = 0.0):
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = stream
	sfx_player.bus = "SFX"
	sfx_player.volume_db = volume_db
	sfx_player.autoplay = true
	
	add_child(sfx_player)
	
	# 播放完成后自动删除
	sfx_player.finished.connect(sfx_player.queue_free)

# 播放按钮点击音效
func play_button_click():
	# 这里应该加载实际的音效资源
	# var click_sound = preload("res://audio/sfx/button_click.ogg")
	# play_sfx(click_sound)
	pass

# 设置主音量
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume))
	volume_changed.emit("Master", master_volume)

# 设置音乐音量
func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))
	volume_changed.emit("Music", music_volume)

# 设置音效音量
func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))
	volume_changed.emit("SFX", sfx_volume)

# 线性音量转分贝
func linear_to_db(volume: float) -> float:
	if volume <= 0.0:
		return -60.0
	return 20.0 * log(volume) / log(10.0)

# 分贝转线性音量
func db_to_linear(db: float) -> float:
	return pow(10.0, db / 20.0)

# 保存音量设置
func save_volume_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save("user://audio_settings.cfg")

# 加载音量设置
func load_volume_settings():
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	
	if err == OK:
		master_volume = config.get_value("audio", "master_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 0.6)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
		
		# 应用音量
		set_master_volume(master_volume)
		set_music_volume(music_volume)
		set_sfx_volume(sfx_volume)
