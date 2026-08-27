#pragma once

#include "godot_cpp/classes/array_mesh.hpp"
#include "godot_cpp/classes/csg_shape3d.hpp"
#include "godot_cpp/variant/transform3d.hpp"

using namespace godot;

namespace blockout::api {

Ref<ArrayMesh> bake_csg_mesh(CSGShape3D *p_root, const Transform3D &p_base_transform, float p_texel_size);

} // namespace blockout::api
