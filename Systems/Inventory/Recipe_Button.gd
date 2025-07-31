extends VBoxContainer

@onready var recipe_list_container = $RecipeList

func _ready() -> void:
	populate_recipes()

func populate_recipes():
	clear_container(recipe_list_container)

	for recipe in CraftingManager.recipe_list:
		var button = Button.new()
		button.text = recipe.result.name
		button.disabled = false#button.disabled = not CraftingManager.can_craft(recipe)
		button.pressed.connect(func():
			try_craft(recipe)
		)
		recipe_list_container.add_child(button)
		
		
func try_craft(recipe: Recipe):
	if CraftingManager.can_craft(recipe):
		CraftingManager.craft(recipe)
		populate_recipes() # refresca los botones
		show_feedback("¡Has creado: " + recipe.result.name + "!")
	else:
		show_feedback("No tienes los materiales necesarios.")

func show_feedback(text: String):
	var label = $FeedbackLabel
	label.text = text
	label.show()
	await get_tree().create_timer(2.0).timeout
	label.hide()

func clear_container(container: Node):
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
