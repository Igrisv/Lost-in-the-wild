extends Resource
class_name ConsumableData

@export var effects: Array[Effect] = []

enum EffectType {
	Hunger,
	Thirst,
	Sleep,
	Stamina,
	Health,
}
