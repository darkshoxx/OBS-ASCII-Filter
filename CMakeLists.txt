cmake_minimum_required(VERSION 3.20)
project(obs_ascii_filter_project LANGUAGES C CXX)

# Standalone test executable
add_executable(test-ascii
    src/test_main.cpp
    src/ascii_filter.cpp
    ascii-view/src/image.c
    ascii-view/src/print_image.c
)

target_include_directories(test-ascii PRIVATE
    ascii-view/include
)
target_compile_definitions(test-ascii PRIVATE M_PI=3.14159265358979323846)
