## GameManager.gd
## 游戏管理器 - 管理游戏状态、场景切换、存档系统
## 核心全局管理器，协调各个子系统
extends Node

# ==================== 信号 ====================
signal state_changed(new_state: int)
signal scene_changed(scene_name: String)
signal player_data_updated()
signal game_saved()
signal game_loaded()

# ==================== 游戏状态 ====================
enum GameState { 
	MAIN_MENU, 
	PLAYING, 
	PAUSED, 
	BATTLE, 
	DIALOGUE,
	CUTSCENE,
	LOADING
}

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU

# ==================== 场景管理 ====================
const SCENES = {
	"main_menu": "res://scenes/MainMenu.tscn",
	"world": "res://scenes/World.tscn",
	"battle": "res://scenes/Battle.tscn",
	"inventory": "res://scenes/Inventory.tscn",
	"skill_tree": "res://scenes/SkillTree.tscn"
}

var current_scene: String = "main_menu"

# ==================== 玩家数据引用 ====================
# PlayerData作为autoload全局单例，直接通过PlayerData访问

# ==================== 存档数据 ====================
var save_data: Dictionary = {
	"chapter": 1,
	"play_time_seconds": 0,
	"last_save_time": "",
	"unlocked_areas": ["starter_village"],
	"completed_quests": [],
	"defeated_bosses": []
}

# ==================== 游戏时间 ====================
var play_time_timer: Timer
var is_timer_running: bool = false

# ==================== 配置 ====================
const SAVE_FILE_PATH: String = "user://savegame.save"
const SETTINGS_FILE_PATH: String = "user://settings.cfg"

# ==================== 初始化 ====================
func _ready() -> void:
	print("[GameManager] 初始化游戏管理器")
	
	# 初始化游戏时间计时器
	_setup_play_time_timer()
	
	# 加载设置
	_load_settings()
	
	# 连接PlayerData信号
	_connect_player_data_signals()

func _setup_play_time_timer() -> void:
	play_time_timer = Timer.new()
	play_time_timer.wait_time = 1.0
	play_time_timer.one_shot = false
	play_time_timer.timeout.connect(_on_play_time_tick)
	add_child(play_time_timer)

func _connect_player_data_signals() -> void:
	# 连接PlayerData的信号
	PlayerData.stats_changed.connect(_on_player_stats_changed)
	PlayerData.level_changed.connect(_on_player_level_changed)

# ==================== 游戏状态管理 ====================
func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	
	previous_state = current_state
	current_state = new_state
	state_changed.emit(new_state)
	
	print("[GameManager] 状态切换: %s -> %s" % [
		GameState.keys()[previous_state],
		GameState.keys()[current_state]
	])
	
	# 状态特定处理
	match current_state:
		GameState.PLAYING:
			start_play_time()
		GameState.PAUSED, GameState.BATTLE:
			pause_play_time()
		GameState.MAIN_MENU:
			stop_play_time()

func get_state() -> GameState:
	return current_state

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func is_in_battle() -> bool:
	return current_state == GameState.BATTLE

func is_paused() -> bool:
	return current_state == GameState.PAUSED

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		get_tree().paused = true

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		get_tree().paused = false

# ==================== 场景管理 ====================
func change_scene(scene_name: String) -> void:
	if not SCENES.has(scene_name):
		push_error("[GameManager] 未知场景: " + scene_name)
		return
	
	print("[GameManager] 切换场景: %s" % scene_name)
	current_scene = scene_name
	
	# 更新游戏状态
	match scene_name:
		"main_menu":
			change_state(GameState.MAIN_MENU)
		"battle":
			change_state(GameState.BATTLE)
		_:
			change_state(GameState.PLAYING)
	
	# 切换场景
	get_tree().change_scene_to_file(SCENES[scene_name])
	scene_changed.emit(scene_name)

func change_scene_with_transition(scene_name: String, transition_type: String = "fade") -> void:
	# TODO: 实现场景过渡动画
	change_scene(scene_name)

func reload_current_scene() -> void:
	get_tree().reload_current_scene()

# ==================== 战斗场景启动 ====================
func start_battle(enemy_id: String, enemy_level: int = 1) -> void:
	# 保存当前场景
	PlayerData.last_location = current_scene
	
	# 设置战斗数据
	PlayerData.current_battle_enemy = {
		"id": enemy_id,
		"level": enemy_level
	}
	
	# 切换到战斗场景
	change_scene("battle")

func start_battle_with_group(enemies: Array[Dictionary]) -> void:
	# 保存当前场景
	PlayerData.last_location = current_scene
	
	# 设置战斗数据
	PlayerData.current_battle_enemies = enemies
	
	# 切换到战斗场景
	change_scene("battle")

# ==================== 游戏时间管理 ====================
func start_play_time() -> void:
	if not is_timer_running:
		play_time_timer.start()
		is_timer_running = true

func pause_play_time() -> void:
	if is_timer_running:
		play_time_timer.stop()
		is_timer_running = false

func stop_play_time() -> void:
	pause_play_time()
	save_data.play_time_seconds = 0

func _on_play_time_tick() -> void:
	save_data.play_time_seconds += 1

func get_play_time() -> Dictionary:
	var total_seconds = save_data.play_time_seconds
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60
	return {
		"hours": hours,
		"minutes": minutes,
		"seconds": seconds,
		"formatted": "%02d:%02d:%02d" % [hours, minutes, seconds]
	}

# ==================== 存档系统 ====================
func save_game() -> bool:
	print("[GameManager] 保存游戏...")
	
	# 更新保存时间
	save_data.last_save_time = Time.get_datetime_string_from_system()
	
	# 构建保存数据
	var save_content: Dictionary = {
		"version": 1,
		"player_data": PlayerData.save_data(),
		"game_data": save_data,
		"timestamp": Time.get_ticks_msec()
	}
	
	# 写入文件
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[GameManager] 无法打开存档文件")
		return false
	
	var json_string = JSON.stringify(save_content, "  ")
	file.store_string(json_string)
	file.close()
	
	game_saved.emit()
	print("[GameManager] 游戏已保存")
	return true

func load_game() -> bool:
	print("[GameManager] 加载游戏...")
	
	if not has_save_data():
		print("[GameManager] 没有存档")
		return false
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		push_error("[GameManager] 无法读取存档文件")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("[GameManager] 存档解析失败")
		return false
	
	var save_content = json.data
	
	# 加载玩家数据
	if save_content.has("player_data"):
		PlayerData.load_data(save_content.player_data)
	
	# 加载游戏数据
	if save_content.has("game_data"):
		save_data = save_content.game_data
	
	game_loaded.emit()
	print("[GameManager] 游戏已加载")
	return true

func has_save_data() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func delete_save() -> bool:
	if has_save_data():
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("[GameManager] 存档已删除")
		return true
	return false

func new_game() -> void:
	print("[GameManager] 开始新游戏")
	
	# 重置玩家数据
	PlayerData.reset_to_default()
	
	# 重置游戏数据
	save_data = {
		"chapter": 1,
		"play_time_seconds": 0,
		"last_save_time": "",
		"unlocked_areas": ["starter_village"],
		"completed_quests": [],
		"defeated_bosses": []
	}
	
	# 进入游戏世界
	change_scene("world")

# ==================== 设置系统 ====================
func _load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_FILE_PATH) == OK:
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("Master"),
			config.get_value("audio", "master_volume", 0.0)
		)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("BGM"),
			config.get_value("audio", "bgm_volume", 0.0)
		)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("SFX"),
			config.get_value("audio", "sfx_volume", 0.0)
		)

func save_settings(settings: Dictionary) -> bool:
	var config = ConfigFile.new()
	
	for section in settings:
		for key in settings[section]:
			config.set_value(section, key, settings[section][key])
	
	return config.save(SETTINGS_FILE_PATH) == OK

# ==================== 玩家数据信号处理 ====================
func _on_player_stats_changed(stat_name: String, old_value: float, new_value: float) -> void:
	player_data_updated.emit()

func _on_player_level_changed(new_level: int) -> void:
	player_data_updated.emit()
	print("[GameManager] 玩家升级到 %d 级" % new_level)

# ==================== 屏幕适配 ====================
func get_safe_area() -> Rect2:
	return DisplayServer.get_display_safe_area()

func get_screen_size() -> Vector2:
	return get_viewport().size

# ==================== 调试功能 ====================
func add_gold(amount: int) -> void:
	PlayerData.add_gold(amount)
	print("[GameManager] 添加金币: %d, 当前: %d" % [amount, PlayerData.gold])

func add_exp(amount: int) -> void:
	PlayerData.add_experience(amount)
	print("[GameManager] 添加经验: %d" % amount)

func full_heal() -> void:
	PlayerData.current_hp = PlayerData.stats.max_hp
	PlayerData.current_mp = PlayerData.stats.max_mp
	print("[GameManager] 玩家完全恢复")

func unlock_all_skills() -> void:
	# 调试用：解锁所有技能
	var skill_data = preload("res://scripts/data/SkillData.gd")
	for skill_id in skill_data.SKILLS:
		if not skill_data.SKILLS[skill_id].get("enemy_only", false):
			PlayerData.unlock_skill(skill_id)
	print("[GameManager] 已解锁所有技能")
