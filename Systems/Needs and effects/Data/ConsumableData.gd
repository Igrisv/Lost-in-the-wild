extends Resource
class_name ConsumableData

@export var effects: Array[Effect] = []

enum EffectType {
	HUNGER,
	THIRST,
	SLEEP,
	STAMINA,
	HEALTH,
	REMOVE_POISON,
	HALLUCINATION
}
