#include "blockout/api/csg_collision.h"

namespace blockout::api {

Ref<ConcavePolygonShape3D> build_trimesh_collision_shape(const Ref<Mesh> &p_mesh) {
	Ref<ConcavePolygonShape3D> shape;
	shape.instantiate();

	if (p_mesh.is_valid()) {
		shape->set_faces(p_mesh->get_faces());
	}

	return shape;
}

} // namespace blockout::api
