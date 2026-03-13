## ItemData.gd
## 物品数据库 - 存储所有物品的配置数据
## 包含武器、防具、消耗品、材料等
extends Resource

class_name ItemDataResource

# ==================== 物品类型枚举 ====================
enum ItemType {
	WEAPON,      # 武器
	ARMOR,       # 防具
	ACCESSORY,   # 饰品
	CONSUMABLE,  # 消耗品
	MATERIAL,    # 材料
	QUEST,       # 任务物品
	SKILL_BOOK   # 技能书
}

enum ItemRarity {
	COMMON = 1,    # 普通(白)
	UNCOMMON = 2,  # 优秀(绿)
	RARE = 3,      # 稀有(蓝)
	EPIC = 4,      # 史诗(紫)
	LEGENDARY = 5  # 传说(金)
}

enum EquipSlot {
	WEAPON,
	HEAD,
	CHEST,
	LEGS,
	FEET,
	HANDS,
	NECKLACE,
	RING,
	ACCESSORY
}

# ==================== 物品数据库 ====================
static var ITEMS: Dictionary = {}

static func _static_init():
	_register_all_items()

static func _register_all_items():
	# ========== 武器 ==========
	register_item({
		"id": "sword_wooden",
		"name": "木剑",
		"description": "新手村标配的木剑，勉强能用",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.COMMON,
		"slot": EquipSlot.WEAPON,
		"stats": {
			"patk": 5
		},
		"level_requirement": 1,
		"buy_price": 50,
		"sell_price": 10,
		"icon": "🗡️",
		"stackable": false
	})
	
	register_item({
		"id": "sword_iron",
		"name": "铁剑",
		"description": "普通的铁剑，结实耐用",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.UNCOMMON,
		"slot": EquipSlot.WEAPON,
		"stats": {
			"patk": 15,
			"crit_rate": 0.02
		},
		"level_requirement": 5,
		"buy_price": 200,
		"sell_price": 50,
		"icon": "⚔️",
		"stackable": false
	})
	
	register_item({
		"id": "sword_flame",
		"name": "炎之剑",
		"description": "附有火焰魔法的剑，攻击时有几率灼烧敌人",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.RARE,
		"slot": EquipSlot.WEAPON,
		"stats": {
			"patk": 30,
			"matk": 10,
			"crit_rate": 0.05,
			"crit_dmg": 0.1
		},
		"effects": [
			{"type": "burn", "chance": 0.1, "value": 10}
		],
		"element": "fire",
		"level_requirement": 15,
		"buy_price": 1500,
		"sell_price": 400,
		"icon": "🔥⚔️",
		"stackable": false
	})
	
	register_item({
		"id": "staff_apprentice",
		"name": "学徒法杖",
		"description": "法修专用的初级法杖",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.COMMON,
		"slot": EquipSlot.WEAPON,
		"stats": {
			"matk": 8,
			"max_mp": 20
		},
		"level_requirement": 1,
		"buy_price": 60,
		"sell_price": 15,
		"icon": "🪄",
		"stackable": false,
		"class_requirement": ["法修"]
	})
	
	# ========== 防具 ==========
	register_item({
		"id": "armor_cloth",
		"name": "布甲",
		"description": "最基础的布甲，聊胜于无",
		"type": ItemType.ARMOR,
		"rarity": ItemRarity.COMMON,
		"slot": EquipSlot.CHEST,
		"stats": {
			"pdef": 3,
			"mdef": 3,
			"max_hp": 10
		},
		"level_requirement": 1,
		"buy_price": 40,
		"sell_price": 8,
		"icon": "👕",
		"stackable": false
	})
	
	register_item({
		"id": "armor_leather",
		"name": "皮甲",
		"description": "轻便的皮革护甲，提供不错的防护",
		"type": ItemType.ARMOR,
		"rarity": ItemRarity.UNCOMMON,
		"slot": EquipSlot.CHEST,
		"stats": {
			"pdef": 10,
			"mdef": 5,
			"max_hp": 30,
			"eva_rate": 0.02
		},
		"level_requirement": 5,
		"buy_price": 250,
		"sell_price": 60,
		"icon": "🦺",
		"stackable": false
	})
	
	register_item({
		"id": "armor_plate",
		"name": "板甲",
		"description": "厚重的金属铠甲，防御极高但影响速度",
		"type": ItemType.ARMOR,
		"rarity": ItemRarity.RARE,
		"slot": EquipSlot.CHEST,
		"stats": {
			"pdef": 25,
			"mdef": 10,
			"max_hp": 100,
			"speed": -10
		},
		"level_requirement": 15,
		"buy_price": 1200,
		"sell_price": 300,
		"icon": "🛡️",
		"stackable": false
	})
	
	# ========== 消耗品 ==========
	register_item({
		"id": "hp_potion_small",
		"name": "小型生命药水",
		"description": "恢复50点HP",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.COMMON,
		"effect": {
			"type": "heal_hp",
			"value": 50
		},
		"cooldown": 5.0,
		"buy_price": 25,
		"sell_price": 5,
		"icon": "🧪",
		"stackable": true,
		"max_stack": 99
	})
	
	register_item({
		"id": "hp_potion_medium",
		"name": "中型生命药水",
		"description": "恢复150点HP",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.UNCOMMON,
		"effect": {
			"type": "heal_hp",
			"value": 150
		},
		"cooldown": 5.0,
		"buy_price": 80,
		"sell_price": 20,
		"icon": "🧪",
		"stackable": true,
		"max_stack": 99
	})
	
	register_item({
		"id": "hp_potion_large",
		"name": "大型生命药水",
		"description": "恢复400点HP",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.RARE,
		"effect": {
			"type": "heal_hp",
			"value": 400
		},
		"cooldown": 5.0,
		"buy_price": 200,
		"sell_price": 50,
		"icon": "🧪",
		"stackable": true,
		"max_stack": 99
	})
	
	register_item({
		"id": "mp_potion_small",
		"name": "小型法力药水",
		"description": "恢复30点MP",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.COMMON,
		"effect": {
			"type": "heal_mp",
			"value": 30
		},
		"cooldown": 5.0,
		"buy_price": 30,
		"sell_price": 8,
		"icon": "💙",
		"stackable": true,
		"max_stack": 99
	})
	
	register_item({
		"id": "mp_potion_large",
		"name": "大型法力药水",
		"description": "恢复200点MP",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.RARE,
		"effect": {
			"type": "heal_mp",
			"value": 200
		},
		"cooldown": 5.0,
		"buy_price": 250,
		"sell_price": 60,
		"icon": "💙",
		"stackable": true,
		"max_stack": 99
	})
	
	register_item({
		"id": "antidote",
		"name": "解毒药",
		"description": "解除中毒状态",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.COMMON,
		"effect": {
			"type": "remove_status",
			"status": "poison"
		},
		"cooldown": 3.0,
		"buy_price": 50,
		"sell_price": 12,
		"icon": "💊",
		"stackable": true,
		"max_stack": 99
	})
	
	# ========== 材料 ==========
	register_item({
		"id": "slime_gel",
		"name": "史莱姆凝胶",
		"description": "史莱姆身上的粘液，可用于制作药水",
		"type": ItemType.MATERIAL,
		"rarity": ItemRarity.COMMON,
		"buy_price": 5,
		"sell_price": 2,
		"icon": "💧",
		"stackable": true,
		"max_stack": 999
	})
	
	register_item({
		"id": "fire_essence",
		"name": "火元素精华",
		"description": "蕴含火元素力量的精华，可用于附魔",
		"type": ItemType.MATERIAL,
		"rarity": ItemRarity.RARE,
		"buy_price": 200,
		"sell_price": 50,
		"icon": "🔥",
		"stackable": true,
		"max_stack": 99
	})
	
	register_item({
		"id": "wolf_fang",
		"name": "狼牙",
		"description": "锋利的狼牙，可用于制作武器",
		"type": ItemType.MATERIAL,
		"rarity": ItemRarity.UNCOMMON,
		"buy_price": 50,
		"sell_price": 15,
		"icon": "🦷",
		"stackable": true,
		"max_stack": 99
	})
	
	register_item({
		"id": "dragon_scale",
		"name": "龙鳞",
		"description": "传说中的龙鳞，极其珍贵的材料",
		"type": ItemType.MATERIAL,
		"rarity": ItemRarity.LEGENDARY,
		"buy_price": 5000,
		"sell_price": 2000,
		"icon": "🐉",
		"stackable": true,
		"max_stack": 10
	})
	
	# ========== 技能书 ==========
	register_item({
		"id": "skill_book_basic",
		"name": "基础技能书",
		"description": "可以随机学习一个基础技能",
		"type": ItemType.SKILL_BOOK,
		"rarity": ItemRarity.UNCOMMON,
		"effect": {
			"type": "learn_skill",
			"tier": "basic"
		},
		"buy_price": 500,
		"sell_price": 100,
		"icon": "📕",
		"stackable": true,
		"max_stack": 10
	})
	
	register_item({
		"id": "skill_book_fire",
		"name": "火系技能书",
		"description": "可以随机学习一个火系技能",
		"type": ItemType.SKILL_BOOK,
		"rarity": ItemRarity.RARE,
		"effect": {
			"type": "learn_skill",
			"element": "fire"
		},
		"buy_price": 2000,
		"sell_price": 500,
		"icon": "📕",
		"stackable": true,
		"max_stack": 10
	})

# ==================== 注册函数 ====================
static func register_item(data: Dictionary) -> void:
	ITEMS[data.id] = data

static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})

static func get_items_by_type(type: ItemType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in ITEMS:
		if ITEMS[item_id].type == type:
			result.append(ITEMS[item_id])
	return result

static func get_items_by_rarity(rarity: ItemRarity) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in ITEMS:
		if ITEMS[item_id].rarity == rarity:
			result.append(ITEMS[item_id])
	return result

static func get_equipment_for_slot(slot: EquipSlot) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in ITEMS:
		if ITEMS[item_id].get("slot") == slot:
			result.append(ITEMS[item_id])
	return result

static func get_usable_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in ITEMS:
		if ITEMS[item_id].type == ItemType.CONSUMABLE:
			result.append(ITEMS[item_id])
	return result

static func can_use_item(item_id: String, user_stats: Dictionary) -> bool:
	var item = get_item(item_id)
	if item.is_empty():
		return false
	
	if item.type != ItemType.CONSUMABLE:
		return false
	
	# 检查等级要求
	if item.get("level_requirement", 1) > user_stats.get("level", 1):
		return false
	
	return true

static func use_item(item_id: String, user: Node) -> Dictionary:
	var item = get_item(item_id)
	if item.is_empty():
		return {"success": false, "message": "物品不存在"}
	
	var effect = item.get("effect", {})
	var result = {"success": true, "message": ""}
	
	match effect.type:
		"heal_hp":
			if user.has_method("heal"):
				user.heal(effect.value)
				result.message = "恢复了%d点HP" % effect.value
		"heal_mp":
			if user.has_method("restore_mp"):
				user.restore_mp(effect.value)
				result.message = "恢复了%d点MP" % effect.value
		"remove_status":
			if user.has_method("remove_status"):
				user.remove_status(effect.status)
				result.message = "解除了%s状态" % effect.status
		"learn_skill":
			result.message = "学习了新技能"
			# TODO: 实现技能学习逻辑
		_:
			result.success = false
			result.message = "未知效果类型"
	
	return result
