extends MeshInstance3D

var subfaces = null
var center: Vector3
var radius: float = 1
const FaceScene = preload("res://scenes/face.tscn")
@export var gradient: Gradient

func _enter_tree() -> void:
	center = global_transform * get_aabb().get_center()


func _ready() -> void:
	pass

func _process(_delta) -> void:
	var cd: float = get_viewport().get_camera_3d().global_position.distance_to(center)
	if subfaces == null && cd <= visibility_range_begin - visibility_range_begin_margin:
		subfaces = add_subfaces()
		for face in subfaces:
			face.visibility_parent = get_path()
			add_child(face)
			
	if subfaces != null && cd > visibility_range_begin * 2:
		remove_subfaces()
func remove_subfaces() -> void:
	for face in subfaces:
		if face.subfaces != null:
			face.remove_subfaces()
		face.queue_free()
	subfaces = null
	


func add_subfaces() -> Array[Face]:
	var faces: Array[Face] = []
	var shape: Face.Shape = Face.Shape.new()
	shape.gradient = gradient
	for si in mesh.get_surface_count():
		var surface_array = mesh.surface_get_arrays(si)
		var indices: PackedInt32Array = surface_array[Mesh.ARRAY_INDEX]
		var verts: PackedVector3Array = surface_array[Mesh.ARRAY_VERTEX]
		var heights: PackedFloat32Array = PackedFloat32Array()
		var points: Array[Face.Point] = []
		for vi in len(verts):
			points.append(Face.Point.new(
				shape,
				verts[vi],
				randf()*2-1,
				randi(),
				1
			))
			heights.append(randf()*2-1)
		for fi in range(0, len(indices), 3):
			var i0 := indices[fi]
			var i1 := indices[fi+1]
			var i2 := indices[fi+2]
			faces.append(Face.from_points(points[i0], points[i1], points[i2]))
	return faces








const PHI: float = 1.61803398875

func generate_icosahedron():
	var verts := [
		Vector3(0, 1, PHI),
		Vector3(0, -1, PHI),
		Vector3(0, 1, -PHI),
		Vector3(0, -1, -PHI),
		Vector3(PHI, 0, 1),
		Vector3(PHI, 0, -1),
		Vector3(-PHI, 0, 1),
		Vector3(-PHI, 0, -1),
		Vector3(1, PHI, 0),
		Vector3(-1, PHI, 0),
		Vector3(1, -PHI, 0),
		Vector3(-1, -PHI, 0),
	].map(func(v): return v.normalized())
	var normals := verts.map(func(v): return v.normalized())
	var indices: Array[int] = [
		1, 0, 4,
		0, 1, 6,
		2, 3, 5,
		3, 2, 7,
		5, 4, 8,
		4, 5, 10,
		6, 7, 9,
		7, 6, 11,
		9, 8, 0,
		8, 9, 2,
		10,11,1,
		11,10,3,
		0, 8, 4,
		0, 6, 9,
		1, 4, 10,
		1, 11,6,
		2, 5, 8,
		2, 9, 7,
		3, 10,5,
		3, 7, 11,
	]
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array(verts)
	#surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = PackedVector3Array(normals)
	surface_array[Mesh.ARRAY_INDEX] = PackedInt32Array(indices)
	print(verts[0])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
