## Pixel-perfect camera follower using parent's fractional offset correction
## Camera is a CHILD of the player node - it automatically follows via parent transform
## But applies a local offset to counteract parent's fractional position for pixel snapping
extends Camera2D

## Enable pixel-perfect positioning to prevent sub-pixel jitter
@export var pixel_perfect: bool = true


func _ready() -> void:
	# Camera should update AFTER player's physics
	# Use IDLE mode so camera updates in _process() after physics completes
	process_callback = Camera2D.CAMERA2D_PROCESS_IDLE

	# Disable position smoothing for pixel-perfect movement
	# Smoothing can cause sub-pixel interpolation which creates jitter
	position_smoothing_enabled = false

	# Make this camera the active one
	enabled = true

	# Initialize camera offset immediately
	_update_pixel_snap_offset()


func _process(_delta: float) -> void:
	# Update in _process() which runs AFTER _physics_process()
	# This ensures we read the player's updated position
	if pixel_perfect:
		_update_pixel_snap_offset()


func _update_pixel_snap_offset() -> void:
	# Get parent's position (the player we're following)
	var parent := get_parent()
	if not parent:
		return

	# Calculate fractional offset correction
	# This counteracts the parent's fractional position to snap camera to whole pixels
	# Example: parent at (648.753, 424.159)
	# → fractional parts (0.753, 0.159)
	# → camera local position = (-0.753, -0.159)
	# → camera global = parent + local = (648.753, 424.159) + (-0.753, -0.159) = (648.0, 424.0) ✓
	var parent_pos: Vector2 = parent.global_position
	var fractional: Vector2 = Vector2(fmod(parent_pos.x, 1.0), fmod(parent_pos.y, 1.0))
	position = -fractional
