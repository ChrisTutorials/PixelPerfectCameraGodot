## Pixel Perfect Camera Test Constants
## Centralized UID preloads and test configuration for pixel perfect camera tests
class_name PixelPerfectTestConstants

#region UID Preloads

## Camera follower script - main pixel perfect implementation
const CameraFollower = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")

## Camera diagnostics overlay - jitter visualization and debugging
const CameraDiagnostics = preload("res://addons/pixel_perfect_camera/camera_diagnostics.gd")

## Stable camera follower - alternative implementation with reduced jitter
const CameraFollowerStable = preload("res://addons/pixel_perfect_camera/pixel_perfect_camera_2d.gd")

#endregion

#region Test Configuration

## Default test positions for pixel alignment validation
const TEST_POSITIONS: Array[Vector2] = [
	Vector2(100.1, 200.1), # Should round to (100, 200)
	Vector2(100.6, 200.6), # Should round to (101, 201)
	Vector2(100.49, 200.49), # Should round to (100, 200)
	Vector2(100.51, 200.51), # Should round to (101, 201)
	Vector2(648.753, 424.159), # Complex fractional position
	Vector2.ZERO, # Zero position edge case
	Vector2(-100.753, -200.159) # Negative position edge case
]

## Zoom levels for compatibility testing
const ZOOM_LEVELS: Array[float] = [1.0, 2.0, 3.0, 4.0]

## Pixel alignment tolerance for assertions
const PIXEL_TOLERANCE: float = 0.001

## Jitter tolerance thresholds for different algorithms
const STABLE_JITTER_THRESHOLD: float = 2.0
const PRECISE_JITTER_THRESHOLD: float = 5.0

## Movement pattern parameters for stability testing
const MOVEMENT_AMPLITUDE_X: float = 50.7
const MOVEMENT_AMPLITUDE_Y: float = 30.3
const MOVEMENT_STEPS: int = 20

#endregion

#region Demo Scene References

## Top-down demo scene path for integration testing
const DEMO_TOP_DOWN_SCENE: PackedScene = preload("res://demos/top_down/demo_top_down.tscn")

## Platformer demo scene path for integration testing
const DEMO_PLATFORMER_SCENE: PackedScene = preload("res://demos/platformer/demo_platformer.tscn")

## Pixel perfect demo scene path
const DEMO_PIXEL_PERFECT_SCENE: PackedScene = preload("res://demos/camera/pixel_perfect_demo.tscn")

#endregion

#region Assertion Helpers

## Validate that a position is pixel-aligned (within tolerance)
static func is_pixel_aligned(position: Vector2, tolerance: float = PIXEL_TOLERANCE) -> bool:
	var x_fraction = fmod(position.x, 1.0)
	var y_fraction = fmod(position.y, 1.0)
	return x_fraction <= tolerance and y_fraction <= tolerance

## Get pixel alignment error for a position
static func get_alignment_error(position: Vector2) -> Vector2:
	return Vector2(fmod(position.x, 1.0), fmod(position.y, 1.0))

## Format alignment error for assertion messages
static func format_alignment_error(position: Vector2) -> String:
	var error: Vector2 = get_alignment_error(position)
	return "Position (%.3f, %.3f) has alignment error (%.3f, %.3f)" % [
		position.x, position.y, error.x, error.y
	]

#endregion

#region Test Environment Setup

## Create a standard pixel perfect camera for testing
static func create_pixel_perfect_camera() -> Camera2D:
	var camera = Camera2D.new()
	camera.script = CameraFollower
	camera.pixel_perfect = true
	return camera

## Create a stable algorithm camera for testing
static func create_stable_camera() -> Camera2D:
	var camera = Camera2D.new()
	camera.script = CameraFollowerStable
	camera.pixel_perfect = true
	camera.algorithm = "stable"
	return camera

## Create a precise algorithm camera for testing
static func create_precise_camera() -> Camera2D:
	var camera = Camera2D.new()
	camera.script = CameraFollowerStable
	camera.pixel_perfect = true
	camera.algorithm = "precise"
	return camera

## Create camera diagnostics overlay
static func create_diagnostics(camera: Camera2D) -> CanvasLayer:
	var diagnostics = CameraDiagnostics.new()
	diagnostics.camera = camera
	return diagnostics

#endregion

#region Performance Testing

## Calculate jitter sum for movement pattern
static func calculate_jitter(camera: Camera2D, parent: Node2D, steps: int = MOVEMENT_STEPS) -> float:
	var jitter_sum = 0.0
	var last_pos = Vector2.ZERO
	
	for i in range(steps):
		var movement_time = i * 0.1
		parent.global_position = Vector2(
			640 + sin(movement_time) * MOVEMENT_AMPLITUDE_X,
			360 + cos(movement_time) * MOVEMENT_AMPLITUDE_Y
		)
		
		if camera.has_method("_update_pixel_snap_offset"):
			camera._update_pixel_snap_offset()
		
		var current_pos = camera.global_position
		if last_pos != Vector2.ZERO:
			jitter_sum += current_pos.distance_to(last_pos)
		last_pos = current_pos
	
	return jitter_sum

#endregion
