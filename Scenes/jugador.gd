extends CharacterBody2D

var speed: float = 200.0
var target = null
var damage: float = 50.0
var attack_range: float = 50.0
var player_name: String = "Jugador"
var is_skinning: bool = false
var is_taming: bool = false
var current_animal: Node = null
var skinning_timer: float = 0.0
var taming_timer: float = 0.0
var skinning_progress: ProgressBar = null
var taming_skill: float = 50.0  # Habilidad de domesticación (0-100)

func _ready():
	skinning_progress = $ProgressBar
	if skinning_progress:
		skinning_progress.hide()
	else:
		print("Error: ProgressBar no encontrada en %s" % name)

func _physics_process(_delta):
	if not is_skinning and not is_taming:
		var direction = Vector2.ZERO
		if Input.is_action_pressed("derecha"):
			direction.x += 1
		if Input.is_action_pressed("izquierda"):
			direction.x -= 1
		if Input.is_action_pressed("abajo"):
			direction.y += 1
		if Input.is_action_pressed("arriba"):
			direction.y -= 1
		velocity = direction.normalized() * speed
		move_and_slide()

func _input(event):
	if event is InputEventKey and event.is_pressed():
		if not is_skinning and not is_taming and target:
			if event.is_action_pressed("interactuar"):
				# Interacciones para despellejar o domesticar
				if target.is_in_group("Food") and target.is_dead:
					start_skinning(target)
				elif target.is_in_group("Animals") and not target.is_dead:
					var distance = global_position.distance_to(target.global_position)
					if distance <= attack_range:
						if target.taming_stage == target.TamingStage.DESCONFIANZA:
							target.start_observing(self)
						elif target.taming_stage == target.TamingStage.OBSERVACION:
							if Inventory.has_item_in_hotbar(target.preferred_resource):
								if Inventory.use_stackable_item(target.preferred_resource,1):
									start_taming(target)
								else:
									print("Error al usar %s para domesticar a %s" % [target.preferred_resource, target.animal_name])
							else:
								print("No tienes %s en la hotbar para domesticar a %s" % [target.preferred_resource, target.animal_name])
						elif target.taming_stage == target.TamingStage.ACERCAMIENTO:
							target.bond_with_animal()
						elif target.taming_stage == target.TamingStage.VINCULO:
							target.tame_animal()
						elif target.taming_stage == target.TamingStage.DOMESTICADO:
							target.perform_behavior()
							if target.can_be_mounted:
								print("Montando a %s" % target.animal_name)
					else:
						print("El objetivo %s está fuera de rango para interactuar (distancia: %.1f)" % [target.animal_name, distance])
			elif event.is_action_pressed("atacar"):
				# Acción para atacar
				if target.is_in_group("Animals") and not target.is_dead:
					var distance = global_position.distance_to(target.global_position)
					if distance <= attack_range:
						target.take_damage(damage, self)
						print("Atacaste a %s, causando %.1f de daño" % [target.animal_name, damage])
					else:
						print("El objetivo %s está fuera de rango para atacar (distancia: %.1f)" % [target.animal_name, distance])

func start_skinning(animal: Node):
	if not animal or not animal.is_in_group("Food") or not animal.is_dead:
		print("Error: No se puede despellejar %s (no es comida o no está muerto)" % animal.animal_name if animal else "ningún animal")
		return
	is_skinning = true
	current_animal = animal
	skinning_timer = 0.0
	skinning_progress.value = 0
	skinning_progress.max_value = animal.skinning_time
	skinning_progress.show()
	print("Comenzando a despellejar %s (%.1f segundos)" % [animal.animal_name, animal.skinning_time])

func start_taming(animal: Node):
	if not animal or not animal.is_in_group("Animals") or animal.is_dead:
		print("Error: No se puede domesticar %s (no es un animal o está muerto)" % animal.animal_name if animal else "ningún animal")
		return
	is_taming = true
	current_animal = animal
	taming_timer = 0.0
	skinning_progress.value = 0
	skinning_progress.max_value = animal.taming_time_per_stage
	skinning_progress.show()
	animal.is_taming = true
	animal.taming_timer = 0.0
	animal.approach_with_resource(animal.preferred_resource)
	print("Comenzando a alimentar %s con %s (%.1f segundos)" % [animal.animal_name, animal.preferred_resource, animal.taming_time_per_stage])

func _process(delta):
	if is_skinning:
		skinning_timer += delta
		skinning_progress.value = skinning_timer
		if skinning_timer >= current_animal.skinning_time:
			finish_skinning()
	if is_taming:
		taming_timer += delta
		skinning_progress.value = taming_timer
		if taming_timer >= current_animal.taming_time_per_stage:
			finish_taming()

func finish_skinning():
	is_skinning = false
	skinning_progress.hide()
	if current_animal and not current_animal.is_skinned:
		var loot = current_animal.interact_for_loot()
		for item_name in loot.keys():
			var amount = loot[item_name]
			if amount > 0:
				var item = Inventory.item_map.get(item_name)
				if item:
					Inventory.add_item(item, amount)
					print("Recolectaste %.1f de %s" % [amount, item_name])
				else:
					print("Advertencia: No se encontró un ítem con nombre %s en item_map" % item_name)
	current_animal = null

func finish_taming():
	is_taming = false
	skinning_progress.hide()
	if current_animal:
		current_animal.is_taming = false
		print("Alimentación de %s completada" % current_animal.animal_name)
	current_animal = null

func improve_taming_skill(amount: float):
	taming_skill = clamp(taming_skill + amount, 0.0, 100.0)
	print("Habilidad de domesticación mejorada a %.1f" % taming_skill)

func _on_InteractionArea_body_entered(body):
	if body.is_in_group("Animals") or body.is_in_group("Food"):
		print("Detectado: %s" % body.animal_name)
		target = body

func _on_InteractionArea_body_exited(body):
	if body == target:
		target = null
		print("Perdido objetivo: %s" % body.animal_name)
