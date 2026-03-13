## SkillTree.gd
## 技能树界面 - 显示和管理技能学习
## 集成PlayerData和SkillData系统
extends Control

# ==================== 信号 ====================
signal skill_learned(skill_id: String)
signal skill_leveled_up(skill_id: String, new_level: int)
signal skill_equipped(skill_id: String, slot: int)

# ==================== 节点引用 ====================
@onready var category_tabs: HBoxContainer = $VBoxContainer/CategoryTabs/HBoxContainer
@onready var skill_points_label: Label = $VBoxContainer/SkillPoints/HBoxContainer/Label
@onready var skill_tree_area: VBoxContainer = $VBoxContainer/SkillTreeArea/VBoxContainer
@onready var detail_panel: Control = $VBoxContainer/DetailPanel

# ==================== 数据 ====================
var current_category: String = "all"
var selected_skill: Dictionary = {}

# 技能系别映射
const CATEGORY_ELEMENTS: Dictionary = {
	"all": -1,
	"fire": 1,      # SkillElement.FIRE
	"ice": 2,       # SkillElement.ICE
	"wind": 3,      # SkillElement.WIND
	"thunder": 5,   # SkillElement.THUNDER
	"water": 6,     # SkillElement.WATER
	"support": -1   # 特殊类别
}

# ==================== 初始化 ====================
func _ready() -> void:
	_connect_signals()
	_setup_category_tabs()
	update_skill_points()
	update_skill_tree()
	adapt_safe_area()
	
	print("[SkillTree] 技能树界面已加载")

func _connect_signals() -> void:
	# 连接PlayerData信号
	PlayerData.skill_unlocked.connect(_on_skill_unlocked)
	PlayerData.stats_changed.connect(_on_stats_changed)
	
	# 连接技能系别标签信号
	for tab in category_tabs.get_children():
		tab.pressed.connect(_on_category_tab_pressed.bind(tab))

func _setup_category_tabs() -> void:
	# 设置默认选中"全部"
	var all_tab = category_tabs.get_node_or_null("AllTab")
	if all_tab:
		all_tab.button_pressed = true

# ==================== 技能树显示 ====================
func update_skill_tree() -> void:
	# 清空当前技能树
	for child in skill_tree_area.get_children():
		child.queue_free()
	
	# 获取技能列表
	var skills_to_display = _get_skills_for_category(current_category)
	
	# 按等级要求排序
	skills_to_display.sort_custom(_sort_by_level_requirement)
	
	# 添加技能节点
	for i in range(skills_to_display.size()):
		var skill = skills_to_display[i]
		create_skill_node(skill)
		
		# 如果不是最后一个技能，添加连接线
		if i < skills_to_display.size() - 1:
			create_connector()

func _get_skills_for_category(category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for skill_id in SkillData.SKILLS:
		var skill = SkillData.SKILLS[skill_id]
		
		# 跳过敌人专用技能
		if skill.get("enemy_only", false):
			continue
		
		# 检查类别筛选
		if category == "all":
			result.append(skill)
		elif category == "support":
			# 辅助技能（治疗、增益、减益）
			var skill_type = skill.get("type", 0)
			if skill_type in [1, 2, 3]:  # HEAL, BUFF, DEBUFF
				result.append(skill)
		else:
			var element = CATEGORY_ELEMENTS.get(category, -1)
			if skill.get("element", -1) == element:
				result.append(skill)
	
	return result

func _sort_by_level_requirement(a: Dictionary, b: Dictionary) -> bool:
	return a.get("level_requirement", 0) < b.get("level_requirement", 0)

func create_skill_node(skill: Dictionary) -> void:
	var skill_id = skill.get("id", "")
	var is_learned = PlayerData.has_skill(skill_id)
	var skill_level = PlayerData.get_skill_level(skill_id)
	var max_level = skill.get("max_level", 5)
	var level_req = skill.get("level_requirement", 0)
	var can_learn = PlayerData.player_level >= level_req
	
	# 确定技能状态
	var status: String
	if is_learned:
		status = "learned"
	elif can_learn:
		status = "available"
	else:
		status = "locked"
	
	# 创建技能节点面板
	var skill_panel = PanelContainer.new()
	skill_panel.custom_minimum_size = Vector2(0, 90)
	skill_panel.name = "SkillNode_%s" % skill_id
	
	# 创建HBox容器
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	
	# 创建图标
	var icon = Label.new()
	icon.text = skill.get("icon", "⭐")
	icon.custom_minimum_size = Vector2(64, 64)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 根据状态调整图标
	if status == "locked":
		icon.modulate = Color(0.4, 0.4, 0.4)
		icon.add_theme_font_size_override("font_size", 24)
	else:
		icon.add_theme_font_size_override("font_size", 32)
	
	hbox.add_child(icon)
	
	# 创建信息容器
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 创建技能名称
	var name_label = Label.new()
	if is_learned:
		name_label.text = "%s Lv.%d/%d" % [skill.get("name", "未知技能"), skill_level, max_level]
	else:
		name_label.text = skill.get("name", "未知技能")
	
	if status == "locked":
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		name_label.add_theme_color_override("font_color", Color.WHITE)
	
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)
	
	# 创建等级进度或解锁条件
	if status != "locked":
		var level_dots = Label.new()
		level_dots.text = get_level_dots(skill_level, max_level)
		level_dots.add_theme_color_override("font_color", Color(0.992, 0.851, 0.204))
		level_dots.add_theme_font_size_override("font_size", 14)
		vbox.add_child(level_dots)
		
		# 显示技能消耗
		var cost_info = Label.new()
		var ap_cost = skill.get("ap_cost", 1)
		var mp_cost = skill.get("mp_cost", 0)
		cost_info.text = "AP:%d" % ap_cost
		if mp_cost > 0:
			cost_info.text += " MP:%d" % mp_cost
		cost_info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		cost_info.add_theme_font_size_override("font_size", 12)
		vbox.add_child(cost_info)
	else:
		var lock_info = Label.new()
		lock_info.text = "🔒 需要 Lv.%d" % level_req
		lock_info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		lock_info.add_theme_font_size_override("font_size", 14)
		vbox.add_child(lock_info)
	
	hbox.add_child(vbox)
	skill_panel.add_child(hbox)
	skill_tree_area.add_child(skill_panel)
	
	# 连接点击事件
	if status != "locked":
		skill_panel.gui_input.connect(_on_skill_gui_input.bind(skill, status))

func create_connector() -> void:
	# 创建连接线
	var connector = Control.new()
	connector.custom_minimum_size = Vector2(0, 24)
	connector.name = "Connector"
	
	var line = Line2D.new()
	line.points = PackedVector2Array([
		Vector2(540, 0),
		Vector2(540, 24)
	])
	line.width = 3.0
	line.default_color = Color(0.424, 0.361, 0.906)
	
	connector.add_child(line)
	skill_tree_area.add_child(connector)

# ==================== 技能操作 ====================
func _on_skill_gui_input(event: InputEvent, skill: Dictionary, status: String) -> void:
	if event is InputEventScreenTouch and event.pressed:
		select_skill(skill, status)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			select_skill(skill, status)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			show_skill_context_menu(skill, status)

func select_skill(skill: Dictionary, status: String) -> void:
	selected_skill = skill
	
	# 显示技能详情
	show_skill_details(skill, status)

func show_skill_details(skill: Dictionary, status: String) -> void:
	var skill_id = skill.get("id", "")
	var message = skill.get("name", "")
	message += "\n" + skill.get("description", "")
	
	var ap_cost = skill.get("ap_cost", 1)
	var mp_cost = skill.get("mp_cost", 0)
	message += "\n消耗: AP %d" % ap_cost
	if mp_cost > 0:
		message += " | MP %d" % mp_cost
	
	if status == "available":
		if PlayerData.attribute_points > 0:
			message += "\n\n💡 点击学习此技能"
		else:
			message += "\n\n⚠️ 技能点不足"
	elif status == "learned":
		var skill_level = PlayerData.get_skill_level(skill_id)
		var max_level = skill.get("max_level", 5)
		if skill_level < max_level and PlayerData.attribute_points > 0:
			message += "\n\n💡 点击升级技能"
	
	UIManager.show_toast(message)

func show_skill_context_menu(skill: Dictionary, status: String) -> void:
	# TODO: 显示技能菜单（学习、装备等）
	match status:
		"available":
			learn_skill(skill)
		"learned":
			upgrade_skill(skill)

func learn_skill(skill: Dictionary) -> void:
	if PlayerData.attribute_points <= 0:
		UIManager.show_toast("技能点不足！")
		return
	
	var skill_id = skill.get("id", "")
	
	if PlayerData.unlock_skill(skill_id):
		update_skill_points()
		update_skill_tree()
		skill_learned.emit(skill_id)
		UIManager.show_toast("学会了 %s！" % skill.get("name", ""))
	else:
		UIManager.show_toast("学习失败")

func upgrade_skill(skill: Dictionary) -> void:
	if PlayerData.attribute_points <= 0:
		UIManager.show_toast("技能点不足！")
		return
	
	var skill_id = skill.get("id", "")
	var current_level = PlayerData.get_skill_level(skill_id)
	var max_level = skill.get("max_level", 5)
	
	if current_level >= max_level:
		UIManager.show_toast("技能已达到最高等级！")
		return
	
	if PlayerData.upgrade_skill(skill_id):
		update_skill_points()
		update_skill_tree()
		skill_leveled_up.emit(skill_id, current_level + 1)
		UIManager.show_toast("%s 升级到 Lv.%d！" % [skill.get("name", ""), current_level + 1])
	else:
		UIManager.show_toast("升级失败")

func equip_skill(skill: Dictionary, slot: int) -> void:
	var skill_id = skill.get("id", "")
	
	if PlayerData.equip_skill_to_slot(skill_id, slot):
		skill_equipped.emit(skill_id, slot)
		UIManager.show_toast("已装备 %s 到技能栏 %d" % [skill.get("name", ""), slot + 1])
	else:
		UIManager.show_toast("装备失败")

# ==================== 筛选功能 ====================
func _on_category_tab_pressed(tab: Button) -> void:
	# 取消其他标签的选中状态
	for other_tab in category_tabs.get_children():
		if other_tab != tab:
			other_tab.button_pressed = false
	
	# 更新当前技能系别
	current_category = tab.name.to_lower().replace("tab", "")
	
	# 更新技能树
	update_skill_tree()

# ==================== UI更新 ====================
func _on_skill_unlocked(skill_id: String) -> void:
	update_skill_points()
	update_skill_tree()

func _on_stats_changed(stat_name: String, _old_value: float, _new_value: float) -> void:
	if stat_name == "attribute_points":
		update_skill_points()

func update_skill_points() -> void:
	skill_points_label.text = "技能点: %d" % PlayerData.attribute_points

# ==================== 辅助函数 ====================
func get_level_dots(level: int, max_level: int) -> String:
	var dots = ""
	for i in range(max_level):
		if i < level:
			dots += "●"
		else:
			dots += "○"
	return dots

# ==================== 屏幕适配 ====================
func adapt_safe_area() -> void:
	var safe_area = GameManager.get_safe_area()
	var screen_size = get_viewport().size
	
	var safe_top = $VBoxContainer.get_node_or_null("SafeAreaTop")
	var safe_bottom = $VBoxContainer.get_node_or_null("SafeAreaBottom")
	
	if safe_top:
		safe_top.offset_bottom = safe_area.position.y
	if safe_bottom:
		safe_bottom.offset_top = screen_size.y - safe_area.end.y

# ==================== 调试功能 ====================
func add_test_skill_points(amount: int = 10) -> void:
	PlayerData.attribute_points += amount
	update_skill_points()
	UIManager.show_toast("添加 %d 技能点" % amount)

func unlock_all_skills_debug() -> void:
	GameManager.unlock_all_skills()
	update_skill_tree()
	UIManager.show_toast("已解锁所有技能")
