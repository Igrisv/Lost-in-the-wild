extends Control


@onready var nueva_partida: Control = $Nueva_Partida
@onready var opciones: Control = $Opciones
@onready var creditos: Control = $Creditos
@onready var main_menu: Control = $Main_Menu
@onready var Movil_: Label = $Opciones/Movil_


#region Nueva_Partida
func _on_nueva_partida_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
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

func _process(delta: float) -> void:
	Movil_.text = ManagerMovil.sting_id_status

func _on_id_movil_pressed() -> void:
	if ManagerMovil.id_movil:
		ManagerMovil.id_movil = false
	else:
		ManagerMovil.id_movil = true
		
