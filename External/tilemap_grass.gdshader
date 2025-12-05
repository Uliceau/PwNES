shader_type canvas_item;

uniform float tolerance: hint_range(0.0, 1.0, 0.001) = 0.1;
uniform float grass_spread: hint_range(0.0, 1.0, 0.001) = 0.05;
uniform vec4 prev_color: source_color = vec4(1.0);
uniform sampler2D deco_tex;
uniform sampler2D tolerance_tex;
uniform sampler2D warp_tex;
uniform sampler2D palette;
uniform float animation_speed = 1.0;
uniform float alpha_intensity: hint_range(0.0, 1.0, 0.01) = 1.0;
varying mat4 canvas_matrix;

uniform sampler2D flower_tex;
uniform float spawn_chance : hint_range(0.0, 1.0) = 0.3;
uniform vec2 density = vec2(1.0);

void vertex() {
	canvas_matrix = CANVAS_MATRIX;
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 rotate(vec2 uv, vec2 pivot, float angle)
{
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
						vec2(cos(angle), sin(angle)));

	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}

void fragment() {
	vec2 tex_size = vec2(textureSize(deco_tex, 0));
	// Screen position (pixels)
	vec2 screen_pos = FRAGCOORD.xy;
	vec4 screen_pos_h = vec4(screen_pos, 0.0, 1.0);
	vec2 world_pos = (inverse(canvas_matrix) * screen_pos_h).xy;

	vec2 uv = fract(world_pos/tex_size);
	uv = (floor(uv * tex_size) + 0.5) / tex_size;
	vec4 color = texture(TEXTURE, UV);
	vec4 initial_color = color;

	float color_distance = distance(prev_color.rgb, color.rgb);
	float new_tolerance = tolerance* texture(tolerance_tex, fract(uv + vec2(TIME*animation_speed*0.03) -texture(warp_tex, uv).g*0.1)).r;


	float blend = clamp(1.0 - (color_distance / new_tolerance), 0.0, 1.0);
	float alpha_blend = blend;




	if (color.a < 1.0) {
	    alpha_blend *= alpha_intensity;
	}
	color.rgb = mix(initial_color.rgb, texture(deco_tex, uv).rgb, alpha_blend);
	color.a = initial_color.a;

    // Use world pixel coordinates for grid
    vec2 grid = floor(world_pos / density);

    // Random per grid cell
    float rnd = hash(grid);

    vec4 flower_col = vec4(0.0);
    if (rnd < spawn_chance) {
        // Grid cell center in world space
        vec2 cell_center = (grid + mod(density, 2)*0.5) * density;

        // Flower size in texels
        vec2 flower_px_size = vec2(textureSize(flower_tex, 0));

        // Offset from flower center (world pixels)
		// 1. Local delta (before rotation)
		vec2 local_delta = world_pos + round(rnd*1.0) - cell_center;

		// 2. Quantize the local delta (pixel grid stays stable in world space)
		vec2 q_delta = floor(local_delta+0.5);

		// 3. Rotate the quantized delta (now it stays "blocky" but rotates as a rigid flower)
		vec2 delta = rotate(q_delta, vec2(0, 2.0), 1.6 + sin(TIME*1.0+ (cell_center.y + cell_center.x) * 0.05) * 0.3);
		vec2 spawn_uv = fract(cell_center/tex_size);
		spawn_uv = (floor(spawn_uv * tex_size) + 0.5) / tex_size;
		float new_blend = tolerance* texture(tolerance_tex,fract(spawn_uv+ vec2(TIME*animation_speed*0.03)  -texture(warp_tex, uv).g*0.1)).r;

		vec4 center_color = texture(TEXTURE, spawn_uv);

		float color_distance = distance(prev_color.rgb, center_color.rgb);
		float blend = clamp(1.0 - (color_distance / new_blend), 0.0, 1.0);

		// Draw inside flower bounds
        if (all(lessThan(abs(delta), flower_px_size * 0.5)) && new_blend > grass_spread) {
            vec2 fuv = (delta / flower_px_size) + 0.5;
			fuv = (floor(fuv * flower_px_size) + 0.5) / flower_px_size;
            flower_col = texture(flower_tex, fuv) * texture(palette, clamp((vec2(spawn_uv.x*10.0, 0)), vec2(0.0), vec2(1.0)));
			flower_col.rgb = pow(flower_col.rgb, vec3(2.2/1.0));
        }
    }

	if (flower_col.a > 0.0){
		COLOR = flower_col;
	}
	else{
		COLOR = color;
	}
}
