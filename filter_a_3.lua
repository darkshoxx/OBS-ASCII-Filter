obs = obslua

-- Returns description in the Scripts window
function script_description()
    return [[<center><h2>Example Filter Phase A-2</h2></center>
    <p>This is step 3 of Phase A of making an ASCII shader filter 
    for OBS.</p>]]
end

-- Called on script startup
function script_load(settings)
    obs.obs_register_source(source_info)
end

-- global varaibale definitions of source info
source_info = {}
source_info.id = 'Filter-Phase-A3'
source_info.type = obs.OBS_SOURCE_TYPE_FILTER   -- INPUT or FILTER or TRANSITION
source_info.output_flags = obs.OBS_SOURCE_VIDEO -- Can be VIDEO/AUDIO/ASYNC/etc
source_info.get_name = function()
    return "Phase-A3"
end

-- Creates the implementation data for the source
source_info.create = function(settings, source)

    -- Initializes the custom data table
    local data = {}
    data.source = source -- Keeps a reference to this filter as a source object
    data.width = 1       -- Dummy value during initialization phase
    data.height = 1       -- Dummy value during initialization phase
    data.error_message = nil

    -- Compiles the effect
    obs.obs_enter_graphics()
    local effect_file_path = script_path() .. 'filter_a_3.effect.hlsl'
    data.effect = obs.gs_effect_create_from_file(effect_file_path, nil)
    obs.obs_leave_graphics()

    
    if data.effect == nil then
        data.error_message = "Effect failed to compile — check OBS log for details."
        obs.blog(obs.LOG_ERROR, "Effect compliation failed for " .. " (" .. effect_file_path .. ")")
        -- source_info.destroy(data)
        -- return nil
    else
        -- Retrieves the shader uniform variables
        data.params = {}
        data.params.width = obs.gs_effect_get_param_by_name(data.effect, "width")
        data.params.height = obs.gs_effect_get_param_by_name(data.effect, "height")
        data.params.cells_h = obs.gs_effect_get_param_by_name(data.effect, "cells_h")
        data.params.cells_v = obs.gs_effect_get_param_by_name(data.effect, "cells_v")
    end
    -- Calls update to initialize the rest of the properties-managed settings
    source_info.update(data, settings)
    return data
end


-- Destroys and releases resources linked to the custom data
-- source_info.destroy = function(data)
--     if data.effect ~= nil then
--         obs.obs_enter_graphics()
--         obs.gs_effect_destroy(data.effect)
--         data.effect = nil
--         obs.obs_leave_graphics()
--     end
-- end

-- Returns the width of the source
source_info.get_width = function(data)
    return data.width
end

-- Returns the height of the source
source_info.get_height = function(data)
    return data.height
end

-- Called when rendering the source with the graphics subsystem
source_info.video_render = function(data)
    local parent = obs.obs_filter_get_parent(data.source)
    data.width = obs.obs_source_get_base_width(parent)
    data.height = obs.obs_source_get_base_height(parent)

    obs.obs_source_process_filter_begin(data.source, obs.GS_RGBA, obs.OBS_NO_DIRECT_RENDERING)


    -- Effect parameters initialization goes here
    obs.gs_effect_set_int(data.params.width, data.width)
    obs.gs_effect_set_int(data.params.height, data.height)
    obs.gs_effect_set_int(data.params.cells_h, data.cells_h)
    obs.gs_effect_set_int(data.params.cells_v, data.cells_v)

    if not obs.obs_source_process_filter_end(data.source, data.effect, data.width, data.height) then
        return
    end
end

source_info.get_defaults = function(settings)
    obs.obs_data_set_default_int(settings, "cells_h", 16)
    obs.obs_data_set_default_int(settings, "cells_v", 9)
end

source_info.get_properties = function(data)
    local props = obs.obs_properties_create()
    obs.obs_properties_add_int_slider(props, "cells_h", "Number of cells per row", 1, 160, 1)
    obs.obs_properties_add_int_slider(props, "cells_v", "Number of cells per column", 1, 90, 1)
    return props
end


-- Updates the internal data for the source upon settings change
source_info.update = function(data, settings)
    data.cells_h = obs.obs_data_get_int(settings, "cells_h")
    data.cells_v = obs.obs_data_get_int(settings, "cells_v")
end