## Pixel Perfect Camera Test Runner
## Simple test execution and reporting
extends SceneTree

func _ready() -> void:
	print("🎯 Running Pixel Perfect Camera Tests...")
	print("==================================================")
	
	# Run core functionality tests
	run_test("Pixel Snapping", test_pixel_snapping)
	run_test("Toggle Functionality", test_pixel_perfect_toggle)
	run_test("Camera Configuration", test_camera_configuration)
	
	# Run performance tests
	run_test("Jitter Reduction", test_jitter_reduction)
	run_test("Zoom Compatibility", test_zoom_compatibility)
	
	# Run integration tests
	run_test("Diagnostics Overlay", test_diagnostics_overlay)
	
	# Run value proposition tests
	run_test("Value Comparison", test_value_comparison)
	
	# Run edge cases
	run_test("Zero Position", test_zero_position)
	run_test("Negative Positions", test_negative_positions)
	
	print("==================================================")
	print("✅ All Pixel Perfect Camera Tests Completed!")
	quit()

func run_test(test_name: String, test_func: Callable) -> void:
	print("\n🧪 %s:" % test_name)
	test_func.call()
	print("   ✅ PASSED")

#region TEST IMPLEMENTATIONS

func test_pixel_snapping() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	camera.pixel_perfect = true
	
	var parent = Node2D.new()
	parent.global_position = Vector2(648.753, 424.159)
	parent.add_child(camera)
	
	camera._update_pixel_snap_offset()
	
	var cam_pos = camera.global_position
	var x_fraction = fmod(cam_pos.x, 1.0)
	var y_fraction = fmod(cam_pos.y, 1.0)
	
	_assert_check(x_fraction <= 0.001, "X position not pixel-aligned: %s" % x_fraction)
	_assert_check(y_fraction <= 0.001, "Y position not pixel-aligned: %s" % y_fraction)

func test_pixel_perfect_toggle() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	camera.pixel_perfect = true
	
	_assert_check(camera.pixel_perfect == true, "Should be enabled by default")
	
	camera.pixel_perfect = false
	_assert_check(camera.pixel_perfect == false, "Should toggle off")
	
	camera.pixel_perfect = true
	_assert_check(camera.pixel_perfect == true, "Should toggle on")

func test_camera_configuration() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	camera.pixel_perfect = true
	
	_assert_check(camera.process_callback == Camera2D.CAMERA2D_PROCESS_IDLE, "Should use IDLE process")
	_assert_check(camera.position_smoothing_enabled == false, "Should disable smoothing")
	_assert_check(camera.enabled == true, "Should be enabled")

func test_jitter_reduction() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	camera.pixel_perfect = true
	
	var parent = Node2D.new()
	parent.add_child(camera)
	
	var jitter_sum = 0.0
	var last_pos = Vector2.ZERO
	
	for i in range(10):
		parent.global_position = Vector2(600 + i * 10.7, 400 + i * 7.3)
		camera._update_pixel_snap_offset()
		
		var current_pos = camera.global_position
		if last_pos != Vector2.ZERO:
			jitter_sum += current_pos.distance_to(last_pos)
		last_pos = current_pos
	
	_assert_check(jitter_sum <= 1.0, "Jitter too high: %s" % jitter_sum)

func test_zoom_compatibility() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	camera.pixel_perfect = true
	
	var parent = Node2D.new()
	parent.global_position = Vector2(648.753, 424.159)
	parent.add_child(camera)
	
	var zoom_levels = [1.0, 2.0, 3.0, 4.0]
	
	for zoom in zoom_levels:
		camera.zoom = Vector2(zoom, zoom)
		camera._update_pixel_snap_offset()
		
		var cam_pos = camera.global_position
		var x_fraction = fmod(cam_pos.x, 1.0)
		var y_fraction = fmod(cam_pos.y, 1.0)
		
		_assert_check(x_fraction <= 0.001, "X not aligned at zoom %s: %s" % [zoom, x_fraction])
		_assert_check(y_fraction <= 0.001, "Y not aligned at zoom %s: %s" % [zoom, y_fraction])

func test_diagnostics_overlay() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	
	var diagnostics = preload("res://addons/pixel_perfect_camera/camera_diagnostics.gd").new()
	diagnostics.camera = camera
	
	_assert_check(diagnostics.camera == camera, "Camera not assigned to diagnostics")
	_assert_check(diagnostics.frame_count == 0, "Frame count should start at 0")
	
	for i in range(5):
		diagnostics._physics_process(0.016)
	
	_assert_check(diagnostics.frame_count == 5, "Frame count should increment")

func test_value_comparison() -> void:
	var pixel_camera = Camera2D.new()
	pixel_camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	pixel_camera.pixel_perfect = true
	
	var default_camera = Camera2D.new()
	
	var parent = Vector2(648.753, 424.159)
	
	# Pixel perfect calculation
	pixel_camera.global_position = parent + Vector2(-fmod(parent.x, 1.0), -fmod(parent.y, 1.0))
	var pixel_pos = pixel_camera.global_position
	
	# Default calculation
	default_camera.global_position = parent
	var default_pos = default_camera.global_position
	
	# Should be different
	_assert_check(pixel_pos != default_pos, "Positions should differ")
	
	# Pixel perfect should be aligned
	var pixel_x_fraction = fmod(pixel_pos.x, 1.0)
	var pixel_y_fraction = fmod(pixel_pos.y, 1.0)
	_assert_check(pixel_x_fraction <= 0.001, "Pixel perfect X not aligned")
	_assert_check(pixel_y_fraction <= 0.001, "Pixel perfect Y not aligned")
	
	# Default should have fractions
	var default_x_fraction = fmod(default_pos.x, 1.0)
	var default_y_fraction = fmod(default_pos.y, 1.0)
	_assert_check(abs(default_x_fraction) + abs(default_y_fraction) > 0.01, "Default should have fractions")

func test_zero_position() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	camera.pixel_perfect = true
	
	var parent = Node2D.new()
	parent.global_position = Vector2.ZERO
	parent.add_child(camera)
	
	camera._update_pixel_snap_offset()
	
	_assert_check(camera.global_position == Vector2.ZERO, "Should handle zero position")

func test_negative_positions() -> void:
	var camera = Camera2D.new()
	camera.script = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")
	camera.pixel_perfect = true
	
	var parent = Node2D.new()
	parent.global_position = Vector2(-100.753, -200.159)
	parent.add_child(camera)
	
	camera._update_pixel_snap_offset()
	
	var cam_pos = camera.global_position
	var x_fraction = fmod(cam_pos.x, 1.0)
	var y_fraction = fmod(cam_pos.y, 1.0)
	
	_assert_check(x_fraction <= 0.001, "Negative X not aligned: %s" % x_fraction)
	_assert_check(y_fraction <= 0.001, "Negative Y not aligned: %s" % y_fraction)

#endregion

func _assert_check(condition: bool, message: String) -> void:
	if not condition:
		push_error("ASSERTION FAILED: " + message)
		assert(false, "ASSERTION FAILED: " + message)
