using Godot;
using System;

public partial class GraffitiButton : Node2D
{
	[Export] public string Text { get; set; } = "Click Me";
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		var button = GetNode<Button>("Button");
		button.Text = Text;
		button.MouseEntered += () =>
		{
			GetNode<Sprite2D>("Sprite2D").Hide();
			GetNode<Sprite2D>("Sprite2D2").Show();
		};
		button.MouseExited += () =>
		{
			GetNode<Sprite2D>("Sprite2D").Show();
			GetNode<Sprite2D>("Sprite2D2").Hide();
		};
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
	
	public void addPressedListener(Action action)
	{
		var button = GetNode<Button>("Button");
		button.Pressed += action;
	}
}
