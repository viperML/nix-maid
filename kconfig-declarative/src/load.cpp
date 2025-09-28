#include "load.hpp"

#include <KConfigGroup>
#include <KSharedConfig>
#include <map>
#include <optional>
#include <print>
#include <string>
#include <vector>

using nlohmann::json;
using std::optional;
using std::println;
using std::string;
using std::vector;

namespace ns {
struct manifest {
    std::map<std::string, json::object_t> files;
};
void from_json(const json& j, manifest& m) { j.at("files").get_to(m.files); }
}  // namespace ns

bool processJson(
    KSharedConfig::Ptr kconfig,
    optional<vector<string>> stack,
    const json::object_t& obj
) {
    bool tainted = false;

    for (auto [key, _value] : obj) {
        if (_value.is_object()) {
            // Recurse
            auto newStack = stack.value_or(vector<string>{});
            newStack.push_back(key);
            processJson(kconfig, newStack, _value);
        } else {
            KConfigGroup group(kconfig, "");
            if (stack) {
                for (const auto& groupName : stack.value()) {
                    group =
                        KConfigGroup(&group, QString::fromStdString(groupName));
                    print("{}/", groupName);
                }
            }

            println("{} -> {}", key, _value.dump());

            auto qKey = QString::fromStdString(key);

            if (_value.is_string()) {
                auto value = _value.get<string>();
                QString qValue = QString::fromStdString(value);

                QString prevValue = group.readEntry(qKey, QString());

                group.writeEntry(qKey, qValue);

                if (prevValue == qValue) {
                    tainted = true;
                }
            } else if (_value.is_boolean()) {
                auto value = _value.get<bool>();

                bool prevValue = group.readEntry(qKey, false);

                group.writeEntry(qKey, value);

                if (prevValue == value) {
                    tainted = true;
                }
            } else if (_value.is_number_integer()) {
                auto value = _value.get<int>();

                int prevValue = group.readEntry(qKey, 0);

                group.writeEntry(qKey, value);

                if (prevValue == value) {
                    tainted = true;
                }
            } else {
                println("Unknown type!");
            }
        }
    }

    return tainted;
}

void load(const json& manifest) {
    auto m = manifest.get<ns::manifest>();

    for (auto& [filename, fileConfig] : m.files) {
        println("[{}]", filename);

        KSharedConfig::Ptr kconfig =
            KSharedConfig::openConfig(QString::fromStdString(filename));

        bool tainted = processJson(kconfig, std::nullopt, fileConfig);

        kconfig->sync();
        println("  Tainted: {}", tainted);
        println();
        if (tainted) {
            if (filename == "kwinrc") {
                println("    Triggering kwin restart");
                println("qdbus org.kde.KWin /KWin org.kde.KWin.restart");
            }
        }
    }
}
