class_name Outcome
extends Resource

@export var outcome_type: int = OutcomeType.ADD_ITEM

@export var type: String # Ej.: "add_item", "damage_tool"
@export var target: String # Ej.: "inventory", "tool"
@export var value: Array # Ej.: ["wood", 5] o 1 (para daño a herramienta)
enum OutcomeType { ADD_ITEM, DAMAGE_TOOL, MODIFY_STAT, APPLY_EFFECT }
