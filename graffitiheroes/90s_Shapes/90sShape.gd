extends Sprite2D

@export var rotation_speed: float = 0.02

@onready var shadow: Sprite2D = $Shadow

	# Shapes to choose from, I just dragged them here from the file system with CTRL held
var rnd_png: Array[CompressedTexture2D] = [
	preload("uid://drbdtlokhlkuh"),
	preload("uid://du6clcwgxvdci"),
	preload("uid://cdpksxtp5axqj"),
	preload("uid://rd5x3kiqavsq")
]

	# Random colos
var colors: Array[Color] = [
	Color.BLUE, Color.YELLOW, Color.ORANGE, Color.GREEN, Color.PINK, Color.PURPLE, Color.AQUA
]


func _ready() -> void:
		# Random texture from array (Shape_1-Shape_4)
	texture = rnd_png.pick_random()
	shadow.texture = texture
	
		# Random color from array
	self_modulate = colors.pick_random()
	
		# Bring shadow to position
	shadow.global_position = global_position + Vector2.ONE * 10.0


func _physics_process(_delta: float) -> void:
	global_rotation += rotation_speed
	shadow.global_rotation = global_rotation
