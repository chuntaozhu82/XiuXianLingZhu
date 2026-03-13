extends Node

# UI Manager - 管理UI界面和动画

# 当前活动页面
var current_scene: Node = null

# 场景缓存
var scene_cache = {}

# 动画时长
const PAGE_TRANSITION_DURATION = 0.3
const BUTTON_PRESS_DURATION = 0.1
const POPUP_DURATION = 0.35

# 缓动类型
const EASE_OUT = Tween.EASE_OUT
const EASE_IN = Tween.EASE_IN
const TRANS_SINE = Tween.TRANS_SINE

# 信号
signal scene_changed(scene_name: String)

func _ready():
	print("UIManager initialized")

# 切换场景
func change_scene(scene_path: String):
	# 加载场景
	var scene_resource = load(scene_path)
	if scene_resource == null:
		push_error("Failed to load scene: " + scene_path)
		return
	
	# 实例化场景
	var new_scene = scene_resource.instantiate()
	
	# 添加到场景树
	if current_scene:
		current_scene.queue_free()
	
	get_tree().root.add_child(new_scene)
	current_scene = new_scene
	
	scene_changed.emit(scene_path)

# 页面滑入动画（从右侧）
func slide_in_from_right(node: Control, duration: float = PAGE_TRANSITION_DURATION):
	node.modulate.a = 0.0
	node.position.x = get_viewport().size.x
	
	var tween = create_tween()
	tween.set_ease(EASE_OUT)
	tween.set_trans(TRANS_SINE)
	tween.parallel().tween_property(node, "position:x", 0, duration)
	tween.parallel().tween_property(node, "modulate:a", 1.0, duration)

# 页面滑出动画（向右侧）
func slide_out_to_right(node: Control, duration: float = PAGE_TRANSITION_DURATION * 0.8):
	var tween = create_tween()
	tween.set_ease(EASE_IN)
	tween.set_trans(TRANS_SINE)
	tween.parallel().tween_property(node, "position:x", get_viewport().size.x, duration)
	tween.parallel().tween_property(node, "modulate:a", 0.0, duration)

# 从底部弹出动画
func popup_from_bottom(node: Control, target_y: float, duration: float = POPUP_DURATION):
	node.modulate.a = 0.0
	node.position.y = get_viewport().size.y
	
	var tween = create_tween()
	tween.set_ease(EASE_OUT)
	tween.set_trans(TRANS_SINE)
	tween.parallel().tween_property(node, "position:y", target_y, duration)
	tween.parallel().tween_property(node, "modulate:a", 1.0, duration)

# 按钮按下动画
func button_press_animation(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), BUTTON_PRESS_DURATION)
	
	# 触发震动反馈
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(10)

# 按钮释放动画
func button_release_animation(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), BUTTON_PRESS_DURATION * 1.5)

# 淡入动画
func fade_in(node: Control, duration: float = 0.3):
	node.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)

# 淡出动画
func fade_out(node: Control, duration: float = 0.3):
	var tween = create_tween()
	tween.tween_property(node, "modulate.a", 0.0, duration)

# 缩放动画
func scale_animation(node: Control, target_scale: Vector2, duration: float = 0.3):
	var tween = create_tween()
	tween.set_ease(EASE_OUT)
	tween.tween_property(node, "scale", target_scale, duration)

# 显示Toast提示
func show_toast(message: String, duration: float = 2.0):
	# 创建Toast节点
	var toast = PanelContainer.new()
	toast.name = "Toast"
	
	# 设置样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	toast.add_theme_stylebox_override("panel", style)
	
	# 添加文本
	var label = Label.new()
	label.text = message
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 16)
	toast.add_child(label)
	
	# 添加到场景
	get_tree().root.add_child(toast)
	
	# 设置位置
	toast.position = Vector2(
		(get_viewport().size.x - toast.size.x) / 2,
		get_viewport().size.y * 0.1
	)
	
	# 淡入
	fade_in(toast, 0.2)
	
	# 延迟后淡出并删除
	await get_tree().create_timer(duration).timeout
	fade_out(toast, 0.3)
	await get_tree().create_timer(0.3).timeout
	toast.queue_free()

# 显示对话框
func show_dialog(title: String, message: String, buttons: Array = ["确定"]):
	# 创建对话框节点
	var dialog = preload("res://scenes/components/Dialog.tscn").instantiate()
	
	# 设置内容
	dialog.set_meta("title", title)
	dialog.set_meta("message", message)
	dialog.set_meta("buttons", buttons)
	
	# 添加到场景
	get_tree().root.add_child(dialog)
	
	return dialog

# 适配安全区域
func adapt_to_safe_area(node: Control):
	var safe_area = GameManager.get_safe_area()
	var screen_size = get_viewport().size
	
	# 调整位置和大小
	node.offset_left = safe_area.position.x
	node.offset_top = safe_area.position.y
	node.offset_right = screen_size.x - safe_area.end.x
	node.offset_bottom = screen_size.y - safe_area.end.y
