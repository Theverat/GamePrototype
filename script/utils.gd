class_name Utils

static func sqr(value):
	return value * value

static func elapsedSec() -> float:
	return Time.get_ticks_msec() / 1000.0
