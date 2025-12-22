cmake_minimum_required(VERSION 3.16)
project(Weather LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Qt modules
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Widgets
    Quick
    QuickControls2
    QuickLayouts
    Network
)

# LayerShellQt
find_package(LayerShellQt REQUIRED)

# Sources
add_executable(Weather
    main.cpp
    resources.qrc
)

# Link libraries
target_link_libraries(Weather
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Widgets
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::QuickLayouts
        Qt6::Network
        # LayerShellQt::Interface
)

# Output binary in build root
set_target_properties(Weather PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)

# Ensure that compile_commands.json is copied to the root directory
if(EXISTS "${CMAKE_BINARY_DIR}/compile_commands.json")
    add_custom_command(
        TARGET Weather POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_BINARY_DIR}/compile_commands.json"
        "${CMAKE_SOURCE_DIR}/compile_commands.json"
    )
endif()
