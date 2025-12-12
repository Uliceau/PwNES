shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform float pixel_size = 1.0;
varying mat4 canvas_matrix;

void vertex() {
	canvas_matrix = CANVAS_MATRIX;
}

void fragment() {
    vec2 screen_pos = FRAGCOORD.xy;
    vec4 screen_pos_h = vec4(screen_pos, 0.0, 1.0);

    //world space
    vec2 world_pos = (inverse(canvas_matrix) * screen_pos_h).xy;
    vec2 snapped_world = floor(world_pos / pixel_size) * pixel_size;

    vec4 snapped_screen_h = canvas_matrix * vec4(snapped_world, 0.0, 1.0);
    vec2 snapped_screen = snapped_screen_h.xy;

    vec2 snapped_uv = snapped_screen * SCREEN_PIXEL_SIZE;

    COLOR = texture(SCREEN_TEXTURE, snapped_uv);
}
