extends DigitalPlayer


func start_turn(align : int):
	super.start_turn(align)


func think_bonus():
	think_normal()


func think_normal():
	if controler.get_action_amount() == 0:
		controler.CALL_end_turn = true
		return
	
#	print("think default first")
	var eligable_regions : Array = []
	
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	
	for region in controler.get_owned_regions():
		if region.power != region.max_power:
			eligable_regions.append(region)
	
#	print(eligable_regions)
	
	if eligable_regions.size() > 0:
		controler.selected_capital = eligable_regions[rng.randi_range(0, eligable_regions.size() - 1)].name
	else:
		for region in controler.get_owned_regions():
#			print("owned: ", region.name)
			var in_threat : bool = false
			for link in region.links:
				var target : Region = link.get_other_region(region)
				if not target:
					continue
#				print("connected: ", target.name)
				if controler.alignment_friendly(current_alignment, target.alignment):
#					print("friendly alignment")
					continue
				if not controler.alignment_inactive(target.alignment):
					in_threat = true
#					print("not neutral")
				if not target.incoming_attack(current_alignment, 0, true):
#					print("cannot attack")
					continue
				eligable_regions.append(target)
			if in_threat and region.power != region.max_power:
				eligable_regions.append(region)
		
#		print(eligable_regions)
		
		if eligable_regions.size() > 0:
			controler.selected_capital = eligable_regions[0].name
			var highest_benefit = calculate_benefit_default(eligable_regions.pop_front())
			rng.randomize()
			var results : Array = []
			for region in eligable_regions:
				var benefit = calculate_benefit_default(region)
				if benefit > highest_benefit:
					results = [region.name]
					highest_benefit = benefit
				if benefit == highest_benefit:
					results.append(region.name)
					highest_benefit = benefit
			if results:
				controler.selected_capital = results[rng.randi_range(0, results.size() - 1)]
		else:
			controler.CALL_end_turn = true


func think_mobilize():
	if controler.get_capital_amount() == 0:
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
				controler.CALL_change_current_phase = true
	else:
		controler.CALL_change_current_phase = true


func calculate_benefit_default(region : Region):
	var action_amount : int = controler.get_action_amount()
	var benefit = 0
	if region.alignment == current_alignment:
		var threat : int = determine_attacks(region)
		if threat < -action_amount:
			benefit = -region.power - 1
		if threat == -action_amount:
			if region.is_capital and region.power != region.max_power:
				benefit += 4
		if threat >= -action_amount:
			@warning_ignore("integer_division")
			benefit += region.power / 2
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
