extends Node
class_name DigitalPlayer


var controler : DPControl
var current_alignment : int


func start_turn(align : int):
	current_alignment = align

func think_normal():
	controler.CALL_end_turn = true

func think_mobilize():
	controler.CALL_end_turn = true

func think_bonus():
	controler.CALL_end_turn = true
