shader_type spatial;
// Debug biome colors for the island terrain. No textures yet.
//
// Repeats the biome math from world/island_generator.tres (see
// IslandGenerator.inland_at / band_at). IslandGenerator.apply_to_material()
// fills every uniform below from the graph's named constants and bakes the
// graph's own CoastNoise and BiomeEdgeNoise (same seed) into the two maps.

uniform sampler2D coast_noise_map : filter_linear, repeat_disable, hint_default_black;
uniform sampler2D edge_noise_map : filter_linear, repeat_disable, hint_default_black;
uniform float map_half = 1600.0;  // the maps cover -map_half..map_half on x and z

uniform float island_radius = 1000.0;
uniform float coast_warp = 0.5;
uniform float edge_jitter = 0.05;
uniform float shore_end = 0.09;
uniform float greenwood_end = 0.40;

uniform vec3 shore_color : source_color = vec3(0.86, 0.78, 0.52);
uniform vec3 greenwood_color : source_color = vec3(0.36, 0.58, 0.28);
uniform vec3 old_interior_color : source_color = vec3(0.50, 0.44, 0.38);
uniform float steep_start = 0.35;  // 1 - normal.y where darkening begins
uniform float steep_full = 0.7;  // and where it is strongest
uniform float steep_darkness = 0.5;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// The maps store raw noise mapped from -1..1 to 0..1 (Noise.get_image with
// normalize off). Texel i sits at world -map_half + (i + 0.5) * texel size.
float sample_noise(sampler2D map, vec2 xz) {
	vec2 uv = (xz + map_half) / (2.0 * map_half);
	return texture(map, uv).r * 2.0 - 1.0;
}

void fragment() {
	vec2 xz = world_pos.xz;
	float inland = 1.0 - length(xz) / island_radius + sample_noise(coast_noise_map, xz) * coast_warp;
	float band = inland + sample_noise(edge_noise_map, xz) * edge_jitter;

	vec3 color = old_interior_color;
	if (band < shore_end) {
		color = shore_color;
	} else if (band < greenwood_end) {
		color = greenwood_color;
	}

	// Height cues: wet, darker sand below sea level; high rock lightens a
	// touch so tall ridges read at a distance.
	color *= mix(1.0, 0.55, clamp(-world_pos.y / 10.0, 0.0, 1.0));
	color = mix(color, color * 1.25, clamp((world_pos.y - 70.0) / 50.0, 0.0, 1.0));

	// Steep slopes darker.
	float steepness = 1.0 - clamp(world_normal.y, 0.0, 1.0);
	color *= mix(1.0, steep_darkness, smoothstep(steep_start, steep_full, steepness));

	ALBEDO = color;
	ROUGHNESS = 1.0;
}
