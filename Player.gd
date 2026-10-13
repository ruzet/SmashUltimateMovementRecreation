extends CharacterBody2D

const Speed = 30
const Acceleration = 10
const JumpPower = 50

var XVelocity = 0
var YVelocity = 0
var Gravity = 100
var Friction = 100
var AirFriction = 100

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	var Direction = Input.get_axis("ui_left", "ui_right")
	var OnGround = self.is_on_floor()

	if Direction == 0:
		pass
	else:
		var TargetXVelocity = Direction * Speed
		XVelocity = TargetXVelocity + (XVelocity - TargetXVelocity) * exp(-Acceleration * delta)

	if OnGround == true:
		XVelocity -= Friction * delta
		YVelocity = 0
	else:
		YVelocity -= Gravity * delta

	self.velocity = Vector2(XVelocity, -YVelocity)
	move_and_slide()
