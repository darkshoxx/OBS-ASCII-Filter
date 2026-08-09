// OBS-specific syntax adaptation to HLSL standard to avoid errors reported by
// the code editor
#define SamplerState sampler_state
#define Texture2D texture2d

// General Properties
uniform int cells_h = 16;
uniform int cells_v = 9;
uniform float4 white = {1.0, 1.0, 1.0, 1.0};
uniform float4 black = {0.0, 0.0, 0.0, 1.0};

// Sobel Kernels
uniform float3x3 sobel_x = {-1.0, 0.0, 1.0,
                            -2.0, 0.0, 2.0,
                            -1.0, 0.0, 1.0
                            };
uniform float3x3 sobel_y = {-1.0, -2.0, -1.0,
                            0.0, 0.0, 0.0,
                            1.0, 2.0, 1.0
                            };
// Sobel Cutoffs
uniform float tol_x = 0.5;
uniform float tol_y = 0.5;


// Size of the source picture
uniform int width;
uniform int height;

// Uniform variables set by OBS (required)
uniform float4x4 ViewProj;  // View-Projection matrix used in the vertex shader
uniform Texture2D image;    // Texture containing the source picture

uniform Texture2D atlas_tex;
uniform Texture2D atlas_tex_edges;
uniform int num_chars;  // len(chars), e.g. 10
uniform int num_chars_edges;  // len(chars), e.g. 10



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
pixel_data vertex_shader_c(vertex_data vertex)
{
    pixel_data pixel;
    pixel.pos   = mul(float4(vertex.pos.xyz, 1.0), ViewProj); // this is called "vector SWIZZLING" lmao
    pixel.uv    = vertex.uv;
    return pixel;
}

float4 pixel_shader_c(pixel_data pixel) : TARGET
{   // example given in 1 dimension
    // frac(x) = x-floor(x), just the fractional part
    // this scales pixel.uv [0,1] to the grid size [0,16]. Ex, pixel at 0.1 goes to 1.6
    // cell_uv then only takes "how far I am along the cell": 0.6 , so 60%
    float2 cell_uv = frac(pixel.uv * float2(cells_h, cells_v));
    // floor does the opposite and returns the index 1.0. 
    // Adding a half gives the center of the cell: 1.5. 
    // scaling back down to [0,1] by dividing by grid size: 1.5/16 = 0.09375
    float2 cell_center = (floor(pixel.uv * float2(cells_h, cells_v)) + 0.5) / float2(cells_h, cells_v);
    // For each pixel in the cell we only sample the center. That ensures that
    // every part of the cell displays it's position in the same ASCII character.
    float4 src = image.Sample(linear_clamp, cell_center);
    // The 3d vector is a known constant, giving the percieved relative luminance
    // of the colours in RGB space. Note how Green is percieved brighter than the others.
    // luma then becomes the percieved luminance of the cell (center)
    float luma = dot(src.rgb, float3(0.299, 0.587, 0.114));
    // we use the luminance to see how far along the character is we wish to draw
    int char_index = round(luma * (num_chars - 1));
    // We only need the char_index for column-offsets. The row position remains the same.
    float2 atlas_uv = float2((char_index + cell_uv.x) / num_chars, cell_uv.y);
    // finally, we sample from that position on the atlas.
    return atlas_tex.Sample(linear_clamp, atlas_uv);
}

technique Draw
{
    pass DrawAsciiVideo
    {
        vertex_shader = vertex_shader_c(vertex);
        pixel_shader  = pixel_shader_c(pixel);
    }
}