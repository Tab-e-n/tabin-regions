extends Resource
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


func iterate() -> Variant:
	if empty():
		return null
	var value : Variant = dict.keys()[0]
	remove(value)
	return value
