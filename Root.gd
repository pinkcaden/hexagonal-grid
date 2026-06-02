extends Node2D

var _top_slider : Slider
var _center_slider : Slider
var _hex_map : HexMap
func _ready() -> void:
	_hex_map = $HexMap
	_top_slider = $TopWidth
	_center_slider = $CenterWidth
	_top_slider.drag_ended.connect(_update_size)
	_center_slider.drag_ended.connect(_update_size)
	
func _update_size(val):
	if _center_slider.value < _top_slider.value: return
	_hex_map.set_width_tiles(_center_slider.value, _top_slider.value)
	_hex_map.reposition_tiles()
	_hex_map.set_random_textures()
