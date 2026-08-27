@tool
class_name BlockoutEditor
extends RefCounted

const BlockoutEditModeBannerScene: PackedScene = preload(
    "res://addons/blockout/editor/blockout_edit_mode_banner.tscn"
)
const EDIT_MODE_ACTION := "Toggle Edit Mode"
const REBUILD_ACTION := "Rebuild Mesh"
const EDIT_MODE_BANNER_NAME := "BlockoutEditModeBanner"

var _plugin: EditorPlugin
var _toolbar: BlockoutToolbar
var _edited_node: CSGInstance3D = null
var _last_edit_key_event: InputEvent = null


func _init(plugin: EditorPlugin, toolbar: BlockoutToolbar) -> void:
    _plugin = plugin
    _toolbar = toolbar


func handles(object: Object) -> bool:
    return _get_csg_instance(object) != null


func edit(object: Object) -> void:
    _edited_node = _get_csg_instance(object)
    if _edited_node == null:
        _clear_edit_state()
        return

    _toolbar.show()
    _toolbar.set_edit_mode_pressed(_edited_node.is_edit_mode())
    _plugin.update_overlays()


func make_visible(visible: bool) -> void:
    if visible:
        return

    _clear_edit_state()


func on_selection_changed() -> void:
    call_deferred("_sync_edit_state_with_selection")


func on_edit_mode_toggled(enabled: bool) -> void:
    _set_edit_mode(enabled)


func on_rebuild_requested() -> void:
    if not _is_edited_node_current():
        return

    var undo_redo := _plugin.get_undo_redo()
    undo_redo.create_action(REBUILD_ACTION)
    undo_redo.add_undo_property(_edited_node, "mesh", _edited_node.mesh)
    undo_redo.add_do_method(_edited_node, "rebuild_mesh")
    undo_redo.commit_action()


func handle_viewport_input(event: InputEvent) -> int:
    if not _is_edited_node_current():
        return EditorPlugin.AFTER_GUI_INPUT_PASS
    if not _is_edit_mode_shortcut(event):
        return EditorPlugin.AFTER_GUI_INPUT_PASS
    if event == _last_edit_key_event:
        return EditorPlugin.AFTER_GUI_INPUT_STOP

    _last_edit_key_event = event
    _set_edit_mode(not _edited_node.is_edit_mode())
    return EditorPlugin.AFTER_GUI_INPUT_STOP


func update_viewport_overlay(overlay: Control) -> void:
    var banner := _get_or_create_edit_mode_banner(overlay)
    if not _is_edited_node_current():
        banner.hide()
        return

    banner.show() if _edited_node.is_edit_mode() else banner.hide()


func _sync_edit_state_with_selection() -> void:
    if _edited_node == null or _is_edited_node_selected():
        return

    _clear_edit_state()


func _clear_edit_state() -> void:
    _toolbar.hide()
    _edited_node = null
    _last_edit_key_event = null
    _plugin.update_overlays()


func _set_edit_mode(enabled: bool) -> void:
    if not _is_edited_node_current():
        return

    _select_edited_node()
    _commit_edit_mode_change(enabled)
    _toolbar.set_edit_mode_pressed(_edited_node.is_edit_mode())
    _plugin.update_overlays()


func _select_edited_node() -> void:
    var selection := _plugin.get_editor_interface().get_selection()
    selection.clear()
    selection.add_node(_edited_node)


func _commit_edit_mode_change(enabled: bool) -> void:
    var undo_redo := _plugin.get_undo_redo()
    undo_redo.create_action(EDIT_MODE_ACTION)
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

    var scene_root := _plugin.get_editor_interface().get_edited_scene_root()
    if scene_root == null:
        return false
    return scene_root == _edited_node or scene_root.is_ancestor_of(_edited_node)


func _is_edited_node_selected() -> bool:
    var selection := _plugin.get_editor_interface().get_selection()
    for selected_node: Node in selection.get_selected_nodes():
        if _get_csg_instance(selected_node) == _edited_node:
            return true
    return false


func _get_or_create_edit_mode_banner(overlay: Control) -> BlockoutEditModeBanner:
    var banner := overlay.get_node_or_null(EDIT_MODE_BANNER_NAME) as BlockoutEditModeBanner
    if banner != null:
        return banner

    banner = BlockoutEditModeBannerScene.instantiate() as BlockoutEditModeBanner
    overlay.add_child(banner)
    return banner


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
