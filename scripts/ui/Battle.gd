## Battle.gd
## 战斗界面控制器 - 连接UI和战斗系统
## 集成CombatSystem处理战斗逻辑
extends Control

# ==================== 节点引用 ====================
@onready var turn_label = $TopStatusBar/HBoxContainer/TurnInfo
@onready var timer_label = $TopStatusBar/HBoxContainer/TimerLabel
@onready var speed_button = $TopStatusBar/HBoxContainer/SpeedButton
@onready var auto_button = $TopStatusBar/HBoxContainer/AutoButton

@onready var enemy_name = $EnemyArea/EnemyInfoPanel/VBoxContainer/EnemyName
@onready var enemy_hp_bar = $EnemyArea/EnemyInfoPanel/VBoxContainer/HPBar
@onready var enemy_hp_label = $EnemyArea/EnemyInfoPanel/VBoxContainer/HPLabel
@onready var enemy_status = $EnemyArea/EnemyInfoPanel/VBoxContainer/StatusLabel

@onready var player_hp_bar = $BottomStatus/HBoxContainer/PlayerHPBar
@onready var player_hp_label = $BottomStatus/HBoxContainer/PlayerHPLabel
@onready var player_mp_bar = $BottomStatus/HBoxContainer/PlayerMPBar
@onready var player_mp_label = $BottomStatus/HBoxContainer/PlayerMPLabel
@onready var player_ap_label = $BottomStatus/HBoxContainer/APLabel

@onready var skill_buttons = {
	"attack": $SkillArea/VBoxContainer/SkillRow1/AttackButton,
	"fireball": $SkillArea/VBoxContainer/SkillRow1/FireballButton,
	"heal": $SkillArea/VBoxContainer/SkillRow1/HealButton,
	"defend": $SkillArea/VBoxContainer/SkillRow2/DefendButton,
	"item": $SkillArea/VBoxContainer/SkillRow2/ItemButton,
	"flee": $SkillArea/VBoxContainer/SkillRow2/FleeButton
}

# ==================== 战斗系统 ====================
var combat_system: Node = null
var player_unit: Node = null
var enemy_unit: Node = null

# ==================== 战斗配置 ====================
var current_turn: int = 1
var max_turns: int = 20
var turn_time: float = 30.0
var time_remaining: float = 30.0
var speed_multiplier: int = 1
var is_auto: bool = false

# ==================== 初始化 ====================
func _ready():
	# 初始化战斗系统
	_setup_combat_system()
	
	# 连接技能按钮信号
	for skill_name in skill_buttons:
		skill_buttons[skill_name].pressed.connect(_on_skill_pressed.bind(skill_name))
	
	# 连接控制按钮
	speed_button.pressed.connect(_on_speed_pressed)
	auto_button.pressed.connect(_on_auto_pressed)
	
	# 适配安全区域
	adapt_safe_area()
	
	# 开始战斗
	start_battle()

func _setup_combat_system():
	"""初始化战斗系统"""
	combat_system = preload("res://scripts/combat/CombatSystem.gd").new()
	add_child(combat_system)
	
	# 连接战斗系统信号
	combat_system.combat_started.connect(_on_combat_started)
	combat_system.combat_ended.connect(_on_combat_ended)
	combat_system.turn_started.connect(_on_turn_started)
	combat_system.damage_dealt.connect(_on_damage_dealt)
	combat_system.healing_done.connect(_on_healing_done)
	combat_system.unit_died.connect(_on_unit_died)
	
	# 创建玩家单位
	player_unit = _create_player_unit()
	add_child(player_unit)
	
	# 创建敌人单位（示例：史莱姆王）
	enemy_unit = _create_enemy_unit("slime_king", 5)
	add_child(enemy_unit)

func _create_player_unit() -> Node:
	"""创建玩家战斗单位"""
	var unit = preload("res://scripts/combat/CombatUnit.gd").new()
	unit.unit_name = PlayerData.player_name
	unit.unit_level = PlayerData.player_level
	unit.unit_element = "neutral"
	
	# 从PlayerData复制属性
	unit.stats = {
		"max_hp": PlayerData.get_current_stat("max_hp"),
		"max_mp": PlayerData.get_current_stat("max_mp"),
		"patk": PlayerData.get_current_stat("patk"),
		"matk": PlayerData.get_current_stat("matk"),
		"pdef": PlayerData.get_current_stat("pdef"),
		"mdef": PlayerData.get_current_stat("mdef"),
		"speed": PlayerData.get_current_stat("speed"),
		"crit_rate": PlayerData.get_current_stat("crit_rate"),
		"crit_dmg": PlayerData.get_current_stat("crit_dmg"),
		"hit_rate": PlayerData.get_current_stat("hit_rate"),
		"eva_rate": PlayerData.get_current_stat("eva_rate")
	}
	
	unit.current_hp = PlayerData.current_hp
	unit.current_mp = PlayerData.current_mp
	unit.max_ap = 3
	unit.current_ap = 3
	
	# 添加技能
	unit.skills = _get_player_skills()
	
	return unit

func _get_player_skills() -> Array[Dictionary]:
	"""获取玩家已解锁技能"""
	var skills: Array[Dictionary] = []
	
	# 基础攻击
	skills.append({
		"id": "attack",
		"name": "普通攻击",
		"type": "physical",
		"attack_type": "physical",
		"mp_cost": 0,
		"ap_cost": 1,
		"cooldown": 0,
		"multiplier": 1.0,
		"target_type": "single"
	})
	
	# 火球术（示例技能）
	if PlayerData.has_skill("fireball"):
		skills.append({
			"id": "fireball",
			"name": "火球术",
			"type": "magic",
			"attack_type": "magical",
			"element": "fire",
			"mp_cost": 15,
			"ap_cost": 2,
			"cooldown": 0,
			"multiplier": 1.5,
			"target_type": "single"
		})
	
	# 治疗（示例技能）
	if PlayerData.has_skill("heal"):
		skills.append({
			"id": "heal",
			"name": "治愈术",
			"type": "heal",
			"mp_cost": 20,
			"ap_cost": 2,
			"cooldown": 2,
			"heal_type": "percentage",
			"heal_percent": 0.3,
			"target_type": "self"
		})
	
	return skills

func _create_enemy_unit(enemy_id: String, level: int) -> Node:
	"""创建敌人单位"""
	var unit = preload("res://scripts/combat/CombatUnit.gd").new()
	
	# 敌人配置（可从配置文件加载）
	var enemy_configs = {
		"slime_king": {
			"name": "史莱姆王",
			"element": "neutral",
			"base_stats": {
				"max_hp": 150,
				"max_mp": 50,
				"patk": 15,
				"matk": 10,
				"pdef": 8,
				"mdef": 8,
				"speed": 80
			},
			"ai_pattern": "BOSS",
			"skills": ["attack"]
		}
	}
	
	var config = enemy_configs.get(enemy_id, {})
	unit.unit_name = config.get("name", "敌人")
	unit.unit_level = level
	unit.unit_element = config.get("element", "neutral")
	
	# 根据等级计算属性
	var base_stats = config.get("base_stats", {})
	for stat in base_stats:
		unit.stats[stat] = base_stats[stat] * (1 + (level - 1) * 0.15)
	
	unit.current_hp = unit.stats.max_hp
	unit.current_mp = unit.stats.max_mp
	
	# 添加敌人技能
	unit.skills = [{
		"id": "attack",
		"name": "攻击",
		"type": "physical",
		"attack_type": "physical",
		"mp_cost": 0,
		"ap_cost": 1,
		"multiplier": 1.0
	}]
	
	return unit

# ==================== 战斗流程 ====================
func start_battle():
	"""开始战斗"""
	combat_system.start_combat(player_unit, [enemy_unit])
	update_all_ui()

func _process(delta):
	if combat_system == null:
		return
	
	if combat_system.is_player_turn():
		# 更新计时器
		time_remaining -= delta * speed_multiplier
		update_timer_display()
		
		# 时间耗尽
		if time_remaining <= 0:
			_auto_end_turn()
		
		# 自动战斗
		elif is_auto:
			await get_tree().create_timer(0.5).timeout
			_auto_select_action()

func _auto_end_turn():
	"""超时自动结束回合"""
	UIManager.show_toast("时间到！自动防御")
	_on_skill_pressed("defend")

func _auto_select_action():
	"""自动选择行动"""
	if not combat_system.is_player_turn():
		return
	
	# 简单AI：优先治疗，其次攻击
	if player_unit.current_hp < player_unit.stats.max_hp * 0.5:
		if player_unit.current_mp >= 20:
			_on_skill_pressed("heal")
			return
	
	# 随机选择攻击技能
	var available_skills = []
	for skill in player_unit.skills:
		var mp_cost = skill.get("mp_cost", 0)
		if player_unit.current_mp >= mp_cost:
			available_skills.append(skill.id)
	
	if available_skills.size() > 0:
		var random_skill = available_skills[randi() % available_skills.size()]
		_on_skill_pressed(random_skill)
	else:
		_on_skill_pressed("attack")

# ==================== 技能执行 ====================
func _on_skill_pressed(skill_name: String):
	if not combat_system.is_player_turn():
		return
	
	if not is_auto:
		# 按钮动画
		UIManager.button_press_animation(skill_buttons.get(skill_name))
		AudioManager.play_button_click()
	
	# 获取技能配置
	var skill = _get_skill_by_id(skill_name)
	
	# 检查MP是否足够
	var mp_cost = skill.get("mp_cost", 0)
	if player_unit.current_mp < mp_cost:
		UIManager.show_toast("法力不足！")
		return
	
	# 检查AP是否足够
	var ap_cost = skill.get("ap_cost", 1)
	if player_unit.current_ap < ap_cost:
		UIManager.show_toast("行动点不足！")
		return
	
	# 执行技能
	match skill_name:
		"attack":
			combat_system.execute_attack(player_unit, enemy_unit, skill)
		"fireball":
			combat_system.execute_attack(player_unit, enemy_unit, skill)
		"heal":
			combat_system.execute_heal(player_unit, player_unit, skill)
		"defend":
			combat_system.execute_defend(player_unit)
		"item":
			open_item_menu()
		"flee":
			attempt_flee()
		_:
			UIManager.show_toast("技能开发中")

func _get_skill_by_id(skill_id: String) -> Dictionary:
	"""根据ID获取技能配置"""
	for skill in player_unit.skills:
		if skill.get("id", "") == skill_id:
			return skill
	return {}

func open_item_menu():
	UIManager.show_toast("物品系统开发中")

func attempt_flee():
	# 逃跑成功率基于速度差
	var flee_chance = 0.3 + (player_unit.stats.speed - enemy_unit.stats.speed) * 0.005
	flee_chance = clamp(flee_chance, 0.1, 0.7)
	
	if randf() < flee_chance:
		UIManager.show_toast("逃跑成功！")
		await get_tree().create_timer(1.0).timeout
		UIManager.change_scene("res://scenes/MainMenu.tscn")
	else:
		UIManager.show_toast("逃跑失败！")

# ==================== 战斗结果处理 ====================
func _on_combat_started():
	print("战斗开始！")

func _on_combat_ended(victory: bool):
	if victory:
		battle_victory()
	else:
		battle_defeat()

func _on_turn_started(turn_number: int, current_unit: Node):
	current_turn = turn_number
	time_remaining = turn_time
	update_turn_display()
	update_all_ui()

func _on_damage_dealt(attacker: Node, target: Node, damage: float, is_crit: bool):
	var text = ""
	if is_crit:
		text = "暴击！%.0f 伤害" % damage
	else:
		text = "%.0f 伤害" % damage
	
	UIManager.show_toast(text)
	update_all_ui()

func _on_healing_done(healer: Node, target: Node, amount: float):
	UIManager.show_toast("恢复 %.0f HP" % amount)
	update_all_ui()

func _on_unit_died(unit: Node):
	if unit == player_unit:
		battle_defeat()
	else:
		battle_victory()

func battle_victory():
	UIManager.show_toast("战斗胜利！")
	
	# 计算奖励
	var exp_reward = enemy_unit.unit_level * 100
	var gold_reward = enemy_unit.unit_level * 50
	
	# 发放奖励
	PlayerData.add_experience(exp_reward)
	PlayerData.add_gold(gold_reward)
	
	await get_tree().create_timer(2.0).timeout
	UIManager.change_scene("res://scenes/MainMenu.tscn")

func battle_defeat():
	UIManager.show_toast("战斗失败...")
	await get_tree().create_timer(2.0).timeout
	UIManager.change_scene("res://scenes/MainMenu.tscn")

# ==================== UI更新 ====================
func update_all_ui():
	update_turn_display()
	update_player_ui()
	update_enemy_ui()
	update_skill_buttons()

func update_turn_display():
	turn_label.text = "回合 %d" % current_turn

func update_timer_display():
	var seconds = int(time_remaining)
	timer_label.text = "%02ds" % seconds

func update_player_ui():
	if player_unit == null:
		return
	
	# HP
	var hp_percent = (player_unit.current_hp / player_unit.stats.max_hp) * 100
	player_hp_bar.value = hp_percent
	player_hp_label.text = "HP: %.0f/%.0f" % [player_unit.current_hp, player_unit.stats.max_hp]
	
	# MP
	var mp_percent = (player_unit.current_mp / player_unit.stats.max_mp) * 100
	player_mp_bar.value = mp_percent
	player_mp_label.text = "MP: %.0f/%.0f" % [player_unit.current_mp, player_unit.stats.max_mp]
	
	# AP
	player_ap_label.text = "AP: %d/%d" % [player_unit.current_ap, player_unit.max_ap]

func update_enemy_ui():
	if enemy_unit == null:
		return
	
	enemy_name.text = enemy_unit.unit_name + " Lv." + str(enemy_unit.unit_level)
	
	var hp_percent = (enemy_unit.current_hp / enemy_unit.stats.max_hp) * 100
	enemy_hp_bar.value = hp_percent
	enemy_hp_label.text = "HP: %.0f/%.0f" % [enemy_unit.current_hp, enemy_unit.stats.max_hp]
	
	# 状态效果
	var status_text = ""
	for status in enemy_unit.active_status:
		status_text += status + " "
	enemy_status.text = status_text

func update_skill_buttons():
	"""更新技能按钮状态"""
	for skill_id in skill_buttons:
		var button = skill_buttons[skill_id]
		var skill = _get_skill_by_id(skill_id)
		
		if skill.is_empty():
			continue
		
		# 检查MP是否足够
		var mp_cost = skill.get("mp_cost", 0)
		if player_unit.current_mp < mp_cost:
			button.modulate = Color(0.5, 0.5, 0.5)
			button.disabled = true
		else:
			button.modulate = Color(1, 1, 1)
			button.disabled = false

# ==================== 控制按钮 ====================
func _on_speed_pressed():
	speed_multiplier += 1
	if speed_multiplier > 3:
		speed_multiplier = 1
	speed_button.text = str(speed_multiplier) + "x"

func _on_auto_pressed():
	is_auto = !is_auto
	auto_button.text = "自动" if is_auto else "手动"
	auto_button.modulate = Color(0.5, 1, 0.5) if is_auto else Color(1, 1, 1)

# ==================== 安全区域适配 ====================
func adapt_safe_area():
	var safe_area = GameManager.get_safe_area()
	var screen_size = get_viewport().size
	
	$SafeAreaTop.offset_bottom = safe_area.position.y
	$SafeAreaBottom.offset_top = screen_size.y - safe_area.end.y
