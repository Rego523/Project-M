extends Control



func _on_back_to_title_screen_pressed():
	get_tree().change_scene_to_file("res://Scenes/TitleScreen.tscn")




func _on_save_1_pressed():
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")
