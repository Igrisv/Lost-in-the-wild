extends Resource
class_name ItemEffect

@export var effect_type: int # Usa ItemEffectType
@export var value: float = 0.0
@export var duration: float = 0.0
@export var intensity: float = 1.0
@export var status_effect: String = "" # Solo si el tipo es ADD_STATUS_EFFECT
