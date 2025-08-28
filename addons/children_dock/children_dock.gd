@tool
extends EditorPlugin

var collapsed_states: Dictionary = {}
var dock
var last_manually_selected_node: Node

func _enter_tree():
	dock = preload("res://addons/children_dock/dock.tscn").instantiate()

	if dock:
		print("Dock loaded successfully")
		dock.editor_interface = get_editor_interface()
		dock.plugin_instance = self
		add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)
		dock.name = "Children Dock"
	else:
		printerr("Failed to load dock scene")

	get_editor_interface().get_selection().connect("selection_changed", self._on_selection_changed)

func _exit_tree():
	if dock:
		remove_control_from_docks(dock)
		dock.free()

func _on_selection_changed():
	if not dock:
		printerr("Dock is not initialized")
		return

	var selected_nodes = get_editor_interface().get_selection().get_selected_nodes()
	if selected_nodes.size() == 0:
		return

	var selected_node = selected_nodes[0]

	if dock.is_selection_from_dock:
		dock.is_selection_from_dock = false
		return

	if selected_node != last_manually_selected_node:
		last_manually_selected_node = selected_node
		dock.update_children(selected_node)

func edit_node(node: Node):
	# This method is called when a node is selected for editing
	if node and dock:
		var parent = node.get_parent()
		if parent:
			dock.update_children(parent)
		else:
			dock.update_children(node)

# ... rest of your existing code ...


func _on_filesystem_changed():
	if dock:
		var scene_root = get_editor_interface().get_edited_scene_root()
		if scene_root:
			# Select the parent of the scene root (which is typically the root itself)
			var node_to_select = scene_root
			if scene_root.get_parent():
				node_to_select = scene_root.get_parent()
			
			# Update the selection
			get_editor_interface().get_selection().clear()
			get_editor_interface().get_selection().add_node(node_to_select)
			
			# Update the dock
			dock.update_children(node_to_select)

func _on_scene_changed(scene_root: Node):
	if dock:
		dock.update_children(scene_root)

func select_node_from_dock(node: Node):
	dock.is_selection_from_dock = true
	get_editor_interface().get_selection().clear()
	get_editor_interface().get_selection().add_node(node)

	save_collapsed_states()

	await get_tree().create_timer(0.00001).timeout

	var parent_node = node.get_parent()
	if parent_node:
		var path_in_scene = get_editor_interface().get_edited_scene_root().get_path_to(parent_node)
		var item: TreeItem = _get_editor_scene_tree_item(path_in_scene)
		if item:
			item.collapsed = true

	restore_collapsed_states()

# Helper function to save the collapsed state of all nodes in the scene tree
func save_collapsed_states():
	collapsed_states.clear()
	var tree = _get_scene_tree_control(get_editor_interface().get_base_control())
	if tree:
		var root = tree.get_root()
		_save_collapsed_states_recursive(root)

# Recursive function to save the collapsed state of each TreeItem
func _save_collapsed_states_recursive(item: TreeItem):
	if item:
		var path = _get_tree_item_path(item)
		collapsed_states[path] = item.collapsed
		var child = item.get_first_child()
		while child:
			_save_collapsed_states_recursive(child)
			child = child.get_next()

# Helper function to restore the collapsed state of all nodes in the scene tree
func restore_collapsed_states():
	var tree = _get_scene_tree_control(get_editor_interface().get_base_control())
	if tree:
		var root = tree.get_root()
		_restore_collapsed_states_recursive(root)

# Recursive function to restore the collapsed state of each TreeItem
func _restore_collapsed_states_recursive(item: TreeItem):
	if item:
		var path = _get_tree_item_path(item)
		if collapsed_states.has(path):
			item.collapsed = collapsed_states[path]
		var child = item.get_first_child()
		while child:
			_restore_collapsed_states_recursive(child)
			child = child.get_next()

# Helper function to get the path of a TreeItem
func _get_tree_item_path(item: TreeItem) -> String:
	var path = []
	while item:
		path.append(item.get_text(0))
		item = item.get_parent()
	path.reverse()
	return "/".join(path)

# Helper function to get the Scene Tree control
func _get_scene_tree_control(base: Node) -> Tree:
	if base.name == "Scene":
		var tree = null
		for c in base.get_children(true):
			if c.name.contains("SceneTreeEditor"):
				return c.get_child(0)
	for child in base.get_children():
		var tree = _get_scene_tree_control(child)
		if tree != null:
			return tree
	return null

# Helper function to get a TreeItem by path
func _get_editor_scene_tree_item(path: String, parent: TreeItem = null) -> TreeItem:
	if parent == null:
		parent = _get_scene_tree_control(get_editor_interface().get_base_control()).get_root()
	var path_parts = path.split("/")
	var first_part = path_parts[0]
	var next_parts = null
	if len(path_parts) > 1:
		next_parts = "/".join(path_parts.slice(1))
	if first_part == ".":
		return parent
	for child in parent.get_children():
		if child.get_text(0) == first_part:
			if next_parts == null:
				return child
			else:
				return _get_editor_scene_tree_item(next_parts, child)
	return null
