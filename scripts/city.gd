extends TextureButton
class_name City

@export var is_capital : bool = false

@onready var region : Region = get_parent()

var text : Label = Label.new()
var region_name : Label = Label.new()

var was_hovered : bool = false
var offset : Vector2

func _ready():
	if region.hide_capital:
		visible = false
	
	if is_capital:
		texture_normal = preload("res://sprites/capital.png")
		offset = Vector2(40, 40)
	else:
		texture_normal = preload("res://sprites/city.png")
		offset = Vector2(32, 32)
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
	text.add_theme_font_size_override("font_size", offset.x * 1.2)
	text.scale = Vector2(0.5, 0.5)
	add_child(text)
	
	region_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	region_name.visible = false
	region_name.z_index = 2
	
	region_name.add_theme_font_size_override("font_size", 32)
	region_name.scale = Vector2(0.5, 0.5)
	region_name.clip_contents = true
	update_region_name()
	
	region_name.add_theme_stylebox_override("normal", preload("res://styles/style_label_city_name.tres"))
	add_child(region_name)


func _process(_delta):
	text.text = String.num(region.power)
	if not region.hide_capital and region.region_control:
		visible = region.region_control.cities_visible
	if region.region_control and not region.region_control.dummy:
		if was_hovered != is_hovered():
			was_hovered = is_hovered()
			if was_hovered:
				show_attacks()
			else:
				hide_attacks()
			region_name.visible = is_hovered()
		
		if Input.is_action_just_pressed("show_extra") and region.power > 1:
			if Input.is_action_pressed("shift"):
				if region.region_control.current_playing_align != region.alignment and not region.region_control.alignment_neutral(region.alignment):
					make_particle(true)
			else:
				if region.region_control.current_playing_align == region.alignment:
					make_particle(true)


func update_region_name():
	region_name.text = region.name + " (" + String.num(region.max_power) + ")"
	if OS.has_feature("editor"):
		region_name.text += " (" + String.num(region.distance_from_capital) + ")"
	region_name.size = region_name.get_theme_font("font").get_string_size(region_name.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	region_name.position = Vector2((offset.x - region_name.size.x * 0.5 - 4), -offset.y)


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


func show_attacks():
	if region.region_control and not region.region_control.dummy:
		region.region_control.game_camera.call_deferred("show_attacks", region)


func hide_attacks():
	if region.region_control and not region.region_control.dummy:
		region.region_control.game_camera.hide_attacks()
