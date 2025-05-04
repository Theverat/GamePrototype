shader_type spatial;

uniform sampler2D tex;
uniform float lengthY;
uniform float brightness = 5.0;

void vertex() {
	// Make UV independent from object transform (this ensures the texture is 
	// tiled and not stretched when the object is scaled along its Y axis)
	UV.y *= lengthY;
}

void fragment() {
	const float speed = 15.;
	vec2 texUV = UV.yx;  // rotate
	texUV.x *= 0.2;  // scale
	texUV.x += TIME * speed;  // animate
	vec4 texVal = texture(tex, texUV);
	
	ALBEDO = vec3(0);
	ALPHA = texVal.a;
	EMISSION = texVal.rgb * brightness;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
