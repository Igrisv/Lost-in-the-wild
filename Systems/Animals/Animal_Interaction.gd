class_name AnimalInteraction
extends Resource

# Enum para especies disponibles
enum Species { NONE, HUMAN, CONEJO, CIERVO, OSO, LEON , LOBO}

@export var target_species: Array[Species] = []  # Lista de especies objetivo (ej. [Species.CONEJO, Species.CIERVO])
@export_enum("Atacar", "Huir", "Ignorar", "Seguir") var interaction_type: String = "Ignorar"
@export var interaction_range: float = 100.0  # Rango para activar la interacción
@export_range(0.0, 1.0, 0.1) var priority: float = 0.5  # Prioridad de la interacción
