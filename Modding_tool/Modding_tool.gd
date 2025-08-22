extends Control

const ACTIONS_DIR := "user://"

@onready var resource: ActionResource = ActionResource.new()
@onready var file_dialog: FileDialog = $Action/Nigga/Setters/FileDialog
@onready var outcomes: VBoxContainer = $Outcome/Box_container
@onready var action: Control = $Action
@onready var outcome: Control = $Outcome

func _ready():
	#var dir = DirAccess.open("user://")
	#if dir and not dir.dir_exists("actions"):
		#dir.make_dir_recursive("actions")
	
	if resource:
		$Action/Nigga/Setters/action_id.text = resource.action_id
		$Action/Nigga/Setters/display_name.text = resource.display_name
		$Action/Nigga/Setters/required_tool_type.text = resource.required_tool_type
		$Action/Nigga/Setters/base_stamina_cost.value = resource.base_stamina_cost
		$Action/Nigga/Setters/base_execution_time.value = resource.base_execution_time
		$Action/Nigga/Setters/animation.text = resource.animation
	
	file_dialog.current_dir = ACTIONS_DIR
	file_dialog.filters = ["*.tres"]

func _on_save_pressed():
	resource.action_id = $Action/Nigga/Setters/action_id.text
	resource.display_name = $Action/Nigga/Setters/display_name.text
	resource.required_tool_type = $Action/Nigga/Setters/required_tool_type.text
	resource.base_stamina_cost = $Action/Nigga/Setters/base_stamina_cost.value
	resource.base_execution_time = $Action/Nigga/Setters/base_execution_time.value
	resource.animation = $Action/Nigga/Setters/animation.text

func _on_btn_guardar_pressed():
	_on_save_pressed()
	var file_name = $Nigga/Setters/name.text.strip_edges()
	if file_name == "":
		push_error("Nombre de archivo vacío")
		$Action/Nigga/Setters/name.placeholder_text = "Por favor, ingrese un nombre"
		return

	if not file_name.ends_with(".tres"):
		file_name += ".tres"

	# Validar caracteres inválidos
	var invalid_chars = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
	for ch in invalid_chars:
		if ch in file_name:
			push_error("Nombre de archivo inválido: %s" % file_name)
			$Action/Nigga/Setters/name.placeholder_text = "Nombre inválido: no use %s" % invalid_chars
			return

	# Verificar si el archivo ya existe
	var path = ACTIONS_DIR.path_join(file_name)
	var dir = DirAccess.open(ACTIONS_DIR)
	if dir and dir.file_exists(file_name):
		push_error("El archivo ya existe: %s" % path)
		$Action/Nigga/Setters/name.placeholder_text = "El nombre %s ya está en uso" % file_name
		return

	var result = ResourceSaver.save(resource, path)
	if result != OK:
		push_error("Error al guardar: %s" % error_string(result))
		$Action/Nigga/Setters/name.placeholder_text = "Error al guardar el recurso"
	else:
		print("Guardado exitosamente en: ", path)
		$Action/Nigga/Setters/name.placeholder_text = "Guardado exitoso"

func cargar_resource(path: String):
	var loaded = ResourceLoader.load(path)
	if loaded and loaded is ActionResource:
		resource = loaded
		_cargar_datos_en_ui()
		print("Recurso cargado desde: ", path)
	else:
		push_error("No se pudo cargar el recurso o no es del tipo correcto: %s" % path)

func _cargar_datos_en_ui():
	if not resource:
		push_error("Recurso no válido.")
		return

	# Cargar texto
	$Action/Nigga/Setters/action_id.text = resource.action_id if resource.action_id != null else ""
	$Action/Nigga/Setters/display_name.text = resource.display_name if resource.display_name != null else ""
	$Action/Nigga/Setters/required_tool_type.text = resource.required_tool_type if resource.required_tool_type != null else ""
	$Action/Nigga/Setters/animation.text = resource.animation if resource.animation != null else ""

	# Cargar números
	$Action/Nigga/Setters/base_stamina_cost.value = resource.base_stamina_cost
	$Action/Nigga/Setters/base_execution_time.value = resource.base_execution_time

func _on_file_dialog_file_selected(path: String) -> void:
	var loaded = ResourceLoader.load(path)
	if loaded is ActionResource:
		resource = loaded
		_cargar_datos_en_ui()
		print("Recurso cargado desde: ", path)
	else:
		push_error("El archivo seleccionado no es un ActionResource válido: %s" % path)

func _on_cargar_pressed() -> void:
	file_dialog.popup_centered()

func _on_edit_outcomes_pressed() -> void:
	outcomes.visible = true


func _on_recipe_pressed() -> void:
	pass # Replace with function body.


func _on_outcome_pressed() -> void:
	pass # Replace with function body.


func _on_action_pressed() -> void:
	pass # Replace with function body.


func _on_item_pressed() -> void:
	pass # Replace with function body.


func _on_node_pressed() -> void:
	pass # Replace with function body.


func _on_creature_pressed() -> void:
	pass # Replace with function body.
