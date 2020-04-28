# Controls the visibility of world elements
extends Node2D

onready var tilemap: TileMap = $TileMap


func get_limits() -> Rect2:
	var limits: Rect2 = tilemap.get_used_rect()
	limits.position = limits.position * tilemap.cell_size + tilemap.global_position
	limits.size *= tilemap.cell_size
	return limits
