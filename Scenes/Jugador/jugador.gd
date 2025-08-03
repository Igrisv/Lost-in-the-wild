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

func _ready() -> void:
	add_to_group("Player")
	hotbar_node = get_hotbar()

func _physics_process(_delta):
	# Actualizar necesidades según el tiempo
	needs.hunger = max(needs.hunger - 0.1 * _delta, MIN_STAT)
	needs.thirst = max(needs.thirst - 0.15 * _delta, MIN_STAT)
	needs.sleep = max(needs.sleep - 0.05 * _delta, MIN_STAT)
	
	sed_bar.value = needs.thirst
	hambre_bar.value = needs.hunger
	sueño_bar.value = needs.sleep
	
	if velocity.length() < 1:
		needs.stamina = min(needs.stamina + 0.2 * _delta, MAX_STAT)
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
			damage -= 0.1 * _delta

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

	if Input.is_action_pressed("derecha"):
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play("Moverse_Derecha")
		direction.x += 1
		last_direction = "derecha"
		moving = true
	elif Input.is_action_pressed("izquierda"):
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.play("Moverse_Derecha")
		direction.x -= 1
		last_direction = "izquierda"
		moving = true
	elif Input.is_action_pressed("abajo"):
		animated_sprite_2d.play("Moverse_Abajo")
		direction.y += 1
		last_direction = "abajo"
		moving = true
	elif Input.is_action_pressed("arriba"):
		animated_sprite_2d.play("Moverse_Arriba")
		direction.y -= 1
		last_direction = "arriba"
		moving = true

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

	velocity = direction.normalized() * speed
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
