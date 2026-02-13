## PixelPerfectCamera2D Unit Tests
##
## Behavior verified:
## - Pixel-perfect correction is applied via `offset` (not by overwriting `global_position`).
## - The correction matches the intended formula: `round(global_position) - global_position` plus any centering offset.
## - `use_physics_process` gates when the correction runs (process vs physics), since update-cycle mismatch is a primary source of jitter.
extends GdUnitTestSuite

func _create_camera(use_physics: bool) -> PixelPerfectCamera2D:
	var camera: PixelPerfectCamera2D = PixelPerfectCamera2D.new()
	camera.use_physics_process = use_physics
	camera.pixel_perfect = true
	add_child(camera)
	return camera

func test_apply_pixel_perfect_sets_offset_to_snapped_position() -> void:
	var camera: PixelPerfectCamera2D = _create_camera(true)
	await get_tree().process_frame

	camera.global_position = Vector2(100.25, 200.75)
	camera.zoom = Vector2.ONE
	camera._refresh_scaling_cache()
	camera._apply_pixel_perfect()

	var current_position: Vector2 = camera.global_position
	var expected_snapped: Vector2 = current_position.round()
	var expected_centering: Vector2 = camera._compute_centering_offset(camera._viewport_size, camera._visible_rect, camera.zoom)

	var expected_offset: Vector2 = (expected_snapped - current_position) + expected_centering
	assert_vector(camera.offset).is_equal(expected_offset)

func test_use_physics_process_true_applies_in_physics_only() -> void:
	var camera: PixelPerfectCamera2D = _create_camera(true)
	await get_tree().process_frame

	camera.global_position = Vector2(10.25, 10.25)
	camera.zoom = Vector2.ONE
	camera._refresh_scaling_cache()
	camera.offset = Vector2.ZERO

	camera._process(0.0)
	assert_vector(camera.offset).is_equal(Vector2.ZERO)

	camera._physics_process(0.0)
	assert_vector(camera.offset).is_not_equal(Vector2.ZERO)

func test_use_physics_process_false_applies_in_process_only() -> void:
	var camera: PixelPerfectCamera2D = _create_camera(false)
	await get_tree().process_frame

	camera.global_position = Vector2(10.25, 10.25)
	camera.zoom = Vector2.ONE
	camera._refresh_scaling_cache()
	camera.offset = Vector2.ZERO

	camera._physics_process(0.0)
	assert_vector(camera.offset).is_equal(Vector2.ZERO)

	camera._process(0.0)
	assert_vector(camera.offset).is_not_equal(Vector2.ZERO)
