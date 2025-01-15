class_name Planet
extends Node3D

var subfaces = null
var center: Vector3
@export var radius: float = 1
const FaceScene = preload("res://scenes/face.tscn")
@export var gradient: Gradient
var core: Vector3 = Vector3(0, 0, 0)
@export var gradient_scale = 500
@export var height_base: float = 100
@export var random_weight: float = 1000
@export var material: Material
var min_resolution: float = 1.0

func _enter_tree() -> void:
	material.set_shader_parameter("gradient_scale", gradient_scale)
	material.set_shader_parameter("radius", radius)


func _ready() -> void:
	generate_icosahedron()
	$GravityField.scale = Vector3(1, 1, 1) * radius * 4
	$Mesh.visibility_range_begin = radius * 4
	center = global_position

func _process(_delta) -> void:
	var cd: float = get_viewport().get_camera_3d().global_position.distance_to(center)
	if subfaces == null && cd <= radius * 4:
		subfaces = add_subfaces()
		for face in subfaces:
			add_child(face)
	if subfaces != null && cd > radius * 8:
		remove_subfaces()

func remove_subfaces() -> void:
	for face in subfaces:
		if face.subfaces != null:
			face.remove_subfaces()
		face.queue_free()
	subfaces = null
	


func add_subfaces() -> Array[Face]:
	var faces: Array[Face] = []
	for si in $Mesh.mesh.get_surface_count():
		var surface_array = $Mesh.mesh.surface_get_arrays(si)
		var indices: PackedInt32Array = surface_array[Mesh.ARRAY_INDEX]
		var verts: PackedVector3Array = surface_array[Mesh.ARRAY_VERTEX]
		var points: Array[Face.Point] = []
		for vi in len(verts):
			points.append(Face.Point.new(
				self,
				verts[vi],
				(randf()*2-1) * height_base,
				randi(),
				1
			))
		for fi in range(0, len(indices), 3):
			var i0 := indices[fi]
			var i1 := indices[fi+1]
			var i2 := indices[fi+2]
			faces.append(Face.from_points(points[i0], points[i1], points[i2]))
	return faces


func surface_point(p: Vector3, height: float = 0) -> Vector3:
	return (p - core).normalized() * (radius + height) + core
func color(height: float) -> Color:
	if height < 0:
		return Color.BLUE
	else:
		return gradient.sample(height / gradient_scale)



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
	].map(func(v): return v.normalized() * radius)
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
	#print(verts[0])
	$Mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
