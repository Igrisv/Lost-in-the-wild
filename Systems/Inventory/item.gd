extends Resource
class_name Item

@export var max_stack: int
@export var id: String
@export var name: String
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var consumable_data: ConsumableData
@export var is_equippable: bool = false  # Nuevo: Indica si el ítem es equipable
@export var equipment_slot: String = ""  # Nuevo: Slot donde se equipa (ej. "Hand", "Head", "Body")
@export var durability : int
@export var protection : int  # Protección mínima
@export var comfort : int
@export var mobility : int

enum ItemType {
	CONSUMABLE,
	TOOL,
	WEAPON,
	PLACEABLE,
}
