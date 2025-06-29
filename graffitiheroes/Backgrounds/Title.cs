using Godot;
using System;

public partial class Title : Control
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		GetNode<GraffitiButton>("GraffitiButton").addPressedListener(() =>
		{
			GetTree().ChangeSceneToFile("res://main_scene.tscn");
		});
	}
}
