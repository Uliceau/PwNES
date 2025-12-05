shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform float pixel_size = 1.0; // size of your "pixels" in world units
varying mat4 canvas_matrix;

void vertex() {
	canvas_matrix = CANVAS_MATRIX;
}

void fragment() {
    // Screen position (pixels)
    vec2 screen_pos = FRAGCOORD.xy;
    vec4 screen_pos_h = vec4(screen_pos, 0.0, 1.0);

    // Convert to world space
    vec2 world_pos = (inverse(canvas_matrix) * screen_pos_h).xy;

    // Snap world position to pixel grid
    vec2 snapped_world = floor(world_pos / pixel_size) * pixel_size;

    // Figure out where that snapped world point is on the screen
    vec4 snapped_screen_h = canvas_matrix * vec4(snapped_world, 0.0, 1.0);
    vec2 snapped_screen = snapped_screen_h.xy;

    // Normalize to SCREEN_TEXTURE UVs
    vec2 snapped_uv = snapped_screen * SCREEN_PIXEL_SIZE;

    // Sample screen at snapped UV → gives pixel-locked look
    COLOR = texture(SCREEN_TEXTURE, snapped_uv);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
