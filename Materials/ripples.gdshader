shader_type spatial;
render_mode depth_draw_opaque;

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


void vertex() {
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
    float norm_y = clamp(vert_y, 0.01, 0.99);
	vec3 initial_lava_color = texture(gradient_texture, vec2(norm_y, 0.0)).rgb;
    vec3 lava_color = initial_lava_color + initial_lava_color * texture(noise_albedo_overlay, UV*10.0).r;

    // Scene depth (linearized)
    float z_depth = edge_depth(edge_near, edge_far, texture(depth_texture, SCREEN_UV).x);
    // Fragment depth (linearized)
    float z_pos   = edge_depth(edge_near, edge_far, FRAGCOORD.z);

    // Positive = lava is behind other geometry
    float depth_diff = z_depth - z_pos;
    depth_diff = max(depth_diff, 0.0);

    // Create a thin border near the intersection
    float border = 1.0 - smoothstep(0.0, border_thickness, depth_diff);

    // Mix lava with border glow
    vec3 final_color = mix(lava_color, border_color, border);

    ALBEDO   = final_color;
    EMISSION = final_color * 0.1;
	if( !FRONT_FACING){
		ALBEDO = vec3(1.0, 0.0, 0.0);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
