extends Sprite2D
class_name DecorCloud


enum CLOUD_TYPE {
	NO_RARE_CLOUDS = -2,
	NO_PREFERENCE = -1,
	SONIC_RUNNER,
	PIXELATED,
	SELF_REFERENCE,
	SNOOZY,
	BOTCH,
	KING_OF_THE_CANVAS,
	GOOBER,
	ONLY_SECRET_CLOUDS,
}

const CLOUD_DURATION : float = 64
const CLOUDS : Array[Texture2D] = [
	preload("res://sprites/cloud_0.png"),
	preload("res://sprites/cloud_1.png"),
	preload("res://sprites/cloud_2.png"),
	preload("res://sprites/cloud_3.png"),
	preload("res://sprites/cloud_4.png"),
	preload("res://sprites/cloud_5.png"),
	preload("res://sprites/cloud_6.png"),
	preload("res://sprites/cloud_7.png"),
	preload("res://sprites/cloud_8.png"),
	preload("res://sprites/cloud_9.png"),
]
const SECRET_CLOUDS : Array[Texture2D] = [
	preload("res://sprites/cloud_secret_0.png"),
	preload("res://sprites/cloud_secret_1.png"),
	preload("res://sprites/cloud_secret_2.png"),
	preload("res://sprites/cloud_secret_3.png"),
	preload("res://sprites/cloud_secret_4.png"),
	preload("res://sprites/cloud_secret_5.png"),
	preload("res://sprites/cloud_secret_6.png"),
]

@export var speed : float = 16
@export var rarity : int = 49
@export var rare_cloud : CLOUD_TYPE = CLOUD_TYPE.NO_PREFERENCE


func _ready():
	if rare_cloud == CLOUD_TYPE.NO_RARE_CLOUDS or randi_range(0, rarity):
		var r : int = randi_range(0, CLOUDS.size() - 1)
		texture = CLOUDS[r]
	elif rare_cloud >= 0 and rare_cloud < SECRET_CLOUDS.size():
		texture = SECRET_CLOUDS[rare_cloud]
	else:
		var r : int = randi_range(0, SECRET_CLOUDS.size() - 1)
		texture = SECRET_CLOUDS[r]
	var f : int = randi_range(0, 3)
	@warning_ignore("integer_division")
	flip_h = f / 2
	flip_v = f % 2
	$shadow.self_modulate = self_modulate
	$shadow.texture = texture
	$shadow.flip_h = flip_h
	$shadow.flip_v = flip_v
	$anim.play("Cloud")


func _process(delta):
	position.x -= delta * speed


func _on_anim_animation_finished(_anim_name):
	get_parent().remove_child(self)
	queue_free()
