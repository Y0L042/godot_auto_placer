@tool
extends ItemList

signal signal_add_scene_to_library(scene_name, scene_path)

func _ready() -> void:
	pass


func _gui_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MASK_LEFT and event.pressed:
		# Start dragging
		var dragged_data = _get_drag_data(event.position)
		#if dragged_data != null:
			#set_drag_preview(dragged_data.preview)

	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		# Handle drag motion
		pass

func _get_drag_data(position) -> Variant:
	# Define how you identify and handle the dragged scene
	return {"type": "scene", "path": "res://path_to_scene.tscn"}

func _can_drop_data(position, data) -> bool:
	# Check if the data is the type we can handle
	#print(data and "type" in data and data["type"] == "scene")
	#return data and "type" in data and data["type"] == "scene"
	return true

func _drop_data(position, data) -> void:
	if _can_drop_data(position, data):
		if typeof(data) == TYPE_DICTIONARY && data.has('files'):
			var scene_path: String = data['files'][0]
			print('Scene Path:', scene_path)
			if is_a_duplicate(scene_path):
				return
			_add_scene_to_library(scene_path)
			print('Scene added to library:   ',scene_path)
			return

func is_a_duplicate(scene: String) -> bool:
	for item_idx in self.item_count:
		print('Item in prop_grid:   ', self.get_item_text(item_idx))
		if self.get_item_text(item_idx) in scene:
			print('AP.prop_grid.is_a_duplicate(): duplicate ->   ', scene)
			return true
	return false

func _add_scene_to_library(scene_path: String) -> void:
	var scene_name: String = scene_path.get_file().get_basename()
	add_item(scene_name)
	emit_signal("signal_add_scene_to_library", scene_name, scene_path)

