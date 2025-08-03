# systems/status_effects.gd
extends Node
class_name StatusEffects

enum EffectType { POISON, DRUNK, SPEED_BOOST }

var active_effects: Dictionary = {}

func has_effect(effect_type: EffectType) -> bool:
	return effect_type in active_effects

func apply_effect(effect_type: EffectType, duration: float, intensity: float = 1.0):
	active_effects[effect_type] = {
		"duration": duration,
		"intensity": intensity,
		"timer": duration
	}

func _process(delta):
	for effect_type in active_effects.keys():
		active_effects[effect_type]["timer"] -= delta
		if active_effects[effect_type]["timer"] <= 0:
			active_effects.erase(effect_type)
