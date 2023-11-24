@tool
extends Control

#region Nodes
@onready var prop_grid: ItemList = %prop_grid
@onready var btn_autoplace: Button = %btn_autoplace
@onready var btn_debug: Button = $Panel/VBoxContainer/btn_debug
@onready var txt_marker_key: TextEdit = %txt_marker_key
#endregion Nodes

#region Variables
var editor_interface:EditorInterface
var ap_parent: EditorPlugin
var debug_print_enabled: bool = true
#endregion Variables

#region Saved Variables TODO
var marker_key: String
var library_scenes: Dictionary = {}  # Dictionary to store scenes with their names as keys
#endregion Saved Variables



func _ready() -> void:
	# Connect Signals
	btn_autoplace.pressed.connect(_on_btn_autoplace_pressed)
	prop_grid.scene_added.connect(_on_scene_added)
	btn_debug.pressed.connect(_on_btn_debug_pressed)
	txt_marker_key.text_changed.connect(_on_txt_marker_key_changed)

	# Set Variables
	prop_grid.mouse_filter = Control.MOUSE_FILTER_PASS # Set the item list mouse filter to pass to get the drag and drop working on this node
	marker_key = txt_marker_key.text


#region Scene Placement Functions
func autoplace_scenes() -> void:
	var active_scene_root: Node = get_tree().edited_scene_root
	print('Active Scene Root:   ', active_scene_root)
	#debug_print_tree(active_scene_root)
	place_scenes_recursive(active_scene_root, active_scene_root)
	debug_print_tree(active_scene_root)


func place_scenes_recursive(node: Node, root_owner: Node) -> void:
	var _root_owner: Node = root_owner
	var has_placed_scene: bool = false
	for child in node.get_children():
		#print('Testing --   Marker Key: ', marker_key, '   |   Child Name: ', child.name, '   |   [1] in [2]: ', marker_key in child.name)
		if marker_key in child.name:
			var modified_name: String = child.name.replace(marker_key, "")
			if node_name_in_library(modified_name):
				print(' + ', child.name.replace(marker_key, ""), ' is in library')
				place_scene(child, modified_name, _root_owner)
				has_placed_scene = true
		else:
			print(' - ',child.name, ' not found in library')
		# Only continue recursion if no scene was placed in this child
		if not has_placed_scene:
			place_scenes_recursive(child, _root_owner)



func place_scene(node: Node, name: String, root_owner: Node) -> void:
	var scene_resource: PackedScene = library_scenes[name]
	if scene_resource is PackedScene:
		var scene_instance: Node = scene_resource.instantiate()
		node.add_child(scene_instance)
		scene_instance.set_owner(root_owner)
		print('Placed Prop Owner: ',scene_instance.owner)

#endregion Scene Placement Functions

#region Utility Functions
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


func _on_scene_added(scene_name: String, scene_path: String) -> void:
	var scene_resource = load(scene_path)
	if scene_resource and scene_resource is PackedScene:
		library_scenes[scene_name] = scene_resource


func _on_txt_marker_key_changed() -> void:
	var old_marker_key: String = marker_key
	marker_key = txt_marker_key.text
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
