extends Control

signal close_menu

# ===== НОДЫ =====
@onready var tab_container = $HBoxContainer2/TabContainer
@onready var tab_buttons = $HBoxContainer2/Tabs.get_children()

@onready var delete_save: Button = $HBoxContainer/DeleteSave

@onready var language_option = $HBoxContainer2/TabContainer/Game/MarginContainer/VBoxContainer/Language/MenuButton
@onready var roll_animation_toggle: SwitchButton = $HBoxContainer2/TabContainer/Game/MarginContainer/VBoxContainer/RollAnimation/OnOff

@onready var resolution_option = $HBoxContainer2/TabContainer/Video/MarginContainer/VBoxContainer/Resolution/MenuButton
@onready var fullscreen_toggle = $HBoxContainer2/TabContainer/Video/MarginContainer/VBoxContainer/Fullscreen/OnOff

@onready var overall_slider = $HBoxContainer2/TabContainer/Audio/MarginContainer/VBoxContainer/Overall/Slider
@onready var overall_toggle = $HBoxContainer2/TabContainer/Audio/MarginContainer/VBoxContainer/Overall/OnOff
@onready var overall_value = $HBoxContainer2/TabContainer/Audio/MarginContainer/VBoxContainer/Overall/Value

@onready var music_slider = $HBoxContainer2/TabContainer/Audio/MarginContainer/VBoxContainer/Music/Slider
@onready var music_toggle = $HBoxContainer2/TabContainer/Audio/MarginContainer/VBoxContainer/Music/OnOff
@onready var music_value = $HBoxContainer2/TabContainer/Audio/MarginContainer/VBoxContainer/Music/Value

@onready var sfx_slider = $HBoxContainer2/TabContainer/Audio/MarginContainer/VBoxContainer/SFX/Slider
@onready var sfx_toggle = $HBoxContainer2/TabContainer/Audio/MarginContainer/VBoxContainer/SFX/OnOff
@onready var sfx_value = $HBoxContainer2/TabContainer/Audio/MarginContainer/VBoxContainer/SFX/Value

@onready var back_btn = $HBoxContainer/Back
@onready var reset_btn = $HBoxContainer/Reset

var resolutions = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
	
	Vector2i(1680, 1050),
	Vector2i(1920, 1200),
	
	Vector2i(1024, 768),
	Vector2i(1280, 960),
]

var is_updating_ui = false
	
# ===== INIT =====
func _ready() -> void:
	get_tree().current_scene.ready.connect(_on_scene_ready)

func _on_scene_ready():
	Config._load()  # Загружаем настройки из синглтона
	connect_signals()
	update_ui()
	apply_all_once()

# ===== SIGNALS =====
func connect_signals():
	for i in tab_buttons.size():
		tab_buttons[i].pressed.connect(func(): switch_tab(i))

	delete_save.pressed.connect(_on_delete_save_pressed)

	back_btn.pressed.connect(_on_back_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)

	language_option.item_selected.connect(_on_language_changed)
	roll_animation_toggle.switched.connect(_on_roll_anim_toggled)
	
	resolution_option.item_selected.connect(_on_resolution_changed)
	fullscreen_toggle.switched.connect(_on_fullscreen_toggled)

	overall_slider.value_changed.connect(_on_overall_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	overall_toggle.switched.connect(_on_overall_toggled)
	music_toggle.switched.connect(_on_music_toggled)
	sfx_toggle.switched.connect(_on_sfx_toggled)

# ===== UI =====
func switch_tab(index: int):
	tab_container.current_tab = index
	for i in tab_buttons.size():
		tab_buttons[i].modulate = Color(1,1,1) if i == index else Color(0.5,0.5,0.5)

func update_ui():
	is_updating_ui = true

	language_option.select(Config.data["language"])
	roll_animation_toggle.switch(Config.data["roll_anim"])
	
	resolution_option.select(Config.data["resolution"])
	fullscreen_toggle.switch(Config.data["fullscreen"])

	overall_slider.value = Config.data["audio"]["overall"]["value"]
	overall_toggle.switch(Config.data["audio"]["overall"]["enabled"])

	music_slider.value = Config.data["audio"]["music"]["value"]
	music_toggle.switch(Config.data["audio"]["music"]["enabled"])

	sfx_slider.value = Config.data["audio"]["sfx"]["value"]
	sfx_toggle.switch(Config.data["audio"]["sfx"]["enabled"])

	update_volume_labels()
	update_reset_button()

	is_updating_ui = false

func update_volume_labels():
	overall_value.text = str(int(Config.data["audio"]["overall"]["value"] * 100)) + "%"
	music_value.text = str(int(Config.data["audio"]["music"]["value"] * 100)) + "%"
	sfx_value.text = str(int(Config.data["audio"]["sfx"]["value"] * 100)) + "%"

func update_reset_button():
	var is_default_now = Config.is_default()
	reset_btn.disabled = is_default_now
	reset_btn.modulate = Color(1,1,1) if !is_default_now else Color(0.5,0.5,0.5)

# ===== APPLY =====
func apply_fullscreen():
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if Config.data["fullscreen"]
		else DisplayServer.WINDOW_MODE_WINDOWED
	)

func apply_resolution():
	var res = resolutions[Config.data["resolution"]]
	DisplayServer.window_set_size(res)


func apply_audio(bus: int, data: Dictionary):
	AudioServer.set_bus_volume_db(bus, linear_to_db(data["value"]))
	AudioServer.set_bus_mute(bus, not data["enabled"])

func apply_all_once():
	apply_fullscreen()
	apply_resolution()
	apply_audio(0, Config.data["audio"]["overall"])
	apply_audio(1, Config.data["audio"]["music"])
	apply_audio(2, Config.data["audio"]["sfx"])

# ===== SETTINGS CHANGED =====
func _on_language_changed(index):
	if is_updating_ui: return
	Config.data["language"] = language_option.get_item_id(index)
	TranslationServer.set_locale(["en","ru"][Config.data["language"]])
	
func _on_roll_anim_toggled(on):
	if is_updating_ui: return
	Config.data["roll_anim"] = on
	update_reset_button()

func _on_fullscreen_toggled(on):
	if is_updating_ui: return
	Config.data["fullscreen"] = on
	apply_fullscreen()
	update_reset_button()
	
func _on_resolution_changed(index):
	if is_updating_ui: return
	Config.data["resolution"] = resolution_option.get_item_id(index)
	apply_resolution()
	update_reset_button()
	
func _on_overall_changed(value):
	if is_updating_ui: return
	Config.data["audio"]["overall"]["value"] = value
	update_volume_labels()
	apply_audio(0, Config.data["audio"]["overall"])
	update_reset_button()
	
func _on_music_changed(value):
	if is_updating_ui: return
	Config.data["audio"]["music"]["value"] = value
	update_volume_labels()
	apply_audio(1, Config.data["audio"]["music"])
	update_reset_button()

func _on_sfx_changed(value):
	if is_updating_ui: return
	Config.data["audio"]["sfx"]["value"] = value
	update_volume_labels()
	apply_audio(2, Config.data["audio"]["sfx"])
	update_reset_button()

func _on_overall_toggled(on):
	if is_updating_ui: return
	Config.data["audio"]["overall"]["enabled"] = on
	apply_audio(0, Config.data["audio"]["overall"])
	update_reset_button()

func _on_music_toggled(on):
	if is_updating_ui: return
	Config.data["audio"]["music"]["enabled"] = on
	apply_audio(1, Config.data["audio"]["music"])
	update_reset_button()

func _on_sfx_toggled(on):
	if is_updating_ui: return
	Config.data["audio"]["sfx"]["enabled"] = on
	apply_audio(2, Config.data["audio"]["sfx"])
	update_reset_button()

# ===== BUTTONS =====
func _on_back_pressed():
	Config._save()
	close_menu.emit()

func _on_reset_pressed():
	Config._reset()        # возвращаем все к дефолту
	update_ui()
	apply_all_once()
	
func _on_delete_save_pressed():
	Config.delete_save()
	Config._save()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
