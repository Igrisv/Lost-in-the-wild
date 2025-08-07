extends CharacterBody2D

class_name  animal
# Enums para valores cualitativos
enum Level { MINIMO, BAJO, MEDIO, ALTO, EXTREMO }
enum BehaviorType { AGRESIVO, NEUTRAL, PASIVO }
enum Species { NONE, CONEJO, CIERVO, OSO, LEON, LOBO }
enum TamingStage { DESCONFIANZA, OBSERVACION, ACERCAMIENTO, VINCULO, DOMESTICADO }

# Propiedades exportadas organizadas por categorías
@export_group("Configuración General")
@export var animal_name: String = "Animal"
@export var animal_species: Species = Species.NONE
@export var behavior: BehaviorType = BehaviorType.NEUTRAL
@export var animation_change_interval: float = 2.0  # Intervalo para cambiar animaciones en Idle

@export_group("Configuración de Movimiento")
@export var max_speed: Level = Level.MEDIO
@export var move_smoothing: float = 0.1
@export var patrol_radius: float = 150.0
@export var patrol_change_interval: float = 3.0
@export var patrol_min_distance: float = 50.0

@export_group("Salud y Recursos")
@export var max_health: Level = Level.MEDIO
@export var hunger_max: Level = Level.MEDIO
@export var hunger_rate: Level = Level.BAJO
@export var max_stamina: Level = Level.MEDIO
@export var stamina_drain_rate: Level = Level.BAJO
@export var stamina_regen_rate: Level = Level.MEDIO

@export_group("Loot")
@export var loot_table: Dictionary = {
	"Carne": {"quantity": 25.0, "probability": 1.0},
	"Piel": {"quantity": 10.0, "probability": 0.7},
	"Huesos": {"quantity": 5.0, "probability": 0.3}
}
@export var skinning_time: float = 5.0

@export_group("Domesticación")
@export var taming_stage: TamingStage = TamingStage.DESCONFIANZA
@export var taming_progress: float = 0.0
@export var max_taming_progress: float = 100.0
@export var loyalty: float = 0.0
@export var can_be_mounted: bool = false
@export var docility: float = 50.0
@export var strength: float = 30.0
@export var agility: float = 40.0
@export var preferred_resource: String = "Hierba"
@export var taming_time_per_stage: float = 3.0  # Tiempo en segundos para la etapa de alimentación

@export_group("Configuración de Combate")
@export var damage: Level = Level.MEDIO
@export var detection_range: float = 400.0
@export var threat_range: float = 250.0
@export var attack_range: float = 35.0
@export var quick_attack_range: float = 25.0
@export var stalk_attack_range: float = 20.0
@export var stalk_range: float = 100.0
@export var stalk_speed_multiplier: float = 0.3
@export var stalk_damage_multiplier: float = 1.5
@export var attack_preparation_time: float = 0.3
@export var attack_cooldown: float = 0.6
@export var quick_attack_cooldown: float = 0.2
@export var detection_probability: float = 0.3

@export_group("Probabilidades de Comportamiento")
@export var patrol_probability: float = 0.4
@export var idle_probability: float = 0.4
@export var wander_probability: float = 0.2
@export var idle_duration: float = 2.0
@export var wander_duration: float = 1.5
@export var alert_duration: float = 3.0
@export var eat_timer: float = 0.0
@export var eat_duration: float = 2.0

@export_group("Interacciones")
@export var interactions: Array[AnimalInteraction] = []

@export_group("Animaciones")
@export var animation_map: Dictionary = {
	"AGRESIVO": {
		"Idle": [{"name": "Parado", "weight": 0.6}, {"name": "Olfatear", "weight": 0.4}],
		"Patrol": [{"name": "Caminar", "weight": 1.0}],
		"Wander": [{"name": "Caminar", "weight": 1.0}],
		"Chase": [{"name": "Correr", "weight": 1.0}],
		"Flee": [{"name": "Correr", "weight": 1.0}],
		"Attack": [{"name": "Manotazo", "weight": 1.0}],
		"Eat": [{"name": "Comer", "weight": 1.0}],
		"Alert": [{"name": "Alerta", "weight": 1.0}],
		"Stalk": [{"name": "CaminarSigiloso", "weight": 1.0}],
		"Follow": [{"name": "Caminar", "weight": 1.0}]
	},
	"NEUTRAL": {
		"Idle": [{"name": "Parado", "weight": 0.5}, {"name": "Rascarse", "weight": 0.5}],
		"Patrol": [{"name": "Caminar", "weight": 1.0}],
		"Wander": [{"name": "Hozar", "weight": 1.0}],
		"Chase": [{"name": "Correr", "weight": 1.0}],
		"Flee": [{"name": "Correr", "weight": 1.0}],
		"Attack": [{"name": "Embestir", "weight": 1.0}],
		"Eat": [{"name": "Comer", "weight": 1.0}],
		"Alert": [{"name": "MirarAlrededor", "weight": 1.0}],
		"Stalk": [{"name": "Caminar", "weight": 1.0}],
		"Follow": [{"name": "Caminar", "weight": 1.0}]
	},
	"PASIVO": {
		"Idle": [{"name": "Pastar", "weight": 0.7}, {"name": "MirarAlrededor", "weight": 0.3}],
		"Patrol": [{"name": "Trotar", "weight": 1.0}],
		"Wander": [{"name": "Atrás de comida", "weight": 1.0}],
		"Chase": [{"name": "Correr", "weight": 1.0}],
		"Flee": [{"name": "Correr", "weight": 1.0}],
		"Attack": [{"name": "Embestir", "weight": 1.0}],
		"Eat": [{"name": "Comer", "weight": 1.0}],
		"Alert": [{"name": "Alerta", "weight": 1.0}],
		"Stalk": [{"name": "Trotar", "weight": 1.0}],
		"Follow": [{"name": "Trotar", "weight": 1.0}]
	}
}

# Variables internas
var hunger: float = 0.0
var health: float = 0.0
var stamina: float = 0.0
var state: String = "Idle"
var target: Node2D = null
var move_direction: Vector2 = Vector2.ZERO
var time_since_last_eat: float = 0.0
var time_since_last_attack: float = 0.0
var home_position: Vector2
var state_timer: float = 0.0
var patrol_direction: Vector2 = Vector2.ZERO
var alert_timer: float = 0.0
var attack_preparation_timer: float = 0.0
var alert_level: float = 0.0
var is_surprised: bool = false
var is_dead: bool = false
var is_skinned: bool = false
@onready var animated_sprite: AnimatedSprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea
var animation_change_timer: float = 0.0
var current_animation: String = ""
var nearby_animals: Array = []
var nearby_food: Array = []
var remaining_loot: Dictionary = loot_table.duplicate(true)

# Variables para domesticación
var is_tamed: bool = false
var taming_player: Node = null
var action_cooldown: float = 0.0
var is_taming: bool = false
var taming_timer: float = 0.0

# Mapeo de niveles a valores numéricos
const LEVEL_VALUES = {
	Level.MINIMO: 50.0,
	Level.BAJO: 100.0,
	Level.MEDIO: 150.0,
	Level.ALTO: 200.0,
	Level.EXTREMO: 300.0
}

const HUNGER_RATE_VALUES = {
	Level.MINIMO: 0.5,
	Level.BAJO: 1.0,
	Level.MEDIO: 1.5,
	Level.ALTO: 2.0,
	Level.EXTREMO: 3.0
}

const STAMINA_DRAIN_VALUES = {
	Level.MINIMO: 2.0,
	Level.BAJO: 5.0,
	Level.MEDIO: 10.0,
	Level.ALTO: 15.0,
	Level.EXTREMO: 20.0
}

const STAMINA_REGEN_VALUES = {
	Level.MINIMO: 5.0,
	Level.BAJO: 10.0,
	Level.MEDIO: 15.0,
	Level.ALTO: 20.0,
	Level.EXTREMO: 25.0
}

const DAMAGE_VALUES = {
	Level.MINIMO: 10.0,
	Level.BAJO: 25.0,
	Level.MEDIO: 50.0,
	Level.ALTO: 75.0,
	Level.EXTREMO: 100.0
}

# Señales
signal animal_died(animal)
signal animal_tamed(animal)

func _ready():
	randomize()
	health = LEVEL_VALUES[max_health]
	stamina = LEVEL_VALUES[max_stamina]
	hunger = 0.0
	home_position = global_position
	add_to_group("Animals")
	
	 #Validar preferred_resource contra Inventory.item_map
	if not Inventory.item_map.has(preferred_resource):
		print("Advertencia: %s tiene un preferred_resource '%s' que no está en Inventory.item_map" % [animal_name, preferred_resource])
	
	# Configurar área de detección
	if detection_area:
		var collision_shape = detection_area.get_node_or_null("CollisionShape2D")
		if collision_shape and collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = detection_range
			collision_shape.disabled = false
			print("%s configuró DetectionArea/CollisionShape2D con radio %.1f" % [animal_name, detection_range])
		else:
			print("%s advertencia: CollisionShape2D no encontrado o no es CircleShape2D" % animal_name)
		if not detection_area.is_connected("body_entered", _on_detection_area_entered):
			detection_area.body_entered.connect(_on_detection_area_entered)
		if not detection_area.is_connected("body_exited", _on_detection_area_exited):
			detection_area.body_exited.connect(_on_detection_area_exited)
	else:
		print("%s advertencia: Nodo DetectionArea no encontrado" % animal_name)
	
	# Validar loot_table en _ready
	for item_name in loot_table.keys():
		if not Inventory.item_map.has(item_name):
			print("Advertencia: %s tiene un ítem '%s' en loot_table que no está en Inventory.item_map" % [animal_name, item_name])
	
	_validate_animations()
	_validate_probabilities()
	_validate_ranges()
	_validate_interactions()
	update_state()
	setup_animal_stats()
	queue_redraw()
	print("%s creado con especie %s, comportamiento %s, salud %.1f, hambre %.1f, estamina %.1f, loot_table: %s en posición %s" % [
		animal_name, Species.keys()[animal_species], BehaviorType.keys()[behavior], health, hunger, stamina, str(loot_table), global_position
	])

func setup_animal_stats():
	match animal_species:
		Species.CONEJO:
			docility = 80.0
			strength = 10.0
			agility = 60.0
			can_be_mounted = false
			preferred_resource = "Carne"  # Asegúrate de que esté en Inventory.item_map
		Species.CIERVO:
			docility = 60.0
			strength = 30.0
			agility = 70.0
			can_be_mounted = true
			preferred_resource = "Hierba Dulce"
		Species.OSO:
			docility = 20.0
			strength = 90.0
			agility = 30.0
			can_be_mounted = false
			preferred_resource = "Miel"
		Species.LOBO:
			docility = 40.0
			strength = 70.0
			agility = 60.0
			can_be_mounted = true
			preferred_resource = "Carne Cruda"
		Species.LEON:
			docility = 30.0
			strength = 80.0
			agility = 50.0
			can_be_mounted = false
			preferred_resource = "Carne Fresca"

	# Ajustar dificultad según comportamiento
	match behavior:
		BehaviorType.PASIVO:
			max_taming_progress = 50.0
		BehaviorType.NEUTRAL:
			max_taming_progress = 100.0
		BehaviorType.AGRESIVO:
			max_taming_progress = 150.0

func start_observing(player):
	if taming_stage == TamingStage.DESCONFIANZA and not is_tamed and not is_dead:
		taming_player = player
		taming_stage = TamingStage.OBSERVACION
		taming_progress = 0.0
		print("%s está siendo observado por %s" % [animal_name, player.player_name])

func approach_with_resource(resource: String):
	if taming_stage == TamingStage.OBSERVACION and resource == preferred_resource:
		is_taming = true
		taming_timer = 0.0
		taming_progress += (docility / 2.0) * taming_player.taming_skill / 100.0
		if taming_progress >= max_taming_progress:
			taming_stage = TamingStage.ACERCAMIENTO
			taming_progress = 0.0
			is_taming = false
			print("%s aceptó el recurso y permite acercarse" % animal_name)
		else:
			print("%s progresa en observación: %.1f/%.1f" % [animal_name, taming_progress, max_taming_progress])

func bond_with_animal():
	if taming_stage == TamingStage.ACERCAMIENTO:
		var success_chance = docility + (taming_player.taming_skill * 0.5)
		if randf() * 100.0 < success_chance:
			taming_progress += 40.0
			if taming_progress >= max_taming_progress:
				taming_stage = TamingStage.VINCULO
				taming_progress = 0.0
				print("%s comienza a formar un vínculo con %s" % [animal_name, taming_player.player_name])
			else:
				print("%s progresa en vínculo: %.1f/%.1f" % [animal_name, taming_progress, max_taming_progress])
		else:
			taming_progress -= 20.0
			print("%s se resiste al vínculo" % animal_name)

func tame_animal():
	if taming_stage == TamingStage.VINCULO:
		taming_progress += (docility + taming_player.taming_skill) / 2.0
		if taming_progress >= max_taming_progress:
			taming_stage = TamingStage.DOMESTICADO
			is_tamed = true
			loyalty = 50.0
			emit_signal("animal_tamed", self)
			print("%s ha sido domesticado por %s!" % [animal_name, taming_player.player_name])

func perform_behavior():
	if is_tamed and loyalty > 0:
		if taming_player and is_instance_valid(taming_player):
			target = taming_player
			_switch_to_follow()
			print("%s está siguiendo a %s" % [animal_name, taming_player.player_name])
		else:
			print("%s no puede seguir: taming_player no válido" % animal_name)

func get_interactions() -> Array[Dictionary]:
	var interactions: Array[Dictionary] = []
	if is_dead and not is_skinned and not remaining_loot.is_empty():
		interactions.append({"name": "Despellejar", "condition": "has_loot"})
	if not is_dead and not is_tamed and health > 0:
		interactions.append({"name": "Domar", "condition": "is_alive"})
		if preferred_resource and not is_taming:
			interactions.append({"name": "Alimentar", "condition": "is_alive"})
	if is_tamed and taming_player:
		interactions.append({"name": "Seguir", "condition": "not_dead"})
	return interactions

func perform_interaction(action: String):
	match action:
		"Despellejar":
			var loot = interact_for_loot()
			if loot:
				print("%s recolectó: %s" % [animal_name, str(loot)])
		"Domar":
			if taming_player:
				start_observing(taming_player)
		"Alimentar":
			if taming_player and preferred_resource:
				approach_with_resource(preferred_resource)
		"Seguir":
			if taming_player:
				_switch_to_follow()
	print("%s realizó acción: %s" % [animal_name, action])

func _process(delta):
	if is_dead:
		# Verificar si el animal está despellejado y no tiene loot, eliminar si es necesario
		if is_skinned and remaining_loot.is_empty() and is_inside_tree():
			print("%s está muerto, despellejado y sin loot, ejecutando queue_free en _process" % animal_name)
			queue_free()
			return
		if has_node("DebugLabel"):
			$DebugLabel.text = "Estado: Muerto\nObjetivo: %s\nEstamina: %.1f\nHambre: %.1f\nAnimales cercanos: %d\nComida cercana: %d\nLoot: %s\nDomesticado: %s\nAlimentando: %s" % [
				target.animal_name if target and target.is_in_group("Animals") else "comida" if target else "Ninguno",
				stamina,
				hunger,
				nearby_animals.size(),
				nearby_food.size(),
				str(remaining_loot),
				"Sí" if is_tamed else "No",
				"Sí" if is_taming else "No"
			]
		return
	if is_taming:
		# Detener movimiento y reproducir animación de comer durante la alimentación
		move_direction = Vector2.ZERO
		velocity = Vector2.ZERO
		play_animation("Eat")
		taming_timer += delta
		if taming_timer >= taming_time_per_stage:
			is_taming = false
			print("%s terminó la alimentación, volviendo a comportamiento normal" % animal_name)
			update_state()
		return
	
	if action_cooldown > 0:
		action_cooldown -= delta
	if is_tamed:
		loyalty -= delta * 0.2
		if loyalty <= 0:
			is_tamed = false
			taming_player = null
			taming_stage = TamingStage.DESCONFIANZA
			target = null
			_switch_to_idle()
			print("%s ha abandonado a %s por falta de lealtad" % [animal_name, taming_player.player_name if taming_player else "jugador"])

	# Actualizar recursos
	hunger += HUNGER_RATE_VALUES[hunger_rate] * delta
	time_since_last_eat += delta
	time_since_last_attack += delta
	state_timer += delta
	
	if state == "Idle":
		animation_change_timer += delta
		if animation_change_timer >= animation_change_interval:
			play_animation("Idle")
			animation_change_timer = 0.0
	
	if state not in ["Flee", "Chase", "Attack", "Stalk", "Follow"]:
		stamina = min(LEVEL_VALUES[max_stamina], stamina + STAMINA_REGEN_VALUES[stamina_regen_rate] * delta)
	
	if hunger >= LEVEL_VALUES[hunger_max]:
		die("inanición")
	if health <= 0:
		die("asesinado")
	
	if state == "Alert":
		alert_timer -= delta
		if alert_timer <= 0:
			update_state()
	
	if target and not is_instance_valid(target):
		print("%s perdió objetivo %s porque ya no es válido" % [animal_name, target.animal_name if target and target.is_in_group("Animals") else "comida"])
		target = null
		nearby_animals.erase(target)
		nearby_food.erase(target)
		update_state()
		queue_redraw()
	
	match state:
		"Idle": _idle_behavior(delta)
		"Patrol": _patrol_behavior(delta)
		"Wander": _wander_behavior(delta)
		"Chase": _chase_behavior(delta)
		"Flee": _flee_behavior(delta)
		"Eat": _eat_behavior(delta)
		"Attack": _attack_behavior(delta)
		"Alert": _alert_behavior(delta)
		"Stalk": _stalk_behavior(delta)
		"Follow": _follow_behavior(delta)
	
	var speed_multiplier = stalk_speed_multiplier if state == "Stalk" else 0.5 if state in ["Patrol", "Wander", "Follow"] else 1.0
	velocity = move_direction * LEVEL_VALUES[max_speed] * speed_multiplier
	move_and_slide()
	
	if animated_sprite and state in ["Patrol", "Wander", "Chase", "Flee", "Stalk", "Follow"]:
		animated_sprite.flip_h = move_direction.x < 0
	
	if has_node("DebugLabel"):
		$DebugLabel.text = "Estado: %s\nObjetivo: %s\nEstamina: %.1f\nHambre: %.1f\nAnimales cercanos: %d\nComida cercana: %d\nLoot: %s\nDomesticado: %s\nAlimentando: %s" % [
			state, 
			target.animal_name if target and target.is_in_group("Animals") else "comida" if target else "Ninguno",
			stamina,
			hunger,
			nearby_animals.size(),
			nearby_food.size(),
			str(remaining_loot),
			"Sí" if is_tamed else "No",
			"Sí" if is_taming else "No"
		]
	
	if target and is_instance_valid(target):
		queue_redraw()

#func _mouse_entered():
	#print("Mouse entró en %s, nodo: %s" % [animal_name, name])
	#if not has_node("MouseDetectionArea"):
		#print("Error: MouseDetectionArea no existe en %s" % animal_name)
		#return
	#var area = $MouseDetectionArea
	#if not area.input_pickable:
		#print("Error: MouseDetectionArea no tiene input_pickable activado en %s" % animal_name)
		#return
	#var collision = area.get_node_or_null("CollisionShape2D")
	#if not collision:
		#print("Error: CollisionShape2D no encontrado en MouseDetectionArea de %s" % animal_name)
		#return
	#print("Área detectada, revisando interacciones para %s" % animal_name)
	#if is_dead:
		#print("Ignorado: %s está muerto" % animal_name)
		#return
	#
	#var interactions = get_interactions()
	#if interactions.is_empty():
		#print("No hay interacciones disponibles para %s" % animal_name)
		#return
	#
	#if not $InteractionContainer:
		#print("Error: InteractionContainer no encontrado en %s" % animal_name)
		#return
	#
	#$InteractionContainer.visible = true
	#print("Mostrando InteractionContainer para %s con %d interacciones" % [animal_name, interactions.size()])
	#
	#for child in $InteractionContainer/VBoxContainer.get_children():
		#child.queue_free()
	#
	#var button_scene = preload("res://Systems/Botones_Interactuables/Boton_Interaccion.tscn")
	#if not button_scene:
		#print("Error: No se pudo preload Boton_Interaccion.tscn en %s" % animal_name)
		#return
	#
	#for action in interactions:
		#var button = button_scene.instantiate()
		#if button:
			#$InteractionContainer/VBoxContainer.add_child(button)
			#button.setup(action["name"], self, action.get("condition", ""))
			#print("Añadido botón %s para %s" % [action["name"], animal_name])
		#else:
			#print("Error: No se pudo instanciar botón para %s" % animal_name)

func _mouse_exited():
	$InteractionContainer.visible = false
	for child in $InteractionContainer/VBoxContainer.get_children():
		child.queue_free()

func _validate_animations():
	if animated_sprite == null:
		print("%s advertencia: Nodo AnimatedSprite2D no encontrado" % animal_name)
		return
	var behavior_key = BehaviorType.keys()[behavior]
	if behavior_key in animation_map:
		for state in animation_map[behavior_key]:
			var animations = animation_map[behavior_key][state]
			for anim in animations:
				if not animated_sprite.sprite_frames or not animated_sprite.sprite_frames.has_animation(anim["name"]):
					print("%s advertencia: Animación %s para estado %s (%s) no encontrada en SpriteFrames" % [animal_name, anim["name"], state, behavior_key])

func _validate_probabilities():
	var total_prob = patrol_probability + idle_probability + wander_probability
	if abs(total_prob - 1.0) > 0.01:
		print("%s advertencia: Las probabilidades de comportamiento suman %s, deberían sumar 1.0" % [animal_name, total_prob])

func _validate_ranges():
	if stalk_range <= attack_range or attack_range <= stalk_attack_range:
		print("%s advertencia: Configuración de rangos inválida: stalk_range (%s) > attack_range (%s) > stalk_attack_range (%s)" % [animal_name, stalk_range, attack_range, stalk_attack_range])

func _validate_interactions():
	for interaction in interactions:
		if interaction.target_species.is_empty():
			print("%s advertencia: Interacción con target_species vacío" % animal_name)
		for species in interaction.target_species:
			if species == Species.NONE:
				print("%s advertencia: Interacción contiene especie NONE en target_species" % animal_name)
		if not interaction.interaction_type in ["Atacar", "Huir", "Seguir"]:
			print("%s advertencia: interaction_type inválido %s para especies %s" % [animal_name, interaction.interaction_type, ", ".join(interaction.target_species.map(func(s): return Species.keys()[s]))])

func _draw():
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, detection_range, Color(0, 1, 0, 0.2))
		for interaction in interactions:
			for species in interaction.target_species:
				var color = Color(1, 0, 0, 0.2) if interaction.interaction_type == "Atacar" else Color(0, 0, 1, 0.2) if interaction.interaction_type == "Huir" else Color(1, 1, 0, 0.2)
				if species == Species.CONEJO:
					color = Color(0.5, 0.5, 0.5, 0.2)
				elif species == Species.CIERVO:
					color = Color(0.6, 0.4, 0.2, 0.2)
				elif species == Species.OSO:
					color = Color(0.3, 0.2, 0.1, 0.2)
				elif species == Species.LEON:
					color = Color(1, 0.8, 0, 0.2)
				elif species == Species.LOBO:
					color = Color(0.4, 0.4, 0.4, 0.2)
				draw_circle(Vector2.ZERO, interaction.interaction_range, color)
		draw_circle(Vector2.ZERO, attack_range, Color(1, 0.5, 0, 0.3))
	elif not is_dead and target and is_instance_valid(target) and target.global_position != global_position:
		var color = Color(1, 0, 0, 0.5) if state in ["Attack", "Chase"] else Color(0, 0, 1, 0.5) if state == "Flee" else Color(1, 1, 0, 0.5)
		var relative_pos = to_local(target.global_position)
		var target_name = target.animal_name if target.is_in_group("Animals") else "comida"
		print("%s dibujando círculo %s en objetivo %s (posición relativa: %s)" % [
			animal_name, 
			"rojo" if state in ["Attack", "Chase"] else "azul" if state == "Flee" else "amarillo", 
			target_name, 
			relative_pos
		])
		draw_circle(relative_pos, 10.0, color)
	else:
		print("%s no dibuja círculo: muerto %s, target %s (válido: %s)" % [
			animal_name, 
			is_dead, 
			target.animal_name if target and target.is_in_group("Animals") else "comida" if target else "ninguno", 
			is_instance_valid(target)
		])
		queue_redraw()

func _set(property: StringName, _value) -> bool:
	if property in ["detection_range", "attack_range", "interactions"]:
		queue_redraw()
	return false

func choose_animation(state: String) -> String:
	var behavior_key = BehaviorType.keys()[behavior]
	if behavior_key in animation_map and state in animation_map[behavior_key]:
		var animations = animation_map[behavior_key][state]
		if animations.size() == 0:
			return state
		var total_weight = 0.0
		for anim in animations:
			total_weight += anim["weight"]
		var rand = randf() * total_weight
		var current_weight = 0.0
		for anim in animations:
			current_weight += anim["weight"]
			if rand <= current_weight:
				return anim["name"]
	return state

func update_state():
	if is_dead:
		return
	if is_tamed and taming_player and is_instance_valid(taming_player):
		target = taming_player
		_switch_to_follow()
		return
	print("%s actualizando estado (actual: %s, target: %s, hambre: %.1f, nearby_food: %d)" % [
		animal_name, 
		state, 
		target.animal_name if target and target.is_in_group("Animals") else "comida" if target else "ninguno", 
		hunger,
		nearby_food.size()
	])
	if _handle_preserved_target(): return
	if _handle_interaction_targets(): return
	if _handle_hunger(): return
	if _handle_flee(): return
	_handle_exploration_cycle()

func _handle_preserved_target() -> bool:
	if state in ["Chase", "Attack", "Stalk", "Follow"] and is_instance_valid(target) and target.is_in_group("Animals") and target.health > 0:
		var distance = global_position.distance_to(target.global_position)
		if state == "Stalk" and distance <= stalk_attack_range:
			_try_surprise_attack()
			return true
		if distance <= attack_range + 0.5:
			_switch_to_attack()
			return true
		if state == "Attack" and distance > attack_range + 0.5:
			_switch_to_chase("objetivo perdido")
			return true
		if state == "Stalk" and distance > stalk_range:
			_switch_to_chase("fuera de rango de acecho")
			return true
		if state == "Follow" and distance > get_interaction_range(target):
			_switch_to_follow()
			return true
		print("%s manteniendo estado %s con objetivo %s (distancia: %.1f)" % [animal_name, state, Species.keys()[target.animal_species], distance])
		return true
	return false

func _handle_interaction_targets() -> bool:
	if behavior != BehaviorType.AGRESIVO or stamina <= 0:
		if behavior != BehaviorType.AGRESIVO:
			print("%s no procesa interacciones agresivas: comportamiento %s" % [animal_name, BehaviorType.keys()[behavior]])
		if stamina <= 0:
			print("%s no procesa interacciones agresivas: estamina %.1f" % [animal_name, stamina])
		return false
	var valid_interactions = interactions.filter(func(i): return i.interaction_type in ["Atacar", "Huir", "Seguir"])
	if valid_interactions.is_empty():
		print("%s no tiene interacciones válidas (Atacar, Huir, Seguir)" % animal_name)
		return false
	
	valid_interactions.sort_custom(func(a, b): return a.priority > b.priority)
	
	for animal in nearby_animals:
		for interaction in valid_interactions:
			if animal.animal_species in interaction.target_species and animal.health > 0:
				var distance = global_position.distance_to(animal.global_position)
				print("%s detectó a %s (especie: %s, distancia: %.1f, interacción: %s, rango: %.1f)" % [
					animal_name, animal.animal_name, Species.keys()[animal.animal_species], distance, interaction.interaction_type, interaction.interaction_range
				])
				target = animal
				if interaction.interaction_type == "Atacar":
					if distance <= stalk_attack_range:
						_try_surprise_attack()
					elif distance <= attack_range + 0.5:
						_switch_to_attack()
					elif distance <= stalk_range:
						_switch_to_stalk()
					else:
						_switch_to_chase("instinto")
					return true
				elif interaction.interaction_type == "Huir" and distance < interaction.interaction_range:
					_switch_to_flee()
					return true
				elif interaction.interaction_type == "Seguir" and distance < interaction.interaction_range:
					_switch_to_follow()
					return true
	return false

func _handle_hunger() -> bool:
	if state == "Eat": 
		print("%s ya está en estado Eat, objetivo: %s" % [animal_name, target.animal_name if target else "ninguno"])
		return true
	for food in nearby_food:
		if is_instance_valid(food) and food.is_in_group("Food") and not food.remaining_loot.is_empty():
			target = food
			_switch_to_eat("encontró cuerpo con loot")
			print("%s seleccionó comida %s con loot %s" % [animal_name, food.animal_name, str(food.remaining_loot)])
			return true
	print("%s no encontró comida válida, nearby_food: %d" % [animal_name, nearby_food.size()])
	return false

func _handle_flee() -> bool:
	if behavior != BehaviorType.PASIVO:
		print("%s no huye: comportamiento %s no es PASIVO" % [animal_name, BehaviorType.keys()[behavior]])
		return false
	var valid_interactions = interactions.filter(func(i): return i.interaction_type == "Huir")
	if valid_interactions.is_empty():
		print("%s no tiene interacciones de huida" % animal_name)
		return false
	
	for animal in nearby_animals:
		for interaction in valid_interactions:
			if animal.animal_species in interaction.target_species and animal.health > 0:
				var distance = global_position.distance_to(animal.global_position)
				print("%s detectó amenaza %s (especie: %s, distancia: %.1f, rango de huida: %.1f)" % [
					animal_name, animal.animal_name, Species.keys()[animal.animal_species], distance, interaction.interaction_range
				])
				if distance < interaction.interaction_range:
					target = animal
					_switch_to_flee()
					return true
	if alert_level > 0.5:
		_switch_to_alert()
		return true
	return false

func _handle_exploration_cycle():
	var rand = randf()
	var total_prob = patrol_probability + idle_probability + wander_probability
	if rand < patrol_probability / total_prob:
		_switch_to_patrol()
	elif rand < (patrol_probability + idle_probability) / total_prob:
		_switch_to_idle()
	else:
		_switch_to_wander()

func _try_surprise_attack():
	var detection_chance = target.detection_probability * (1.0 + target.alert_level)
	if randf() > detection_chance:
		is_surprised = true
		target.is_surprised = true
		_switch_to_attack()
		print("%s sorprendió a %s con ataque de acecho" % [animal_name, Species.keys()[target.animal_species]])
	else:
		_switch_to_chase("falló sorpresa")
		target.alert_level = min(1.0, target.alert_level + 0.5)
		target._switch_to_alert()

func _switch_to_attack():
	state = "Attack"
	attack_preparation_timer = 0.0
	play_animation("Attack")
	print("%s cambió a Atacar" % animal_name)

func _switch_to_chase(reason: String):
	state = "Chase"
	play_animation("Chase")
	print("%s cambió a Perseguir (%s)" % [animal_name, reason])

func _switch_to_stalk():
	state = "Stalk"
	play_animation("Stalk")
	print("%s cambió a Acechar" % animal_name)

func _switch_to_flee():
	if not is_surprised:
		state = "Flee"
		play_animation("Flee")
		print("%s cambió a Huir" % animal_name)

func _switch_to_eat(reason: String):
	state = "Eat"
	eat_timer = 0.0
	play_animation("Eat")
	print("%s cambió a Comer (%s)" % [animal_name, reason])

func _switch_to_alert():
	state = "Alert"
	alert_timer = alert_duration
	play_animation("Alert")
	print("%s cambió a Alerta" % animal_name)

func _switch_to_patrol():
	state = "Patrol"
	is_surprised = false
	play_animation("Patrol")
	print("%s cambió a Patrullar" % animal_name)

func _switch_to_idle():
	state = "Idle"
	is_surprised = false
	state_timer = 0.0
	animation_change_timer = 0.0
	play_animation("Idle")
	print("%s cambió a Reposo" % animal_name)

func _switch_to_wander():
	state = "Wander"
	is_surprised = false
	state_timer = 0.0
	play_animation("Wander")
	print("%s cambió a Vagabundear" % animal_name)

func _switch_to_follow():
	state = "Follow"
	play_animation("Follow")
	print("%s cambió a Seguir" % animal_name)

func get_interaction_range(target_animal: Node2D) -> float:
	for interaction in interactions:
		if target_animal.is_in_group("Player") or target_animal.animal_species in interaction.target_species and interaction.interaction_type == "Seguir":
			return interaction.interaction_range
	return detection_range

func _idle_behavior(_delta):
	move_direction = move_direction.lerp(Vector2.ZERO, move_smoothing)
	if state_timer >= idle_duration:
		update_state()

func _patrol_behavior(_delta):
	if state_timer >= patrol_change_interval:
		update_state()
		return
	var random_offset = Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
	patrol_direction = patrol_direction.lerp(Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() + random_offset, move_smoothing * 0.5).normalized()
	if global_position.distance_to(home_position) > patrol_radius:
		patrol_direction = (home_position - global_position).normalized()
	move_direction = move_direction.lerp(patrol_direction, move_smoothing)

func _wander_behavior(_delta):
	if state_timer >= wander_duration:
		update_state()
		return
	var random_offset = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	patrol_direction = patrol_direction.lerp(Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() + random_offset, move_smoothing * 0.3).normalized()
	if global_position.distance_to(home_position) > patrol_radius:
		patrol_direction = (home_position - global_position).normalized()
	move_direction = move_direction.lerp(patrol_direction, move_smoothing)

func _stalk_behavior(delta):
	if target and is_instance_valid(target) and target.is_in_group("Animals") and target.health > 0 and stamina > 0:
		var distance = global_position.distance_to(target.global_position)
		if distance <= stalk_attack_range:
			_try_surprise_attack()
			return
		if distance > stalk_range:
			_switch_to_chase("fuera de rango de acecho")
			return
		stamina = max(0, stamina - STAMINA_DRAIN_VALUES[stamina_drain_rate] * delta * 0.5)
		var target_direction = (target.global_position - global_position).normalized()
		move_direction = move_direction.lerp(target_direction, move_smoothing)
	else:
		target = null
		is_surprised = false
		update_state()

func _chase_behavior(delta):
	if target and is_instance_valid(target) and target.is_in_group("Animals") and target.health > 0 and stamina > 0:
		var distance = global_position.distance_to(target.global_position)
		if distance <= attack_range + 0.5:
			_switch_to_attack()
			return
		if distance <= quick_attack_range + 0.5 and time_since_last_attack >= quick_attack_cooldown:
			if target.has_method("take_damage"):
				var quick_damage = DAMAGE_VALUES[damage] * 0.7
				target.take_damage(quick_damage, self)
				time_since_last_attack = 0.0
				stamina = max(0, stamina - STAMINA_DRAIN_VALUES[stamina_drain_rate] * 0.2 * delta)
				print("%s realizó ataque rápido a %s, causando %s de daño" % [animal_name, Species.keys()[target.animal_species], quick_damage])
				if target.health <= 0:
					update_state()
			return
		stamina = max(0, stamina - STAMINA_DRAIN_VALUES[stamina_drain_rate] * delta)
		var target_direction = (target.global_position - global_position).normalized()
		move_direction = move_direction.lerp(target_direction, move_smoothing)
		print("%s está persiguiendo a %s (estamina: %s, distancia: %s)" % [animal_name, Species.keys()[target.animal_species], stamina, distance])
	else:
		target = null
		is_surprised = false
		update_state()

func _attack_behavior(delta):
	if target and is_instance_valid(target) and target.is_in_group("Animals") and target.health > 0 and stamina > 0:
		var distance = global_position.distance_to(target.global_position)
		if distance > attack_range + 0.5:
			_switch_to_chase("objetivo fuera de rango")
			return
		attack_preparation_timer += delta
		stamina = max(0, stamina - STAMINA_DRAIN_VALUES[stamina_drain_rate] * delta * 0.5)
		if attack_preparation_timer >= attack_preparation_time and time_since_last_attack >= attack_cooldown:
			var damage_amount = DAMAGE_VALUES[damage]
			if is_surprised:
				damage_amount *= stalk_damage_multiplier
				is_surprised = false
			if target.has_method("take_damage"):
				target.take_damage(damage_amount, self)
				time_since_last_attack = 0.0
				print("%s atacó a %s, causando %s de daño (salud objetivo: %.1f, estamina: %.1f)" % [
					animal_name, 
					Species.keys()[target.animal_species], 
					damage_amount, 
					target.health, 
					stamina
				])
				if target.health <= 0:
					if not target.remaining_loot.is_empty() and not target.is_in_group("Food"):
						target.add_to_group("Food")
						print("%s marcó a %s como comida tras matarlo, loot: %s" % [animal_name, target.animal_name, str(target.remaining_loot)])
					if target in nearby_animals:
						nearby_animals.erase(target)
					if not target in nearby_food and target.is_dead and not target.remaining_loot.is_empty():
						nearby_food.append(target)
						print("%s añadió %s a nearby_food tras matarlo" % [animal_name, target.animal_name])
					update_state()
		move_direction = move_direction.lerp(Vector2.ZERO, move_smoothing)
	else:
		print("%s no puede atacar: objetivo %s (válido: %s, salud: %s, estamina: %.1f)" % [
			animal_name, 
			target.animal_name if target else "ninguno", 
			is_instance_valid(target), 
			target.health if target and is_instance_valid(target) else 0, 
			stamina
		])
		if target:
			nearby_animals.erase(target)
		target = null
		is_surprised = false
		update_state()

func _flee_behavior(delta):
	if target and is_instance_valid(target) and target.is_in_group("Animals") and global_position.distance_to(target.global_position) < threat_range and stamina > 0:
		stamina = max(0, stamina - STAMINA_DRAIN_VALUES[stamina_drain_rate] * delta)
		var direction_to_target = (target.global_position - global_position).normalized()
		var separation_distance = 30.0
		var target_direction = -direction_to_target
		if global_position.distance_to(target.global_position) < separation_distance:
			target_direction *= (separation_distance / global_position.distance_to(target.global_position))
		move_direction = move_direction.lerp(target_direction, move_smoothing)
		print("%s está huyendo de %s, estamina %s" % [animal_name, Species.keys()[target.animal_species], stamina])
	else:
		target = null
		_switch_to_alert()

func _follow_behavior(delta):
	if target and is_instance_valid(target) and (target.is_in_group("Animals") or target.is_in_group("Player")) and stamina > 0:
		var distance = global_position.distance_to(target.global_position)
		var follow_distance = get_interaction_range(target) * 0.5
		if distance > follow_distance:
			stamina = max(0, stamina - STAMINA_DRAIN_VALUES[stamina_drain_rate] * delta * 0.5)
			var target_direction = (target.global_position - global_position).normalized()
			move_direction = move_direction.lerp(target_direction, move_smoothing)
			print("%s está siguiendo a %s (estamina: %s, distancia: %s)" % [animal_name, target.player_name if target.is_in_group("Player") else Species.keys()[target.animal_species], stamina, distance])
		else:
			move_direction = move_direction.lerp(Vector2.ZERO, move_smoothing)
			print("%s está cerca de %s, deteniéndose (distancia: %s)" % [animal_name, target.player_name if target.is_in_group("Player") else Species.keys()[target.animal_species], distance])
	else:
		target = null
		update_state()

func _eat_behavior(delta):
	if not target or not is_instance_valid(target) or not target.is_in_group("Food") or target.remaining_loot.is_empty():
		print("%s no hay objetivo válido para comer, cambiando a Idle" % animal_name)
		_switch_to_idle()
		return
	var distance = global_position.distance_to(target.global_position)
	print("%s en Eat: distancia a %s = %.1f, loot disponible: %s" % [animal_name, target.animal_name, distance, str(target.remaining_loot)])
	if distance < 80.0:
		if eat_timer < eat_duration:
			eat_timer += delta
			print("%s está comiendo, tiempo: %.1f/%.1f" % [animal_name, eat_timer, eat_duration])
		else:
			var consumed_items: Dictionary = {}
			for item_name in target.remaining_loot.keys():
				var loot_data = target.remaining_loot[item_name]
				var roll = randf()
				print("%s probando loot %s: probabilidad %.2f, roll %.4f" % [animal_name, item_name, loot_data["probability"], roll])
				if roll <= loot_data["probability"]:
					var consumed = min(loot_data["quantity"], 50.0)
					loot_data["quantity"] -= consumed
					consumed_items[item_name] = consumed
					print("%s consumió %.1f de %s de %s, restante: %.1f" % [animal_name, consumed, item_name, target.animal_name, loot_data["quantity"]])
					if loot_data["quantity"] <= 0:
						target.remaining_loot.erase(item_name)
			if not consumed_items.is_empty():
				hunger = max(0, hunger - consumed_items.values().reduce(func(acc, x): return acc + x, 0))
				time_since_last_eat = 0.0
				print("%s terminó de comer, hambre ahora %.1f" % [animal_name, hunger])
				if target.remaining_loot.is_empty():
					nearby_food.erase(target)
					target = null
					print("%s eliminó %s de nearby_food y limpió target, total: %d" % [animal_name, target.animal_name if target else "consumido", nearby_food.size()])
			else:
				print("%s no pudo consumir loot de %s" % [animal_name, target.animal_name])
				target = null
			eat_timer = 0.0
			_switch_to_idle()
	else:
		var target_direction = (target.global_position - global_position).normalized()
		move_direction = move_direction.lerp(target_direction, move_smoothing)
		print("%s moviéndose para comer loot de %s (distancia: %.1f)" % [animal_name, target.animal_name, distance])

func _alert_behavior(_delta):
	move_direction = move_direction.lerp(Vector2.ZERO, move_smoothing)
	if state_timer >= alert_duration:
		update_state()
	else:
		print("%s está alerta (tiempo: %s/%s, nivel_alerta: %s)" % [animal_name, state_timer, alert_duration, alert_level])

func take_damage(amount: float, attacker: Node):
	health -= amount
	var attacker_name = "Jugador" if attacker.is_in_group("Player") else Species.keys()[attacker.animal_species] if "animal_species" in attacker else "Desconocido"
	print("%s recibió %.1f de daño de %s, salud ahora %.1f" % [animal_name, amount, attacker_name, health])
	if health <= 0:
		die("asesinado por %s" % attacker_name)

func die(cause: String):
	if is_dead:
		return
	is_dead = true
	# Limpiar estado de domesticación
	is_tamed = false
	taming_player = null
	taming_stage = TamingStage.DESCONFIANZA
	is_taming = false
	taming_timer = 0.0
	target = null
	# Limpiar referencias en listas
	if self in nearby_animals:
		nearby_animals.erase(self)
	if self in nearby_food:
		nearby_food.erase(self)
	# Notificar a otros animales para que eliminen este animal de sus listas
	for animal in get_tree().get_nodes_in_group("Animals"):
		if animal != self and is_instance_valid(animal) and animal is CharacterBody2D:
			if "nearby_animals" in animal and self in animal.nearby_animals:
				animal.nearby_animals.erase(self)
				print("%s eliminado de nearby_animals de %s" % [animal_name, animal.animal_name if "animal_name" in animal else animal.name])
			if "nearby_food" in animal and self in animal.nearby_food:
				animal.nearby_food.erase(self)
				print("%s eliminado de nearby_food de %s" % [animal_name, animal.animal_name if "animal_name" in animal else animal.name])
		else:
			print("%s - Ignorando nodo inválido en grupo Animals: %s (tipo: %s, válido: %s, grupos: %s)" % [
				animal_name, animal.name if animal else "null", animal.get_class() if animal else "null", is_instance_valid(animal), animal.get_groups() if animal else []
			])
	emit_signal("animal_died", self)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = false
	if has_node("DetectionArea") and has_node("DetectionArea/CollisionShape2D"):
		var detection_collision = $DetectionArea/CollisionShape2D
		detection_collision.disabled = false
		print("%s mantuvo DetectionArea/CollisionShape2D activo, estado: %s" % [animal_name, !detection_collision.disabled])
	set_process(false)
	set_physics_process(false)
	if not remaining_loot.is_empty():
		add_to_group("Food")
		print("%s añadido al grupo Food, remaining_loot: %s" % [animal_name, str(remaining_loot)])
		update_state()
		if animated_sprite:
			if animated_sprite.sprite_frames.has_animation("Dead"):
				animated_sprite.play("Dead")
				print("%s cambió a animación Dead, remaining_loot: %s" % [animal_name, str(remaining_loot)])
			else:
				animated_sprite.play("Idle")
				animated_sprite.stop()
				print("%s advertencia: Animación 'Dead' no encontrada, usando 'Idle' detenido" % animal_name)
	else:
		print("%s eliminado inmediatamente: no hay loot restante" % animal_name)
		queue_free()
	queue_redraw()
	print("%s murió por %s, nodo: %s, en árbol: %s, loot: %s, grupos: %s" % [
		animal_name, cause, self, is_inside_tree(), str(remaining_loot), get_groups()
	])

func consume_loot(item_name: String, amount: float) -> float:
	if not is_dead or remaining_loot.is_empty():
		print("%s no puede proporcionar loot: muerto %s, remaining_loot %s" % [animal_name, is_dead, str(remaining_loot)])
		return 0.0
	
	if item_name in remaining_loot:
		var loot_data = remaining_loot[item_name]
		
		if not ("probability" in loot_data and "quantity" in loot_data):
			print("Error: loot_data para %s no tiene 'probability' o 'quantity': %s" % [item_name, str(loot_data)])
			return 0.0
		
		var probability = float(loot_data["probability"])
		if probability < 0.0 or probability > 1.0:
			print("Advertencia: Probabilidad inválida para %s: %.2f" % [item_name, probability])
			probability = clamp(probability, 0.0, 1.0)
		
		var roll = randf()
		print("%s probando loot %s: probabilidad %.2f, roll %.4f" % [animal_name, item_name, probability, roll])
		
		if roll <= probability:
			var consumed = min(loot_data["quantity"], amount)
			loot_data["quantity"] -= consumed
			if loot_data["quantity"] <= 0:
				remaining_loot.erase(item_name)
			print("%s proporcionó %.1f de %s, restante: %.1f" % [animal_name, consumed, item_name, loot_data["quantity"]])
			return consumed
		else:
			var failed_consume = min(loot_data["quantity"], 1.0)
			loot_data["quantity"] -= failed_consume
			if loot_data["quantity"] <= 0:
				remaining_loot.erase(item_name)
			print("%s falló al obtener %s, consumió %.1f de %s sin éxito" % [animal_name, item_name, failed_consume, item_name])
			return 0.0
	return 0.0

func interact_for_loot() -> Dictionary:
	if not is_dead or is_skinned or remaining_loot.is_empty():
		print("%s no puede ser despellejado: muerto %s, ya despellejado %s, remaining_loot %s" % [animal_name, is_dead, is_skinned, str(remaining_loot)])
		return {}
	is_skinned = true
	var collected_loot: Dictionary = {}
	var loot_keys = remaining_loot.keys().duplicate()
	for item_name in loot_keys:
		if not Inventory.item_map.has(item_name):
			print("Advertencia: %s intentó proporcionar '%s', pero no está en Inventory.item_map" % [animal_name, item_name])
		var loot_data = remaining_loot[item_name]
		var roll = randf()
		print("%s probando loot %s: probabilidad %.2f, roll %.4f" % [animal_name, item_name, loot_data["probability"], roll])
		if roll <= loot_data["probability"]:
			var loot_amount = loot_data["quantity"]
			collected_loot[item_name] = loot_amount
			print("%s jugador recolectó %.1f de %s en un solo despellejamiento" % [animal_name, loot_amount, item_name])
		else:
			print("%s no obtuvo %s (probabilidad fallida)" % [animal_name, item_name])
		remaining_loot.erase(item_name)
	if remaining_loot.is_empty():
		set_process(false)
		set_physics_process(false)
		if animated_sprite and animated_sprite.sprite_frames.has_animation("Consumed"):
			animated_sprite.play("Consumed")
			print("%s cambió a animación Consumed por despellejar, loot agotado" % animal_name)
		else:
			print("%s advertencia: Animación 'Consumed' no encontrada, preparando eliminación" % animal_name)
		nearby_food.erase(self)
		print("%s eliminado de nearby_food, total: %d, preparando queue_free" % [animal_name, nearby_food.size()])
		queue_free()
		print("%s ejecutó queue_free tras despellejamiento completo" % animal_name)
	else:
		print("%s advertencia: remaining_loot no está vacío después de despellejar: %s" % [animal_name, str(remaining_loot)])
	return collected_loot

func play_animation(state: String):
	if animated_sprite and animated_sprite.sprite_frames:
		var animation_name = choose_animation(state)
		if animation_name != current_animation:
			if animated_sprite.sprite_frames.has_animation(animation_name):
				animated_sprite.play(animation_name)
				current_animation = animation_name
				print("%s reproduciendo animación %s para estado %s" % [animal_name, animation_name, state])
			else:
				print("%s advertencia: Animación %s para estado %s no encontrada, reproduciendo 'Idle'" % [animal_name, animation_name, state])
				current_animation = "Idle"
	else:
		print("%s advertencia: No se puede reproducir animación %s - AnimatedSprite2D o SpriteFrames faltante" % [animal_name, state])

func _on_detection_area_entered(body):
	# Imprimir información detallada del nodo detectado
	print("%s - Entrada detectada: nodo=%s, tipo=%s, grupos=%s, padre=%s" % [
		animal_name, body.name, body.get_class(), body.get_groups(), body.get_parent().name if body.get_parent() else "ninguno"
	])
	
	# Verificar si el body es CharacterBody2D o está en el grupo "Player"
	if not (body is CharacterBody2D or body.is_in_group("Player")):
		print("%s - IGNORADO: %s no es CharacterBody2D ni Player (tipo: %s, grupos: %s)" % [
			animal_name, body.name, body.get_class(), body.get_groups()
		])
		return
	
	# Procesar nodos válidos
	if body != self and body.is_in_group("Animals"):
		if body.has_method("take_damage"):
			if body.is_dead and not body.remaining_loot.is_empty() and body.is_in_group("Food"):
				if body not in nearby_food:
					nearby_food.append(body)
					print("%s - Añadió %s (comida muerta) a nearby_food, total: %d" % [
						animal_name, body.animal_name if "animal_name" in body else body.name, nearby_food.size()
					])
			else:
				if body not in nearby_animals:
					nearby_animals.append(body)
					print("%s - Añadió %s (vivo) a nearby_animals, total: %d" % [
						animal_name, body.animal_name if "animal_name" in body else body.name, nearby_animals.size()
					])
			update_state()
	elif body.is_in_group("Player"):
		if behavior == BehaviorType.AGRESIVO:
			target = body
			print("%s - Detectó al jugador y es AGRESIVO" % animal_name)
			update_state()
		elif is_tamed and taming_player == body:
			target = body
			_switch_to_follow()
			print("%s - Detectó a su domesticador %s" % [
				animal_name, body.player_name if "player_name" in body else body.name
			])

func _on_detection_area_exited(body):
	# Imprimir información detallada del nodo que salió
	print("%s - Salida detectada: nodo=%s, tipo=%s, grupos=%s, padre=%s" % [
		animal_name, body.name, body.get_class(), body.get_groups(), body.get_parent().name if body.get_parent() else "ninguno"
	])
	
	# Verificar si el body es CharacterBody2D o está en el grupo "Player"
	if not (body is CharacterBody2D or body.is_in_group("Player")):
		print("%s - IGNORADO: %s no es CharacterBody2D ni Player (tipo: %s, grupos: %s)" % [
			animal_name, body.name, body.get_class(), body.get_groups()
		])
		return
	
	# Procesar nodos válidos
	if body in nearby_animals:
		nearby_animals.erase(body)
		print("%s - Eliminó %s de nearby_animals, total: %d" % [
			animal_name, body.animal_name if "animal_name" in body else body.name, nearby_animals.size()
		])
	if body in nearby_food:
		nearby_food.erase(body)
		print("%s - Eliminó %s de nearby_food, total: %d" % [
			animal_name, body.animal_name if "animal_name" in body else body.name, nearby_food.size()
		])
	if body == target:
		print("%s - Perdió objetivo %s al salir del área" % [
			animal_name, body.animal_name if "animal_name" in body else body.name
		])
		target = null
		update_state()
