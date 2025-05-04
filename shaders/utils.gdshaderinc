
// Map value from range fromMin..fromMax to toMin..toMax
float remap(float value, float fromMin, float fromMax, float toMin, float toMax) {
	return toMin + (value - fromMin) * (toMax - toMin) / (fromMax - fromMin);
}
