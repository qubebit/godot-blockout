@tool
extends EditorPlugin

const BlockoutToolbarScene: PackedScene = preload(
    "res://addons/blockout/editor/blockout_toolbar.tscn"
)
const BlockoutDrawToolbarScene: PackedScene = preload(
    "res://addons/blockout/editor/blockout_draw_toolbar.tscn"
)

var _toolbar: BlockoutToolbar
var _editor: BlockoutEditor
var _draw_toolbar: BlockoutDrawToolbar
var _draw_tool: BlockoutDrawTool


func _enter_tree() -> void:
    _setup_editor()


func _exit_tree() -> void:
    _teardown_editor()


func _setup_editor() -> void:
    _setup_blockout_toolbar()
    _setup_draw_tool()


func _teardown_editor() -> void:
    _teardown_blockout_toolbar()
    _teardown_draw_tool()


func _setup_blockout_toolbar() -> void:
    _toolbar = BlockoutToolbarScene.instantiate() as BlockoutToolbar
    _editor = BlockoutEditor.new(self, _toolbar)

    _toolbar.edit_mode_toggled.connect(_editor.on_edit_mode_toggled)
    _toolbar.rebuild_requested.connect(_editor.on_rebuild_requested)

    get_editor_interface().get_selection().selection_changed.connect(_editor.on_selection_changed)

    _toolbar.hide()

    add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)


func _teardown_blockout_toolbar() -> void:
    get_editor_interface().get_selection().selection_changed.disconnect(
        _editor.on_selection_changed
    )

    remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)

    _toolbar.queue_free()
    _editor = null
    _toolbar = null


func _setup_draw_tool() -> void:
    _draw_toolbar = BlockoutDrawToolbarScene.instantiate() as BlockoutDrawToolbar
    _draw_tool = BlockoutDrawTool.new(self, _draw_toolbar)

    _draw_toolbar.box_tool_toggled.connect(_draw_tool.set_active)

    add_control_to_container(CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _draw_toolbar)


func _teardown_draw_tool() -> void:
    remove_control_from_container(CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, _draw_toolbar)

    _draw_toolbar.queue_free()
    _draw_tool = null
    _draw_toolbar = null


func _handles(_object: Object) -> bool:
    return true


func _edit(object: Object) -> void:
    _editor.edit(object)


func _make_visible(visible: bool) -> void:
    _editor.make_visible(visible)


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
    var draw_result := _draw_tool.handle_viewport_input(viewport_camera, event)
    if draw_result != EditorPlugin.AFTER_GUI_INPUT_PASS:
        return draw_result
    return _editor.handle_viewport_input(event)


func _forward_3d_draw_over_viewport(overlay: Control) -> void:
    _draw_tool.update_viewport_overlay(overlay)
    _editor.update_viewport_overlay(overlay)
