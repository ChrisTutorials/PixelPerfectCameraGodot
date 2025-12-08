## Pixel Perfect Camera Test Base Class
## Provides common setup and utilities for pixel perfect camera tests
class_name PixelPerfectTestBase
extends GdUnitTestSuite

#region Local Classes

## Type-safe camera setup container
## Replaces brittle Dictionary[String, Node2D] anti-pattern
class CameraSetup:
	var camera: Camera2D
	var parent: Node2D
	var setup: RefCounted # Test-specific setup data
	
	func _init(p_camera: Camera2D, p_parent: Node2D, p_setup: RefCounted = null) -> void:
		camera = p_camera
		parent = p_parent
		setup = p_setup
	
	## Convenience getter for camera position
	func get_position() -> Vector2:
		return camera.global_position
	
	## Convenience setter for camera position
	func set_position(position: Vector2) -> void:
		parent.global_position = position
	
	## Trigger camera update if available
	func update_camera() -> void:
		if camera.has_method("_update_pixel_snap_offset"):
			camera._update_pixel_snap_offset()

#endregion

#region Test Setup

## Common test setup for pixel perfect camera tests
func before_test() -> void:
	# Override in subclasses if needed
	pass

## Common test cleanup
func after_test() -> void:
	# Override in subclasses if needed
	pass

#endregion

#region Camera Creation Helpers

## Create a standard pixel perfect camera with parent
func create_camera_with_parent(camera_script: Script = PixelPerfectTestConstants.CameraFollower) -> CameraSetup:
	var parent = Node2D.new()
	add_child(parent)
	auto_free(parent)
	
	var camera = Camera2D.new()
	camera.script = camera_script
	camera.pixel_perfect = true
	parent.add_child(camera)
	
	return CameraSetup.new(camera, parent, null)

## Create camera at specific position
func create_camera_at_position(position: Vector2, camera_script: Script = PixelPerfectTestConstants.CameraFollower) -> Camera2D:
	var setup: CameraSetup = create_camera_with_parent(camera_script)
	setup.set_position(position)
	setup.update_camera()
	
	return setup.camera

## Create stable algorithm camera
func create_stable_camera() -> Camera2D:
	var camera = Camera2D.new()
	camera.script = PixelPerfectTestConstants.CameraFollowerStable
	camera.pixel_perfect = true
	camera.algorithm = "stable"
	
	var parent = Node2D.new()
	add_child(parent)
	auto_free(parent)
	parent.add_child(camera)
	
	return camera

## Create precise algorithm camera
func create_precise_camera() -> Camera2D:
	var camera = Camera2D.new()
	camera.script = PixelPerfectTestConstants.CameraFollowerStable
	camera.pixel_perfect = true
	camera.algorithm = "precise"
	
	var parent = Node2D.new()
	add_child(parent)
	auto_free(parent)
	parent.add_child(camera)
	
	return camera

## Create camera with diagnostics
func create_camera_with_diagnostics(position: Vector2 = Vector2.ZERO) -> CameraSetup:
	var setup: CameraSetup = create_camera_with_parent()
	setup.set_position(position)
	
	var diagnostics: CanvasLayer = PixelPerfectTestConstants.create_diagnostics(setup.camera)
	add_child(diagnostics)
	auto_free(diagnostics)
	
	# Return enhanced setup with diagnostics
	var enhanced_setup = CameraSetup.new(setup.camera, setup.parent, diagnostics)
	return enhanced_setup

#endregion

#region Assertion Helpers

## Assert pixel alignment with descriptive message
func assert_pixel_aligned(camera: Camera2D, context: String = "camera") -> void:
	var position = camera.global_position
	var is_aligned: bool = PixelPerfectTestConstants.is_pixel_aligned(position)
	
	assert_bool(is_aligned) \
		.append_failure_message(
			"%s position %s is not pixel aligned. %s" % [
				context.capitalize(),
				str(position),
				PixelPerfectTestConstants.format_alignment_error(position)
			]
		) \
		.is_true()

## Assert pixel alignment at specific position
func assert_pixel_aligned_at_position(camera: Camera2D, expected_position: Vector2, tolerance: float = PixelPerfectTestConstants.PIXEL_TOLERANCE) -> void:
	var actual_position = camera.global_position
	var x_diff = abs(actual_position.x - expected_position.x)
	var y_diff = abs(actual_position.y - expected_position.y)
	
	assert_float(x_diff).is_less_equal(tolerance) \
		.append_failure_message(
			"Camera X position %.3f differs from expected %.3f by %.3f" % [
				actual_position.x, expected_position.x, x_diff
			]
		)
	
	assert_float(y_diff).is_less_equal(tolerance) \
		.append_failure_message(
			"Camera Y position %.3f differs from expected %.3f by %.3f" % [
				actual_position.y, expected_position.y, y_diff
			]
		)

## Assert jitter within threshold
func assert_jitter_within_threshold(jitter_sum: float, threshold: float, algorithm_name: String) -> void:
	assert_float(jitter_sum).is_less_equal(threshold) \
		.append_failure_message(
			"%s algorithm jitter %.3f exceeds threshold %.3f" % [
				algorithm_name.capitalize(),
				jitter_sum,
				threshold
			]
		)

## Assert camera configuration
func assert_camera_configuration(camera: Camera2D, pixel_perfect: bool = true) -> void:
	assert_bool(camera.pixel_perfect).is_equal(pixel_perfect) \
		.append_failure_message("Camera pixel_perfect should be %s" % pixel_perfect)
	
	assert_int(camera.process_callback).is_equal(Camera2D.CAMERA2D_PROCESS_IDLE) \
		.append_failure_message("Camera should use IDLE process callback")
	
	assert_bool(camera.position_smoothing_enabled).is_false() \
		.append_failure_message("Camera position smoothing should be disabled")
	
	assert_bool(camera.enabled).is_true() \
		.append_failure_message("Camera should be enabled")

#endregion

#region Movement Testing

## Test pixel alignment across multiple positions
func test_pixel_alignment_positions(camera_script: Script = PixelPerfectTestConstants.CameraFollower) -> void:
	for test_pos in PixelPerfectTestConstants.TEST_POSITIONS:
		var camera: Camera2D = create_camera_at_position(test_pos, camera_script)
		assert_pixel_aligned(camera, "camera at position %s" % str(test_pos))

## Test zoom compatibility
func test_zoom_compatibility(camera_script: Script = PixelPerfectTestConstants.CameraFollower) -> void:
	var setup: CameraSetup = create_camera_with_parent(camera_script)
	setup.set_position(Vector2(648.753, 424.159))
	
	for zoom in PixelPerfectTestConstants.ZOOM_LEVELS:
		setup.camera.zoom = Vector2(zoom, zoom)
		setup.update_camera()
		
		assert_pixel_aligned(setup.camera, "camera at zoom %.1f" % zoom)

## Test jitter reduction for algorithm
func test_algorithm_jitter(algorithm: String, expected_threshold: float) -> void:
	var camera = Camera2D.new()
	camera.script = PixelPerfectTestConstants.CameraFollowerStable
	camera.pixel_perfect = true
	camera.algorithm = algorithm
	
	var parent = Node2D.new()
	add_child(parent)
	auto_free(parent)
	parent.add_child(camera)
	
	var jitter_sum: float = PixelPerfectTestConstants.calculate_jitter(camera, parent)
	assert_jitter_within_threshold(jitter_sum, expected_threshold, algorithm)

#endregion

#region Integration Testing

## Test with demo scene integration
func test_demo_scene_integration(demo_scene: PackedScene, expected_camera_path: String) -> void:
	var scene_instance = demo_scene.instantiate()
	add_child(scene_instance)
	auto_free(scene_instance)
	
	# Find camera in demo scene
	var camera = scene_instance.get_node(expected_camera_path)
	
	# Verify pixel perfect camera is loaded
	assert_object(camera.get_script()).is_not_null() \
		.append_failure_message("Camera should have a script attached")
	
	assert_bool(camera.pixel_perfect).is_true() \
		.append_failure_message("Camera should have pixel_perfect enabled")
	
	# Test pixel alignment with fractional movement
	# Use get_node() for fail-fast behavior - PlayerBuilder should exist in demo scenes
	var player_node = scene_instance.get_node("World/PlayerBuilder")
	player_node.global_position = Vector2(648.753, 424.159)
	
	await get_tree().process_frame
	
	assert_pixel_aligned(camera, "demo scene camera")

#endregion

#region Edge Case Testing

## Test zero position handling
func test_zero_position(camera_script: Script = PixelPerfectTestConstants.CameraFollower) -> void:
	var camera: Camera2D = create_camera_at_position(Vector2.ZERO, camera_script)
	
	var position = camera.global_position
	assert_float(position.x).is_equal(0.0) \
		.append_failure_message("Camera X should be exactly 0 at zero position")
	
	assert_float(position.y).is_equal(0.0) \
		.append_failure_message("Camera Y should be exactly 0 at zero position")

## Test negative position handling
func test_negative_positions(camera_script: Script = PixelPerfectTestConstants.CameraFollower) -> void:
	var test_pos = Vector2(-100.753, -200.159)
	var camera: Camera2D = create_camera_at_position(test_pos, camera_script)
	assert_pixel_aligned(camera, "camera at negative position %s" % str(test_pos))

#endregion

#endregion
