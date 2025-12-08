@tool
extends EditorPlugin
## Pixel Perfect Camera Plugin
##
## Provides pixel-perfect camera functionality for Godot 4.x projects.
## This plugin ensures cameras snap to whole pixels, eliminating sub-pixel jitter.
##
## Usage:
## 1. Enable this plugin in Project Settings > Plugins
## 2. Add a Camera2D node as a child of your player/character
## 3. Attach the pixel_perfect_camera_2d.gd script to the Camera2D
## 4. Enable the pixel_perfect property in the inspector
##
## The camera will automatically follow its parent and snap to whole pixels,
## preventing the jittery appearance that occurs with sub-pixel positioning.


func _enter_tree() -> void:
	# Plugin initialization
	# The pixel_perfect_camera_2d.gd script can be attached manually to Camera2D nodes
	pass


func _exit_tree() -> void:
	# Cleanup when plugin is disabled
	pass


func _get_plugin_name() -> String:
	return "Pixel Perfect Camera"


func _get_plugin_icon() -> Texture2D:
	# Return the Godot editor's Camera2D icon as default
	return EditorInterface.get_editor_theme().get_icon("Camera2D", "EditorIcons")
