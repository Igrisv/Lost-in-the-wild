extends CharacterBody2D

var speed: float = 200.0
var damage: float = 50.0
var attack_range: float = 50.0
var player_name: String = "Jugador"

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var needs: Needs = Needs.new() # Instancia del sistema Needs
@onready var hambre_bar: ProgressBar = $Hambre_Bar
@onready var sueño_bar: ProgressBar = $Sueño_Bar
@onready var sed_bar: ProgressBar = $Sed_Bar

var last_direction: String = "abajo"

const MAX_STAT := 100.0
const MIN_STAT := 0.0

# Estados alterados
var poisoned := false
var poisoned_time := 0.0
const POISON_DURATION := 5.0

var hotbar_node = null

# Diccionario para los cooldowns de cada necesidad (en segundos)
var cooldowns = {
	"hunger": 0.0,
	"thirst": 0.0,
	"sleep": 0.0,
	"stamina": 0.0
}

# Nuevas variables para estadísticas del equipamiento
var base_protection := 0.0  # Protección base (sin equipamiento)
var protection := 0.0       # Protección total (base + equipamiento)
var movement_speed_bonus := 0.0  # Bonificación a la velocidad por movilidad
var comfort_bonus := 0.0    # Bonificación a la regeneración de energía por comodidad
var capacity_bonus := 0.0   # Capacidad adicional de inventario (kg o slots)
var efficiency_bonus := 0.0 # Bonificación a la eficiencia de acciones

func _ready() -> void:
	add_to_group("Player")
	hotbar_node = get_hotbar()
	var inventory = get_node_or_null("/root/Inventory")
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

func _physics_process(_delta):
	# Actualizar necesidades según el tiempo
	needs.hunger = max(needs.hunger - 0.1 * _delta, MIN_STAT)
	needs.thirst = max(needs.thirst - 0.15 * _delta, MIN_STAT)
	needs.sleep = max(needs.sleep - 0.05 * _delta, MIN_STAT)
	
	sed_bar.value = needs.thirst
	hambre_bar.value = needs.hunger
	sueño_bar.value = needs.sleep
	
	if velocity.length() < 1:
		needs.stamina = min(needs.stamina + (0.2 + comfort_bonus * 0.01) * _delta, MAX_STAT)  # Ajuste por comodidad
		print("Regeneración de stamina: ", needs.stamina, " (Comfort bonus: ", comfort_bonus, ")")
	else:
		needs.stamina = max(needs.stamina - 0.5 * _delta, MIN_STAT)
	
	# Manejo envenenamiento
	if poisoned:
		poisoned_time += _delta
		if poisoned_time >= POISON_DURATION:
			poisoned = false
			poisoned_time = 0.0
			print("Ya no estás envenenado.")
		else:
			damage -= 0.1 * _delta * (1.0 - (protection / 100.0))  # Reducción de daño por protección
			print("Daño por envenenamiento: ", 0.1 * _delta * (1.0 - (protection / 100.0)), " (Protección: ", protection, "%)")

	# Actualizar los cooldowns en cada frame
	for key in cooldowns.keys():
		if cooldowns[key] > 0:
			cooldowns[key] -= _delta
			if cooldowns[key] < 0:
				cooldowns[key] = 0.0

	# --- Código original de movimiento y animaciones ---
	if Input.is_action_pressed("interactuar"):
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

	# Animaciones según dirección
	if direction != Vector2.ZERO:
		if direction.y > 0:
			animated_sprite_2d.play("Moverse_Abajo")
		elif direction.y < 0:
			animated_sprite_2d.play("Moverse_Arriba")
		else:
			animated_sprite_2d.play("Moverse_Derecha")  # Se reutiliza izquierda con flip_h
	else:
		animated_sprite_2d.stop()
		moving = false

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

	velocity = direction.normalized() * (speed + movement_speed_bonus)
	print("Velocidad actual: ", speed + movement_speed_bonus, " (Movement bonus: ", movement_speed_bonus, ")")
	move_and_slide()

func reproducir_animacion_ataque():
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

# Consumir item con efectos, usando Needs.EffectType
func consume_item(item: Item) -> void:
	if not item or not item.effects:
		return

	for effect in item.effects:
		match effect.type:
			Needs.EffectType.HUNGER:
				needs.hunger = clamp(needs.hunger + effect.value, MIN_STAT, MAX_STAT)
				if needs.hunger >= MAX_STAT:
					activate_cooldown("hunger")
			Needs.EffectType.THIRST:
				needs.thirst = clamp(needs.thirst + effect.value, MIN_STAT, MAX_STAT)
				if needs.thirst >= MAX_STAT:
					activate_cooldown("thirst")
			Needs.EffectType.SLEEP:
				needs.sleep = clamp(needs.sleep + effect.value, MIN_STAT, MAX_STAT)
				if needs.sleep >= MAX_STAT:
					activate_cooldown("sleep")
			Needs.EffectType.STAMINA:
				needs.stamina = clamp(needs.stamina + effect.value, MIN_STAT, MAX_STAT)
				if needs.stamina >= MAX_STAT:
					activate_cooldown("stamina")
			Needs.EffectType.POISON:
				poisoned = true
				poisoned_time = 0.0
			Needs.EffectType.CURE_POISON:
				poisoned = false
				poisoned_time = 0.0
			_:
				print("Efecto no manejado:", effect.type)

# Activa un cooldown para una necesidad específica
func activate_cooldown(need_type: String, duration: float = 10.0):
	cooldowns[need_type] = duration
	print("Cooldown activado para %s por %.1f segundos" % [need_type, duration])

func get_hotbar() -> Node:
	var hotbars = get_tree().get_nodes_in_group("Hotbar")
	if hotbars.size() > 0:
		return hotbars[0]
	return null

func apply_consumable_effect(consumable_data):
	if consumable_data == null:
		return

	for effect in consumable_data.effects:
		match effect.type:
			ConsumableData.EffectType.HUNGER:
				needs.hunger = clamp(needs.hunger + effect.value, MIN_STAT, MAX_STAT)
				if needs.hunger >= MAX_STAT:
					activate_cooldown("hunger")
			ConsumableData.EffectType.THIRST:
				needs.thirst = clamp(needs.thirst + effect.value, MIN_STAT, MAX_STAT)
				if needs.thirst >= MAX_STAT:
					activate_cooldown("thirst")
			ConsumableData.EffectType.SLEEP:
				needs.sleep = clamp(needs.sleep + effect.value, MIN_STAT, MAX_STAT)
				if needs.sleep >= MAX_STAT:
					activate_cooldown("sleep")
			ConsumableData.EffectType.STAMINA:
				needs.stamina = clamp(needs.stamina + effect.value, MIN_STAT, MAX_STAT)
				if needs.stamina >= MAX_STAT:
					activate_cooldown("stamina")
			_:
				print("Efecto no manejado en consumable:", effect.type)

func should_consume(consumable_data: ConsumableData) -> Dictionary:
	if consumable_data == null:
		return { "can_consume": false, "reason": "Sin datos" }

	var can_consume = false
	var reasons = []

	for effect in consumable_data.effects:
		match effect.type:
			ConsumableData.EffectType.HUNGER:
				if cooldowns["hunger"] > 0:
					reasons.append("Espera para consumir más que afecte el hambre")
				elif needs.hunger < MAX_STAT:
					can_consume = true
			ConsumableData.EffectType.THIRST:
				if cooldowns["thirst"] > 0:
					reasons.append("Espera para consumir más que afecte la sed")
				elif needs.thirst < MAX_STAT:
					can_consume = true
			ConsumableData.EffectType.SLEEP:
				if cooldowns["sleep"] > 0:
					reasons.append("Espera para consumir más que afecte el sueño")
				elif needs.sleep < MAX_STAT:
					can_consume = true
			ConsumableData.EffectType.STAMINA:
				if cooldowns["stamina"] > 0:
					reasons.append("Espera para consumir más que afecte la stamina")
				elif needs.stamina < MAX_STAT:
					can_consume = true
			ConsumableData.EffectType.HEALTH:
				if damage < 100.0:
					can_consume = true
			ConsumableData.EffectType.REMOVE_POISON:
				if poisoned:
					can_consume = true
			ConsumableData.EffectType.HALLUCINATION:
				can_consume = true  # Efecto negativo, siempre permitido

	if can_consume:
		return { "can_consume": true }
	else:
		var reason = ", ".join(reasons) if reasons else "No tienes necesidad de esto ahora"
		return { "can_consume": false, "reason": reason }

# Nueva función para actualizar estadísticas basadas en equipamiento
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
				print("Propiedades de ", slot.item.name, ": ", slot.item)
				if "protection" in slot.item:
					protection += slot.item.protection
					print("Protección añadida: ", slot.item.protection, " (Total: ", protection, ")")
				else:
					print("Propiedad 'protection' no encontrada en ", slot.item.name)
				if "mobility" in slot.item:
					movement_speed_bonus += slot.item.mobility
					print("Movilidad añadida: ", slot.item.mobility, " (Total bonus: ", movement_speed_bonus, ")")
				else:
					print("Propiedad 'mobility' no encontrada en ", slot.item.name)
				if "comfort" in slot.item:
					comfort_bonus += slot.item.comfort
					print("Comodidad añadida: ", slot.item.comfort, " (Total bonus: ", comfort_bonus, ")")
				else:
					print("Propiedad 'comfort' no encontrada en ", slot.item.name)
				if "capacity" in slot.item:
					capacity_bonus += slot.item.capacity
					print("Capacidad añadida: ", slot.item.capacity, " (Total bonus: ", capacity_bonus, ")")
				else:
					print("Propiedad 'capacity' no encontrada en ", slot.item.name)
				if "efficiency" in slot.item:
					efficiency_bonus += slot.item.efficiency
					print("Eficiencia añadida: ", slot.item.efficiency, " (Total bonus: ", efficiency_bonus, ")")
				else:
					print("Propiedad 'efficiency' no encontrada en ", slot.item.name)
			else:
				print("Slot ", slot.name, " está vacío")
	else:
		print("ERROR: No se pudo acceder al Autoload Inventory o equipment_slots no está definido")

	print("Estadísticas actualizadas - Protección: ", protection, ", Velocidad bonus: ", movement_speed_bonus,
		  ", Comodidad: ", comfort_bonus, ", Capacidad: ", capacity_bonus, ", Eficiencia: ", efficiency_bonus)

# Nuevos métodos para manejar las señales
func _on_item_equipped(item, slot):
	print("Ítem equipado detectado: ", item.name, " en slot: ", slot.equipment_slot)
	update_equipment_stats()

func _on_item_unequipped(item, slot):
	print("Ítem desequipado detectado: ", item.name, " de slot: ", slot.equipment_slot)
	update_equipment_stats()
