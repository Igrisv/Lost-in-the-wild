extends Area2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 100.0
var damage: float = 0.0
var velocity: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	velocity = direction * speed
	global_position += velocity * delta

func _ready() -> void:
	# Conectar señal body_entered para detectar colisiones
	body_entered.connect(_on_body_entered)
	# Destruir el proyectil tras 5 segundos si no colisiona
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()  # Destruir el proyectil al impactar
