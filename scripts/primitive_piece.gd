@tool
class_name PrimitivePiece
extends MeshInstance3D

@export_enum("box", "half_cylinder") var primitive := "box":
	set(value):
		primitive = value
		_refresh()
@export var dimensions := Vector3.ONE:
	set(value):
		dimensions = value.max(Vector3.ONE * 0.01)
		_refresh()
@export_range(0.01,10.0,0.01) var radius := 0.37:
	set(value):
		radius = maxf(value,0.01)
		_refresh()
@export_range(0.01,10.0,0.01) var depth := 0.72:
	set(value):
		depth = maxf(value,0.01)
		_refresh()
@export var surface_color := Color("ded0a6"):
	set(value):
		surface_color = value
		_refresh()
@export var hazardous := false

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	if not is_inside_tree():
		return
	mesh = PrimitiveGeometry.mesh(_shape())
	var material := StandardMaterial3D.new()
	material.resource_local_to_scene = true
	material.albedo_color = surface_color
	material.roughness = 0.55
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func _shape() -> Dictionary:
	return {"id":str(name),"primitive":primitive,"center":Vector3.ZERO,"size":dimensions,"radius":radius,"depth":depth,"color":surface_color,"hazard":hazardous}

func definition(root: Node3D) -> Dictionary:
	var pose := transform
	var ancestor := get_parent()
	while ancestor != root and ancestor is Node3D:
		pose = ancestor.transform * pose
		ancestor = ancestor.get_parent()
	var result := _shape()
	result.center = pose.origin
	result.transform = pose
	return result

static func collect(root: Node) -> Array[PrimitivePiece]:
	var found: Array[PrimitivePiece] = []
	for child in root.get_children():
		if child is PrimitivePiece:
			found.append(child)
		found.append_array(collect(child))
	return found
