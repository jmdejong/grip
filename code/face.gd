extends Node3D


@export var verts: PackedVector3Array
@export var heights: PackedFloat32Array
@export var gradient: Gradient
var radius: float

var center: Vector3
var near: float
var far: float
const segments := 4
var subfaces = null
const Face = preload("res://scenes/face.tscn")

func _enter_tree() -> void:
	#print(verts, " ", len(verts))
	assert(len(verts) == 3)
	#print(verts)
	#print(verts[0].length_squared(), " ", radius*radius)
	#print(heights[0])
	assert(is_equal_approx(verts[0].length_squared(), radius*radius))
	center = global_transform * ((verts[0] + verts[1] + verts[2])/3.0)
	near = (global_transform * verts[0]).distance_to(center) * 4.0
	far = near * 2
	if $Mesh.mesh == null:
		$Mesh.mesh = build_mesh()

func build_mesh():
	var surface := []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	surface[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	surface[Mesh.ARRAY_COLOR] = PackedColorArray()
	surface[Mesh.ARRAY_INDEX] = PackedInt32Array()
	var i: int = 0
	var prev: Array[int]
	for iv: int in range(segments+1):
		var line: Array[int] = []
		var v: float = float(iv) / segments
		for iu: int in range(segments - iv+1):
			var u: float = float(iu) / segments
			line.append(i)
			var w: float = 1.0 - u - v
			var pos: Vector3 = (verts[0] * u + verts[1] * v + verts[2] * w).normalized() * radius
			surface[Mesh.ARRAY_VERTEX].append(pos)
			surface[Mesh.ARRAY_NORMAL].append(pos.normalized())
			var height = u * heights[0] + v * heights[1] + w * heights[2]
			#print(gradient.sample(height))
			surface[Mesh.ARRAY_COLOR].append(gradient.sample(height))
			#surface[Mesh.ARRAY_COLOR].append(Color.AQUA)
			if iv > 0:
				surface[Mesh.ARRAY_INDEX].append_array(PackedInt32Array([prev[iu], prev[iu+1], i]))
				if iu > 0:
					surface[Mesh.ARRAY_INDEX].append_array([prev[iu], i, i-1])
			i += 1
		prev = line
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	return mesh

func make_subface(points: PackedVector3Array) -> Node3D:
	var face := Face.instantiate()
	for uvw in points:
		assert(is_equal_approx(uvw.x + uvw.y + uvw.z, 1))
		face.verts.append((verts[0] * uvw.x + verts[1] * uvw.y + verts[2] * uvw.z).normalized() * radius)
		face.heights.append(heights[0] * uvw.x + heights[1] * uvw.y + heights[2] * uvw.z)
	face.radius = radius
	face.gradient = gradient
	return face


func make_subfaces() -> Array[Node3D]:
	var faces: Array[Node3D] = []
	#var c01: Vector3 = (verts[0] + verts[1]).normalized() * radius
	#var c02: Vector3 = (verts[0] + verts[2]).normalized() * radius
	#var c12: Vector3 = (verts[1] + verts[2]).normalized() * radius
	for sub in [
		PackedVector3Array([Vector3(1, 0, 0), Vector3(.5, .5, 0), Vector3(.5, 0, .5)]),
		PackedVector3Array([Vector3(.5, .5, 0), Vector3(0, 1, 0), Vector3(0, .5, .5)]),
		PackedVector3Array([Vector3(0, 0, 1), Vector3(.5, 0, .5), Vector3(0, .5, .5)]),
		PackedVector3Array([Vector3(.5, .5, 0), Vector3(0, .5, .5), Vector3(.5, 0, .5)]),
		#[verts[0], verts[0] + verts[1], verts[0] + verts[2]],
		#[verts[0] + verts[1], verts[1], verts[1] + verts[2]],
		#[verts[2], verts[0] + verts[2], verts[1] + verts[2]],
		#[verts[0] + verts[1], verts[1] + verts[2], verts[0] + verts[2]],
	]:
		#var face := Face.instantiate()
		#face.verts = PackedVector3Array(sub.map(func(p): return p.normalized() * radius))
		#face.radius = radius
		#face.gradient = gradient
		faces.append(make_subface(sub))
	
	return faces

func remove_subfaces() -> void:
	for face in subfaces:
		if face.subfaces != null:
			face.remove_subfaces()
		face.queue_free()
	subfaces = null


func _process(_delta: float) -> void:
	var cd: float = get_viewport().get_camera_3d().global_position.distance_to(center)
	$Mesh.visible = cd > near
	$SubFaces.visible = cd <= near
	if subfaces == null && cd <= near:
		subfaces = make_subfaces()
		for face in subfaces:
			$SubFaces.add_child(face)
	if subfaces != null && cd > far:
		remove_subfaces()


#class Point:
	#func _init(pos: Vector3, normal: Vector3) -> void:
		#self.pos = pos
		#self.normal = normal
