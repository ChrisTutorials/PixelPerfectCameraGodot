## PixelPerfectCamera2D
## Robust pixel-perfect camera solution for Godot 4
## Eliminates jitter by snapping the final camera position to integers
## This extends the base Camera2D, allowing you to use all built-in drag and smoothing features
## 
## USAGE:
## - For direct follow: Leave drag margins disabled (default behavior)
## - For smooth drag: Enable drag_horizontal_enabled/drag_vertical_enabled in inspector
## - Pixel snapping works automatically in both modes
##
## LOGGING BEST PRACTICES:
## - Use PackedStringArray + single print() instead of consecutive print statements
## - Format strings with %s and array interpolation for cleaner output
## - Call debug_status() for comprehensive camera state information
class_name PixelPerfectCamera2D
extends Camera2D

## Snap method options for pixel-perfect positioning
enum SnapMethod {
	## Standard mathematical rounding
	## Best for: General purpose, balanced behavior
	## Example: 50.4 → 50, 50.5 → 51, 50.6 → 51
	ROUND,
	
	## Always round down to previous integer
	## Best for: Preventing objects from going past screen edges
	## Example: 50.1 → 50, 50.5 → 50, 50.9 → 50
	FLOOR,
	
	## Always round up to next integer
	## Best for: Maximum screen coverage, aggressive follow
	## Example: 50.1 → 51, 50.5 → 51, 50.9 → 51
	CEIL,
}

# --- Configuration ---

## Enable pixel-perfect behavior
@export var pixel_perfect: bool = true

## Method used to snap coordinates to integers
@export var snap_method: SnapMethod = SnapMethod.ROUND

func _ready() -> void:
	# CRITICAL: Run after the engine's internal Camera2D process to capture final positions
	# Camera2D updates its transform in the internal process
	process_priority = 100
	
	# We rely on standard Camera2D behavior, so we don't detach (top_level = false)
	# and we don't disable built-in drag or smoothing.

func _process(delta: float) -> void:
	if not pixel_perfect or not enabled:
		return
	
	var parent: Node = get_parent()
	if not parent or not (parent is Node2D):
		return
		
	# 1. Update Camera2D position to follow parent if needed
	# This works WITH built-in drag margins, not against them
	if not drag_horizontal_enabled and not drag_vertical_enabled:
		# No drag margins - direct follow
		global_position = parent.global_position
	# If drag margins are enabled, Camera2D handles following automatically
	
	# 2. Snap the Global Position to Grid (Rendering Layer)
	# This ensures the camera ALWAYS sits on an integer pixel
	var target_global_pos = global_position
	var snapped_pos := Vector2.ZERO
	
	match snap_method:
		SnapMethod.ROUND:
			snapped_pos = target_global_pos.round()
		SnapMethod.FLOOR:
			snapped_pos = target_global_pos.floor()
		SnapMethod.CEIL:
			snapped_pos = target_global_pos.ceil()
			
	# 3. Apply to Camera
	# This slightly adjusts the camera for this frame to align with pixels
	# It does not break the internal drag logic because the delta is < 1px
	global_position = snapped_pos
	
	# 4. Force Engine Update
	# This prevents one-frame lag artifacts by committing the scroll immediately
	force_update_scroll()

## Debug function - outputs camera status in a single log
func debug_status() -> void:
	var status_lines: PackedStringArray = []
	status_lines.append("PixelPerfectCam Status:")
	status_lines.append("  Global Pos (Snapped): %s" % global_position)
	
	var parent = get_parent()
	if parent is Node2D:
		status_lines.append("  Parent Pos: %s" % parent.global_position)
		status_lines.append("  Delta: %s" % (parent.global_position - global_position))
	
	status_lines.append("  Built-in Drag: H=%s, V=%s" % [drag_horizontal_enabled, drag_vertical_enabled])
	status_lines.append("  Built-in Smoothing: %s" % position_smoothing_enabled)
	
	print("\n".join(status_lines))
