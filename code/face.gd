class_name Face
extends Node3D

var points: Array[Point]

var center: Vector3
var near: float
var far: float
var shape: Shape
const segments := 5
var subfaces = null
const FaceScene = preload("res://scenes/face.tscn")

static func from_points(a: Point, b: Point, c: Point) -> Face:
	var face: Face = FaceScene.instantiate()
	face.points = [a, b, c]
	return face
	

func hash(v: Vector3) -> float:
	return 0

func _enter_tree() -> void:
	assert(len(points) == 3)
	center = global_transform * ((points[0].pos + points[1].pos + points[2].pos)/3.0)
	near = (global_transform * points[0].pos).distance_to(center) * 4.0
	far = near * 2
	shape = points[0].shape
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
	for iv: int in range(segments+1):
		var v: float = float(iv) / segments
		for iu: int in range(segments - iv + 1):
			var u: float = float(iu) / segments
			var w: float = 1.0 - u - v
			var point := Point.interpolate(points[0], points[1], points[2], Vector3(u, v, w))
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
	var m01: Point = points[0].mid(points[1])
	var m02: Point = points[0].mid(points[2])
	var m12: Point = points[1].mid(points[2])
	return [
		Face.from_points(points[0], m01, m02),
		Face.from_points(m01, points[1], m12),
		Face.from_points(m02, m12, points[2]),
		Face.from_points(m01, m12, m02)
	]

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


class Shape:
	var core: Vector3 = Vector3(0, 0, 0)
	var radius: float = 1
	var gradient: Gradient
	func surface_point(p: Vector3) -> Vector3:
		return (p - core).normalized() * radius + core

class Point:
	var shape: Shape
	var pos: Vector3
	var height: float
	var seed: int
	var depth: int
	var actual: bool = true
	func _init(shape: Shape, pos: Vector3, height: float, seed: int, depth: int) -> void:
		self.shape = shape
		self.pos = pos
		assert(is_equal_approx((pos - shape.core).length_squared(), shape.radius * shape.radius))
		self.height = height
		self.seed = seed
		self.depth = depth
	
	func position() -> Vector3:
		return pos
	
	func normal() -> Vector3:
		return shape.core.direction_to(pos)
	
	func color() -> Color:
		return shape.gradient.sample(height)
	
	func mid(other: Point) -> Point:
		assert(self.shape == other.shape)
		assert(self.pos != other.pos)
		return Point.new(
			self.shape,
			self.shape.surface_point((self.pos + other.pos) / 2),
			(self.height + other.height) / 2,
			rand_from_seed(self.seed + other.seed)[0],
			max(depth, other.depth) + 1
		)
	
	static func interpolate(a: Point, b: Point, c: Point, uvw: Vector3) -> Point:
		assert(is_equal_approx(uvw.x + uvw.y + uvw.z, 1))
		var p := Point.new(
			a.shape,
			(a.pos * uvw.x + b.pos * uvw.y + c.pos * uvw.z).normalized() * a.shape.radius,
			a.height * uvw.x + b.height * uvw.y + c.height * uvw.z,
			0,
			-1
		)
		p.actual = false
		return p
	
