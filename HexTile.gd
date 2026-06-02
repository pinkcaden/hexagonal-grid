class_name HexTile
extends Node2D

@export var initial_width : int = 500
@export var initial_height : int = 500
@export var point_up : bool = true
var _sprite : Sprite2D
var _point_up : bool 
var _sprite_width : int
var _sprite_height : int


func _ready() -> void:
	_sprite = $Sprite
	_sprite_width = _sprite.texture.get_width()
	_sprite_height = _sprite.texture.get_height()
	_point_up = point_up
	set_size(initial_width, initial_height)
	
	# may want to consider chaning parameter type to int.
	# current method favors calculation accuracy over arghument size 
func set_size(width : float, height : float) -> void:
	if _point_up:
		scale.x = width / _sprite_width
		scale.y = height / _sprite_height
	else:
		scale.x = height / _sprite_height
		scale.y = width / _sprite_width

func set_texture(texture : Texture):
	_sprite.texture = texture

func set_point_up():
	if !_point_up:
		var temp = scale.x
		scale.x = scale.y
		scale.y = temp
	_point_up = true

func set_point_right():
	if _point_up:
		var temp = scale.x
		scale.x = scale.y
		scale.y = temp
	_point_up = false
