## CombatUnit.gd
## 战斗单位基类 - 玩家和敌人的共同基类
## 包含属性、状态效果、技能等战斗相关功能
extends Node

# ==================== 信号 ====================
signal hp_changed(current: float, maximum: float)
signal mp_changed(current: float, maximum: float)
signal ap_changed(current: int, maximum: int)
signal status_added(status_name: String)
signal status_removed(status_name: String)
signal unit_died()

# ==================== 基础信息 ====================
@export var unit_name: String = "Unknown"
@export var unit_level: int = 1
@export var unit_element: String = "neutral"  # fire/ice/thunder/wind/earth/dark/neutral

# ==================== 核心属性 ====================
var stats: Dictionary = {
	"max_hp": 100.0,
	"max_mp": 50.0,
	"patk": 20.0,
	"matk": 20.0,
	"pdef": 10.0,
	"mdef": 10.0,
	"speed": 100.0,
	"crit_rate": 0.05,
	"crit_dmg": 1.5,
	"hit_rate": 0.95,
	"eva_rate": 0.05
}

# ==================== 战斗状态 ====================
var current_hp: float = 100.0
var current_mp: float = 50.0
var current_ap: int = 3
var max_ap: int = 3

# ==================== 状态效果系统 ====================
var active_status: Dictionary = {}  # {status_name: {duration: int, params: Dictionary}}

# ==================== 技能列表 ====================
var skills: Array[Dictionary] = []

# ==================== 初始化 ====================
func _ready() -> void:
	current_hp = stats.max_hp
	current_mp = stats.max_mp
	current_ap = max_ap

func initialize_for_combat() -> void:
	"""战斗初始化"""
	current_hp = stats.max_hp
	current_mp = stats.max_mp
	current_ap = max_ap
	active_status.clear()

# ==================== 属性访问 ====================
func get_stat(stat_name: String, default: float = 0.0) -> float:
	"""获取属性值"""
	return stats.get(stat_name, default)

func set_stat(stat_name: String, value: float) -> void:
	"""设置属性值"""
	stats[stat_name] = value

func get_level() -> int:
	return unit_level

func get_name() -> String:
	return unit_name

func get_element() -> String:
	return unit_element

func get_speed() -> float:
	return get_stat("speed", 100.0)

# ==================== HP/MP管理 ====================
func get_current_hp() -> float:
	return current_hp

func get_current_mp() -> float:
	return current_mp

func get_current_ap() -> int:
	return current_ap

func take_damage(amount: float) -> void:
	"""受到伤害"""
	# 检查防御状态
	if has_status("defending"):
		var damage_reduction = get_status_param("defending", "damage_reduction", 0.5)
		amount *= (1.0 - damage_reduction)
	
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(current_hp, stats.max_hp)
	
	if current_hp <= 0:
		on_death()

func heal(amount: float) -> void:
	"""治疗"""
	current_hp = min(stats.max_hp, current_hp + amount)
	hp_changed.emit(current_hp, stats.max_hp)

func use_mp(amount: float) -> bool:
	"""消耗MP"""
	if current_mp >= amount:
		current_mp -= amount
		mp_changed.emit(current_mp, stats.max_mp)
		return true
	return false

func recover_mp(amount: float) -> void:
	"""恢复MP"""
	current_mp = min(stats.max_mp, current_mp + amount)
	mp_changed.emit(current_mp, stats.max_mp)

func use_ap(amount: int) -> bool:
	"""消耗AP"""
	if current_ap >= amount:
		current_ap -= amount
		ap_changed.emit(current_ap, max_ap)
		return true
	return false

func recover_ap(amount: int = 1) -> void:
	"""恢复AP"""
	current_ap = min(max_ap, current_ap + amount)
	ap_changed.emit(current_ap, max_ap)

func is_alive() -> bool:
	return current_hp > 0

func on_death() -> void:
	"""死亡处理"""
	unit_died.emit()

# ==================== 状态效果系统 ====================
func add_status(status_name: String, duration: int, params: Dictionary = {}) -> void:
	"""添加状态效果"""
	active_status[status_name] = {
		"duration": duration,
		"params": params
	}
	status_added.emit(status_name)

func remove_status(status_name: String) -> void:
	"""移除状态效果"""
	active_status.erase(status_name)
	status_removed.emit(status_name)

func has_status(status_name: String) -> bool:
	return active_status.has(status_name)

func get_status_param(status_name: String, param_name: String, default = null) -> Variant:
	"""获取状态效果参数"""
	if active_status.has(status_name):
		return active_status[status_name].params.get(param_name, default)
	return default

func decrease_status_duration(status_name: String) -> void:
	"""减少状态效果持续时间"""
	if active_status.has(status_name):
		active_status[status_name].duration -= 1

func get_active_status() -> Dictionary:
	return active_status

# ==================== 技能系统 ====================
func get_available_skills() -> Array[Dictionary]:
	"""获取可用技能列表（AP和MP足够）"""
	var available: Array[Dictionary] = []
	
	for skill in skills:
		var ap_cost = skill.get("ap_cost", 1)
		var mp_cost = skill.get("mp_cost", 0)
		
		if current_ap >= ap_cost and current_mp >= mp_cost:
			available.append(skill)
	
	return available

func add_skill(skill: Dictionary) -> void:
	skills.append(skill)

func can_use_skill(skill_id: String) -> bool:
	"""检查是否可以使用指定技能"""
	for skill in skills:
		if skill.get("id", "") == skill_id:
			var ap_cost = skill.get("ap_cost", 1)
			var mp_cost = skill.get("mp_cost", 0)
			return current_ap >= ap_cost and current_mp >= mp_cost
	return false

func process_status_effects() -> void:
	"""处理状态效果（每回合开始时调用）"""
	var expired_status: Array[String] = []
	
	for status_name in active_status:
		var status = active_status[status_name]
		
		# 应用持续伤害/治疗
		match status_name:
			"poison":
				var poison_damage = stats.max_hp * 0.05  # 5% HP
				take_damage(poison_damage)
			"burn":
				var burn_damage = stats.max_hp * 0.03  # 3% HP
				take_damage(burn_damage)
			"regeneration":
				var regen_amount = stats.max_hp * 0.05
				heal(regen_amount)
		
		# 减少持续时间
		status.duration -= 1
		
		# 检查是否过期
		if status.duration <= 0:
			expired_status.append(status_name)
	
	# 移除过期状态
	for status_name in expired_status:
		remove_status(status_name)

# ==================== 战斗力计算 ====================
func get_combat_power() -> int:
	"""计算战斗力"""
	var base_power = (
		stats.max_hp / 10.0 +
		stats.max_mp / 5.0 +
		(stats.patk + stats.matk) * 2.0 +
		(stats.pdef + stats.mdef) * 1.5 +
		stats.speed * 0.5
	)
	
	var crit_bonus = 1.0 + stats.crit_rate * stats.crit_dmg
	
	return int(base_power * crit_bonus)

# ==================== 数据序列化 ====================
func save() -> Dictionary:
	"""保存数据"""
	return {
		"name": unit_name,
		"level": unit_level,
		"element": unit_element,
		"stats": stats,
		"current_hp": current_hp,
		"current_mp": current_mp,
		"skills": skills
	}

func load_data(data: Dictionary) -> void:
	"""加载数据"""
	unit_name = data.get("name", "Unknown")
	unit_level = data.get("level", 1)
	unit_element = data.get("element", "neutral")
	stats = data.get("stats", stats)
	current_hp = data.get("current_hp", stats.max_hp)
	current_mp = data.get("current_mp", stats.max_mp)
	skills = data.get("skills", [])
