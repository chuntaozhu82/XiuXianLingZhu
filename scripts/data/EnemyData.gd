## EnemyData.gd
## 敌人数据库 - 存储所有敌人的配置数据
## 基于数值策划文档的敌人设计
extends Resource

class_name EnemyDataResource

# ==================== 敌人类型枚举 ====================
enum EnemyType { 
	NORMAL,    # 普通怪
	ELITE,     # 精英怪
	BOSS,      # BOSS
	SECRET     # 隐藏怪
}

enum EnemyElement {
	NONE,
	FIRE,
	ICE,
	WIND,
	EARTH,
	THUNDER,
	WATER
}

# ==================== 敌人数据结构 ====================
class EnemyDefinition:
	var id: String
	var name: String
	var description: String
	var type: EnemyType
	var element: EnemyElement
	
	# 基础属性
	var base_hp: int
	var base_patk: int
	var base_matk: int
	var base_pdef: int
	var base_mdef: int
	var base_speed: int
	
	# 成长系数
	var hp_growth: float = 1.0
	var patk_growth: float = 1.0
	var matk_growth: float = 1.0
	var pdef_growth: float = 1.0
	var mdef_growth: float = 1.0
	
	# 战利品
	var exp_reward: int
	var gold_reward: int
	var drop_table: Array[Dictionary] = []
	
	# 技能
	var skills: Array[Dictionary] = []
	
	# AI配置
	var ai_type: String = "aggressive"
	var aggro_range: float = 100.0

# ==================== 敌人数据库 ====================
static var ENEMIES: Dictionary = {}

static func _static_init():
	_register_all_enemies()

static func _register_all_enemies():
	# ========== 第一章：新手村 ==========
	register_enemy({
		"id": "slime_green",
		"name": "绿色史莱姆",
		"description": "最基础的史莱姆，新手练手的好对象",
		"type": EnemyType.NORMAL,
		"element": EnemyElement.NONE,
		"base_hp": 50,
		"base_patk": 8,
		"base_matk": 5,
		"base_pdef": 2,
		"base_mdef": 2,
		"base_speed": 80,
		"hp_growth": 1.15,
		"patk_growth": 1.12,
		"exp_reward": 10,
		"gold_reward": 5,
		"drop_table": [
			{"item_id": "hp_potion_small", "chance": 0.3},
			{"item_id": "slime_gel", "chance": 0.5}
		],
		"skills": [
			{"id": "basic_attack", "weight": 100}
		],
		"ai_type": "passive"
	})
	
	register_enemy({
		"id": "slime_blue",
		"name": "蓝色史莱姆",
		"description": "带有水元素的史莱姆，会使用水球攻击",
		"type": EnemyType.NORMAL,
		"element": EnemyElement.WATER,
		"base_hp": 60,
		"base_patk": 6,
		"base_matk": 12,
		"base_pdef": 3,
		"base_mdef": 5,
		"base_speed": 75,
		"hp_growth": 1.18,
		"matk_growth": 1.15,
		"exp_reward": 15,
		"gold_reward": 8,
		"drop_table": [
			{"item_id": "mp_potion_small", "chance": 0.25},
			{"item_id": "slime_gel", "chance": 0.5}
		],
		"skills": [
			{"id": "basic_attack", "weight": 60},
			{"id": "water_ball", "weight": 40}
		],
		"ai_type": "balanced"
	})
	
	register_enemy({
		"id": "slime_red",
		"name": "红色史莱姆",
		"description": "带有火元素的史莱姆，攻击力更强",
		"type": EnemyType.NORMAL,
		"element": EnemyElement.FIRE,
		"base_hp": 55,
		"base_patk": 14,
		"base_matk": 8,
		"base_pdef": 4,
		"base_mdef": 3,
		"base_speed": 85,
		"hp_growth": 1.16,
		"patk_growth": 1.18,
		"exp_reward": 18,
		"gold_reward": 10,
		"drop_table": [
			{"item_id": "hp_potion_small", "chance": 0.35},
			{"item_id": "fire_essence", "chance": 0.1}
		],
		"skills": [
			{"id": "basic_attack", "weight": 70},
			{"id": "flame_strike", "weight": 30}
		],
		"ai_type": "aggressive"
	})
	
	# ========== 精英怪 ==========
	register_enemy({
		"id": "slime_king",
		"name": "史莱姆王",
		"description": "史莱姆一族的王者，统领所有史莱姆",
		"type": EnemyType.ELITE,
		"element": EnemyElement.NONE,
		"base_hp": 500,
		"base_patk": 35,
		"base_matk": 25,
		"base_pdef": 20,
		"base_mdef": 15,
		"base_speed": 90,
		"hp_growth": 1.25,
		"exp_reward": 200,
		"gold_reward": 150,
		"drop_table": [
			{"item_id": "hp_potion_medium", "chance": 0.5},
			{"item_id": "slime_crown", "chance": 0.1},
			{"item_id": "skill_book_basic", "chance": 0.15}
		],
		"skills": [
			{"id": "basic_attack", "weight": 40},
			{"id": "slime_split", "weight": 30},
			{"id": "body_slam", "weight": 30}
		],
		"ai_type": "boss"
	})
	
	register_enemy({
		"id": "wolf_alpha",
		"name": "狼王",
		"description": "狼群的首领，极其凶猛",
		"type": EnemyType.ELITE,
		"element": EnemyElement.WIND,
		"base_hp": 400,
		"base_patk": 50,
		"base_matk": 10,
		"base_pdef": 25,
		"base_mdef": 10,
		"base_speed": 120,
		"hp_growth": 1.22,
		"patk_growth": 1.25,
		"exp_reward": 250,
		"gold_reward": 200,
		"drop_table": [
			{"item_id": "hp_potion_medium", "chance": 0.4},
			{"item_id": "wolf_fang", "chance": 0.3},
			{"item_id": "skill_book_wind", "chance": 0.1}
		],
		"skills": [
			{"id": "basic_attack", "weight": 35},
			{"id": "claw_strike", "weight": 35},
			{"id": "howl", "weight": 30}
		],
		"ai_type": "tactical"
	})
	
	# ========== BOSS ==========
	register_enemy({
		"id": "forest_guardian",
		"name": "森林守护者",
		"description": "守护森林的远古精灵，拥有强大的自然之力",
		"type": EnemyType.BOSS,
		"element": EnemyElement.WIND,
		"base_hp": 2000,
		"base_patk": 60,
		"base_matk": 80,
		"base_pdef": 40,
		"base_mdef": 50,
		"base_speed": 100,
		"hp_growth": 1.3,
		"exp_reward": 1000,
		"gold_reward": 500,
		"drop_table": [
			{"item_id": "hp_potion_large", "chance": 0.8},
			{"item_id": "mp_potion_large", "chance": 0.6},
			{"item_id": "wind_crystal", "chance": 0.3},
			{"item_id": "skill_book_nature", "chance": 0.2},
			{"item_id": "legendary_weapon", "chance": 0.05}
		],
		"skills": [
			{"id": "basic_attack", "weight": 20},
			{"id": "wind_blade", "weight": 25},
			{"id": "nature_blessing", "weight": 20},
			{"id": "entangle", "weight": 20},
			{"id": "tornado", "weight": 15}
		],
		"ai_type": "boss"
	})
	
	register_enemy({
		"id": "fire_dragon",
		"name": "炎龙",
		"description": "传说中的火龙，喷吐炽热的火焰",
		"type": EnemyType.BOSS,
		"element": EnemyElement.FIRE,
		"base_hp": 5000,
		"base_patk": 100,
		"base_matk": 150,
		"base_pdef": 80,
		"base_mdef": 60,
		"base_speed": 90,
		"hp_growth": 1.35,
		"exp_reward": 3000,
		"gold_reward": 2000,
		"drop_table": [
			{"item_id": "hp_potion_large", "chance": 1.0},
			{"item_id": "fire_crystal", "chance": 0.5},
			{"item_id": "dragon_scale", "chance": 0.4},
			{"item_id": "skill_book_fire", "chance": 0.3},
			{"item_id": "legendary_weapon", "chance": 0.1}
		],
		"skills": [
			{"id": "basic_attack", "weight": 15},
			{"id": "flame_breath", "weight": 25},
			{"id": "fire_storm", "weight": 20},
			{"id": "dragon_roar", "weight": 15},
			{"id": "tail_sweep", "weight": 25}
		],
		"ai_type": "boss"
	})

# ==================== 注册函数 ====================
static func register_enemy(data: Dictionary) -> void:
	ENEMIES[data.id] = data

static func get_enemy(enemy_id: String) -> Dictionary:
	return ENEMIES.get(enemy_id, {})

static func get_enemy_scaled(enemy_id: String, level: int) -> Dictionary:
	var base_data = get_enemy(enemy_id)
	if base_data.is_empty():
		return {}
	
	var scaled_data = base_data.duplicate(true)
	var level_diff = level - 1
	
	# 计算缩放属性
	scaled_data.current_hp = int(base_data.base_hp * base_data.get("hp_growth", 1.0) * level_diff)
	scaled_data.max_hp = scaled_data.current_hp
	scaled_data.patk = int(base_data.base_patk * base_data.get("patk_growth", 1.0) * level_diff)
	scaled_data.matk = int(base_data.base_matk * base_data.get("matk_growth", 1.0) * level_diff)
	scaled_data.pdef = int(base_data.base_pdef * base_data.get("pdef_growth", 1.0) * level_diff)
	scaled_data.mdef = int(base_data.base_mdef * base_data.get("mdef_growth", 1.0) * level_diff)
	scaled_data.speed = base_data.base_speed
	
	# 缩放奖励
	scaled_data.exp_reward = int(base_data.exp_reward * (1 + level_diff * 0.1))
	scaled_data.gold_reward = int(base_data.gold_reward * (1 + level_diff * 0.1))
	
	return scaled_data

static func get_enemies_by_type(type: EnemyType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enemy_id in ENEMIES:
		if ENEMIES[enemy_id].type == type:
			result.append(ENEMIES[enemy_id])
	return result

static func get_enemies_by_element(element: EnemyElement) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enemy_id in ENEMIES:
		if ENEMIES[enemy_id].element == element:
			result.append(ENEMIES[enemy_id])
	return result

static func get_random_enemy(type: EnemyType = EnemyType.NORMAL) -> Dictionary:
	var enemies = get_enemies_by_type(type)
	if enemies.is_empty():
		return {}
	return enemies[randi() % enemies.size()]
