extends LineEditValidate

var regex := RegEx.new()


func _init() -> void:
	# warning-ignore:return_value_discarded
	regex.compile('.+\\@.+\\.[a-z][a-z]+')


func _validate(email_address: String) -> bool:
	return regex.search(email_address) != null
