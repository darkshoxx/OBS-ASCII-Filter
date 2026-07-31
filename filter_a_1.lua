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
source_info.it = ''