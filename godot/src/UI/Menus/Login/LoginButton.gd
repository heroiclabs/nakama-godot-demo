extends Button

var regex := RegEx.new()


func _init() -> void:
	regex.compile('.+\\@.+\\..+')


# Returns `true` if the email address has a valid format
func validate_email(address: String) -> bool:
	return regex.search(address) != null
