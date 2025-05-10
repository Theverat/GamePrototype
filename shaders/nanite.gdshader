shader_type spatial;
render_mode world_vertex_coords;

#include "simplex_noise.gdshaderinc"
#include "utils.gdshaderinc"

// Low Frequency
uniform float lfNoiseScale = 0.2;
uniform float lfDisplaceStrength = 1.0;
// High Frequency
uniform float hfNoiseScale = 0.2;
uniform float hfDisplaceStrength = 1.0;

uniform float speed = 0.9;
uniform float spikeBrightness = 3.0;
uniform float spikeMin : hint_range(0, 0.99) = 0.7;
uniform vec3 spikeColor : source_color = vec3(0., 0.3, 1.);

// Original vertex position in model space
// (varying is used to pass it from vertex shader to fragment shader)
varying vec3 origVertexPos;
// Displaced vertex position in model space
varying vec3 displacedVertexPos;

float make_spiky(float value) {
	float spiky = value * 1.1;
	return pow(spiky, 8);
}

float high_freq_noise(vec3 point) {
	float scaledTime = TIME * speed;
	// snoise() returns a value between -1..1, so we bring it into 0..1 range
	float fine_noise = snoise((point + scaledTime) * hfNoiseScale) * 0.5 + 0.5;
	fine_noise += make_spiky(fine_noise);
	return fine_noise;
}

float low_freq_noise(vec3 point) {
	float scaledTime = TIME * speed;
	vec3 offset = vec3(0.5, 0.3, 0.8) + scaledTime * 4.0;
	return snoise((point + offset) * lfNoiseScale * 0.3);
}

vec3 displace(vec3 point, vec3 normal) {
	float disp = high_freq_noise(point) * hfDisplaceStrength 
				 + low_freq_noise(point) * lfDisplaceStrength;
	return point + normal * disp;
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
	float noise = high_freq_noise(origVertexPos);

	//ALBEDO = vec3(noise);
	ALBEDO = vec3(0.03, 0, 0);
	//ALBEDO = vec3(noise > 1. ? 1.0 : 0.0);
	SPECULAR = 1.0;
	METALLIC = 1.0;
	ROUGHNESS = 0.0;

	float spikeMask = clamp(noise, spikeMin, 1.);
	spikeMask = remap(spikeMask, spikeMin, 1., 0., 1.);
	EMISSION = spikeColor * spikeMask * spikeBrightness;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
