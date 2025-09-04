shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;

uniform sampler2D noise_texture;
uniform sampler2D noise_overlay;
uniform sampler2D noise_albedo_overlay;
uniform sampler2D gradient_texture;
uniform sampler2D depth_texture : hint_depth_texture;
uniform float wave_amplitude = 4.0;

uniform float edge_near = 0.05;
uniform float edge_far  = 4000.0;
uniform float border_thickness = 10.2;
uniform vec3 border_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float time = 0.0;
uniform float noise_scale = 0.01;
varying float vert_y;

varying vec3 world_pos;

void vertex() {
	world_pos = (VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 noise_uv = VERTEX.xz;
	float noise = texture(noise_texture, noise_uv * noise_scale + time*0.1).r +  texture(noise_overlay, noise_uv * noise_scale - time*0.02).r - 0.5;
	VERTEX.y += noise*wave_amplitude;
	vert_y = noise;
}

float edge_depth(float near, float far, float depth){
    depth = 1.0 - 2.0 * depth;
    return near * far / (far + depth * (near - far));
}

void fragment() {
	float norm_y = clamp(vert_y, 0.001, 0.8);
	vec3 initial_lava_color = texture(gradient_texture, vec2(norm_y, 0.0)+texture(noise_albedo_overlay, UV).rg*0.1).rgb;
	vec3 lava_color = initial_lava_color + initial_lava_color * texture(noise_albedo_overlay, UV*10.0).r;

	float z_depth = edge_depth(edge_near, edge_far, texture(depth_texture, SCREEN_UV).x);
	float z_pos   = edge_depth(edge_near, edge_far, FRAGCOORD.z);

	float depth_diff = z_depth - z_pos;
	depth_diff = max(depth_diff, 0.0);

	float border = 1.0 - smoothstep(0.0, border_thickness, depth_diff);

	vec3 final_color = mix(lava_color, border_color, border);

	ALBEDO   = final_color;
	EMISSION = final_color * 0.1;
}