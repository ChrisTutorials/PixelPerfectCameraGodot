## Camera Diagnostic Overlay - Objectively measures camera jitter
## Add this as a CanvasLayer child to visualize camera movement metrics
extends CanvasLayer

@export var camera: Camera2D

var label: Label
var last_position: Vector2 = Vector2.ZERO
var movement_history: Array[float] = []
const HISTORY_SIZE: int = 60
var frame_count: int = 0


func _ready() -> void:
	label = Label.new()
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)

	if camera:
		last_position = camera.global_position


func _physics_process(_delta: float) -> void:
	if not camera:
		label.text = "No camera assigned!"
		return

	frame_count += 1
	var current_pos: Vector2 = camera.global_position
	var movement: Vector2 = current_pos - last_position
	var movement_magnitude: float = movement.length()

	movement_history.append(movement_magnitude)
	if movement_history.size() > HISTORY_SIZE:
		movement_history.pop_front()

	var jitter_score: float = _calculate_jitter()
	var variance: float = _calculate_variance()
	var avg_movement: float = _calculate_average()
	var max_movement: float = _calculate_max()
	var is_sub_pixel: bool = fmod(current_pos.x, 1.0) != 0.0 or fmod(current_pos.y, 1.0) != 0.0
	var vsync_enabled: bool = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	var is_moving: bool = movement_magnitude > 0.5

	label.text = (
		"""CAMERA DIAGNOSTICS [Frame %d]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Position: (%.3f, %.3f)
Fractional: (%.3f, %.3f)
Movement: %.3f px/frame %s
Avg: %.3f | Max: %.3f
Jitter Score: %.2f %s
Variance: %.4f
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sub-pixel: %s %s
V-Sync: %s %s
FPS: %.1f / %.1f (physics)
Process: PHYSICS_PROCESS ✓
Camera Mode: %s
"""
		% [
			frame_count,
			current_pos.x,
			current_pos.y,
			fmod(current_pos.x, 1.0),
			fmod(current_pos.y, 1.0),
			movement_magnitude,
			"🔴" if is_moving else "⏸️",
			avg_movement,
			max_movement,
			jitter_score,
			"⚠️ JITTER!" if jitter_score > 0.5 else "✓",
			variance,
			"YES" if is_sub_pixel else "NO",
			"⚠️" if is_sub_pixel else "✓",
			"ON" if vsync_enabled else "OFF",
			"✓" if vsync_enabled else "⚠️",
			Engine.get_frames_per_second(),
			Engine.physics_ticks_per_second,
			(
				"PHYSICS"
				if camera and camera.process_callback == Camera2D.CAMERA2D_PROCESS_PHYSICS
				else "IDLE"
			)
		]
	)

	# Color feedback
	if jitter_score > 0.5:
		label.add_theme_color_override("font_color", Color.RED)
	elif is_sub_pixel:
		label.add_theme_color_override("font_color", Color.ORANGE)
	elif not vsync_enabled:
		label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		label.add_theme_color_override("font_color", Color.GREEN)

	last_position = current_pos


func _calculate_average() -> float:
	if movement_history.is_empty():
		return 0.0
	var sum: float = 0.0
	for val: float in movement_history:
		sum += val
	return sum / float(movement_history.size())


func _calculate_max() -> float:
	if movement_history.is_empty():
		return 0.0
	var max_val: float = 0.0
	for val: float in movement_history:
		if val > max_val:
			max_val = val
	return max_val


func _calculate_variance() -> float:
	if movement_history.size() < 10:
		return 0.0

	var avg: float = _calculate_average()
	var variance: float = 0.0
	for val: float in movement_history:
		var diff: float = val - avg
		variance += diff * diff

	return variance / float(movement_history.size())


func _calculate_jitter() -> float:
	if movement_history.size() < 10:
		return 0.0

	# Only measure jitter when there's significant movement
	# Count how many frames had movement above threshold
	const MOVEMENT_THRESHOLD: float = 0.5
	var moving_frames: int = 0
	var moving_values: Array[float] = []

	for val: float in movement_history:
		if val > MOVEMENT_THRESHOLD:
			moving_frames += 1
			moving_values.append(val)

	# Not enough movement data to measure jitter
	if moving_frames < 5:
		return 0.0

	# Calculate variance only from frames that were actually moving
	var avg: float = 0.0
	for val: float in moving_values:
		avg += val
	avg /= float(moving_values.size())

	var variance: float = 0.0
	for val: float in moving_values:
		var diff: float = val - avg
		variance += diff * diff

	variance /= float(moving_values.size())
	var std_dev: float = sqrt(variance)

	# Jitter score: how much movement varies relative to average
	# 0.0 = perfectly smooth, 1.0 = extremely inconsistent
	return min(std_dev / avg, 1.0)
