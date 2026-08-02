obs = obslua

-- Returns description in the Scripts window
function script_description()
    return [[<center><h2>Example Filter Phase A-1</h2></center>
    <p>This is step 1 of Phase A of making an ASCII shader filter 
    for OBS.</p>]]
end

-- Called on script startup
function script_load(settings)
    obs.obs_register_source(source_info)
end

-- global varaibale definitions of source info
source_info = {}
source_info.id = 'Filter-Phase-A1'
source_info.type = obs.OBS_SOURCE_TYPE_FILTER   -- INPUT or FILTER or TRANSITION
source_info.output_flags = obs.OBS_SOURCE_VIDEO -- Can be VIDEO/AUDIO/ASYNC/etc
source_info.get_name = function()
    return "Phase-A1"
end

-- Creates the implementation data for the source
source_info.create = function(settings, source)

    -- Initializes the custom data table
    local data = {}
    data.source = source -- Keeps a reference to this filter as a source object
    data.width = 1       -- Dummy value during initialization phase
    data.height = 1       -- Dummy value during initialization phase

    -- Compiles the effect
    obs.obs_enter_graphics()
    local effect_file_path = script_path() .. 'filter_a_1.effect.hlsl'
    data.effect = obs.gs_effect_create_from_file(effect_file_path, nil)
    obs.obs_leave_graphics()

    -- Calls the destroy function if the effect was not compiled properly
    if data.effect == nil then
        obs.blog(obs.LOG_ERROR, "Effect compliation failed for" .. effect_file_path)
        source_info.destroy(data)
        return nil
    end

    -- Retrieves the shader uniform variables
    data.params = {}
    data.params.width = obs.gs_effect_get_param_by_name(data.effect, "width")
    data.params.height = obs.gs_effect_get_param_by_name(data.effect, "height")

    -- Calls update to initialize the rest of the properties-managed settings
    source_info.update(data, settings)
    return data
end


-- Destroys and releases resources linked to the custom data
source_info.destroy = function(data)
    if data.effect ~= nil then
        obs.obs_enter_graphics()
        obs.gs_effect_destroy(data.effect)
        data.effect = nil
        obs.obs_leave_graphics()
    end
end

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

    if not obs.obs_source_process_filter_end(data.source, data.effect, data.width, data.height) then
        return
    end
end

-- Updates the internal data for the source upon settings change
source_info.update = function(data, settings)
    -- data.gamma = obs.obs_data_get_double(settings, "gamma")
    -- data.gamma_shift = obs.obs_data_get_double(settings, "gamma_shift")
    -- data.scale = obs.obs_data_get_double(settings, "scale")
    -- data.amplitude = obs.obs_data_get_double(settings, "amplitude")
    -- data.number_of_color_levels = obs.obs_data_get_int(settings, "number_of_color_levels")
end