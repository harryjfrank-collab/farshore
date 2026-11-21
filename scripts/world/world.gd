extends Node3D
## World root. Owns the authoritative terrain edit path.
##
## Clients never edit terrain directly: they call request_terrain_edit() with an
## intent, the server checks Permissions.can(), applies the edit, and (later) the
## voxel multiplayer synchronizer sends the result to everyone. In single player
## the local player is peer 1, the server.

const EDIT_RADIUS := 1.8
const PLAYER_CLEARANCE := 0.5  # keep fills from burying a player

@onready var terrain: VoxelTerrain = $VoxelTerrain
@onready var player: CharacterBody3D = $Player


func _ready() -> void:
	Permissions.set_role(1, Permissions.Role.OWNER)
	player.setup(self, terrain, 1)


## Single entry point for terrain edits. Becomes the server side of an RPC in the
## networking task; keep its arguments plain data (ints, StringNames, Vector3).
func request_terrain_edit(peer_id: int, action: StringName, center: Vector3) -> bool:
	if action != &"dig" and action != &"fill":
		return false
	if not Permissions.can(peer_id, action, center):
		return false
	if action == &"fill" and _fill_would_bury_player(center):
		return false

	var vt := terrain.get_voxel_tool()
	vt.channel = VoxelBuffer.CHANNEL_SDF
	vt.mode = VoxelTool.MODE_REMOVE if action == &"dig" else VoxelTool.MODE_ADD
	vt.do_sphere(center, EDIT_RADIUS)
	return true


func _fill_would_bury_player(center: Vector3) -> bool:
	# Approximate the capsule with two points (feet and head).
	var feet := player.global_position + Vector3.UP * 0.4
	var head := player.global_position + Vector3.UP * 1.4
	var limit := EDIT_RADIUS + PLAYER_CLEARANCE
	return center.distance_to(feet) < limit or center.distance_to(head) < limit
