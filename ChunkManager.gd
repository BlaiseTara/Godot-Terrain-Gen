extends Node3D

@export var plane_size : Vector2 = Vector2(10, 10)
@export var chunk_load_distance : float = 20.0
@export var chunk_unload_distance : float = 30.0
@export var player_path : NodePath = "Player"
@export var vertices_x : int = 10
@export var vertices_z : int = 10
@export var noise_scale : float = 5.0
@export var height_scale : float = 5.0
@export var terrain_texture : Texture2D # Export the texture
@export var seed: int = 123

var chunks : Dictionary = {}
var player : Node3D
var noise : FastNoiseLite

func _ready():
	player = get_node(player_path)
	if player == null:
		printerr("Player node not found at path: ", player_path)
		return

	noise = FastNoiseLite.new()
	noise.seed = seed
	#noise.noise_type = FastNoiseLite.TYPE_PERLIN # Use Perlin noise
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	_update_chunks()

func _process(delta):
	_update_chunks()

func _update_chunks():
	var player_pos = player.global_position

	# Calculate the chunk coordinates the player is in
	var player_chunk_x = floor(player_pos.x / plane_size.x)
	var player_chunk_z = floor(player_pos.z / plane_size.y)

	# Generate a grid of chunks around the player
	var load_range = ceil(chunk_load_distance / plane_size.x)

	var chunks_to_load = []
	for x in range(player_chunk_x - load_range, player_chunk_x + load_range + 1):
		for z in range(player_chunk_z - load_range, player_chunk_z + load_range + 1):
			chunks_to_load.append(Vector2i(x, z))

	# Load new chunks
	for chunk_coord in chunks_to_load:
		if !chunks.has(chunk_coord):
			var chunk_pos = Vector3(chunk_coord.x * plane_size.x, 0, chunk_coord.y * plane_size.y)
			if player_pos.distance_to(chunk_pos + Vector3(plane_size.x/2, 0, plane_size.y/2)) < chunk_load_distance: #added vector3
				_create_chunk(chunk_coord, chunk_pos)

	# Unload distant chunks
	var chunks_to_unload = []
	for chunk_coord in chunks.keys():
		var chunk_pos = Vector3(chunk_coord.x * plane_size.x, 0, chunk_coord.y * plane_size.y)
		if player_pos.distance_to(chunk_pos + Vector3(plane_size.x/2, 0, plane_size.y/2)) > chunk_unload_distance: #added Vector3
			chunks_to_unload.append(chunk_coord)

	for chunk_coord in chunks_to_unload:
		_destroy_chunk(chunk_coord)

func _create_chunk(chunk_coord: Vector2i, chunk_pos: Vector3):
	var plane_mesh_instance = MeshInstance3D.new()
	var plane_script = load("res://Scripts/Chunk.gd")
	plane_mesh_instance.set_script(plane_script)

	# Pass chunk-specific data to the Chunk script
	plane_mesh_instance.set("plane_size", plane_size)
	plane_mesh_instance.set("vertices_x", vertices_x)
	plane_mesh_instance.set("vertices_z", vertices_z)
	plane_mesh_instance.set("noise_scale", noise_scale)
	plane_mesh_instance.set("height_scale", height_scale)
	plane_mesh_instance.set("chunk_coord", chunk_coord)
	plane_mesh_instance.set("noise", noise)
	plane_mesh_instance.set("terrain_texture", terrain_texture) # Pass the texture
	plane_mesh_instance.global_position = chunk_pos
	add_child(plane_mesh_instance)
	chunks[chunk_coord] = plane_mesh_instance
	plane_mesh_instance.name = str(chunk_coord)

func _destroy_chunk(chunk_coord: Vector2i):
	if chunks.has(chunk_coord):
		var chunk = chunks[chunk_coord]
		remove_child(chunk)
		chunk.queue_free()
		chunks.erase(chunk_coord)
