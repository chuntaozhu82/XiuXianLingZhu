## EnemyAI.gd
## 敌人AI系统 - 管理敌人的行为决策
## 支持多种AI行为模式
extends Node

# ==================== AI行为模式 ====================
enum AIPattern {
	RANDOM,         # 随机选择技能
	AGGRESSIVE,     # 优先高伤害技能
	DEFENSIVE,      # 优先防御和治疗
	BALANCED,       # 平衡策略
	SUPPORT,        # 辅助型（优先治疗队友）
	BOSS            # Boss专用AI（多阶段）
}

# ==================== 配置 ====================
@export var ai_pattern: AIPattern = AIPattern.RANDOM
@export var aggressiveness: float = 0.5  # 攻击倾向 0-1
@export var heal_threshold: float = 0.3  # HP低于30%时考虑治疗

# ==================== 引用 ====================
var combat_system: Node = null
var enemy_unit: Node = null

# ==================== 初始化 ====================
func _ready() -> void:
	pass

func initialize(unit: Node, combat_sys: Node) -> void:
	enemy_unit = unit
	combat_system = combat_sys

# ==================== 决策系统 ====================
func decide_action() -> Dictionary:
	"""决定下一步行动，返回 {action_type, target, skill}"""
	var available_skills = enemy_unit.get_available_skills()
	
	if available_skills.is_empty():
		return {"action_type": "defend"}
	
	# 根据AI模式选择策略
	match ai_pattern:
		AIPattern.RANDOM:
			return _random_strategy(available_skills)
		AIPattern.AGGRESSIVE:
			return _aggressive_strategy(available_skills)
		AIPattern.DEFENSIVE:
			return _defensive_strategy(available_skills)
		AIPattern.BALANCED:
			return _balanced_strategy(available_skills)
		AIPattern.SUPPORT:
			return _support_strategy(available_skills)
		AIPattern.BOSS:
			return _boss_strategy(available_skills)
		_:
			return _random_strategy(available_skills)

# ==================== AI策略实现 ====================
func _random_strategy(skills: Array[Dictionary]) -> Dictionary:
	"""随机策略"""
	var skill = skills[randi() % skills.size()]
	var target = _select_target_for_skill(skill)
	
	return {
		"action_type": "attack" if skill.get("type") != "heal" else "heal",
		"target": target,
		"skill": skill
	}

func _aggressive_strategy(skills: Array[Dictionary]) -> Dictionary:
	"""激进策略：优先高伤害技能"""
	# 过滤出攻击技能
	var attack_skills = skills.filter(func(s): return s.get("type") != "heal")
	
	if attack_skills.is_empty():
		# 没有攻击技能，随机选择
		return _random_strategy(skills)
	
	# 按伤害倍率排序
	attack_skills.sort_custom(func(a, b): 
		return a.get("multiplier", 1.0) > b.get("multiplier", 1.0)
	)
	
	var skill = attack_skills[0]
	var target = _select_target_for_skill(skill)
	
	return {
		"action_type": "attack",
		"target": target,
		"skill": skill
	}

func _defensive_strategy(skills: Array[Dictionary]) -> Dictionary:
	"""防御策略：优先治疗和防御"""
	var hp_percent = enemy_unit.get_current_hp() / enemy_unit.get_stat("max_hp")
	
	# HP低于阈值时优先治疗
	if hp_percent < heal_threshold:
		var heal_skills = skills.filter(func(s): return s.get("type") == "heal")
		if not heal_skills.is_empty():
			var skill = heal_skills[0]
			var target = _find_most_damaged_ally()
			return {
				"action_type": "heal",
				"target": target if target else enemy_unit,
				"skill": skill
			}
	
	# 否则随机攻击
	return _random_strategy(skills)

func _balanced_strategy(skills: Array[Dictionary]) -> Dictionary:
	"""平衡策略：根据HP比例决定"""
	var hp_percent = enemy_unit.get_current_hp() / enemy_unit.get_stat("max_hp")
	
	# HP低于40%时有30%概率选择治疗
	if hp_percent < 0.4 and randf() < 0.3:
		var heal_skills = skills.filter(func(s): return s.get("type") == "heal")
		if not heal_skills.is_empty():
			var skill = heal_skills[0]
			var target = _find_most_damaged_ally()
			return {
				"action_type": "heal",
				"target": target if target else enemy_unit,
				"skill": skill
			}
	
	# 否则优先高伤害技能
	return _aggressive_strategy(skills)

func _support_strategy(skills: Array[Dictionary]) -> Dictionary:
	"""辅助策略：优先治疗队友"""
	var heal_skills = skills.filter(func(s): return s.get("type") == "heal")
	
	if not heal_skills.is_empty():
		# 检查是否有队友需要治疗
		var damaged_ally = _find_most_damaged_ally()
		if damaged_ally:
			var ally_hp_percent = damaged_ally.get_current_hp() / damaged_ally.get_stat("max_hp")
			if ally_hp_percent < 0.7:  # HP低于70%就治疗
				return {
					"action_type": "heal",
					"target": damaged_ally,
					"skill": heal_skills[0]
				}
	
	# 没有治疗需求，随机攻击
	return _random_strategy(skills)

func _boss_strategy(skills: Array[Dictionary]) -> Dictionary:
	"""Boss策略：多阶段行为"""
	var hp_percent = enemy_unit.get_current_hp() / enemy_unit.get_stat("max_hp")
	
	# 第一阶段：HP > 70%，普通攻击
	if hp_percent > 0.7:
		return _aggressive_strategy(skills)
	
	# 第二阶段：HP 40%-70%，加强攻击
	elif hp_percent > 0.4:
		# 优先使用AOE技能
		var aoe_skills = skills.filter(func(s): return s.get("target_type") == "all")
		if not aoe_skills.is_empty():
			return {
				"action_type": "attack",
				"target": combat_system.player_unit,
				"skill": aoe_skills[0]
			}
		return _aggressive_strategy(skills)
	
	# 第三阶段：HP < 40%，狂暴模式
	else:
		# 优先大招，同时召唤小怪（如果有）
		var ultimate_skills = skills.filter(func(s): return s.get("is_ultimate", false))
		if not ultimate_skills.is_empty() and enemy_unit.get_current_mp() >= ultimate_skills[0].get("mp_cost", 0):
			return {
				"action_type": "attack",
				"target": combat_system.player_unit,
				"skill": ultimate_skills[0]
			}
		return _aggressive_strategy(skills)

# ==================== 目标选择 ====================
func _select_target_for_skill(skill: Dictionary) -> Node:
	"""为技能选择目标"""
	var target_type = skill.get("target_type", "single")
	
	match target_type:
		"single":
			if skill.get("type") == "heal":
				return _find_most_damaged_ally()
			else:
				return _select_attack_target()
		"all":
			return combat_system.player_unit
		"self":
			return enemy_unit
		_:
			return combat_system.player_unit

func _select_attack_target() -> Node:
	"""选择攻击目标"""
	# 简化：优先攻击HP最低的玩家
	# 可扩展：考虑威胁值、仇恨值等
	return combat_system.player_unit

func _find_most_damaged_ally() -> Node:
	"""寻找受伤最重的队友"""
	var allies = combat_system.enemy_units.filter(func(e): return e.is_alive())
	
	if allies.is_empty():
		return null
	
	var most_damaged = allies[0]
	var lowest_hp_percent = 1.0
	
	for ally in allies:
		var hp_percent = ally.get_current_hp() / ally.get_stat("max_hp")
		if hp_percent < lowest_hp_percent:
			lowest_hp_percent = hp_percent
			most_damaged = ally
	
	return most_damaged if lowest_hp_percent < 1.0 else null

# ==================== 敌人数据创建 ====================
static func create_enemy(enemy_data: Dictionary) -> Dictionary:
	"""创建敌人数据
	参数示例:
	{
		"name": "史莱姆",
		"level": 1,
		"element": "earth",
		"hp": 50,
		"patk": 10,
		"pdef": 5,
		"speed": 80,
		"ai_pattern": "random",
		"skills": [
			{"name": "撞击", "multiplier": 1.0, "ap_cost": 1}
		],
		"rewards": {
			"exp": 10,
			"gold": 5
		}
	}
	"""
	var enemy = {
		"name": enemy_data.get("name", "Enemy"),
		"level": enemy_data.get("level", 1),
		"element": enemy_data.get("element", "neutral"),
		"stats": {
			"max_hp": enemy_data.get("hp", 100),
			"max_mp": enemy_data.get("mp", 50),
			"patk": enemy_data.get("patk", 20),
			"matk": enemy_data.get("matk", 20),
			"pdef": enemy_data.get("pdef", 10),
			"mdef": enemy_data.get("mdef", 10),
			"speed": enemy_data.get("speed", 100),
			"crit_rate": enemy_data.get("crit_rate", 0.05),
			"crit_dmg": 1.5,
			"hit_rate": 0.95,
			"eva_rate": 0.05
		},
		"ai_pattern": enemy_data.get("ai_pattern", "random"),
		"skills": enemy_data.get("skills", []),
		"rewards": enemy_data.get("rewards", {"exp": 10, "gold": 5})
	}
	
	return enemy

# ==================== 敌人模板库 ====================
static func get_enemy_template(template_name: String) -> Dictionary:
	"""获取敌人模板"""
	var templates = {
		"slime": {
			"name": "史莱姆",
			"level": 1,
			"element": "earth",
			"hp": 50,
			"patk": 10,
			"pdef": 5,
			"speed": 80,
			"ai_pattern": "random",
			"skills": [
				{"name": "撞击", "multiplier": 1.0, "ap_cost": 1, "attack_type": "physical"}
			],
			"rewards": {"exp": 10, "gold": 5}
		},
		"goblin": {
			"name": "哥布林",
			"level": 3,
			"element": "neutral",
			"hp": 80,
			"patk": 15,
			"pdef": 8,
			"speed": 90,
			"ai_pattern": "aggressive",
			"skills": [
				{"name": "挥砍", "multiplier": 1.2, "ap_cost": 1, "attack_type": "physical"},
				{"name": "偷袭", "multiplier": 1.5, "ap_cost": 2, "mp_cost": 5, "attack_type": "physical"}
			],
			"rewards": {"exp": 25, "gold": 15}
		},
		"fire_elemental": {
			"name": "火焰元素",
			"level": 5,
			"element": "fire",
			"hp": 120,
			"matk": 25,
			"mdef": 15,
			"speed": 100,
			"ai_pattern": "aggressive",
			"skills": [
				{"name": "火球术", "multiplier": 1.3, "ap_cost": 1, "mp_cost": 8, "attack_type": "magical", "element": "fire"},
				{"name": "烈焰风暴", "multiplier": 1.8, "ap_cost": 2, "mp_cost": 15, "attack_type": "magical", "element": "fire", "target_type": "all"}
			],
			"rewards": {"exp": 50, "gold": 30}
		},
		"dark_knight": {
			"name": "黑暗骑士",
			"level": 10,
			"element": "dark",
			"hp": 300,
			"patk": 40,
			"pdef": 30,
			"speed": 85,
			"ai_pattern": "balanced",
			"skills": [
				{"name": "重击", "multiplier": 1.5, "ap_cost": 1, "attack_type": "physical"},
				{"name": "暗影斩", "multiplier": 2.0, "ap_cost": 2, "mp_cost": 20, "attack_type": "physical", "element": "dark"},
				{"name": "黑暗护盾", "type": "heal", "heal_percent": 0.2, "ap_cost": 1, "mp_cost": 15}
			],
			"rewards": {"exp": 150, "gold": 100}
		},
		"boss_dragon": {
			"name": "炎龙",
			"level": 20,
			"element": "fire",
			"hp": 1000,
			"patk": 80,
			"matk": 100,
			"pdef": 50,
			"mdef": 60,
			"speed": 120,
			"ai_pattern": "boss",
			"skills": [
				{"name": "爪击", "multiplier": 1.2, "ap_cost": 1, "attack_type": "physical"},
				{"name": "龙息", "multiplier": 1.5, "ap_cost": 1, "mp_cost": 20, "attack_type": "magical", "element": "fire", "target_type": "all"},
				{"name": "烈焰吐息", "multiplier": 3.0, "ap_cost": 3, "mp_cost": 50, "attack_type": "magical", "element": "fire", "is_ultimate": true},
				{"name": "龙之怒", "type": "heal", "heal_percent": 0.3, "ap_cost": 2, "mp_cost": 30}
			],
			"rewards": {"exp": 500, "gold": 300}
		}
	}
	
	return templates.get(template_name, templates["slime"])
