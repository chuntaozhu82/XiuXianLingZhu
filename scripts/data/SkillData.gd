## SkillData.gd
## 技能数据库 - 存储所有技能的配置数据
## 包含攻击技能、辅助技能、被动技能等
extends Resource

class_name SkillDataResource

# ==================== 技能类型枚举 ====================
enum SkillType {
	ATTACK,     # 攻击技能
	HEAL,       # 治疗技能
	BUFF,       # 增益技能
	DEBUFF,     # 减益技能
	PASSIVE,    # 被动技能
	SUMMON      # 召唤技能
}

enum SkillElement {
	NONE,
	FIRE,
	ICE,
	WIND,
	EARTH,
	THUNDER,
	WATER,
	LIGHT,
	DARK
}

enum TargetType {
	SINGLE_ENEMY,    # 单体敌人
	ALL_ENEMIES,     # 全体敌人
	SINGLE_ALLY,     # 单体友方
	ALL_ALLIES,      # 全体友方
	SELF,            # 自身
	RANDOM_ENEMY     # 随机敌人
}

# ==================== 技能数据库 ====================
static var SKILLS: Dictionary = {}

static func _static_init():
	_register_all_skills()

static func _register_all_skills():
	# ========== 基础技能 ==========
	register_skill({
		"id": "basic_attack",
		"name": "普通攻击",
		"description": "最基础的物理攻击",
		"type": SkillType.ATTACK,
		"element": SkillElement.NONE,
		"target": TargetType.SINGLE_ENEMY,
		"ap_cost": 1,
		"mp_cost": 0,
		"cooldown": 0,
		"damage_type": "physical",
		"base_damage": 100,  # 基于攻击力的百分比
		"hit_rate": 0.95,
		"animation": "slash",
		"icon": "⚔️",
		"tier": 0
	})
	
	# ========== 火系技能 ==========
	register_skill({
		"id": "fire_ball",
		"name": "火球术",
		"description": "发射一颗火球攻击敌人，有几率造成灼烧",
		"type": SkillType.ATTACK,
		"element": SkillElement.FIRE,
		"target": TargetType.SINGLE_ENEMY,
		"ap_cost": 2,
		"mp_cost": 15,
		"cooldown": 0,
		"damage_type": "magical",
		"base_damage": 130,
		"hit_rate": 0.95,
		"status_effect": {
			"burn": {"chance": 0.2, "duration": 3, "damage": 10}
		},
		"animation": "fire_ball",
		"icon": "🔥",
		"tier": 1,
		"level_requirement": 1
	})
	
	register_skill({
		"id": "flame_strike",
		"name": "烈焰斩",
		"description": "带有火焰之力的斩击",
		"type": SkillType.ATTACK,
		"element": SkillElement.FIRE,
		"target": TargetType.SINGLE_ENEMY,
		"ap_cost": 2,
		"mp_cost": 20,
		"cooldown": 1,
		"damage_type": "physical",
		"base_damage": 150,
		"hit_rate": 0.90,
		"status_effect": {
			"burn": {"chance": 0.3, "duration": 2, "damage": 15}
		},
		"animation": "flame_slash",
		"icon": "🗡️🔥",
		"tier": 1,
		"level_requirement": 5
	})
	
	register_skill({
		"id": "fire_storm",
		"name": "火焰风暴",
		"description": "召唤火焰风暴攻击全体敌人",
		"type": SkillType.ATTACK,
		"element": SkillElement.FIRE,
		"target": TargetType.ALL_ENEMIES,
		"ap_cost": 3,
		"mp_cost": 40,
		"cooldown": 3,
		"damage_type": "magical",
		"base_damage": 100,
		"hit_rate": 0.85,
		"status_effect": {
			"burn": {"chance": 0.4, "duration": 3, "damage": 12}
		},
		"animation": "fire_storm",
		"icon": "🌋",
		"tier": 2,
		"level_requirement": 15
	})
	
	# ========== 冰系技能 ==========
	register_skill({
		"id": "ice_bolt",
		"name": "冰锥术",
		"description": "发射冰锥攻击敌人，有几率冻结",
		"type": SkillType.ATTACK,
		"element": SkillElement.ICE,
		"target": TargetType.SINGLE_ENEMY,
		"ap_cost": 2,
		"mp_cost": 18,
		"cooldown": 0,
		"damage_type": "magical",
		"base_damage": 120,
		"hit_rate": 0.95,
		"status_effect": {
			"freeze": {"chance": 0.15, "duration": 1}
		},
		"animation": "ice_bolt",
		"icon": "❄️",
		"tier": 1,
		"level_requirement": 1
	})
	
	register_skill({
		"id": "blizzard",
		"name": "暴风雪",
		"description": "召唤暴风雪攻击全体敌人",
		"type": SkillType.ATTACK,
		"element": SkillElement.ICE,
		"target": TargetType.ALL_ENEMIES,
		"ap_cost": 3,
		"mp_cost": 45,
		"cooldown": 3,
		"damage_type": "magical",
		"base_damage": 90,
		"hit_rate": 0.80,
		"status_effect": {
			"freeze": {"chance": 0.25, "duration": 2}
		},
		"animation": "blizzard",
		"icon": "🌨️",
		"tier": 2,
		"level_requirement": 15
	})
	
	# ========== 雷系技能 ==========
	register_skill({
		"id": "thunder_bolt",
		"name": "雷击",
		"description": "召唤雷电攻击敌人，高暴击率",
		"type": SkillType.ATTACK,
		"element": SkillElement.THUNDER,
		"target": TargetType.SINGLE_ENEMY,
		"ap_cost": 2,
		"mp_cost": 22,
		"cooldown": 0,
		"damage_type": "magical",
		"base_damage": 140,
		"hit_rate": 0.85,
		"crit_rate_bonus": 0.15,
		"animation": "thunder",
		"icon": "⚡",
		"tier": 1,
		"level_requirement": 5
	})
	
	register_skill({
		"id": "chain_lightning",
		"name": "连锁闪电",
		"description": "闪电在敌人之间弹跳，造成多次伤害",
		"type": SkillType.ATTACK,
		"element": SkillElement.THUNDER,
		"target": TargetType.RANDOM_ENEMY,
		"ap_cost": 3,
		"mp_cost": 35,
		"cooldown": 2,
		"damage_type": "magical",
		"base_damage": 80,
		"hit_rate": 0.95,
		"chain_count": 3,
		"chain_damage_decay": 0.8,
		"animation": "chain_lightning",
		"icon": "⚡⚡",
		"tier": 2,
		"level_requirement": 10
	})
	
	# ========== 风系技能 ==========
	register_skill({
		"id": "wind_blade",
		"name": "风刃",
		"description": "召唤锋利的风刃攻击敌人",
		"type": SkillType.ATTACK,
		"element": SkillElement.WIND,
		"target": TargetType.SINGLE_ENEMY,
		"ap_cost": 2,
		"mp_cost": 16,
		"cooldown": 0,
		"damage_type": "magical",
		"base_damage": 125,
		"hit_rate": 0.98,
		"animation": "wind_blade",
		"icon": "🌀",
		"tier": 1,
		"level_requirement": 3
	})
	
	register_skill({
		"id": "tornado",
		"name": "龙卷风",
		"description": "召唤强大的龙卷风攻击全体敌人",
		"type": SkillType.ATTACK,
		"element": SkillElement.WIND,
		"target": TargetType.ALL_ENEMIES,
		"ap_cost": 3,
		"mp_cost": 50,
		"cooldown": 4,
		"damage_type": "magical",
		"base_damage": 110,
		"hit_rate": 0.85,
		"status_effect": {
			"stun": {"chance": 0.2, "duration": 1}
		},
		"animation": "tornado",
		"icon": "🌪️",
		"tier": 3,
		"level_requirement": 20
	})
	
	# ========== 水系技能 ==========
	register_skill({
		"id": "water_ball",
		"name": "水球术",
		"description": "发射水球攻击敌人",
		"type": SkillType.ATTACK,
		"element": SkillElement.WATER,
		"target": TargetType.SINGLE_ENEMY,
		"ap_cost": 2,
		"mp_cost": 14,
		"cooldown": 0,
		"damage_type": "magical",
		"base_damage": 115,
		"hit_rate": 0.95,
		"animation": "water_ball",
		"icon": "💧",
		"tier": 1,
		"level_requirement": 1
	})
	
	register_skill({
		"id": "healing_rain",
		"name": "治愈之雨",
		"description": "召唤治愈之雨，恢复全体友方生命",
		"type": SkillType.HEAL,
		"element": SkillElement.WATER,
		"target": TargetType.ALL_ALLIES,
		"ap_cost": 2,
		"mp_cost": 40,
		"cooldown": 3,
		"heal_type": "percentage",
		"heal_value": 30,  # 最大HP的30%
		"animation": "healing_rain",
		"icon": "🌧️💚",
		"tier": 2,
		"level_requirement": 12
	})
	
	# ========== 土系技能 ==========
	register_skill({
		"id": "rock_throw",
		"name": "投石",
		"description": "投掷巨石攻击敌人",
		"type": SkillType.ATTACK,
		"element": SkillElement.EARTH,
		"target": TargetType.SINGLE_ENEMY,
		"ap_cost": 2,
		"mp_cost": 18,
		"cooldown": 0,
		"damage_type": "physical",
		"base_damage": 135,
		"hit_rate": 0.90,
		"animation": "rock_throw",
		"icon": "🪨",
		"tier": 1,
		"level_requirement": 3
	})
	
	register_skill({
		"id": "earth_wall",
		"name": "土墙",
		"description": "召唤土墙保护全体友方，提升防御",
		"type": SkillType.BUFF,
		"element": SkillElement.EARTH,
		"target": TargetType.ALL_ALLIES,
		"ap_cost": 2,
		"mp_cost": 30,
		"cooldown": 4,
		"buff": {
			"pdef": 30,
			"duration": 3
		},
		"animation": "earth_wall",
		"icon": "🏰",
		"tier": 2,
		"level_requirement": 10
	})
	
	# ========== 辅助技能 ==========
	register_skill({
		"id": "heal",
		"name": "治疗术",
		"description": "恢复单体友方生命值",
		"type": SkillType.HEAL,
		"element": SkillElement.NONE,
		"target": TargetType.SINGLE_ALLY,
		"ap_cost": 2,
		"mp_cost": 20,
		"cooldown": 0,
		"heal_type": "flat",
		"heal_value": 80,
		"animation": "heal",
		"icon": "💚",
		"tier": 1,
		"level_requirement": 1
	})
	
	register_skill({
		"id": "greater_heal",
		"name": "高级治疗术",
		"description": "大幅恢复单体友方生命值",
		"type": SkillType.HEAL,
		"element": SkillElement.NONE,
		"target": TargetType.SINGLE_ALLY,
		"ap_cost": 3,
		"mp_cost": 45,
		"cooldown": 2,
		"heal_type": "percentage",
		"heal_value": 50,
		"animation": "heal",
		"icon": "💚✨",
		"tier": 2,
		"level_requirement": 15
	})
	
	register_skill({
		"id": "power_up",
		"name": "力量强化",
		"description": "提升自身攻击力",
		"type": SkillType.BUFF,
		"element": SkillElement.NONE,
		"target": TargetType.SELF,
		"ap_cost": 1,
		"mp_cost": 15,
		"cooldown": 3,
		"buff": {
			"patk": 25,
			"matk": 25,
			"duration": 3
		},
		"animation": "buff",
		"icon": "💪",
		"tier": 1,
		"level_requirement": 5
	})
	
	register_skill({
		"id": "shield",
		"name": "护盾",
		"description": "为目标添加护盾，吸收伤害",
		"type": SkillType.BUFF,
		"element": SkillElement.NONE,
		"target": TargetType.SINGLE_ALLY,
		"ap_cost": 2,
		"mp_cost": 25,
		"cooldown": 3,
		"shield_value": 100,
		"duration": 3,
		"animation": "shield",
		"icon": "🛡️✨",
		"tier": 1,
		"level_requirement": 8
	})
	
	# ========== 敌人技能 ==========
	register_skill({
		"id": "slime_split",
		"name": "分裂",
		"description": "史莱姆分裂成两个小史莱姆",
		"type": SkillType.SUMMON,
		"element": SkillElement.NONE,
		"target": TargetType.SELF,
		"ap_cost": 3,
		"mp_cost": 0,
		"cooldown": 5,
		"summon_id": "slime_green",
		"summon_count": 2,
		"summon_hp_percent": 0.3,
		"animation": "slime_split",
		"icon": "💧",
		"tier": 0,
		"enemy_only": true
	})
	
	register_skill({
		"id": "body_slam",
		"name": "身体冲撞",
		"description": "用身体猛烈撞击敌人",
		"type": SkillType.ATTACK,
		"element": SkillElement.NONE,
		"target": TargetType.SINGLE_ENEMY,
		"ap_cost": 2,
		"mp_cost": 0,
		"cooldown": 1,
		"damage_type": "physical",
		"base_damage": 140,
		"hit_rate": 0.85,
		"recoil_damage": 10,  # 反弹伤害
		"animation": "slam",
		"icon": "💥",
		"tier": 0,
		"enemy_only": true
	})
	
	register_skill({
		"id": "claw_strike",
		"name": "利爪攻击",
		"description": "用锋利的爪子攻击敌人",
		"type": SkillType.ATTACK,
		"element": SkillElement.NONE,
		"target": TargetType.SINGLE_ENEMY,
		"ap_cost": 2,
		"mp_cost": 0,
		"cooldown": 0,
		"damage_type": "physical",
		"base_damage": 120,
		"hit_rate": 0.92,
		"status_effect": {
			"bleed": {"chance": 0.2, "duration": 3, "damage": 8}
		},
		"animation": "claw",
		"icon": "🐺",
		"tier": 0,
		"enemy_only": true
	})
	
	register_skill({
		"id": "howl",
		"name": "嚎叫",
		"description": "发出震耳的嚎叫，提升自身攻击",
		"type": SkillType.BUFF,
		"element": SkillElement.NONE,
		"target": TargetType.SELF,
		"ap_cost": 1,
		"mp_cost": 0,
		"cooldown": 4,
		"buff": {
			"patk": 30,
			"speed": 20,
			"duration": 3
		},
		"animation": "howl",
		"icon": "🌙",
		"tier": 0,
		"enemy_only": true
	})
	
	register_skill({
		"id": "flame_breath",
		"name": "火焰吐息",
		"description": "龙类喷吐火焰攻击全体敌人",
		"type": SkillType.ATTACK,
		"element": SkillElement.FIRE,
		"target": TargetType.ALL_ENEMIES,
		"ap_cost": 3,
		"mp_cost": 0,
		"cooldown": 2,
		"damage_type": "magical",
		"base_damage": 150,
		"hit_rate": 0.90,
		"status_effect": {
			"burn": {"chance": 0.5, "duration": 3, "damage": 20}
		},
		"animation": "fire_breath",
		"icon": "🐉🔥",
		"tier": 0,
		"enemy_only": true
	})
	
	register_skill({
		"id": "dragon_roar",
		"name": "龙吼",
		"description": "发出恐怖的龙吼，降低敌方防御",
		"type": SkillType.DEBUFF,
		"element": SkillElement.NONE,
		"target": TargetType.ALL_ENEMIES,
		"ap_cost": 2,
		"mp_cost": 0,
		"cooldown": 3,
		"debuff": {
			"pdef": -20,
			"mdef": -20,
			"duration": 2
		},
		"animation": "roar",
		"icon": "🔊",
		"tier": 0,
		"enemy_only": true
	})
	
	register_skill({
		"id": "tail_sweep",
		"name": "尾击",
		"description": "用强有力的尾巴横扫敌人",
		"type": SkillType.ATTACK,
		"element": SkillElement.NONE,
		"target": TargetType.ALL_ENEMIES,
		"ap_cost": 2,
		"mp_cost": 0,
		"cooldown": 1,
		"damage_type": "physical",
		"base_damage": 100,
		"hit_rate": 0.95,
		"status_effect": {
			"stun": {"chance": 0.15, "duration": 1}
		},
		"animation": "tail_sweep",
		"icon": "🦎",
		"tier": 0,
		"enemy_only": true
	})

# ==================== 注册函数 ====================
static func register_skill(data: Dictionary) -> void:
	SKILLS[data.id] = data

static func get_skill(skill_id: String) -> Dictionary:
	return SKILLS.get(skill_id, {})

static func get_skills_by_element(element: SkillElement) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill_id in SKILLS:
		if SKILLS[skill_id].element == element:
			result.append(SKILLS[skill_id])
	return result

static func get_skills_by_type(type: SkillType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill_id in SKILLS:
		if SKILLS[skill_id].type == type:
			result.append(SKILLS[skill_id])
	return result

static func get_skills_by_tier(tier: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill_id in SKILLS:
		if SKILLS[skill_id].tier == tier:
			result.append(SKILLS[skill_id])
	return result

static func get_player_skills(level: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill_id in SKILLS:
		var skill = SKILLS[skill_id]
		if not skill.get("enemy_only", false):
			if skill.get("level_requirement", 0) <= level:
				result.append(skill)
	return result

static func get_enemy_skills() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill_id in SKILLS:
		if SKILLS[skill_id].get("enemy_only", false):
			result.append(SKILLS[skill_id])
	return result

static func calculate_damage(skill_id: String, attacker_stats: Dictionary, defender_stats: Dictionary) -> Dictionary:
	var skill = get_skill(skill_id)
	if skill.is_empty():
		return {"damage": 0, "is_crit": false, "is_hit": false}
	
	var result = {
		"damage": 0,
		"is_crit": false,
		"is_hit": false,
		"status_applied": null
	}
	
	# 命中判定
	var hit_rate = skill.get("hit_rate", 1.0)
	var eva_rate = defender_stats.get("eva_rate", 0.0)
	var final_hit_rate = clamp(hit_rate - eva_rate, 0.0, 1.0)
	
	if randf() > final_hit_rate:
		return result
	
	result.is_hit = true
	
	# 基础伤害计算
	var base_damage = skill.get("base_damage", 100)
	var damage_type = skill.get("damage_type", "physical")
	
	var attack_stat: float
	var defense_stat: float
	
	if damage_type == "physical":
		attack_stat = attacker_stats.get("patk", 10)
		defense_stat = defender_stats.get("pdef", 5)
	else:
		attack_stat = attacker_stats.get("matk", 10)
		defense_stat = defender_stats.get("mdef", 5)
	
	var damage = attack_stat * (base_damage / 100.0)
	damage = damage * (100.0 / (100.0 + defense_stat))
	
	# 暴击判定
	var crit_rate = attacker_stats.get("crit_rate", 0.05) + skill.get("crit_rate_bonus", 0.0)
	if randf() < crit_rate:
		var crit_dmg = attacker_stats.get("crit_dmg", 1.5)
		damage *= crit_dmg
		result.is_crit = true
	
	# 状态效果判定
	if skill.has("status_effect"):
		for status_name in skill.status_effect:
			var status_data = skill.status_effect[status_name]
			if randf() < status_data.chance:
				result.status_applied = {
					"name": status_name,
					"duration": status_data.duration,
					"damage": status_data.get("damage", 0)
				}
				break
	
	result.damage = max(1, int(damage))
	return result
