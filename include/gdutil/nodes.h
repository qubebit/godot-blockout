#pragma once

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/object.hpp>

namespace gdutil::nodes {

template <typename T> T *find_child(const godot::Node *p_parent, bool p_include_internal = false) {
	if (p_parent == nullptr) {
		return nullptr;
	}

	const godot::TypedArray<godot::Node> children = p_parent->get_children(p_include_internal);
	for (int32_t i = 0; i < children.size(); i++) {
		if (T *child = godot::Object::cast_to<T>(children[i])) {
			return child;
		}
	}

	return nullptr;
}

template <typename T, typename Function>
void for_each_child(const godot::Node *p_parent, Function &&p_function, bool p_include_internal = false) {
	if (p_parent == nullptr) {
		return;
	}

	const godot::TypedArray<godot::Node> children = p_parent->get_children(p_include_internal);
	for (int32_t i = 0; i < children.size(); i++) {
		if (T *child = godot::Object::cast_to<T>(children[i])) {
			p_function(child);
		}
	}
}

template <typename T> int32_t count_children(const godot::Node *p_parent, bool p_include_internal = false) {
	int32_t count = 0;
	for_each_child<T>(p_parent, [&count](T *) { count++; }, p_include_internal);
	return count;
}

} // namespace gdutil::nodes
