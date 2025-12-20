#include <obs-module.h>
#include "glyphs.h"
#include "font_loader.h"

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE("obs-ascii-filter", "en-US")

// Function Declarations

static const char *ascii_filter_get_name(void *unused);
static void *ascii_filter_create(obs_data_t *settings, obs_source_t *source);
static void ascii_filter_destroy(void *data);
static void ascii_filter_render(void *data, gs_effect_t *effect); // only for GPU based shaders
static struct obs_source_frame *ascii_filter_video(void *data, struct obs_source_frame *frame); // for CPU based filters
static obs_properties_t *ascii_filter_properties(void *data);
static void ascii_filter_update(void *data, obs_data_t *settings);

// OBS Filter Definition

struct obs_source_info ascii_filter = {
    .id = "ascii_filter",
    .type = OBS_SOURCE_TYPE_FILTER,
    .output_flags = OBS_SOURCE_VIDEO,
    
    .get_name = ascii_filter_get_name,
    .create = ascii_filter_create,
    .destroy = ascii_filter_destroy,

    .get_properties = ascii_filter_properties,
    .update = ascii_filter_update,
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
    obs_source_t *source;
    bool invert;
    bool ascii;
    int ascii_width;
    int ascii_height;
};

static void *ascii_filter_create(obs_data_t *settings, obs_source_t *source)
{
    struct ascii_filter_data *filter = bzalloc(sizeof(struct ascii_filter_data));
    filter->source = source;
    filter->invert = obs_data_get_bool(settings, "invert");
    return filter;
}

static void ascii_filter_destroy(void *data)
{
    struct ascii_filter_data *filter = data;
    bfree(data);
};


static obs_properties_t *ascii_filter_properties(void *data)
{
    obs_properties_t *props = obs_properties_create();

    obs_properties_add_bool(
        props,
        "invert",
        "Invert colours"
    );

    obs_properties_add_bool(
        props,
        "ascii",
        "ASCII Filter"
    );

    obs_properties_add_int_slider(props, "ascii_width", "ASCII Width", 16, 256, 1);
    obs_properties_add_int_slider(props, "ascii_height", "ASCII Height", 16, 128, 1);

    return props;
}

static void ascii_filter_update(void *data, obs_data_t *settings)
{
    struct ascii_filter_data *filter = data;
    filter->invert = obs_data_get_bool(settings, "invert");
    filter->ascii = obs_data_get_bool(settings, "ascii");
    filter->ascii_width  = (size_t)obs_data_get_int(settings, "ascii_width");
    filter->ascii_height = (size_t)obs_data_get_int(settings, "ascii_height");
}

/**
 * Filter callback for raw video frames.
 *
 * This function is called for sources that provide raw video frames to OBS,
 * such as webcams or some media inputs. It allows CPU-side manipulation of
 * the frame data before it is sent to the GPU for rendering.
 *
 * @note Only sources that provide raw frames will trigger this callback.
 *       GPU-rendered sources (e.g., scenes, images, or games) may bypass
 *       this function entirely and instead invoke the .video_render callback.
 *
 * @param data  Pointer to the filter-specific data structure (ascii_filter_data)
 *              returned by ascii_filter_create.
 * @param frame Pointer to the obs_source_frame containing the current frame's
 *              pixel data, dimensions, format, and other metadata.
 * @return      Pointer to the obs_source_frame to use for further processing.
 *              Returning the original frame is valid for in-place filtering.
 */
static struct obs_source_frame *ascii_filter_video(void *data, struct obs_source_frame *frame)
{
    struct ascii_filter_data *filter = (struct ascii_filter_data *)data;
    bool invert = filter->invert;
    bool ascii = filter->ascii;
    const size_t ascii_width  = filter->ascii_width;
    const size_t ascii_height = filter->ascii_height;
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
        if (invert){
        uint8_t *buffer_nv12 = frame->data[0];
        uint32_t width_nv12 = frame->width;
        uint32_t height_nv12 = frame->height;
        uint32_t stride_nv12 = frame->linesize[0];

            for (uint32_t y = 0; y < height_nv12; y++){
                uint8_t *row = buffer_nv12 + y * stride_nv12;
                for (uint32_t x = 0; x < width_nv12; x += 1){
                    // invert luma
                row[x] = 255 - row[x];
              }
            }
        }
        break;

    case VIDEO_FORMAT_I420:
        blog(LOG_INFO, "[ASCII FILTER] I420 (YUV420p) Source!");
        break;

    case VIDEO_FORMAT_YUY2:
        blog(LOG_INFO, "[ASCII FILTER] YUY2 Source!");
        // notescam

        uint8_t *buffer_yuy2 = frame->data[0];
        uint32_t width_yuy2 = frame->width;
        uint32_t height_yuy2 = frame->height;
        uint32_t stride_yuy2 = frame->linesize[0];
        if (ascii) {
            // ASCII character set
            const char *VALUE_CHARS = " .-=+*x#$&X@";
            const size_t N_VALUES = strlen(VALUE_CHARS);

            const int ascii_width = 64;   // could later be made configurable via OBS slider
            const int ascii_height = 48;
            const int scale_x = frame->width / ascii_width;
            const int scale_y = frame->height / ascii_height;
            const int glyph_scale = 8; // how many video pixels per glyph pixel

            uint8_t *buffer = frame->data[0];
            uint32_t stride = frame->linesize[0];
            uint32_t width  = frame->width;
            uint32_t height = frame->height;

            for (int j = 0; j < ascii_height; j++) {
                for (int i = 0; i < ascii_width; i++) {

                    // Compute average Y in this ASCII cell
                    double avg_y = 0.0;
                    int count = 0;

                    for (int y = j*scale_y; y < (j+1)*scale_y && y < height; y++) {
                        uint8_t *row = buffer + y * stride;
                        for (int x = i*scale_x; x < (i+1)*scale_x && x < width; x++) {
                            avg_y += row[x*2]; // YUY2: Y at even byte indices
                            count++;
                        }
                    }

                    if (count > 0) avg_y /= count;

                    // Map to ASCII index
                    size_t idx = (size_t)(avg_y / 255.0 * (N_VALUES - 1));
                    char ascii_char = VALUE_CHARS[idx];

                    // Load glyph for character (from FreeType or hardcoded glyphs)
                    const glyph_t *g = get_glyph(ascii_char);
                    if (!g) continue;

                    // Render glyph into frame
                    for (int gy = 0; gy < GLYPH_H; gy++) {
                        for (int gx = 0; gx < GLYPH_W; gx++) {

                            uint8_t row_byte = g->rows[gy];
                            bool on = (row_byte & (1 << (7 - gx))) != 0;

                            uint8_t Y = on ? 235 : 16; // standard YUV luma levels

                            for (int sy = 0; sy < glyph_scale; sy++) {
                                int y = j*scale_y + gy*glyph_scale + sy;
                                if (y >= height) continue;

                                uint8_t *row = buffer + y * stride;

                                for (int sx = 0; sx < glyph_scale; sx++) {
                                    int x = i*scale_x + gx*glyph_scale + sx;
                                    if (x >= width) continue;

                                    row[x*2] = Y;
                                }
                            }
                        }
                    }
                }
            }
        }


        if (invert){
            
            for (uint32_t y = 0; y < height_yuy2; y++){
                uint8_t *row = buffer_yuy2 + y * stride_yuy2;

                // YUY2 = 2 bytes per pixel
                for (uint32_t x = 0; x < width_yuy2 * 2; x += 2){
                    // invert luma only
                    row[x] = 255 - row[x];
                }
            }
        }
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