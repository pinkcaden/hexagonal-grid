## Author: Caden Pink
## TODO: Fix these horrible variable names

class_name HexMap
extends Node2D

var _TILE_LOAD_RETRIES = 5

@export var tile_scene : PackedScene
@export var tile_types : Array[String]
@export var tile_textures : Dictionary[String, Texture]
@export var texture_weights : Dictionary[String, float]
@export var tile_setup_method : Dictionary[String, Array]
@export var tile_setup_arguments : Dictionary[String, Array]

var _center_width_count : int 
var _top_width_count : int

var _free_tiles : Array[HexTile] = []
var _added_tiles : Array[HexTile] = []
var _placed_tiles : Array[Array] = []


var _map_width : int = 750
var _map_height : int = 750
var _tile_height : int = 0
var _tile_width : int = 0

var _tile_scene_pool : ScenePool
var _tile_area_count : int = 0
var _tile_height_count : int = 0

func _ready():
	for node in get_children():
		node.queue_free()
	var tile_keys = tile_textures.keys()
	if tile_keys != texture_weights.keys():
		print("Check texture keys")
	if tile_setup_arguments.keys() != tile_setup_method.keys():
		print("Check set-up keys")
	_tile_scene_pool = ScenePool.new(tile_scene, _tile_area_count)
	set_width_tiles(5, 3)
	create_tiles()
	set_size_pixels(_map_width, _map_height)
	reposition_tiles()
		
func set_width_tiles(center_width_count : int, top_width_count : int) -> void:
	_center_width_count = center_width_count
	_top_width_count = top_width_count
	# center row + center to end triange - top to end triangle
	# triangle size uses sum of natual numebrs formula. factor of 2 multiplied because triange is mirrored.
	_tile_area_count = center_width_count + center_width_count*(center_width_count-1) - top_width_count*(top_width_count-1)
	_tile_height_count = 1 + 2 * (center_width_count - top_width_count)
	set_size_pixels(_map_width, _map_height)
	
	
func set_size_pixels(width_pixels : int, height_pixels : int) -> void:
	_tile_width = width_pixels / (_center_width_count + 2)
	_tile_height = height_pixels / (_tile_height_count + 2 + _tile_height_count % 2) 
	_map_width = width_pixels

func create_tiles() -> bool:
	var retry_count = 0
	for i in range(_free_tiles.size(), _tile_area_count + 10):
		retry_count = 0
		var _new_tile_node = _tile_scene_pool.get_scene()
		while (_new_tile_node == null):
			retry_count += 1
			if retry_count > _TILE_LOAD_RETRIES:
				return false
			_tile_scene_pool.create_scene_blocking()
			_new_tile_node = _tile_scene_pool.get_scene()
		_free_tiles.append(_new_tile_node)
	return true


func reposition_tiles() -> void:
	for row : Array[HexTile] in _placed_tiles:
		for tile : HexTile in row:
			if tile != null:
				remove_child(tile)
				_free_tiles.append(tile)
	_placed_tiles = []
	create_tiles()
	## TODO: reuse placed tiles
	var vert_correction = _tile_height_count % 2
	for r in range(_tile_height_count + 2 + vert_correction):
		var new_li = []
		new_li.resize(_center_width_count + 2)
		new_li.fill(null)
		_placed_tiles.append(new_li)
	var middle_ind = (_tile_height_count + 2 + vert_correction) / 2
	var middle_row = _placed_tiles[middle_ind]
	var x_pos = -_map_width / 2
	for col in range (1, _center_width_count + 1):
		x_pos += _tile_width
		var claimed_tile = _free_tiles.pop_back()
		add_child(claimed_tile)
		claimed_tile.position.x = x_pos
		claimed_tile.position.y = 0
		claimed_tile.set_size(_tile_width, _tile_height)
		middle_row[col] = claimed_tile
	var y_delta = 0
	var tile_count = _center_width_count
	for row_delta in range(1, _center_width_count - _top_width_count):
		tile_count -= 1
		y_delta += _tile_height * 3/4
		var x_offset = -_map_width / 2 + row_delta * (_tile_width / 2)
		var top_row = _placed_tiles[middle_ind - row_delta]
		var bottom_row = _placed_tiles[middle_ind + row_delta]
		for col in range(row_delta + row_delta % 2, row_delta + row_delta % 2 + tile_count): ##TODO: fix this line
			x_offset += _tile_width
			var top_node = _free_tiles.pop_back()
			add_child(top_node)
			top_node.position.y = -y_delta
			top_node.position.x = x_offset
			top_node.set_size(_tile_width, _tile_height)
			var bottom_node = _free_tiles.pop_back()
			add_child(bottom_node)
			bottom_node.position.y = y_delta
			bottom_node.position.x = x_offset
			bottom_node.set_size(_tile_width, _tile_height)
			top_row[col] = top_node
			bottom_row[col] = bottom_node

			
func set_random_textures() -> void:
	var tile_weight_sum : float = 0
	for val in texture_weights.values():
		tile_weight_sum +=  val
	for row : Array[HexTile] in _placed_tiles:
		for tile : HexTile in row:
			if tile != null: 
				var prob = randf()
				var cumulative_prob = 0
				for type in tile_textures.keys():
					cumulative_prob += 	float(texture_weights[type]) / tile_weight_sum
					if cumulative_prob >= prob:
						tile.set_texture(tile_textures[type])
						break
