## Inventory.gd
## 物品栏界面 - 显示和管理玩家物品
## 集成PlayerData物品系统
extends Control

# ==================== 信号 ====================
signal item_selected(item_id: String, slot: int)
signal item_used(item_id: String, slot: int)
signal item_equipped(item_id: String, slot: int)

# ==================== 节点引用 ====================
@onready var filter_tabs: HBoxContainer = $VBoxContainer/FilterTabs/HBoxContainer
@onready var item_list: VBoxContainer = $VBoxContainer/ItemList/VBoxContainer
@onready var item_count_label: Label = $VBoxContainer/StatusBar/HBoxContainer/ItemCount
@onready var detail_panel: Control = $VBoxContainer/DetailPanel

# ==================== 数据 ====================
var current_filter: String = "all"
var selected_item: Dictionary = {}
var selected_slot: int = -1

# 物品类型筛选映射
const FILTER_MAP: Dictionary = {
	"all": null,
	"weapon": 0,    # ItemType.WEAPON
	"armor": 1,     # ItemType.ARMOR
	"consumable": 3, # ItemType.CONSUMABLE
	"material": 4   # ItemType.MATERIAL
}

# ==================== 初始化 ====================
func _ready() -> void:
	_connect_signals()
	_setup_filter_tabs()
	update_item_list()
	update_item_count()
	adapt_safe_area()
	
	print("[Inventory] 物品栏界面已加载")

func _connect_signals() -> void:
	# 连接PlayerData信号
	PlayerData.inventory_updated.connect(_on_inventory_updated)
	
	# 连接筛选标签信号
	for tab in filter_tabs.get_children():
		tab.pressed.connect(_on_filter_tab_pressed.bind(tab))

func _setup_filter_tabs() -> void:
	# 设置默认选中"全部"
	var all_tab = filter_tabs.get_node_or_null("AllTab")
	if all_tab:
		all_tab.button_pressed = true

# ==================== 物品列表管理 ====================
func update_item_list() -> void:
	# 清空当前列表
	for child in item_list.get_children():
		child.queue_free()
	
	# 获取玩家物品栏
	var inventory = PlayerData.inventory
	
	# 根据筛选条件添加物品
	for i in range(inventory.size()):
		var slot_data = inventory[i]
		if slot_data.is_empty():
			continue
		
		# 检查筛选条件
		if current_filter != "all":
			var item_data = ItemData.get_item(slot_data.get("id", ""))
			var item_type = item_data.get("type", -1)
			if FILTER_MAP.get(current_filter, -1) != item_type:
				continue
		
		create_item_entry(slot_data, i)

func create_item_entry(slot_data: Dictionary, slot: int) -> void:
	var item_data = ItemData.get_item(slot_data.get("id", ""))
	if item_data.is_empty():
		return
	
	# 创建物品条目面板
	var item_panel = PanelContainer.new()
	item_panel.custom_minimum_size = Vector2(0, 96)
	item_panel.name = "ItemSlot_%d" % slot
	
	# 创建HBox容器
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	
	# 创建图标
	var icon = Label.new()
	icon.text = item_data.get("icon", "📦")
	icon.custom_minimum_size = Vector2(64, 64)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 32)
	hbox.add_child(icon)
	
	# 创建信息容器
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 创建名称
	var name_label = Label.new()
	name_label.text = item_data.get("name", "未知物品")
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)
	
	# 创建属性描述
	var stats_label = Label.new()
	stats_label.text = item_data.get("description", "")
	stats_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	stats_label.add_theme_font_size_override("font_size", 13)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(stats_label)
	
	# 创建稀有度
	var rarity_label = Label.new()
	rarity_label.text = get_rarity_text(item_data.get("rarity", 1))
	rarity_label.add_theme_color_override("font_color", get_rarity_color(item_data.get("rarity", 1)))
	rarity_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(rarity_label)
	
	hbox.add_child(vbox)
	
	# 创建数量
	if item_data.get("stackable", false):
		var quantity_label = Label.new()
		quantity_label.text = "x" + str(slot_data.get("count", 1))
		quantity_label.add_theme_color_override("font_color", Color.WHITE)
		quantity_label.add_theme_font_size_override("font_size", 16)
		hbox.add_child(quantity_label)
	
	item_panel.add_child(hbox)
	item_list.add_child(item_panel)
	
	# 连接点击事件
	item_panel.gui_input.connect(_on_item_gui_input.bind(slot_data, slot))

# ==================== 物品操作 ====================
func _on_item_gui_input(event: InputEvent, slot_data: Dictionary, slot: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		select_item(slot_data, slot)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			select_item(slot_data, slot)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			show_item_context_menu(slot_data, slot)

func select_item(slot_data: Dictionary, slot: int) -> void:
	selected_item = slot_data
	selected_slot = slot
	
	# 高亮选中项
	for child in item_list.get_children():
		child.modulate = Color(1, 1, 1)
	
	var selected_panel = item_list.get_node_or_null("ItemSlot_%d" % slot)
	if selected_panel:
		selected_panel.modulate = Color(1.2, 1.2, 0.8)
	
	# 显示物品详情
	show_item_details(slot_data)
	
	var item_id = slot_data.get("id", "")
	item_selected.emit(item_id, slot)

func show_item_details(slot_data: Dictionary) -> void:
	var item_id = slot_data.get("id", "")
	var item_data = ItemData.get_item(item_id)
	if item_data.is_empty():
		return
	
	if detail_panel:
		detail_panel.visible = true
		# TODO: 更新详情面板内容
		UIManager.show_toast(item_data.get("name", "") + ": " + item_data.get("description", ""))

func show_item_context_menu(slot_data: Dictionary, slot: int) -> void:
	var item_id = slot_data.get("id", "")
	var item_data = ItemData.get_item(item_id)
	if item_data.is_empty():
		return
	
	# 根据物品类型显示不同选项
	match item_data.get("type"):
		0:  # WEAPON
			show_equipment_menu(slot_data, slot)
		1:  # ARMOR
			show_equipment_menu(slot_data, slot)
		3:  # CONSUMABLE
			show_consumable_menu(slot_data, slot)
		_:
			show_default_menu(slot_data, slot)

func show_equipment_menu(slot_data: Dictionary, slot: int) -> void:
	# TODO: 显示装备菜单（装备、丢弃等）
	var item_id = slot_data.get("id", "")
	var item_data = ItemData.get_item(item_id)
	if PlayerData.can_equip(item_data):
		UIManager.show_toast("点击装备: " + item_data.get("name", ""))
	else:
		UIManager.show_toast("等级不足，无法装备")

func show_consumable_menu(slot_data: Dictionary, slot: int) -> void:
	# 使用消耗品
	use_item(slot_data, slot)

func show_default_menu(slot_data: Dictionary, slot: int) -> void:
	var item_id = slot_data.get("id", "")
	var item_data = ItemData.get_item(item_id)
	UIManager.show_toast(item_data.get("name", ""))

func use_item(slot_data: Dictionary, slot: int) -> void:
	var item_id = slot_data.get("id", "")
	var item_data = ItemData.get_item(item_id)
	if item_data.is_empty():
		return
	
	if item_data.get("type") != 3:  # CONSUMABLE
		UIManager.show_toast("此物品无法使用")
		return
	
	# 执行物品效果
	var effect = item_data.get("effect", {})
	match effect.get("type"):
		"heal_hp":
			var heal_amount = effect.get("value", 0)
			PlayerData.current_hp = min(PlayerData.current_hp + heal_amount, PlayerData.stats.max_hp)
			UIManager.show_toast("恢复了%d点HP" % heal_amount)
		"heal_mp":
			var heal_amount = effect.get("value", 0)
			PlayerData.current_mp = min(PlayerData.current_mp + heal_amount, PlayerData.stats.max_mp)
			UIManager.show_toast("恢复了%d点MP" % heal_amount)
		"remove_status":
			# TODO: 实现状态移除
			UIManager.show_toast("解除了状态")
		_:
			UIManager.show_toast("使用成功")
	
	# 减少物品数量
	PlayerData.remove_item(item_id, 1)
	
	item_used.emit(item_id, slot)

func equip_item(slot_data: Dictionary, slot: int) -> void:
	var item_id = slot_data.get("id", "")
	var item_data = ItemData.get_item(item_id)
	if item_data.is_empty():
		return
	
	var equip_slot_type = _get_equip_slot_from_item(item_data)
	if PlayerData.equip_item(equip_slot_type, slot_data):
		PlayerData.remove_item(item_id, 1)
		item_equipped.emit(item_id, slot)
		UIManager.show_toast("已装备: " + item_data.get("name", ""))
	else:
		UIManager.show_toast("无法装备此物品")

func _get_equip_slot_from_item(item_data: Dictionary) -> int:
	"""根据物品类型获取装备槽位"""
	match item_data.get("type"):
		0: return PlayerData.EquipSlot.WEAPON
		1: return PlayerData.EquipSlot.ARMOR
		3: return PlayerData.EquipSlot.ACCESSORY
		_: return PlayerData.EquipSlot.WEAPON

# ==================== 筛选功能 ====================
func _on_filter_tab_pressed(tab: Button) -> void:
	# 取消其他标签的选中状态
	for other_tab in filter_tabs.get_children():
		if other_tab != tab:
			other_tab.button_pressed = false
	
	# 更新当前筛选
	current_filter = tab.name.to_lower().replace("tab", "")
	
	# 更新物品列表
	update_item_list()

# ==================== UI更新 ====================
func _on_inventory_updated() -> void:
	update_item_list()
	update_item_count()

func update_item_count() -> void:
	var total_items = 0
	for slot_data in PlayerData.inventory:
		if not slot_data.is_empty():
			total_items += slot_data.get("count", 1)
	
	item_count_label.text = "物品数量: %d/%d" % [total_items, PlayerData.MAX_INVENTORY_SIZE]

# ==================== 辅助函数 ====================
func get_rarity_text(rarity: int) -> String:
	var stars = ""
	for i in range(5):
		if i < rarity:
			stars += "★"
		else:
			stars += "☆"
	return stars

func get_rarity_color(rarity: int) -> Color:
	match rarity:
		1:
			return Color.WHITE  # 普通
		2:
			return Color(0.133, 0.588, 0.314)  # 优秀(绿)
		3:
			return Color(0.129, 0.588, 0.953)  # 稀有(蓝)
		4:
			return Color(0.612, 0.153, 0.69)   # 史诗(紫)
		5:
			return Color(1.0, 0.596, 0.0)      # 传说(金)
		_:
			return Color.WHITE

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
func add_test_item(item_id: String, quantity: int = 1) -> void:
	PlayerData.add_item(item_id, quantity)
	UIManager.show_toast("添加物品: %s x%d" % [item_id, quantity])
