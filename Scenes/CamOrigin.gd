extends Node3D

@onready var player1: CharacterBody3D = $"../Player1"
@onready var player2: CharacterBody3D = $"../Player2"
@onready var player3: CharacterBody3D = $"../Player3"

@onready var players = [player1, player2, player3]
@onready var leader = 0
@onready var target: CharacterBody3D = players[leader]
@onready var origin: Vector3 = target.global_transform.origin

@onready var pivot: Node3D = $"."
@onready var spring_arm = $SpringArm3D
@onready var camera = $SpringArm3D/Camera3D

var mouse_sensitivity: float = 0.5
var min_distance: float = 5.0
var max_distance: float = 20.0
var zoom_speed: float = 200.0

var transitioning: bool = false
var transition_time: float = 0.5
var transition_timer: float = 0.0
var control_point: Vector3

func _ready():
	# Hide mouse.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Assign SpringArm3D at the start.
	spring_arm.spring_length = 15.0
	spring_arm.add_excluded_object($"../Player1")
	spring_arm.add_excluded_object($"../Player2")
	spring_arm.add_excluded_object($"../Player3")
	pivot.global_transform.origin = target.global_transform.origin

func _input(event):
	# Camera Rotation.
	if event is InputEventMouseMotion:
		pivot.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		pivot.rotation.x -= deg_to_rad(event.relative.y * mouse_sensitivity)
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-90), deg_to_rad(45))

	# Camera Zoom.
	if event is InputEventMouseButton:
		if event.is_action_pressed("ZoomIn", true):
			var target_length = spring_arm.spring_length - zoom_speed
			spring_arm.spring_length = lerp(spring_arm.spring_length, target_length, 0.005)
		if event.is_action_pressed("ZoomOut", true):
			var target_length = spring_arm.spring_length + zoom_speed
			spring_arm.spring_length = lerp(spring_arm.spring_length, target_length, 0.005)
		
		spring_arm.spring_length = clamp(spring_arm.spring_length, min_distance, max_distance)

	# Camara focus on a player.
	if event.is_action_pressed("ChangeLeftCharacter"):
		origin = pivot.global_transform.origin
		leader = (leader + 1) % 3
		target = players[leader]
		transitioning = true
		transition_timer = 0.0
		control_point = (origin + target.global_transform.origin) / 2 + Vector3(0, 5, 0)  # Ajustar altura según sea necesario
	elif event.is_action_pressed("ChangeRightCharacter"):
		origin = pivot.global_transform.origin
		leader = (leader - 1 + 3) % 3
		target = players[leader]
		transitioning = true
		transition_timer = 0.0
		control_point = (origin + target.global_transform.origin) / 2 + Vector3(0, 5, 0)  # Ajustar altura según sea necesario

func _process(delta):
	if transitioning:
		transition_timer += delta
		var t = transition_timer / transition_time
		if t >= 1.0:
			t = 1.0
			transitioning = false

		# Interpolate position along a quadratic Bezier curve
		pivot.global_transform.origin = _quadratic_bezier(origin, control_point, target.global_transform.origin, t)
	else:
		pivot.global_transform.origin = target.global_transform.origin

func _quadratic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: float) -> Vector3:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	return q0.lerp(q1, t)
