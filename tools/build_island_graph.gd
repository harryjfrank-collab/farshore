extends SceneTree
## Bootstraps world/island_generator.tres, the VoxelGeneratorGraph for the island.
##
## Run once from the repo root (the editor or the game never runs this):
##   godot --headless --path . --script res://tools/build_island_graph.gd
##
## WARNING: this overwrites the .tres. After the first run the .tres is the
## source of truth: sculpt it in the editor's graph view, not here. Only rerun
## this if you want to throw away graph edits and get the default layout back.
##
## Nodes that game code looks up by name (see scripts/world/island_generator.gd):
##   constants IslandRadius, CoastWarp, EdgeJitter, ShoreEnd, GreenwoodEnd
##   noises    CoastNoise, BiomeEdgeNoise, DuneNoise, HillNoise, HighlandNoise
## Renaming those nodes breaks the shader colors and the seed.

const OUT_PATH := "res://world/island_generator.tres"
const COL := 220.0  # horizontal spacing between columns in the graph editor
const ROW := 120.0

var f: VoxelGraphFunction


func _init() -> void:
	var graph := VoxelGeneratorGraph.new()
	f = graph.get_main_function()
	_build()
	var result: Dictionary = graph.compile()
	if not result.success:
		push_error("Graph failed to compile: %s (node %s)" % [result.message, result.get("node_id")])
		quit(1)
		return
	var err := ResourceSaver.save(graph, OUT_PATH)
	if err != OK:
		push_error("Could not save %s: %s" % [OUT_PATH, error_string(err)])
		quit(1)
		return
	print("Wrote ", OUT_PATH)
	quit(0)


func _build() -> void:
	# Column 0: inputs and the named tuning constants.
	var x := _node(VoxelGraphFunction.NODE_INPUT_X, 0, 0)
	var z := _node(VoxelGraphFunction.NODE_INPUT_Z, 0, 1)
	var y := _node(VoxelGraphFunction.NODE_INPUT_Y, 0, 12)

	var island_radius := _const("IslandRadius", 1000.0, 0, 2)  # half the island width, in meters
	var coast_warp := _const("CoastWarp", 0.5, 0, 3)  # how far bays and headlands push the shore
	var edge_jitter := _const("EdgeJitter", 0.05, 0, 4)  # how wobbly biome borders are
	var shore_end := _const("ShoreEnd", 0.09, 0, 5)  # Inland value where Shore becomes Greenwood
	var greenwood_end := _const("GreenwoodEnd", 0.40, 0, 6)  # Inland value where Old Interior starts
	var biome_fade := _const("BiomeFade", 0.06, 0, 7)  # width of the blend between biome shapes
	var peak_height := _const("PeakHeight", 90.0, 0, 8)  # meters at the top of CoastProfile
	var seabed_drop := _const("SeabedDrop", 150.0, 0, 9)  # how fast the seabed falls off
	var seabed_floor := _const("SeabedFloor", -40.0, 0, 10)  # deepest the sea gets
	var dune_height := _const("DuneHeight", 1.6, 4, 8)
	var rolling_height := _const("RollingHeight", 6.0, 4, 9)
	var highland_height := _const("HighlandHeight", 55.0, 4, 10)

	# Column 1: noises. One seed drives all of them (World offsets each one).
	var coast_noise := _noise("CoastNoise", 1, 1, 0.0009, 4, FastNoiseLite.FRACTAL_FBM)
	var edge_noise := _noise("BiomeEdgeNoise", 1, 3, 0.006, 2, FastNoiseLite.FRACTAL_FBM)
	var dune_noise := _noise("DuneNoise", 1, 5, 0.03, 2, FastNoiseLite.FRACTAL_FBM)
	var hill_noise := _noise("HillNoise", 1, 7, 0.004, 4, FastNoiseLite.FRACTAL_FBM)
	var highland_noise := _noise("HighlandNoise", 1, 9, 0.0035, 5, FastNoiseLite.FRACTAL_RIDGED)
	for n in [coast_noise, edge_noise, dune_noise, hill_noise, highland_noise]:
		_wire(x, n, 0)
		_wire(z, n, 1)

	# Inland: 0 on the coastline, about 1 at the island center, negative at sea.
	# Inland = 1 - distance / IslandRadius + CoastNoise * CoastWarp
	var dist := _node(VoxelGraphFunction.NODE_DISTANCE_2D, 1, 0, "DistanceFromCenter")
	_wire(x, dist, 2)
	_wire(z, dist, 3)
	var radial := _op(VoxelGraphFunction.NODE_DIVIDE, dist, island_radius, 2, 0)
	var one_minus := _node(VoxelGraphFunction.NODE_SUBTRACT, 3, 0)
	f.set_node_default_input(one_minus, 0, 1.0)
	_wire(radial, one_minus, 1)
	var coast_term := _op(VoxelGraphFunction.NODE_MULTIPLY, coast_noise, coast_warp, 2, 1)
	var inland := _op(VoxelGraphFunction.NODE_ADD, one_minus, coast_term, 4, 0, "Inland")

	# BiomeBand: Inland plus a little extra noise, so biome borders don't run
	# exactly parallel to the coast. The terrain shader repeats this math.
	var edge_term := _op(VoxelGraphFunction.NODE_MULTIPLY, edge_noise, edge_jitter, 2, 3)
	var band := _op(VoxelGraphFunction.NODE_ADD, inland, edge_term, 5, 2, "BiomeBand")

	# Base height: the CoastProfile curve on land, a falling seabed at sea.
	# Keep the curve's first point at (0, 0) so the coastline stays at sea level.
	var land_t := _node(VoxelGraphFunction.NODE_CLAMP, 5, 0)
	f.set_node_default_input(land_t, 1, 0.0)
	f.set_node_default_input(land_t, 2, 1.0)
	_wire(inland, land_t, 0)
	var profile := _node(VoxelGraphFunction.NODE_CURVE, 6, 0, "CoastProfile")
	f.set_node_param(profile, 0, _coast_profile())
	_wire(land_t, profile, 0)
	var land_h := _op(VoxelGraphFunction.NODE_MULTIPLY, profile, peak_height, 7, 0)
	var sea_t := _node(VoxelGraphFunction.NODE_MIN, 5, 1)  # min(Inland, 0)
	_wire(inland, sea_t, 0)
	var sea_h := _op(VoxelGraphFunction.NODE_MULTIPLY, sea_t, seabed_drop, 6, 1)
	var sea_h_clamped := _op(VoxelGraphFunction.NODE_MAX, sea_h, seabed_floor, 7, 1)
	var base_h := _op(VoxelGraphFunction.NODE_ADD, land_h, sea_h_clamped, 8, 0, "BaseHeight")

	# Biome masks: 0 before the border, 1 after it, blended over BiomeFade.
	var greenwood_mask := _mask(band, shore_end, biome_fade, 6, 3, "GreenwoodMask")
	var interior_mask := _mask(band, greenwood_end, biome_fade, 6, 5, "OldInteriorMask")

	# Shore: low dunes, faded out at the waterline so the beach stays walkable.
	var dune_shape := _remap(dune_noise, 0.0, 1.0, 2, 5)
	var waterline_fade := _node(VoxelGraphFunction.NODE_SMOOTHSTEP, 5, 7)
	f.set_node_param(waterline_fade, 0, 0.02)
	f.set_node_param(waterline_fade, 1, 0.07)
	_wire(inland, waterline_fade, 0)
	var not_greenwood := _node(VoxelGraphFunction.NODE_SUBTRACT, 9, 3)
	f.set_node_default_input(not_greenwood, 0, 1.0)
	_wire(greenwood_mask, not_greenwood, 1)
	var dune_mask := _op(VoxelGraphFunction.NODE_MULTIPLY, waterline_fade, not_greenwood, 10, 3, "DuneMask")
	var dunes := _op(VoxelGraphFunction.NODE_MULTIPLY, dune_shape, dune_height, 5, 8)
	var dunes_masked := _op(VoxelGraphFunction.NODE_MULTIPLY, dunes, dune_mask, 11, 4, "Dunes")

	# Greenwood: gentle rolling meadows, biased upward to avoid inland ponds.
	var rolling_shape := _remap(hill_noise, -0.3, 1.0, 2, 7)
	var rolling := _op(VoxelGraphFunction.NODE_MULTIPLY, rolling_shape, rolling_height, 5, 9)
	var rolling_masked := _op(VoxelGraphFunction.NODE_MULTIPLY, rolling, greenwood_mask, 11, 5, "Rolling")

	# Old Interior: ridged hills and highlands, the roughest terrain.
	var highland_shape := _remap(highland_noise, 0.0, 1.0, 2, 9)
	var highland := _op(VoxelGraphFunction.NODE_MULTIPLY, highland_shape, highland_height, 5, 10)
	var highland_masked := _op(VoxelGraphFunction.NODE_MULTIPLY, highland, interior_mask, 11, 6, "Highlands")

	# Sum everything and turn height into a signed distance: SDF = Y - height.
	var h1 := _op(VoxelGraphFunction.NODE_ADD, base_h, dunes_masked, 12, 1)
	var h2 := _op(VoxelGraphFunction.NODE_ADD, h1, rolling_masked, 13, 2)
	var height := _op(VoxelGraphFunction.NODE_ADD, h2, highland_masked, 14, 3, "Height")
	var sdf := _op(VoxelGraphFunction.NODE_SUBTRACT, y, height, 15, 4)
	var out := _node(VoxelGraphFunction.NODE_OUTPUT_SDF, 16, 4)
	_wire(sdf, out, 0)


func _coast_profile() -> Curve:
	# x: Inland (0 = coast, 1 = center). y: fraction of PeakHeight.
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.0), 0.0, 0.45)
	c.add_point(Vector2(0.09, 0.045), 0.45, 0.6)  # top of the beach, about 4 m
	c.add_point(Vector2(0.40, 0.28), 0.8, 0.8)  # Greenwood edge, about 25 m
	c.add_point(Vector2(1.0, 0.75), 0.6, 0.0)  # island center, about 67 m before hills
	return c


func _node(type: int, col: float, row: float, node_name := "") -> int:
	var id := f.create_node(type, Vector2(col * COL, row * ROW))
	if node_name != "":
		f.set_node_name(id, node_name)
	return id


func _const(node_name: String, value: float, col: float, row: float) -> int:
	var id := _node(VoxelGraphFunction.NODE_CONSTANT, col, row, node_name)
	f.set_node_param(id, 0, value)
	return id


func _noise(node_name: String, col: float, row: float, frequency: float, octaves: int, fractal: int) -> int:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = frequency
	n.fractal_type = fractal
	n.fractal_octaves = octaves
	n.seed = 0  # replaced at runtime from World.world_seed
	var id := _node(VoxelGraphFunction.NODE_NOISE_2D, col, row, node_name)
	f.set_node_param(id, 0, n)
	return id


func _op(type: int, a: int, b: int, col: float, row: float, node_name := "") -> int:
	var id := _node(type, col, row, node_name)
	_wire(a, id, 0)
	_wire(b, id, 1)
	return id


func _remap(src: int, out_min: float, out_max: float, col: float, row: float) -> int:
	var id := _node(VoxelGraphFunction.NODE_REMAP, col, row)
	f.set_node_param(id, 0, -1.0)
	f.set_node_param(id, 1, 1.0)
	f.set_node_param(id, 2, out_min)
	f.set_node_param(id, 3, out_max)
	_wire(src, id, 0)
	return id


## smoothstep(0, 1, (value - border) / fade), built from wireable nodes so the
## border and fade come from the named constants.
func _mask(value: int, border: int, fade: int, col: float, row: float, node_name: String) -> int:
	var offset := _op(VoxelGraphFunction.NODE_SUBTRACT, value, border, col, row)
	var scaled := _op(VoxelGraphFunction.NODE_DIVIDE, offset, fade, col + 1, row)
	var id := _node(VoxelGraphFunction.NODE_SMOOTHSTEP, col + 2, row, node_name)
	f.set_node_param(id, 0, 0.0)
	f.set_node_param(id, 1, 1.0)
	_wire(scaled, id, 0)
	return id


func _wire(src: int, dst: int, dst_port: int) -> void:
	f.add_connection(src, 0, dst, dst_port)
