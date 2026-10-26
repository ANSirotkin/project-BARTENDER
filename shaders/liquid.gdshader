shader_type canvas_item;

uniform sampler2D palette_tex : filter_nearest;
uniform float palette_size = 5.0;
uniform bool pixel_mode = true;   // true = raw pixels, false = blobby liquid
uniform float blur_px = 1.0;
uniform float threshold = 0.3;
uniform float softness = 0.15;
uniform float opacity = 0.9;

void fragment() {
	if (pixel_mode) {
		float id = floor(texture(TEXTURE, UV).r * 255.0 + 0.5);
		COLOR = texture(palette_tex, vec2((id + 0.5) / palette_size, 0.5));
	} else {
		vec2 px = TEXTURE_PIXEL_SIZE * blur_px;
		vec4 sum = vec4(0.0);
		float wsum = 0.0;
		for (int x = -2; x <= 2; x++) {
			for (int y = -2; y <= 2; y++) {
				float wt = 1.0 / (1.0 + float(x * x + y * y));
				vec2 uv = UV + vec2(float(x), float(y)) * px;
				float id = floor(texture(TEXTURE, uv).r * 255.0 + 0.5);
				vec4 c = texture(palette_tex, vec2((id + 0.5) / palette_size, 0.5));
				sum += vec4(c.rgb * c.a, c.a) * wt;
				wsum += wt;
			}
		}
		sum /= wsum;
		float a = smoothstep(threshold - softness, threshold + softness, sum.a);
		vec3 rgb = sum.a > 0.001 ? sum.rgb / sum.a : vec3(0.0);
		COLOR = vec4(rgb, a * opacity);
	}
}