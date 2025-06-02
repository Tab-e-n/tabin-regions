extends Polygon2D


@export var speed : Vector2 = Vector2(0, 0)
@export var edges_x : Vector2 = Vector2(0, 0)
@export var edges_y : Vector2 = Vector2(0, 0)


func _process(delta):
	position += speed * delta
	if position.x < edges_x.x:
		position.x = edges_x.y
	if position.x > edges_x.y:
		position.x = edges_x.x
	if position.y < edges_y.x:
		position.y = edges_y.y
	if position.y > edges_y.y:
		position.y = edges_y.x
