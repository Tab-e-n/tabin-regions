extends Node2D
class_name DecorThunderCloud


@export var speed : float = 16
@export var rarity : int = 49
@export var rare_cloud : int = -1
@export var color_cloud : Color = Color(1, 1, 1, 1)

@export var time_range_bottom : float = 3
@export var time_range_top : float = 5
@export var point_amount_bot : int = 3
@export var point_amount_top : int = 6
@export var elec_count_bot : int = 1
@export var elec_count_top : int = 2
@export var jump_lenght : Vector2 = Vector2(48, 48)
@export var direction : Vector2 = Vector2(0, 1)
@export var time_between : float = 0.05
@export var color_bolt : Color = Color(1, 1, 1, 1)

@onready var cloud : DecorCloud = $Cloud as DecorCloud

var packed_elec : PackedScene = preload("res://Objects/elec_decor.tscn")


var timer : float = 0.0


func _ready():
	cloud.speed = speed
	cloud.rarity = rarity
	cloud.rare_cloud = rare_cloud
	cloud.self_modulate = color_cloud
	
	timer = time_range_bottom


func _process(delta):
	timer -= delta
	if timer <= 0:
		if not cloud:
			return
		timer = randf_range(time_range_bottom, time_range_top)
		var elec_pos : Vector2 = Vector2(0, 0)
		elec_pos = cloud.position
		var elec_count = randi_range(elec_count_bot, elec_count_top)
		for i in range(elec_count):
			var elec : DecorElec = packed_elec.instantiate() as DecorElec
			elec.modulate = color_bolt
			elec.point_amount = randi_range(point_amount_bot, point_amount_top)
			elec.jump_lenght = jump_lenght
			elec.direction = direction
			elec.time_between = time_between
			elec.position = elec_pos
			add_child(elec)
