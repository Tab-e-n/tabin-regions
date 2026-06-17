extends Node

var current_directory: String = "res://maps"
var current_map_name: String = ""
var current_pack_name: String = "Base Maps"

var player_amount: int = 1
var default_digital_player: DPControl.CONTROLER = DPControl.CONTROLER.DEFAULT

var aliances_amount: int = 0

var used_alignments: int = 0

var preset_alignments: Array[int] = []


func print_map_data():
	print(current_map_name)
	print("Players: ", player_amount)
	print("Default DP: ", default_digital_player)
	print("Aliances: ", aliances_amount)
	print("Used Aligns: ", used_alignments)
	print("Preset Aligns: ", preset_alignments)

