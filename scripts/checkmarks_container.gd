extends Container


func _on_sort_children():
	var width: float = 0.0
	for node in get_children():
		var control: Control = node as Control
		if control:
			width += control.size.x * control.scale.x
	
	var overlap: float = (width - size.x) / (get_child_count() - 1)
	if overlap < 8:
		overlap = 8
	
	var current_position: float = size.x - overlap
	for node in get_children():
		var control: Control = node as Control
		if not control:
			continue
		current_position -= control.size.x * control.scale.x
		current_position += overlap
		control.position.x = current_position
		if control.size.y * control.scale.y < size.y:
			control.position.y = (size.y - control.size.y * control.scale.y) # * 0.5
