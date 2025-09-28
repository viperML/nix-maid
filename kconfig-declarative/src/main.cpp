#include <CLI/CLI.hpp>
#include <QCoreApplication>
#include <print>

#include "load.hpp"

using nlohmann::json;
using std::println;
using std::filesystem::path;

int applyCommand(std::string manifestPath) {
    std::println("Manifest: {}", manifestPath);

    path p(manifestPath);

    // Check if exists
    if (!std::filesystem::exists(p)) {
        println("Manifest {} doesn't exit.", p.string());
        return EXIT_FAILURE;
    }

    std::ifstream ifs(manifestPath);

    json j = json::parse(ifs);

    load(j);

    return EXIT_SUCCESS;
}

int watchCommand() {
    std::println("Watch command not yet implemented.");
    return EXIT_SUCCESS;
}

int main(int argc, char** argv) {
    CLI::App app{"App description"};
    argv = app.ensure_utf8(argv);

    auto watch_app = app.add_subcommand("watch", "Watch for changes");
    auto apply_app = app.add_subcommand("apply", "Apply a manifest");
    app.require_subcommand();

    watch_app->callback([]() { watchCommand(); });

    std::string manifestPath;
    apply_app->add_option("manifest", manifestPath)->required();

    apply_app->callback([&manifestPath]() { applyCommand(manifestPath); });

    CLI11_PARSE(app, argc, argv);
}
