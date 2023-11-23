@tool
extends Control

@onready var prop_grid: ItemList = %prop_grid
@onready var btn_autoplace: Button = %btn_autoplace


var editor_interface:EditorInterface
var library_scenes: Dictionary = {}  # Dictionary to store scenes with their names as keys



func _ready() -> void:
	prop_grid.mouse_filter = Control.MOUSE_FILTER_PASS # Set the item list mouse filter to pass to get the drag and drop working on this node
	btn_autoplace.pressed.connect(_on_btn_autoplace_pressed)
	prop_grid.scene_added.connect(_on_scene_added)

func autoplace_scenes() -> void:
	var active_scene: Node = get_tree().edited_scene_root
	for node in active_scene.get_children():
		if node_name_in_library(node.name):
			print('In library')
			var scene_resource: PackedScene = library_scenes[node.name]
			if scene_resource is PackedScene:
				var scene_instance: Node = scene_resource.instantiate()
				node.add_child(scene_instance)


func update_scene_list(scenes: Array) -> void:
	prop_grid.clear()
	for scene in scenes:
		prop_grid.add_item(scene)

func _on_btn_autoplace_pressed() -> void:
	print('Hello, World!')
	autoplace_scenes()

func _on_scene_added(scene_name: String, scene_path: String) -> void:
	var scene_resource = load(scene_path)
	if scene_resource and scene_resource is PackedScene:
		library_scenes[scene_name] = scene_resource


func node_name_in_library(node_name: String) -> bool:
	for key in library_scenes.keys():
		if node_name in key:
			return true
	return false
