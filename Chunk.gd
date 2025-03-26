extends MeshInstance3D

@export var plane_size : Vector2 = Vector2(10, 10)
@export var vertices_x : int = 10
@export var vertices_z : int = 10
@export var noise_scale : float = 5.0
@export var height_scale : float = 5.0
@export var chunk_coord : Vector2i
@export var noise : FastNoiseLite
@export var terrain_texture : Texture2D

func _ready():
	generate_mesh()
	apply_texture()
	create_collision()

func generate_mesh():
	var mesh_data = ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()

	var indices = PackedInt32Array()

	# Generate vertices with noise-based height
	for x in range(vertices_x + 1):
		for z in range(vertices_z + 1):
			var pos_x = (x / float(vertices_x)) * plane_size.x - plane_size.x / 2
			var pos_z = (z / float(vertices_z)) * plane_size.y - plane_size.y / 2
			var global_pos_x = pos_x + chunk_coord.x * plane_size.x #shift the noise sampling
			var global_pos_z = pos_z + chunk_coord.y * plane_size.y #shift the noise sampling

			var height = noise.get_noise_2d(global_pos_x * noise_scale, global_pos_z * noise_scale) * height_scale

			vertices.append(Vector3(pos_x, height, pos_z))
			normals.append(Vector3(0, 1, 0))
			uvs.append(Vector2(x / float(vertices_x), z / float(vertices_z)))

	# Generate indices for triangles
	for x in range(vertices_x):
		for z in range(vertices_z):
			var i0 = x + z * (vertices_x + 1)
			var i1 = (x + 1) + z * (vertices_x + 1)
			var i2 = x + (z + 1) * (vertices_x + 1)
			var i3 = (x + 1) + (z + 1) * (vertices_x + 1)

			indices.append(i0)
			indices.append(i2)
			indices.append(i1)
			indices.append(i1)
			indices.append(i2)
			indices.append(i3)

	# Assign arrays to mesh data
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	arrays[ArrayMesh.ARRAY_INDEX] = indices

	# Create mesh surface
	mesh_data.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = mesh_data

func apply_texture():
	if terrain_texture:
		var material = StandardMaterial3D.new()
		material.albedo_texture = terrain_texture
		mesh.surface_set_material(0, material) # 0 is the surface index

func create_collision():
	var collision_shape = CollisionShape3D.new()
	var static_body = StaticBody3D.new()
	static_body.add_child(collision_shape)
	add_child(static_body)

	# create trimesh shape from the mesh
	var trimesh_shape = mesh.create_trimesh_shape()

	# assign the trimesh shape to the collision shape
	collision_shape.shape = trimesh_shape
