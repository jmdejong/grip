extends Node3D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("meshing")
	for si in get_parent().mesh.get_surface_count():
		var surface_array = get_parent().mesh.surface_get_arrays(si)
		var indices: PackedInt32Array = surface_array[Mesh.ARRAY_INDEX]
		var verts: PackedVector3Array = surface_array[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = surface_array[Mesh.ARRAY_NORMAL]
		for fi in range(0, len(indices), 3):
			var surface := []
			surface.resize(Mesh.ARRAY_MAX)
			var i0 := indices[fi]
			var i1 := indices[fi+1]
			var i2 := indices[fi+2]
			surface[Mesh.ARRAY_VERTEX] = PackedVector3Array([
				verts[i0],
				verts[i1],
				verts[i2],
				(verts[i0] + verts[i1])/2,
				(verts[i0] + verts[i2])/2,
				(verts[i2] + verts[i1])/2
			])
			surface[Mesh.ARRAY_NORMAL] = PackedVector3Array([
				normals[i0],
				normals[i1],
				normals[i2],
				(normals[i0] + normals[i1])/2,
				(normals[i0] + normals[i2])/2,
				(normals[i2] + normals[i1])/2
			])
			surface[Mesh.ARRAY_INDEX] = PackedInt32Array([
				0, 3, 4,
				3, 1, 5,
				4, 5, 2,
				4, 3, 5
			])
			var face := MeshInstance3D.new()
			face.mesh = ArrayMesh.new()
			face.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
			add_child(face)
			print("face ", face.global_position, " ", face.global_transform * face.get_aabb().get_center())

func _on_visibility_changed() -> void:
	print("visibility changed")
	if is_visible_in_tree():
		print("visible")
	else:
		print("invisible")


func _on_planet_mesh_visibility_changed() -> void:
	print("parent changed")
	if is_visible_in_tree():
		print("parent visible")
	else:
		print("parent invisible")
