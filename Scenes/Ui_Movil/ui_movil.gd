extends Control

@onready var pause_menu: Control = $Pause_Menu
@onready var ui_movil: Control = self
@onready var camera_2d: Camera2D = $Camera2D
@onready var btn_seleccionado: Label = $Movil_Config/Btn_Seleccionado
@onready var movil_config: Panel = $Movil_Config

var is_paused = false

func _ready():
	# Asegúrate de que el nodo esté en el árbol antes de procesar
	await get_tree().process_frame
	# Cargar posiciones y escalas
	cargar_configuracion()
	
	# Conectamos cambios de edición
	ManagerMovil.connect("modo_edicion_cambiado", Callable(self, "_on_modo_edicion_cambiado"))
	
	# Activar modo edición solo si se ha solicitado desde el menú
	if ManagerMovil.activar_edicion_al_entrar:
		print("Activando modo edición desde bandera activar_edicion_al_entrar")
		ManagerMovil.alternar_modo_edicion()
		ManagerMovil.activar_edicion_al_entrar = false  # Restablecer para futuras entradas
	
	# Aplicar posiciones y escalas iniciales
	for nodo in get_tree().get_nodes_in_group("editable_ui"):
		var pos = ManagerMovil.cargar_posicion(nodo.name)
		if pos != Vector2.ZERO:
			nodo.global_position = pos
		var item_scale = ManagerMovil.cargar_escala(nodo.name)
		if item_scale != Vector2.ZERO:
			nodo.scale = item_scale
		# Forzar actualización del modo edición en los nodos
		nodo.edit_mode = ManagerMovil.modo_edicion

func _process(_delta: float) -> void:
	if not is_inside_tree():
		return  # Evita procesar si el nodo no está en el árbol
	
	if ManagerMovil.modo_edicion == false:
		movil_config.visible = false
	if ManagerMovil.contenedor_activo != null:
		btn_seleccionado.text = "Editando: " + ManagerMovil.contenedor_activo.name
	else:
		btn_seleccionado.text = "Sin selección"
		ui_movil.visible = ManagerMovil.id_movil

	if Input.is_action_just_pressed("menu_movil"):
		is_paused = !is_paused
		pause_menu.visible = is_paused

	camera_2d.enabled = ManagerMovil.camera_on_editable_controls

func _on_modo_edicion_cambiado(activado: bool) -> void:
	print("Edición activada: ", activado)
	set_process_input(activado)
	for nodo in get_tree().get_nodes_in_group("editable_ui"):
		nodo.edit_mode = activado
	# Guardar configuración al salir del modo edición
	if not activado:
		guardar_configuracion()

# Guardar posiciones y escalas en un solo archivo
func guardar_configuracion():
	print("Guardando configuración")
	var config = ConfigFile.new()
	for nodo in get_tree().get_nodes_in_group("editable_ui"):
		var node_name = nodo.name  # Renombrar para evitar shadowing
		config.set_value("posiciones", node_name, nodo.global_position)
		config.set_value("escalas", node_name, nodo.scale)
		# Actualizar caché en ManagerMovil
		ManagerMovil.guardar_posicion(node_name, nodo.global_position)
		ManagerMovil.guardar_escala(node_name, nodo.scale)
	
	var err = config.save("user://Ui_Controles_Movil.cfg")
	if err != OK:
		print("Error al guardar:", err)
	else:
		print("Configuración guardada exitosamente")

# Cargar posiciones y escalas desde el archivo
func cargar_configuracion():
	print("Cargando configuración")
	var config = ConfigFile.new()
	var err = config.load("user://Ui_Controles_Movil.cfg")
	if err != OK:
		print("No se pudo cargar archivo de configuración:", err)
		return
	
	for nodo in get_tree().get_nodes_in_group("editable_ui"):
		var node_name = nodo.name  # Renombrar para evitar shadowing
		if config.has_section_key("posiciones", node_name):
			var pos = config.get_value("posiciones", node_name)
			ManagerMovil.guardar_posicion(node_name, pos)
		if config.has_section_key("escalas", node_name):
			var item_scale = config.get_value("escalas", node_name)
			ManagerMovil.guardar_escala(node_name, item_scale)

# Botones del menú de pausa
func _on_resume_pressed() -> void:
	is_paused = false
	pause_menu.visible = is_paused

func _on_options_pressed() -> void:
	pass # Implementar opciones si es necesario

func _on_to_menu_pressed() -> void:
	guardar_configuracion() # Guardar antes de cambiar escena
	ManagerMovil.modo_edicion = false  # Restablecer modo edición al salir
	ManagerMovil.camera_on_editable_controls = false  # Desactivar cámara
	get_tree().change_scene_to_file("res://Scenes/Main_Menu/main_menu.tscn")

# Botones de escala
func _on_aumentar_pressed():
	if ManagerMovil.contenedor_activo:
		var new_scale = ManagerMovil.contenedor_activo.scale * 1.1
		ManagerMovil.contenedor_activo.scale = new_scale
		ManagerMovil.guardar_escala(ManagerMovil.contenedor_activo.name, new_scale)

func _on_disminuir_pressed():
	if ManagerMovil.contenedor_activo:
		var new_scale = ManagerMovil.contenedor_activo.scale * 0.9
		ManagerMovil.contenedor_activo.scale = new_scale
		ManagerMovil.guardar_escala(ManagerMovil.contenedor_activo.name, new_scale)
