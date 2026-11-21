# Game Design Spec: Farshore (working title)

_Nov 21, 2026 · Harry_

## Pitch and pillars

A cozy, co-op sandbox set in a beautiful, realistic natural world. You can dig, build and farm anywhere. You explore with friends, and the server owner controls exactly who can do what.

The game sits between Creativerse and Stardew Valley: building and digging as simple as Creativerse, a farming rhythm like Stardew, and a hand-built look closer to Valheim or Enshrouded than to cubes.

Pillars. Every feature must serve at least one of these and break none of them.

1. Everything is reshapeable. Terrain can be dug and filled, and anything you build can be torn down for a full refund.

2. Simple over deep. A new player builds a shelter in their first 10 minutes. No recipe grids, no hunger meter, no wiring logic.

3. Exploration pays. New materials, seeds and recipes are found in the world, not ground out of menus.

4. Safe to share. Inviting people into your world is never a risk. Owners decide what visitors can touch, take and break, and every action can be traced and undone.

## World concept (brainstorm)

The world needs a reason to exist, not a plot. The test for each premise: does it explain why you dig, build, farm and explore, and why claims and shared worlds make sense? The story is told only through places, ruins and items; there are no quest-givers or cutscenes.

A. The Regrowth. An earlier people tended this land, then left. Nature took it back, and something they held at bay, the Wilt, crept in. You arrive as settlers. Planting and tending land pushes the Wilt back, so farming is the progression: cultivated land becomes safe at night, and their ruins hold the recipes they left behind.

- Fits: farming matters beyond food; ruins reward exploration; night threats have a reason.
- Risk: "heal the land" is a familiar premise and needs a distinctive look.

B. The Hearth Valleys. A remote mountain range, wild and unmapped. Settlers keep the wild at bay with Hearths, carved stones whose light keeps the night creatures away. Your Hearth's glow is your claim, and you widen it as you build.

- Fits: claims and permissions become part of the world, not a menu. "Light this Hearth to share it with friends" is permissions with a story.
- Risk: on its own it's thin on mystery; it needs something to explore toward.

C. The Receding Water. The world was flooded long ago and the water is slowly going down. Every few in-game weeks, the tide falls and new land, ruins and caves emerge for the whole server at once.

- Fits: a shared progression event for a server ("the water dropped last night!"), natural pacing for updates.
- Risk: world-wide terrain changes are hard technically with player builds near the waterline.

D. The Gardeners' Machines. The land is a giant abandoned garden built by an earlier people. Their stone helpers lie dormant around the world. Find and wake them and they help with chores, which is a light, cozy kind of automation.

- Fits: gives a reason for gentle automation without wiring systems.
- Risk: adds scope (creature AI, tasks); best as a later layer.

Recommendation: A + B. The Regrowth gives the why (heal the land, uncover who was here). Hearths give the how and make the admin system part of the world: a server is a valley, a Hearth is a claim, and lighting someone into your Hearth is sharing permissions. D can join later as the automation update, and C is worth keeping for a sequel or a special server mode.

Emotional core: the one-way trip (draft). In the near future, people can buy passage to a distant, unspoiled world, but there is no return. You went because you needed to leave something behind: a loss, a life that stopped fitting. The world is beautiful and plentiful, and you are building it alone. That is the bittersweet note: abundance without anyone to share it with, at first.

How it ties into Regrowth + Hearths:

- The ruins are earlier travellers. Others made the same trip years ago. Their homesteads, gardens and journals are what you find, and the Wilt grew where they stopped tending. Their stories are told through what they left, not through dialogue.
- A Hearth is a beacon. Lighting one pushes back the Wilt and also signals across the world that someone is here. In multiplayer, that's the fiction for friends joining: other one-way travellers who saw your light.
- Solo is the default emotion; co-op is the relief. Playing alone, the game is quiet and reflective. Inviting someone into your Hearth is the moment the world stops being lonely, which gives the permission system an emotional meaning.
- Tone guardrail: bittersweet, never grim. Grief stays in the background, carried by journals, music and empty homesteads, and the world keeps rewarding care with growth and colour.

Open choice: is the player's reason for leaving fixed (a single backstory), or left unstated so each player brings their own? Unstated fits the light-story goal better.

Tone references. Ghibli-style calm, Breath of the Wild-style ruins that tell their story without words, Valheim-style sense of place.

## Core loop

The loop runs explore → gather → craft → build or farm → unlock, and each pass pushes the player one biome or cave layer further out.

1. Explore. Head out from home and find new terrain, caves, creatures and ruins.

2. Gather. Dig, chop, mine and forage. Better tools open up harder materials.

3. Craft. Turn materials into tools, building pieces, furniture and seeds at crafting stations.

4. Build and farm. Make a home base and grow crops that feed back into crafting and trade.

5. Unlock. New materials unlock new recipes, which open the next biome, and the loop starts again further out.

A session. One in-game day is about 20 real minutes. A typical evening: tend the farm in the morning, go on an expedition at midday, build at dusk, and stay safe at night. Night brings out threats, but it's never punishing; you just go back to your bed.

With friends. Co-op multiplies the loop. One player farms while others explore, and the shared base becomes the group's project.

## Game systems

Each system has a deliberate ceiling. The "cap" column is what we promise not to build in version 1.

| System | Version 1 | Cap (not in v1) |
|---|---|---|
| Terrain | Smooth voxel terrain you can dig and fill; 3 surface biomes + caves; day/night | Fluids that flow, erosion, floating islands |
| Building | Grid-snapped pieces (floor, wall, roof, stairs, door, window, beam) in 4 materials; free placement for furniture | Structural stress, freeform sculpting, wiring/logic |
| Farming | Till, plant, water, harvest; ~12 crops; crops grow in real time while the area is loaded | Seasons, soil quality, crossbreeding |
| Crafting | Flat recipe list per station (workbench, forge, kitchen); recipes unlock on first pickup of an ingredient | Recipe grids, item durability, quality tiers |
| Creatures | ~6 passive animals (some tameable for produce); ~4 hostile creatures at night or underground | Breeding trees, mounts, boss fights |
| Combat | One-button melee + bow; health regenerates out of combat | Skill trees, stamina, armour sets |
| Progression | Tool tiers (wood → stone → copper → iron) gate which materials you can mine; materials gate biomes | Character levels, XP |
| Death | Respawn at bed; items dropped stay in a marker for 15 minutes | Permadeath, hardcore mode (maybe later as a server option) |

Look and feel. Realistic materials and lighting (CC0 textures from Poly Haven and ambientCG to start), a slightly warm, saturated grade so it stays cozy. Third-person and first-person camera.

## Multiplayer architecture

The game is server-authoritative from the first prototype: clients only send intents, and the server decides what happens. Single-player is just a private server running inside the game.

A client asks to dig or take an item; the permission gate allows or refuses it, the world applies it, the log records it, and every client gets the new state.

- No trust in clients. Inventory, position checks, and block changes are all validated on the server. This blocks most cheating and is what makes container limits enforceable.
- Hosting. Players host from the main menu (listen server) or run a headless dedicated server on Windows, Linux or Mac.
- Sync. Voxel edits are sent as small deltas; godot_voxel's `VoxelTerrainMultiplayerSynchronizer` streams terrain blocks from the server to each client around their position. Farming and creatures run only on the server.
- Cost for a solo developer. Building this in from day one adds roughly 30–50% to early prototype time, but retrofitting it later would mean rewriting most systems.

## Admin and permissions

Every player action is checked on the server by one function, can(player, action, target), before it happens. Because there is exactly one gate, every rule below is a data change, not new code.

Roles. Owners can create custom roles; these four ship as defaults.

| Role | Can do | Default for |
|---|---|---|
| Owner | Everything, including transfer ownership and delete world | World creator |
| Admin | Manage players, roles, claims and rollbacks; cannot remove the Owner | Trusted friends |
| Builder | Build, dig, farm and use containers inside claims they're added to | Regular players |
| Visitor | Walk, look, chat; touch nothing unless a claim allows it | New joiners |

Claims. A claim is a box-shaped area with an owner and per-role rules: build, dig, open doors, use stations, harvest crops, open containers. Unclaimed land follows world-wide defaults the Owner sets, such as "anyone can dig outside claims" or "nobody can".

Containers. Each chest can have its own rules:

- Take limit: max items per player per day (for example, 10 per day from the shared food chest).
- Deposit-only: visitors can give but not take (donation boxes).
- Per-item locks: certain items can never be removed.
- Owner-only: private storage, even inside a shared base.

Moderation tools.

- Kick, timed ban (1 hour to forever) and permanent ban by platform account ID, not by name.
- Mute and freeze (player can't move or act) while an admin investigates.
- Join rules: open, invite code, allowlist, or approval queue.
- Spawn protection radius and new-player grace period (Visitor until promoted, or auto-promote after N hours).

Audit log and rollback. Every block change, container transaction and permission change is logged with who, what, where and when. Admins can inspect a block or chest to see its history, and roll back one player's changes in an area over a time window. This is the feature that makes "Safe to share" real; it is also the most expensive to build, so it ships in the MVP, not the vertical slice.

Where admins do it. An in-game admin panel, chat commands (/kick, /ban, /claim, /rollback), and a config file for dedicated servers.

## Tech stack and platforms

The stack is Godot 4 with GDScript, the godot_voxel extension for terrain, and Steam for distribution. That covers PC and Mac directly; consoles stay possible but aren't planned for.

| Area | Choice | Why |
|---|---|---|
| Engine | Godot 4 (MIT) | Free, no royalties, fast iteration for a solo developer |
| Language | GDScript; C++ only if profiling demands it | Fastest to write; avoids C# console-export gaps |
| Terrain | godot_voxel `VoxelTerrain` with `VoxelMesherTransvoxel` (smooth) | Diggable smooth terrain, streaming, built-in multiplayer sync (`VoxelTerrainMultiplayerSynchronizer`). No LOD: see note below |
| Networking | Godot high-level multiplayer (ENet) for LAN/direct; Steam relay via GodotSteam for invites and NAT traversal | Same game code; transport is swappable |
| Saves | Voxel regions in the module's own format; game state (inventories, claims, permissions, audit log) in SQLite | Audit log and rollback need real queries |
| Art | CC0 textures and models (Poly Haven, ambientCG) first; commission or buy packs later | A solo developer can't model a whole world |

Terrain LOD vs multiplayer (checked Nov 21, 2026 against godot_voxel docs). The module's multiplayer sync only supports `VoxelTerrain`; `VoxelLodTerrain` has no multiplayer support yet (planned upstream). So v1 uses `VoxelTerrain`: smooth terrain without LOD, which caps view distance (128 voxels by default). Fog and a finite world help hide it. Revisit if upstream adds LOD sync.

Platforms.

- Windows and Linux: straightforward exports; Steam Deck comes nearly free if the controls work on a gamepad.
- Mac: Godot exports Apple Silicon and Intel builds; shipping needs an Apple Developer account for code signing and notarization.
- Consoles: Godot's console exports aren't public (platform NDAs), so a port goes through a porting partner such as W4 Games. godot_voxel is native C++ and would need compiling for each console, which is the biggest port risk. Mitigation: design for gamepad from day one, keep to GDScript, and revisit after a PC launch.

All version details here are from memory and should be checked against current docs before setting up the project.

## Roadmap

The first goal is a networked gray box: two players digging and building together in about 2 months, with no art. If that isn't fun, nothing later will fix it.

Each gate is a real stop: if it fails, fix the loop before adding content. Scope moves right, never left: anything new goes into a later phase unless something of equal size comes out.

First tasks (phase 0).

- [ ] Pick the world concept and a working title
- [ ] Create a Git repository and a Godot 4 project with godot_voxel
- [ ] First-person controller walking on smooth voxel terrain
- [ ] Dig and fill terrain, synced between a host and one client
- [ ] Place and remove 3 build pieces on a grid, synced
- [ ] can() permission gate stub with Owner and Visitor roles
- [ ] Day/night cycle

## Out of scope and open questions

Out of scope for version 1: written quests and NPC dialogue, wiring or logic blocks, hunger and thirst, item durability, skill trees, mods and scripting API, cross-play with consoles, more than 16 players per server.

Open questions.

- [ ] World concept: go with Regrowth + Hearths, or another premise?
- [ ] Server size target: 2–8 friends, or up to 16 on dedicated servers?
- [ ] Finite worlds (for example 4 × 4 km) or endless? Finite is far easier to save, sync and roll back.
- [ ] First-person, third-person, or both from day one?
- [ ] Working title.
- [ ] Price and model: one-time purchase assumed; no microtransactions.
