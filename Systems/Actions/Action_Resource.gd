# action_resource.gd
class_name ActionResource
extends Resource

@export var action_id: String # Ej.: "chop_tree"
@export var display_name: String # Ej.: "Cortar árbol"
@export var required_tool_type: String # Ej.: "axe" (coincide con Item.id o una nueva propiedad)
@export var base_stamina_cost: float # Ej.: 10.0
@export var base_execution_time: float # Ej.: 2.0
@export var animation: String # Ej.: "chop"
@export var sound: AudioStream
@export var outcomes: Array[Outcome] # Efectos de la acción
