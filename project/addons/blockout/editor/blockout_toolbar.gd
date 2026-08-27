@tool
class_name BlockoutToolbar
extends MenuButton

signal edit_mode_toggled(enabled: bool)
signal rebuild_requested()

const ITEM_EDIT_MODE := 0
const ITEM_REBUILD := 1


func _ready() -> void:
    _setup_popup()


func set_edit_mode_pressed(enabled: bool) -> void:
    var popup := get_popup()
    var idx := popup.get_item_index(ITEM_EDIT_MODE)
    if idx == -1:
        return
    popup.set_item_checked(idx, enabled)


func _setup_popup() -> void:
    var popup := get_popup()
    popup.clear()
    popup.add_check_item("Edit Mode", ITEM_EDIT_MODE)
    popup.add_item("Rebuild Mesh", ITEM_REBUILD)
    if not popup.id_pressed.is_connected(_on_id_pressed):
        popup.id_pressed.connect(_on_id_pressed)


func _on_id_pressed(id: int) -> void:
    match id:
        ITEM_EDIT_MODE:
            _toggle_edit_mode()
        ITEM_REBUILD:
            _request_rebuild()


func _toggle_edit_mode() -> void:
    var popup := get_popup()
    var idx := popup.get_item_index(ITEM_EDIT_MODE)
    if idx == -1:
        return
    edit_mode_toggled.emit(not popup.is_item_checked(idx))


func _request_rebuild() -> void:
    rebuild_requested.emit()
