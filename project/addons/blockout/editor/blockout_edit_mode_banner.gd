@tool
extends PanelContainer


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

    var settings := EditorInterface.get_editor_settings()
    var scale := EditorInterface.get_editor_scale()
    var corner_radius := int(settings.get_setting("interface/theme/corner_radius") * scale)

    var style := get_theme_stylebox("panel") as StyleBoxFlat
    if style:
        style.set_corner_radius_all(corner_radius)

    offset_top = 10 * scale

    minimum_size_changed.connect(reset_size)
    call_deferred("reset_size")
