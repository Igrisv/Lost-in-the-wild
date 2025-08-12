extends WeatherManager

func set_weather(weather_name: String) -> void:
	if weather_name == "" or weather_name == current_weather:
		if weather_name == "":
			push_error("WeatherManager: Intento de establecer clima vacío")
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
		print("Escena de clima instanciada: ", weather_name)
	else:
		push_error("ERROR: Clima no encontrado en WEATHER_SCENES: ", weather_name)

	# Actualizar current_weather y emitir señal
	current_weather = weather_name
	emit_signal("weather_changed", current_weather)
	print("Señal weather_changed emitida para: ", current_weather)
