@tool
class_name BlockoutDrawToolbar
extends MarginContainer

signal box_tool_toggled(enabled: bool)

const POPUP_SIZE := Vector2i(220, 0)
const BOX_ICON := preload("res://addons/blockout/icons/box_tool.svg")

@onready var _box_button: Button = $Content/BoxButton
@onready var _settings_button: Button = $Content/SettingsButton
@onready var _settings_popup: PopupPanel = $SettingsPopup
@onready var _grid_step_spin_slider: EditorSpinSlider = (
    $SettingsPopup/PopupMargin/PopupVBox/GridStepSpinSlider
)


func _ready() -> void:
    var base_control := EditorInterface.get_base_control()
    _box_button.icon = BOX_ICON
    _settings_button.icon = base_control.get_theme_icon("Tools", "EditorIcons")
    _box_button.toggled.connect(_on_box_button_toggled)
    _settings_button.pressed.connect(_on_settings_button_pressed)


func set_box_tool_pressed(enabled: bool) -> void:
    _box_button.set_pressed_no_signal(enabled)


func get_grid_step() -> float:
    return _grid_step_spin_slider.value


func _on_box_button_toggled(enabled: bool) -> void:
    box_tool_toggled.emit(enabled)


func _on_settings_button_pressed() -> void:
    _settings_popup.popup_centered(POPUP_SIZE)
