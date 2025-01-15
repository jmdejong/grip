shader_type spatial;

uniform sampler2D gradient: source_color;
uniform vec3 water_color: source_color;
uniform float gradient_scale;
uniform float radius;

varying float height;

void vertex() {
	height = CUSTOM0.x;
	//VERTEX = normalize(VERTEX) * radius + max(height, 0.0);
}

void fragment() {
	if (height < 0.0) {
		ALBEDO = water_color;
	} else {
		ALBEDO = texture(gradient, vec2(height/100.0, 0)).xyz;
		//ALBEDO = COLOR.xyz;
	}
}
