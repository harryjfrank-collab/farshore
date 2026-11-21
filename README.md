# Farshore (working title)

A cozy co-op sandbox: dig, build and farm anywhere on a distant, unspoiled coast you can never leave. Explore with friends, and the server owner controls exactly who can do what.

Built with Godot 4, GDScript and godot_voxel.

## Docs

- [Design spec](docs/design-spec.md): pillars, core loop, systems, multiplayer, admin and roadmap
- [Concept note: Farshore](docs/concept-farshore.md): the coastal setting

## Setup

Pinned versions: **Godot 4.7 with Voxel Tools 1.7**, using the prebuilt editor that has the voxel module compiled in.

1. Download the editor for your platform from https://github.com/Zylann/godot_voxel/releases (the "Godot 4.7.x + Voxel Tools 1.7" release, not the GDExtension one).
2. Unzip it anywhere and run it. On macOS the build is unsigned: right-click the app and choose Open the first time.
3. In the Project Manager, choose Import and select this repo's `project.godot`.
4. Check Help > About shows a 4.7 custom build. If the Voxel nodes (VoxelLodTerrain, VoxelTerrain) appear in Add Node, the module is working.

The GDExtension build exists too, but its author notes it hasn't had much testing. Stick with the module build unless there's a reason to switch.

## Phase 0 checklist

- [x] Pick a working title (Farshore)
- [x] Create the Git repository and Godot 4 project
- [ ] Install Godot 4.7 + Voxel Tools 1.7 and open the project
- [ ] First-person controller walking on smooth voxel terrain
- [ ] Dig and fill terrain, synced between a host and one client
- [ ] Place and remove 3 build pieces on a grid, synced
- [ ] `can()` permission gate stub with Owner and Visitor roles
- [ ] Day/night cycle

Goal: a networked gray box with two players digging and building together, no art. If that isn't fun, nothing later will fix it.
