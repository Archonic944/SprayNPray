using Godot;
using System;

public partial class TitleScreen : Node2D
{
	private Button _button;

	private Sprite2D sprite;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		_button = GetNode<Button>("Control/Button");
		_button.Pressed += OnButtonPressed;
		sprite = GetNode<Sprite2D>("Sprite2D");
	}
	
	private void OnButtonPressed()
	{
		// Load the main scene when the button is pressed
		GetTree().ChangeSceneToFile("res://main_scene.tscn");
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		//scroll the noise resource within the sprite
		var texture = sprite.Texture as NoiseTexture2D;
		if (texture != null)
		{
			// Update the offset of the noise texture to create a scrolling effect
			var noise = texture.GetNoise() as FastNoiseLite;
			if (noise == null) return;
			noise.Offset += new Vector3(0.1f * (float)delta, 0.1f * (float) delta, 0);
			texture.SetNoise(noise);
			sprite.SetTexture(texture);
		}
		else
		{
			GD.PrintErr("Sprite texture is not a NoiseTexture2D.");
		}
	}
}
