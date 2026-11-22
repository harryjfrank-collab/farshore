class_name IslandGenerator
extends RefCounted
## Loads the island VoxelGeneratorGraph, applies a seed to it, and answers
## questions about the generated island on the CPU: shape parameters for the
## terrain shader, surface height, biome, and where the spawn beach is.
##
## Determinism: everything here and in the graph is a pure function of the seed
## and the graph resource, so every machine builds the same unedited island.
## Only edits will need to go over the network.

const GRAPH_PATH := "res://world/island_generator.tres"

## Noise nodes in the graph, in a fixed order. The order decides each noise's
## derived seed, so append new noises at the end to keep old seeds stable.
const NOISE_NODES: Array[StringName] = [
	&"CoastNoise", &"BiomeEdgeNoise", &"DuneNoise", &"HillNoise", &"HighlandNoise",
]

## The baked noise maps cover the whole terrain area at this many pixels a side.
const MAP_RESOLUTION := 1024
## Terrain and maps extend this far past IslandRadius, so the sea all around the
## island is generated too. Matches the reach of CoastWarp with some margin.
const MAP_MARGIN := 1.6

const SKY := 300.0  # height queries start here
const ABYSS := -80.0  # and give up here

## Spawn rules: a dry Shore point, just above sea level, with a gentle slope.
const SPAWN_MIN_HEIGHT := 0.6
const SPAWN_MAX_HEIGHT := 3.5
const SPAWN_MAX_SLOPE := 0.2  # rise over run, about 11 degrees
const SPAWN_TRIES := 64
const GOLDEN_ANGLE := 2.39996323

enum Biome { SEA, SHORE, GREENWOOD, OLD_INTERIOR }

var world_seed: int
var graph: VoxelGeneratorGraph

# Shape parameters, read from the graph's named Constant nodes.
var island_radius := 1000.0
var coast_warp := 0.28
var edge_jitter := 0.05
var shore_end := 0.09
var greenwood_end := 0.40

var coast_noise: FastNoiseLite
var edge_noise: FastNoiseLite

## Half the side of the square the terrain and noise maps cover, centered on 0.
var map_half := 1600.0


func _init(p_seed: int) -> void:
	world_seed = p_seed
	# CACHE_MODE_IGNORE gives a fresh graph with fresh noise resources, so the
	# seeds set below never leak into the copy the editor or scene holds.
	graph = ResourceLoader.load(GRAPH_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if graph == null:
		push_error("IslandGenerator: could not load %s" % GRAPH_PATH)
		return
	var f := graph.get_main_function()

	for i in NOISE_NODES.size():
		var noise: FastNoiseLite = f.get_node_param(_find(f, NOISE_NODES[i]), 0)
		noise.seed = derive_seed(world_seed, i)

	coast_noise = f.get_node_param(_find(f, &"CoastNoise"), 0)
	edge_noise = f.get_node_param(_find(f, &"BiomeEdgeNoise"), 0)
	island_radius = _constant(f, &"IslandRadius")
	coast_warp = _constant(f, &"CoastWarp")
	edge_jitter = _constant(f, &"EdgeJitter")
	shore_end = _constant(f, &"ShoreEnd")
	greenwood_end = _constant(f, &"GreenwoodEnd")
	map_half = island_radius * MAP_MARGIN

	var result: Dictionary = graph.compile()
	if not result.success:
		push_error("IslandGenerator: graph failed to compile: %s (node %s)" % [result.message, result.get("node_id")])


## Each noise gets its own seed derived from the world seed, so neighbouring
## world seeds don't produce related islands and the noises don't line up.
static func derive_seed(p_seed: int, index: int) -> int:
	var h := (p_seed * 1103515245 + (index + 1) * 2654435761) & 0x7fffffff
	h = ((h >> 16) ^ h) * 0x45d9f3b & 0x7fffffff
	return (h >> 16) ^ h


## Terrain bounds: the square the island and its surrounding sea fit in.
func terrain_bounds() -> AABB:
	var half := ceilf(map_half / 16.0) * 16.0
	return AABB(Vector3(-half, -64.0, -half), Vector3(half * 2.0, 64.0 + 192.0, half * 2.0))


# --- Shape math. The terrain shader repeats exactly this; keep them in sync. ---

## 0 on the coastline, about 1 at the center, negative out at sea.
func inland_at(x: float, z: float) -> float:
	var radial := Vector2(x, z).length() / island_radius
	return 1.0 - radial + coast_noise.get_noise_2d(x, z) * coast_warp


## Inland plus edge jitter: the value the biome bands are cut from.
func band_at(x: float, z: float) -> float:
	return inland_at(x, z) + edge_noise.get_noise_2d(x, z) * edge_jitter


func biome_at(x: float, z: float) -> Biome:
	if inland_at(x, z) < 0.0:
		return Biome.SEA
	var band := band_at(x, z)
	if band < shore_end:
		return Biome.SHORE
	if band < greenwood_end:
		return Biome.GREENWOOD
	return Biome.OLD_INTERIOR


## Generated (unedited) surface height at x, z, straight from the graph.
## precise = false is about 2 m accurate and much cheaper.
func height_at(x: float, z: float, precise := true) -> float:
	var d := graph.raycast_sdf_approx(Vector3(x, SKY, z), Vector3(x, ABYSS, z), 2.0)
	if d < 0.0:
		return ABYSS
	var coarse := SKY - d
	if not precise:
		return coarse
	var top := coarse + 2.5
	var fine := graph.raycast_sdf_approx(Vector3(x, top, z), Vector3(x, coarse - 0.5, z), 0.05)
	return top - fine if fine >= 0.0 else coarse


# --- Noise maps for the shader ---

## Bakes a noise into a texture covering the terrain square, one sample per
## texel center, using the same noise resource (same seed) as the graph.
func bake_noise_texture(noise: FastNoiseLite) -> ImageTexture:
	var px := map_half * 2.0 / MAP_RESOLUTION
	var origin := -map_half + px * 0.5  # texel centers
	# get_noise_2d(i) samples at (i + offset) * frequency. Scaling frequency by
	# px and offset by 1/px makes pixel i land on world x = origin + i * px.
	var n: FastNoiseLite = noise.duplicate()
	n.frequency = noise.frequency * px
	n.offset = Vector3((origin + noise.offset.x) / px, (origin + noise.offset.y) / px, noise.offset.z)
	var img := n.get_image(MAP_RESOLUTION, MAP_RESOLUTION, false, false, false)  # raw, mapped to 0..1
	return ImageTexture.create_from_image(img)


func apply_to_material(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter(&"coast_noise_map", bake_noise_texture(coast_noise))
	mat.set_shader_parameter(&"edge_noise_map", bake_noise_texture(edge_noise))
	mat.set_shader_parameter(&"map_half", map_half)
	mat.set_shader_parameter(&"island_radius", island_radius)
	mat.set_shader_parameter(&"coast_warp", coast_warp)
	mat.set_shader_parameter(&"edge_jitter", edge_jitter)
	mat.set_shader_parameter(&"shore_end", shore_end)
	mat.set_shader_parameter(&"greenwood_end", greenwood_end)


# --- Spawn beach ---

## Finds a walkable beach point on the main coast. Deterministic for a seed.
## Returns { ok, position, facing (toward the sea), slope, tries }.
func find_spawn_beach() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed
	var start := rng.randf() * TAU
	var best := {}

	for k in SPAWN_TRIES:
		var angle := start + k * GOLDEN_ANGLE
		var dir := Vector2(cos(angle), sin(angle))
		var coast_r := _coast_distance(dir)
		if coast_r < 0.0:
			continue
		for back in [8.0, 14.0, 22.0, 32.0, 45.0]:
			var p: Vector2 = dir * (coast_r - back)
			var h := height_at(p.x, p.y)
			if h < SPAWN_MIN_HEIGHT or h > SPAWN_MAX_HEIGHT:
				continue
			if biome_at(p.x, p.y) != Biome.SHORE:
				continue
			var slope := slope_at(p.x, p.y)
			var candidate := {
				ok = slope <= SPAWN_MAX_SLOPE,
				position = Vector3(p.x, h, p.y),
				facing = Vector3(dir.x, 0.0, dir.y),
				slope = slope,
				tries = k + 1,
			}
			if candidate.ok:
				return candidate
			if best.is_empty() or slope < best.slope:
				best = candidate

	if best.is_empty():
		# Should never happen with sane graph settings. Fall back to the center.
		var h0 := height_at(0.0, 0.0)
		best = { ok = false, position = Vector3(0.0, h0, 0.0), facing = Vector3.FORWARD, slope = INF, tries = SPAWN_TRIES }
	return best


## Largest rise over run around a point, from four height samples.
func slope_at(x: float, z: float, d := 2.0) -> float:
	var sx := absf(height_at(x + d, z) - height_at(x - d, z)) / (2.0 * d)
	var sz := absf(height_at(x, z + d) - height_at(x, z - d)) / (2.0 * d)
	return maxf(sx, sz)


## Walks outward from the center along dir and returns the distance where the
## land meets the open sea: the first drop below sea level that stays water for
## at least OPEN_SEA_RUN meters, so inland lakes are skipped. Offshore islets
## further out are ignored. Returns -1 if there is no such coast.
func _coast_distance(dir: Vector2) -> float:
	const STEP := 8.0
	const OPEN_SEA_RUN := 200.0
	if height_at(0.0, 0.0, false) <= 0.0:
		return -1.0
	var r := island_radius * 0.3
	var last_land := r
	var water_since := -1.0
	while r < map_half:
		var p := dir * r
		if height_at(p.x, p.y, false) > 0.0:
			last_land = r
			water_since = -1.0
		elif water_since < 0.0:
			water_since = r
		if water_since >= 0.0 and (r - water_since >= OPEN_SEA_RUN or r + STEP >= map_half):
			# Bisect between the last land sample and the first water sample.
			var lo := last_land
			var hi := water_since
			for i in 6:
				var mid := (lo + hi) * 0.5
				var q := dir * mid
				if height_at(q.x, q.y) > 0.0:
					lo = mid
				else:
					hi = mid
			return lo
		r += STEP
	return -1.0


# --- Survey (debug) ---

## Coarse stats for judging an island: size, height, biome mix, spawn.
func survey(grid := 96) -> Dictionary:
	var cell := map_half * 2.0 / grid
	var land := 0
	var counts := { Biome.SHORE: 0, Biome.GREENWOOD: 0, Biome.OLD_INTERIOR: 0 }
	var max_h := -INF
	for j in grid:
		for i in grid:
			var x := -map_half + (i + 0.5) * cell
			var z := -map_half + (j + 0.5) * cell
			var h := height_at(x, z, false)
			if h <= 0.0:
				continue
			land += 1
			max_h = maxf(max_h, h)
			var b := biome_at(x, z)
			if counts.has(b):
				counts[b] += 1
	var land_f := maxf(land, 1)
	return {
		land_km2 = land * cell * cell / 1.0e6,
		max_height = max_h,
		shore = counts[Biome.SHORE] / land_f,
		greenwood = counts[Biome.GREENWOOD] / land_f,
		old_interior = counts[Biome.OLD_INTERIOR] / land_f,
	}


func _find(f: VoxelGraphFunction, node_name: StringName) -> int:
	var id := f.find_node_by_name(node_name)
	if id == 0xFFFFFFFF or not f.get_node_ids().has(id):
		push_error("IslandGenerator: graph has no node named %s" % node_name)
	return id


func _constant(f: VoxelGraphFunction, node_name: StringName) -> float:
	return f.get_node_param(_find(f, node_name), 0)
