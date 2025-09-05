
// NOTE: Shader automatically converted from Godot Engine 4.5.beta7's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform sampler2D screen_texture : hint_screen_texture;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

// Black hole param
uniform vec2 blackhole_center = vec2(0.5, 0.5);
uniform float distortion_strength = 0.25;
uniform float distortion_radius = 0.4;
uniform float flatness = 1.5;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;

	// Billboard Mode: Enabled
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 screen_uv = SCREEN_UV;
	
	// Use center as the distortion origin
	vec2 local_center = vec2(0.5, 0.5);
	vec2 dir = (UV - local_center)*vec2(1.0, flatness);
	
	float dist = length(dir);
	float mask = smoothstep(distortion_radius, 0.0, dist);
	
	// Distortion direction
	vec2 offset_uv = screen_uv + normalize(dir) * distortion_strength * mask;
	
	// Distorted screen behind mesh
	vec4 screen_tex = texture(screen_texture, offset_uv);
	
	vec2 local_uv = UV - local_center;
	local_uv.y *= flatness;
	vec2 new_uv = clamp(local_center + local_uv, 0.0, 1.0);
	vec4 albedo_tex = texture(texture_albedo, new_uv);
	
	//vec4 albedo_tex = texture(texture_albedo, UV * vec2(1.0, flatness));
	
	
	ALBEDO = screen_tex.rgb;
	ALPHA = clamp(albedo_tex.r*10.0, 0.0, 0.9);
	
	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, UV), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
}