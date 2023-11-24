@tool
extends Control

#region Nodes
@onready var prop_grid: ItemList = %prop_grid
@onready var btn_autoplace: Button = %btn_autoplace
@onready var btn_debug: Button = $Panel/VBoxContainer/btn_debug
@onready var txt_marker_key: TextEdit = %txt_marker_key
@onready var btn_prop_grid_remove_item: Button = %btn_prop_grid_remove_item

#endregion Nodes

#region Variables
var ap_saver: AutoPlaceSaver
var editor_interface:EditorInterface
var ap_parent: EditorPlugin
var debug_print_enabled: bool = true
#endregion Variables

#region Saved Variables TODO
const marker_key_name: String = 'marker_key'
var marker_key: String
const library_scenes_name: String = 'library_scenes'
var library_scenes: Dictionary = {}  # Dictionary to store scenes with their names as keys
#endregion Saved Variables



func _ready() -> void:
	# Connect Signals
	btn_autoplace.pressed.connect(_on_btn_autoplace_pressed)
	btn_prop_grid_remove_item.pressed.connect(_on_btn_prop_grid_remove_item_pressed)
	prop_grid.signal_add_scene_to_library.connect(_add_scene_to_library)
	txt_marker_key.text_changed.connect(_on_txt_marker_key_changed)

	btn_debug.pressed.connect(_on_btn_debug_pressed)


	# Read Values from Save Config && Set Variables
	ap_parent = AutoPlacer.instance
	if AutoPlaceSaver.instance:
		ap_saver = AutoPlaceSaver.instance
	else:
		ap_saver = AutoPlaceSaver.new(self)

	var value: Variant = null

	value = ap_saver.read_from_config(marker_key_name)
	if typeof(value) == TYPE_STRING   &&   value != "":
		marker_key = value
		txt_marker_key.text = marker_key
	else:
		marker_key = txt_marker_key.text
		ap_saver.call_deferred('write_to_config', marker_key_name, marker_key)

	value = ap_saver.read_from_config(library_scenes_name)
	prop_grid.clear()
	if typeof(value) != TYPE_DICTIONARY:
		library_scenes = {}
		ap_saver.call_deferred('write_to_config', library_scenes_name, library_scenes)
	elif typeof(value) == TYPE_DICTIONARY:
		library_scenes = value
		for item in library_scenes:
			prop_grid.add_item(item)

	prop_grid.mouse_filter = Control.MOUSE_FILTER_PASS # Set the item list mouse filter to pass to get the drag and drop working on this node



#region Scene Placement Functions
func autoplace_scenes() -> void:
	var active_scene_root: Node = get_tree().edited_scene_root
	print('Active Scene Root:   ', active_scene_root)
	var undo_redo: EditorUndoRedoManager = ap_parent.get_undo_redo()   # ap_parent.undo_redo
	undo_redo.create_action('Auto Place Scenes')
	place_scenes_recursive(active_scene_root, active_scene_root, undo_redo)
	undo_redo.commit_action()
	debug_print_tree(active_scene_root)


func place_scenes_recursive(node: Node, root_owner: Node, undo_redo: EditorUndoRedoManager) -> void:
	var _root_owner: Node = root_owner
	var has_placed_scene: bool = false
	for child in node.get_children():
		#print('Testing --   Marker Key: ', marker_key, '   |   Child Name: ', child.name, '   |   [1] in [2]: ', marker_key in child.name)
		if marker_key in child.name:
			var modified_node_name: String = child.name.replace(marker_key, "")
			print('modded node name   ', modified_node_name)
			var library_prop_name: String = get_library_prop_in_node_name(modified_node_name)
			if library_prop_name:
				print(' + ', child.name.replace(marker_key, ""), ' is in library')
				var scene_instance: Node = place_scene(child, library_prop_name, _root_owner, undo_redo)
				has_placed_scene = true

			#if node_name_in_library(modified_node_name):
				#print(' + ', child.name.replace(marker_key, ""), ' is in library')
				#var scene_instance: Node = place_scene(child, modified_node_name, _root_owner, undo_redo)
				#has_placed_scene = true
		else:
			print(' - ',child.name, ' not found in library')
		# Only continue recursion if no scene was placed in this child
		if not has_placed_scene:
			place_scenes_recursive(child, _root_owner, undo_redo)



func place_scene(node: Node, name: String, root_owner: Node, undo_redo: EditorUndoRedoManager) -> Node:
	var scene_resource: PackedScene = library_scenes[name]
	if scene_resource is PackedScene:
		var scene_instance: Node = scene_resource.instantiate()
		#undo_redo.add_do_method(do_add_child.bind(node, scene_instance))
		#undo_redo.add_do_method(node, 'add_child', scene_instance)
		#undo_redo.add_undo_method(undo_add_child.bind(node, scene_instance))
		undo_redo.add_undo_method(node, 'remove_child', scene_instance)
		node.add_child(scene_instance)
		scene_instance.set_owner(root_owner)
		print('Placed Prop Owner: ',scene_instance.owner)
		return scene_instance
	return node

#endregion Scene Placement Functions

#region Utility Functions
func do_add_child(parent: Node, child: Node) -> void:
	parent.add_child(child)

func undo_add_child(parent: Node, child: Node) -> void:
	parent.remove_child(child)

func save_current_scene(postfix: String = "") -> void:
	var editor = ap_parent.get_editor_interface()
	var current_scene = editor.get_edited_scene_root()
	var current_scene_name = current_scene.get_scene_file_path()

	if current_scene and current_scene_name != "":
		var save_path: String = current_scene_name
		var base_name: String = save_path.get_basename()
		var directory: String = save_path.get_base_dir()
		var extension: String = save_path.get_extension()

		# Append the postfix to the base name
		var new_file_name: String = base_name + postfix
		new_file_name = new_file_name.replace("res://", "")
		if extension != "":
			new_file_name += "." + extension
		var new_save_path: String
		if directory != "res://":
			new_save_path = directory + "/" + new_file_name
		else:
			new_save_path = new_file_name

		var packed_scene: PackedScene = PackedScene.new()
		packed_scene.pack(current_scene)
		var result = ResourceSaver.save(packed_scene, new_save_path)
		if result == OK:
			print("Scene saved successfully to: ", new_save_path)
		else:
			print("Failed to save scene. Error code: ", result)
	else:
		print("Current scene has not been saved yet.")


func get_active_scene_name() -> String:
	var editor = ap_parent.get_editor_interface()
	var active_scene = editor.get_edited_scene_root()
	if active_scene:
		return active_scene.name
	else:
		return "No Active Scene"

func get_library_prop_in_node_name(node_name: String) -> String:
	print('library_scenes.keys:   ', library_scenes.keys())
	for key in library_scenes.keys():
		print('get_library_prop_in_node_name:  key: ', key,'  | node name:',node_name)
		if key in node_name:
			return key
	return ""

func node_name_in_library(node_name: String) -> bool:
	for key in library_scenes.keys():
		if node_name in key:
			return true
	return false

func update_scene_list(scenes: Array) -> void:
	prop_grid.clear()
	for scene in scenes:
		prop_grid.add_item(scene)

#endregion Utility Functions


#region Signal Callback Functions
func _on_btn_autoplace_pressed() -> void:
	print('Auto Placing...')
	save_current_scene('_backup')
	autoplace_scenes()
	save_current_scene()

func _on_btn_prop_grid_remove_item_pressed() -> void:
	var selected_items: PackedInt32Array = prop_grid.get_selected_items()
	for item_idx in selected_items:
		var name: String = prop_grid.get_item_text(item_idx)
		prop_grid.remove_item(item_idx)
		library_scenes.erase(name)
	ap_saver.write_to_config(library_scenes_name, library_scenes)

func _add_scene_to_library(scene_name: String, scene_path: String) -> void:
	var scene_resource = load(scene_path)
	if scene_resource and scene_resource is PackedScene:
		library_scenes[scene_name] = scene_resource
		ap_saver.write_to_config(library_scenes_name, library_scenes)


func _on_txt_marker_key_changed() -> void:
	var old_marker_key: String = marker_key
	marker_key = txt_marker_key.text
	ap_saver.write_to_config(marker_key_name, marker_key)
	print('Marker Key changed from "', old_marker_key, '" to "', marker_key, '"')


func _on_btn_debug_pressed() -> void:
	debug_print_tree()

#endregion Signal Callback Functions


#region Debug Functions
func debug_print_tree(node: Node = self) -> void:
	for _i in 2:
		print('')
	print('Debug Print: ')
	print('Marker Key:   ', marker_key)
	print('')
	print('Scene Tree of node   ', node,'   :')
	node.print_tree_pretty()

#func db_print(variable) -> void:
	#if debug_print_enabled:
		#print(variable)

#endregion Debug Functions
