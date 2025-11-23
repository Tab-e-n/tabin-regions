extends Line2D


@export var color : Color = Color.WHITE
@export var size : float = 1


func _draw():
	for p in points:
		draw_circle(p, size, color)
