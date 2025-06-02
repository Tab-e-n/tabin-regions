extends TextureButton


@export_multiline var text : String = """default text"""

@onready var label : Label = $text
@onready var anim : AnimationPlayer = $anim

@export_category("Developer")
@export var custom_shader : bool = false
@export var shader_light : ShaderMaterial = null
@export var shader_dark : ShaderMaterial = null

func _ready():
	label.text = text
	if custom_shader:
		pass
	elif self_modulate.v > RegionControl.COLOR_TOO_BRIGHT:
		material = shader_dark
	else:
		material = shader_light


func _on_toggled(down):
	if down:
		anim.play("appear")
	else:
		anim.play("disappear")
