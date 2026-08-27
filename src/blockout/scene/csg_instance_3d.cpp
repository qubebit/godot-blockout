#include "blockout/scene/csg_instance_3d.h"

#include "blockout/api/csg_bake.h"

#include "godot_cpp/classes/engine.hpp"
#include "godot_cpp/classes/rendering_server.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/core/memory.hpp"
#include "godot_cpp/variant/typed_array.hpp"

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
}

void CSGInstance3D::_notification(int p_what) {
	switch (p_what) {
		case NOTIFICATION_ENTER_TREE: {
			// Keep the CSG source tree editor-only; the baked mesh is all a running game needs.
			if (!Engine::get_singleton()->is_editor_hint()) {
				free_csg_children();
			}
			_update_render_visibility();
		} break;
		case NOTIFICATION_CHILD_ORDER_CHANGED:
		case NOTIFICATION_VISIBILITY_CHANGED: {
			_update_render_visibility();
		} break;
		default: {
		} break;
	}
}

CSGShape3D *CSGInstance3D::find_csg_root() const {
	TypedArray<Node> children = get_children();
	for (int i = 0; i < children.size(); i++) {
		CSGShape3D *shape = Object::cast_to<CSGShape3D>(children[i]);
		if (shape != nullptr) {
			return shape;
		}
	}
	return nullptr;
}

void CSGInstance3D::free_csg_children() {
	TypedArray<Node> children = get_children();
	for (int i = 0; i < children.size(); i++) {
		CSGShape3D *shape = Object::cast_to<CSGShape3D>(children[i]);
		if (shape == nullptr) {
			continue;
		}
		remove_child(shape);
		shape->queue_free();
	}
}

void CSGInstance3D::set_lightmap_texel_size(float p_texel_size) { lightmap_texel_size = p_texel_size; }

float CSGInstance3D::get_lightmap_texel_size() const { return lightmap_texel_size; }

void CSGInstance3D::set_csg_source(const Ref<PackedScene> &p_csg_source) { csg_source = p_csg_source; }

Ref<PackedScene> CSGInstance3D::get_csg_source() const { return csg_source; }

void CSGInstance3D::_set_owner_recursive(Node *p_node, Node *p_owner) {
	p_node->set_owner(p_owner);
	for (int i = 0; i < p_node->get_child_count(); i++) {
		_set_owner_recursive(p_node->get_child(i), p_owner);
	}
}

void CSGInstance3D::_update_render_visibility() {
	bool edit_mode = find_csg_root() != nullptr;
	RenderingServer::get_singleton()->instance_set_visible(get_instance(), is_visible_in_tree() && !edit_mode);
}

void CSGInstance3D::set_edit_mode(bool p_enabled) {
	CSGShape3D *root = find_csg_root();

	if (p_enabled) {
		if (root != nullptr || csg_source.is_null()) {
			return; // Already editable, or nothing to restore.
		}
		Node *instance = csg_source->instantiate();
		CSGShape3D *instanced_root = Object::cast_to<CSGShape3D>(instance);
		if (instanced_root == nullptr) {
			if (instance != nullptr) {
				memdelete(instance);
			}
			return;
		}
		add_child(instanced_root);
		_set_owner_recursive(instanced_root, get_owner() != nullptr ? get_owner() : this);
	} else {
		if (root == nullptr) {
			return;
		}
		rebuild_mesh();
		for (int i = 0; i < root->get_child_count(); i++) {
			_set_owner_recursive(root->get_child(i), root);
		}
		Ref<PackedScene> packed;
		packed.instantiate();
		packed->pack(root);
		csg_source = packed;
		remove_child(root);
		root->queue_free();
	}

	_update_render_visibility();
	update_configuration_warnings();
}

bool CSGInstance3D::is_edit_mode() const { return find_csg_root() != nullptr; }

void CSGInstance3D::rebuild_mesh() {
	CSGShape3D *root = find_csg_root();
	if (root == nullptr) {
		return;
	}

	set_mesh(blockout::api::bake_csg_mesh(root, get_global_transform(), lightmap_texel_size));
}

PackedStringArray CSGInstance3D::_get_configuration_warnings() const {
	PackedStringArray warnings = MeshInstance3D::_get_configuration_warnings();

	CSGShape3D *root = find_csg_root();
	if (root == nullptr) {
		if (csg_source.is_null()) {
			warnings.push_back("CSGInstance3D has no CSGShape3D child to bake. Add a CSGBox3D, CSGCombiner3D, "
							   "etc. as a child.");
		} else if (get_mesh().is_null()) {
			warnings.push_back("No baked mesh yet. Enter CSG edit mode and rebuild to generate the mesh.");
		}
		return warnings;
	}

	int32_t csg_child_count = 0;
	TypedArray<Node> children = get_children();
	for (int i = 0; i < children.size(); i++) {
		if (Object::cast_to<CSGShape3D>(children[i]) != nullptr) {
			csg_child_count++;
		}
	}

	warnings.push_back("Exit edit mode before running or exporting the game so the baked "
					   "mesh reflects your latest changes.");

	if (csg_child_count > 1) {
		warnings.push_back("CSGInstance3D only bakes the first CSGShape3D child; additional top-level CSG "
						   "shapes are ignored.");
	}

	return warnings;
}

} // namespace blockout::scene
