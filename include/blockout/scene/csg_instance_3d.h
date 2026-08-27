#pragma once

#include "godot_cpp/classes/csg_shape3d.hpp"
#include "godot_cpp/classes/mesh_instance3d.hpp"
#include "godot_cpp/classes/packed_scene.hpp"
#include "godot_cpp/variant/packed_string_array.hpp"

using namespace godot;

namespace blockout::scene {

class CSGInstance3D : public MeshInstance3D {
	GDCLASS(CSGInstance3D, MeshInstance3D)

	float lightmap_texel_size = 0.2f;
	Ref<PackedScene> csg_source;

	CSGShape3D *find_csg_root() const;
	void free_csg_children();
	static void _set_owner_recursive(Node *p_node, Node *p_owner);

	void _update_render_visibility();

	void set_csg_source(const Ref<PackedScene> &p_csg_source);
	Ref<PackedScene> get_csg_source() const;

protected:
	static void _bind_methods();
	void _notification(int p_what);

public:
	void set_lightmap_texel_size(float p_texel_size);
	float get_lightmap_texel_size() const;

	void set_edit_mode(bool p_enabled);
	bool is_edit_mode() const;

	void rebuild_mesh();

	PackedStringArray _get_configuration_warnings() const override;
};

} // namespace blockout::scene
