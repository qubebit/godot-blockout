#pragma once

#include "godot_cpp/classes/collision_shape3d.hpp"
#include "godot_cpp/classes/concave_polygon_shape3d.hpp"
#include "godot_cpp/classes/csg_shape3d.hpp"
#include "godot_cpp/classes/mesh_instance3d.hpp"
#include "godot_cpp/classes/packed_scene.hpp"
#include "godot_cpp/classes/static_body3d.hpp"
#include "godot_cpp/core/object_id.hpp"
#include "godot_cpp/variant/packed_string_array.hpp"

using namespace godot;

namespace blockout::scene {

class CSGInstance3D : public MeshInstance3D {
	GDCLASS(CSGInstance3D, MeshInstance3D)

	Ref<PackedScene> csg_source;
	float lightmap_texel_size = 0.2f;
	bool edit_mode = false;
	ObjectID cached_csg_root_id;

	bool generate_collision = false;
	uint32_t collision_layer = 1;
	uint32_t collision_mask = 1;
	Ref<ConcavePolygonShape3D> collision_shape;

	CSGShape3D *find_csg_root() const;
	bool has_current_csg_root() const;
	CSGShape3D *get_cached_csg_root() const;
	void update_edit_mode();
	void free_csg_children();
	bool enter_edit_mode(CSGShape3D *p_root);
	bool exit_edit_mode(CSGShape3D *p_root);
	CSGShape3D *instantiate_cached_csg_root();
	void free_cached_csg_root();
	void reset_csg_state();
	static void set_owner_recursive(Node *p_node, Node *p_owner);

	void update_render_visibility();
	void rebuild_collision_shape();
	void update_collision();
	StaticBody3D *find_collision_body() const;
	void remove_collision_body();
	StaticBody3D *ensure_collision_body();
	CollisionShape3D *ensure_collision_shape(StaticBody3D *p_body);
	void append_baked_warnings(PackedStringArray &p_warnings) const;
	void append_edit_mode_warnings(PackedStringArray &p_warnings) const;

	void set_csg_source(const Ref<PackedScene> &p_csg_source);
	Ref<PackedScene> get_csg_source() const;

	void set_collision_shape(const Ref<ConcavePolygonShape3D> &p_shape);
	Ref<ConcavePolygonShape3D> get_collision_shape() const;

protected:
	static void _bind_methods();
	void _notification(int p_what);
	void _validate_property(PropertyInfo &p_property) const;

public:
	void _enter_tree() override;

	void set_lightmap_texel_size(float p_texel_size);
	float get_lightmap_texel_size() const;

	void set_generate_collision(bool p_enabled);
	bool is_generating_collision() const;

	void set_collision_layer(uint32_t p_layer);
	uint32_t get_collision_layer() const;

	void set_collision_mask(uint32_t p_mask);
	uint32_t get_collision_mask() const;

	void set_edit_mode(bool p_enabled);
	bool is_edit_mode() const;

	void rebuild_mesh();

	PackedStringArray _get_configuration_warnings() const override;
};

} // namespace blockout::scene
