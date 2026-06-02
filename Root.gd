extends Node2D

var _width_slider : Slider
var _height_slider : Slider
var _hex_map : HexMap
func _ready() -> void:
	_hex_map = $HexMap
	_width_slider = $Width
	_height_slider = $Height
	_width_slider.drag_ended.connect(_update_size)
	_height_slider.drag_ended.connect(_update_size)
	
func _update_size(val):
	_hex_map.set_map_size_tiles(_width_slider.value, _height_slider.value)
	_hex_map.reposition_tiles()
	_hex_map.set_random_textures()
