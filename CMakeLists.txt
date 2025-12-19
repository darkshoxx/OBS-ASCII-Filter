cmake_minimum_required(VERSION 3.20)
project(obs_ascii_filter_project LANGUAGES C CXX)

# =============== test exe ===============
add_executable(test-ascii
    src/test_main.cpp
    src/ascii_filter.cpp
    ascii-view/src/image.c
    ascii-view/src/print_image.c
)
if (MSVC)
    set_source_files_properties(
        ascii-view/src/image.c
        PROPERTIES COMPILE_FLAGS "/wd4068"
    )
endif()

target_include_directories(test-ascii PRIVATE
    ascii-view/include
)
target_compile_definitions(test-ascii PRIVATE M_PI=3.14159265358979323846)

# =============== plugin module ===============
add_library(obs-ascii-filter MODULE
    # src/ascii_filter.cpp
    src/ascii_filter_minimal.c
    # ascii-view/src/image.c
    # ascii-view/src/print_image.c
)

# set(OBS_INCLUDE_DIR "C:/Code/GithubRepos/OBS-ASCII-Filter/obs-sources/obs/libobs")

target_include_directories(obs-ascii-filter PRIVATE
    ascii-view/include
    ${OBS_INCLUDE_DIR}                  # libobs headers
    "C:/Code/GithubRepos/obs-studio/build_x64/config"  # where obsconfig.h was generated
)

if (DEFINED LIBOBS_LIBRARY)
    target_link_libraries(obs-ascii-filter PRIVATE ${LIBOBS_LIBRARY})
endif()

set_target_properties(obs-ascii-filter PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/plugin_out"
)

target_compile_definitions(obs-ascii-filter PRIVATE M_PI=3.14159265358979323846)

add_custom_command(TARGET obs-ascii-filter POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
    $<TARGET_FILE:obs-ascii-filter>
    "C:/Program Files/obs-studio/obs-plugins/64bit/"
)