## MainMenu.gd
## 主菜单界面控制器
## 管理游戏开始、继续、设置等功能
extends Control

# ==================== 节点引用 ====================
@onready var continue_button = $VBoxContainer/MenuButtons/ContinueButton
@onready var new_game_button = $VBoxContainer/MenuButtons/NewGameButton
@onready var settings_button = $VBoxContainer/MenuButtons/SettingsButton
@onready var achievement_button = $VBoxContainer/MenuButtons/AchievementButton

# 底部Tab引用
@onready var battle_tab = $BottomBar/TabContainer/BattleTab
@onready var inventory_tab = $BottomBar/TabContainer/InventoryTab
@onready var skills_tab = $BottomBar/TabContainer/SkillsTab
@onready var status_tab = $BottomBar/TabContainer/StatusTab

# 玩家信息显示
@onready var player_name_label = $VBoxContainer/PlayerInfo/PlayerName
@onready var player_level_label = $VBoxContainer/PlayerInfo/PlayerLevel
@onready var gold_label = $VBoxContainer/PlayerInfo/GoldLabel

# ==================== 初始化 ====================
func _ready():
	# 连接按钮信号
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	achievement_button.pressed.connect(_on_achievement_pressed)
	
	# 连接Tab信号
	battle_tab.gui_input.connect(_on_tab_gui_input.bind("Battle"))
	inventory_tab.gui_input.connect(_on_tab_gui_input.bind("Inventory"))
	skills_tab.gui_input.connect(_on_tab_gui_input.bind("Skills"))
	status_tab.gui_input.connect(_on_tab_gui_input.bind("Status"))
	
	# 检查是否有存档
	if not GameManager.has_save_data():
		continue_button.disabled = true
		continue_button.modulate.a = 0.5
	else:
		# 加载玩家数据显示
		_load_player_display()
	
	# 适配安全区域
	adapt_safe_area()
	
	print("MainMenu loaded")

func _load_player_display():
	"""加载玩家信息显示"""
	player_name_label.text = PlayerData.player_name
	player_level_label.text = "Lv.%d" % PlayerData.player_level
	gold_label.text = "%d 金币" % PlayerData.gold

# ==================== 按钮事件 ====================
func _on_continue_pressed():
	UIManager.button_press_animation(continue_button)
	await get_tree().create_timer(0.1).timeout
	
	# 加载游戏
	if GameManager.load_game():
		UIManager.show_toast("欢迎回来，%s！" % PlayerData.player_name)
		UIManager.change_scene("res://scenes/Battle.tscn")
	else:
		UIManager.show_toast("加载存档失败")

func _on_new_game_pressed():
	UIManager.button_press_animation(new_game_button)
	await get_tree().create_timer(0.1).timeout
	
	# 重置玩家数据
	PlayerData.reset_to_default()
	
	# 设置初始属性
	PlayerData.player_name = "修仙者"
	PlayerData.player_class = "剑修"
	PlayerData.player_level = 1
	PlayerData.current_exp = 0
	
	# 初始资源
	PlayerData.gold = 100
	PlayerData.diamond = 10
	
	# 初始属性
	PlayerData.current_hp = PlayerData.get_current_stat("max_hp")
	PlayerData.current_mp = PlayerData.get_current_stat("max_mp")
	
	# 解锁初始技能
	PlayerData.unlock_skill("attack")
	PlayerData.unlock_skill("fireball")
	
	# 保存初始数据
	GameManager.save_game()
	
	# 显示欢迎信息
	UIManager.show_toast("欢迎来到修仙世界！")
	
	# 进入战斗场景
	UIManager.change_scene("res://scenes/Battle.tscn")

func _on_settings_pressed():
	UIManager.button_press_animation(settings_button)
	# TODO: 打开设置界面
	UIManager.show_toast("设置功能开发中")

func _on_achievement_pressed():
	UIManager.button_press_animation(achievement_button)
	# TODO: 打开成就界面
	UIManager.show_toast("成就功能开发中")

# ==================== Tab导航 ====================
func _on_tab_gui_input(event: InputEvent, tab_name: String):
	if event is InputEventScreenTouch and event.pressed:
		UIManager.button_press_animation(get_node("BottomBar/TabContainer/" + tab_name + "Tab"))
		await get_tree().create_timer(0.1).timeout
		
		match tab_name:
			"Battle":
				UIManager.change_scene("res://scenes/Battle.tscn")
			"Inventory":
				UIManager.change_scene("res://scenes/Inventory.tscn")
			"Skills":
				UIManager.change_scene("res://scenes/SkillTree.tscn")
			"Status":
				UIManager.change_scene("res://scenes/CharacterStatus.tscn")

# ==================== 安全区域适配 ====================
func adapt_safe_area():
	var safe_area = GameManager.get_safe_area()
	var screen_size = get_viewport().size
	
	# 调整顶部安全区域
	$SafeAreaTop.offset_bottom = safe_area.position.y
	
	# 调整底部安全区域
	$SafeAreaBottom.offset_top = screen_size.y - safe_area.end.y
