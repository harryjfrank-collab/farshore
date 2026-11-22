extends SceneTree
## Generates islands for several seeds without opening a window and reports
## whether any are broken (no beach, too small, spawn underwater).
##
##   godot --headless --path . --script res://tools/survey_seeds.gd -- 1 2 3 4 5
##   godot --headless --path . --script res://tools/survey_seeds.gd -- --maps=/tmp/maps 1 2 3
##
## With --maps=DIR it also writes a top-down PNG per seed: debug biome colors,
## shaded by height, sea in blue, spawn as a red dot.

const MIN_LAND_KM2 := 1.5  # an island of "roughly 2 x 2 km" should have at least this
const MAP_PIXELS := 256

const COLORS := {
	IslandGenerator.Biome.SHORE: Color(0.86, 0.78, 0.52),
	IslandGenerator.Biome.GREENWOOD: Color(0.36, 0.58, 0.28),
	IslandGenerator.Biome.OLD_INTERIOR: Color(0.50, 0.44, 0.38),
}


func _init() -> void:
	var seeds: Array[int] = []
	var maps_dir := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--maps="):
			maps_dir = arg.trim_prefix("--maps=")
		elif arg.is_valid_int():
			seeds.append(arg.to_int())
	if seeds.is_empty():
		seeds = [1, 2, 3, 4, 5]

	var broken := 0
	for s in seeds:
		var t0 := Time.get_ticks_msec()
		var island := IslandGenerator.new(s)
		var spawn := island.find_spawn_beach()
		var stats := island.survey()
		var p: Vector3 = spawn.position
		var problems: Array[String] = []
		if not spawn.ok:
			problems.append("no walkable beach")
		if p.y <= 0.0:
			problems.append("spawn underwater")
		if island.biome_at(p.x, p.z) != IslandGenerator.Biome.SHORE:
			problems.append("spawn not on Shore")
		if stats.land_km2 < MIN_LAND_KM2:
			problems.append("island too small")
		if not problems.is_empty():
			broken += 1
		print("seed %d: land %.2f km2, highest %.0f m, Shore %d%% Greenwood %d%% Old Interior %d%% | spawn (%.0f, %.1f, %.0f) %.0f m from center, slope %.2f, try %d | %s (%d ms)" % [
			s, stats.land_km2, stats.max_height,
			stats.shore * 100, stats.greenwood * 100, stats.old_interior * 100,
			p.x, p.y, p.z, Vector2(p.x, p.z).length(), spawn.slope, spawn.tries,
			"OK" if problems.is_empty() else "BROKEN: " + ", ".join(problems),
			Time.get_ticks_msec() - t0])
		if maps_dir != "":
			_write_map(island, p, maps_dir.path_join("seed_%d.png" % s))

	print("%d of %d seeds broken" % [broken, seeds.size()])
	quit(1 if broken > 0 else 0)


func _write_map(island: IslandGenerator, spawn: Vector3, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var img := Image.create(MAP_PIXELS, MAP_PIXELS, false, Image.FORMAT_RGB8)
	var cell := island.map_half * 2.0 / MAP_PIXELS
	for j in MAP_PIXELS:
		for i in MAP_PIXELS:
			var x := -island.map_half + (i + 0.5) * cell
			var z := -island.map_half + (j + 0.5) * cell
			var h := island.height_at(x, z, false)
			var c: Color
			if h <= 0.0:
				c = Color(0.13, 0.34, 0.52).lerp(Color(0.05, 0.12, 0.25), clampf(-h / 40.0, 0.0, 1.0))
			else:
				c = COLORS[island.biome_at(x, z)]
				c = c.darkened(0.25).lerp(c.lightened(0.3), clampf(h / 120.0, 0.0, 1.0))
			img.set_pixel(i, j, c)
	var si := int((spawn.x + island.map_half) / cell)
	var sj := int((spawn.z + island.map_half) / cell)
	for dj in range(-2, 3):
		for di in range(-2, 3):
			var px := clampi(si + di, 0, MAP_PIXELS - 1)
			var py := clampi(sj + dj, 0, MAP_PIXELS - 1)
			img.set_pixel(px, py, Color.RED)
	img.save_png(path)
