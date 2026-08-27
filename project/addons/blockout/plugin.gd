@tool
extends EditorPlugin

const BlockoutToolbarScene := preload("res://addons/blockout/editor/blockout_toolbar.tscn")
const BlockoutEditModeBannerScene := preload(
    "res://addons/blockout/editor/blockout_edit_mode_banner.tscn"
)

var _toolbar: Control
var _edited_node: CSGInstance3D
var _last_edit_key_event: InputEvent


func _enter_tree() -> void:
    _toolbar = BlockoutToolbarScene.instantiate()
    _toolbar.icon = load("res://addons/blockout/icons/csg_instance_3d.svg")
    _toolbar.edit_mode_toggled.connect(_on_edit_mode_toggled)
    _toolbar.rebuild_requested.connect(_on_rebuild_requested)
    get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)
    _toolbar.hide()
    add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)


func _exit_tree() -> void:
    get_editor_interface().get_selection().selection_changed.disconnect(_on_selection_changed)
    remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)
    _toolbar.queue_free()


func _handles(object: Object) -> bool:
    return _get_csg_instance(object) != null


func _edit(object: Object) -> void:
    _edited_node = _get_csg_instance(object)
    if _edited_node == null:
        _clear_edit_state()
        return

    _toolbar.show()
    _toolbar.set_edit_mode_pressed(_edited_node.is_edit_mode())
    update_overlays()


func _make_visible(visible: bool) -> void:
    if visible:
        return

    _clear_edit_state()


func _on_selection_changed() -> void:
    call_deferred("_sync_edit_state_with_selection")


func _sync_edit_state_with_selection() -> void:
    if _edited_node == null or _is_edited_node_selected():
        return

    _clear_edit_state()


func _clear_edit_state() -> void:
    _toolbar.hide()
    _edited_node = null
    _last_edit_key_event = null
    update_overlays()


func _forward_3d_gui_input(_viewport_camera: Camera3D, event: InputEvent) -> int:
    if not _is_edited_node_current():
        return EditorPlugin.AFTER_GUI_INPUT_PASS
    if not _is_edit_mode_shortcut(event):
        return EditorPlugin.AFTER_GUI_INPUT_PASS
    if event == _last_edit_key_event:
        return EditorPlugin.AFTER_GUI_INPUT_STOP

    _last_edit_key_event = event
    _set_edit_mode(not _edited_node.is_edit_mode())
    return EditorPlugin.AFTER_GUI_INPUT_STOP


func _forward_3d_draw_over_viewport(overlay: Control) -> void:
    var banner := _get_or_create_edit_mode_banner(overlay)
    if not _is_edited_node_current():
        banner.hide()
        return

    banner.show() if _edited_node.is_edit_mode() else banner.hide()


func _get_or_create_edit_mode_banner(overlay: Control) -> Control:
    var banner := overlay.get_node_or_null("BlockoutEditModeBanner") as Control
    if banner != null:
        return banner

    banner = BlockoutEditModeBannerScene.instantiate()
    overlay.add_child(banner)
    return banner


func _on_edit_mode_toggled(enabled: bool) -> void:
    _set_edit_mode(enabled)


func _on_rebuild_requested() -> void:
    if not _is_edited_node_current():
        return
    var undo_redo := get_undo_redo()
    undo_redo.create_action("Rebuild Mesh")
    undo_redo.add_undo_property(_edited_node, "mesh", _edited_node.mesh)
    undo_redo.add_do_method(_edited_node, "rebuild_mesh")
    undo_redo.commit_action()


func _set_edit_mode(enabled: bool) -> void:
    if not _is_edited_node_current():
        return

    _select_edited_node()
    _commit_edit_mode_change(enabled)
    _toolbar.set_edit_mode_pressed(_edited_node.is_edit_mode())
    update_overlays()


func _select_edited_node() -> void:
    var selection := get_editor_interface().get_selection()
    selection.clear()
    selection.add_node(_edited_node)


func _commit_edit_mode_change(enabled: bool) -> void:
    var undo_redo := get_undo_redo()
    undo_redo.create_action("Toggle Edit Mode")
    undo_redo.add_do_method(_edited_node, "set_edit_mode", enabled)
    undo_redo.add_undo_method(_edited_node, "set_edit_mode", not enabled)
    undo_redo.commit_action()


func _is_edit_mode_shortcut(event: InputEvent) -> bool:
    if not event is InputEventKey:
        return false
    var key_event := event as InputEventKey
    return (
        key_event.pressed and not key_event.echo and key_event.keycode == KEY_E
        and key_event.is_command_or_control_pressed()
    )


func _is_edited_node_current() -> bool:
    if _edited_node == null:
        return false
    if not is_instance_valid(_edited_node):
        return false
    if not _is_edited_node_selected():
        return false
    var scene_root := get_editor_interface().get_edited_scene_root()
    if scene_root == null:
        return false
    return scene_root == _edited_node or scene_root.is_ancestor_of(_edited_node)


func _is_edited_node_selected() -> bool:
    var selection := get_editor_interface().get_selection()
    for selected_node in selection.get_selected_nodes():
        if _get_csg_instance(selected_node) == _edited_node:
            return true
    return false


func _get_csg_instance(object: Object) -> CSGInstance3D:
    if not object is Node:
        return null
    return _find_csg_instance_ancestor(object as Node)


func _find_csg_instance_ancestor(node: Node) -> CSGInstance3D:
    var current: Node = node
    while current != null:
        if current is CSGInstance3D:
            return current as CSGInstance3D
        current = current.get_parent()
    return null
