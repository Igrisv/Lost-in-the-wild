extends Node

var recipe_list: Array = []

func _ready():
	# Puedes cargar recetas desde archivos
	recipe_list = [
		#preload("res://Systems/Crafteo/Recetas/rosa.tres"),
	]

func get_available_recipes() -> Array:
	return recipe_list

func can_craft(recipe: Recipe) -> bool:
	for item in recipe.ingredients.keys():
		var required_amount = recipe.ingredients[item]
		var has_enough = Inventory.count_item(item) >= required_amount
		if not has_enough:
			return false
	return true

func craft(recipe: Recipe):
	if not can_craft(recipe):
		return

	for item in recipe.ingredients.keys():
		var amt = recipe.ingredients[item]
		Inventory.use_stackable_item(item, amt)

	Inventory.add_item(recipe.result)
