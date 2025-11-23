extends _BASE_


func start_turn(align : int):
	super.start_turn(align)


func think_normal():
	controler.CALL_end_turn = true


func think_mobilize():
	controler.CALL_end_turn = true


func think_bonus():
	controler.CALL_end_turn = true
