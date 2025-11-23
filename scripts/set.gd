extends RefCounted
class_name Set


var dict : Dictionary = {}


func add(value : Variant):
	dict[value] = true


func remove(value : Variant) -> bool:
	return dict.erase(value)


func contains(value : Variant) -> bool:
	return value in dict


func empty() -> bool:
	return dict.is_empty()


func values() -> Array:
	return dict.keys()


func pop() -> Variant:
	if empty():
		push_error("pop called on an empty Set")
		return null
	var value : Variant = dict.keys()[0]
	remove(value)
	return value


func clear() -> void:
	dict.clear()


func size() -> int:
	return dict.size()


func copy_to(other : Set, deep : bool = false) -> void:
	other.clear()
	other.dict = dict.duplicate(deep)


func duplicate(deep : bool = false) -> Set:
	var new : Set = Set.new()
	new.dict = dict.duplicate(deep)
	return new
