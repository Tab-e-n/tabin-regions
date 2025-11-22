extends TextureButton
class_name City


const CITY_TEXTURE_SIZE = Vector2(64, 64)
const CAPITAL_TEXTURE_SIZE = Vector2(80, 80)


@export var is_capital : bool = false

@onready var region : Region = get_parent()

var text : Label = Label.new()

var was_hovered : bool = false
var offset : Vector2

func _ready():
	visible = not region.hide_capital
	
	if is_capital:
		texture_normal = preload("res://sprites/capital.png")
		offset = CAPITAL_TEXTURE_SIZE * 0.5
	else:
		texture_normal = preload("res://sprites/city.png")
		offset = CITY_TEXTURE_SIZE * 0.5
	
	z_index = 20
	
	var city_size : float = 0.8
	if region.region_control:
		city_size = region.region_control.city_size * 0.8
	position = offset * -city_size
	scale = Vector2(city_size, city_size)
	
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.size = offset * 4
	text.z_index = 1
	text.add_theme_font_size_override("font_size", (int)(offset.x * 1.2))
	text.scale = Vector2(0.5, 0.5)
	add_child(text)
	
	_on_power_changed(region.power)
	
	if RegionControl.active(region.region_control):
		Options.timestamp(" -- " + region.name + " city ready", "Cities")


func _process(_delta):
	visible = region._city_visible()
	if was_hovered != is_hovered():
		was_hovered = is_hovered()
		if was_hovered:
			show_description()
		else:
			hide_description()


func color_self(new_color : Color):
	self_modulate = new_color
	text.self_modulate = RegionControl.text_color(new_color.v)


func make_particle(mobilize : bool):
	var part : Sprite2D = Sprite2D.new()
	part.set_script(preload("res://scripts/particle_city_selected.gd"))
	part.texture = preload("res://sprites/circle.png")
	part.position = offset
	part.set_color(self_modulate)
	part.mobilize = mobilize
	add_child(part)


func show_description():
	if RegionControl.active(region.region_control):
		region.region_control.show_region_description.call_deferred(region)


func hide_description():
	if RegionControl.active(region.region_control):
		region.region_control.hide_region_description()


func _on_power_changed(power : int) -> void:
	text.text = String.num(power)


func _on_end_turn():
	if not Options.action_change_particles:
		return
	if not region.region_control.is_player_controled:
		return
	if is_capital and region.alignment == region.region_control.current_playing_align:
		var part : Node2D = preload("res://objects/particle_number.tscn").instantiate()
		part.color = self_modulate
		part.text = "+1"
		add_child(part)


func _on_show_extra_current(alignment : int):
	if alignment == region.alignment and region.power > 1:
		make_particle(true)


func _on_show_extra_other(alignment : int):
	if region.region_control and region.region_control.alignment_inactive(region.alignment):
		return
	if alignment != region.alignment and region.power > 1:
		make_particle(true)
