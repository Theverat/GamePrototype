shader_type spatial;

#include "simplex_noise.gdshaderinc"
#include "utils.gdshaderinc"

uniform float noiseScale = 0.2;
uniform float speed = 0.9;
uniform float spikeBrightness = 3.0;
uniform float spikeMin : hint_range(0, 0.99) = 0.7;

// Original vertex position in model space
// (varying is used to pass it from vertex shader to fragment shader)
varying vec3 origVertexPos;
// Displaced vertex position in model space
varying vec3 displacedVertexPos;

float make_spiky(float value) {
	float spiky = value * 1.1;
	return pow(spiky, 8);
}

float tex1(vec3 point) {
	// snoise() returns a value between -1..1, so we bring it into 0..1 range
	return snoise(point * noiseScale + TIME * speed) * 0.5 + 0.5;
}

vec3 displace(vec3 point, vec3 normal) {	
	float noise = tex1(point);
	noise += make_spiky(noise);
	return point + normal * noise;
}

void vertex() {
	// Displace vertices by moving along original normal
	vec3 newPos = displace(VERTEX, NORMAL);
	
	// Recalculate the normal by displacing two neighbouring points
	// and constructing vectors to them
	float offset = 0.02;
	vec3 posPlusTangent = VERTEX + TANGENT * offset;
	vec3 posPlusTangentDisp = displace(posPlusTangent, NORMAL);
	
	vec3 bitangent = cross(NORMAL, TANGENT);
	vec3 posPlusBitangent = VERTEX + bitangent * offset;
	vec3 posPlusBitangentDisp = displace(posPlusBitangent, NORMAL);
	
	vec3 newTangent = posPlusTangentDisp - newPos;
	vec3 newBitangent = posPlusBitangentDisp - newPos;
	vec3 newNormal = normalize(cross(newTangent, newBitangent));
	
	origVertexPos = VERTEX;
	VERTEX = newPos;
	displacedVertexPos = newPos;
	NORMAL = newNormal;
}

void fragment() {
	float noise = tex1(origVertexPos);
	noise += make_spiky(noise);
	
	ALBEDO = vec3(0.03, 0, 0);
	//ALBEDO = vec3(noise < 0.1 ? 1.0 : 0.0);
	SPECULAR = 1.0;
	METALLIC = 1.0;
	ROUGHNESS = 0.0;
	
	float onlySpikes = clamp(noise, spikeMin, 1.);
	onlySpikes = remap(onlySpikes, spikeMin, 1., 0., 1.);
	EMISSION = vec3(0., 0.3, 1.) * onlySpikes * spikeBrightness;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
