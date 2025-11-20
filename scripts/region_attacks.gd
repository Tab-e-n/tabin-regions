extends Node2D
class_name RegionAttacks


@onready var label : RichTextLabel = $Label


func change_text(colors : Array[Color], values : Array[int]) -> void:
	label.clear()
	if colors.size() != values.size():
		push_warning("Incorrectly inputted RegionAttacks colors or values.")
		return
	
	var text : String = ""
	for i in range(colors.size()):
		var color = colors[i]
		var value = values[i]
		var text_color : Color = RegionControl.text_color(color.v)
		text += "[cell][bgcolor=#" + colors[i].to_html() + "]" + \
				"[color=#" + text_color.to_html() + "] " + \
				String.num(value) + " [/color][/bgcolor][/cell]"
	text = "[center][table=" + String.num(colors.size()) + "]" + text + "[/table][/center]"
#	print(text)
	label.append_text(text)


func text_size() -> Vector2:
	return label.size
