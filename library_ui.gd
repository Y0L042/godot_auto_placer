@tool
extends Control

@onready var prop_grid: ItemList = %prop_grid
@onready var btn_autoplace: Button = %btn_autoplace

@onready var btn_debug: Button = $Panel/VBoxContainer/btn_debug


var editor_interface:EditorInterface
var library_scenes: Dictionary = {}  # Dictionary to store scenes with their names as keys

var ap_parent: EditorPlugin


func _ready() -> void:
	prop_grid.mouse_filter = Control.MOUSE_FILTER_PASS # Set the item list mouse filter to pass to get the drag and drop working on this node
	btn_autoplace.pressed.connect(_on_btn_autoplace_pressed)
	prop_grid.scene_added.connect(_on_scene_added)

	btn_debug.pressed.connect(_on_btn_debug_pressed)


func autoplace_scenes() -> void:
	var active_scene: Node = get_tree().edited_scene_root
	print('Active Scene:   ', active_scene)
	print('Active Scene Children:   ', active_scene.get_children())
	for node in active_scene.get_children():
		print('Node Name:   ', node.name, '   - Node Children:   ',node.get_children())
		if node_name_in_library(node.name):
			print(node.name,'   is in library')
			var scene_resource: PackedScene = library_scenes[node.name]
			if scene_resource is PackedScene:
				var scene_instance: Node = scene_resource.instantiate()
				node.add_child(scene_instance)
				scene_instance.set_owner(node.get_owner())
				print(scene_instance.owner)
				debug_print_tree(scene_instance)
		else:
			print(node.name,'   not found in library')
		debug_print_tree(node.owner)





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



func update_scene_list(scenes: Array) -> void:
	prop_grid.clear()
	for scene in scenes:
		prop_grid.add_item(scene)

func _on_btn_autoplace_pressed() -> void:
	print('Auto Placing...')
	save_current_scene('_backup')
	autoplace_scenes()
	save_current_scene()

func _on_scene_added(scene_name: String, scene_path: String) -> void:
	var scene_resource = load(scene_path)
	if scene_resource and scene_resource is PackedScene:
		library_scenes[scene_name] = scene_resource


func node_name_in_library(node_name: String) -> bool:
	for key in library_scenes.keys():
		if node_name in key:
			return true
	return false



func _on_btn_debug_pressed() -> void:
	debug_print_tree()

func debug_print_tree(node: Node = self) -> void:
	print('Scene Tree of node   ', node,'   :')
	node.print_tree_pretty()
