extends Node2D

var climates = ["lluvia"]
var current_index = 0

func _input(event):
	if event.is_action_pressed("ui_accept"):  # por defecto, esta es la barra espaciadora
		current_index = (current_index + 1) % climates.size()
		var new_climate = climates[current_index]
		$Ui/weather_manager.set_weather(new_climate)
		print("Clima actual: ", new_climate)


#func _input(event):
	#if event.is_action_pressed("ui_accept"):
		#var random_climate = climates[randi() % climates.size()]
		#$ClimateManager.set_weather(random_climate)
