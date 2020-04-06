extends HBoxContainer

signal new_character_created(name, color)

onready var create := $VBoxContainer/Create
onready var name_field := $VBoxContainer/HBoxContainer/LineEdit
onready var red := $VBoxContainer/Color/VBoxContainer/Red
onready var green := $VBoxContainer/Color/VBoxContainer/Green
onready var blue := $VBoxContainer/Color/VBoxContainer/Blue


func _ready() -> void:
	#warning-ignore: return_value_discarded
	create.connect("button_down", self, "_on_Create_down")


func disable() -> void:
	modulate = Color.gray
	red.editable = false
	green.editable = false
	blue.editable = false
	create.disabled = true
	name_field.editable = false


func enable() -> void:
	modulate = Color.white
	red.editable = true
	green.editable = true
	blue.editable = true
	create.disabled = false
	name_field.editable = true


func _on_Create_down() -> void:
	var name: String = name_field.text
	if name.length() == 0:
		return
	var color := Color(red.value, green.value, blue.value)
	emit_signal("new_character_created", name, color)
