extends Node

signal weather_changed(new_weather: String)

var current_weather: String = ""
var weather_effect: Node2D = null
const WEATHER_SCENES := {
	"lluvia": preload("res://Systems/Climas/Scenes/rain.tscn"),
}

func set_weather(weather_name: String):
	if current_weather == weather_name:
		return

	# Fade-out del clima anterior
	if weather_effect and weather_effect.has_method("fade_out_and_free"):
		weather_effect.fade_out_and_free()
	else:
		if weather_effect:
			weather_effect.queue_free()

	weather_effect = null

	# Instanciar el nuevo clima
	if weather_name in WEATHER_SCENES:
		weather_effect = WEATHER_SCENES[weather_name].instantiate()
		add_child(weather_effect)
		current_weather = weather_name
		emit_signal("weather_changed", current_weather)
