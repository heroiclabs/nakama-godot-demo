extends LineEditValidate


func _validate(text: String) -> bool:
	return text.length() >= 8
