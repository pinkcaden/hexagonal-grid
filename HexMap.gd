## Author: Caden Pink, Date: 06/01/26
## TODO: Fix these horrible variable names

class_name HexMap
extends Node2D

var _TILE_LOAD_RETRIES : int = 5

var _SQUARE_TO_HEX_AREA_RATIO : float = 2 / (3 * sqrt(3))

var _ELLIPSE_GRACE_PERC : float = .5

@export var tile_scene : PackedScene
@export var tile_types : Array[String]
@export var tile_textures : Dictionary[String, Texture]
@export var texture_weights : Dictionary[String, float]
@export var tile_setup_method : Dictionary[String, Array]
@export var tile_setup_arguments : Dictionary[String, Array]

var _tile_scene_pool : ScenePool = null
var _placed_tiles : Array[Array] = []


var _map_w_px : int = 750
var _map_h_px : int = 750
var _approx_map_area_tiles : int = 0

var _map_w_tiles : int = 0
var _map_h_tiles : int = 0

var _tile_h_px : int = 0
var _tile_w_px : int = 0




func _ready():
	for node in get_children():
		node.queue_free()
	var tile_keys = tile_textures.keys()
	if tile_keys != texture_weights.keys():
		print("Check texture keys")
	if tile_setup_arguments.keys() != tile_setup_method.keys():
		print("Check set-up keys")
	set_map_size_tiles(9, 9)
	set_map_size_pixels(_map_w_px, _map_h_px)
	reposition_tiles()
	set_random_textures()
		
func set_map_size_tiles(width_in_tiles : int, height_in_tiles : int) -> void:
	
	if width_in_tiles > 15 or height_in_tiles > 15 or height_in_tiles > width_in_tiles:
		return
	_map_w_tiles = width_in_tiles
	_map_h_tiles = height_in_tiles
	
	var ellipse_area = PI * width_in_tiles * height_in_tiles
	_approx_map_area_tiles = int(ellipse_area * _SQUARE_TO_HEX_AREA_RATIO)
	
	if _tile_scene_pool == null:
		_tile_scene_pool = ScenePool.new(tile_scene, _approx_map_area_tiles)
		add_child(_tile_scene_pool)
	set_map_size_pixels(_map_w_px, _map_h_px)
	
func set_map_size_pixels(width_in_pixels : int, height_in_pixels : int) -> void:
	_map_w_px = width_in_pixels
	_map_h_px = height_in_pixels
	
	_tile_w_px = width_in_pixels / _map_w_tiles
	_tile_h_px = height_in_pixels / _map_h_tiles



func reposition_tiles() -> void:
	for row : Array[HexTile] in _placed_tiles:
		for tile : HexTile in row:
			if tile != null:
				remove_child(tile)
				_tile_scene_pool.return_scene(tile)
	_placed_tiles = []
	for r in range(_map_h_tiles):
		var new_li = []
		new_li.resize(_map_w_tiles + 1)
		new_li.fill(null)
		_placed_tiles.append(new_li)
	var middle_ind = _map_h_tiles / 2
	var middle_row = _placed_tiles[middle_ind]
	var x_pos =  - ( _map_w_px + _tile_w_px ) / 2
	for col in range (0, _map_w_tiles):
		x_pos += _tile_w_px
		var claimed_tile = _spawn_tile(x_pos, 0)
		middle_row[col] = claimed_tile

	var y_diff : int = 0
	var ellipse_x : float
	var grace = _tile_w_px * _ELLIPSE_GRACE_PERC
	for row in range(1, _map_h_tiles / 2 + 1):
		x_pos =  - ( _map_w_px  + _tile_w_px * row) / 2 + _tile_w_px / 2
		y_diff += 3 * _tile_h_px / 4
		## f(y) for ellipse: x = b * sqrt(1 - y^2 / a^2) b is vert acis, a is horiz axis
		ellipse_x = (_map_w_px / 2) * sqrt(1 - (pow(y_diff, 2) / pow((_map_h_px / 2), 2)))
		var ind = row - row & 2
		while x_pos < ellipse_x - grace:
			if x_pos > - (ellipse_x - grace):
				_placed_tiles[middle_ind + row][ind] = _spawn_tile(x_pos, y_diff)
				_placed_tiles[middle_ind - row][ind] = _spawn_tile(x_pos, -y_diff)
			ind += 1
			x_pos += _tile_w_px
			
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


func _spawn_tile(x_pos_px : int, y_pos_px : int) -> HexTile:
		var claimed_tile = _get_tile()
		add_child(claimed_tile)
		claimed_tile.position.x = x_pos_px
		claimed_tile.position.y = y_pos_px
		claimed_tile.set_size(_tile_w_px, _tile_h_px)
		return claimed_tile

func _get_tile() -> HexTile:
	var claimed_tile = _tile_scene_pool.get_scene()
	var retry_count : int = 0
	while (claimed_tile == null):
		retry_count += 1
		if retry_count > _TILE_LOAD_RETRIES:
			print("failed to get tile from pool")
			return null
		_tile_scene_pool.create_scene_blocking()
		claimed_tile = _tile_scene_pool.get_scene()
	return claimed_tile
