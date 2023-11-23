@tool
extends EditorPlugin

var library_ui: Control  # UI for the plugin

func _enter_tree() -> void:
	library_ui = preload("res://addons/auto_placer/library_ui.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, library_ui)

func _exit_tree() -> void:
	remove_control_from_docks(library_ui)
	library_ui.queue_free()








