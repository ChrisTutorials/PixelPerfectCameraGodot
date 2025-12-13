## PixelPerfectCamera2D
## A Camera2D that ensures pixel-perfect positioning by rounding to whole pixels.
## This prevents jittering/stuttering in pixel-art games caused by sub-pixel positioning.
##
## For best results:
## - Use PhysicsProcess mode (default) when following objects that move in _physics_process
## - Use Process mode when following objects that move in _process
## The camera must update in the same cycle as the target to avoid jitter.
##
## Behavior:
## - **Pixel-perfect output**: each update snaps the camera to whole pixels by applying a correction via `offset`.
## - **Non-invasive**: does not overwrite `global_position` (avoids fighting Camera2D follow, smoothing, or RemoteTransform2D).
## - **Update-cycle correctness**: must run in the same cycle as the followed target to avoid jitter.
##   - If the target moves in `_physics_process`, keep `use_physics_process = true`.
##   - If the target moves in `_process`, set `use_physics_process = false`.
## - **Viewport scaling support**: compensates for viewport->window scaling when centering.
class_name PixelPerfectCamera2D
extends Camera2D

## Enable pixel-perfect behavior.
@export var pixel_perfect: bool = true

## Which update cycle to use for applying the pixel-perfect offset.
## Must match the followed target's update cycle.
@export var use_physics_process: bool = true

var _viewport_size: Vector2
var _window_size: Vector2
var _scale_factor: Vector2
var _visible_rect: Rect2


## Initializes process mode and caches viewport/window metrics used for pixel-perfect correction.
## Must run after the node is inside a viewport.
func _ready() -> void:
	# Configure which process mode to use.
	set_process(not use_physics_process)
	set_physics_process(use_physics_process)

	# Use drag center for proper following.
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER

	_refresh_scaling_cache()


## Applies pixel-perfect correction during `_process` when `use_physics_process` is disabled.
func _process(_delta: float) -> void:
	if not use_physics_process:
		_apply_pixel_perfect()


## Applies pixel-perfect correction during `_physics_process` when `use_physics_process` is enabled.
func _physics_process(_delta: float) -> void:
	if use_physics_process:
		_apply_pixel_perfect()


## Refreshes cached viewport/window data.
## Uses `Viewport.get_visible_rect()` so windowed-mode / letterboxed configurations are accounted for.
func _refresh_scaling_cache() -> void:
	_viewport_size = get_viewport_rect().size
	_window_size = DisplayServer.window_get_size()
	_scale_factor = _window_size / _viewport_size
	_visible_rect = get_viewport().get_visible_rect()


## Computes the world-space offset needed to keep the visible area centered.
## `visible_rect.position` is non-zero when the viewport is letterboxed/pillarboxed inside the window.
func _compute_centering_offset(viewport_size: Vector2, visible_rect: Rect2, camera_zoom: Vector2) -> Vector2:
	var viewport_center: Vector2 = viewport_size / 2.0
	var visible_center: Vector2 = visible_rect.position + (visible_rect.size / 2.0)
	return (visible_center - viewport_center) / camera_zoom


## Rounds the final camera position to whole pixels and applies the correction via `offset`.
## Does not overwrite `global_position` to avoid fighting follow/smoothing/RemoteTransform2D.
func _apply_pixel_perfect() -> void:
	if not pixel_perfect or not enabled:
		return

	# Get the current position (after built-in Camera2D behavior).
	var current_position: Vector2 = global_position

	# Round to whole pixels.
	var pixel_perfect_position: Vector2 = current_position.round()

	# Account for viewport/window scaling when centering.
	var centering_offset: Vector2 = _compute_centering_offset(_viewport_size, _visible_rect, zoom)

	# Apply correction via Offset so we don't fight follow/smoothing/RemoteTransform2D.
	offset = (pixel_perfect_position - current_position) + centering_offset
