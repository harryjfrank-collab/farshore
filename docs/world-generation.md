# World generation

_Nov 22, 2026. Decisions for the island generator; Phase 0 skeleton with debug colors._

## Approach

A seeded procedural island with strong authored rules, plus hand-placed set pieces stamped in later (wrecks, old homesteads, the opening beach). Fully hand-sculpted doesn't suit a solo developer, and every server would get the same world, which works against pillar 3 (exploration pays). Fully random gives generic terrain with no sense of place. The generator comes before any polish on the opening scene, because the arrival beach lives inside the generated world.

## Rules

- **Finite island.** Roughly 2 x 2 km, bounded by sea on all sides. This settles the spec's open question: finite is far easier to save, sync and roll back. Size is one constant: `IslandRadius` (default 1000 m) in the graph. Terrain bounds, noise maps and the ocean all scale from it.
- **Sea level is y = 0.** A flat ocean plane sits at y = 0 and runs well past the island edge.
- **Coastline.** A radial falloff distorted by low-frequency noise, so the shore has bays and headlands instead of a circle. The core value is `Inland = 1 - distance / IslandRadius + CoastNoise * CoastWarp`: 0 on the coastline, about 1 at the center, negative at sea.
- **The coast is a timeline.** Every traveller landed on the same shore, so biomes are bands by distance inland. Walking inland moves you through the biomes, the story (newest homesteads near the water, oldest and most overgrown inland) and the tool tiers together.
- **Three surface biomes**, cut from `BiomeBand = Inland + BiomeEdgeNoise * EdgeJitter`, so borders wobble and don't form clean rings:

  | Biome | BiomeBand | Terrain |
  |---|---|---|
  | Shore | below `ShoreEnd` (0.09) | Beaches and low dunes, flat, near sea level |
  | Greenwood | `ShoreEnd` to `GreenwoodEnd` (0.40) | Rolling meadows and coastal forest land, mid height |
  | Old Interior | above `GreenwoodEnd` | Ridged hills and highlands, tallest and roughest |

  Caves come later.
- **Height.** A `CoastProfile` curve maps Inland to a base height (the beach top is about 4 m, the Greenwood edge about 25 m). Each biome then adds its own detail, faded in over `BiomeFade`: dunes on the Shore (faded out at the waterline), gentle rolling noise in Greenwood, ridged noise in the Old Interior. At sea the seabed falls away to `SeabedFloor`.
- **One integer seed drives everything.** Each noise node gets its own seed derived from the world seed. Generation is deterministic: the same seed and graph give the same island on every machine, so clients can later generate unedited terrain locally and only edits go over the network.
- **There is always a walkable beach.** The spawn finder walks outward from the center along seeded directions to the main coastline, then steps back inland to a dry Shore point between 0.6 and 3.5 m above sea level with a slope under 0.2 (about 11 degrees). The player spawns there facing the sea.

## Where things live

| File | Role |
|---|---|
| `world/island_generator.tres` | The VoxelGeneratorGraph. Source of truth for the island shape. |
| `scripts/world/island_generator.gd` | Loads the graph, applies the seed, height and biome queries, spawn beach, survey stats. |
| `shaders/terrain_debug.gdshader` | Debug colors: sand Shore, green Greenwood, grey-brown Old Interior, steep slopes darker. |
| `tools/build_island_graph.gd` | One-off script that wrote the first version of the graph. Rerunning it overwrites graph edits. |

The shader repeats the biome math. It gets the graph's constants as uniforms and the graph's own `CoastNoise` and `BiomeEdgeNoise` (same seed) baked into two textures at about 3 m per pixel, so colors line up with the generator to within a few meters.

## Sculpting the graph in the editor

1. Open `world/island_generator.tres` from the FileSystem dock (or select `VoxelTerrain` in `main.tscn` and click its Generator). The Voxel Graph editor opens in the bottom panel.
2. The graph reads left to right: inputs and named constants, noises, Inland and BiomeBand, base height, biome masks, detail per biome, sum, `OutputSDF`.
3. Tune the named constants and the `CoastProfile` curve; noise settings live on each Noise2D node. The 3D viewport regenerates `VoxelTerrain` around the editor camera as you edit (seed 0 in the editor; the game applies `World.world_seed`).
4. Keep these node names, which code looks up: `IslandRadius`, `CoastWarp`, `EdgeJitter`, `ShoreEnd`, `GreenwoodEnd`, `CoastNoise`, `BiomeEdgeNoise`, `DuneNoise`, `HillNoise`, `HighlandNoise`. Add new noises after the existing ones in `IslandGenerator.NOISE_NODES` so old seeds stay the same.
5. Keep `CoastProfile`'s first point at (0, 0) so the coastline stays at sea level.

## Debug controls

- `World.world_seed` is an exported var. F5 reloads with a random seed and prints it; the seed also shows top right.
- F toggles a free-fly camera (WASD, Space up, Ctrl or C down, Shift fast). It raises the view distance and thins the fog while flying.
- On load the output shows the seed, the spawn beach and a survey line: land area, highest point and biome mix.

## Not yet

Caves, rivers, set pieces, textures and real materials, tides, foliage. Hand-placed set pieces will be stamped into the generated terrain at seeded spots, through the same edit path players use.
