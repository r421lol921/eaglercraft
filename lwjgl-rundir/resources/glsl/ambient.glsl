// PeytOtoria ambient world shader
// Warm pink ambient light and enhanced green saturation for lush world feel

#line 0

precision highp int;
precision highp sampler2D;
precision highp float;

in vec2 a_pos;
out vec2 pos;

#ifdef CC_VERT
void main() {
    gl_Position = vec4((pos = a_pos) * 2.0 - 1.0, 0.0, 1.0);
}
#endif

#ifdef CC_FRAG

uniform sampler2D f_color;
uniform sampler2D f_depth;
uniform vec2 screenSize;

// PeytOtoria palette
const vec3 PINK_AMBIENT   = vec3(1.0,  0.82, 0.92);  // warm rose-pink
const vec3 SKY_ZENITH     = vec3(0.95, 0.72, 0.88);  // pinkish sky top
const vec3 GRASS_BOOST    = vec3(0.88, 1.10, 0.82);  // green saturation push
const float AMBIENT_BLEND = 0.08;

// Soft saturation boost
vec3 saturate(vec3 c, float sat) {
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    return mix(vec3(lum), c, sat);
}

void main() {
    vec4 base = texture(f_color, pos);
    vec3 color = base.rgb;

    // Detect green-dominant pixels (grass, leaves, vines) and boost vibrancy
    float greenDom = max(0.0, color.g - max(color.r, color.b));
    color = mix(color, color * GRASS_BOOST, smoothstep(0.0, 0.2, greenDom) * 0.6);
    color = saturate(color, 1.15); // slight global saturation boost

    // Warm pink ambient overlay on bright areas
    float bright = dot(color, vec3(0.333));
    color = mix(color, color * PINK_AMBIENT, smoothstep(0.4, 0.9, bright) * AMBIENT_BLEND);

    // Subtle sky-zenith pink gradient from top to bottom of screen
    float topFade = 1.0 - pos.y;
    color = mix(color, color * SKY_ZENITH, topFade * 0.06);

    fragColor = vec4(clamp(color, 0.0, 1.0), base.a);
}

out vec4 fragColor;
#endif
