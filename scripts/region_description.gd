extends Node2D
class_name RegionDescription


@onready var attacks : RichTextLabel = $Attacks
@onready var region_name : Label = $Name


func city_texture_offset(is_capital : bool) -> Vector2:
	return City.CAPITAL_TEXTURE_SIZE if is_capital else City.CITY_TEXTURE_SIZE


func attacks_position(is_capital : bool) -> void:
	attacks.position.x = -attacks.size.x
	attacks.position.y = city_texture_offset(is_capital).y
	attacks.position *= attacks.scale * 0.5


func update_attacks(colors : Array[Color], values : Array[int]) -> void:
	attacks.clear()
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
	attacks.append_text(text)


func update_name(region : Region):
	region_name.text = region.name + " (" + str(region.max_power) + ")"
	if Options.editor:
		region_name.text += " (" + str(region.distance_from_capital) + ")"
	region_name.size = region_name.get_theme_font("font").get_string_size(region_name.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 32) * region_name.scale
	region_name.position = region_name.size * Vector2(-0.5, -1.0) * region_name.scale
	region_name.position.y += -city_texture_offset(region.is_capital).y * region_name.scale.y
