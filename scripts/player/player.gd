extends CharacterBody3D
## First-person controller: mouse/keyboard and gamepad.
## Terrain edits are sent to the world as intents; the player never touches voxels itself.

@export var walk_speed := 5.0
@export var sprint_speed := 8.5
@export var jump_velocity := 5.5
@export var mouse_sensitivity := 0.0025  # radians per pixel
@export var stick_sensitivity := 3.0  # radians per second at full tilt
@export var reach := 6.0
@export var edit_interval := 0.15  # seconds between edits while held
@export var spawn_timeout := 10.0  # give up waiting for terrain after this long

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var world: Node3D
var terrain: VoxelTerrain
var peer_id := 1

var _spawned := false
var _spawn_wait := 0.0
var _edit_cooldown := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func setup(p_world: Node3D, p_terrain: VoxelTerrain, p_peer_id: int) -> void:
	world = p_world
	terrain = p_terrain
	peer_id = p_peer_id


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		_look(-motion.relative.x * mouse_sensitivity, -motion.relative.y * mouse_sensitivity)
	elif event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if (event as InputEventMouseButton).pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()  # don't dig on the click that recaptures


func _physics_process(delta: float) -> void:
	if not _spawned:
		_try_spawn(delta)
		return

	var look := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	if look != Vector2.ZERO:
		_look(-look.x * stick_sensitivity * delta, -look.y * stick_sensitivity * delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed(&"jump"):
		velocity.y = jump_velocity

	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction := transform.basis * Vector3(input.x, 0.0, input.y)
	var speed := sprint_speed if Input.is_action_pressed(&"sprint") else walk_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()

	_edit_cooldown -= delta
	if _edit_cooldown <= 0.0 and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if Input.is_action_pressed(&"dig"):
			_request_edit(&"dig")
		elif Input.is_action_pressed(&"fill"):
			_request_edit(&"fill")


func _look(yaw: float, pitch: float) -> void:
	rotate_y(yaw)
	head.rotation.x = clampf(head.rotation.x + pitch, deg_to_rad(-89.0), deg_to_rad(89.0))


func _request_edit(action: StringName) -> void:
	var origin := camera.global_position
	var forward := -camera.global_basis.z
	var hit: VoxelRaycastResult = terrain.get_voxel_tool().raycast(origin, forward, reach)
	if hit == null:
		return
	# Dig at the solid voxel we hit; fill in the empty voxel just in front of it.
	var center := Vector3(hit.position) if action == &"dig" else Vector3(hit.previous_position)
	world.request_terrain_edit(peer_id, action, center)
	_edit_cooldown = edit_interval


## Hold the player in the air until the terrain under them has meshed (so its
## collision exists), then drop them onto the surface.
func _try_spawn(delta: float) -> void:
	_spawn_wait += delta
	var p := global_position
	var column := AABB(Vector3(p.x - 8.0, -32.0, p.z - 8.0), Vector3(16.0, p.y + 40.0, 16.0))
	if not terrain.is_area_meshed(column) and _spawn_wait < spawn_timeout:
		return

	var hit: VoxelRaycastResult = terrain.get_voxel_tool().raycast(p, Vector3.DOWN, p.y + 64.0)
	if hit != null:
		global_position = Vector3(p.x, hit.position.y + 2.0, p.z)
	elif _spawn_wait < spawn_timeout:
		return  # meshed but no ground found yet; keep waiting
	velocity = Vector3.ZERO
	_spawned = true
