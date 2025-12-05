shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture;

uniform bool enabled;
uniform sampler2D Blend;  //Blending mode texture
uniform float Intensity : hint_range(0, 1) = 1.0;  //Default should be 1 but syntax doesn't allow it currently?
uniform sampler2D Noise;
uniform float NoiseScale = 1.0;
uniform float Rotation = 0.0;

void fragment() {
	
	if (COLOR.a != 0.0){
		vec4 bgColor = texture( screen_texture, SCREEN_UV);
		vec4 Color = COLOR;
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
		
		
		vec2 uv = UV;
		vec2 tex_size = vec2(textureSize(TEXTURE, 0));
		// Snap to the original texture's pixel grid BEFORE scaling
		uv = (floor(uv * tex_size) + 0.5) / tex_size;
		
		vec2 rotated_uv;
		rotated_uv.x = uv.x * cos(Rotation) - uv.y * sin(Rotation);
		rotated_uv.y = uv.x * cos(Rotation) + uv.y * sin(Rotation);
		
		COLOR = output*1.0 * texture(Noise, mod(rotated_uv*NoiseScale+TIME*0.002
		, vec2(1.0)));
		
	} else {
		COLOR = vec4(0.0);
	}
}