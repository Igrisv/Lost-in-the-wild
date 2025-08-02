extends CharacterBody2D

var speed: float = 200.0
var damage: float = 50.0
var attack_range: float = 50.0
var player_name: String = "Jugador"

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var last_direction: String = "abajo"

func _physics_process(_delta):
	# Si está atacando, no se mueve
	if Input.is_action_pressed("interactuar"):
		reproducir_animacion_ataque()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Movimiento normal
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

	# Idle si no se mueve
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

	# Movimiento real
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
