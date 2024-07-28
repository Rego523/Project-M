extends CharacterBody3D

@onready var leader : bool
@onready var follower1 : bool
@onready var follower2 : bool

@onready var pivot = $"../CamOrigin"
@onready var model = $BodyMesh

@export var rotation_speed = 20.0

@export var speed = 10.0
@export var acceleration = 20.0
@export var deceleration = 10.0

@export var jump_speed = 8.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

####################################################################################################

@onready var navigation_agent: NavigationAgent3D = get_node("NavigationAgent3D")

@onready var target_character: CharacterBody3D
@export var movement_speed: float = 10.0
@export var min_distance_to_target: float = 2.0

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
		else:
			velocity = velocity.lerp(Vector3.ZERO, deceleration * delta)
		velocity.y = vy

		move_and_slide()

		# Model rotation while player is in movement.
		if velocity.length() > 1.0:
			# Ignore the y component for rotation
			var horizontal_velocity = Vector3(velocity.x, 0, velocity.z).normalized()
			var corrected_rotation = atan2(horizontal_velocity.x, horizontal_velocity.z)
			model.rotation.y = lerp_angle(model.rotation.y, corrected_rotation - PI / 2, rotation_speed * delta)

	elif follower1 or follower2:
		if not map_synced:
			return # Esperar hasta que el mapa esté sincronizado
		
		# Posición del objetivo (líder)
		var target_position = target_character.global_position
		# Distancia lateral desde el líder
		var offset_distance = 3.0
		
		if follower1:
			target_position -= target_character.transform.basis.x * offset_distance # Izquierda
		elif follower2:
			target_position += target_character.transform.basis.x * offset_distance # Derecha
		
		# Verificar si la distancia al objetivo es mayor que la distancia mínima.
		var distance_to_target = global_position.distance_to(target_position)
		
		if distance_to_target > min_distance_to_target:
			set_movement_target(target_position)
		else:
			# Si estamos demasiado cerca, detenemos el agente.
			navigation_agent.set_target_position(global_position)
		
		if navigation_agent.is_navigation_finished():
			return
		
		var next_path_position: Vector3 = navigation_agent.get_next_path_position()
		var current_agent_position: Vector3 = global_position
		var new_velocity: Vector3 = (next_path_position - current_agent_position).normalized() * movement_speed
		
		if navigation_agent.avoidance_enabled:
			navigation_agent.set_velocity(new_velocity)
		else:
			_on_velocity_computed(new_velocity)
		
		# Girar el modelo para mirar al personaje objetivo si estamos lo suficientemente lejos.
		if distance_to_target > min_distance_to_target:
			var direction_to_target = (target_position - global_position).normalized()
			var target_rotation = atan2(direction_to_target.x, direction_to_target.z)
			model.rotation.y = target_rotation - PI / 2

####################################################################################################

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)

func _on_velocity_computed(safe_velocity: Vector3):
	velocity = safe_velocity
	move_and_slide()
