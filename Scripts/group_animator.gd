extends Node2D
class_name GroupAnimator


@export var animating_objects : Array[NodePath] = []
var keys : Array = []


func _ready():
	for path in animating_objects:
		var node : Node2D = get_node(path) as Node2D
		if node:
			var key_node : Node2D = Node2D.new()
			key_node.position = node.position - position
			add_child(key_node)
			keys.append([key_node, node])
	
	animating_objects.clear()


func update_object_positions():
	for pairs in keys:
		pairs[1].global_position = pairs[0].global_position

func update_object_scale():
	for pairs in keys:
		pairs[1].scale = pairs[0].scale
