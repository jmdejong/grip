class_name Face
extends Node3D

var p0: Point
var p1: Point
var p2: Point

var center: Vector3
var near: float
var far: float
var shape: Planet
var subfaces = null
var depth: int
var resolution: float
var levels: int = 5
var segments: int = 2**levels
const FaceScene = preload("res://scenes/face.tscn")

static func from_points(a: Point, b: Point, c: Point) -> Face:
	var face: Face = FaceScene.instantiate()
	face.p0 = a
	face.p1 = b
	face.p2 = c
	
	return face

func _enter_tree() -> void:
	center = global_transform * ((p0.pos + p1.pos + p2.pos)/3.0)
	near = (global_transform * p0.pos).distance_to(center) * 2.0
	far = near * 2
	shape = p0.shape
	depth = max(p0.depth, p1.depth, p2.depth)
	if $Mesh.mesh == null:
		$Mesh.mesh = build_mesh()
	resolution = p1.pos.distance_to(p2.pos) / segments

func sub_points() -> Dictionary:
	var subpoints: Dictionary = {}
	subpoints[Vector3i(segments, 0, 0)] = p0
	subpoints[Vector3i(0, segments, 0)] = p1
	subpoints[Vector3i(0, 0, segments)] = p2
	for level in levels:
		var step: int = 2**(levels-level)
		for iv: int in range(0, segments, step):
			for iu: int in range(0, segments - iv, step):
				var iw: int = segments - iv - iu
				var a: Point = subpoints[Vector3i(iu, iv, iw)]
				var b: Point = subpoints[Vector3i(iu + step, iv, iw - step)]
				var c: Point = subpoints[Vector3i(iu, iv  + step, iw - step)]
				subpoints[Vector3i(iu + step / 2, iv, iw - step / 2)] = Point.mid(a, b)
				subpoints[Vector3i(iu, iv + step / 2, iw - step / 2)] = Point.mid(a, c)
				subpoints[Vector3i(iu + step / 2, iv + step / 2, iw - step)] = Point.mid(b, c)
	return subpoints
	

func build_mesh():
	var surface := []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	surface[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	surface[Mesh.ARRAY_COLOR] = PackedColorArray()
	surface[Mesh.ARRAY_INDEX] = PackedInt32Array()
	var subpoints := sub_points()
	var i: int = 0
	for iv: int in range(segments+1):
		for iu: int in range(segments - iv + 1):
			var iw: int = segments-iu-iv
			var point: Point = subpoints[Vector3i(iu, iv, iw)]
			var pos: Vector3 = point.pos
			surface[Mesh.ARRAY_VERTEX].append(point.position())
			surface[Mesh.ARRAY_NORMAL].append(point.normal())
			surface[Mesh.ARRAY_COLOR].append(point.color())
			if iv > 0:
				var p: int = i + iv - segments - 2
				surface[Mesh.ARRAY_INDEX].append_array(PackedInt32Array([p, p+1, i]))
				if iu > 0:
					surface[Mesh.ARRAY_INDEX].append_array([p, i, i-1])
			i += 1
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	return mesh

func make_subfaces() -> Array[Face]:
	var m01 := Point.mid(p0, p1)
	var m02 := Point.mid(p0, p2)
	var m12 := Point.mid(p1, p2)
	return [
		Face.from_points(p0, m01, m02),
		Face.from_points(m01, p1, m12),
		Face.from_points(m02, m12, p2),
		Face.from_points(m01, m12, m02)
	]

func remove_subfaces() -> void:
	for face in subfaces:
		if face.subfaces != null:
			face.remove_subfaces()
		face.queue_free()
	subfaces = null


func _process(_delta: float) -> void:
	if resolution < shape.min_resolution:
		return
	var cd: float = get_viewport().get_camera_3d().global_position.distance_to(center)
	$Mesh.visible = cd > near
	$SubFaces.visible = cd <= near
	if subfaces == null && cd <= near:
		subfaces = make_subfaces()
		for face in subfaces:
			$SubFaces.add_child(face)
	if subfaces != null && cd > far:
		remove_subfaces()


static func randomizef(seed: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.set_seed(seed)
	return rng.randf()



class Point:
	var shape: Planet
	var pos: Vector3
	var height: float
	var seed: int
	var depth: int
	var actual: bool = true
	func _init(shape: Planet, pos: Vector3, height: float, seed: int, depth: int) -> void:
		self.shape = shape
		self.pos = pos
		assert(is_equal_approx((pos - shape.core).length_squared(), shape.radius * shape.radius))
		self.height = height
		self.seed = seed
		self.depth = depth
	
	func position() -> Vector3:
		return shape.surface_point(pos, max(height, -0.000001))
	
	func normal() -> Vector3:
		return shape.core.direction_to(pos)
	
	func color() -> Color:
		return shape.color(height)
	
	static func mid(a: Point, b: Point) -> Point:
		assert(a.shape == b.shape)
		var shape: Planet = a.shape
		assert(a.pos != b.pos)
		assert(a.depth >= 0 && b.depth >= 0)
		var seed: int = rand_from_seed(a.seed + b.seed)[0]
		var depth: int = max(a.depth, b.depth) + 1
		return Point.new(
			shape,
			shape.surface_point(a.pos*.5 + b.pos*.5),
			(a.height + b.height) / 2 + (Face.randomizef(seed) * 2 - 1) / 1.7**depth * shape.random_weight,
			seed,
			depth
		)
	
	static func interpolate(a: Point, b: Point, c: Point, uvw: Vector3) -> Point:
		assert(is_equal_approx(uvw.x + uvw.y + uvw.z, 1))
		var p := Point.new(
			a.shape,
			a.shape.surface_point(a.pos * uvw.x + b.pos * uvw.y + c.pos * uvw.z),
			a.height * uvw.x + b.height * uvw.y + c.height * uvw.z,
			0,
			-1
		)
		p.actual = false
		return p
