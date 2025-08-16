class_name AggressiveCreature
extends Creature

# Sobrescribir detección para comportamiento agresivo
func update_state_based_on_target(t: Node2D) -> void:
	if is_valid_target(t) and global_position.distance_to(t.global_position) < detection_range:
		if global_position.distance_to(t.global_position) <= interaction_range:
			change_state(State.ATTACK)
		else:
			change_state(State.WANDER)  # Persigue pero no ataca si está fuera de rango
	else:
		change_state(State.WANDER)

# Determinar objetivos válidos (escalable)
func is_valid_target(target: Node2D) -> bool:
	# Ataca a jugadores, criaturas pacíficas o de facciones opuestas
	return target is Player or target is PacificCreature or (target is Creature and target.faction != faction)

# Sobrescribir proceso de ataque
func process_state(delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.WANDER:
			velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed
		State.FLEE:
			if target:
				velocity = (global_position - target.global_position).normalized() * speed
		State.ATTACK:
			if target:
				velocity = (target.global_position - global_position).normalized() * speed
				if global_position.distance_to(target.global_position) <= interaction_range:
					attack_target()

# Implementar ataque
func attack_target() -> void:
	if target is Player:
		var player = target as Player
		# player.take_damage(10.0)  # Descomentar cuando take_damage esté implementado en jugador.gd
	elif target is Creature:
		var creature = target as Creature
		creature.take_damage(10.0)  # Inflige daño a otras criaturas
	change_state(State.IDLE)

# Condición de doma: ítem + resistencia (agresivas son más difíciles)
func can_be_tamed_by(player: Player) -> bool:
	var inventory = Inventory
	if inventory.has_item_in_hotbar(tame_requirements.get("item", "AggressiveTameItem")):
		# Requiere más proximidad y resistencia (ej: no estar en combate)
		return global_position.distance_to(player.global_position) < 15 and current_state != State.ATTACK
	return false

# Sobrescribir tame para consumir ítem y comportamiento post-doma
func tame(player: Player) -> void:
	super.tame(player)
	var item = Inventory.get_item(tame_requirements.get("item", "AggressiveTameItem"))
	if item:
		Inventory.use_stackable_item(item, 1)
	change_state(State.WANDER)  # Vaga cerca del jugador tras ser domado

# Sobrescribir take_damage para soportar combate
func take_damage(amount: float) -> void:
	# Placeholder: implementar sistema de salud en el futuro
	needs.hunger -= amount  # Ejemplo: daño reduce hambre como proxy
	if needs.hunger <= 0:
		die()
