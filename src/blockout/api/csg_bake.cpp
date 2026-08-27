#include "blockout/api/csg_bake.h"

#include "godot_cpp/classes/material.hpp"
#include "godot_cpp/classes/surface_tool.hpp"
#include "godot_cpp/variant/array.hpp"

namespace blockout::api {

Ref<ArrayMesh> bake_csg_mesh(CSGShape3D *p_root, const Transform3D &p_base_transform, float p_texel_size) {
	if (p_root == nullptr) {
		return Ref<ArrayMesh>();
	}

	Array meshes = p_root->get_meshes();
	if (meshes.size() < 2) {
		return Ref<ArrayMesh>();
	}

	Transform3D local_transform = meshes[0];
	Ref<ArrayMesh> mesh = meshes[1];
	if (!mesh.is_valid()) {
		return Ref<ArrayMesh>();
	}

	if (!local_transform.is_equal_approx(Transform3D())) {
		Ref<SurfaceTool> surface_tool;
		surface_tool.instantiate();
		Ref<ArrayMesh> transformed;
		transformed.instantiate();
		for (int32_t i = 0; i < mesh->get_surface_count(); i++) {
			surface_tool->clear();
			surface_tool->append_from(mesh, i, local_transform);
			surface_tool->set_material(mesh->surface_get_material(i));
			transformed = surface_tool->commit(transformed);
		}
		mesh = transformed;
	}

	mesh->lightmap_unwrap(p_base_transform, p_texel_size);
	return mesh;
}

} // namespace blockout::api
