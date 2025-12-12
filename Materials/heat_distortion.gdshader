shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D noise_texture;
uniform float time;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.03;
uniform float distortion_speed : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    vec2 uv = SCREEN_UV;

    vec2 noise_uv = fract(uv * 5.0 + vec2(TIME * distortion_speed, -TIME * distortion_speed));
    float noise = texture(noise_texture, noise_uv).r;

    vec2 distortion = vec2(noise - 0.5) * distortion_strength;
    vec2 distorted_uv = uv + distortion;

    vec4 color = texture(screen_texture, distorted_uv);

    COLOR = color;
}
