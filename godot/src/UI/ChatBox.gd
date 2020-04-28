# Panel that displays and enables sending of chat messages
extends Control

signal text_sent(text)
signal edit_started
signal edit_ended

# Number of replies stored in the chat history
const HISTORY_LENGTH := 20

# Count of replies currently stored in the chat history
var reply_count := 0

onready var chat_log: RichTextLabel = $ScrollContainer/ChatLog
onready var line_edit: LineEdit = $HBoxContainer/LineEdit


func _init() -> void:
	visible = false


func _ready() -> void:
	chat_log.bbcode_text = ""


# Add a new reply to the chat box, taking `HISTORY_LENGTH` into account.
func add_reply(text: String, sender_name: String, color: Color) -> void:
	if reply_count == HISTORY_LENGTH:
		chat_log.bbcode_text = chat_log.bbcode_text.substr(chat_log.bbcode_text.find("\n"))
	else:
		reply_count += 1
	chat_log.bbcode_text += (
		"\n[color=#%s]%s[/color]: %s"
		% [color.to_html(false), sender_name, text]
	)


func send_chat_message() -> void:
	if line_edit.text.length() == 0:
		return
	var text: String = line_edit.text.replace("[", "{").replace("]", "}")
	emit_signal("text_sent", text)
	line_edit.text = ""


func _on_SendButton_pressed() -> void:
	send_chat_message()


func _on_LineEdit_text_entered(_new_text: String) -> void:
	send_chat_message()


func _on_LineEdit_focus_entered() -> void:
	emit_signal("edit_started")


func _on_LineEdit_focus_exited() -> void:
	emit_signal("edit_ended")


func _on_ToggleChatButton_toggled(button_pressed: bool) -> void:
	visible = button_pressed
