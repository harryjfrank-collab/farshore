# Farshore (working title)

A cozy co-op sandbox: dig, build and farm anywhere on a distant, unspoiled coast you can never leave. Explore with friends, and the server owner controls exactly who can do what.

Built with Godot 4, GDScript and godot_voxel.

## Docs

- [Design spec](docs/design-spec.md): pillars, core loop, systems, multiplayer, admin and roadmap
- [Concept note: Farshore](docs/concept-farshore.md): the coastal setting
- [World generation](docs/world-generation.md): the seeded island, biome bands, spawn beach and how to sculpt the generator graph

## Setup

Pinned versions: **Godot 4.7 with Voxel Tools 1.7**, using the prebuilt editor that has the voxel module compiled in.

1. Download the editor for your platform from https://github.com/Zylann/godot_voxel/releases (the "Godot 4.7.x + Voxel Tools 1.7" release, not the GDExtension one).
2. Unzip it anywhere and run it. On macOS the build is unsigned: right-click the app and choose Open the first time.
3. In the Project Manager, choose Import and select this repo's `project.godot`.
4. Check Help > About shows a 4.7 custom build. If the Voxel nodes (VoxelLodTerrain, VoxelTerrain) appear in Add Node, the module is working.

The GDExtension build exists too, but its author notes it hasn't had much testing. Stick with the module build unless there's a reason to switch.

## Controls

Keyboard/mouse: WASD move, Shift sprint, Space jump, left click dig, right click fill, Esc frees the mouse (click to recapture).

Gamepad: left stick move, right stick look, A jump, left stick click sprint, right trigger dig, left trigger fill.

Debug: F (gamepad Back) toggles a free-fly camera (Space up, Ctrl or C or gamepad B down, Shift fast). F5 reloads with a new random island seed and prints it to the output.

Dig and fill run through `World.request_terrain_edit()` and the `Permissions.can()` gate, the same path a networked client will use. Local dig/fill works now.

## Order of work

Environment and look come before multiplayer. Multiplayer is deferred, not dropped. The rule that keeps that safe: every player action that changes the world keeps going through `request_terrain_edit()` / `can()`, and gameplay systems that change shared state (building pieces, inventory, chests, crops) wait until after a small two-window sync test. World generation, lighting and look don't touch networking.

To check islands without opening a window:

```bash
godot --headless --path . --script res://tools/survey_seeds.gd -- --maps=/tmp/maps 1 2 3 4 5
```

## Phase 0 checklist

- [x] Pick a working title (Farshore)
- [x] Create the Git repository and Godot 4 project
- [ ] Install Godot 4.7 + Voxel Tools 1.7 and open the project
- [x] First-person controller walking on smooth voxel terrain (spawn and walking run in a headless test build; still needs a hands-on test)
- [x] World generation skeleton: seeded 2 x 2 km island, Shore / Greenwood / Old Interior bands, guaranteed spawn beach, ocean, debug biome colors
- [x] Debug tools: free-fly camera (F), new random seed (F5), seed survey script
- [ ] Dig and fill terrain, synced between a host and one client
- [ ] Place and remove 3 build pieces on a grid, synced
- [x] `can()` permission gate stub with Owner and Visitor roles
- [ ] Day/night cycle

Goal: a networked gray box with two players digging and building together, no art. If that isn't fun, nothing later will fix it.
