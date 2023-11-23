@tool
extends TextEdit

func _can_drop_data(position, data) -> bool:
	# Check if the data is the type we can handle
	#print(data and "type" in data and data["type"] == "scene")
	#return data and "type" in data and data["type"] == "scene"
	return true

func _drop_data(position, data) -> void:
	print(data)
	self.text = data

