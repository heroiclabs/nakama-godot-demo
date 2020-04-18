# Panel that displays and enables sending of chat messages
extends Control

signal text_sent(text)
#warning-ignore: unused_signal
signal editing(value)

# Number of replies stored in the chat history
const HISTORY_LENGTH := 20

var line_count := 0

onready var chat_log: RichTextLabel = $ScrollContainer/ChatLog
onready var line_edit: LineEdit = $HBoxContainer/LineEdit


func _ready() -> void:
	chat_log.bbcode_text = ""
	#warning-ignore: return_value_discarded
	line_edit.connect("focus_entered", self, "emit_signal", ["editing", true])
	#warning-ignore: return_value_discarded
	line_edit.connect("focus_exited", self, "emit_signal", ["editing", false])


func add_text(text: String, sender_name: String, color: Color) -> void:
	if line_count == HISTORY_LENGTH:
		chat_log.bbcode_text = chat_log.bbcode_text.substr(chat_log.bbcode_text.find("\n"))
	else:
		line_count += 1

	chat_log.bbcode_text += "\n[color=#%s]%s[/color]: %s" % [color.to_html(false), sender_name, text]


func send_chat_message() -> void:
	var output: String = line_edit.text
	if output.length() > 0:
		output = output.replace("[", "{").replace("]", "}")
		emit_signal("text_sent", output)
		line_edit.text = ""
		line_edit.release_focus()


func _on_SendButton_pressed() -> void:
	send_chat_message()
