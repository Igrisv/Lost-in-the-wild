extends Node

@export var day_length: float = 60.0  # Duración de un día en segundos
@export var start_time: float = 0.3    # Hora inicial (0.0 = medianoche, 0.5 = mediodía)
@export var transition_speed: float = 2.0  # Velocidad de la transición (menor = más lenta)

var time: float = 0.0                  # Tiempo actual (0.0 a 1.0)
var current_color: Color              # Color actual del CanvasModulate
var target_color: Color               # Color objetivo según la hora

@onready var canvas_modulate = $"."  # Referencia al CanvasModulate
var current_sun_pos: Vector2          # Posición actual del sol
var target_sun_pos: Vector2           # Posición objetivo del sol

func _ready():
	time = start_time
	current_color = get_target_color(time)
	canvas_modulate.color = current_color
	current_sun_pos = get_target_sun_position(time)

func _process(delta):
	# Avanza el tiempo
	time += delta / day_length
	if time > 1.0:
		time -= 1.0
	
	# Determina el color objetivo según la hora
	target_color = get_target_color(time)
	
	# Interpola el color actual hacia el objetivo
	current_color = current_color.lerp(target_color, delta * transition_speed)
	canvas_modulate.color = current_color
	

func get_target_color(t: float) -> Color:
	# Define los colores para cada fase del día
	if t < 0.25 or t > 0.75:  # Noche
		return Color(0.2, 0.2, 0.4)  # Azul oscuro
	elif t < 0.5:  # Amanecer/Mañana
		return Color(1.0, 0.9, 0.7)  # Cálido claro
	else:  # Tarde/Atardecer
		return Color(1.0, 0.7, 0.5)  # Anaranjado

func get_target_sun_position(t: float) -> Vector2:
	# Calcula la posición del sol/luna en un arco
	var sun_angle = t * 2.0 * PI
	# Ajusta los valores según la resolución de tu juego (por ejemplo, 1024x600)
	var x = 200 * cos(sun_angle) + 512  # Centro en x = 512
	var y = 200 * -sin(sun_angle) + 300  # Centro en y = 300
	return Vector2(x, y)
