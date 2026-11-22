extends Node3D
## World root. Builds the island from a seed and owns the authoritative terrain
## edit path.
##
## Clients never edit terrain directly: they call request_terrain_edit() with an
## intent, the server checks Permissions.can(), applies the edit, and (later) the
## voxel multiplayer synchronizer sends the result to everyone. In single player
## the local player is peer 1, the server.
##
## World generation (docs/world-generation.md) is deterministic from world_seed,
## so later every client can generate unedited terrain itself and only edits
## need syncing.

const EDIT_RADIUS := 1.8
const PLAYER_CLEARANCE := 0.5  # keep fills from burying a player
const SPAWN_DROP_HEIGHT := 20.0  # spawn this far above the beach, then fall
const FLY_FOG_SCALE := 0.3  # thinner fog while surveying in fly mode

## One integer drives the whole island. F5 picks a new random one.
@export var world_seed := 1
## Print island stats (size, height, biome mix) on load. Costs about a second.
@export var print_survey := true

## Set by the F5 debug reload; survives the scene reload, overrides world_seed.
static var _seed_override := -1

var island: IslandGenerator
var _base_fog_density := 0.0

@onready var terrain: VoxelTerrain = $VoxelTerrain
@onready var ocean: MeshInstance3D = $Ocean
@onready var environment: Environment = $WorldEnvironment.environment
@onready var player: CharacterBody3D = $Player
@onready var seed_label: Label = $HUD/SeedLabel


func _ready() -> void:
	if _seed_override >= 0:
		world_seed = _seed_override
	print("[World] Seed %d" % world_seed)
	seed_label.text = "Seed %d" % world_seed

	island = IslandGenerator.new(world_seed)
	_setup_terrain()
	_setup_ocean()
	_base_fog_density = environment.fog_density

	var spawn := island.find_spawn_beach()
	var p: Vector3 = spawn.position
	if spawn.ok:
		print("[World] Spawn beach at (%.0f, %.1f, %.0f), slope %.2f, found on try %d" % [p.x, p.y, p.z, spawn.slope, spawn.tries])
	else:
		push_warning("[World] Seed %d has no good beach; best spot (%.0f, %.1f, %.0f) slope %.2f" % [world_seed, p.x, p.y, p.z, spawn.slope])
	if print_survey:
		var s := island.survey()
		print("[World] Land %.2f km2, highest %.0f m, Shore %d%%, Greenwood %d%%, Old Interior %d%%" % [
			s.land_km2, s.max_height, s.shore * 100, s.greenwood * 100, s.old_interior * 100])

	Permissions.set_role(1, Permissions.Role.OWNER)
	player.setup(self, terrain, 1)
	player.fly_mode_changed.connect(_on_fly_mode_changed)
	player.place_for_spawn(p + Vector3.UP * SPAWN_DROP_HEIGHT, spawn.facing)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"reseed"):
		_seed_override = randi() % 1_000_000
		print("[World] F5: reloading with new seed %d" % _seed_override)
		get_tree().reload_current_scene()


func _setup_terrain() -> void:
	terrain.generator = island.graph
	terrain.bounds = island.terrain_bounds()
	var mat := terrain.material_override as ShaderMaterial
	if mat == null:
		push_error("[World] VoxelTerrain needs the terrain_debug ShaderMaterial as material_override")
		return
	island.apply_to_material(mat)


func _setup_ocean() -> void:
	# Flat sea at y = 0, three times wider than the terrain so it runs to the fog.
	var plane := ocean.mesh as PlaneMesh
	var side := island.map_half * 6.0
	plane.size = Vector2(side, side)
	ocean.position = Vector3.ZERO


func _on_fly_mode_changed(flying: bool) -> void:
	environment.fog_density = _base_fog_density * (FLY_FOG_SCALE if flying else 1.0)


## Generated surface height (ignores edits). Used to lift the player out of the
## ground when leaving fly mode.
func surface_height_hint(x: float, z: float) -> float:
	return island.height_at(x, z, false)


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
