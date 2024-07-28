extends Node

@onready var player1: CharacterBody3D = $Player1
@onready var player2: CharacterBody3D = $Player2
@onready var player3: CharacterBody3D = $Player3

@onready var players = [player1, player2, player3]
@onready var leader = 0


func _ready():
	set_roles(player1, player2, player3)

func _input(event):
	if event.is_action_pressed("ChangeLeftCharacter"):
		leader = (leader + 1) % 3
		set_roles(players[leader], players[(leader + 1) % 3], players[(leader + 2) % 3])
		
	elif event.is_action_pressed("ChangeRightCharacter"):
		leader = (leader - 1 + 3) % 3
		set_roles(players[leader], players[(leader + 1) % 3], players[(leader + 2) % 3])

func set_roles(new_leader: CharacterBody3D, follower1: CharacterBody3D, follower2: CharacterBody3D):
	new_leader._set_rol(true, false, false, new_leader)
	follower1._set_rol(false, true, false, new_leader)
	follower2._set_rol(false, false, true, new_leader)
