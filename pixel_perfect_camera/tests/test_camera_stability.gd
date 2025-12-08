## Camera Stability Tests
## Tests the stable vs precise pixel perfect algorithms
extends GdUnitTestSuite

## Test pixel perfect camera algorithm jitter behavior
func test_algorithm_jitter_behavior(
	algorithm: String,
	max_jitter_threshold: float,
	test_name: String,
	_test_parameters: Array[Variant] = [
		["stable", 2.0, "stable_algorithm_reduces_jitter"],
		["precise", 100.0, "precise_algorithm_jitter"] # Higher threshold for precise
	]
) -> void:
	var camera = Camera2D.new()
	camera.script = preload("uid://js27qgfeh3j6v")
	camera.pixel_perfect = true
	camera.algorithm = algorithm
	add_child(camera)
	
	var parent = Node2D.new()
	parent.add_child(camera)
	
	# Track jitter during movement pattern
	var jitter_sum = 0.0
	var last_pos = Vector2.ZERO
	
	# Simulate character movement pattern
	for i in range(20):
		var movement_time = i * 0.1
		parent.global_position = Vector2(
			640 + sin(movement_time) * 50.7, # Fractional movement
			360 + cos(movement_time) * 30.3 # Fractional movement
		)
		camera._update_pixel_snap_offset()
		
		var current_pos = camera.global_position
		if last_pos != Vector2.ZERO:
			jitter_sum += current_pos.distance_to(last_pos)
		last_pos = current_pos
	
	# Algorithm should stay within jitter threshold
	assert_float(jitter_sum).append_failure_message("%s algorithm jitter (%.3f) should be <= %.1f for %s" % [algorithm.capitalize(), jitter_sum, max_jitter_threshold, test_name]).is_less_equal(max_jitter_threshold)
	
	# Log actual jitter for comparison
	print("%s algorithm jitter: %.3f" % [algorithm.capitalize(), jitter_sum])

## Test algorithm comparison
func test_algorithm_comparison() -> void:
	var parent = Node2D.new()
	parent.global_position = Vector2(648.753, 424.159)
	
	# Test stable algorithm
	var stable_camera = Camera2D.new()
	stable_camera.script = preload("uid://js27qgfeh3j6v")
	stable_camera.pixel_perfect = true
	stable_camera.algorithm = "stable"
	parent.add_child(stable_camera)
	stable_camera._update_pixel_snap_offset()
	
	# Test precise algorithm
	var precise_camera = Camera2D.new()
	precise_camera.script = preload("uid://js27qgfeh3j6v")
	precise_camera.pixel_perfect = true
	precise_camera.algorithm = "precise"
	parent.add_child(precise_camera)
	precise_camera._update_pixel_snap_offset()
	
	var stable_pos = stable_camera.global_position
	var precise_pos = precise_camera.global_position
	
	# Both should be pixel-aligned
	var stable_x_frac = fmod(stable_pos.x, 1.0)
	var stable_y_frac = fmod(stable_pos.y, 1.0)
	assert_float(stable_x_frac).is_less_equal(0.001)
	assert_float(stable_y_frac).is_less_equal(0.001)
	
	var precise_x_frac = fmod(precise_pos.x, 1.0)
	var precise_y_frac = fmod(precise_pos.y, 1.0)
	assert_float(precise_x_frac).is_less_equal(0.001)
	assert_float(precise_y_frac).is_less_equal(0.001)
	
	# But they might target different pixel positions
	print("Stable target: ", stable_pos)
	print("Precise target: ", precise_pos)
	print("Difference: ", stable_pos.distance_to(precise_pos))

## Test hybrid algorithm
func test_hybrid_algorithm() -> void:
	var camera = Camera2D.new()
	camera.script = preload("uid://js27qgfeh3j6v")
	camera.pixel_perfect = true
	camera.algorithm = "hybrid"
	add_child(camera)
	
	var parent = Node2D.new()
	parent.add_child(camera)
	
	# Test with different parent positions
	parent.global_position = Vector2(648.753, 424.159)
	camera._update_pixel_snap_offset()
	
	var cam_pos = camera.global_position
	var x_fraction = fmod(cam_pos.x, 1.0)
	var y_fraction = fmod(cam_pos.y, 1.0)
	
	# Should still be pixel-aligned
	assert_float(x_fraction).is_less_equal(0.001)
	assert_float(y_fraction).is_less_equal(0.001)
