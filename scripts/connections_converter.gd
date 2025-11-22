# --- HOWTO ---
# COPY THIS CODE INTO CONNECTION SETTERS, REMOVE queue_free FROM _ready FUNCTION,
# RELOAD SCENE, THEN SET convert_connections IN INSPECTOR UNTIL CONVERSION IS DONE
# Once done, detach the connections setters script
@tool
extends Node
var converted : int = 0
@export var step : int = 10
@export var convert_connections : bool = false:
	set(_u):
		if "connections" not in self:
			push_error("Connections not found, cannot convert")
			return
		if self.connections.is_empty():
			return
		var region_control : RegionControl = get_tree().edited_scene_root as RegionControl
		if not region_control:
			push_error("Could not find RegionControl")
			return
		if converted >= self.connections.size():
			print("Conversion done.")
			return
		var i : int = 0
		while converted < self.connections.size():
			var connection = self.connections[converted]
			var power_reduction = 0
			if connection.size() >= 3: power_reduction = connection[2]
			var region_from : Node = region_control.get_node(connection[0])
			var region_to : Node = region_control.get_node(connection[1])
			var link : RegionLink = RegionLink.new()
			add_child(link)
			link.set_owner(region_control)
			link.from_name = region_from.name
			link.to_name = region_to.name
			link.power_reduction = power_reduction
			link._generate_name()
			converted += 1
			i += 1
			if i >= step:
				print("One step done, ", converted)
				return
@export var reset : bool = false:
	set(_u):
		converted = 0
		print("Reset")
func _ready():
	if not Engine.is_editor_hint():
		push_error("You forgot to detach the connection convertor script!")
