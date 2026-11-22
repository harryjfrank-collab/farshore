class_name DayNightSettings
extends Resource
## The look of one day: colors and amounts over time, edited in the inspector.
## Every Gradient and Curve here runs over the day on its x axis:
## 0 = midnight, 0.25 = sunrise (06:00), 0.5 = noon, 0.75 = sunset (18:00), 1 = midnight.
## Keep the two ends equal so midnight doesn't jump.

@export_group("Sun and moon")
@export var sun_color: Gradient
@export_range(0.0, 4.0) var sun_energy := 1.05
## How far the noon sun leans away from straight overhead. Gives long shadows.
@export_range(5.0, 60.0) var sun_tilt_degrees := 32.0
@export var moon_color := Color(0.6, 0.7, 1.0)
@export_range(0.0, 1.0) var moon_energy := 0.2

@export_group("Sky")
@export var sky_top_color: Gradient
@export var sky_horizon_color: Gradient

@export_group("Ambient and fog")
## Multiplies the light the sky casts on everything. Higher at night keeps
## nights dark blue and readable instead of black.
@export var ambient_energy: Curve
@export var fog_color: Gradient
@export_range(0.0, 0.05, 0.0005) var fog_density := 0.006
## Multiplies fog_density. Thicker at dawn and dusk: sea fog rolling in.
@export var fog_density_curve: Curve
