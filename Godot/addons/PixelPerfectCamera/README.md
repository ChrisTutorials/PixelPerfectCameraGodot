# PixelPerfectCamera (Godot 4, C#)

`PixelPerfectCamera2D` is a `Camera2D` implementation that helps eliminate visible jitter in pixel-art games by ensuring the final camera positioning resolves to whole pixels.

## What it does

- Snaps the camera result to whole pixels to avoid sub-pixel jitter
- Works alongside Godot's built-in `Camera2D` smoothing features
- Accounts for viewport/window scaling so the followed target remains truly centered

## Installation

Copy this folder into your Godot project:

- `res://addons/PixelPerfectCamera/`

Then rebuild your C# solution (if your editor doesn’t do it automatically).

## Usage

1. Add a `Camera2D` node to your scene.
2. Attach `PixelPerfectCamera2D.cs` to the node.
3. Make the camera current.
4. (Optional) Enable and tune smoothing using the built-in `Camera2D` properties.

### Update cycle (important)

`PixelPerfectCamera2D` exposes:

- `UsePhysicsProcess` (default `true`)

Guideline:

- Use `true` when following characters that move in `_PhysicsProcess` (common for `CharacterBody2D`).
- Use `false` when following targets that move in `_Process`.

The camera should update in the same cycle as the followed target to prevent jitter.

## Files

- `PixelPerfectCamera2D.cs`

