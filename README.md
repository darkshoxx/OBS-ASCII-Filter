# OBS-ASCII-Filter
An attempt at turning gouwsxander's ascii-view image-to-ascii-art program into a plugin filter for OBS.
Find the original repo here:
https://github.com/gouwsxander/ascii-view
and the accompanying video:
https://www.youtube.com/watch?v=t8aSqlC_Duo

## Ignore the below, that was the old plan, the new plan is HLSL + LUA
## How to actually make a (CPU-based) filter plugin (as opposed to a shader running on GPU):
1. Define the filter in a cpp file
2. Define a bridge to C
3. Build OBS from scratch according to the build instructions on their github
4. Build the library files by running `cmake --build build_x64 --config Release --target libobs`
    This will create obs.lib and obs.dll for some reason in /build_x64/libobs/Release/
5. Link those library files in the build of your filter as follows:
`cmake -S . -B build -DOBS_INCLUDE_DIR=Path/To/obs-studio/libobs^;Path/To/obs-studio/build_x64/config -DLIBOBS_LIBRARY=Path/To/obs-studio/build_x64/libobs/Release/obs.lib"`
assuming you cloned to `Path/To/obs-studio` and compiled to `Path/To/obs-studio/build_x64`
6. Building with  `cmake --build build --target obs-ascii-filter`, then copying the `obs_ascii-filter.dll` from `/build/Debug` to your `obs-plugins/64bit/` folder.
