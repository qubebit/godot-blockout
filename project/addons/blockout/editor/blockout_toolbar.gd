@tool
extends MenuButton

signal edit_mode_toggled(enabled: bool)
signal rebuild_requested()

const ITEM_EDIT_MODE := 0
const ITEM_REBUILD := 1


func _ready() -> void:
    text = "Blockout"
    focus_mode = Control.FOCUS_NONE
    var popup := get_popup()
    popup.add_check_item("Edit Mode", ITEM_EDIT_MODE)
    popup.add_item("Rebuild Mesh", ITEM_REBUILD)
    popup.id_pressed.connect(_on_id_pressed)


func set_edit_mode_pressed(enabled: bool) -> void:
    var popup := get_popup()
    popup.set_item_checked(popup.get_item_index(ITEM_EDIT_MODE), enabled)


func _on_id_pressed(id: int) -> void:
    match id:
        ITEM_EDIT_MODE:
            var popup := get_popup()
            var idx := popup.get_item_index(ITEM_EDIT_MODE)
            edit_mode_toggled.emit(not popup.is_item_checked(idx))
        ITEM_REBUILD:
            rebuild_requested.emit()
