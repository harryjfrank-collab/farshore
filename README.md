# Farshore (working title)

A cozy co-op sandbox: dig, build and farm anywhere on a distant, unspoiled coast you can never leave. Explore with friends, and the server owner controls exactly who can do what.

Built with Godot 4, GDScript and godot_voxel.

## Docs

- [Design spec](docs/design-spec.md): pillars, core loop, systems, multiplayer, admin and roadmap
- [Concept note: Farshore](docs/concept-farshore.md): the coastal setting

## Setup

1. Install the current stable Godot 4 editor (standard build, not .NET).
2. Install godot_voxel. Either use a Godot editor build that includes the voxel module, or add the GDExtension build under `addons/zylann.voxel/`. Check the godot_voxel docs for which option matches your Godot version.
3. Open `project.godot` in the editor.

Version details in the spec were written from memory; check them against current docs before relying on them.

## Phase 0 checklist

- [x] Pick a working title (Farshore)
- [x] Create the Git repository and Godot 4 project
- [ ] Add godot_voxel
- [ ] First-person controller walking on smooth voxel terrain
- [ ] Dig and fill terrain, synced between a host and one client
- [ ] Place and remove 3 build pieces on a grid, synced
- [ ] `can()` permission gate stub with Owner and Visitor roles
- [ ] Day/night cycle

Goal: a networked gray box with two players digging and building together, no art. If that isn't fun, nothing later will fix it.
