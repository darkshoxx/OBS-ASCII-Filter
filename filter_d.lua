obs = obslua

-- Returns description in the Scripts window
function script_description()
    return [[<center><h2>Example Filter Phase D</h2></center>
    <p>This is Phase D of making an ASCII shader filter 
    for OBS, including edge detection.</p>]]
end

-- Called on script startup
function script_load(settings)
    obs.obs_register_source(source_info)
end

-- global varaibale definitions of source info
source_info = {}
source_info.id = 'Filter-Phase-D'
source_info.type = obs.OBS_SOURCE_TYPE_FILTER   -- INPUT or FILTER or TRANSITION
source_info.output_flags = obs.OBS_SOURCE_VIDEO -- Can be VIDEO/AUDIO/ASYNC/etc
source_info.get_name = function()
    return "Phase-D"
end

-- Creates the implementation data for the source
source_info.create = function(settings, source)

    -- Initializes the custom data table
    local data = {}
    data.source = source -- Keeps a reference to this filter as a source object
    data.width = 1       -- Dummy value during initialization phase
    data.height = 1       -- Dummy value during initialization phase
    data.error_message = nil
    
    -- luminance atlas
    data.atlas = obs.gs_image_file()
    obs.gs_image_file_init(data.atlas, script_path() .. "atlas/ascii_atlas_c_8_16.png")
    obs.blog(obs.LOG_INFO, "Atlas loaded: " .. tostring(data.atlas.loaded) .. 
    " size: " .. data.atlas.cx .. "x" .. data.atlas.cy)

    -- edges atlas
    data.atlas_edges = obs.gs_image_file()
    obs.gs_image_file_init(data.atlas_edges, script_path() .. "atlas/ascii_atlas_e_8_16.png")
    obs.blog(obs.LOG_INFO, "Atlas loaded: " .. tostring(data.atlas_edges.loaded) .. 
    " size: " .. data.atlas_edges.cx .. "x" .. data.atlas_edges.cy)


    -- OBS runs all GPU-bound operations on a single rendering thread.
    -- enter_graphics and leave_graphics handles a mutex to that thread blocking 
    -- it, as the lua script runs on a separate thread.
    -- It locks the graphics render thread so you can splice in new data, 
    -- such as the ASCII atlas.
    obs.obs_enter_graphics()
    local effect_file_path = script_path() .. 'filter_d.effect.hlsl'
    obs.gs_image_file_init_texture(data.atlas)
    obs.gs_image_file_init_texture(data.atlas_edges)
    data.effect = obs.gs_effect_create_from_file(effect_file_path, nil)
    obs.obs_leave_graphics()

    
    if data.effect == nil then
        data.error_message = "Effect failed to compile — check OBS log for details."
        obs.blog(obs.LOG_ERROR, "Effect compilation failed for " .. " (" .. effect_file_path .. ")")
        -- source_info.destroy(data)
        -- return nil
    else
        -- Retrieves the shader uniform variables
        data.params = {}
        data.params.width = obs.gs_effect_get_param_by_name(data.effect, "width")
        data.params.height = obs.gs_effect_get_param_by_name(data.effect, "height")
        data.params.cells_h = obs.gs_effect_get_param_by_name(data.effect, "cells_h")
        data.params.cells_v = obs.gs_effect_get_param_by_name(data.effect, "cells_v")
        data.params.num_colours = obs.gs_effect_get_param_by_name(data.effect, "num_colours")
        data.params.tol_x = obs.gs_effect_get_param_by_name(data.effect, "tol_x")
        data.params.tol_y = obs.gs_effect_get_param_by_name(data.effect, "tol_y")
        data.params.tol_sat = obs.gs_effect_get_param_by_name(data.effect, "tol_sat")
        data.params.num_chars = obs.gs_effect_get_param_by_name(data.effect, "num_chars")
        data.params.num_chars_edges = obs.gs_effect_get_param_by_name(data.effect, "num_chars_edges")
        data.params.atlas_tex = obs.gs_effect_get_param_by_name(data.effect, "atlas_tex")
        data.params.atlas_tex_edges = obs.gs_effect_get_param_by_name(data.effect, "atlas_tex_edges")
        data.num_chars = 10
        data.num_chars_edges = 4
    end
    -- Calls update to initialize the rest of the properties-managed settings
    source_info.update(data, settings)
    return data
end


-- Destroys and releases resources linked to the custom data
-- source_info.destroy = function(data)
--     obs.obs_enter_graphics()
--     if data.effect ~= nil then
--         obs.gs_effect_destroy(data.effect)
--         data.effect = nil
--     end
--     if data.atlas ~= nil then
--         obs.gs_image_file_free(data.atlas)
--     end
--     if data.atlas_edges ~= nil then
--         obs.gs_image_file_free(data.atlas_edges)
--     end
--     obs.obs_leave_graphics()
-- end

-- Returns the width of the source
source_info.get_width = function(data)
    return data.width
end

-- Returns the height of the source
source_info.get_height = function(data)
    return data.height
end

-- Called when rendering the source with the graphics subsystem. it runs once 
-- every frame, so usually 60 times per second.
source_info.video_render = function(data)
    if data.effect == nil then
        obs.obs_source_skip_video_filter(data.source)
        return
    end
    -- we need the width and height from the source the filter is attached to.
    local parent = obs.obs_filter_get_parent(data.source)
    data.width = obs.obs_source_get_base_width(parent)
    data.height = obs.obs_source_get_base_height(parent)

    obs.obs_source_process_filter_begin(data.source, obs.GS_RGBA, obs.OBS_NO_DIRECT_RENDERING)


    -- Effect parameters initialization goes here
    obs.gs_effect_set_int(data.params.width, data.width)
    obs.gs_effect_set_int(data.params.height, data.height)
    obs.gs_effect_set_int(data.params.cells_h, data.cells_h)
    obs.gs_effect_set_int(data.params.cells_v, data.cells_v)
    obs.gs_effect_set_int(data.params.num_colours, data.num_colours)
    obs.gs_effect_set_float(data.params.tol_x, data.tol_x)
    obs.gs_effect_set_float(data.params.tol_y, data.tol_y)
    obs.gs_effect_set_float(data.params.tol_sat, data.tol_sat)
    obs.gs_effect_set_int(data.params.num_chars, data.num_chars)
    obs.gs_effect_set_int(data.params.num_chars_edges, data.num_chars_edges)
    obs.gs_effect_set_texture(data.params.atlas_tex, data.atlas.texture)
    obs.gs_effect_set_texture(data.params.atlas_tex_edges, data.atlas_edges.texture)


    if not obs.obs_source_process_filter_end(data.source, data.effect, data.width, data.height) then
        return
    end
end

source_info.get_defaults = function(settings)
    obs.obs_data_set_default_int(settings, "cells_h", 16)
    obs.obs_data_set_default_int(settings, "cells_v", 9)
    obs.obs_data_set_default_int(settings, "num_colours", 4)
    obs.obs_data_set_default_double(settings, "tol_x", 0.5)
    obs.obs_data_set_default_double(settings, "tol_y", 0.5)
    obs.obs_data_set_default_double(settings, "tol_sat", 0.1)
end

source_info.get_properties = function(data)
    local props = obs.obs_properties_create()
    obs.obs_properties_add_int_slider(props, "cells_h", "Number of cells per row", 1, 160, 1)
    obs.obs_properties_add_int_slider(props, "cells_v", "Number of cells per column", 1, 90, 1)
    obs.obs_properties_add_int_slider(props, "num_colours", "Number of colours to sample", 1, 20, 1)
    obs.obs_properties_add_float_slider(props, "tol_x", "Edge Tolerance X", 0.0, 2.0, 0.01)
    obs.obs_properties_add_float_slider(props, "tol_y", "Edge Tolerance Y", 0.0, 2.0, 0.01)
    obs.obs_properties_add_float_slider(props, "tol_sat", "Saturation Tolerance", 0.0, 1.0, 0.05)
    return props
end


-- Updates the internal data for the source upon settings change
source_info.update = function(data, settings)
    data.cells_h = obs.obs_data_get_int(settings, "cells_h")
    data.cells_v = obs.obs_data_get_int(settings, "cells_v")
    data.num_colours = obs.obs_data_get_int(settings, "num_colours")
    data.tol_x = obs.obs_data_get_double(settings, "tol_x")
    data.tol_y = obs.obs_data_get_double(settings, "tol_y")
    data.tol_sat = obs.obs_data_get_double(settings, "tol_sat")
end