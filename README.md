# OBS-ASCII-Filter
An attempt at turning gouwsxander's ascii-view image-to-ascii-art program into a plugin filter for OBS.
Find the original repo here:
https://github.com/gouwsxander/ascii-view
and the accompanying video:
https://www.youtube.com/watch?v=t8aSqlC_Duo


Originally intended as a C/C++ Project, now shifted to lua and HLSL.

## How to use
Download the `atlas` folder as well as both `filter_e.lua` and `filter_e.effect.hlsl` and have them in the same folder. Doesn't have to be the `obs-studio\data\obs-plugins\frontend-tools\scripts`
folder but can make things easier.

Open OBS, go to Tools, Scripts, click "+", and navigate to the `filter_e.lua` script.
Have a Video source in a scene, and set parameters as required.

A lot of these depend on the lighting and camera settings so I'm giving a little more flexibility with parameters to play around.
