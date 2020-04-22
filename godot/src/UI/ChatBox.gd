# Panel that displays and enables sending of chat messages
extends Control

signal text_sent(text)
signal editing(value)

# Number of replies stored in the chat history
const HISTORY_LENGTH := 20

# Count of replies currently stored in the chat history
var reply_count := 0

onready var chat_log: RichTextLabel = $ScrollContainer/ChatLog
onready var line_edit: LineEdit = $HBoxContainer/LineEdit


func _ready() -> void:
	chat_log.bbcode_text = ""


# Add a new reply to the chat box, taking `HISTORY_LENGTH` into account.
func add_text(text: String, sender_name: String, color: Color) -> void:
	if reply_count == HISTORY_LENGTH:
		chat_log.bbcode_text = chat_log.bbcode_text.substr(chat_log.bbcode_text.find("\n"))
	else:
		reply_count += 1
	chat_log.bbcode_text += (
		"\n[color=#%s]%s[/color]: %s"
		% [color.to_html(false), sender_name, text]
	)


func send_chat_message() -> void:
	var output: String = line_edit.text
	if output.length() > 0:
		output = output.replace("[", "{").replace("]", "}")
		emit_signal("text_sent", output)
		line_edit.text = ""


func _on_SendButton_pressed() -> void:
	send_chat_message()


func _on_LineEdit_focus_entered() -> void:
	emit_signal("editing", true)


func _on_LineEdit_focus_exited() -> void:
	emit_signal("editing", true)
