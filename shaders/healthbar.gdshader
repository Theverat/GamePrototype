shader_type spatial;
render_mode unshaded, skip_vertex_transform;

uniform float percentage : hint_range(0, 1) = 0.7;
uniform vec3 healthy : source_color = vec3(0, 1, 0);
uniform vec3 damaged : source_color = vec3(1, 0, 0);

void vertex() {
	mat4 transform = MODELVIEW_MATRIX;

    transform[0][0] = 1.0;
    transform[0][1] = 0.0;
    transform[0][2] = 0.0;

    transform[1][0] = 0.0;
    transform[1][1] = 1.0;
    transform[1][2] = 0.0;

    transform[2][0] = 0.0;
    transform[2][1] = 0.0;
    transform[2][2] = 1.0;

    VERTEX = (transform * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {	
	ALBEDO = UV.x > percentage ? damaged : healthy;
}
