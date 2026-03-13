## PlayerData.gd
## 玩家数据模型 - 管理玩家属性、装备、技能、背包等核心数据
## 基于数值策划文档实现的完整数据系统
extends Node

# ==================== 信号 ====================
signal stats_changed(stat_name: String, old_value: float, new_value: float)
signal hp_changed(current: float, maximum: float)
signal mp_changed(current: float, maximum: float)
signal level_changed(new_level: int)
signal exp_changed(current: int, required: int)
signal gold_changed(amount: int)
signal diamond_changed(amount: int)
signal equipment_changed(slot: String, equipment: Dictionary)
signal skill_unlocked(skill_id: String)
signal inventory_updated()

# ==================== 基础信息 ====================
var player_name: String = "修士"
var player_level: int = 1
var player_class: String = "剑修"  # 职业：剑修、法修、体修
var current_exp: int = 0

# ==================== 核心属性 ====================
# 基础属性值（1级）
const BASE_STATS = {
	"max_hp": 100,      # 生命上限
	"max_mp": 50,       # 法力上限
	"patk": 20,         # 物理攻击
	"matk": 20,         # 魔法攻击
	"pdef": 10,         # 物理防御
	"mdef": 10,         # 魔法防御
	"speed": 100,       # 速度
	"crit_rate": 0.05,  # 暴击率 (5%)
	"crit_dmg": 1.5,    # 暴击伤害 (150%)
	"hit_rate": 0.95,   # 命中率 (95%)
	"eva_rate": 0.05    # 闪避率 (5%)
}

# 成长系数
const GROWTH_RATES = {
	"max_hp": 15,
	"max_mp": 8,
	"patk": 3,
	"matk": 3,
	"pdef": 2,
	"mdef": 2,
	"speed": 1,
	"crit_rate": 0.001,   # 每级+0.1%
	"crit_dmg": 0.005,    # 每级+0.5%
	"hit_rate": 0.0005,   # 每级+0.05%
	"eva_rate": 0.0005    # 每级+0.05%
}

# 当前属性值（基础+装备+buff）
var stats: Dictionary = {}

# 当前HP/MP
var current_hp: float = 100
var current_mp: float = 50

# ==================== AP行动点系统 ====================
var base_ap: int = 3          # 基础AP
var bonus_ap: int = 0         # 额外AP（从装备/buff获得）
var current_ap: int = 3       # 当前AP

# ==================== 元素亲和 ====================
enum Element { FIRE, ICE, THUNDER, WIND, EARTH, DARK }
var element_affinity: Dictionary = {
	Element.FIRE: 0,      # 火元素亲和度
	Element.ICE: 0,       # 冰元素亲和度
	Element.THUNDER: 0,   # 雷元素亲和度
	Element.WIND: 0,      # 风元素亲和度
	Element.EARTH: 0,     # 土元素亲和度
	Element.DARK: 0       # 暗元素亲和度
}

# ==================== 装备系统 ====================
enum EquipSlot { WEAPON, ARMOR, HELMET, ACCESSORY, ARTIFACT }
var equipment: Dictionary = {
	EquipSlot.WEAPON: null,
	EquipSlot.ARMOR: null,
	EquipSlot.HELMET: null,
	EquipSlot.ACCESSORY: null,
	EquipSlot.ARTIFACT: null
}

# ==================== 技能系统 ====================
var unlocked_skills: Array[String] = []   # 已解锁技能ID列表
var equipped_skills: Array[String] = []   # 装备的技能（最多4个）
var skill_levels: Dictionary = {}         # 技能等级 {skill_id: level}

# ==================== 背包系统 ====================
const MAX_INVENTORY_SIZE: int = 100
var inventory: Array[Dictionary] = []     # 物品列表 [{id, count, data}]
var inventory_max_size: int = 100

# ==================== 战斗相关 ====================
var last_location: String = "world"
var current_battle_enemy: Dictionary = {}
var current_battle_enemies: Array[Dictionary] = []

# ==================== 货币系统 ====================
var gold: int = 1000           # 金币
var diamond: int = 0           # 钻石
var spirit_stone: int = 0      # 灵石
var medal: int = 0             # 勋章
var guild_coin: int = 0        # 公会币

# ==================== 成长系统 ====================
var attribute_points: int = 0  # 可分配属性点
var cultivation: int = 0       # 修为值（用于突破）

# ==================== 初始化 ====================
func _ready() -> void:
	_initialize_stats()
	_connect_signals()

func _initialize_stats() -> void:
	"""初始化所有属性"""
	for stat_name in BASE_STATS:
		stats[stat_name] = BASE_STATS[stat_name]
	
	# 根据等级计算属性
	_recalculate_stats()

func _connect_signals() -> void:
	"""连接内部信号"""
	pass

# ==================== 等级与经验系统 ====================
func get_exp_required_for_level(level: int) -> int:
	"""计算升级所需经验值（指数增长）"""
	# 公式: 100 × 等级² × 1.2^(等级-1)
	return int(100 * level * level * pow(1.2, level - 1))

func add_exp(amount: int) -> void:
	"""增加经验值"""
	current_exp += amount
	
	# 检查升级
	while current_exp >= get_exp_required_for_level(player_level):
		current_exp -= get_exp_required_for_level(player_level)
		level_up()
	
	exp_changed.emit(current_exp, get_exp_required_for_level(player_level))

func level_up() -> void:
	"""升级处理"""
	var old_level = player_level
	player_level += 1
	attribute_points += 3  # 每级获得3点属性点
	
	_recalculate_stats()
	
	# 升级时恢复满HP/MP
	current_hp = stats.max_hp
	current_mp = stats.max_mp
	
	level_changed.emit(player_level)
	print("升级！当前等级: %d" % player_level)

# ==================== 属性计算系统 ====================
func _recalculate_stats() -> void:
	"""重新计算所有属性（基础+等级成长+装备加成）"""
	for stat_name in BASE_STATS:
		var base_value = BASE_STATS[stat_name]
		var growth = GROWTH_RATES[stat_name]
		var level_bonus = (player_level - 1) * growth
		var equip_bonus = _get_equipment_bonus(stat_name)
		var buff_bonus = _get_buff_bonus(stat_name)
		
		var old_value = stats.get(stat_name, 0)
		var new_value = base_value + level_bonus + equip_bonus + buff_bonus
		
		stats[stat_name] = new_value
		
		if old_value != new_value:
			stats_changed.emit(stat_name, old_value, new_value)
	
	# 更新当前HP/MP不超过上限
	current_hp = min(current_hp, stats.max_hp)
	current_mp = min(current_mp, stats.max_mp)

func _get_equipment_bonus(stat_name: String) -> float:
	"""获取装备加成"""
	var total_bonus: float = 0.0
	
	for slot in equipment:
		var equip = equipment[slot]
		if equip and equip.has("stats"):
			total_bonus += equip.stats.get(stat_name, 0)
	
	return total_bonus

func _get_buff_bonus(stat_name: String) -> float:
	"""获取Buff加成（待实现状态效果系统）"""
	return 0.0

# ==================== HP/MP管理 ====================
func take_damage(amount: float) -> void:
	"""受到伤害"""
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(current_hp, stats.max_hp)
	
	if current_hp <= 0:
		_on_death()

func heal(amount: float) -> void:
	"""治疗"""
	current_hp = min(stats.max_hp, current_hp + amount)
	hp_changed.emit(current_hp, stats.max_hp)

func use_mp(amount: float) -> bool:
	"""消耗MP，返回是否成功"""
	if current_mp >= amount:
		current_mp -= amount
		mp_changed.emit(current_mp, stats.max_mp)
		return true
	return false

func recover_mp(amount: float) -> void:
	"""恢复MP"""
	current_mp = min(stats.max_mp, current_mp + amount)
	mp_changed.emit(current_mp, stats.max_mp)

func _on_death() -> void:
	"""死亡处理"""
	print("玩家死亡！")
	# TODO: 触发死亡事件

# ==================== AP行动点系统 ====================
func get_max_ap() -> int:
	"""获取最大AP"""
	return base_ap + bonus_ap

func use_ap(amount: int) -> bool:
	"""消耗AP，返回是否成功"""
	if current_ap >= amount:
		current_ap -= amount
		return true
	return false

func recover_ap(amount: int = 1) -> void:
	"""恢复AP"""
	current_ap = min(get_max_ap(), current_ap + amount)

func reset_ap() -> void:
	"""重置AP（新回合开始）"""
	current_ap = get_max_ap()

# ==================== 装备系统 ====================
func equip_item(slot: EquipSlot, item: Dictionary) -> Dictionary:
	"""装备物品，返回被替换的装备"""
	var old_equipment = equipment[slot]
	equipment[slot] = item
	_recalculate_stats()
	equipment_changed.emit(EquipSlot.keys()[slot], item)
	return old_equipment if old_equipment else {}

func unequip_item(slot: EquipSlot) -> Dictionary:
	"""卸下装备"""
	var old_equipment = equipment[slot]
	equipment[slot] = null
	_recalculate_stats()
	equipment_changed.emit(EquipSlot.keys()[slot], {})
	return old_equipment if old_equipment else {}

# ==================== 技能系统 ====================
func unlock_skill(skill_id: String) -> void:
	"""解锁技能"""
	if skill_id not in unlocked_skills:
		unlocked_skills.append(skill_id)
		skill_levels[skill_id] = 1
		skill_unlocked.emit(skill_id)

func equip_skill(skill_id: String, slot: int = -1) -> bool:
	"""装备技能到快捷栏"""
	if skill_id not in unlocked_skills:
		return false
	
	if skill_id in equipped_skills:
		return false
	
	if equipped_skills.size() >= 4:
		return false
	
	if slot >= 0 and slot < 4:
		equipped_skills.insert(slot, skill_id)
	else:
		equipped_skills.append(skill_id)
	
	return true

func unequip_skill(skill_id: String) -> void:
	"""卸下技能"""
	equipped_skills.erase(skill_id)

func upgrade_skill(skill_id: String) -> bool:
	"""升级技能"""
	if skill_id not in skill_levels:
		return false
	
	if attribute_points <= 0:
		return false
	
	attribute_points -= 1
	skill_levels[skill_id] += 1
	return true

func get_skill_level(skill_id: String) -> int:
	"""获取技能等级"""
	return skill_levels.get(skill_id, 0)

func equip_skill_to_slot(skill_id: String, slot: int) -> bool:
	"""装备技能到指定槽位"""
	if skill_id not in unlocked_skills:
		return false
	
	if slot < 0 or slot >= 4:
		return false
	
	# 检查该槽位是否已有技能
	if equipped_skills.size() > slot and equipped_skills[slot] != "":
		# 先卸下原技能
		equipped_skills[slot] = skill_id
	else:
		# 确保数组大小足够
		while equipped_skills.size() <= slot:
			equipped_skills.append("")
		equipped_skills[slot] = skill_id
	
	return true

func can_equip(item_data: Dictionary) -> bool:
	"""检查是否可以装备物品"""
	var level_req = item_data.get("level_requirement", 1)
	if player_level < level_req:
		return false
	
	# 检查职业要求
	var class_req = item_data.get("class_requirement", [])
	if not class_req.is_empty() and player_class not in class_req:
		return false
	
	return true

# ==================== 背包系统 ====================
func add_item(item_id: String, count: int = 1, item_data: Dictionary = {}) -> bool:
	"""添加物品到背包"""
	# 检查是否已有该物品（堆叠）
	for item in inventory:
		if item.id == item_id:
			item.count += count
			inventory_updated.emit()
			return true
	
	# 检查背包空间
	if inventory.size() >= inventory_max_size:
		return false
	
	# 添加新物品
	inventory.append({
		"id": item_id,
		"count": count,
		"data": item_data
	})
	inventory_updated.emit()
	return true

func remove_item(item_id: String, count: int = 1) -> bool:
	"""移除物品"""
	for i in range(inventory.size()):
		if inventory[i].id == item_id:
			if inventory[i].count >= count:
				inventory[i].count -= count
				if inventory[i].count <= 0:
					inventory.remove_at(i)
				inventory_updated.emit()
				return true
	return false

func get_item_count(item_id: String) -> int:
	"""获取物品数量"""
	for item in inventory:
		if item.id == item_id:
			return item.count
	return 0

# ==================== 货币系统 ====================
func add_gold(amount: int) -> void:
	"""增加金币"""
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	"""花费金币"""
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

func add_diamond(amount: int) -> void:
	"""增加钻石"""
	diamond += amount
	diamond_changed.emit(diamond)

func spend_diamond(amount: int) -> bool:
	"""花费钻石"""
	if diamond >= amount:
		diamond -= amount
		diamond_changed.emit(diamond)
		return true
	return false

# ==================== 元素系统 ====================
func get_element_damage_bonus(element: Element) -> float:
	"""获取元素伤害加成"""
	return 1.0 + element_affinity[element] * 0.01  # 每点亲和度+1%伤害

func add_element_affinity(element: Element, amount: int) -> void:
	"""增加元素亲和度"""
	element_affinity[element] += amount

# ==================== 属性点分配 ====================
func allocate_attribute_point(stat_name: String) -> bool:
	"""分配属性点"""
	if attribute_points <= 0:
		return false
	
	if stat_name in stats:
		stats[stat_name] += 1
		attribute_points -= 1
		stats_changed.emit(stat_name, stats[stat_name] - 1, stats[stat_name])
		return true
	
	return false

# ==================== 战斗力计算 ====================
func get_combat_power() -> int:
	"""计算战斗力"""
	# 公式: (HP/10 + MP/5 + ATK*2 + DEF*1.5 + SPD*0.5) * (1 + CRIT_RATE*CRIT_DMG)
	var base_power = (
		stats.max_hp / 10.0 +
		stats.max_mp / 5.0 +
		(stats.patk + stats.matk) * 2.0 +
		(stats.pdef + stats.mdef) * 1.5 +
		stats.speed * 0.5
	)
	
	var crit_bonus = 1.0 + stats.crit_rate * stats.crit_dmg
	
	return int(base_power * crit_bonus)

# ==================== 辅助方法 ====================
func get_current_stat(stat_name: String) -> float:
	"""获取当前属性值"""
	return stats.get(stat_name, BASE_STATS.get(stat_name, 0))

func has_skill(skill_id: String) -> bool:
	"""检查是否已解锁技能"""
	return skill_id in unlocked_skills

func add_experience(amount: int) -> void:
	"""增加经验值（add_exp的别名）"""
	add_exp(amount)

func reset_to_default() -> void:
	"""重置为默认状态"""
	player_name = "修士"
	player_level = 1
	player_class = "剑修"
	current_exp = 0
	gold = 1000
	diamond = 0
	spirit_stone = 0
	medal = 0
	guild_coin = 0
	attribute_points = 0
	cultivation = 0
	unlocked_skills.clear()
	equipped_skills.clear()
	skill_levels.clear()
	inventory.clear()
	
	for slot in equipment:
		equipment[slot] = null
	
	for element in element_affinity:
		element_affinity[element] = 0
	
	_initialize_stats()
	current_hp = stats.max_hp
	current_mp = stats.max_mp

# ==================== 数据保存/加载 ====================
func save_data() -> Dictionary:
	"""保存玩家数据"""
	return {
		"name": player_name,
		"level": player_level,
		"class": player_class,
		"exp": current_exp,
		"stats": stats,
		"current_hp": current_hp,
		"current_mp": current_mp,
		"equipment": equipment,
		"skills": {
			"unlocked": unlocked_skills,
			"equipped": equipped_skills,
			"levels": skill_levels
		},
		"inventory": inventory,
		"currencies": {
			"gold": gold,
			"diamond": diamond,
			"spirit_stone": spirit_stone
		},
		"element_affinity": element_affinity,
		"attribute_points": attribute_points
	}

func load_data(data: Dictionary) -> void:
	"""加载玩家数据"""
	player_name = data.get("name", "修士")
	player_level = data.get("level", 1)
	player_class = data.get("class", "剑修")
	current_exp = data.get("exp", 0)
	stats = data.get("stats", BASE_STATS.duplicate())
	current_hp = data.get("current_hp", stats.max_hp)
	current_mp = data.get("current_mp", stats.max_mp)
	equipment = data.get("equipment", {})
	
	var skills_data = data.get("skills", {})
	unlocked_skills = skills_data.get("unlocked", [])
	equipped_skills = skills_data.get("equipped", [])
	skill_levels = skills_data.get("levels", {})
	
	inventory = data.get("inventory", [])
	
	var currencies = data.get("currencies", {})
	gold = currencies.get("gold", 1000)
	diamond = currencies.get("diamond", 0)
	spirit_stone = currencies.get("spirit_stone", 0)
	
	element_affinity = data.get("element_affinity", {})
	attribute_points = data.get("attribute_points", 0)
	
	_recalculate_stats()
