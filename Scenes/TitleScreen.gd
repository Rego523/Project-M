extends Control



func _on_jugar_pressed():
	get_tree().change_scene_to_file("res://Scenes/save_selection_screen.tscn")


func _on_opciones_pressed():
	pass # Replace with function body.


func _on_creditos_pressed():
	pass # Replace with function body.


func _on_salir_del_juego_pressed():
	get_tree().quit()
