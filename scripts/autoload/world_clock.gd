extends Node
## The world's time of day: one clock for sky and lighting now, and later for
## crops, creatures and beds.
##
## Server-owned shared state. Only the server advances it; when networking
## lands, clients receive (day, time_of_day) and call set_time(). Keep it plain
## data so it syncs cheaply and survives scene reloads (it is an autoload).

signal day_started(day: int)  ## at sunrise
signal night_started(day: int)  ## at sunset

const DAY_LENGTH := 1200.0  ## real seconds per in-game day (design spec: about 20 minutes)
const SUNRISE := 0.25  ## 06:00
const SUNSET := 0.75  ## 18:00
const START_HOUR := 8.0

var day := 1
## 0 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset.
var time_of_day := START_HOUR / 24.0
## Debug or admin speed-up. 1 = normal.
var time_scale := 1.0
var running := true


func _process(delta: float) -> void:
	if running:
		advance(delta * time_scale / DAY_LENGTH)


## Moves the clock forward by a fraction of a day (1.0 / 24.0 is one hour).
func advance(fraction: float) -> void:
	var was_day := is_daytime()
	time_of_day += fraction
	while time_of_day >= 1.0:
		time_of_day -= 1.0
		day += 1
	if is_daytime() != was_day:
		if is_daytime():
			day_started.emit(day)
		else:
			night_started.emit(day)


## For network sync and save games.
func set_time(p_day: int, p_time_of_day: float) -> void:
	day = p_day
	time_of_day = fposmod(p_time_of_day, 1.0)


func is_daytime() -> bool:
	return time_of_day >= SUNRISE and time_of_day < SUNSET


func get_hour() -> float:
	return time_of_day * 24.0


func clock_text() -> String:
	var minutes := int(time_of_day * 24.0 * 60.0)
	return "Day %d  %02d:%02d" % [day, minutes / 60, minutes % 60]
