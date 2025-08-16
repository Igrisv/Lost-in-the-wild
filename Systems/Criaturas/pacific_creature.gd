class_name PacificCreature
extends Creature

# Sobrescribir detección para comportamiento pacífico
func update_state_based_on_target(t: Node2D) -> void:
	if is_threat(t) and global_position.distance_to(t.global_position) < detection_range:
		change_state(State.FLEE)
	else:
		change_state(State.WANDER)

# Determinar amenazas (escalable)
func is_threat(target: Node2D) -> bool:
	return target is AggressiveCreature or (Inventory.has_item_in_hotbar("Weapon"))  # Ejemplo: huye de agresivas o jugadores armados

# Condición de doma: ítem + proximidad prolongada
func can_be_tamed_by(player: Player) -> bool:
	var inventory = Inventory
	var required_item = tame_requirements.get("item", "Madera")
	var proximity_time = tame_requirements.get("proximity_time", 5.0)

	# Verificar si el ítem está en la hotbar
	if not inventory.has_item_in_hotbar(required_item):
		return false

	# Verificar tiempo de proximidad
	if proximity_time > 0.0:
		if not $ProximityTimer:
			var timer = Timer.new()
			timer.name = "ProximityTimer"
			add_child(timer)
			timer.connect("timeout", _on_proximity_timeout)
		if global_position.distance_to(player.global_position) < 70:  # Distancia de proximidad
			if not $ProximityTimer.is_stopped():
				$ProximityTimer.stop()  # Resetear si ya se completó
				return true  # Domesticación exitosa tras el tiempo
			if $ProximityTimer.time_left <= 0:
				$ProximityTimer.start(proximity_time)
			return false  # Aún no se cumple el tiempo
		else:
			if $ProximityTimer and  $ProximityTimer.time_left <= 0:
				$ProximityTimer.stop()  # Pausar si se aleja
			return false
	else:
		# Si no hay tiempo de proximidad, solo requiere el ítem y proximidad básica
		return global_position.distance_to(player.global_position) < 20

# Sobrescribir tame para consumir ítem y comportamiento post-doma
func tame(player: Player) -> void:
	super.tame(player)
	var item = Inventory.get_item(tame_requirements.get("item", "Madera"))
	if item:
		Inventory.use_stackable_item(item, 1)
	change_state(State.WANDER)  # Vaga cerca del jugador

func _on_proximity_timeout() -> void:
	$ProximityTimer.stop()  # Detener el timer tras completarse

# Añade o reemplaza process_tamed_behavior en PacificCreature.gd
func process_tamed_behavior(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		var desired_distance: float = 50.0  # Distancia prudencial (ajustable)
		var distance_to_player = global_position.distance_to(player.global_position)
		var direction = (player.global_position - global_position).normalized()

		if distance_to_player > desired_distance:
			velocity = velocity.move_toward(direction * speed, speed * delta * 3)  # Acercarse si está lejos
		elif distance_to_player < desired_distance - 10.0:  # Margen para evitar oscilaciones
			velocity = velocity.move_toward(-direction * speed, speed * delta * 3)  # Alejarse si está muy cerca
		else:
			velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 3)  # Mantener distancia
