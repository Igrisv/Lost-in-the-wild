extends Control

@onready var nueva_partida: Control = $Nueva_Partida
@onready var opciones: Control = $Opciones
@onready var creditos: Control = $Creditos
@onready var main_menu: Control = $Main_Menu
@onready var Movil_: Label = $Opciones/Controles_mp/Movil_
@onready var controles_mp: Control = $Opciones/Controles_mp
@onready var video: Control = $Opciones/Video
@onready var audio: Control = $Opciones/Audio



var modo_edicion_activado := false

func _process(_delta: float) -> void:
	Movil_.text = ManagerMovil.sting_id_status

func _ready():
	# Cargar valores guardados al iniciar
	$Opciones/Audio/Music_slider.value = load_volume("Music") * 100
	#$SFXSlider.value = load_volume("SFX")

#region Nueva_Partida
func _on_nueva_partida_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Mundo/main.tscn")
#endregion

#region Atras
func _on_atras_nueva_partida_pressed() -> void:
	nueva_partida.visible = false
	main_menu.visible = true


func _on_atras_opciones_pressed() -> void:
	opciones.visible = false
	main_menu.visible = true


func _on_atras_creditos_pressed() -> void:
	creditos.visible = false
	main_menu.visible = true
#endregion

#region Menu
func _on_nueva_partida_menu_pressed() -> void:
	main_menu.visible = false
	nueva_partida.visible = true

func _on_opciones_pressed() -> void:
	opciones.visible = true
	main_menu.visible = false

func _on_creditos_pressed() -> void:
	creditos.visible = true
	main_menu.visible = false

func _on_salir_pressed() -> void:
	get_tree().quit()
#endregion

#region Verificaciones
func _on_id_movil_pressed() -> void:
	if ManagerMovil.id_movil:
		ManagerMovil.id_movil = false
	else:
		ManagerMovil.id_movil = true
		
#endregion

#region Opciones

#region Audio

func _on_audio_opciones_pressed() -> void:
	audio.visible = true
	video.visible = false
	controles_mp.visible = false

func _on_music_slider_value_changed(value):
	var normalized = value / 100.0  # convertir 0–100 a 0–1
	set_bus_volume("Music", normalized)
	save_volume("Music", normalized)

func _on_sfx_slider_value_changed(value):
	var normalized = value / 100.0
	set_bus_volume("SFX", normalized)
	save_volume("SFX", normalized)

func set_bus_volume(bus_name: String, normalized_value: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(normalized_value))

func load_volume(bus_name: String) -> float:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		return config.get_value("audio", bus_name, 1.0)
	return 1.0

func save_volume(bus_name: String, normalized_value: float):
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("audio", bus_name, normalized_value)
	config.save("user://settings.cfg")

#endregion

#region Video

func _on_video_opciones_pressed() -> void:
	video.visible = true
	audio.visible = false
	controles_mp.visible = false

#endregion

#region Controles

func _on_controles_opciones_pressed() -> void:
	controles_mp.visible = true
	video.visible = false
	audio.visible = false

func _on_edit_pressed():
	ManagerMovil.id_movil = true
	ManagerMovil.camera_on_editable_controls = true
	ManagerMovil.activar_edicion_al_entrar = true  # Activar modo edición al entrar
	get_tree().change_scene_to_file("res://Scenes/Ui_Movil/ui_movil.tscn")

	
#endregion

#endregion
