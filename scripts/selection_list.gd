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

@onready var page: float = size.y / SELECTION_ITEM_SIZE
@onready var items: Control = $HBoxContainer/Items
#@onready var scrollbar: ScrollBar = $HBoxContainer/ScrollBar


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
	reset_scrollbar()
	
	return item


func remove_item(item: SelectionListItem) -> void:
	if item.get_parent() != items:
		push_warning("This isn't my child!")
		return
	
	items.remove_child(item)
	item.queue_free()
	
	item_count -= 1
	reset_scrollbar()


func clear() -> void:
	for node in items.get_children():
		items.remove_child(node)
		node.queue_free()
	
	item_count = 0
	reset_scrollbar()


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
		item_selected.emit(item)


func select_index(index: int) -> void:
	var children: Array[Node] = items.get_children()
	if index >= 0 and index < children.size():
		select_item(children[index])


func get_selected_item() -> SelectionListItem:
	return selected_item


func reset_scrollbar() -> void:
	pass
#	scrollbar.visible = item_count > page
#	scrollbar.max_value = item_count
#	scrollbar.page = page
#	scrollbar.set_value_no_signal(0)
#	items.set_deferred(&"position", Vector2(items.position.x, 0))


func _item_toggled(pressed: bool, item: Control) -> void:
	select_item(item as SelectionListItem)
	if pressed == false:
		if double_click_timer > 0:
			item_activated.emit(item)
		double_click_timer = 0.5


#func _on_scroll_bar_value_changed(value: float) -> void:
#	items.position.y = value * -SELECTION_ITEM_SIZE
