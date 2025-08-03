extends Resource
class_name ConsumableData

@export var effects: Array[Effect] = []
@export var hunger_restore: float = 0
@export var thirst_restore: float = 0
@export var sleep_restore: float = 0
@export var stamina_restore: float = 0
@export var health_restore: float = 0
@export var removes_poison: bool = false
@export var causes_hallucination: bool = false

enum EffectType {
	HUNGER,
	THIRST,
	SLEEP,
	STAMINA,
	HEALTH,
	REMOVE_POISON,
	HALLUCINATION
}
