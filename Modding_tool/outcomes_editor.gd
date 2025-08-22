extends VBoxContainer

const OUTCOME_DIR := "user://"

var current_outcome: Outcome = null
@onready var outcomes: VBoxContainer = $"."
@onready var outcomes_list: ItemList = $HBoxContainer/OutcomesList
@onready var btn_new_outcome: Button = $HBoxContainer/BtnNewOutcome
@onready var btn_delete_outcome: Button = $HBoxContainer/BtnDeleteOutcome
@onready var lbl_empty: Label = $HBoxContainer/LblEmpty
@onready var outcome_panel: Panel = $OutcomePanel
@onready var ob_type: OptionButton = $OutcomePanel/OBType
@onready var le_target: LineEdit = $OutcomePanel/LETarget
@onready var le_value: LineEdit = $OutcomePanel/LEValue
@onready var btn_save_outcome: Button = $OutcomePanel/BtnSaveOutcome
@onready var btn_close_outcome: Button = $OutcomePanel/BtnCloseOutcome

func _ready():
	# 1) Asegura que exista la carpeta de outcomes
	var root = DirAccess.open("user://")
	if root:
		if not root.dir_exists("outcomes"):
			root.make_dir_recursive("outcomes")
		root = null 
	# 2) Pobla el OptionButton con los valores del enum
	for name in Outcome.OutcomeType.keys():
		ob_type.add_item(name)
	# 3) Configura el ItemList
	outcomes_list.select_mode = ItemList.SELECT_SINGLE
	outcomes_list.allow_reselect = true # Permitir reselección
	# 4) Conecta señales
	btn_new_outcome.pressed.connect(_on_new_outcome)
	btn_delete_outcome.pressed.connect(_on_delete_outcome)
	if outcomes_list.item_selected.is_connected(_on_select_outcome):
		outcomes_list.item_selected.disconnect(_on_select_outcome)
	outcomes_list.item_selected.connect(_on_select_outcome)
	btn_save_outcome.pressed.connect(_on_save_outcome)
	btn_close_outcome.pressed.connect(_on_close_outcome)
	# 5) Refresca el listado
	_refresh_list()

func _refresh_list() -> void:
	outcomes_list.clear()
	print("Intentando abrir la carpeta: ", OUTCOME_DIR)
	var dir = DirAccess.open(OUTCOME_DIR)
	if not dir:
		lbl_empty.text = "No se pudo abrir la carpeta outcomes"
		lbl_empty.visible = true
		push_error("Error al abrir el directorio: ", OUTCOME_DIR)
		return
	
	print("Carpeta abierta correctamente, listando archivos...")
	dir.list_dir_begin()
	var file = dir.get_next()
	var count = 0
	
	while file != "":
		print("Archivo encontrado: ", file)
		if file.ends_with(".tres"):
			print("Añadiendo al ItemList: ", file)
			outcomes_list.add_item(file)
			count += 1
		file = dir.get_next()
	
	dir.list_dir_end()
	print("Total de archivos .tres encontrados: ", count)
	lbl_empty.text = "No hay outcomes disponibles" if count == 0 else ""
	lbl_empty.visible = (count == 0)
	outcome_panel.visible = false
	current_outcome = null
	outcomes_list.queue_redraw()

func _on_select_outcome(index: int) -> void:
	print("Seleccionado índice: ", index, " en ItemList")
	var fname = outcomes_list.get_item_text(index)
	print("Cargando archivo: ", OUTCOME_DIR + fname)
	var res = ResourceLoader.load(OUTCOME_DIR + fname)
	if res == null:
		push_error("No se pudo cargar el outcome: %s" % fname)
		lbl_empty.text = "Error: No se pudo cargar %s" % fname
		lbl_empty.visible = true
		return
	if not res is Outcome:
		push_error("El recurso no es del tipo Outcome: %s" % fname)
		lbl_empty.text = "Error: %s no es un Outcome válido" % fname
		lbl_empty.visible = true
		return
	current_outcome = res
	print("Outcome cargado: ", fname, " - Mostrando panel")
	_show_outcome_panel()

func _show_outcome_panel():
	if not current_outcome:
		print("Error: current_outcome es null")
		return
	print("Mostrando outcome_panel para: ", current_outcome.resource_path)
	outcome_panel.visible = true
	ob_type.select(current_outcome.outcome_type)
	le_target.text = current_outcome.target
	le_value.text = JSON.stringify(current_outcome.outcome_value)
	outcome_panel.queue_redraw() # Forzar redibujado del panel

func _on_save_outcome() -> void:
	if not current_outcome:
		print("No hay outcome seleccionado para guardar")
		return
	current_outcome.outcome_type = ob_type.selected
	current_outcome.target = le_target.text
	var j = JSON.new()
	var err = j.parse(le_value.text)
	if err != OK or typeof(j.get_data()) != TYPE_ARRAY:
		push_error("Value debe ser un array JSON válido")
		lbl_empty.text = "Error: Value debe ser un array JSON válido"
		lbl_empty.visible = true
		return
	current_outcome.outcome_value = j.get_data()
	var sel = outcomes_list.get_selected_items()
	if sel.is_empty():
		print("No hay ítem seleccionado en ItemList")
		return
	var path = OUTCOME_DIR + outcomes_list.get_item_text(sel[0])
	var res = ResourceSaver.save(current_outcome, path)
	if res != OK:
		push_error("Error guardando: %s" % error_string(res))
		lbl_empty.text = "Error al guardar outcome"
		lbl_empty.visible = true
		return
	_refresh_list()

func _on_new_outcome() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Nuevo Outcome"
	dialog.dialog_text = "Ingresa el nombre del nuevo outcome:"
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Ejemplo: nuevo_outcome"
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog.add_child(line_edit)
	
	dialog.confirmed.connect(func():
		var fname = line_edit.text.strip_edges()
		if fname == "":
			fname = "outcome_%d" % Time.get_unix_time_from_system()
		if not fname.ends_with(".tres"):
			fname += ".tres"
		var invalid_chars = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
		for ch in invalid_chars:
			if ch in fname:
				push_error("El nombre contiene caracteres inválidos: %s" % fname)
				lbl_empty.text = "Nombre inválido: no use %s" % invalid_chars
				lbl_empty.visible = true
				return
		var dir = DirAccess.open(OUTCOME_DIR)
		if dir and dir.file_exists(fname):
			push_error("El archivo ya existe: %s" % fname)
			lbl_empty.text = "El nombre %s ya está en uso" % fname
			lbl_empty.visible = true
			return
		
		var o = Outcome.new()
		o.outcome_type = 0
		o.target = ""
		o.outcome_value = []
		var res = ResourceSaver.save(o, OUTCOME_DIR + fname)
		if res != OK:
			push_error("No se pudo crear outcome: %s" % error_string(res))
			lbl_empty.text = "Error al crear outcome"
			lbl_empty.visible = true
			return
		_refresh_list()
		var idx = outcomes_list.get_item_count() - 1
		if idx >= 0:
			for i in range(outcomes_list.get_item_count()):
				if outcomes_list.get_item_text(i) == fname:
					idx = i
					break
			outcomes_list.select(idx)
			_on_select_outcome(idx)
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered(Vector2i(300, 150))

func _on_delete_outcome() -> void:
	var sel = outcomes_list.get_selected_items()
	if sel.is_empty():
		return
	var fname = outcomes_list.get_item_text(sel[0])
	var dir = DirAccess.open(OUTCOME_DIR)
	if dir:
		dir.remove(fname)
	_refresh_list()

func _on_close_outcome() -> void:
	outcome_panel.visible = false
	current_outcome = null

func _on_close_pressed() -> void:
	outcomes.visible = false
