extends Control


signal item_selected(item: Control)
signal item_deselected(item: Control)


const PACKED_ITEM: PackedScene = preload("res://objects/selection_item.tscn")
const SELECTION_ITEM_SIZE: float = 20.0


var item_count: int = 0

@onready var page: float = size.y / SELECTION_ITEM_SIZE
@onready var items: Control = $HBoxContainer/Items
@onready var scrollbar: ScrollBar = $HBoxContainer/ScrollBar


func _ready():
	for i in range(40):  # TEMP
		add_item(str(i))


func add_item(value: String) -> void:
	var item: Button = PACKED_ITEM.instantiate() as Button
	item.text = value
	item.pressed.connect(_item_toggled.bind(item))
	items.add_child(item)
	
	item_count += 1
	reset_scrollbar()


func remove_item() -> void:
	pass


func clear() -> void:
	pass


func reset_scrollbar() -> void:
	scrollbar.visible = item_count > page
	scrollbar.max_value = item_count
	scrollbar.page = page
	scrollbar.set_value_no_signal(0)
	items.set_deferred(&"position", Vector2(items.position.x, 0))


func _item_toggled(pressed: bool, item: Control) -> void:
	if pressed:
		item_selected.emit(item)
	else:
		item_deselected.emit(item)


func _on_scroll_bar_value_changed(value: float) -> void:
	items.position.y = value * -SELECTION_ITEM_SIZE
