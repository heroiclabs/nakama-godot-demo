extends Control

#warning-ignore: unused_signal
signal text_sent(text)

var line_count := 0

onready var chat_log := $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/ChatLog
onready var chat_entry := $MarginContainer/VBoxContainer/HBoxContainer/ChatEntry
onready var send := $MarginContainer/VBoxContainer/HBoxContainer/Send


func _ready() -> void:
	#warning-ignore: return_value_discarded
	send.connect("button_down", self, "send_chat_message")


func add_text(text: String, sender: String, color: Color) -> void:
	if line_count == 20:
		chat_log.bbcode_text = chat_log.bbcode_text.substr(chat_log.bbcode_text.find("\n"))
		line_count -= 1

	var output := "\n[color=#%s]%s[/color]: %s" % [color.to_html(false), sender, text]
	chat_log.bbcode_text += output
	line_count += 1


func send_chat_message() -> void:
	var output: String = chat_entry.text
	if output.length() > 0:
		output = output.replace("[", "{").replace("]", "}")
		emit_signal("text_sent", output)
		chat_entry.text = ""
