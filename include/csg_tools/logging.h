#pragma once

#include <initializer_list>
#include <utility>

#include <godot_cpp/variant/utility_functions.hpp>

namespace csg_tools::logging {

struct Field {
	godot::String key;
	godot::String value;

	template <typename T> Field(const char *p_key, T &&p_value) : key(p_key) {
		godot::Variant value_variant(std::forward<T>(p_value));
		value = static_cast<godot::String>(value_variant);
	}
};

template <typename T> Field field(const char *p_key, T &&p_value) { return Field(p_key, std::forward<T>(p_value)); }

template <typename... Fields> void debug(bool p_enabled, const char *p_message, Fields &&...p_fields) {
	if (!p_enabled) {
		return;
	}
	godot::String line("[CSGTools] ");
	line += p_message;
	const std::initializer_list<Field> fields{ std::forward<Fields>(p_fields)... };
	for (const Field &field : fields) {
		line += " ";
		line += field.key;
		line += "=";
		line += field.value;
	}
	godot::UtilityFunctions::print(line);
}

} // namespace csg_tools::logging
