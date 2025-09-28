#pragma once

#include <nlohmann/json.hpp>

using nlohmann::json;

void load(const json& manifest);
