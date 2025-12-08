## Stable Pixel-perfect camera follower
## Combines the stability of the original algorithm with submodule benefits
## Camera is a CHILD of the player node - it automatically follows via parent transform
## But applies a local offset to counteract parent's fractional position for pixel snapping
extends Camera2D

## Enable pixel-perfect positioning to prevent sub-pixel jitter
@export var pixel_perfect: bool = true

## Algorithm choice: "stable" (old) or "precise" (new)
@export var algorithm: String = "stable"

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
	
	var parent_pos: Vector2 = parent.global_position
	
	match algorithm:
		"stable":
			# Original stable algorithm (like the old custom script)
			# This was more predictable for character following
			var rounded_parent_pos: Vector2 = parent_pos.round()
			position = rounded_parent_pos - parent_pos
			
		"precise":
			# New precise algorithm using fmod()
			# Mathematically cleaner but can cause jitter in some cases
			var fractional: Vector2 = Vector2(fmod(parent_pos.x, 1.0), fmod(parent_pos.y, 1.0))
			position = - fractional
			
		"hybrid":
			# Hybrid approach: use stable for movement, precise for static
			# This gives the best of both algorithms
			var velocity: Vector2 = _get_parent_velocity()
			if velocity.length() > 1.0:
				# Moving: use stable algorithm for smooth following
				var rounded_parent_pos: Vector2 = parent_pos.round()
				position = rounded_parent_pos - parent_pos
			else:
				# Static: use precise algorithm for perfect alignment
				var fractional: Vector2 = Vector2(fmod(parent_pos.x, 1.0), fmod(parent_pos.y, 1.0))
				position = - fractional
		
		_:
			# Default to stable for character following
			var rounded_parent_pos: Vector2 = parent_pos.round()
			position = rounded_parent_pos - parent_pos

func _get_parent_velocity() -> Vector2:
	# Estimate parent velocity for hybrid algorithm
	# This is a simple implementation - could be enhanced with actual velocity tracking
	var parent := get_parent()
	if not parent:
		return Vector2.ZERO
	
	# For now, return zero (will default to stable algorithm)
	# In a real implementation, you'd track position changes over time
	return Vector2.ZERO

## Debug function to compare algorithms
func debug_compare_algorithms() -> void:
	var parent := get_parent()
	if not parent:
		return
	
	var parent_pos: Vector2 = parent.global_position
	
	# Stable algorithm
	var stable_result = parent_pos.round() - parent_pos
	
	# Precise algorithm  
	var fractional = Vector2(fmod(parent_pos.x, 1.0), fmod(parent_pos.y, 1.0))
	var precise_result = - fractional
	
	print("Parent pos: ", parent_pos)
	print("Stable offset: ", stable_result, " → Global: ", parent_pos + stable_result)
	print("Precise offset: ", precise_result, " → Global: ", parent_pos + precise_result)
	print("Difference: ", stable_result - precise_result)
