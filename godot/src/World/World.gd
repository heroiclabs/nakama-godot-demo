# Controls the visibility of world elements
extends Node2D

onready var background := $CanvasLayer/Background
onready var spawn_default: Position2D = $SpawnDefault


func do_hide() -> void:
	hide()
	background.hide()


func do_show() -> void:
	show()
	background.show()
