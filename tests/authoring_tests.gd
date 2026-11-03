class_name AuthoringTests
extends SceneTree

const DESIGN = preload("res://scripts/level_design.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if value:
		print("PASS: ",message)
	else:
		failures += 1
		printerr("FAIL: ",message)

func matches(piece: PrimitivePiece, root_node: Node3D) -> bool:
	var data := piece.definition(root_node)
	var expected := PrimitiveGeometry.vertices(data)
	var actual: PackedVector3Array = piece.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for vertex in actual:
		var transformed := root_node.to_local(piece.to_global(vertex))
		var found := false
		for point in expected:
			found = found or point.distance_to(transformed)<0.001
		if not found:
			return false
	return true

func _run() -> void:
	var installation := DESIGN.create_installation()
	root.add_child(installation)
	await process_frame
	var pieces := PrimitivePiece.collect(installation)
	check(pieces.size()==DESIGN.pieces().size(),"saved scene supplies the complete runtime figure list")
	var cap: PrimitivePiece = installation.get_node("RedCrossbar")
	var stick: PrimitivePiece = installation.get_node("WoodenStick")
	var tower: PrimitivePiece = installation.get_node("BlueTower")
	var roof: PrimitivePiece = installation.get_node("RoundedRoof")
	check(is_equal_approx(cap.rotation.y,PI/2.0) and is_equal_approx(stick.rotation.y,PI/2.0),"crossbar and stick have the requested 90 degree rotation")
	check(roof.radius*2.0>tower.dimensions.x and roof.depth>tower.dimensions.z,"roof slightly overhangs both sides of the tower")
	var piece := pieces[0]
	piece.dimensions = Vector3(0.8,0.7,0.9)
	piece.position += Vector3(0.2,0.4,-0.3)
	piece.rotation = Vector3(0.2,0.6,-0.1)
	piece.scale = Vector3(0.8,1.2,0.9)
	check(matches(piece,installation),"editor size, rotation, scale and position match projected geometry")
	var group := Node3D.new()
	installation.add_child(group)
	group.transform = Transform3D(Basis.from_euler(Vector3(0.1,0.3,0)),Vector3(0.2,0.1,0.4))
	piece.reparent(group,false)
	check(matches(piece,installation),"grouped figure transforms also match the geometry source")
	var duplicate := piece.duplicate() as PrimitivePiece
	group.add_child(duplicate)
	duplicate.position += Vector3(1,0,0)
	check(PrimitivePiece.collect(installation).size()==pieces.size()+1 and matches(duplicate,installation),"duplicated figures can be assembled without changing gameplay code")
	installation.transform = Transform3D(Basis.from_euler(Vector3(0,0.2,0)).scaled(Vector3(1.1,0.9,1.0)),Vector3(0.1,0.2,0.3))
	var descriptions := DESIGN.describe_installation(installation)
	var root_pose_ok := true
	var nodes := PrimitivePiece.collect(installation)
	for i in nodes.size():
		var expected := PrimitiveGeometry.vertices(descriptions[i])
		var actual: PackedVector3Array = nodes[i].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex in actual:
			var found := false
			for point in expected:
				found = found or point.distance_to(nodes[i].to_global(vertex))<0.001
			root_pose_ok = root_pose_ok and found
	check(root_pose_ok,"whole-layout transforms remain consistent with physical geometry")
	for path in ["res://scenes/primitives/box.tscn","res://scenes/primitives/half_cylinder.tscn"]:
		var prefab: PrimitivePiece = load(path).instantiate()
		root.add_child(prefab)
		check(prefab.mesh != null,"reusable primitive scene loads: "+path)
		prefab.queue_free()
	installation.queue_free()
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
