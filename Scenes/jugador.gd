extends CharacterBody2D

var speed: float = 200.0
var target = null
var damage: float = 50.0
var attack_range: float = 50.0
var player_name: String = "Jugador"


func _physics_process(_delta):
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
