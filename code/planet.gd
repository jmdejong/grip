extends MeshInstance3D

const PHI: float = 1.61803398875

var subfaces = null
@onready var center = global_transform * get_aabb().get_center()

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

func _ready() -> void:
	print("ready ", visibility_range_begin)

func _process(_delta) -> void:
	var cd: float = get_viewport().get_camera_3d().global_position.distance_to(center)
	if subfaces == null && cd <= visibility_range_begin - visibility_range_begin_margin:
		subfaces = add_subfaces()
		print("adding subfaces")
		for face in subfaces:
			face.visibility_parent = get_path()
			add_child(face)
			
	if subfaces != null && cd > visibility_range_begin * 2:
		for face in subfaces:
			face.queue_free()
		subfaces = null
		print("removing subfaces")

func center_between(p0: Vector3, n0: Vector3, p1: Vector3, n1: Vector3) -> Vector3:
	var k := p0.distance_to(p1)*0.360
	var c0 := p0 + n0.cross(p1 - p0).cross(n0).normalized() * k
	var c1 := p1 + n1.cross(p0 - p1).cross(n1).normalized() * k
	var t := 0.5
	var r = p0.bezier_interpolate(c0, c1, p1, t)
	#print(r.length())
	return r

func subdivide_face(v0: Vector3, n0: Vector3, v1: Vector3, n1: Vector3, v2: Vector3, n2: Vector3) -> Mesh:
	var surface := []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		v0,
		v1,
		v2,
		center_between(v0, n0, v1, n1),
		center_between(v0, n0, v2, n2),
		center_between(v2, n2, v1, n1),
	])
	surface[Mesh.ARRAY_NORMAL] = PackedVector3Array([
		n0,
		n1,
		n2,
		(n0 + n1) / 2,
		(n0 + n2) / 2,
		(n2 + n1) / 2
	])
	surface[Mesh.ARRAY_INDEX] = PackedInt32Array([
		0, 3, 4,
		3, 1, 5,
		4, 5, 2,
		4, 3, 5
	])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	return mesh

func add_subfaces() -> Array[MeshInstance3D]:
	var faces: Array[MeshInstance3D] = []
	for si in mesh.get_surface_count():
		var surface_array = mesh.surface_get_arrays(si)
		var indices: PackedInt32Array = surface_array[Mesh.ARRAY_INDEX]
		var verts: PackedVector3Array = surface_array[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = surface_array[Mesh.ARRAY_NORMAL]
		for fi in range(0, len(indices), 3):
			var i0 := indices[fi]
			var i1 := indices[fi+1]
			var i2 := indices[fi+2]
			#print("f {1} {0} {2}".format([i0+1, i1+1, i2+1]))
			var face := MeshInstance3D.new()
			face.mesh = subdivide_face(verts[i0], normals[i0], verts[i1], normals[i1], verts[i2], normals[i2])
			face.set_script(load("res://code/planet.gd"))
			face.visibility_range_begin = (global_transform * verts[i0]).distance_to(global_transform *verts[i1]) * 2
			faces.append(face)
	return faces
