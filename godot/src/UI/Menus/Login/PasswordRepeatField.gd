tool
extends LineEditValidate

export var password_field_path: NodePath setget set_password_field_path

var password_field: LineEdit


func _ready() -> void:
	yield(self, "ready")
	password_field = get_node(password_field_path)
	if not password_field:
		printerr("%s: Missing Password Field Path NodePath" % [get_path()])


func _get_configuration_warning() -> String:
	return "You must set the Password Field" if not password_field else ""


func _validate(text: String) -> bool:
	if not password_field:
		return false
	return password_field.text == text


func set_password_field_path(value: NodePath) -> void:
	password_field_path = value
	if not password_field:
		return
	password_field = get_node(password_field_path)
