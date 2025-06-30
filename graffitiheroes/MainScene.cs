using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Runtime.CompilerServices;
using Godot;
using Vector2 = Godot.Vector2;

public partial class MainScene : Node2D
{
	private PathFollow2D _follower;
	private Sprite2D _sprite;
	private Path2D _path;
	private RichTextLabel _text;
	private Area2D _canvas;
	private Area2D _mouseArea; //is always at the mouse position
	private TextureRect _sprayCan;
	private double _lastTextUpdate; // Added for text update timing

	private Random random = new();
	private string[] curves;
	private HashSet<string> unusedEasy = [];
	private HashSet<string> unusedMedium = [];
	private HashSet<string> unusedHard = [];

	public static readonly int[] StarThresholds = { 540, 625, 680, 740, 800 };

	private void tweenSprayCan()
	{
		ShaderMaterial mat = (ShaderMaterial) _sprayCan.GetMaterial();
		Tween t = CreateTween();
		t.TweenProperty(mat, "shader_parameter/water_level_percentage", inkLeft / (float)inkStartedWith, 0.2f).FromCurrent();
		t.TweenCallback(Callable.From(tweenSprayCan));
	}
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		_follower = GetNode<PathFollow2D>("Path2D/PathFollow2D");
		_sprite = GetNode<Sprite2D>("Path2D/PathFollow2D/Sprite2D");
		_path = GetNode<Path2D>("Path2D");
		_text = GetNode<RichTextLabel>("Control/RichTextLabel");
		_canvas = GetNode<Area2D>("canvas/Area2D");
		_mouseArea = GetNode<Area2D>("hitbox");
		_sprayCan = GetNode<TextureRect>("Spray_Can");
		Area2D overlapArea = GetNode<Area2D>("Path2D/PathFollow2D/Sprite2D/OverlapArea");
		overlapArea.AreaEntered += (area) =>
		{
			_currentOverlaps.Add(area);
			canPlaceDot = false;
		};
		overlapArea.AreaExited += (area) =>
		{
			_currentOverlaps.Remove(area);
			if (_currentOverlaps.Count == 0) canPlaceDot = true;
		};
		init();
		tweenSprayCan();
		//get all curve resource names
		unusedEasy = new HashSet<string>(ResourceLoader.ListDirectory("res://curves/easy"));
		unusedMedium = new HashSet<string>(ResourceLoader.ListDirectory("res://curves/medium"));
		unusedHard = new HashSet<string>(ResourceLoader.ListDirectory("res://curves/hard"));
		//random curve
		NextCurve();
	}

	void NextCurve()
	{
		currentRound++;
		if (currentRound <= 4)// Easy
		{
			string curveName = unusedEasy.ElementAt(random.Next(unusedEasy.Count));
			unusedEasy.Remove(curveName);
			_path.Curve = ResourceLoader.Load<Curve2D>("res://curves/easy/" + curveName);
			GetNode<RichTextLabel>("RoundLabel").Text = "Round " + currentRound + "/7\nEasy";
		}else if (currentRound <= 6) // Medium
		{
			string curveName = unusedMedium.ElementAt(random.Next(unusedMedium.Count));
			unusedMedium.Remove(curveName);
			_path.Curve = ResourceLoader.Load<Curve2D>("res://curves/medium/" + curveName);
			GetNode<RichTextLabel>("RoundLabel").Text = "Round " + currentRound + "/7\nMedium";
		}
		else // Hard
		{
			string curveName = unusedHard.ElementAt(random.Next(unusedHard.Count));
			unusedHard.Remove(curveName);
			_path.Curve = ResourceLoader.Load<Curve2D>("res://curves/hard/" + curveName);
			GetNode<RichTextLabel>("RoundLabel").Text = "Round " + currentRound + "/7\nHard";
		}
	}

	public double totalAccumulatedScore = 0;  

	public static float DrawRate = 0.01f; //100 new dots per second
	private double _lastUpdated;
	private double _elapsed;
	private string state;
	private List<Sprite2D> _drawnSprites = [];
	private List<Sprite2D> _sprites = [];
	private static int _drawSpeed = 1000; // pixels per second
	private static double _finishWaitTime = 1; // seconds to wait after drawing
	private double _finishTimer;
	private int inkLeft = 1;
	private int inkStartedWith = 1;
	private int totalEarnedStars = 0;
	private int potentialStars = 0;
	private int potentialPoints = 0;
	private int currentRound = 0;
	private bool canPlaceDot = true;
	private HashSet<Area2D> _currentOverlaps = [];
	

	private float _judgingProgress = 0; //progresratio amount

	private static readonly float _possiblePoints = 1000;
	private float _earnedPoints = 0;

	private float _judgeSpeed = 500f; // pixels per second during judging
	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		if (_elapsed == 0)
		{
			_elapsed += delta;
			return; //we chuck the first frame because uhh umm uhh yeah huh right well yep
		}
		_elapsed += delta;
		if (state == "drawing")
		{
			float curveLength = _path.Curve.GetBakedLength();
			if (_follower.Progress + _drawSpeed * delta < curveLength) 
				_follower.Progress += (float)(_drawSpeed * delta);
			else
			{
				_follower.Progress = 1;
				state = "drawing_finished";
			}
			//drop a sprite there
			Sprite2D dot = (Sprite2D) _sprite.Duplicate();
			AddChild(dot);
			dot.GlobalPosition = _follower.GlobalPosition;
			_sprites.Add(dot);
		}
		else if (state == "drawing_finished")
		{
			// Show instruction text
			_text.Text = "Press SPACE to start drawing";
			_text.Show();
			
			// Wait for player to press a button instead of using a timer
			if (Input.IsActionJustPressed("ui_accept"))
			{
				_text.Text = "Mouse to draw, SPACE when finished.";
				
				Tween t = CreateTween();
				t.SetParallel();
				foreach (Sprite2D sprite in _sprites)
				{
					t.TweenProperty(sprite, "modulate", Colors.Transparent, 1.2f);
				}
				//calculate how much ink the player needs based on the curve length
				float curveLength = _path.Curve.GetBakedLength();
				float inkNeeded = curveLength / 13.2f; // 13.2 pixels per ink unit
				inkLeft = (int) Math.Ceiling(inkNeeded);
				inkStartedWith = (int) Math.Ceiling(inkNeeded);
				foreach (Sprite2D sprite in _sprites)
				{
					sprite.GetNode<Area2D>("OverlapArea").QueueFree();
				}
				_currentOverlaps.Clear();
				state = "player";
			}
		}
		else if (state == "player")
		{
			if (inkLeft <= 0) GetNode<RichTextLabel>("Spray_Can/NoMoreInk").Show();
			_sprite.GlobalPosition = GetGlobalMousePosition();
			if (Input.IsMouseButtonPressed(MouseButton.Left))
			{
				if (_canvas.GetOverlappingAreas().Count >= 1 && _currentOverlaps.Count == 0)
				{
					if (inkLeft > 0 && canPlaceDot)
					{
						var dot = (Sprite2D)_sprite.Duplicate();
						dot.GlobalPosition = GetGlobalMousePosition();
						AddChild(dot);
						_drawnSprites.Add(dot);
						_lastUpdated = _elapsed;
						inkLeft--;
						canPlaceDot = false; // prevent placing more dots until the area is cleared, assumes the area is entered. if it isn't we have a big problem
					}
				}
			}

			if (Input.IsActionJustPressed("ui_accept"))
			{
				GetNode<RichTextLabel>("Spray_Can/NoMoreInk").Hide();
				//begin judging
				state = "judging";
				_lastUpdated = _elapsed; 
				_sprite.Hide();
				//unhide all the template sprites
				foreach (Sprite2D sprite in _sprites)
				{
					sprite.Show();
					sprite.Modulate = new Color(0, 160, 50, 0.5f);
				}
			}
		}else if (state == "judging")
		{
			float curveLength = _path.Curve.GetBakedLength();
			float judgeStepSize = curveLength / _possiblePoints;
			float judgePixelsPerFrame = _judgeSpeed * (float)delta; // pixels per frame
			int steps = (int)(judgePixelsPerFrame / judgeStepSize); // How many pixel steps to take this frame
			if (steps < 1) steps = 1; // Always take at least one step
			
			for (int i = 0; i < steps; i++)
			{
				//optimistically find distance to closest point
				float min = float.MaxValue;
				Vector2 minVec = GetViewportRect().Size / 2; //if you see lines drawing to the center, you know something went wrong
				foreach (var drawnSprite in _drawnSprites)
				{
					float distance = _follower.GlobalPosition.DistanceTo(drawnSprite.GlobalPosition);
					if (distance < min)
					{
						min = distance;
						minVec = drawnSprite.GlobalPosition;
					}
				}
				Console.WriteLine("Distance: " + min);
				float earnedPoint = 10 / min;
				Color c = Colors.Red.Lerp(Colors.Green, earnedPoint);
				Line2D line = new Line2D();
				AddChild(line);
				line.DefaultColor = c;
				line.AddPoint(_follower.GlobalPosition);
				line.AddPoint(minVec);
				line.SetName("_judgeLine " + _elapsed + " #"+ i);
				_earnedPoints += float.Min(earnedPoint, 1);
				
				if (_follower.Progress + judgeStepSize < curveLength) 
					_follower.Progress += judgeStepSize; // Move 1 pixel at a time
				else {
					_follower.Progress = curveLength;
					break;
				}
				Console.WriteLine("Score is now " + _earnedPoints);
			}
			
			// Update text every 0.1 seconds
			if (_elapsed - _lastTextUpdate >= 0.1)
			{
				UpdateText(_earnedPoints);
				_lastTextUpdate = _elapsed;
			}

			if (_follower.Progress >= curveLength)
			{
				state = "judging_finished";
				Console.Write("Finished judging in " + (_elapsed - _lastUpdated) + "s. Score is "  + _earnedPoints);
				// Use UpdateText function here instead of duplicating code
				UpdateText(_earnedPoints);
				_text.Text += "\nPress SPACE to continue";
				totalAccumulatedScore += _earnedPoints;
				totalEarnedStars += GetEarnedStars(_earnedPoints);
				potentialPoints += (int) _possiblePoints;
				potentialStars += StarThresholds.Length;
			}
		}else if (state == "judging_finished")
		{
			if (Input.IsActionJustPressed("ui_accept"))
			{
				if (currentRound == 7) // Max rounds: 7
				{
					GD.Print("Game finished");
					PackedScene gameOverScene = ResourceLoader.Load<PackedScene>("res://game_over.tscn");
					GameOver scene = gameOverScene.Instantiate<GameOver>();
					scene.Initialize((float) totalAccumulatedScore, totalEarnedStars, potentialStars);
					GetTree().Root.AddChild(scene);
					GetTree().CurrentScene.QueueFree();
					GetTree().CurrentScene = scene;
				}
				else
				{
					NextCurve();
					init();
				}
			}
		}
	}

	int GetEarnedStars(float score)
	{
		int stars = 0;
		for (int i = 0; i < StarThresholds.Length; i++)
		{
			if (score >= StarThresholds[i])
			{
				stars++;
			}
			else
			{
				break;
			}
		}
		return stars;
	}

	void UpdateText(float score)
	{
		_text.Text = "Score: [color=green]" + (int) Math.Round(score) + "[/color]\n";
		int earnedStars = GetEarnedStars(score);
		for(int i= 0; i<earnedStars; i++)
		{
			_text.Text += "[img=60x60]res://images/color_star.png[/img]";
		}
		//add empty stars
		for (int i = earnedStars; i < StarThresholds.Length; i++)
		{
			_text.Text += "[img=60x60]res://images/star_empty.png[/img]";
		}
		_text.Show();
	}

	void init()
	{
		_text.Hide();
		foreach (Sprite2D sprite in _sprites)
		{
			sprite.QueueFree();
		}
		foreach (Sprite2D sprite in _drawnSprites)
		{
			sprite.QueueFree();
		}
		//clear all nodes that start with _
		foreach (Node child in GetChildren())
		{
			if (child.Name.ToString().StartsWith('_'))
			{
				GD.Print("Removing child: " + child.Name);
				child.QueueFree();
			}
		}

		canPlaceDot = true;
		inkLeft = 1;
		inkStartedWith = 1;
		_currentOverlaps.Clear();
		_sprites.Clear();
		_sprite.Position = Vector2.Zero;
		_drawnSprites.Clear();
		_sprite.Show();
		_follower.Progress = 0;
		_lastUpdated = 0f;
		_elapsed = 0;
		state = "drawing";
		_earnedPoints = 0;
	}

	public override void _PhysicsProcess(double delta)
	{
		_mouseArea.GlobalPosition = GetGlobalMousePosition();
	}
}
