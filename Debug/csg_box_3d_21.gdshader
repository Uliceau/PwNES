shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, unshaded;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D screen_texture : hint_screen_texture;

uniform float distortion_strength : hint_range(0.0, 0.05); // small shift
uniform float distortion_radius : hint_range(0.0, 1.0);   // size of distortion zone
uniform vec2 blackhole_center = vec2(0.5, 0.5);

void fragment() {
    vec2 base_uv = UV;

    // Direction from center of effect
    vec2 dir = base_uv - blackhole_center;
    float dist = length(dir);

    // Only distort inside radius
    float mask = smoothstep(distortion_radius, 0.0, dist);

    // Offset sampling position by a small fraction of dir
    vec2 offset_uv = base_uv + normalize(dir + 1e-6) * distortion_strength * mask;

    // Sample screen with distortion
    vec4 screen_tex = texture(screen_texture, offset_uv);

    // Sample object albedo
    vec4 albedo_tex = texture(texture_albedo, base_uv);

    // Final mix: mesh acts as a "distortion lens"
    ALBEDO = albedo.rgb * albedo_tex.rgb + screen_tex.rgb;
}
