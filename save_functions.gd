class_name AutoPlaceSaver
extends Resource

const config_address: String = 'res://addons/auto_placer/ap_save_data.cfg'

var _config: ConfigFile = ConfigFile.new() : set = _set_config, get = get_config
func _set_config(new_config: ConfigFile) -> void:
	_config = new_config
func get_config() -> ConfigFile:
	return _config


func _init() -> void:
	print("AP: Trying to load ap_save_data.cfg")
	var err: Error = _config.load(config_address)
	if err == OK:
		print("AP: Success!")
	if err != OK:
		print('AP: Error code: ', err)
		_config = ConfigFile.new()
		save_config()


func write_to_config(key: String, value: Variant, section: String = 'global'):
	_config.set_value(section, key, value)
	save_config()


func read_from_config(key: String, section: String = 'global') -> Variant:
	var value: Variant = null
	value = _config.get_value(section, key)
	return value


func save_config() -> Error:
	var err: Error = _config.save(config_address)
	print('Saving Config...   ', err)
	return err
