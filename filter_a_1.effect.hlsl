// OBS-specific syntax adaptation to HLSL standard to avoid errors reported by
// the code editor
#define SamplerState sampler_state
#define Texture2D texture2d

// Size of the source picture
uniform int width;
uniform int height;

// Uniform variables set by OBS (required)
uniform float4x4 ViewProj;  // Vier-Projection matrix used in the vertex shader
uniform Texture2D image;    // Texture containing the source picture

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
    float4 pos  : POSITION;     // Homogenours screen coordinates XYZW
    float2 uv   : TEXCOORD0;    // UV coordinates in the source picture
};

// Vertex shader used to compute position of rendered pizels and pass UV
pixel_data vertex_shader_a_1(vertex_data vertex)
{
    pixel_data pixel;
    pixel.pos   = mul(float4(vertex.pos.xyz, 1.0), ViewProj);
    pixel.uv    = vertex.uv;
    return pixel;
}

float4 pixel_shader_a_1(pixel_data pixel) : TARGET
{
    float2 position = pixel.uv * float2(width, height);
    float new_x = max(position.x, position.y);
    float new_y = min(position.x, position.y);
    float2 new_pos;
    new_pos.x = new_x;
    new_pos.y = new_y;

    new_pos /= float2(width, height);

    float4 source_sample = image.Sample(linear_clamp, new_pos);
    return source_sample;
}

technique Draw
{
    pass
    {
        vertex_shader = vertex_shader_a_1(vertex);
        pixel_shader  = pixel_shader_a_1(pixel);
    }
}