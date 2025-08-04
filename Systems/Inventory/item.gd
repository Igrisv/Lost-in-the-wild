# item.gd
class_name Item
extends Resource

@export var max_stack: int
@export var id: String
@export var name: String
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var consumable_data: ConsumableData
@export var is_equippable: bool = false
@export var equipment_slot: String = ""
@export var durability: int = 100
@export var protection: int = 0
@export var comfort: int = 0
@export var mobility: int = 0
@export var efficiency: float = 1.0 # Nueva: eficiencia de la herramienta
@export var modifiers: Dictionary = {} # Nueva: bonificaciones, ej.: {"stamina_cost": 0.8, "extra_yield": 1}
@export var animation_override: String = "" # Nueva: animación específica
@export var sound_override: AudioStream = null # Nueva: sonido específico

enum ItemType {
	CONSUMABLE,
	TOOL,
	WEAPON,
	PLACEABLE,
}
