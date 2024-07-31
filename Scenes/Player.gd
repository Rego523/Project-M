extends CharacterBody3D

@onready var leader : bool
@onready var follower1 : bool
@onready var follower2 : bool

@onready var pivot = $"../CamOrigin"
@onready var model = $BodyMesh

@onready var leftReferece = $LeftReference
@onready var rightReferece = $RightReference
@onready var is_follower_stop : bool = true
@onready var is_leader_stop : bool = true
@onready var target_position

@export var rotation_speed = 20.0

@export var speed = 10.0
@export var acceleration = 20.0
@export var deceleration = 10.0

@export var jump_speed = 8.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

####################################################################################################

@onready var navigation_agent: NavigationAgent3D = get_node("NavigationAgent3D")

@onready var target_character: CharacterBody3D
@onready var new_velocity: Vector3
@export var min_distance_to_leader: float = 15.0

var map_synced: bool = false

func _ready():
	# Esperar un fotograma antes de marcar el mapa como sincronizado
	await get_tree().process_frame
	map_synced = true

####################################################################################################

func _set_rol(is_leader, is_follower1, is_follower2, target):
	leader = is_leader
	follower1 = is_follower1
	follower2 = is_follower2

	if is_follower1 or is_follower2:
		target_character = target

####################################################################################################

func _physics_process(delta):
	if leader:
		# Gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta

		# Jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump_speed

		# Quit Game.
		if Input.is_action_just_pressed("Quit"):
			get_tree().quit()

		# Player movement while moving the camera.
		var vy = velocity.y
		velocity.y = 0
		var input = Input.get_vector("Left", "Right", "Up", "Down")
		var dir = Vector3(input.x, 0, input.y).rotated(Vector3.UP, pivot.rotation.y)

		# Aplicar aceleración y desaceleración
		if dir.length() > 0:
			velocity = velocity.lerp(dir * speed, acceleration * delta)
			is_leader_stop = false
		else:
			velocity = velocity.lerp(Vector3.ZERO, deceleration * delta)
			is_leader_stop = true
		velocity.y = vy

		move_and_slide()

		# Model rotation while player is in movement.
		if velocity.length() > 1.0:
			# Ignore the y component for rotation
			var horizontal_velocity = Vector3(velocity.x, 0, velocity.z).normalized()
			var corrected_rotation = atan2(horizontal_velocity.x, horizontal_velocity.z)
			model.rotation.y = lerp_angle(model.rotation.y, corrected_rotation - PI / 2, rotation_speed * delta)
			
			# Puedes comentar estas dos lineas por optimacion si quieres, se encargan de rotar los puntos de referencia.
			leftReferece.rotation.y = lerp_angle(leftReferece.rotation.y, corrected_rotation - PI / 2, rotation_speed * delta)
			rightReferece.rotation.y = lerp_angle(rightReferece.rotation.y, corrected_rotation - PI / 2, rotation_speed * delta)
			
			# Calcular las nuevas posiciones de las referencias izquierda y derecha
			var distance_from_model_x = 2.0  # Distancia desde el modelo a las referencias
			var distance_from_model_z = 3.0
			var left_position = model.global_position - model.transform.basis.x * distance_from_model_x - model.transform.basis.z * distance_from_model_z
			var right_position = model.global_position - model.transform.basis.x * distance_from_model_x + model.transform.basis.z * distance_from_model_z

			# Interpolar las posiciones actuales hacia las nuevas posiciones
			leftReferece.global_position = leftReferece.global_position.lerp(left_position, speed * delta)
			rightReferece.global_position = rightReferece.global_position.lerp(right_position, speed * delta)

	elif follower1 or follower2:
		if not map_synced:
			return # Esperar hasta que el mapa esté sincronizado
		
		if follower1:
			target_position = target_character.leftReferece.global_position # Izquierda
		elif follower2:
			target_position = target_character.rightReferece.global_position # Derecha
		
		
		var distance_to_target = global_position.distance_to(target_position)
		var distance_to_leader = global_position.distance_to(target_character.global_position)
		
		# Arrancar
		if is_follower_stop && distance_to_leader > min_distance_to_leader:
			set_movement_target(target_position)
			is_follower_stop = false
		# Seguir corriendo
		elif not is_follower_stop && distance_to_target > 0.8:
			set_movement_target(target_position)
		# Parar
		elif target_character.is_leader_stop == true:
			navigation_agent.set_target_position(global_position)
			is_follower_stop = true
		
		if navigation_agent.is_navigation_finished():
			return
		
		var next_path_position: Vector3 = navigation_agent.get_next_path_position()
		var current_agent_position: Vector3 = global_position
		
		if distance_to_target > 1.2:
			new_velocity  = (next_path_position - current_agent_position).normalized() * 15
		else:
			new_velocity= (next_path_position - current_agent_position).normalized() * 10
			
		if navigation_agent.avoidance_enabled:
			navigation_agent.set_velocity(new_velocity)
		else:
			_on_velocity_computed(new_velocity)
		
		# Girar el modelo para mirar al personaje objetivo si estamos lo suficientemente lejos.
		if distance_to_leader < min_distance_to_leader:
			var direction_to_target = (target_position - global_position).normalized()
			var target_rotation = atan2(direction_to_target.x, direction_to_target.z)
			model.rotation.y = target_rotation - PI / 2

####################################################################################################

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)

func _on_velocity_computed(safe_velocity: Vector3):
	velocity = safe_velocity
	move_and_slide()
