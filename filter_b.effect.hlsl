// OBS-specific syntax adaptation to HLSL standard to avoid errors reported by
// the code editor
#define SamplerState sampler_state
#define Texture2D texture2d

// General Properties
uniform int cells_h = 16;
uniform int cells_v = 9;
uniform float4 white = {1.0, 1.0, 1.0, 1.0};
uniform float4 black = {0.0, 0.0, 0.0, 1.0};


// Size of the source picture
uniform int width;
uniform int height;

// Uniform variables set by OBS (required)
uniform float4x4 ViewProj;  // Vier-Projection matrix used in the vertex shader
uniform Texture2D image;    // Texture containing the source picture

uniform Texture2D atlas_tex;
uniform int num_chars;  // len(chars), e.g. 10



// Interpolation method and wrap mode for sampling a texture
SamplerState linear_clamp
{
    Filter  = Linear;       // Anisotropy / Point / Linear
    AddressU    = Clamp;    // Wrap / Clamp / Mirror / Border / MirrorOnce
    AddressV    = Clamp;    // Wrap / Clamp / Mirror / Border / MirrorOnce
    BorderColor = 00000000; // Used only with border edges (optional)
};

// Data type of the input of the vertex shader
struct vertex_data
{
    float4 pos  : POSITION;     // Homogenous space coordinates XYZW
    float2 uv   : TEXCOORD0;    // UV coordinates in the source picture
};

// Data type of the output returned by the vertex shader, and used as
// input for the pixel shader after interpolation for each pixel
struct pixel_data
{
    float4 pos  : POSITION;     // Homogenous screen coordinates XYZW
    float2 uv   : TEXCOORD0;    // UV coordinates in the source picture
};

// Vertex shader used to compute position of rendered pizels and pass UV
pixel_data vertex_shader_b(vertex_data vertex)
{
    pixel_data pixel;
    pixel.pos   = mul(float4(vertex.pos.xyz, 1.0), ViewProj);
    pixel.uv    = vertex.uv;
    return pixel;
}

float4 pixel_shader_b(pixel_data pixel) : TARGET
{
    float2 cell_uv = frac(pixel.uv * float2(cells_h, cells_v));
    float2 cell_center = (floor(pixel.uv * float2(cells_h, cells_v)) + 0.5) / float2(cells_h, cells_v);

    float4 src = image.Sample(linear_clamp, cell_center);
    float luma = dot(src.rgb, float3(0.299, 0.587, 0.114));

    int char_index = round(luma * (num_chars - 1));
    float2 atlas_uv = float2((char_index + cell_uv.x) / num_chars, cell_uv.y);

    return atlas_tex.Sample(linear_clamp, atlas_uv);
}

technique Draw
{
    pass
    {
        vertex_shader = vertex_shader_b(vertex);
        pixel_shader  = pixel_shader_b(pixel);
    }
}