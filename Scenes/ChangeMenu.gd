extends Control

@onready var vBox = $VBoxContainer
@onready var Panel1 = $VBoxContainer/PanelContainer1
@onready var Panel2 = $VBoxContainer/PanelContainer2
@onready var Panel3 = $VBoxContainer/PanelContainer3

@onready var paneles = [Panel1, Panel2, Panel3]
@onready var centro = 0


func _ready():
	actualizar_posicion()

func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("ChangeLeftCharacter"):
			centro = (centro + 1) % 3
			
			paneles[centro].z_index = 1
			paneles[(centro + 1) % 3].z_index = 1
			paneles[(centro + 2) % 3].z_index = 0
			
			
			actualizar_posicion()
		elif event.is_action_pressed("ChangeRightCharacter"):
			centro = (centro - 1 + 3) % 3  # Añadir 3 antes del módulo para evitar números negativos
			
			paneles[centro].z_index = 0
			paneles[(centro + 1) % 3].z_index = 1
			paneles[(centro + 2) % 3].z_index = 1
			
			actualizar_posicion()

func actualizar_posicion():
	var tween = get_tree().create_tween().set_parallel(true)
	
	tween.tween_property(paneles[centro], "position:y", 0, 0.2)
	
	tween.tween_property(paneles[(centro + 1) % 3], "position:y", 13, 0.2)
	
	tween.tween_property(paneles[(centro + 2) % 3], "position:y", 26, 0.2)
	
	#actualizar_tamaño()

func actualizar_tamaño():
	# Ajustar los flags de expansión y relleno
	for i in range(3):
		if i == centro:
			paneles[i].size_flags_horizontal = Control.SIZE_EXPAND_FILL
			paneles[i].size_flags_vertical = Control.SIZE_EXPAND_FILL
		else:
			paneles[i].size_flags_horizontal = Control.SIZE_SHRINK_END
			paneles[i].size_flags_vertical = Control.SIZE_SHRINK_END
