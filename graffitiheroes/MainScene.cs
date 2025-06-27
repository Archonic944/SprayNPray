using Godot;
using System;
using System.Collections.Generic;
using System.Numerics;
using System.Runtime.CompilerServices;
using Godot;
using Vector2 = Godot.Vector2;

public partial class MainScene : Node2D
{
	private PathFollow2D _follower;
	private Sprite2D _sprite;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		_follower = GetNode<PathFollow2D>("Path2D/PathFollow2D");
		_follower.ProgressRatio = 0;
		_sprite = GetNode<Sprite2D>("Path2D/PathFollow2D/Sprite2D");
		
	}

	public static float DrawRate = 0.02f; //100 new dots per second
	private double _lastUpdated = 0;
	private double _elapsed = 0f;
	private string state = "drawing";
	private List<Sprite2D> _drawnSprites = [];
	private double _drawSpeed = 0.5f;
	private double _finishWaitTime = 1; // seconds to wait after drawing
	private double _finishTimer = 0;

	private float _judgingProgress = 0; //progresratio amount

	private static readonly float _possiblePoints = 1000;
	private float _earnedPoints = 0;

	private float _judgeTime = 2; //seconds
	private float _judgePathStep = 1f/_possiblePoints;
	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		_elapsed += delta;
		if (state == "drawing")
		{

			if (_elapsed - _lastUpdated > DrawRate || _elapsed == 0)
			{
				Console.WriteLine("Updating");
				var duplicate = (Sprite2D)_sprite.Duplicate();
				duplicate.GlobalPosition = _follower.GlobalPosition;
				AddChild(duplicate);
				_lastUpdated = _elapsed;
				_drawnSprites.Add(duplicate);
			}
			if (_follower.ProgressRatio + _drawSpeed * delta < 1) _follower.ProgressRatio += (float) _drawSpeed * (float)delta;
			else
			{
				Console.WriteLine("Finished");
				Console.WriteLine(_follower.ProgressRatio + 0.2f * delta);
				_follower.ProgressRatio = 0;
				state = "drawing_finished";
				_finishTimer = 0;
			}
		}
		else if (state == "drawing_finished")
		{
			_finishTimer += delta;
			if (_finishTimer >= _finishWaitTime)
			{
				foreach (var drawnSprite in _drawnSprites)
				{
					drawnSprite.QueueFree();
				}
				_drawnSprites.Clear();
				state = "player";
			}
		}
		else if (state == "player")
		{
			_sprite.GlobalPosition = GetGlobalMousePosition();
			if (_elapsed - _lastUpdated > DrawRate && Input.IsMouseButtonPressed(MouseButton.Left))
			{
				var dot = (Sprite2D)_sprite.Duplicate();
				dot.GlobalPosition = GetGlobalMousePosition();
				AddChild(dot);
				_drawnSprites.Add(dot);
				_lastUpdated = _elapsed;
			}

			if (Input.IsActionJustPressed("ui_accept"))
			{
				//begin judging
				state = "judging";
				_lastUpdated = _elapsed; 
				_sprite.Hide();
			}
		}else if (state == "judging")
		{
			short steps = (short)(delta / (_judgeTime / _possiblePoints)); //how many full steps we get to do
			for (int i = 0; i < steps; i++)
			{

				//optimistically find distance to closest point
				float min = float.MaxValue;
				foreach (var drawnSprite in _drawnSprites)
				{
					float distance = _follower.GlobalPosition.DistanceTo(drawnSprite.GlobalPosition);
					if (distance < min) min = distance;
				}
				Console.WriteLine("Distance: " + min);
				_earnedPoints += float.Min(10 / min, 1);
				if (_follower.ProgressRatio + _judgePathStep < 1) _follower.ProgressRatio += _judgePathStep;
				else {
					_follower.ProgressRatio = 1;
					break;
				}
				Console.WriteLine("Score is now " + _earnedPoints);
			}

			if (_follower.ProgressRatio + _judgePathStep > 1)
			{
				state = "judging_finished";
				Console.Write("Finished judging in " + (_elapsed - _lastUpdated) + "s. Score is "  + _earnedPoints);
			}
		}else if (state == "judging_finished")
		{
			//who knows
		}
	}
}
