extends Node
## Drives the sun, moon, sky, ambient light and fog from WorldClock.
## The look lives in settings (world/day_night.tres); this script only applies it.

const SKY_UPDATE_INTERVAL := 0.25  # seconds; sky changes trigger a radiance update

@export var settings: DayNightSettings
@export var sun: DirectionalLight3D
@export var moon: DirectionalLight3D
@export var world_environment: WorldEnvironment

## Extra fog multiplier on top of the settings. Fly mode lowers it.
var fog_scale := 1.0

var _env: Environment
var _sky_material: ProceduralSkyMaterial
var _sky_timer := 0.0


func _ready() -> void:
	_env = world_environment.environment
	_sky_material = _env.sky.sky_material as ProceduralSkyMaterial
	moon.light_color = settings.moon_color
	apply(WorldClock.time_of_day, true)


func _process(delta: float) -> void:
	_sky_timer -= delta
	var update_sky := _sky_timer <= 0.0
	if update_sky:
		_sky_timer = SKY_UPDATE_INTERVAL
	apply(WorldClock.time_of_day, update_sky)


func apply(t: float, update_sky: bool) -> void:
	var s := settings
	var sun_dir := sun_direction(t)
	_aim(sun, sun_dir)
	var sun_up := smoothstep(-0.03, 0.12, sun_dir.y)
	sun.light_color = s.sun_color.sample(t)
	sun.light_energy = s.sun_energy * sun_up
	sun.visible = sun_up > 0.0

	var moon_dir := -sun_dir  # opposite side of the sky
	_aim(moon, moon_dir)
	var moon_up := smoothstep(-0.03, 0.12, moon_dir.y)
	moon.light_energy = s.moon_energy * moon_up
	moon.visible = moon_up > 0.0

	_env.ambient_light_energy = s.ambient_energy.sample_baked(t)
	_env.fog_light_color = s.fog_color.sample(t)
	_env.fog_density = s.fog_density * s.fog_density_curve.sample_baked(t) * fog_scale

	if update_sky and _sky_material:
		var horizon := s.sky_horizon_color.sample(t)
		_sky_material.sky_top_color = s.sky_top_color.sample(t)
		_sky_material.sky_horizon_color = horizon
		_sky_material.ground_horizon_color = horizon
		_sky_material.ground_bottom_color = horizon.darkened(0.5)


## Unit vector pointing at the sun. It rises in the east (+X) at 0.25, peaks at
## noon leaning sun_tilt_degrees toward +Z, and sets in the west at 0.75.
func sun_direction(t: float) -> Vector3:
	var a := (t - WorldClock.SUNRISE) * TAU
	var tilt := deg_to_rad(settings.sun_tilt_degrees)
	return Vector3(cos(a), sin(a) * cos(tilt), sin(a) * sin(tilt)).normalized()


## Points a directional light so it shines from dir toward the ground.
func _aim(light: DirectionalLight3D, dir: Vector3) -> void:
	var up := Vector3.UP if absf(dir.y) < 0.999 else Vector3.FORWARD
	light.global_basis = Basis.looking_at(-dir, up)
