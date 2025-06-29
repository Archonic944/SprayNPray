using Godot;
using System;
using System.Net.Mime;

public partial class GameOver : Node2D
{
	private Button _restartButton;
	public override void _Ready()
	{
		_restartButton = GetNode<Button>("Control/Button");
		_restartButton.Pressed += OnRestartButtonPressed;
		
	}

	private void OnRestartButtonPressed()
	{
		GD.Print("Restarting game...");
		GetTree().ChangeSceneToFile("res://main_scene.tscn");
		GD.Print("Game state reset.");
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}

	public void Initialize(float finalScore, int earnedStars, int potentialStars)
	{
		RichTextLabel text = GetNode<RichTextLabel>("Control/RichTextLabel");
		text.Text = "Your Score: [color=green]" + (int)Math.Round(finalScore) + "[/color]\n" +
		            "Stars Collected: [color=yellow]" + earnedStars + "[/color] / [color=yellow]" + potentialStars +
		            "[/color]";
	}
}
