#pragma once

#include <utility>

#include "gdutil/logging.h"

namespace blockout::logging {

using gdutil::logging::field;

template <typename... Fields> void debug(bool p_enabled, const char *p_message, Fields &&...p_fields) {
	gdutil::logging::debug(p_enabled, "Blockout", p_message, std::forward<Fields>(p_fields)...);
}

} // namespace blockout::logging
