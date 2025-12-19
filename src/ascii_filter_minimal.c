#include <obs-module.h>

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

    return props;
}

static void ascii_filter_update(void *data, obs_data_t *settings)
{
    struct ascii_filter_data *filter = data;
    filter->invert = obs_data_get_bool(settings, "invert");
    filter->ascii = obs_data_get_bool(settings, "ascii");
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
        if (ascii){
            bool checkerboard = false;
            // simple checkerboard pattern
            if (checkerboard) {
                for (uint32_t y = 0; y < height_yuy2; y++) {
                    uint8_t *row = buffer_yuy2 + y * stride_yuy2;
                    for (uint32_t x = 0; x < width_yuy2*2; x += 2) { // YUY2 2 bytes per pixel
                        bool block = ((x / (width_yuy2/8)) % 2) ^ ((y / (height_yuy2/8)) % 2);
                        row[x]   = block ? 0 : 255; // Y
                        row[x+2] = block ? 0 : 255; // Y next pixel
                    }
                }
            } else {
            // ASCII output size
            const size_t ascii_width = 64;
            const size_t ascii_height = 48;
            // Temp RGB buffer for ASCII conversion
            size_t channels = 3;
            double *rgb_data = calloc(ascii_width * ascii_height * channels, sizeof(double));
            if (!rgb_data){
                blog(LOG_ERROR, "[ASCII FILTER] Failed to allocate RGB buffer");
                break;
            }


                // Downsample YUY2 to ASCII grid
            for (size_t j = 0; j < ascii_height; j++) {
                size_t y_start = (j * height_yuy2) / ascii_height;
                size_t y_end   = ((j + 1) * height_yuy2) / ascii_height;

                for (size_t i = 0; i < ascii_width; i++) {
                    size_t x_start = (i * width_yuy2) / ascii_width;
                    size_t x_end   = ((i + 1) * width_yuy2) / ascii_width;

                    double avg_r = 0.0, avg_g = 0.0, avg_b = 0.0;
                    size_t count = 0;

                    for (size_t y = y_start; y < y_end; y++) {
                        uint8_t *row = buffer_yuy2 + y * stride_yuy2;

                        for (size_t x = x_start; x < x_end; x += 2) {
                            uint8_t Y0 = row[x];       // pixel 0 luma
                            uint8_t U  = row[x+1];     // chroma U
                            uint8_t Y1 = row[x+2];     // pixel 1 luma
                            uint8_t V  = row[x+3];     // chroma V

                            // Convert first pixel
                            double r0 = Y0 + 1.402 * (V - 128);
                            double g0 = Y0 - 0.344136 * (U - 128) - 0.714136 * (V - 128);
                            double b0 = Y0 + 1.772 * (U - 128);

                            // Clamp
                            if (r0 < 0) r0 = 0; if (r0 > 255) r0 = 255;
                            if (g0 < 0) g0 = 0; if (g0 > 255) g0 = 255;
                            if (b0 < 0) b0 = 0; if (b0 > 255) b0 = 255;

                            avg_r += r0; avg_g += g0; avg_b += b0; count++;

                            // Convert second pixel
                            double r1 = Y1 + 1.402 * (V - 128);
                            double g1 = Y1 - 0.344136 * (U - 128) - 0.714136 * (V - 128);
                            double b1 = Y1 + 1.772 * (U - 128);

                            if (r1 < 0) r1 = 0; if (r1 > 255) r1 = 255;
                            if (g1 < 0) g1 = 0; if (g1 > 255) g1 = 255;
                            if (b1 < 0) b1 = 0; if (b1 > 255) b1 = 255;

                            avg_r += r1; avg_g += g1; avg_b += b1; count++;
                        }
                    }

                    // Average color in block
                    avg_r /= count;
                    avg_g /= count;
                    avg_b /= count;

                    // Map to ASCII character (simple grayscale)
                    double gray = (0.2126*avg_r + 0.7152*avg_g + 0.0722*avg_b) / 255.0;
                    const char *VALUE_CHARS = " .-=+*x#$&X@";
                    size_t N_VALUES = strlen(VALUE_CHARS);
                    char ascii_char = VALUE_CHARS[(size_t)(gray * (N_VALUES-1))];

                    // Write ASCII as RGB block in output buffer
                    size_t idx = (i + j*ascii_width) * channels;
                    rgb_data[idx+0] = avg_r / 255.0;
                    rgb_data[idx+1] = avg_g / 255.0;
                    rgb_data[idx+2] = avg_b / 255.0;
                }
            }

            // TODO: Map rgb_data back into frame->data or a new OBS frame
            // For now we just free
            free(rgb_data);
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