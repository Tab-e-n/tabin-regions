extends MenuScene


func _ready():
	$fast_dp.set_pressed_no_signal(Options.dp_speedrun)
	$mouse_scroll.set_pressed_no_signal(Options.mouse_scroll_active)
	$auto_phase.set_pressed_no_signal(Options.auto_end_turn_phases)
	$particles.set_pressed_no_signal(Options.action_change_particles)
	$dp_speed.set_value_no_signal(1.0 - (Options.dp_think_timer - DPControl.THINKING_TIMER_MIN) / (DPControl.THINKING_TIMER_MAX - DPControl.THINKING_TIMER_MIN))


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

