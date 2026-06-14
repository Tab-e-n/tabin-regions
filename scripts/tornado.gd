extends Node
class_name Tornado


const WARNING_NAME : String = "TornadoWarning"


## Region that will be used to decide when the volcano erupts.
## The volcano will add 1 power to it's residing region every turn.
## When at max power, the volcano erupts and the region is set back to 1 power.
@export var residing_region : Region
## The alignment used by the volcano. Should have DPDummy.
@export var dummy_alignment : int = 0
## Makes warnings that show up appear further from the city.
## Useful if multiple disasters are present, so their warnings don't overlap.
@export var warning_number : int = 1

@onready var controler : DPDummy
@onready var dp_control : DPControl
@onready var region_control : RegionControl

var pathways : Array[RegionPath] = []
var active : bool = false
var iteration : int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
