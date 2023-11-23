@tool
extends ItemList

signal scene_added(scene_name, scene_path)

func _ready() -> void:
	pass


func _gui_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MASK_LEFT and event.pressed:
		# Start dragging
		var dragged_data = get_drag_data(event.position)
		if dragged_data != null:
			set_drag_preview(dragged_data.preview)

	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		# Handle drag motion
		pass

func get_drag_data(position) -> Variant:
	# Define how you identify and handle the dragged scene
	return {"type": "scene", "path": "res://path_to_scene.tscn"}

func can_drop_data(position, data) -> bool:
	# Check if the data is the type we can handle
	return data and "type" in data and data["type"] == "scene"

func drop_data(position, data) -> void:
	if can_drop_data(position, data):
		var scene_path: String = data["path"]
		add_scene_to_library(scene_path)

func add_scene_to_library(scene_path: String) -> void:
	var scene_name: String = scene_path.get_file().get_basename()
	add_item(scene_name)
	emit_signal("scene_added", scene_name, scene_path)

