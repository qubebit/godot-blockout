#pragma once

#include "godot_cpp/classes/concave_polygon_shape3d.hpp"
#include "godot_cpp/classes/mesh.hpp"

using namespace godot;

namespace blockout::api {

Ref<ConcavePolygonShape3D> build_trimesh_collision_shape(const Ref<Mesh> &p_mesh);

} // namespace blockout::api
