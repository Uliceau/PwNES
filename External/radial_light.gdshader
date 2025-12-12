shader_type canvas_item;

uniform sampler2D mask;
uniform float repeat_count = 5.0;

uniform sampler2D Blend;
uniform float Intensity : hint_range(0, 1) = 1.0;
uniform float curve = 0.0;
uniform float rotate_speed = 1.0;
uniform float color_speed = 1.0;
uniform float color_interval = 1.0;

uniform sampler2D screen_texture : hint_screen_texture;

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

vec2 polar_coordinates(vec2 uv, vec2 center, float zoom, float repeat)
{
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x) * 1.0/(3.1416 * 2.0)+TIME*0.1*rotate_speed-radius*curve;
	return mod(vec2(radius * zoom, angle * repeat), 1.0);
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment(){

	vec4 bgColor = texture( screen_texture, SCREEN_UV);
	vec4 Color = vec4(1.0);
	vec4 blendColor;
	vec4 output = vec4(0.0);

	output.a = Color.a;

	blendColor = texture( Blend, vec2(bgColor.r, Color.r) );
	output.r = blendColor.r;
	blendColor = texture( Blend, vec2(bgColor.g, Color.g) );
	output.g = blendColor.g;
	blendColor = texture( Blend, vec2(bgColor.b, Color.b) );
	output.b = blendColor.b;

	output.rgb = mix(Color.rgb, output.rgb, Intensity)*4.0;

    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 uv = UV;
	vec3 new_col = rgb2hsv(vertex_color.rgb);
    //snap to the original texture's pixel grid
    uv = (floor(uv * tex_size) + 0.5) / tex_size;

	vec2 polar_uv = polar_coordinates(uv.xy, vec2(0.5), 0.3, repeat_count);
	new_col.r = sin(polar_uv.r*color_interval-TIME*color_speed)*1.1;

	COLOR = vec4(hsv2rgb(new_col), 1.0) *  texture(TEXTURE, polar_uv) * output * texture(mask, uv);
}
