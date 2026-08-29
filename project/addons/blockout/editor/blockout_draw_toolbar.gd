@tool
class_name BlockoutDrawToolbar
extends MarginContainer

signal box_tool_toggled(enabled: bool)

const MARGIN_PX := 8
const POPUP_WIDTH_PX := 220

var _popup_min_width := 0

@onready var _box_button: Button = $Content/BoxButton
@onready var _settings_button: Button = $Content/SettingsButton
@onready var _settings_popup: PopupPanel = $SettingsPopup
@onready var _popup_margin: MarginContainer = $SettingsPopup/PopupMargin
@onready var _grid_step_spin_slider: EditorSpinSlider = (
    $SettingsPopup/PopupMargin/PopupVBox/GridStepSpinSlider
)


func _ready() -> void:
    var base_control := EditorInterface.get_base_control()
    _box_button.icon = base_control.get_theme_icon("CSGBox3D", "EditorIcons")
    _settings_button.icon = base_control.get_theme_icon("Tools", "EditorIcons")
    _box_button.toggled.connect(_on_box_button_toggled)
    _settings_button.pressed.connect(_on_settings_button_pressed)
    _apply_editor_scale(EditorInterface.get_editor_scale())


func set_box_tool_pressed(enabled: bool) -> void:
    _box_button.set_pressed_no_signal(enabled)


func get_grid_step() -> float:
    return _grid_step_spin_slider.value


func _apply_editor_scale(scale: float) -> void:
    var margin := int(MARGIN_PX * scale)
    for side in ["left", "top", "right", "bottom"]:
        add_theme_constant_override("margin_" + side, margin)
        _popup_margin.add_theme_constant_override("margin_" + side, margin)
    _popup_min_width = int(POPUP_WIDTH_PX * scale)


func _on_box_button_toggled(enabled: bool) -> void:
    box_tool_toggled.emit(enabled)


func _on_settings_button_pressed() -> void:
    _settings_popup.popup_centered(Vector2i(_popup_min_width, 0))
