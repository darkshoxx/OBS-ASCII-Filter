#include <obs-module.h>

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE("obs-ascii-filter", "en-US")

// Function Declarations

static const char *ascii_filter_get_name(void *unused);
static void *ascii_filter_create(obs_data_t *settings, obs_source_t *source);
static void ascii_filter_destroy(void *data);
static void ascii_filter_render(void *data, gs_effect_t *effect); // only for GPU based shaders
static struct obs_source_frame *ascii_filter_video(void *data, struct obs_source_frame *frame); // for CPU based filters



// OBS Filter Definition

struct obs_source_info ascii_filter = {
    .id = "ascii_filter",
    .type = OBS_SOURCE_TYPE_FILTER,
    .output_flags = OBS_SOURCE_VIDEO,
    .get_name = ascii_filter_get_name,
    .create = ascii_filter_create,
    .destroy = ascii_filter_destroy,
    // .video_render = ascii_filter_render,
    .filter_video = ascii_filter_video,
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

struct ascii_filter_data {
    char meta_data[11];
    uint8_t my_number;
    bool is_fine;
};

static void *ascii_filter_create(obs_data_t *settings, obs_source_t *source)
{
    UNUSED_PARAMETER(settings);
    UNUSED_PARAMETER(source);
    struct ascii_filter_data *mydata = malloc(sizeof(struct ascii_filter_data));
    mydata ->my_number = 3;
    for(int i=0; i<11; i++){
        mydata ->meta_data[i] = "FilterFace"[i];
    }
    // Apparently you're supposed to do memcpy(mydata->meta_data, "FilterFace", 10)
    // but that would be too efficient and I'm a python dev and like shooting myself
    // in the foot when it doesn't matter. 
    mydata -> is_fine = true;
    return mydata;
}

static void ascii_filter_destroy(void *data)
{
    free(data);
};



static struct obs_source_frame *ascii_filter_video(void *data, struct obs_source_frame *frame)
{
    
    UNUSED_PARAMETER(data);
switch (frame->format) {
    case VIDEO_FORMAT_RGBA:
        blog(LOG_INFO, "[ASCII FILTER] RGBA Source!");
        break;

    case VIDEO_FORMAT_BGRA:
        blog(LOG_INFO, "[ASCII FILTER] BGRA Source!");
        break;

    case VIDEO_FORMAT_NV12:
        blog(LOG_INFO, "[ASCII FILTER] NV12 Source!");
        // my facecam
        break;

    case VIDEO_FORMAT_I420:
        blog(LOG_INFO, "[ASCII FILTER] I420 (YUV420p) Source!");
        break;

    case VIDEO_FORMAT_YUY2:
        blog(LOG_INFO, "[ASCII FILTER] YUY2 Source!");
        // notescam
        break;

    default:
    blog(LOG_INFO, "[ASCII FILTER] OTHER Source! format=%d", frame->format); 
}
    return frame;
}

/**
 * Render callback for the ASCII filter.
 *
 * This is the GPU version of the ascii_filter_video callback.
 * We will later implement the GPU version here because the CPU version only works
 * for sources that generate raw video data, like cameras. If the filter is to
 * be applied to game captures, window captures, images etc. it needs this
 *
 * @param data   Pointer to the filter-specific data structure (ascii_filter_data)
 *               returned by ascii_filter_create.
 * @param effect Currently active effect/shader (can be unused if not applying GPU shaders).
 */
static void ascii_filter_render(void *data, gs_effect_t *effect)
{
    UNUSED_PARAMETER(data);
    UNUSED_PARAMETER(effect);
}

const char *obs_module_name(void)
{
    return "ASCII Filter Minimal";
}



// Definition of obs_source_frame
// struct obs_source_frame {
//         uint8_t             *data[MAX_AV_PLANES];
//         uint32_t            linesize[MAX_AV_PLANES];
//         uint32_t            width;
//         uint32_t            height;
//         uint64_t            timestamp;

//         enum video_format   format;
//         float               color_matrix[16];
//         bool                full_range;
//         uint16_t            max_luminance;
//         float               color_range_min[3];
//         float               color_range_max[3];
//         bool                flip;
//         uint8_t             flags;
//         uint8_t             trc; /* enum video_trc */
// };