class_name Creature
extends CharacterBody2D

# Estados base, extensible por clases derivadas
enum State { IDLE, WANDER, FLEE, ATTACK }

# Propiedades exportadas para configuración en el Inspector
@export var speed: float = 80.0
@export var detection_range: float = 200.0
@export var interaction_range: float = 50.0
@export var faction: String = "Nahlir"  # Integra con GDD: Nahlir, Veyari, Kareen
@export var tameable: bool = true  # Para tameo universal
@export var tame_requirements: Dictionary = {}  # Ej: {"item": "FoodItem", "proximity_time": 5.0}
@export var health: float = 100.0  # Nueva variable para vida
@export var health_drain_rate: float = 0.0  # Opcional, 0 por defecto (vida no drena sola)

# Necesidades
@export var needs: Needs = Needs.new()
@export var hunger_drain_rate: float = 0.5
@export var thirst_drain_rate: float = 0.15
@export var sleep_drain_rate: float = 0.05

var current_state: State = State.IDLE
var target: Node2D = null  # Jugador u otra criatura
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_timer: Timer = $StateTimer  # Para transiciones de estado
var wander_target: Vector2 = Vector2.ZERO  # Punto de destino para WANDER
@export var wander_range: float = 100.0  # Radio para elegir puntos de destino
@export var wander_change_interval: float = 3.0  # Segundos entre cambios de dirección
@onready var wander_timer: Timer = $WanderTimer  # Timer para cambios de dirección
@onready var info_label: Label = $InfoLabel  # Label para mostrar información

# Señales para comportamientos escalables
signal state_changed(new_state: State)
signal tamed(player: Player)

func _ready() -> void:
	add_to_group("Creature")
	# Configurar timer para cambios de estado
	if not state_timer:
		var timer = Timer.new()
		timer.name = "StateTimer"
		add_child(timer)
		state_timer = timer
	state_timer.timeout.connect(_on_state_timer_timeout)
	# Configurar timer para cambios de dirección en WANDER
	if not wander_timer:
		var timer = Timer.new()
		timer.name = "WanderTimer"
		add_child(timer)
		wander_timer = timer
	wander_timer.wait_time = wander_change_interval
	wander_timer.timeout.connect(_on_wander_timer_timeout)
	wander_timer.start()
	# Inicializar InfoLabel
	if not info_label:
		var label = Label.new()
		label.name = "InfoLabel"
		add_child(label)
		info_label = label
	update_info_label()

func _physics_process(delta: float) -> void:
	# Actualizar necesidades y vida
	update_needs(delta)
	update_health(delta)
	
	# Procesar estado actual
	process_state(delta)
	
	# Mover y actualizar animaciones
	move_and_slide()
	update_animation(velocity)
	
	# Detectar objetivos e interactuar con entorno
	detect_targets()
	interact_with_environment()
	
	# Actualizar Label
	update_info_label()

# Actualizar necesidades y manejar consecuencias
func update_needs(delta: float) -> void:
	needs.hunger = max(needs.hunger - hunger_drain_rate * delta, 0.0)
	needs.thirst = max(needs.thirst - thirst_drain_rate * delta, 0.0)
	needs.sleep = max(needs.sleep - sleep_drain_rate * delta, 0.0)
	if needs.hunger <= 0 or needs.thirst <= 0 or needs.sleep <= 0:
		die()

# Actualizar vida
func update_health(delta: float) -> void:
	health = max(health - health_drain_rate * delta, 0.0)
	if health <= 0:
		die()

# Método virtual para procesar estados
func process_state(delta: float) -> void:
	if is_in_group("Tamed") and get_tree().get_first_node_in_group("Player"):
		process_tamed_behavior(delta)
		return  # Salir si está domada para evitar estados normales
	match current_state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 2)
			animated_sprite.play("idle")
		State.WANDER:
			if global_position.distance_to(wander_target) < 10.0 or wander_target == Vector2.ZERO:
				update_wander_target()
			var direction = (wander_target - global_position).normalized()
			velocity = velocity.move_toward(direction * speed, speed * delta * 3)
		State.FLEE:
			if target:
				var direction = (global_position - target.global_position).normalized()
				velocity = velocity.move_toward(direction * speed, speed * delta * 3)
		State.ATTACK:
			if target:
				var direction = (target.global_position - global_position).normalized()
				velocity = velocity.move_toward(direction * speed, speed * delta * 3)
				if global_position.distance_to(target.global_position) <= interaction_range:
					attack_target()

# Añade este nuevo método al final de Creature.gd
func process_tamed_behavior(_delta: float) -> void:
	# Comportamiento base vacío, sobrescribible por clases derivadas
	pass

# Detección de objetivos
func detect_targets() -> void:
	var potential_targets = get_tree().get_nodes_in_group("Player") + get_tree().get_nodes_in_group("Creature")
	target = null
	var min_distance = detection_range
	for t in potential_targets:
		if t != self:
			var distance = global_position.distance_to(t.global_position)
			if distance < min_distance:
				min_distance = distance
				target = t
				update_state_based_on_target(t)
	if target == null and current_state != State.IDLE:
		change_state(State.IDLE)

# Método virtual para decidir estado según objetivo
func update_state_based_on_target(_target: Node2D) -> void:
	pass

# Cambiar estado con señal
func change_state(new_state: State) -> void:
	if current_state != new_state:
		current_state = new_state
		emit_signal("state_changed", new_state)
		state_timer.start(randf_range(2.0, 5.0))

# Actualizar animaciones según movimiento
func update_animation(direction: Vector2) -> void:
	if direction.length() < 0.1:
		animated_sprite.play("idle")
	else:
		if abs(direction.x) > abs(direction.y):
			animated_sprite.play("walk_right")
			animated_sprite.flip_h = direction.x < 0

# Interacción con entorno
func interact_with_environment() -> void:
	var resources = get_tree().get_nodes_in_group("Resources")
	if resources.size() > 0:
		var closest = resources[0]
		if global_position.distance_to(closest.global_position) < interaction_range:
			consume_resource(closest)

# Consumir recursos del entorno
func consume_resource(resource: Node2D) -> void:
	needs.hunger = min(needs.hunger + 20, 100)
	resource.queue_free()

# Interacción con jugador (para tameo)
func interact(player: Player) -> void:
	if tameable and can_be_tamed_by(player):
		tame(player)
	else:
		change_state(State.FLEE)

# Condición de doma
func can_be_tamed_by(_player: Player) -> bool:
	return false

# Tameo base
func tame(player: Player) -> void:
	add_to_group("Tamed")
	emit_signal("tamed", player)
	change_state(State.IDLE)

# Muerte por necesidades insatisfechas o falta de vida
func die() -> void:
	queue_free()

# Implementar daño
func take_damage(amount: float) -> void:
	health = max(health - amount, 0.0)
	if health <= 0:
		die()

# Método virtual para atacar
func attack_target() -> void:
	pass

# Manejo de timer para transiciones de estado
func _on_state_timer_timeout() -> void:
	if current_state == State.WANDER:
		change_state(State.IDLE)
	elif current_state == State.IDLE:
		change_state(State.WANDER)

func _on_wander_timer_timeout() -> void:
	if current_state == State.WANDER:
		update_wander_target()

func update_wander_target() -> void:
	var angle = randf_range(0, TAU)
	var distance = randf_range(wander_range * 0.5, wander_range)
	wander_target = global_position + Vector2(cos(angle), sin(angle)) * distance
	wander_timer.start(wander_change_interval)

# Actualizar la información en la Label
func update_info_label() -> void:
	if info_label:
		var state_text = State.keys()[current_state]
		var tamed_status = "Domada" if is_in_group("Tamed") else "No domada"
		var tame_item = tame_requirements.get("item", "Ninguno")
		var proximity_time = tame_requirements.get("proximity_time", 0.0)
		var text = """Vida: %.1f
Hambre: %.1f
Sed: %.1f
Sueño: %.1f
Estado: %s
Domable: %s
Estado de doma: %s
Ítem requerido: %s
Tiempo de proximidad: %.1f s""" % [
			health, needs.hunger, needs.thirst, needs.sleep,
			state_text, "Sí" if tameable else "No", tamed_status, tame_item, proximity_time
		]
		info_label.text = text
