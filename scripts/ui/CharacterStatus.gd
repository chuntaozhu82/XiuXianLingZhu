extends Control

# Character Status UI Script

# 节点引用
@onready var character_name = $VBoxContainer/CharacterInfo/HBoxContainer/VBoxContainer/Name
@onready var level_class = $VBoxContainer/CharacterInfo/HBoxContainer/VBoxContainer/LevelClass
@onready var experience_bar = $VBoxContainer/CharacterInfo/HBoxContainer/VBoxContainer/ExperienceBar
@onready var experience_label = $VBoxContainer/CharacterInfo/HBoxContainer/VBoxContainer/ExperienceLabel

@onready var attributes_panel = $VBoxContainer/AttributesPanel/VBoxContainer

@onready var equipment_grid = $VBoxContainer/EquipmentPanel/VBoxContainer/EquipmentGrid

# 属性行映射
var attribute_rows = {
	"hp": null,
	"mp": null,
	"attack": null,
	"defense": null,
	"speed": null,
	"crit": null
}

# 装备槽位
var equipment_slots = {
	"weapon": null,
	"offhand": null,
	"armor": null,
	"helmet": null,
	"accessory1": null,
	"accessory2": null
}

func _ready():
	# 初始化属性行映射
	init_attribute_rows()
	
	# 更新角色信息
	update_character_info()
	
	# 更新属性
	update_attributes()
	
	# 更新装备槽
	update_equipment_slots()
	
	# 连接装备槽信号
	connect_equipment_signals()
	
	# 适配安全区域
	adapt_safe_area()
	
	print("CharacterStatus loaded")

func init_attribute_rows():
	# 映射属性行节点
	attribute_rows.hp = attributes_panel.get_node("HPRow/Value")
	attribute_rows.mp = attributes_panel.get_node("MPRow/Value")
	attribute_rows.attack = attributes_panel.get_node("AttackRow/Value")
	attribute_rows.defense = attributes_panel.get_node("DefenseRow/Value")
	attribute_rows.speed = attributes_panel.get_node("SpeedRow/Value")
	attribute_rows.crit = attributes_panel.get_node("CritRow/Value")

func update_character_info():
	var data = GameManager.player_data
	
	# 更新名称
	character_name.text = data.name
	
	# 更新等级和职业
	level_class.text = "Lv." + str(data.level) + " " + data.class
	
	# 更新经验条
	var exp_percent = (float(data.experience) / float(data.max_experience)) * 100
	experience_bar.value = exp_percent
	
	# 更新经验标签
	experience_label.text = "经验 " + str(data.experience) + "/" + str(data.max_experience)

func update_attributes():
	var data = GameManager.player_data
	
	# 更新HP
	attribute_rows.hp.text = str(data.hp) + "/" + str(data.max_hp)
	
	# 更新MP
	attribute_rows.mp.text = str(data.mp) + "/" + str(data.max_mp)
	
	# 更新攻击力
	attribute_rows.attack.text = str(data.attack)
	
	# 更新防御力
	attribute_rows.defense.text = str(data.defense)
	
	# 更新速度
	attribute_rows.speed.text = str(data.speed)
	
	# 更新暴击率
	attribute_rows.crit.text = str(data.crit_rate) + "%"

func update_equipment_slots():
	# 映射装备槽节点
	var slot_names = ["WeaponSlot", "OffhandSlot", "ArmorSlot", "HelmetSlot", "Accessory1Slot", "Accessory2Slot"]
	var slot_keys = ["weapon", "offhand", "armor", "helmet", "accessory1", "accessory2"]
	
	for i in range(slot_names.size()):
		equipment_slots[slot_keys[i]] = equipment_grid.get_node(slot_names[i])

func connect_equipment_signals():
	# 连接所有装备槽的点击信号
	for slot_key in equipment_slots:
		var slot = equipment_slots[slot_key]
		if slot:
			slot.pressed.connect(_on_equipment_slot_pressed.bind(slot_key))

func _on_equipment_slot_pressed(slot_key: String):
	var slot = equipment_slots[slot_key]
	UIManager.button_press_animation(slot)
	
	# 检查槽位是否为空
	var slot_text = slot.text
	
	if "[ + ]" in slot_text:
		# 空槽位，打开装备选择界面
		UIManager.show_toast("选择装备 - " + slot_key)
		# TODO: 打开装备选择界面
	else:
		# 已装备，显示装备详情
		UIManager.show_toast("装备详情 - " + slot_text)
		# TODO: 显示装备详情弹窗

func adapt_safe_area():
	var safe_area = GameManager.get_safe_area()
	var screen_size = get_viewport().size
	
	$SafeAreaTop.offset_bottom = safe_area.position.y
	$SafeAreaBottom.offset_top = screen_size.y - safe_area.end.y
