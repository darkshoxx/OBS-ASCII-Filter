#include <obs-module.h>

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE("obs-ascii-filter", "en-US")

// Function Declarations

static const char *ascii_filter_get_name(void *unused);
static void *ascii_filter_create(obs_data_t *settings, obs_source_t *source);
static void ascii_filter_destroy(void *data);
static void ascii_filter_render(void *data, gs_effect_t *effect);



// OBS Filter Definition

struct obs_source_info ascii_filter = {
    .id = "ascii_filter",
    .type = OBS_SOURCE_TYPE_FILTER,
    .output_flags = OBS_SOURCE_VIDEO,
    .get_name = ascii_filter_get_name,
    .create = ascii_filter_create,
    .destroy = ascii_filter_destroy,
    .video_render = ascii_filter_render,
};

const char *obs_module_description(void)
{
    return "A test plugin that does nothing (yet).";
}

// OBS Filter Entrypoints

bool obs_module_load(void)
{
    blog(LOG_INFO, "[ASCII FILTER] Test plugin successfully loaded!");
    obs_register_source(&ascii_filter);
    blog(LOG_INFO, "[ASCII FILTER] Test plugin successfully registered!");
    return true;
}

void obs_module_unload(void)
{
    blog(LOG_INFO, "[ASCII FILTER] Unloaded!");
}

// Filter Functions

static const char *ascii_filter_get_name(void *unused)
{
    UNUSED_PARAMETER(unused);
    return "ASCII Filter (Dummy)";
}

static void *ascii_filter_create(obs_data_t *settings, obs_source_t *source)
{
    UNUSED_PARAMETER(settings);
    UNUSED_PARAMETER(source);
    return (void *)1;
}

static void ascii_filter_destroy(void *data)
{
    UNUSED_PARAMETER(data);
}

static void ascii_filter_render(void *data, gs_effect_t *effect)
{
    UNUSED_PARAMETER(data);
    UNUSED_PARAMETER(effect);
}

const char *obs_module_name(void)
{
    return "ASCII Filter Minimal";
}