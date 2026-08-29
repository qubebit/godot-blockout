@tool
class_name BlockoutDrawTool
extends RefCounted

enum State {
    IDLE,
    DRAWING_BASE,
    DRAWING_HEIGHT,
}

const CREATE_ACTION := "Create CSGBox3D"
const MIN_FOOTPRINT_SIZE := 0.05
const PREVIEW_COLOR := Color(0.3, 0.85, 0.4, 0.9)

var _plugin: EditorPlugin
var _toolbar: BlockoutDrawToolbar
var _active := false
var _state: State = State.IDLE
var _camera: Camera3D = null

var _base_start := Vector3.ZERO
var _rect_min := Vector3.ZERO
var _rect_max := Vector3.ZERO
var _height := 0.0


func _init(plugin: EditorPlugin, toolbar: BlockoutDrawToolbar) -> void:
    _plugin = plugin
    _toolbar = toolbar


func set_active(enabled: bool) -> void:
    if _active == enabled:
        return
    _active = enabled
    if not enabled:
        _reset_state()
    _plugin.update_overlays()


func handle_viewport_input(camera: Camera3D, event: InputEvent) -> int:
    _camera = camera

    if not _active:
        return EditorPlugin.AFTER_GUI_INPUT_PASS

    if event is InputEventKey:
        return _handle_key(event as InputEventKey)
    if event is InputEventMouseButton:
        return _handle_mouse_button(event as InputEventMouseButton)
    if event is InputEventMouseMotion:
        return _handle_mouse_motion(event as InputEventMouseMotion)

    return EditorPlugin.AFTER_GUI_INPUT_PASS


func update_viewport_overlay(overlay: Control) -> void:
    if not _active or _camera == null:
        return

    match _state:
        State.DRAWING_BASE:
            _draw_rect_outline(overlay, _rect_min, _rect_max, 0.0)
        State.DRAWING_HEIGHT:
            _draw_box_outline(overlay, _rect_min, _rect_max, _height)


func _handle_key(key_event: InputEventKey) -> int:
    var is_cancel_shortcut := (
        key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE
    )
    if is_cancel_shortcut and _state != State.IDLE:
        _reset_state()
        return _redraw_and_stop()
    return EditorPlugin.AFTER_GUI_INPUT_PASS


func _handle_mouse_button(mouse_event: InputEventMouseButton) -> int:
    if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
        return EditorPlugin.AFTER_GUI_INPUT_PASS

    match _state:
        State.IDLE:
            var point: Variant = _intersect_ground_plane(mouse_event.position)
            if point == null:
                return EditorPlugin.AFTER_GUI_INPUT_PASS
            _base_start = _snap_ground_point(point)
            _rect_min = _base_start
            _rect_max = _base_start
            _state = State.DRAWING_BASE
            return _redraw_and_stop()
        State.DRAWING_BASE:
            if _rect_min.distance_to(_rect_max) < MIN_FOOTPRINT_SIZE:
                _reset_state()
            else:
                _height = 0.0
                _state = State.DRAWING_HEIGHT
            return _redraw_and_stop()
        State.DRAWING_HEIGHT:
            _commit()
            return _redraw_and_stop()

    return EditorPlugin.AFTER_GUI_INPUT_PASS


func _handle_mouse_motion(mouse_event: InputEventMouseMotion) -> int:
    match _state:
        State.DRAWING_BASE:
            var point: Variant = _intersect_ground_plane(mouse_event.position)
            if point == null:
                return EditorPlugin.AFTER_GUI_INPUT_STOP
            var snapped: Vector3 = _snap_ground_point(point)
            _rect_min = Vector3(minf(_base_start.x, snapped.x), 0.0, minf(_base_start.z, snapped.z))
            _rect_max = Vector3(maxf(_base_start.x, snapped.x), 0.0, maxf(_base_start.z, snapped.z))
            return _redraw_and_stop()
        State.DRAWING_HEIGHT:
            var center := _footprint_center()
            var point: Variant = _intersect_height_plane(mouse_event.position, center)
            if point == null:
                return EditorPlugin.AFTER_GUI_INPUT_STOP
            var step := _grid_step()
            _height = maxf(step, _snap_value((point as Vector3).y, step))
            return _redraw_and_stop()

    return EditorPlugin.AFTER_GUI_INPUT_PASS


func _redraw_and_stop() -> int:
    _plugin.update_overlays()
    return EditorPlugin.AFTER_GUI_INPUT_STOP


func _intersect_ground_plane(mouse_pos: Vector2) -> Variant:
    var plane := Plane(Vector3.UP, 0.0)
    return _intersect_plane(plane, mouse_pos)


func _intersect_height_plane(mouse_pos: Vector2, anchor: Vector3) -> Variant:
    var right := _camera.global_transform.basis.x
    right.y = 0.0
    var normal := right.normalized() if right.length() > 0.001 else Vector3.RIGHT
    return _intersect_plane(Plane(normal, anchor), mouse_pos)


func _intersect_plane(plane: Plane, mouse_pos: Vector2) -> Variant:
    var from := _camera.project_ray_origin(mouse_pos)
    var dir := _camera.project_ray_normal(mouse_pos)
    return plane.intersects_ray(from, dir)


func _footprint_center() -> Vector3:
    return Vector3((_rect_min.x + _rect_max.x) * 0.5, 0.0, (_rect_min.z + _rect_max.z) * 0.5)


func _snap_ground_point(point: Vector3) -> Vector3:
    var step := _grid_step()
    return Vector3(_snap_value(point.x, step), 0.0, _snap_value(point.z, step))


func _snap_value(value: float, step: float) -> float:
    if step <= 0.0:
        return value
    return roundf(value / step) * step


func _grid_step() -> float:
    return _toolbar.get_grid_step()


func _commit() -> void:
    var height := maxf(_height, _grid_step())
    var size := Vector3(_rect_max.x - _rect_min.x, height, _rect_max.z - _rect_min.z)
    var center := _footprint_center()
    center.y = height * 0.5

    var scene_root := _plugin.get_editor_interface().get_edited_scene_root()
    if scene_root == null:
        _reset_state()
        return

    var parent := _resolve_parent(scene_root)
    var local_position := center
    if parent is Node3D:
        local_position = (parent as Node3D).to_local(center)

    var box := CSGBox3D.new()
    box.name = "CSGBox3D"
    box.size = size
    box.position = local_position

    var undo_redo := _plugin.get_undo_redo()
    undo_redo.create_action(CREATE_ACTION)
    undo_redo.add_do_method(parent, "add_child", box, true)
    undo_redo.add_do_method(box, "set_owner", scene_root)
    undo_redo.add_do_reference(box)
    undo_redo.add_undo_method(parent, "remove_child", box)
    undo_redo.commit_action()

    var selection := _plugin.get_editor_interface().get_selection()
    selection.clear()
    selection.add_node(box)

    _reset_state()


func _resolve_parent(scene_root: Node) -> Node:
    var selected := _plugin.get_editor_interface().get_selection().get_selected_nodes()
    if selected.size() != 1 or not (selected[0] is CSGShape3D):
        return scene_root

    var parent := (selected[0] as CSGShape3D).get_parent()
    return parent if parent != null else scene_root


func _reset_state() -> void:
    _state = State.IDLE
    _rect_min = Vector3.ZERO
    _rect_max = Vector3.ZERO
    _height = 0.0


func _draw_rect_outline(
    overlay: Control,
    rect_min: Vector3,
    rect_max: Vector3,
    height: float,
) -> void:
    var corners := [
        Vector3(rect_min.x, height, rect_min.z),
        Vector3(rect_max.x, height, rect_min.z),
        Vector3(rect_max.x, height, rect_max.z),
        Vector3(rect_min.x, height, rect_max.z),
    ]
    for i in corners.size():
        _draw_line_3d(overlay, corners[i], corners[(i + 1) % corners.size()])


func _draw_box_outline(
    overlay: Control,
    rect_min: Vector3,
    rect_max: Vector3,
    height: float,
) -> void:
    _draw_rect_outline(overlay, rect_min, rect_max, 0.0)
    _draw_rect_outline(overlay, rect_min, rect_max, height)
    var bottoms := [
        Vector3(rect_min.x, 0.0, rect_min.z),
        Vector3(rect_max.x, 0.0, rect_min.z),
        Vector3(rect_max.x, 0.0, rect_max.z),
        Vector3(rect_min.x, 0.0, rect_max.z),
    ]
    for corner in bottoms:
        _draw_line_3d(overlay, corner, corner + Vector3.UP * height)


func _draw_line_3d(overlay: Control, from: Vector3, to: Vector3) -> void:
    if _camera.is_position_behind(from) or _camera.is_position_behind(to):
        return
    var from_2d := _camera.unproject_position(from)
    var to_2d := _camera.unproject_position(to)
    overlay.draw_line(from_2d, to_2d, PREVIEW_COLOR, 2.0)
