@tool
extends Panel

@onready var children_list = $VBoxContainer/ScrollContainer/VBoxContainer
var editor_interface: EditorInterface
var plugin_instance: EditorPlugin
var current_node: Node
var selected_node: Node = null
var is_selection_from_dock: bool = false

func clear_children():
	for child in children_list.get_children():
		child.queue_free()

func update_children(node: Node):
	clear_children()
	current_node = node
	
	if node != get_scene_root():
		add_go_up_button()
	
	add_node_item(node, node.name, true, 0)
	
	# Check if the node is a scene instance and not the root of the scene tree
	if node.scene_file_path and node != get_scene_root():
		var children_editable = node.get_parent().is_editable_instance(node)
		
		# Only show "Make Children Editable" if children are not already editable
		if not children_editable:
			add_make_editable_button(node)
		
		add_open_scene_button(node)
		
		# Only show children if the children are editable
		if children_editable:
			for child in node.get_children():
				add_node_item(child, child.name, false, 20)
	else:
		# If it's not a scene instance or it's the root, show children as normal
		for child in node.get_children():
			add_node_item(child, child.name, false, 20)


func add_go_up_button():
	var go_up_button = Button.new()
	go_up_button.text = "../"
	go_up_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	go_up_button.gui_input.connect(_on_go_up_button_pressed)
	go_up_button.custom_minimum_size.y = 24
	children_list.add_child(go_up_button)

func _on_go_up_button_pressed(event: InputEvent):
	if event is InputEventMouseButton:
		if event.double_click and current_node and current_node != get_scene_root():
			var parent = current_node.get_parent()
			if parent:
				update_children(parent)
				plugin_instance.select_node_from_dock(parent)

func get_scene_root() -> Node:
	return editor_interface.get_edited_scene_root()

func add_make_editable_button(node: Node):
	var make_editable_button = Button.new()
	make_editable_button.text = "Make Children Editable"
	make_editable_button.custom_minimum_size.y = 24
	make_editable_button.pressed.connect(_on_make_editable_pressed.bind(node))
	children_list.add_child(make_editable_button)

func add_open_scene_button(node: Node):
	var open_scene_button = Button.new()
	open_scene_button.text = "Open Original Scene"
	open_scene_button.custom_minimum_size.y = 24
	open_scene_button.pressed.connect(_on_open_scene_pressed.bind(node))
	children_list.add_child(open_scene_button)

func _on_make_editable_pressed(node: Node):
	if node.scene_file_path:
		node.get_parent().set_editable_instance(node, true)
		print("Node is now editable")
		update_children(node)
	else:
		print("Node is not a scene instance")

func _on_open_scene_pressed(node: Node):
	if node.scene_file_path:
		editor_interface.open_scene_from_path(node.scene_file_path)
		
		# Wait for the scene to load
		await get_tree().create_timer(0.1).timeout
		
		# Get the root node of the newly opened scene
		var new_scene_root = editor_interface.get_edited_scene_root()
		
		# Select the root node in the scene tree
		editor_interface.get_selection().clear()
		editor_interface.get_selection().add_node(new_scene_root)
		
		# Update the dock with the new root node
		update_children(new_scene_root)


func add_node_item(node: Node, label_text: String, is_current_node: bool, offset: int):
	var hbox = HBoxContainer.new()
	var button = Button.new()
	
	button.text = label_text + ("*" if node.get_child_count() > 0 else "")
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 24
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var icon = editor_interface.get_editor_theme().get_icon(node.get_class(), "EditorIcons")
	if icon:
		button.icon = icon

	hbox.add_child(button)

	if node.get_script():
		var script_button = Button.new()
		script_button.icon = editor_interface.get_editor_theme().get_icon("Script", "EditorIcons")
		script_button.custom_minimum_size.y = 24
		script_button.flat = true #To remove the button background
		script_button.pressed.connect(_on_script_button_pressed.bind(node))
		hbox.add_child(script_button)

	if offset > 0:
		var margin_container = MarginContainer.new()
		margin_container.add_theme_constant_override("margin_left", offset)
		margin_container.add_child(hbox)
		children_list.add_child(margin_container)
	else:
		children_list.add_child(hbox)

	button.gui_input.connect(_on_button_gui_input.bind(node))


func _on_script_button_pressed(node: Node):
	if node.get_script():
		editor_interface.edit_resource(node.get_script())


func _on_button_gui_input(event: InputEvent, node: Node):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				update_children(node)
				plugin_instance.select_node_from_dock(node)
			elif event.pressed:
				plugin_instance.select_node_from_dock(node)
				highlight_selected_node(node)

func highlight_selected_node(node: Node):
	for child in children_list.get_children():
		if child is MarginContainer:
			var button = child.get_child(0)
			if button is Button:
				button.remove_theme_stylebox_override("normal")
				button.remove_theme_stylebox_override("hover")
		elif child is Button:
			child.remove_theme_stylebox_override("normal")
			child.remove_theme_stylebox_override("hover")

	selected_node = node
	for child in children_list.get_children():
		if child is MarginContainer:
			var button = child.get_child(0)
			if button is Button and button.text == node.name:
				var selected_style_box = StyleBoxFlat.new()
				selected_style_box.bg_color = Color(0.3, 0.5, 0.8)
				button.add_theme_stylebox_override("normal", selected_style_box)
				button.add_theme_stylebox_override("hover", selected_style_box)
		elif child is Button and child.text == node.name:
			var selected_style_box = StyleBoxFlat.new()
			selected_style_box.bg_color = Color(0.3, 0.5, 0.8)
			child.add_theme_stylebox_override("normal", selected_style_box)
			child.add_theme_stylebox_override("hover", selected_style_box)
