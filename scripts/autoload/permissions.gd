extends Node
## The single permission gate. Every player action is checked here before it happens.
## Phase 0 stub: Owner and Visitor roles, no claims yet. Rules are data, so adding
## Admin/Builder, custom roles and per-claim rules later means changing data, not callers.

enum Role { OWNER, VISITOR }

## Which actions each role may perform. &"*" means everything.
const RULES := {
	Role.OWNER: [&"*"],
	Role.VISITOR: [],  # walk, look, chat only: touch nothing
}

var _roles: Dictionary = {}  # player_id (int) -> Role


func set_role(player_id: int, role: Role) -> void:
	_roles[player_id] = role


func get_role(player_id: int) -> Role:
	return _roles.get(player_id, Role.VISITOR)


## can(player, action, target): true if player_id may perform action on target.
## target is unused until claims exist; it is a world position for terrain edits.
func can(player_id: int, action: StringName, _target: Variant = null) -> bool:
	var allowed: Array = RULES.get(get_role(player_id), [])
	return allowed.has(&"*") or allowed.has(action)
