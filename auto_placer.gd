@tool
class_name AutoPlacer
extends EditorPlugin

static var instance: AutoPlacer = null
var library_ui: Control  # UI for the plugin
var undo_redo: UndoRedo = UndoRedo.new()

func _enter_tree() -> void:
	instance = self
	print('Auto Placer entered tree')
	library_ui = preload("res://addons/auto_placer/library_ui.tscn").instantiate()
	#library_ui.ap_parent = self
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, library_ui)

func _exit_tree() -> void:
	remove_control_from_docks(library_ui)
	library_ui.queue_free()








