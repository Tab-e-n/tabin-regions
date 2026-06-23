extends MenuScene


func _ready():
	$gameplay/fast_dp.set_pressed_no_signal(Options.dp_speedrun)
	$gameplay/mouse_scroll.set_pressed_no_signal(Options.mouse_scroll_active)
	$gameplay/auto_phase.set_pressed_no_signal(Options.auto_end_turn_phases)
	$visual/particles.set_pressed_no_signal(Options.action_change_particles)
	$gameplay/graph.set_pressed_no_signal(Options.use_graph)
	$debug/capital_dist.set_pressed_no_signal(Options.capital_distance_visible)
	$gameplay/dp_speed.set_value_no_signal(1.0 - (Options.dp_think_timer - DPControl.THINKING_TIMER_MIN) / (DPControl.THINKING_TIMER_MAX - DPControl.THINKING_TIMER_MIN))
	init_default_dp()


## Sets whether to use mouse camera scrolling or not.
func set_mouse_scroll(scrolling: bool):
	Options.mouse_scroll_active = scrolling


## Sets whether to use automatic phases or not.
func set_auto_phases(auto: bool):
	Options.auto_end_turn_phases = auto


## Sets whether to use digital player speedrun or not.
func set_dp_speedrun(speedy: bool):
	Options.dp_speedrun = speedy


## Sets whether to show action change particles or not.
func set_action_change_particles(active: bool):
	Options.action_change_particles = active


## Sets the thinking speed of digital players. 0.0 is fastest, 1.0 is slowest.
func set_dp_think_timer(value: float):
	Options.dp_think_timer = DPControl.THINKING_TIMER_MIN + (DPControl.THINKING_TIMER_MAX - DPControl.THINKING_TIMER_MIN) * (1.0 - value)


func set_use_graph(value: bool):
	Options.use_graph = value


func set_capital_distance_visible(value: bool):
	Options.capital_distance_visible = value


func set_template(value: bool):
	Options.use_graph = value


func init_default_dp():
	match(Options.default_dp):
		DPControl.Controler.TURTLE:
			$gameplay/default_dp.select(0)
		DPControl.Controler.SIMPLETON:
			$gameplay/default_dp.select(1)
		DPControl.Controler.OVERTHINKER:
			$gameplay/default_dp.select(2)
		DPControl.Controler.BOOKWYRM:
			$gameplay/default_dp.select(3)
		DPControl.Controler.CHEATER:
			$gameplay/default_dp.select(4)


func _on_default_dp_item_selected(index: int):
	match(index):
		0:
			Options.default_dp = DPControl.Controler.TURTLE
		1:
			Options.default_dp = DPControl.Controler.SIMPLETON
		2:
			Options.default_dp = DPControl.Controler.OVERTHINKER
		3:
			Options.default_dp = DPControl.Controler.BOOKWYRM
		4:
			Options.default_dp = DPControl.Controler.CHEATER
