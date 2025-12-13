using Godot;

/// <summary>
/// <para>
/// A Camera2D that ensures pixel-perfect positioning by rounding to whole pixels.
/// This prevents jittering/stuttering in pixel-art games caused by sub-pixel positioning.
/// </para>
/// <para>
/// Use Camera2D's built-in position_smoothing_enabled and position_smoothing_speed for smooth following.
/// This script handles pixel-perfect rounding and viewport centering accounting for window/viewport scaling.
/// </para>
/// <para>
/// For best results:
/// - Use PhysicsProcess mode (default) when following characters that move in _PhysicsProcess (e.g., CharacterBody2D, RigidBody2D)
/// - Use Process mode if following objects that move in _Process
/// - The camera must sync with the same update cycle as the target to avoid jitter
/// </para>
/// <para>
/// VIEWPORT CENTERING:
/// When viewport size differs from window size (e.g., 1280x720 viewport in 1920x1080 window),
/// this camera accounts for the scaling to ensure the target remains truly centered.
/// </para>
/// </summary>
[GlobalClass]
public partial class PixelPerfectCamera2D : Camera2D {
  /// <summary>
  /// Which process mode to use for camera updates.
  /// - PhysicsProcess (default): Use when following objects that move in _PhysicsProcess (e.g., CharacterBody2D, RigidBody2D)
  /// - Process: Use when following objects that move in _Process
  /// The camera must update in the same cycle as the target to prevent jitter.
  /// </summary>
  [Export]
  public bool UsePhysicsProcess { get; set; } = true;

  private Vector2 _viewportSize;
  private Vector2 _windowSize;
  private Vector2 _scaleFactor;

  public override void _Ready() {
    // Configure which process mode to use
    SetProcess(!UsePhysicsProcess);
    SetPhysicsProcess(UsePhysicsProcess);

    // Set anchor mode to drag center for proper following
    AnchorMode = AnchorModeEnum.DragCenter;

    // Calculate viewport and window scaling
    _viewportSize = GetViewportRect().Size;
    _windowSize = DisplayServer.WindowGetSize();
    _scaleFactor = _windowSize / _viewportSize;

    GD.Print($"[PixelPerfectCamera2D] Viewport: {_viewportSize}, Window: {_windowSize}, Scale: {_scaleFactor}");
  }

  public override void _Process(double delta) {
    if (!UsePhysicsProcess) {
      ApplyPixelPerfect();
    }
  }

  public override void _PhysicsProcess(double delta) {
    if (UsePhysicsProcess) {
      ApplyPixelPerfect();
    }
  }

  /// <summary>
  /// Apply pixel-perfect rounding to the camera position.
  /// Accounts for viewport/window scaling when centering.
  /// </summary>
  private void ApplyPixelPerfect() {
    // Get the current position (after RemoteTransform2D and built-in smoothing)
    var currentPosition = GlobalPosition;

    // Round to whole pixels to prevent jitter
    var pixelPerfectPosition = currentPosition.Round();

    // Account for viewport/window scaling when centering
    // If viewport is smaller than window (e.g., 1280x720 in 1920x1080),
    // we need to adjust the camera position to account for the upscaling
    var centeringOffset = Vector2.Zero;

    // Only apply centering correction if there's a scale mismatch
    if (_scaleFactor != Vector2.One) {
      // Calculate the true viewport center in world space
      // The viewport center should be at _viewportSize / 2
      var viewportCenter = _viewportSize / 2.0f;

      // When scaled, the actual center point shifts
      // We need to offset the camera to compensate
      // The offset needed is (scaleFactor - 1) * viewportCenter / Zoom
      centeringOffset = (_scaleFactor - Vector2.One) * viewportCenter / Zoom;
    }

    // Apply the pixel-perfect offset with centering correction
    // We use Offset instead of setting Position to avoid fighting with RemoteTransform2D
    Offset = pixelPerfectPosition - currentPosition + centeringOffset;
  }
}
