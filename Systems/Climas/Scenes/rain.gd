extends Node2D

@export var fade_duration := 3
@onready var overlay: CanvasItem = $Overlay

func _ready():
	# Aparecer con tween
	overlay.modulate.a = 0.0
	create_tween().tween_property(overlay, "modulate:a", target_opacity(), fade_duration)
	#overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func target_opacity() -> float:
	return 5 # o lo que necesites

func fade_out_and_free():
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(Callable(self, "queue_free"))
