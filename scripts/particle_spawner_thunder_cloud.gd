extends Node2D


const CLOUD_DISTANCE_COVERED : float = 1024

@export var enabled : bool = true
@export var time_range_bottom : float = 8
@export var time_range_top : float = 24

@export_category("DecorCloud")
@export var speed : float = 16
@export var rarity : int = 49
@export var rare_cloud : DecorCloud.CLOUD_TYPE = DecorCloud.CLOUD_TYPE.NO_PREFERENCE
@export var color_cloud : Color = Color(1, 1, 1, 1)

@export_category("DecorElec")
@export var bolt_time_range_bottom : float = 3
@export var bolt_time_range_top : float = 5
@export var point_amount_bot : int = 3
@export var point_amount_top : int = 6
@export var elec_count_bot : int = 1
@export var elec_count_top : int = 2
@export var jump_lenght : Vector2 = Vector2(48, 48)
@export var time_between : float = 0.05
@export var color_bolt : Color = Color(1, 1, 1, 1)


var packed_cloud : PackedScene = preload("res://objects/particle_thunder_cloud.tscn")
var timer : float = 0

@onready var cloud_offset : Vector4
@onready var game_camera : GameCamera


func _ready():
	cloud_offset.x = -ProjectSettings.get_setting("display/window/size/viewport_width") * 0.4 + CLOUD_DISTANCE_COVERED * 0.5
	cloud_offset.y = ProjectSettings.get_setting("display/window/size/viewport_width") * 0.4 + CLOUD_DISTANCE_COVERED * 0.5
	cloud_offset.z = -ProjectSettings.get_setting("display/window/size/viewport_height") * 0.4
	cloud_offset.w = ProjectSettings.get_setting("display/window/size/viewport_height") * 0.4
	
	position = Vector2(0, 0)
	if get_tree().current_scene is GameControl:
		var game_control : GameControl = get_tree().current_scene as GameControl
		game_camera = game_control.game_camera
	else:
		queue_free()


func _process(delta):
	if enabled:
		timer -= delta
	if timer <= 0:
		timer = randf_range(time_range_bottom, time_range_top)
		var thunder : DecorThunderCloud = packed_cloud.instantiate() as DecorThunderCloud
		thunder.speed = CLOUD_DISTANCE_COVERED / DecorCloud.CLOUD_DURATION
		thunder.color_cloud = color_cloud
		if game_camera:
			thunder.position.x = randf_range(game_camera.farthest_left + cloud_offset.x, game_camera.farthest_right + cloud_offset.y)
			thunder.position.y = randf_range(game_camera.farthest_up + cloud_offset.z, game_camera.farthest_down + cloud_offset.w)
		thunder.rarity = rarity
		thunder.rare_cloud = rare_cloud
		
		thunder.time_range_bottom = bolt_time_range_bottom
		thunder.time_range_top = bolt_time_range_top
		thunder.point_amount_bot = point_amount_bot
		thunder.point_amount_top = point_amount_top
		thunder.elec_count_bot = elec_count_bot
		thunder.elec_count_top = elec_count_top
		thunder.jump_lenght = jump_lenght
		thunder.time_between = time_between
		thunder.color_bolt = color_bolt
		
		add_child(thunder)
