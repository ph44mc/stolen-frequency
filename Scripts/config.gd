# Config.gd
extends Node

var data: Dictionary = {}

var records: Dictionary = {
	"max_wave": 0,
	"max_score": 0,
	"won": 0
}
var watched_cutscene: bool = false

# ===== ДЕФОЛТНЫЕ НАСТРОЙКИ =====
func _default_settings() -> Dictionary:
	return {
		"language": 0,
		"show_enemy_health": false,
		
		"resolution": 3,
		"fullscreen": false,
		
		"audio": {
			"overall": {"value": 1.0, "enabled": true},
			"music": {"value": 1.0, "enabled": true},
			"sfx": {"value": 1.0, "enabled": true}
		}
	}

# ===== ЗАГРУЗКА =====
func _load():
	var cfg = ConfigFile.new()
	if cfg.load("user://GameConfig.cfg") != OK:
		data = _default_settings()
		return
	
	data["language"] = cfg.get_value("game", "language", 0)
	data["show_enemy_health"] = cfg.get_value("game", "show_enemy_health", true)
	data["resolution"] = cfg.get_value("video", "resolution", 3)
	data["fullscreen"] = cfg.get_value("video", "fullscreen", false)
	
	data["audio"] = {
		"overall": cfg.get_value("audio", "overall", _default_settings()["audio"]["overall"]),
		"music": cfg.get_value("audio", "music", _default_settings()["audio"]["music"]),
		"sfx": cfg.get_value("audio", "sfx", _default_settings()["audio"]["sfx"])
	}
	
	records = {
		"max_wave": cfg.get_value("records", "max_wave", 0),
		"max_score": cfg.get_value("records", "max_score", 0),
		"won": cfg.get_value("records", "won", 0),
	}
	
	watched_cutscene = cfg.get_value("cutscene", "watched_cutscene", 0)
	
	TranslationServer.set_locale(["en","ru"][data["language"]])
	
# ===== СОХРАНЕНИЕ =====
func _save():
	var cfg = ConfigFile.new()
	
	cfg.set_value("game", "language", data["language"])
	cfg.set_value("game", "show_enemy_health", data["show_enemy_health"])
	cfg.set_value("video", "resolution", data["resolution"])
	cfg.set_value("video", "fullscreen", data["fullscreen"])
	
	cfg.set_value("audio", "overall", data["audio"]["overall"])
	cfg.set_value("audio", "music", data["audio"]["music"])
	cfg.set_value("audio", "sfx", data["audio"]["sfx"])
	
	
	cfg.set_value("records", "max_wave", records["max_wave"])
	cfg.set_value("records", "max_score", records["max_score"])
	cfg.set_value("records", "won", records["won"])
		
	cfg.set_value("cutscene", "watched_cutscene", watched_cutscene)
		
	cfg.save("user://GameConfig.cfg")
	
	
# ===== RESET =====
func _reset():
	var saved_records = records.duplicate()
	data = _default_settings()
	records = saved_records
	_save()
	
# ===== ПРОВЕРКА НА ДЕФОЛТ =====
func is_default() -> bool:
	return data == _default_settings()
	
func update_wave_record(value: int):
	if value > records["max_wave"]:
		records["max_wave"] = value
		_save()
		
func update_score_record(value: int):
	if value > records["max_score"]:
		records["max_score"] = value
		_save()
		
func add_won_times(value: int):
	records["won"] += value
	_save()
		
		
func set_watched_cutscene(value: bool):
	watched_cutscene = value
	_save()

# ===== УДАЛЕНИЕ СЕЙВА (полное) =====
func delete_save() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("GameConfig.cfg")
	
	# Сброс данных в памяти
	data = _default_settings()
	records = {
		"max_wave": 0,
		"max_score": 0,
		"won": 0
	}
	watched_cutscene = false
	
