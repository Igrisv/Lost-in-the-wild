class_name Player
extends CharacterBody2D

#region Player_stats
@export var speed := 200.0
var damage: float = 50.0
var attack_range: float = 70.0
var player_name: String = "Jugador"
var current_speed := speed
var stamina_drain_mult := 1.0
var hunger_drain_mult := 1.0
var damage_over_time := 0.0
#endregion

#region Onready
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var needs: Needs = Needs.new() # Instancia del sistema Needs
@onready var hambre_bar: ProgressBar = $Hambre_Bar
@onready var sueño_bar: ProgressBar = $Sueño_Bar
@onready var sed_bar: ProgressBar = $Sed_Bar
#endregion

var last_direction: String = "abajo"

const MAX_STAT := 100.0
const MIN_STAT := 0.0
var hotbar_node = null
# Diccionario para los cooldowns de cada necesidad (en segundos)
var cooldowns = {
	"hunger": 0.0,
	"thirst": 0.0,
	"sleep": 0.0,
	"stamina": 0.0
}

#region Equipment
# Nuevas variables para estadísticas del equipamiento
var base_protection := 0.0  # Protección base (sin equipamiento)
var protection := 0.0       # Protección total (base + equipamiento)
var movement_speed_bonus := 0.0  # Bonificación a la velocidad por movilidad
var comfort_bonus := 0.0    # Bonificación a la regeneración de energía por comodidad
var capacity_bonus := 0.0   # Capacidad adicional de inventario (kg o slots)
var efficiency_bonus := 0.0 # Bonificación a la eficiencia de acciones
#endregion

func _ready() -> void:
	add_to_group("Player")
#region Climas
	if WeatherManager:
		var weather_callable = Callable(self, "_on_weather_changed")
		if WeatherManager.weather_changed.is_connected(weather_callable):
			print("Señal weather_changed ya conectada para Player: ", self)
		else:
			WeatherManager.weather_changed.connect(weather_callable, CONNECT_ONE_SHOT if WeatherManager.weather_changed.is_connected(weather_callable) else 0)
			print("Señal weather_changed conectada exitosamente para Player: ", self, " con callable: ", weather_callable)
		if WeatherManager.current_weather != "":
			_on_weather_changed(WeatherManager.current_weather) # Aplicar efectos iniciales
			print("Clima inicial aplicado: ", WeatherManager.current_weather)
		else:
			print("ERROR: WeatherManager.current_weather no está inicializado")
	else:
		print("ERROR: WeatherManager no encontrado")
#endregion
#region Inventory

	hotbar_node = get_hotbar()
	var inventory = Inventory
	if inventory:
		print("Inventario encontrado: ", inventory.name)
		# Conectar señales del inventario al jugador
		if not inventory.is_connected("item_equipped", _on_item_equipped):
			inventory.connect("item_equipped", Callable(self, "_on_item_equipped"))
		if not inventory.is_connected("item_unequipped", _on_item_unequipped):
			inventory.connect("item_unequipped", Callable(self, "_on_item_unequipped"))
	else:
		print("ERROR: Inventario no encontrado en /root/Inventory")
	update_equipment_stats()  # Inicializar estadísticas al empezar
	# Conectar la señal animation_finished para manejar el fin de las animaciones
	animated_sprite_2d.connect("animation_finished", Callable(self, "_on_animation_finished"))
#endregion

func _physics_process(_delta):
	# Actualizar necesidades según el tiempo
	needs.hunger = max(needs.hunger - 0.50 * _delta, MIN_STAT)
	needs.thirst = max(needs.thirst - 0.15 * _delta, MIN_STAT)
	needs.sleep = max(needs.sleep - 0.05 * _delta, MIN_STAT)
	
	sed_bar.value = needs.thirst
	hambre_bar.value = needs.hunger
	sueño_bar.value = needs.sleep
	
	if velocity.length() < 1:
		needs.stamina = min(needs.stamina + (0.2 + comfort_bonus * 0.01) * _delta, MAX_STAT)  # Ajuste por comodidad
	else:
		needs.stamina = max(needs.stamina - 0.5 * _delta, MIN_STAT)
	

	# Actualizar los cooldowns en cada frame
	for key in cooldowns.keys():
		if cooldowns[key] > 0:
			cooldowns[key] -= _delta
			if cooldowns[key] < 0:
				cooldowns[key] = 0.0

# --- Código de ataque ---
	if Input.is_action_just_pressed("attack"):  # Asume input "attack" configurado en Project Settings
		var hotbar = get_hotbar()
		if hotbar and hotbar.currently_equipped and hotbar.currently_equipped.item_type == Item.ItemType.WEAPON:
			hotbar.use_current()  # Delega al hotbar para ejecutar la acción de ataque
			return
	
	# --- Código de movimiento y animaciones ---
	if Input.is_action_just_pressed("interactuar"):
		var interactables = get_tree().get_nodes_in_group("Interactable")
		var closest = null
		var min_distance = attack_range
		for node in interactables:
			var distance = global_position.distance_to(node.global_position)
			if distance < min_distance:
				min_distance = distance
				closest = node
		if closest and closest.has_method("interact"):
			closest.interact(self)
			return
		# Fallback a animación de ataque si no hay interactuables
		if not animated_sprite_2d.is_playing() or not animated_sprite_2d.animation.begins_with("Atacar_"):
			reproducir_animacion_ataque()
			velocity = Vector2.ZERO
			move_and_slide()
			return
	
	if Input.is_action_just_pressed("usar_item"):
		print("Input detectado")
		if hotbar_node:
			hotbar_node.use_current()
	
	var direction = Vector2.ZERO
	var moving = false

	# Dirección horizontal
	if Input.is_action_pressed("derecha"):
		direction.x += 1
		animated_sprite_2d.flip_h = false
		last_direction = "derecha"
		moving = true
	elif Input.is_action_pressed("izquierda"):
		direction.x -= 1
		animated_sprite_2d.flip_h = true
		last_direction = "izquierda"
		moving = true

	# Dirección vertical
	if Input.is_action_pressed("abajo"):
		direction.y += 1
		last_direction = "abajo"
		moving = true
	elif Input.is_action_pressed("arriba"):
		direction.y -= 1
		last_direction = "arriba"
		moving = true

	# Normalizar para evitar velocidad extra en diagonal
	direction = direction.normalized()

	# Animaciones según dirección (solo si no está reproduciendo una animación de ataque)
	if not animated_sprite_2d.is_playing() or not animated_sprite_2d.animation.begins_with("Atacar_"):
		if direction != Vector2.ZERO:
			if direction.y > 0:
				animated_sprite_2d.play("Moverse_Abajo")
			elif direction.y < 0:
				animated_sprite_2d.play("Moverse_Arriba")
			else:
				animated_sprite_2d.play("Moverse_Derecha")  # Se reutiliza izquierda con flip_h
		else:
			# Solo pasar a Idle si no está en movimiento
			if not moving:
				match last_direction:
					"derecha":
						animated_sprite_2d.flip_h = false
						animated_sprite_2d.play("Idle_Derecha")
					"izquierda":
						animated_sprite_2d.flip_h = true
						animated_sprite_2d.play("Idle_Derecha")
					"arriba":
						animated_sprite_2d.play("Idle_Arriba")
					"abajo":
						animated_sprite_2d.play("Idle_Abajo")

	velocity = direction.normalized() * (current_speed + movement_speed_bonus)
	move_and_slide()


#region Animation_func

func reproducir_animacion_ataque():
	# Solo reproducir si no está ya reproduciendo una animación de ataque
	if animated_sprite_2d.is_playing() and animated_sprite_2d.animation.begins_with("Atacar_"):
		return
	
	match last_direction:
		"derecha":
			animated_sprite_2d.flip_h = false
			animated_sprite_2d.play("Atacar_Derecha")
		"izquierda":
			animated_sprite_2d.flip_h = true
			animated_sprite_2d.play("Atacar_Derecha")
		"arriba":
			animated_sprite_2d.play("Atacar_Arriba")
		"abajo":
			animated_sprite_2d.play("Atacar_Abajo")

func play_animation(animation: String) -> void:
	if animation and animated_sprite_2d.sprite_frames.has_animation(animation):
		animated_sprite_2d.play(animation)
	else:
		# Fallback a animación de ataque
		reproducir_animacion_ataque()

func play_sound(sound: AudioStream) -> void:
	if sound:
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = sound
		add_child(audio_player)
		audio_player.play()
		audio_player.finished.connect(func(): audio_player.queue_free())

func _on_animation_finished():
	# Cuando termina una animación de ataque, pasar a la animación de reposo
	if animated_sprite_2d.animation.begins_with("Atacar_") or animated_sprite_2d.animation.begins_with("chop"):
		match last_direction:
			"derecha":
				animated_sprite_2d.flip_h = false
				animated_sprite_2d.play("Idle_Derecha")
			"izquierda":
				animated_sprite_2d.flip_h = true
				animated_sprite_2d.play("Idle_Derecha")
			"arriba":
				animated_sprite_2d.play("Idle_Arriba")
			"abajo":
				animated_sprite_2d.play("Idle_Abajo")
#endregion

#region Inventory_func

#func consume_item(item: Item) -> void:
	#if not item or not item.effects:
		#return
#
	#var result = should_consume(item.consumable_data)
#
	#if not result["can_consume"]:
		#print("No se puede consumir:", result["reason"])
		#return
#
	## Si pasa el chequeo, aplicar efectos
	#for effect in item.effects:
		#match effect.type:
			#Needs.EffectType.HUNGER:
				#needs.hunger = clamp(needs.hunger + effect.value, MIN_STAT, MAX_STAT)
				#if needs.hunger >= MAX_STAT:
					#activate_cooldown("hunger")
			#Needs.EffectType.THIRST:
				#needs.thirst = clamp(needs.thirst + effect.value, MIN_STAT, MAX_STAT)
				#if needs.thirst >= MAX_STAT:
					#activate_cooldown("thirst")
			#Needs.EffectType.SLEEP:
				#needs.sleep = clamp(needs.sleep + effect.value, MIN_STAT, MAX_STAT)
				#if needs.sleep >= MAX_STAT:
					#activate_cooldown("sleep")
			#Needs.EffectType.STAMINA:
				#needs.stamina = clamp(needs.stamina + effect.value, MIN_STAT, MAX_STAT)
				#if needs.stamina >= MAX_STAT:
					#activate_cooldown("stamina")
			#_:
				#print("Efecto no manejado:", effect.type)

func activate_cooldown(need_type: String, duration: float = 10.0):
	cooldowns[need_type] = duration
	print("Cooldown activado para %s por %.1f segundos" % [need_type, duration])

func get_hotbar() -> Node:
	var hotbars = get_tree().get_nodes_in_group("Hotbar")
	if hotbars.size() > 0:
		return hotbars[0]
	return null

func apply_consumable_effect(consumable_data: ConsumableData) -> void:
	if consumable_data == null:
		print("Error: ConsumableData es null")
		return

	for effect in consumable_data.effects:
		match effect.type:
			ConsumableData.EffectType.Hunger:
				if needs.hunger < MAX_STAT:
					needs.hunger = clamp(needs.hunger + effect.value, MIN_STAT, MAX_STAT)
					activate_cooldown("hunger")
					print("Hambre restaurada: ", needs.hunger)
			ConsumableData.EffectType.Thirst:
				if needs.thirst < MAX_STAT:
					needs.thirst = clamp(needs.thirst + effect.value, MIN_STAT, MAX_STAT)
					activate_cooldown("thirst")
					print("Sed restaurada: ", needs.thirst)
			ConsumableData.EffectType.Sleep:
				if needs.sleep < MAX_STAT:
					needs.sleep = clamp(needs.sleep + effect.value, MIN_STAT, MAX_STAT)
					activate_cooldown("sleep")
					print("Sueño restaurado: ", needs.sleep)
			ConsumableData.EffectType.Stamina:
				if needs.stamina < MAX_STAT:
					needs.stamina = clamp(needs.stamina + effect.value, MIN_STAT, MAX_STAT)
					activate_cooldown("stamina")
					print("Estamina restaurada: ", needs.stamina)
			_:
				print("Efecto no manejado en consumable: ", effect.type)

func should_consume(consumable_data: ConsumableData) -> Dictionary:
	if consumable_data == null:
		return { "can_consume": false, "reason": "Sin datos de consumible" }

	var can_consume = false
	var reasons = []

	for effect in consumable_data.effects:
		match effect.type:
			ConsumableData.EffectType.Hunger:
				if cooldowns["hunger"] > 0:
					reasons.append("Estás lleno, espera antes de comer")
				elif needs.hunger < MAX_STAT:
					can_consume = true
				else:
					reasons.append("Hambre al máximo")
			ConsumableData.EffectType.Thirst:
				if cooldowns["thirst"] > 0:
					reasons.append("Estás saciado, espera antes de beber")
				elif needs.thirst < MAX_STAT:
					can_consume = true
				else:
					reasons.append("Sed al máximo")
			ConsumableData.EffectType.Sleep:
				if cooldowns["sleep"] > 0:
					reasons.append("No necesitas dormir ahora")
				elif needs.sleep < MAX_STAT:
					can_consume = true
				else:
					reasons.append("Sueño al máximo")
			ConsumableData.EffectType.Stamina:
				if cooldowns["stamina"] > 0:
					reasons.append("Estamina en cooldown")
				elif needs.stamina < MAX_STAT:
					can_consume = true
				else:
					reasons.append("Estamina al máximo")
			_:
				can_consume = true  # Efectos no relacionados con necesidades siempre permitidos

	if can_consume:
		return { "can_consume": true, "reason": "" }
	elif reasons:
		return { "can_consume": false, "reason": ", ".join(reasons) }
	else:
		return { "can_consume": false, "reason": "No necesitas esto ahora" }

func update_equipment_stats():
	protection = base_protection
	movement_speed_bonus = 0.0
	comfort_bonus = 0.0
	capacity_bonus = 0.0
	efficiency_bonus = 0.0

	var inventory = Inventory  # Acceder al Autoload Inventory
	if inventory and "equipment_slots" in inventory:
		print("Accediendo a equipment_slots desde Autoload Inventory")
		var slots = inventory.equipment_slots
		print("Encontrados ", slots.size(), " slots de equipamiento")
		for slot in slots:
			print("Slot analizado: ", slot.name, " - Item: ", slot.item.name if slot.item else "null")
			if slot.item:
				if "protection" in slot.item:
					protection += slot.item.protection
				else:
					print("Propiedad 'protection' no encontrada en ", slot.item.name)
				if "mobility" in slot.item:
					movement_speed_bonus += slot.item.mobility
				else:
					print("Propiedad 'mobility' no encontrada en ", slot.item.name)
				if "comfort" in slot.item:
					comfort_bonus += slot.item.comfort
				else:
					print("Propiedad 'comfort' no encontrada en ", slot.item.name)
				if "capacity" in slot.item:
					capacity_bonus += slot.item.capacity
				else:
					print("Propiedad 'capacity' no encontrada en ", slot.item.name)
				if "efficiency" in slot.item:
					efficiency_bonus += slot.item.efficiency
				else:
					print("Propiedad 'efficiency' no encontrada en ", slot.item.name)
			else:
				print("Slot ", slot.name, " está vacío")
	else:
		print("ERROR: No se pudo acceder al Autoload Inventory o equipment_slots no está definido")

func _on_item_equipped(item, slot):
	print("Ítem equipado detectado: ", item.name, " en slot: ", slot.equipment_slot)
	update_equipment_stats()

func _on_item_unequipped(item, slot):
	print("Ítem desequipado detectado: ", item.name, " de slot: ", slot.equipment_slot)
	update_equipment_stats()
#endregion

func _on_weather_changed(weather: String) -> void:
	print("DEBUG: _on_weather_changed ejecutado para Player: ", self, " con clima: ", weather)
	if weather == "":
		print("ERROR: Clima recibido es vacío o inválido")
		return
	
	reset_weather_effects()
	match weather:
		"lluvia":
			print("Aplicando efectos de lluvia")
			current_speed = speed * 0.7
			print("Velocidad ajustada a: ", current_speed)
			stamina_drain_mult = 1.3
			if animated_sprite_2d:
				_apply_visual_tint(Color(0.7, 0.7, 0.9)) # más oscuro y húmedo
				print("Tinte aplicado: Color(0.7, 0.7, 0.9)")
			else:
				print("ERROR: animated_sprite_2d no está asignado")
			#if $AnimationPlayer and $AnimationPlayer.has_animation("wet"):
				#_trigger_animation("wet") # animación de caminar más lento
				#print("Animación 'wet' disparada")
			#else:
				#print("ERROR: AnimationPlayer no encontrado o animación 'wet' no existe")
		_:
			print("Clima no manejado: ", weather)

		# Más climas en el futuro:
		# "tormenta_arena":
		# "nieve":
		# "niebla_toxica":

func reset_weather_effects():
	current_speed = speed
	stamina_drain_mult = 1.0
	hunger_drain_mult = 1.0
	damage_over_time = 0.0
	_apply_visual_tint(Color(1, 1, 1))

func _apply_visual_tint(color: Color):
	animated_sprite_2d.modulate = color

func _trigger_animation(anim: String):
	if $AnimationPlayer.has_animation(anim):
		$AnimationPlayer.play(anim)
		
#func _process(delta):
	#if damage_over_time > 0:
		#_apply_damage(damage_over_time * delta)
#
#func _apply_damage(amount: float):
	## Lógica para restar vida
	#pass
