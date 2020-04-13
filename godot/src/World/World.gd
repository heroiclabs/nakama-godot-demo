# Controls the visibility of world elements
extends Node2D

onready var background := $CanvasLayer/Background


func hide() -> void:
	hide()
	background.hide()


func show() -> void:
	show()
	background.show()
