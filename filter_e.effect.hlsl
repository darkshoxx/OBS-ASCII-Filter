// OBS-specific syntax adaptation to HLSL standard to avoid errors reported by
// the code editor
#define SamplerState sampler_state
#define Texture2D texture2d

// General Properties
uniform int cells_h = 16;
uniform int cells_v = 9;
uniform int num_colours = 4;
uniform float4 white = {1.0, 1.0, 1.0, 1.0};
uniform float4 black = {0.0, 0.0, 0.0, 1.0};


// Sobel Cutoffs
uniform float tol_x = 0.5;
uniform float tol_y = 0.5;

// HSV render properties
uniform float tol_sat = 0.1;
uniform bool dyn_sat = true;
uniform bool dyn_val = true;
uniform float mip_bias = 0.75;

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
pixel_data vertex_shader_e(vertex_data vertex)
{
    pixel_data pixel;
    pixel.pos   = mul(float4(vertex.pos.xyz, 1.0), ViewProj); // this is called "vector SWIZZLING" lmao
    pixel.uv    = vertex.uv;
    return pixel;
}

int sobel_test(float sobel_angle)
{
   if ((22.5 <= sobel_angle && sobel_angle <= 67.5) || (-157.5 <= sobel_angle && sobel_angle <= -112.5))
        return 3;
    else if ((67.5 <= sobel_angle && sobel_angle <= 112.5) || (-112.5 <= sobel_angle && sobel_angle <= -67.5))
        return 0;
    else if ((112.5 <= sobel_angle && sobel_angle <= 157.5) || (-67.5 <= sobel_angle && sobel_angle <= -22.5))
        return 1;
    else
        return 2; 
}

float3 hsv_to_rgb(float3 hsv_pack){
    // All three are between 0 and 1
    float chroma = hsv_pack.y * hsv_pack.z;
    float h_six = hsv_pack.x * 6;
    float intermediate = chroma*(1-abs(fmod(h_six, 2)-1));
    float3 rgb_1 = {0,0,0};
    if (0 < h_six && h_six <= 1){
        rgb_1.x = chroma;
        rgb_1.y = intermediate;
    }
    if (1 < h_six && h_six <= 2){
        rgb_1.x = intermediate;
        rgb_1.y = chroma;
    }
    if (2 < h_six && h_six <= 3){
        rgb_1.y = chroma;
        rgb_1.z = intermediate;
    }
    if (3 < h_six && h_six <= 4){
        rgb_1.y = intermediate;
        rgb_1.z = chroma;
    }
    if (4 < h_six && h_six <= 5){
        rgb_1.x = intermediate;
        rgb_1.z = chroma;
    }
    if (5 < h_six && h_six <= 6){
        rgb_1.x = chroma;
        rgb_1.z = intermediate;
    }
    float match = hsv_pack.z - chroma;
    return float3(rgb_1.x + match, rgb_1.y + match,rgb_1.z + match);
}

float3 rgb_to_hsv(float3 rgb_pack){
    float v = max(rgb_pack.r, max(rgb_pack.g, rgb_pack.b));
    float x_min = min(rgb_pack.r, min(rgb_pack.g, rgb_pack.b));
    float chroma = v - x_min;
    float h = 0.0;
    float sat = 0.0;
    // float light = v - (chroma / 2);
    if (chroma==0) { // is this the usual floats can't be equal to each other bug?
        h = 0;
    }
    else if (v==rgb_pack.x){
        float helper = fmod((rgb_pack.y - rgb_pack.z) / chroma, 6);
        if (helper < 0){
            h = (helper + 6) / 6;
        } else {
            h = helper / 6 ;
        }
    }
    else if (v==rgb_pack.y){
        h = (((rgb_pack.z - rgb_pack.x) / chroma) + 2) / 6;
    }
    else if (v==rgb_pack.z){
        h = (((rgb_pack.x - rgb_pack.y) / chroma) + 4) / 6;
    }
    if (v==0){
        sat = 0.0;
    } else {
        sat = chroma / v;
    }
    return float3(h, sat, v);
}

float4 quantize_hue(float3 rgb, int n){
    if (n==1){
        return white;
    }
    float3 hsv = rgb_to_hsv(rgb);
    if (!dyn_val){
    hsv.z = 1.0;
    }
    if (hsv.y < tol_sat){
        if (!dyn_sat){
        hsv.y = 1.0;
        }
        hsv.x = 1.0;
        return float4(hsv_to_rgb(hsv), 1.0);
    }
    if (!dyn_sat){
    hsv.y = 1.0;
    }
    int index = floor(hsv.x*n);
    hsv.x = (index + 0.5)/n;
    return float4(hsv_to_rgb(hsv), 1.0);

}


float4 pixel_shader_e(pixel_data pixel) : TARGET
{
    // Sobel Kernels
    const float3x3 sobel_x = {-1.0, 0.0, 1.0,
                                -2.0, 0.0, 2.0,
                                -1.0, 0.0, 1.0
                                };
    const float3x3 sobel_y = {-1.0, -2.0, -1.0,
                                0.0, 0.0, 0.0,
                                1.0, 2.0, 1.0
                                };
    
       // example given in 1 dimension
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
    float mip_level = log2(max((float)width / cells_h, (float)height / cells_v)) + mip_bias;
    float2 step = float2(1.0 / cells_h, 1.0 / cells_v);
    float4 src = image.Sample(linear_clamp, cell_center);
    src += image.Sample(linear_clamp, cell_center + float2(-step.x, -step.y));
    src += image.Sample(linear_clamp, cell_center + float2(0.0,     -step.y));
    src += image.Sample(linear_clamp, cell_center + float2(step.x,  -step.y));
    src += image.Sample(linear_clamp, cell_center + float2(-step.x, 0.0));
    src += image.Sample(linear_clamp, cell_center + float2(step.x,  0.0));
    src += image.Sample(linear_clamp, cell_center + float2(-step.x, step.y));
    src += image.Sample(linear_clamp, cell_center + float2(0.0,     step.y));
    src += image.Sample(linear_clamp, cell_center + float2(step.x,  step.y));
    src /= 9.0;

    // next gotta sample the neighbourhood of the center. for simplicity, just
    // a 3x3 neigbourhood for a single sobel pass. 
    // 2 options:
    // 1: Sample by cell, using cell-to-cell offsets:


    float3 luma_2 = float3(0.299, 0.587, 0.114);

    // Row 0 - Top: y - step.y
    float m00 = dot(image.SampleLevel(linear_clamp, cell_center + float2(-step.x, -step.y), mip_level).rgb, luma_2);
    float m01 = dot(image.SampleLevel(linear_clamp, cell_center + float2(0.0, -step.y), mip_level).rgb, luma_2);
    float m02 = dot(image.SampleLevel(linear_clamp, cell_center + float2(step.x, -step.y), mip_level).rgb, luma_2);
    
    // Row 1 - Middle: y 
    float m10 = dot(image.SampleLevel(linear_clamp, cell_center + float2(-step.x, 0.0), mip_level).rgb, luma_2);
    float m11 = dot(image.SampleLevel(linear_clamp, cell_center, mip_level).rgb, luma_2);
    float m12 = dot(image.SampleLevel(linear_clamp, cell_center + float2(step.x, 0.0), mip_level).rgb, luma_2);

    // Row 2 - Bottom: y + step.y

    float m20 = dot(image.SampleLevel(linear_clamp, cell_center + float2(-step.x, step.y), mip_level).rgb, luma_2);
    float m21 = dot(image.SampleLevel(linear_clamp, cell_center + float2(0.0, step.y), mip_level).rgb, luma_2);
    float m22 = dot(image.SampleLevel(linear_clamp, cell_center + float2(step.x, step.y), mip_level).rgb, luma_2);

    // 2: Pixel neighbours
    if (1>0){ //quickest way to comment out
        float2 step = float2(1.0 / (float)width, 1.0 / (float)height);

        float3 luma_2 = float3(0.299, 0.587, 0.114);

        // Row 0 - Top: y - step.y
        float m00 = dot(image.Sample(linear_clamp, cell_center + float2(-step.x, -step.y)).rgb, luma_2);
        float m01 = dot(image.Sample(linear_clamp, cell_center + float2(0.0, -step.y)).rgb, luma_2);
        float m02 = dot(image.Sample(linear_clamp, cell_center + float2(step.x, -step.y)).rgb, luma_2);
        
        // Row 1 - Middle: y 
        float m10 = dot(image.Sample(linear_clamp, cell_center + float2(-step.x, 0.0)).rgb, luma_2);
        float m11 = dot(image.Sample(linear_clamp, cell_center).rgb, luma_2);
        float m12 = dot(image.Sample(linear_clamp, cell_center + float2(step.x, 0.0)).rgb, luma_2);

        // Row 2 - Bottom: y + step.y

        float m20 = dot(image.Sample(linear_clamp, cell_center + float2(-step.x, step.y)).rgb, luma_2);
        float m21 = dot(image.Sample(linear_clamp, cell_center + float2(0.0, step.y)).rgb, luma_2);
        float m22 = dot(image.Sample(linear_clamp, cell_center + float2(step.x, step.y)).rgb, luma_2);
    }
    float3x3 G = float3x3(
        m00, m01, m02,
        m10, m11, m12,
        m20, m21, m22
    );

    // then get sobel_x and sobel_y

    float sx = dot(sobel_x[0], G[0]) +  dot(sobel_x[1], G[1]) +  dot(sobel_x[2], G[2]);
    float sy = dot(sobel_y[0], G[0]) +  dot(sobel_y[1], G[1]) +  dot(sobel_y[2], G[2]);
    // check magnitude against tolerance for noise
    float s_mag_sq = sx*sx+sy*sy;
    if (s_mag_sq > (tol_x*tol_y))
    {
        float s_angle = degrees(atan2(sy,sx)); 
        int edges_index = sobel_test(s_angle); // function needs written. Returns index of atlas for correct angle, 5 for bad angle

        float2 atlas_edges_uv = float2((edges_index + cell_uv.x) / num_chars_edges, cell_uv.y);
        float4 glyph_e = atlas_tex_edges.Sample(linear_clamp, atlas_edges_uv);
        return lerp(black, quantize_hue(src.rgb, num_colours), glyph_e.a);

    }
    // otherwise continue here.
    


    // The 3d vector is a known constant, giving the percieved relative luminance
    // of the colours in RGB space. Note how Green is percieved brighter than the others.
    // luma then becomes the percieved luminance of the cell (center)
    float luma = dot(src.rgb, float3(0.299, 0.587, 0.114)); // can be replaced with m11 if too slow
    // we use the luminance to see how far along the character is we wish to draw
    int char_index = round(luma * (num_chars - 1));
    // We only need the char_index for column-offsets. The row position remains the same.
    float2 atlas_uv = float2((char_index + cell_uv.x) / num_chars, cell_uv.y);
    // finally, we sample from that position on the atlas.
    float4 glyph = atlas_tex.Sample(linear_clamp, atlas_uv);
    return lerp(black, quantize_hue(src.rgb, num_colours), glyph.a);
}

technique Draw
{
    pass DrawAsciiVideo
    {
        vertex_shader = vertex_shader_e(vertex);
        pixel_shader  = pixel_shader_e(pixel);
    }
}