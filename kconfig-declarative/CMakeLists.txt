cmake_minimum_required(VERSION 3.16)

project(kconfig-declarative LANGUAGES CXX)

include(GNUInstallDirs)

set(main kconfig-declarative)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core)

qt_standard_project_setup()

qt_add_executable(${main}
    src/main.cpp
    src/load.cpp
)

target_link_libraries(${main} PRIVATE Qt6::Core)

find_package(KF6Config REQUIRED)
target_link_libraries(${main} PRIVATE KF6::ConfigCore)

find_package(nlohmann_json REQUIRED)
target_link_libraries(${main} PRIVATE nlohmann_json::nlohmann_json)

find_package(CLI11 CONFIG REQUIRED)
target_link_libraries(${main} PRIVATE CLI11::CLI11)

target_compile_options(${main} PRIVATE -Werror -Wpedantic)

target_include_directories(${main} PRIVATE src)

if(CMAKE_BUILD_TYPE MATCHES "Debug")
  target_compile_options(
    ${main}
    PRIVATE -O0 -fsanitize=undefined -fsanitize=address -fno-omit-frame-pointer
  )
  target_link_options(${main}
    PRIVATE -fsanitize=undefined -fsanitize=address
  )
endif()

install(TARGETS ${main}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
