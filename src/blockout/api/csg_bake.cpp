#include "blockout/api/csg_bake.h"

#include "godot_cpp/classes/material.hpp"
#include "godot_cpp/classes/surface_tool.hpp"
#include "godot_cpp/variant/array.hpp"

namespace blockout::api {

namespace {

bool get_csg_mesh_data(CSGShape3D *p_root, Transform3D &r_local_transform, Ref<ArrayMesh> &r_mesh) {
	if (p_root == nullptr) {
		return false;
	}

	Array meshes = p_root->get_meshes();
	if (meshes.size() < 2) {
		return false;
	}

	r_local_transform = meshes[0];
	r_mesh = meshes[1];
	return r_mesh.is_valid();
}

Ref<ArrayMesh> apply_transform(const Ref<ArrayMesh> &p_mesh, const Transform3D &p_transform) {
	if (p_transform.is_equal_approx(Transform3D())) {
		return p_mesh;
	}

	Ref<SurfaceTool> surface_tool;
	surface_tool.instantiate();
	Ref<ArrayMesh> transformed;
	transformed.instantiate();
	for (int32_t i = 0; i < p_mesh->get_surface_count(); i++) {
		surface_tool->clear();
		surface_tool->append_from(p_mesh, i, p_transform);
		surface_tool->set_material(p_mesh->surface_get_material(i));
		transformed = surface_tool->commit(transformed);
	}

	return transformed;
}

} // namespace

Ref<ArrayMesh> bake_csg_mesh(CSGShape3D *p_root, const Transform3D &p_base_transform, float p_texel_size) {
	Transform3D local_transform;
	Ref<ArrayMesh> mesh;
	if (!get_csg_mesh_data(p_root, local_transform, mesh)) {
		return Ref<ArrayMesh>();
	}

	mesh = apply_transform(mesh, local_transform);
	mesh->lightmap_unwrap(p_base_transform, p_texel_size);
	return mesh;
}

} // namespace blockout::api
