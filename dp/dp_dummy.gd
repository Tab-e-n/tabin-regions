extends DigitalPlayer
class_name DPDummy


signal started_turn
signal thinking_normal
signal thinking_mobilize
signal thinking_bonus


func start_turn(align : int):
	super.start_turn(align)
	started_turn.emit()


func think_normal():
	thinking_normal.emit()


func think_mobilize():
	thinking_mobilize.emit()


func think_bonus():
	thinking_bonus.emit()
