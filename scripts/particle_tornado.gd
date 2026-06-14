extends Node2D
class_name ParticleTornado


var tornado_id: int = 0
var active: bool = false


func take_region(region: Region, timer: float = 0.5) -> void:
	if not region:
		return
	if active:
		create_tween().tween_property(self, "position", region.position, timer)
	else:
		active = true
		position = region.position
		$Anim.play("Emerge")


func deactivate() -> bool:
	if active:
		active = false
		$Anim.play("Hide")
		return true
	return false
