#pragma once

namespace gdutil::signals {

struct Object {
	inline static constexpr const char *CHANGED = "changed";
};

struct SceneTreeTimer {
	inline static constexpr const char *TIMEOUT = "timeout";
};

} // namespace gdutil::signals