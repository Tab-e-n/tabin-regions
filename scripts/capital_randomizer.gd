extends Node
class_name CapitalRandomizer


@export var capitals_per_player: int = 1
@export var region_control: RegionControl = null


func _on_region_control_used_alignments_chosen(used_alignments: Array):
	if not region_control:
		push_warning("Capital Randomizer needs to have region_control set to function.")
		return
	
	var capitals: Array[Region] = region_control.get_all_capitals()
	
	capitals.shuffle()
	
	for alignment in used_alignments:
		for i in range(capitals_per_player):
			var capital: Region = capitals.pop_back() as Region
			if capital:
				region_control.overtake_region(capital.name, alignment, true)
			else:
				push_warning("Ran out of capitals to give to alignments.")
				break
