## Camera Jitter Fix Test Suite
## Tests the robust PixelPerfectCamera2D implementation for zero jitter
extends GdUnitTestSuite

const PixelPerfectCam = preload("uid://cqzlmu7a5z2ht")

## Test that camera snaps to integers (Zero Jitter requirement)
func test_integer_snapping() -> void:
	var camera = PixelPerfectCam.new()
	camera.pixel_perfect = true
	camera.snap_method = PixelPerfectCam.SnapMethod.ROUND
	add_child(camera)
	
	var parent = Node2D.new()
	parent.add_child(camera)
	
	# Simulate fractional parent positions
	var test_positions = [
		Vector2(100.1, 200.1), # Should round to (100, 200)
		Vector2(100.6, 200.6), # Should round to (101, 201)
		Vector2(100.49, 200.49), # Should round to (100, 200)
		Vector2(100.51, 200.51) # Should round to (101, 201)
	]
	
	for pos in test_positions:
		parent.global_position = pos
		# Manually trigger update logic
		camera._process(0.0)
		
		var cam_pos = camera.global_position
		
		# Verify strictly integer coordinates
		assert_float(cam_pos.x).is_equal(round(cam_pos.x))
		assert_float(cam_pos.y).is_equal(round(cam_pos.y))
		
		# Verify correct rounding
		assert_float(cam_pos.x).is_equal(round(pos.x))
		assert_float(cam_pos.y).is_equal(round(pos.y))

## Test different snap methods
func test_snap_methods() -> void:
	var camera = PixelPerfectCam.new()
	add_child(camera)
	var parent = Node2D.new()
	parent.add_child(camera)
	
	var target = Vector2(10.6, 10.6)
	parent.global_position = target
	
	# Round
	camera.snap_method = PixelPerfectCam.SnapMethod.ROUND
	camera._process(0)
	assert_vector(camera.global_position).is_equal(Vector2(11, 11))
	
	# Floor
	camera.snap_method = PixelPerfectCam.SnapMethod.FLOOR
	camera._process(0)
	assert_vector(camera.global_position).is_equal(Vector2(10, 10))
	
	# Ceil
	camera.snap_method = PixelPerfectCam.SnapMethod.CEIL
	camera._process(0)
	assert_vector(camera.global_position).is_equal(Vector2(11, 11))

## Test robust update cycle
func test_update_robustness() -> void:
	var camera = PixelPerfectCam.new()
	add_child(camera)
	
	# Verify priority is set correctly for late update
	assert_int(camera.process_priority).is_equal(100)
	
	# Verify we DO NOT detach from parent (standard Camera2D behavior)
	assert_bool(camera.top_level).is_false()

## Test no-jitter stability
func test_stability() -> void:
	var camera = PixelPerfectCam.new()
	add_child(camera)
	var parent = Node2D.new()
	parent.add_child(camera)
	
	# Move parent in sub-pixel increments
	var start = Vector2(100, 100)
	var history = []
	
	for i in range(10):
		parent.global_position = start + Vector2(i * 0.1, 0)
		camera._process(0)
		history.append(camera.global_position)
		
	# Verify staircasing (stable steps, no erratic jumping)
	# 0.0 -> 100
	# 0.1 -> 100
	# 0.2 -> 100
	# ...
	# 0.5 -> 101 (or 100 depending on rounding tie-breaking)
	
	var previous = history[0]
	for i in range(1, history.size()):
		var current = history[i]
		# Must be equal or +1 step. Never -1 or >1.
		var diff = current.x - previous.x
		assert_float(diff).is_greater_equal(0.0)
		assert_float(diff).is_less_equal(1.0)
		previous = current
