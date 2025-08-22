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

# Sección especializada para herramientas (item_type == TOOL): variables de recolección
@export var min_yield: int = 1  # Mínimo de loot por golpe/extracción exitosa
@export var max_yield: int = 5  # Máximo de loot por golpe/extracción exitosa
@export var resource_damage: float = 10.0  # Daño base causado al recurso (ej. vida del árbol)
@export var critical_chance: float = 0.1  # Probabilidad (0-1) de golpe crítico para yield extra
@export var yield_per_damage: float = 0.5  # Multiplicador de loot por unidad de daño causado

# Sección especializada para armas (item_type == WEAPON): variables de combate
@export var damage_base: float = 10.0  # Daño base del arma
@export var attack_range: float = 150.0  # Rango de ataque (para melee o proyectil inicial)
@export var is_ranged: bool = false  # Si es true, el arma es a distancia (lanza proyectil)
@export var projectile_speed: float = 400.0
@export var projectile_scene: PackedScene = null  # Escena del proyectil para armas ranged (ej. flecha, bala)
@export var attack_speed: float = 1.0  # Velocidad de ataque (modificador para tiempo de ejecución)

# Sección para munición y recarga en armas ranged
@export var needs_ammo: bool = false  # Si true, el arma requiere munición para disparar
@export var ammo_type: String = ""  # ID del ítem de munición requerido (ej. "arrow")
@export var reload_time: float = 2.0  # Tiempo en segundos para recargar/simular carga antes de disparar

enum ItemType {
	CONSUMABLE,
	TOOL,
	WEAPON,
	PLACEABLE,
}
