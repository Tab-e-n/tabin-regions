extends Node
class_name DigitalPlayer


var controler : DPControl
var current_alignment : int


func start_turn(align : int):
	current_alignment = align


func think_normal():
	controler.selected_action = DPControl.PlayerAction.END_TURN


func think_mobilize():
	controler.selected_action = DPControl.PlayerAction.END_TURN


func think_bonus():
	controler.selected_action = DPControl.PlayerAction.END_TURN
