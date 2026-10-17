extends Camera2D

const FollowSpeed = 4

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	var Player = self.get_parent().find_child("Player")
	self.position = Player.position + (self.position - Player.position) * exp(-FollowSpeed * delta)
	pass
