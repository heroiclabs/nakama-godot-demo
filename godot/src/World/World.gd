# Class to control visibility on world elements
extends Node2D

onready var background := $CanvasLayer/Background


func do_hide() -> void:
	hide()
	background.hide()


func do_show() -> void:
	show()
	background.show()
