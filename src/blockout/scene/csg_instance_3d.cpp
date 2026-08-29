#include "blockout/scene/csg_instance_3d.h"

#include "blockout/api/csg_bake.h"
#include "blockout/api/csg_collision.h"
#include "gdutil/nodes.h"

#include "godot_cpp/classes/engine.hpp"
#include "godot_cpp/classes/rendering_server.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/core/memory.hpp"
#include "godot_cpp/core/object.hpp"

namespace blockout::scene {

void CSGInstance3D::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_lightmap_texel_size", "texel_size"), &CSGInstance3D::set_lightmap_texel_size);
	ClassDB::bind_method(D_METHOD("get_lightmap_texel_size"), &CSGInstance3D::get_lightmap_texel_size);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "lightmap_texel_size"), "set_lightmap_texel_size",
				 "get_lightmap_texel_size");

	ClassDB::bind_method(D_METHOD("set_csg_source", "csg_source"), &CSGInstance3D::set_csg_source);
	ClassDB::bind_method(D_METHOD("get_csg_source"), &CSGInstance3D::get_csg_source);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "csg_source", PROPERTY_HINT_RESOURCE_TYPE, "PackedScene",
							  PROPERTY_USAGE_NO_EDITOR | PROPERTY_USAGE_STORAGE),
				 "set_csg_source", "get_csg_source");

	ClassDB::bind_method(D_METHOD("set_edit_mode", "enabled"), &CSGInstance3D::set_edit_mode);
	ClassDB::bind_method(D_METHOD("is_edit_mode"), &CSGInstance3D::is_edit_mode);

	ClassDB::bind_method(D_METHOD("rebuild_mesh"), &CSGInstance3D::rebuild_mesh);

	ClassDB::bind_method(D_METHOD("set_generate_collision", "enabled"), &CSGInstance3D::set_generate_collision);
	ClassDB::bind_method(D_METHOD("is_generating_collision"), &CSGInstance3D::is_generating_collision);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "generate_collision"), "set_generate_collision",
				 "is_generating_collision");

	ClassDB::bind_method(D_METHOD("set_collision_shape", "shape"), &CSGInstance3D::set_collision_shape);
	ClassDB::bind_method(D_METHOD("get_collision_shape"), &CSGInstance3D::get_collision_shape);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "collision_shape", PROPERTY_HINT_RESOURCE_TYPE, "ConcavePolygonShape3D",
							  PROPERTY_USAGE_NO_EDITOR | PROPERTY_USAGE_STORAGE),
				 "set_collision_shape", "get_collision_shape");

	ClassDB::bind_method(D_METHOD("set_collision_layer", "layer"), &CSGInstance3D::set_collision_layer);
	ClassDB::bind_method(D_METHOD("get_collision_layer"), &CSGInstance3D::get_collision_layer);
	ADD_GROUP("Collision", "collision_");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "collision_layer", PROPERTY_HINT_LAYERS_3D_PHYSICS), "set_collision_layer",
				 "get_collision_layer");

	ClassDB::bind_method(D_METHOD("set_collision_mask", "mask"), &CSGInstance3D::set_collision_mask);
	ClassDB::bind_method(D_METHOD("get_collision_mask"), &CSGInstance3D::get_collision_mask);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "collision_mask", PROPERTY_HINT_LAYERS_3D_PHYSICS), "set_collision_mask",
				 "get_collision_mask");
}

void CSGInstance3D::_validate_property(PropertyInfo &p_property) const {
	if (generate_collision) {
		return;
	}

	if (p_property.name == StringName("collision_layer") || p_property.name == StringName("collision_mask")) {
		p_property.usage = PROPERTY_USAGE_NO_EDITOR;
	}
}

void CSGInstance3D::_enter_tree() {
	if (!Engine::get_singleton()->is_editor_hint()) {
		free_csg_children();
		update_collision();
	}

	update_render_visibility();
}

void CSGInstance3D::_notification(int p_what) {
	switch (p_what) {
		case NOTIFICATION_CHILD_ORDER_CHANGED: {
			discard_stale_cached_root();
			update_render_visibility();
		} break;
		case NOTIFICATION_VISIBILITY_CHANGED: {
			update_render_visibility();
		} break;
		case NOTIFICATION_PREDELETE: {
			free_cached_csg_root();
		} break;
		default: {
		} break;
	}
}

CSGShape3D *CSGInstance3D::find_csg_root() const { return gdutil::nodes::find_child<CSGShape3D>(this); }

CSGShape3D *CSGInstance3D::get_cached_csg_root() const {
	return Object::cast_to<CSGShape3D>(ObjectDB::get_instance(cached_csg_root_id));
}

void CSGInstance3D::free_cached_csg_root() {
	CSGShape3D *root = get_cached_csg_root();
	if (root != nullptr && root->get_parent() == nullptr) {
		memdelete(root);
	}

	cached_csg_root_id = ObjectID();
}

void CSGInstance3D::free_csg_children() {
	gdutil::nodes::for_each_child<CSGShape3D>(this, [this](CSGShape3D *shape) {
		remove_child(shape);
		shape->queue_free();
	});
}

void CSGInstance3D::discard_stale_cached_root() {
	if (!cached_csg_root_id.is_valid()) {
		return;
	}

	CSGShape3D *root = get_cached_csg_root();
	if (root != nullptr && root->get_parent() == this) {
		return;
	}

	cached_csg_root_id = ObjectID();
	csg_source.unref();
	set_mesh(Ref<Mesh>());
	collision_shape.unref();
}

CSGShape3D *CSGInstance3D::instantiate_cached_csg_root() {
	if (csg_source.is_null()) {
		return nullptr;
	}

	if (CSGShape3D *root = get_cached_csg_root()) {
		return root;
	}

	cached_csg_root_id = ObjectID();

	Node *instance = csg_source->instantiate();
	CSGShape3D *root = Object::cast_to<CSGShape3D>(instance);
	if (root != nullptr) {
		cached_csg_root_id = root->get_instance_id();
		return root;
	}

	if (instance != nullptr) {
		memdelete(instance);
	}

	return nullptr;
}

bool CSGInstance3D::enter_edit_mode(CSGShape3D *p_root) {
	if (p_root != nullptr) {
		return false;
	}

	CSGShape3D *root = instantiate_cached_csg_root();
	if (root == nullptr) {
		return false;
	}

	add_child(root);
	set_owner_recursive(root, get_owner() != nullptr ? get_owner() : this);
	return true;
}

bool CSGInstance3D::exit_edit_mode(CSGShape3D *p_root) {
	if (p_root == nullptr) {
		return false;
	}

	rebuild_mesh();
	for (int i = 0; i < p_root->get_child_count(); i++) {
		set_owner_recursive(p_root->get_child(i), p_root);
	}

	Ref<PackedScene> packed;
	packed.instantiate();
	packed->pack(p_root);
	ObjectID root_id(p_root->get_instance_id());
	if (cached_csg_root_id != root_id) {
		free_cached_csg_root();
	}

	cached_csg_root_id = ObjectID();
	remove_child(p_root);
	cached_csg_root_id = root_id;
	csg_source = packed;
	return true;
}

void CSGInstance3D::set_lightmap_texel_size(float p_texel_size) { lightmap_texel_size = p_texel_size; }

float CSGInstance3D::get_lightmap_texel_size() const { return lightmap_texel_size; }

void CSGInstance3D::set_csg_source(const Ref<PackedScene> &p_csg_source) { csg_source = p_csg_source; }

Ref<PackedScene> CSGInstance3D::get_csg_source() const { return csg_source; }

void CSGInstance3D::set_collision_shape(const Ref<ConcavePolygonShape3D> &p_shape) { collision_shape = p_shape; }

Ref<ConcavePolygonShape3D> CSGInstance3D::get_collision_shape() const { return collision_shape; }

void CSGInstance3D::set_owner_recursive(Node *p_node, Node *p_owner) {
	p_node->set_owner(p_owner);
	for (int i = 0; i < p_node->get_child_count(); i++) {
		set_owner_recursive(p_node->get_child(i), p_owner);
	}
}

void CSGInstance3D::update_render_visibility() {
	bool edit_mode = find_csg_root() != nullptr;
	RenderingServer::get_singleton()->instance_set_visible(get_instance(), is_visible_in_tree() && !edit_mode);
}

StaticBody3D *CSGInstance3D::find_collision_body() const {
	return gdutil::nodes::find_child<StaticBody3D>(this, /*p_include_internal=*/true);
}

void CSGInstance3D::remove_collision_body() {
	StaticBody3D *body = find_collision_body();
	if (body == nullptr) {
		return;
	}

	remove_child(body);
	body->queue_free();
}

StaticBody3D *CSGInstance3D::ensure_collision_body() {
	if (StaticBody3D *body = find_collision_body()) {
		return body;
	}

	StaticBody3D *body = memnew(StaticBody3D);
	body->set_name("GeneratedCollision");
	add_child(body, false, INTERNAL_MODE_BACK);
	return body;
}

CollisionShape3D *CSGInstance3D::ensure_collision_shape(StaticBody3D *p_body) {
	if (CollisionShape3D *shape = gdutil::nodes::find_child<CollisionShape3D>(p_body)) {
		return shape;
	}

	CollisionShape3D *shape = memnew(CollisionShape3D);
	p_body->add_child(shape);
	return shape;
}

void CSGInstance3D::update_collision() {
	if (Engine::get_singleton()->is_editor_hint()) {
		return;
	}

	if (!generate_collision || collision_shape.is_null()) {
		remove_collision_body();
		return;
	}

	StaticBody3D *body = ensure_collision_body();
	CollisionShape3D *shape_node = ensure_collision_shape(body);

	body->set_collision_layer(collision_layer);
	body->set_collision_mask(collision_mask);
	shape_node->set_shape(collision_shape);
}

void CSGInstance3D::rebuild_collision_shape() {
	collision_shape =
		generate_collision ? blockout::api::build_trimesh_collision_shape(get_mesh()) : Ref<ConcavePolygonShape3D>();
}

void CSGInstance3D::append_baked_warnings(PackedStringArray &p_warnings) const {
	if (csg_source.is_null()) {
		p_warnings.push_back("CSGInstance3D has no CSGShape3D child to bake. Add a CSGBox3D, CSGCombiner3D, "
							 "etc. as a child.");
		return;
	}

	if (get_mesh().is_null()) {
		p_warnings.push_back("No baked mesh yet. Enter CSG edit mode and rebuild to generate the mesh.");
	}
}

void CSGInstance3D::append_edit_mode_warnings(PackedStringArray &p_warnings) const {
	p_warnings.push_back("Exit edit mode before running or exporting the game so the baked "
						 "mesh reflects your latest changes.");

	if (gdutil::nodes::count_children<CSGShape3D>(this) <= 1) {
		return;
	}

	p_warnings.push_back("CSGInstance3D only bakes the first CSGShape3D child; additional top-level CSG "
						 "shapes are ignored.");
}

void CSGInstance3D::set_edit_mode(bool p_enabled) {
	CSGShape3D *root = find_csg_root();
	bool changed = p_enabled ? enter_edit_mode(root) : exit_edit_mode(root);
	if (!changed) {
		return;
	}

	update_render_visibility();
	update_configuration_warnings();
}

bool CSGInstance3D::is_edit_mode() const { return find_csg_root() != nullptr; }

void CSGInstance3D::rebuild_mesh() {
	CSGShape3D *root = find_csg_root();
	if (root == nullptr) {
		return;
	}

	set_mesh(blockout::api::bake_csg_mesh(root, get_global_transform(), lightmap_texel_size));
	rebuild_collision_shape();
}

void CSGInstance3D::set_generate_collision(bool p_enabled) {
	generate_collision = p_enabled;
	rebuild_collision_shape();
	update_collision();
	notify_property_list_changed();
}

bool CSGInstance3D::is_generating_collision() const { return generate_collision; }

void CSGInstance3D::set_collision_layer(uint32_t p_layer) {
	collision_layer = p_layer;
	if (StaticBody3D *body = find_collision_body()) {
		body->set_collision_layer(p_layer);
	}
}

uint32_t CSGInstance3D::get_collision_layer() const { return collision_layer; }

void CSGInstance3D::set_collision_mask(uint32_t p_mask) {
	collision_mask = p_mask;
	if (StaticBody3D *body = find_collision_body()) {
		body->set_collision_mask(p_mask);
	}
}

uint32_t CSGInstance3D::get_collision_mask() const { return collision_mask; }

PackedStringArray CSGInstance3D::_get_configuration_warnings() const {
	PackedStringArray warnings = MeshInstance3D::_get_configuration_warnings();

	if (find_csg_root() == nullptr) {
		append_baked_warnings(warnings);
		return warnings;
	}

	append_edit_mode_warnings(warnings);
	return warnings;
}

} // namespace blockout::scene
