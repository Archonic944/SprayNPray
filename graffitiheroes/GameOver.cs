using Godot;
using System;

public partial class GameOver : Control
{
	private int totalScore;
	private int totalEarnedStars;
	private int potentialStars;
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		GetNode<GraffitiButton>("GraffitiButton").addPressedListener(() =>
		{
			GetTree().ChangeSceneToFile("res://main_scene.tscn");
		});
		GetNode<RichTextLabel>("ScoreText").Text = $"Total Score: {(int)totalScore}\nStars: {totalEarnedStars}/{potentialStars}";
	}

	public void Initialize(float score, int totalEarnedStars, int potentialStars)
	{
		this.totalEarnedStars = totalEarnedStars;
		this.potentialStars = potentialStars;
		this.totalScore = (int)score;
		GetNode<RichTextLabel>("ScoreText").Text = $"Total Score: {(int)totalScore}\nStars: {totalEarnedStars}/{potentialStars}";
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
}
