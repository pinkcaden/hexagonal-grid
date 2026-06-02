## Author: Caden Pink, Date: 05/16/26
class_name ScenePool
extends Node

var _object_class : String
var _desired_size : int
var _loaded : PackedScene
var _thread : Thread
var _queue : Array[Node]
var _args : Array[Variant]
var _setup_method : String

func _init(scene_load : PackedScene, desired_size : int, 
setup_method : String = "", args : Array[Variant] = []) -> void:
	_loaded = scene_load
	_object_class = _loaded.get_class()
	_setup_method = setup_method
	_args = args
	_desired_size = desired_size
	_start_thread()

func _start_thread() -> void:
	_thread = Thread.new()
	_thread.start(func() -> Node: 
		var new = _loaded.instantiate()
		if _setup_method != "": new.callv(_setup_method, _args)
		return new)

func _process(delta : float) -> void:
	if _thread && !_thread.is_alive(): 
		_queue.push_back(_thread.wait_to_finish())
		_thread = null
		if _queue.size() < _desired_size: 
			_start_thread()
	
func get_scene() ->  Node:
	if _queue.size() > 0:
		return _queue.pop_front()
	else:
		return null

func create_scene_blocking() -> void:
	var new = _loaded.instantiate()
	new.callv(_setup_method, _args)
	_queue.push_back(new)
	
func return_scene(scene : Node) -> void:
	_queue.push_back(scene)
