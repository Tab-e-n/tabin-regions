extends DigitalPlayer


var cheater : bool = false
var cheated : bool = false


func start_turn(align : int):
	super.start_turn(align)
	cheated = false
	if controler.region_control != null:
		if cheater and controler.region_control.current_turn % 6 == 0:
			controler.CALL_cheat = true


func think_bonus():
	think_normal()


func think_normal():
	if controler.get_action_amount() == 0:
		controler.CALL_change_current_phase = true
		return
	
#	print("think default first")
	var eligable_regions : Array = []
	
	var friendly_regions : Array = controler.get_owned_regions()
	
	if controler.aliances_on():
		friendly_regions.append_array(controler.get_allied_regions())
	
#	print(current_alignment)
	for region in friendly_regions:
#		print("FROM: ", region.name)
		var in_threat : bool = false
		for connection in region.connections:
			var target : Region = connection.get_other_region(region)
			if not target:
				continue
#			print("--> ", target.name)
			if controler.alignment_friendly(current_alignment, target.alignment):
#				print("friendly alignment")
				continue
			if not controler.alignment_inactive(target.alignment):
				in_threat = true
#				print("align ", connection.alignment)
			if region.alignment != current_alignment:
#				print("allies region, cannot attack through")
				continue
			if not target.incoming_attack(current_alignment, 0, true):
#				print("cannot attack")
				continue
			eligable_regions.append(target)
		if in_threat and region.power != region.max_power:
			eligable_regions.append(region)
	
#	print(eligable_regions)
	
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	if eligable_regions.size() > 0:
		controler.selected_capital = eligable_regions[0].name
		var highest_benefit : int = calculate_benefit_default(eligable_regions.pop_front())
		var lowest_distance : int
		var results : Array = []
		for region in eligable_regions:
			var benefit : int = calculate_benefit_default(region)
			var distance = region.distance_from_capital
			if benefit > highest_benefit or (benefit == highest_benefit and distance < lowest_distance):
				results = [region.name]
				highest_benefit = benefit
				lowest_distance = distance
			elif benefit == highest_benefit:
				results.append(region.name)
#				highest_benefit = benefit
#				lowest_distance = distance
		if results:
			controler.selected_capital = results[rng.randi_range(0, results.size() - 1)]
	else:
		for region in controler.get_owned_regions():
			if region.power != region.max_power:
				eligable_regions.append(region)
		if eligable_regions.size() > 0:
			controler.selected_capital = eligable_regions[rng.randi_range(0, eligable_regions.size() - 1)].name
		else:
			controler.CALL_change_current_phase = true
	
#	print(controler.selected_capital)


func think_mobilize():
	var no_more_extra : bool = true
	for region in controler.get_owned_regions():
		var threat : int = determine_attacks(region)
		if threat >= 1 and region.power > 1 and not region.name in controler.get_current_moves():
			controler.selected_capital = region.name
			no_more_extra = false
			break
#	print("think default mobilize")
	if no_more_extra:
		if controler.get_bonus_action_amount() == 0:
			controler.CALL_end_turn = true
		else:
			if cheater and not cheated and controler.region_control.current_turn % 6 == 0:
				controler.CALL_cheat = true
				cheated = true
			else:
				controler.CALL_change_current_phase = true


func calculate_benefit_default(region : Region):
	var action_amount : int = controler.get_action_amount()
	var benefit : int = 0
	if controler.alignment_friendly(current_alignment, region.alignment):
		var threat : int = determine_attacks(region)
		if threat < -action_amount:
			benefit = -region.power - 1
		if threat == -action_amount:
			if region.is_capital and region.power != region.max_power:
				benefit += 4
		if threat >= -action_amount:
			@warning_ignore("integer_division")
			benefit += region.power / 2
		if region.alignment != current_alignment:
			benefit -= 1
	else:
		if region.is_capital:
			benefit += 5
		benefit += region.power + 1
		if controler.used_region_previously(region.name):
			benefit -= 4
	
#	print(region, ": ", benefit)
	return benefit


func determine_attacks(region : Region):
	var attacks : Array = []
	for align in range(controler.get_alingment_amount() - 1):
		if controler.alignment_friendly(current_alignment, align + 1):
			continue
		attacks.append(region.attack_power_difference(align + 1))
	var biggest_threat : int = attacks.pop_front()
	for i in attacks:
		if i < biggest_threat:
			biggest_threat = i
#	print(biggest_threat)
	return biggest_threat
