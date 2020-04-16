# Panel that displays and enables sending of chat messages
extends Control

signal text_sent(text)
#warning-ignore: unused_signal
signal editing(value)

var line_count := 0

onready var chat_log: RichTextLabel = $ScrollContainer/Log
onready var chat_entry: LineEdit = $HBoxContainer/LineEdit
onready var send: Button = $HBoxContainer/Send


func _ready() -> void:
	chat_log.bbcode_text = ""
	#warning-ignore: return_value_discarded
	send.connect("button_down", self, "send_chat_message")
	#warning-ignore: return_value_discarded
	chat_entry.connect("focus_entered", self, "emit_signal", ["editing", true])
	#warning-ignore: return_value_discarded
	chat_entry.connect("focus_exited", self, "emit_signal", ["editing", false])


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
		chat_entry.release_focus()
