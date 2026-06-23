class_name SelectionList
extends Control


signal item_selected(item: SelectionListItem)
signal item_deselected(item: SelectionListItem)
signal item_activated(item: SelectionListItem)


const PACKED_ITEM: PackedScene = preload("res://objects/selection_item.tscn")
const SELECTION_ITEM_SIZE: float = 20.0


var item_count: int = 0
var selected_item: SelectionListItem = null

var double_click_timer: float = 0.0

@export var empty_list_message: String = "No items."

@onready var page: float = size.y / SELECTION_ITEM_SIZE
@onready var hbox: ScrollContainer = $ScrollContainer
@onready var items: Control = $ScrollContainer/Items
@onready var label_empty: Label = $Empty


func _physics_process(delta):
	if double_click_timer > 0.0:
		double_click_timer -= delta


func add_item(value: String, display: String = "") -> SelectionListItem:
	var item: SelectionListItem = PACKED_ITEM.instantiate() as SelectionListItem
	item.value = value
	if display.is_empty():
		item.text = value
	else:
		item.text = display
	item.toggled.connect(_item_toggled.bind(item))
	items.add_child(item)
	
	item_count += 1
	
	update_empty_message()
	
	return item


func remove_item(item: SelectionListItem) -> void:
	if item.get_parent() != items:
		push_warning("This isn't my child!")
		return
	
	items.remove_child(item)
	item.queue_free()
	
	item_count -= 1
	
	update_empty_message()


func clear() -> void:
	for node in items.get_children():
		items.remove_child(node)
		node.queue_free()
	
	selected_item = null
	
	item_count = 0
	
	update_empty_message()


func _show_selected_item() -> void:
	await get_tree().process_frame
	hbox.ensure_control_visible(selected_item)


func select_item(item: SelectionListItem) -> void:
	if item == selected_item:
		selected_item.set_pressed_no_signal(true)
		return
	
	if selected_item:
		selected_item.set_pressed_no_signal(false)
		item_deselected.emit(item)
	
	selected_item = item
	
	if selected_item:
		selected_item.set_pressed_no_signal(true)
		_show_selected_item()
		item_selected.emit(item)


func select_index(index: int) -> void:
	var children: Array[Node] = items.get_children()
	if index >= 0 and index < children.size():
		select_item(children[index])


func get_selected_item() -> SelectionListItem:
	return selected_item


func update_empty_message():
	if item_count == 0:
		label_empty.text = empty_list_message
		label_empty.visible = true
	else:
		label_empty.visible = false


func _item_toggled(pressed: bool, item: Control) -> void:
	select_item(item as SelectionListItem)
	if pressed == false:
		if double_click_timer > 0:
			item_activated.emit(item)
	double_click_timer = 0.5
