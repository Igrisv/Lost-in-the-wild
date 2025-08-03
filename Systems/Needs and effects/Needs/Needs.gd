extends Node
class_name Needs

enum EffectType {
	HUNGER,
	THIRST,
	SLEEP,
	STAMINA,
	POISON,
	CURE_POISON
}

var hunger: float = 100.0
var thirst: float = 100.0
var sleep: float = 100.0
var stamina: float = 100.0

func modify_need(need_name: String, amount: float) -> void:
	match need_name:
		"hunger":
			hunger = clamp(hunger + amount, 0, 100)
		"thirst":
			thirst = clamp(thirst + amount, 0, 100)
		"sleep":
			sleep = clamp(sleep + amount, 0, 100)
		"stamina":
			stamina = clamp(stamina + amount, 0, 100)
