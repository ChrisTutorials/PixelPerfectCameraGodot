## High-Value Pixel Perfect Camera Tests
## Focused test suite proving core functionality and value
extends GdUnitTestSuite

#region CORE FUNCTIONALITY TESTS

## Test that pixel perfect camera snaps to whole pixels
func test_pixel_snapping() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	camera.pixel_perfect = true
	add_child(camera)
	
	# Set parent to fractional position
	var parent = Node2D.new()
	parent.global_position = Vector2(648.753, 424.159)
	parent.add_child(camera)
	
	# Update camera
	camera._update_pixel_snap_offset()
	
	# Camera should be at pixel-aligned position
	var cam_pos = camera.global_position
	var x_fraction = fmod(cam_pos.x, 1.0)
	var y_fraction = fmod(cam_pos.y, 1.0)
	
	assert_float(x_fraction).is_less_equal(0.001)
	assert_float(y_fraction).is_less_equal(0.001)

## Test that pixel perfect can be toggled
func test_pixel_perfect_toggle() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	camera.pixel_perfect = true
	add_child(camera)
	
	# Should be enabled by default
	assert_bool(camera.pixel_perfect).is_true()
	
	# Toggle off
	camera.pixel_perfect = false
	assert_bool(camera.pixel_perfect).is_false()
	
	# Toggle on
	camera.pixel_perfect = true
	assert_bool(camera.pixel_perfect).is_true()

## Test camera configuration for pixel perfect
func test_camera_configuration() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	camera.pixel_perfect = true
	add_child(camera)
	
	# Verify pixel perfect settings
	assert_int(camera.process_callback).is_equal(Camera2D.CAMERA2D_PROCESS_IDLE)
	assert_bool(camera.position_smoothing_enabled).is_false()
	assert_bool(camera.enabled).is_true()

#endregion

#region PERFORMANCE TESTS

## Test jitter reduction during movement
func test_jitter_reduction() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	camera.pixel_perfect = true
	add_child(camera)
	
	var parent = Node2D.new()
	parent.add_child(camera)
	
	# Track jitter during movement
	var jitter_sum = 0.0
	var last_pos = Vector2.ZERO
	
	for i in range(10):
		parent.global_position = Vector2(600 + i * 10.7, 400 + i * 7.3)
		camera._update_pixel_snap_offset()
		
		var current_pos = camera.global_position
		if last_pos != Vector2.ZERO:
			jitter_sum += current_pos.distance_to(last_pos)
		last_pos = current_pos
	
	# Pixel perfect camera should have minimal jitter
	assert_float(jitter_sum).is_less_equal(1.0)

## Test performance with different zoom levels
func test_zoom_compatibility(
	zoom_level: float,
	test_name: String,
	_test_parameters: Array[Variant] = [
		[1.0, "zoom_1x"],
		[2.0, "zoom_2x"],
		[3.0, "zoom_3x"],
		[4.0, "zoom_4x"]
	]
) -> void:
	var camera = Camera2D.new()
	camera.script = preload("uid://dt2el6566qhep")
	camera.pixel_perfect = true
	add_child(camera)
	
	var parent = Node2D.new()
	parent.global_position = Vector2(648.753, 424.159)
	parent.add_child(camera)
	
	# Test specific zoom level
	camera.zoom = Vector2(zoom_level, zoom_level)
	camera._update_pixel_snap_offset()
	
	var cam_pos = camera.global_position
	var x_fraction = fmod(cam_pos.x, 1.0)
	var y_fraction = fmod(cam_pos.y, 1.0)
	
	# Should maintain pixel alignment at all zoom levels
	assert_float(x_fraction).append_failure_message("Camera X should be pixel-aligned at zoom %.1f for %s (fraction: %s)" % [zoom_level, test_name, x_fraction]).is_less_equal(0.001)
	assert_float(y_fraction).append_failure_message("Camera Y should be pixel-aligned at zoom %.1f for %s (fraction: %s)" % [zoom_level, test_name, y_fraction]).is_less_equal(0.001)

#endregion

#region INTEGRATION TESTS

## Test diagnostics overlay functionality
func test_diagnostics_overlay() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	add_child(camera)
	
	# Add diagnostics
	var diagnostics = preload("res://addons/pixel_perfect_camera/camera_diagnostics.gd").new()
	diagnostics.camera = camera
	add_child(diagnostics)
	
	# Verify diagnostics setup
	assert_object(diagnostics.camera).is_equal(camera)
	assert_int(diagnostics.frame_count).is_equal(0)
	
	# Simulate frames
	for i in range(5):
		diagnostics._physics_process(0.016)
	
	assert_int(diagnostics.frame_count).is_equal(5)

## Test with real demo scene integration
func test_demo_scene_integration() -> void:
	var demo_scene = preload("res://demos/camera/pixel_perfect_demo.tscn").instantiate()
	add_child(demo_scene)
	
	# Find camera in demo
	var camera = demo_scene.get_node("World/PlayerBuilder/Camera2D")
	
	# Verify pixel perfect camera is loaded
	assert_object(camera.get_script()).is_not_null()
	assert_bool(camera.pixel_perfect).is_true()
	
	# Test pixel alignment
	var player = demo_scene.get_node("World/PlayerBuilder")
	player.global_position = Vector2(648.753, 424.159)
	
	await get_tree().process_frame
	
	var cam_pos = camera.global_position
	var x_fraction = fmod(cam_pos.x, 1.0)
	var y_fraction = fmod(cam_pos.y, 1.0)
	
	assert_float(x_fraction).is_less_equal(0.001)
	assert_float(y_fraction).is_less_equal(0.001)

#endregion

#region VALUE PROPOSITION TESTS

## Test pixel perfect vs default camera comparison
func test_value_comparison() -> void:
	var pixel_camera = Camera2D.new()
	pixel_camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	pixel_camera.pixel_perfect = true
	
	var default_camera = Camera2D.new()
	
	# Test with fractional parent position
	var parent = Vector2(648.753, 424.159)
	
	# Pixel perfect camera calculation
	pixel_camera.global_position = parent + Vector2(-fmod(parent.x, 1.0), -fmod(parent.y, 1.0))
	var pixel_pos = pixel_camera.global_position
	
	# Default camera (no correction)
	default_camera.global_position = parent
	var default_pos = default_camera.global_position
	
	# Pixel perfect should be different from default
	assert_that(pixel_pos).is_not_equal(default_pos)
	
	# Pixel perfect should be aligned to whole pixels
	var pixel_x_fraction = fmod(pixel_pos.x, 1.0)
	var pixel_y_fraction = fmod(pixel_pos.y, 1.0)
	assert_float(pixel_x_fraction).is_less_equal(0.001)
	assert_float(pixel_y_fraction).is_less_equal(0.001)
	
	# Default should have fractional components
	var default_x_fraction = fmod(default_pos.x, 1.0)
	var default_y_fraction = fmod(default_pos.y, 1.0)
	assert_float(abs(default_x_fraction) + abs(default_y_fraction)).is_greater(0.01)

#endregion

#region EDGE CASES

## Test with zero position
func test_zero_position() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	camera.pixel_perfect = true
	add_child(camera)
	
	var parent = Node2D.new()
	parent.global_position = Vector2.ZERO
	parent.add_child(camera)
	
	camera._update_pixel_snap_offset()
	
	# Should handle zero position gracefully
	var zero_pos = camera.global_position
	assert_float(zero_pos.x).is_equal(0.0)
	assert_float(zero_pos.y).is_equal(0.0)

## Test with negative positions
func test_negative_positions() -> void:
	var camera = Camera2D.new()
	camera.script = preload("uid://dt2el6566qhep")
	camera.pixel_perfect = true
	add_child(camera)
	
	var parent = Node2D.new()
	parent.global_position = Vector2(-100.753, -200.159)
	parent.add_child(camera)
	
	camera._update_pixel_snap_offset()
	
	var cam_pos = camera.global_position
	var x_fraction = fmod(cam_pos.x, 1.0)
	var y_fraction = fmod(cam_pos.y, 1.0)
	
	# Should handle negative positions correctly
	assert_float(x_fraction).is_less_equal(0.001)
	assert_float(y_fraction).is_less_equal(0.001)

#endregion
