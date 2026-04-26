// PeytOtoria bloom + pink sky post-processing shader
// Added for PeytOtoria edition - soft bloom glow and pink sky tint

#line 0

precision mediump int;
precision mediump sampler2D;
precision mediump float;

in vec2 pos;
out vec4 fragColor;

uniform sampler2D f_color;
uniform vec2 screenSize;

// Configurable bloom parameters
#define BLOOM_INTENSITY   0.18
#define BLOOM_SPREAD      3.0
#define PINK_SKY_STRENGTH 0.12
#define VIGNETTE_STRENGTH 0.35

// Sample a 9-tap Gaussian blur for bloom
vec3 sampleBloom(sampler2D tex, vec2 uv, vec2 texelSize) {
    vec3 result = vec3(0.0);
    float weights[9];
    vec2 offsets[9];

    weights[0] = 0.0625; offsets[0] = vec2(-1.0, -1.0);
    weights[1] = 0.125;  offsets[1] = vec2( 0.0, -1.0);
    weights[2] = 0.0625; offsets[2] = vec2( 1.0, -1.0);
    weights[3] = 0.125;  offsets[3] = vec2(-1.0,  0.0);
    weights[4] = 0.25;   offsets[4] = vec2( 0.0,  0.0);
    weights[5] = 0.125;  offsets[5] = vec2( 1.0,  0.0);
    weights[6] = 0.0625; offsets[6] = vec2(-1.0,  1.0);
    weights[7] = 0.125;  offsets[7] = vec2( 0.0,  1.0);
    weights[8] = 0.0625; offsets[8] = vec2( 1.0,  1.0);

    for (int i = 0; i < 9; i++) {
        result += texture(tex, uv + offsets[i] * texelSize * BLOOM_SPREAD).rgb * weights[i];
    }
    return result;
}

// Luminance helper
float luma(vec3 col) {
    return dot(col, vec3(0.299, 0.587, 0.114));
}

void main() {
    vec2 texelSize = 1.0 / screenSize;
    vec4 baseColor = texture(f_color, pos);

    // Bloom: extract bright areas and blur
    vec3 bloomSample = sampleBloom(f_color, pos, texelSize);
    float brightness = luma(bloomSample);
    vec3 bloomGlow = max(bloomSample - vec3(0.6), vec3(0.0)) * (1.0 / 0.4);
    vec3 color = baseColor.rgb + bloomGlow * BLOOM_INTENSITY;

    // Pink sky tint: blend a soft rose-pink into bright/sky areas
    // Sky pixels tend to be bright and blue-ish
    float skyBlend = smoothstep(0.5, 1.0, luma(color)) * max(0.0, color.b - color.r) * 2.0;
    vec3 pinkTint = vec3(1.0, 0.72, 0.85); // rose-pink
    color = mix(color, color * pinkTint, skyBlend * PINK_SKY_STRENGTH * 4.0);

    // Global gentle pink atmospheric tint
    color = mix(color, color * vec3(1.03, 0.98, 1.02), PINK_SKY_STRENGTH * 0.4);

    // Vignette for cinematic feel
    vec2 vigUV = pos * 2.0 - 1.0;
    float vignette = 1.0 - dot(vigUV * vec2(0.8, 1.0), vigUV * vec2(0.8, 1.0)) * VIGNETTE_STRENGTH;
    color *= clamp(vignette, 0.0, 1.0);

    // Subtle color grading: slight warm highlights, cool shadows
    float lum = luma(color);
    vec3 warm  = vec3(1.05, 1.0, 0.95);
    vec3 cool  = vec3(0.95, 0.97, 1.05);
    color *= mix(cool, warm, smoothstep(0.0, 1.0, lum));

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
