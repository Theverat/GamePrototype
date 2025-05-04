shader_type spatial;

#include "simplex_noise.gdshaderinc"

vec3 displace(vec3 point, vec3 normal) {
	float noiseScale = 0.8;
	float timeScale = 0.2;
	float noise = snoise(point * noiseScale + TIME * timeScale);
	noise = abs(noise*1.2);
	noise = pow(noise,15);
	return point + normal * noise;
}

void vertex() {
	// Displace vertices by moving along original normal
	vec3 newPos = displace(VERTEX, NORMAL);
	
	// Recalculate the normal
	float offset = 0.01;
	vec3 posPlusTangent = VERTEX + TANGENT * offset;
	vec3 posPlusTangentDisp = displace(posPlusTangent, NORMAL);
	
	vec3 bitangent = cross(NORMAL, TANGENT);
	vec3 posPlusBitangent = VERTEX + bitangent * offset;
	vec3 posPlusBitangentDisp = displace(posPlusBitangent, NORMAL);
	
	vec3 newTangent = posPlusTangentDisp - newPos;
	vec3 newBitangent = posPlusBitangentDisp - newPos;
	vec3 newNormal = normalize(cross(newTangent, newBitangent));
	
	VERTEX = newPos;
	NORMAL = newNormal;
}

void fragment() {
	ALBEDO = vec3(0);
	SPECULAR = 1.0;
	METALLIC = 1.0;
	ROUGHNESS = 0.0;
	EMISSION = vec3(0.1, 0, 0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
