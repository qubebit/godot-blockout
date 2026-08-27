@tool
extends EditorPlugin

const BlockoutToolbarScene: PackedScene = preload(
    "res://addons/blockout/editor/blockout_toolbar.tscn"
)

var _toolbar: BlockoutToolbar
var _editor: BlockoutEditor


func _enter_tree() -> void:
    _setup_editor()


func _exit_tree() -> void:
    _teardown_editor()


func _setup_editor() -> void:
    _toolbar = BlockoutToolbarScene.instantiate() as BlockoutToolbar
    _editor = BlockoutEditor.new(self, _toolbar)

    _toolbar.edit_mode_toggled.connect(_editor.on_edit_mode_toggled)
    _toolbar.rebuild_requested.connect(_editor.on_rebuild_requested)

    get_editor_interface().get_selection().selection_changed.connect(_editor.on_selection_changed)

    _toolbar.hide()

    add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)


func _teardown_editor() -> void:
    get_editor_interface().get_selection().selection_changed.disconnect(
        _editor.on_selection_changed
    )

    remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)

    _toolbar.queue_free()
    _editor = null
    _toolbar = null


func _handles(object: Object) -> bool:
    return _editor.handles(object)


func _edit(object: Object) -> void:
    _editor.edit(object)


func _make_visible(visible: bool) -> void:
    _editor.make_visible(visible)


func _forward_3d_gui_input(_viewport_camera: Camera3D, event: InputEvent) -> int:
    return _editor.handle_viewport_input(event)


func _forward_3d_draw_over_viewport(overlay: Control) -> void:
    _editor.update_viewport_overlay(overlay)
