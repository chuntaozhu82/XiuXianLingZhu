## CombatSystem.gd
## 战斗系统核心 - 处理伤害计算、战斗流程、回合管理
## 基于数值策划文档实现的完整战斗系统
extends Node

# ==================== 信号 ====================
signal combat_started()
signal combat_ended(victory: bool)
signal turn_started(turn_number: int, current_unit: Node)
signal turn_ended(turn_number: int)
signal action_performed(action: Dictionary)
signal damage_dealt(attacker: Node, target: Node, damage: float, is_crit: bool)
signal healing_done(healer: Node, target: Node, amount: float)
signal unit_died(unit: Node)
signal status_applied(unit: Node, status: String)
signal status_removed(unit: Node, status: String)

# ==================== 战斗状态 ====================
enum CombatState { IDLE, PLAYER_TURN, ENEMY_TURN, ANIMATING, VICTORY, DEFEAT }
var current_state: CombatState = CombatState.IDLE
var current_turn: int = 0
var turn_order: Array[Node] = []
var current_unit_index: int = 0

# ==================== 战斗单位引用 ====================
var player_unit: Node = null
var enemy_units: Array[Node] = []
var all_units: Array[Node] = []

# ==================== 元素克制系统 ====================
## 六元素克制关系：
## 火→冰→风→土→雷→水→火（循环克制）
## 克制方造成1.5倍伤害，被克制方造成0.75倍伤害
const ELEMENT_COUNTERS = {
	"fire": "ice",      # 火克冰
	"ice": "wind",      # 冰克风
	"wind": "earth",    # 风克土
	"earth": "thunder", # 土克雷
	"thunder": "water", # 雷克水
	"water": "fire"     # 水克火
}

const ELEMENT_COUNTERED_BY = {
	"fire": "water",
	"ice": "fire",
	"wind": "ice",
	"earth": "wind",
	"thunder": "earth",
	"water": "thunder"
}

# ==================== 初始化 ====================
func _ready() -> void:
	pass

# ==================== 战斗流程控制 ====================
func start_combat(player: Node, enemies: Array[Node]) -> void:
	"""开始战斗"""
	player_unit = player
	enemy_units = enemies
	all_units = [player] + enemies
	
	current_turn = 0
	current_state = CombatState.IDLE
	
	# 初始化所有单位的战斗状态
	for unit in all_units:
		if unit.has_method("initialize_for_combat"):
			unit.initialize_for_combat()
	
	# 计算回合顺序（按速度排序）
	_calculate_turn_order()
	
	combat_started.emit()
	_next_turn()

func _calculate_turn_order() -> void:
	"""计算回合顺序（按速度从高到低）"""
	turn_order = all_units.duplicate()
	turn_order.sort_custom(func(a, b): 
		return a.get_speed() > b.get_speed()
	)

func _next_turn() -> void:
	"""进入下一回合"""
	current_turn += 1
	
	# 更新状态效果
	for unit in all_units:
		if unit.is_alive():
			_update_status_effects(unit)
	
	# 检查战斗是否结束
	if _check_combat_end():
		return
	
	# 移除已死亡的单位
	turn_order = turn_order.filter(func(unit): return unit.is_alive())
	
	# 获取当前行动单位
	if current_unit_index >= turn_order.size():
		current_unit_index = 0
	
	var current_unit = turn_order[current_unit_index]
	
	# 检查是否被控制（眩晕等）
	if current_unit.has_status("stun"):
		_skip_turn(current_unit)
		return
	
	# 根据单位类型决定行动
	if current_unit == player_unit:
		current_state = CombatState.PLAYER_TURN
		turn_started.emit(current_turn, current_unit)
	else:
		current_state = CombatState.ENEMY_TURN
		_execute_enemy_ai(current_unit)

func _skip_turn(unit: Node) -> void:
	"""跳过回合"""
	print("%s 被眩晕，跳过回合" % unit.get_name())
	current_unit_index += 1
	_next_turn()

func _end_turn() -> void:
	"""结束当前回合"""
	turn_ended.emit(current_turn)
	current_unit_index += 1
	
	# 等待动画完成
	await get_tree().create_timer(0.5).timeout
	
	_next_turn()

func _check_combat_end() -> bool:
	"""检查战斗是否结束"""
	# 检查玩家是否死亡
	if not player_unit.is_alive():
		current_state = CombatState.DEFEAT
		combat_ended.emit(false)
		return true
	
	# 检查是否所有敌人都已死亡
	var alive_enemies = enemy_units.filter(func(e): return e.is_alive())
	if alive_enemies.is_empty():
		current_state = CombatState.VICTORY
		combat_ended.emit(true)
		return true
	
	return false

# ==================== 伤害计算系统 ====================
func calculate_damage(attacker: Node, target: Node, skill: Dictionary) -> Dictionary:
	"""
	计算伤害
	返回: {damage: float, is_crit: bool, element_bonus: float, is_miss: bool}
	"""
	var result = {
		"damage": 0.0,
		"is_crit": false,
		"element_bonus": 1.0,
		"is_miss": false,
		"is_counter": false
	}
	
	# 1. 命中判定
	var hit_rate = attacker.get_stat("hit_rate", 0.95)
	var eva_rate = target.get_stat("eva_rate", 0.05)
	var final_hit_rate = clamp(hit_rate - eva_rate, 0.05, 0.95)
	
	if randf() > final_hit_rate:
		result.is_miss = true
		return result
	
	# 2. 获取基础属性
	var attack_type = skill.get("attack_type", "physical")  # physical / magical / true
	var base_damage = 0.0
	var defense = 0.0
	
	match attack_type:
		"physical":
			base_damage = attacker.get_stat("patk", 20)
			defense = target.get_stat("pdef", 10)
		"magical":
			base_damage = attacker.get_stat("matk", 20)
			defense = target.get_stat("mdef", 10)
		"true":
			base_damage = attacker.get_stat("patk", 20)
			defense = 0  # 真实伤害无视防御
	
	# 3. 技能倍率
	var skill_multiplier = skill.get("multiplier", 1.0)
	
	# 4. 防御减伤
	var defense_reduction = 0.0
	if attack_type != "true":
		# 公式: 100 / (100 + 防御力)，最高70%减伤
		defense_reduction = clamp(100.0 / (100.0 + defense), 0.3, 1.0)
	else:
		defense_reduction = 1.0
	
	# 5. 元素克制加成
	var skill_element = skill.get("element", "")
	if skill_element != "":
		result.element_bonus = _calculate_element_bonus(skill_element, target)
	
	# 6. 暴击判定
	var crit_rate = attacker.get_stat("crit_rate", 0.05)
	var crit_dmg = attacker.get_stat("crit_dmg", 1.5)
	
	if randf() < crit_rate:
		result.is_crit = true
		result.damage = base_damage * skill_multiplier * defense_reduction * crit_dmg * result.element_bonus
	else:
		result.damage = base_damage * skill_multiplier * defense_reduction * result.element_bonus
	
	# 7. 随机浮动 (±10%)
	var random_factor = randf_range(0.9, 1.1)
	result.damage *= random_factor
	
	# 8. 等级压制（如果需要）
	var level_diff = attacker.get_level() - target.get_level()
	var level_factor = 1.0 + clamp(level_diff * 0.02, -0.5, 0.5)  # 每级±2%，上限±50%
	result.damage *= level_factor
	
	result.damage = max(1, result.damage)  # 最少造成1点伤害
	
	return result

func _calculate_element_bonus(attack_element: String, target: Node) -> float:
	"""计算元素克制倍率"""
	var target_element = target.get_element()
	
	if target_element == "" or target_element == "neutral":
		return 1.0
	
	# 检查是否克制目标
	if ELEMENT_COUNTERS.get(attack_element, "") == target_element:
		return 1.5  # 克制，1.5倍伤害
	
	# 检查是否被目标克制
	if ELEMENT_COUNTERED_BY.get(attack_element, "") == target_element:
		return 0.75  # 被克制，0.75倍伤害
	
	return 1.0

# ==================== 战斗行动执行 ====================
func execute_attack(attacker: Node, target: Node, skill: Dictionary) -> void:
	"""执行攻击"""
	if current_state != CombatState.PLAYER_TURN and current_state != CombatState.ENEMY_TURN:
		return
	
	current_state = CombatState.ANIMATING
	
	# 消耗AP
	var ap_cost = skill.get("ap_cost", 1)
	if not attacker.use_ap(ap_cost):
		print("AP不足！")
		return
	
	# 消耗MP
	var mp_cost = skill.get("mp_cost", 0)
	if mp_cost > 0:
		if not attacker.use_mp(mp_cost):
			print("MP不足！")
			attacker.recover_ap(ap_cost)  # 退还AP
			return
	
	# 计算伤害
	var damage_result = calculate_damage(attacker, target, skill)
	
	if damage_result.is_miss:
		action_performed.emit({
			"type": "miss",
			"attacker": attacker,
			"target": target
		})
		print("%s 的攻击未命中！" % attacker.get_name())
	else:
		# 造成伤害
		target.take_damage(damage_result.damage)
		
		damage_dealt.emit(attacker, target, damage_result.damage, damage_result.is_crit)
		
		action_performed.emit({
			"type": "attack",
			"attacker": attacker,
			"target": target,
			"damage": damage_result.damage,
			"is_crit": damage_result.is_crit,
			"element_bonus": damage_result.element_bonus
		})
		
		# 应用状态效果
		if skill.has("status_effect"):
			_apply_status_effect(target, skill.status_effect)
		
		print("%s 对 %s 造成了 %.1f 点伤害%s" % [
			attacker.get_name(),
			target.get_name(),
			damage_result.damage,
			" (暴击!)" if damage_result.is_crit else ""
		])
		
		# 检查目标是否死亡
		if not target.is_alive():
			unit_died.emit(target)
			print("%s 被击败了！" % target.get_name())
	
	# 等待动画
	await get_tree().create_timer(1.0).timeout
	
	# 检查AP是否用完
	if attacker.get_current_ap() <= 0:
		_end_turn()
	elif current_state == CombatState.PLAYER_TURN:
		# 等待玩家下一次行动
		current_state = CombatState.PLAYER_TURN
	else:
		# 敌人继续行动
		_execute_enemy_ai(attacker)

func execute_heal(healer: Node, target: Node, skill: Dictionary) -> void:
	"""执行治疗"""
	if current_state != CombatState.PLAYER_TURN and current_state != CombatState.ENEMY_TURN:
		return
	
	current_state = CombatState.ANIMATING
	
	# 消耗AP和MP
	var ap_cost = skill.get("ap_cost", 1)
	var mp_cost = skill.get("mp_cost", 10)
	
	if not healer.use_ap(ap_cost) or not healer.use_mp(mp_cost):
		return
	
	# 计算治疗量
	var heal_amount = 0.0
	var heal_type = skill.get("heal_type", "fixed")
	
	match heal_type:
		"percentage":
			heal_amount = target.get_stat("max_hp") * skill.get("heal_percent", 0.2)
		"matk_based":
			heal_amount = healer.get_stat("matk") * skill.get("multiplier", 2.0)
		_:
			heal_amount = skill.get("heal_amount", 50)
	
	# 应用治疗
	target.heal(heal_amount)
	
	healing_done.emit(healer, target, heal_amount)
	
	action_performed.emit({
		"type": "heal",
		"healer": healer,
		"target": target,
		"amount": heal_amount
	})
	
	print("%s 治疗了 %s %.1f 点生命" % [healer.get_name(), target.get_name(), heal_amount])
	
	await get_tree().create_timer(1.0).timeout
	
	if healer.get_current_ap() <= 0:
		_end_turn()

func execute_defend(unit: Node) -> void:
	"""执行防御"""
	# 防御时恢复一些AP和减少受到的伤害
	unit.add_status("defending", 1, {"damage_reduction": 0.5})
	unit.recover_ap(1)
	
	action_performed.emit({
		"type": "defend",
		"unit": unit
	})
	
	print("%s 进入防御姿态" % unit.get_name())
	
	_end_turn()

# ==================== 状态效果系统 ====================
func _apply_status_effect(target: Node, status_data: Dictionary) -> void:
	"""应用状态效果"""
	var status_name = status_data.get("name", "")
	var duration = status_data.get("duration", 3)
	var params = status_data.get("params", {})
	
	target.add_status(status_name, duration, params)
	status_applied.emit(target, status_name)
	
	print("%s 获得了 %s 状态，持续 %d 回合" % [target.get_name(), status_name, duration])

func _update_status_effects(unit: Node) -> void:
	"""更新状态效果（每回合开始时调用）"""
	var active_status = unit.get_active_status()
	
	for status_name in active_status:
		var status = active_status[status_name]
		
		# 应用持续伤害/治疗
		match status_name:
			"poison":
				var poison_damage = status.params.get("damage", 10)
				unit.take_damage(poison_damage)
				print("%s 受到毒素伤害 %.1f" % [unit.get_name(), poison_damage])
			"regeneration":
				var regen_amount = status.params.get("amount", 20)
				unit.heal(regen_amount)
				print("%s 恢复了 %.1f 点生命" % [unit.get_name(), regen_amount])
			"burn":
				var burn_damage = status.params.get("damage", 15)
				unit.take_damage(burn_damage)
		
		# 减少持续时间
		unit.decrease_status_duration(status_name)
		
		# 检查是否过期
		if status.duration <= 0:
			unit.remove_status(status_name)
			status_removed.emit(unit, status_name)
			print("%s 的 %s 状态消失了" % [unit.get_name(), status_name])

# ==================== 敌人AI系统 ====================
func _execute_enemy_ai(enemy: Node) -> void:
	"""执行敌人AI"""
	await get_tree().create_timer(0.5).timeout
	
	# 获取可用技能
	var available_skills = enemy.get_available_skills()
	if available_skills.is_empty():
		execute_defend(enemy)
		return
	
	# 选择技能（简化AI：随机选择）
	var selected_skill = available_skills[randi() % available_skills.size()]
	
	# 选择目标
	var target = _select_target(enemy, selected_skill)
	
	if target == null:
		execute_defend(enemy)
		return
	
	# 执行技能
	if selected_skill.get("type") == "heal":
		execute_heal(enemy, target, selected_skill)
	else:
		execute_attack(enemy, target, selected_skill)

func _select_target(enemy: Node, skill: Dictionary) -> Node:
	"""选择攻击目标"""
	var skill_type = skill.get("type", "attack")
	
	if skill_type == "heal":
		# 治疗技能：选择受伤最重的队友
		var allies = enemy_units.filter(func(e): return e.is_alive())
		var lowest_hp_ally = null
		var lowest_hp_percent = 1.0
		
		for ally in allies:
			var hp_percent = ally.get_current_hp() / ally.get_stat("max_hp")
			if hp_percent < lowest_hp_percent:
				lowest_hp_percent = hp_percent
				lowest_hp_ally = ally
		
		return lowest_hp_ally if lowest_hp_ally else enemy
	else:
		# 攻击技能：随机攻击玩家（可扩展更复杂的AI）
		return player_unit

# ==================== 辅助方法 ====================
func get_current_unit() -> Node:
	"""获取当前行动单位"""
	if current_unit_index < turn_order.size():
		return turn_order[current_unit_index]
	return null

func is_player_turn() -> bool:
	return current_state == CombatState.PLAYER_TURN

func is_combat_active() -> bool:
	return current_state != CombatState.IDLE
