extends CharacterBody2D

const Speed = 600
const AirSpeed = 450
const Acceleration = 7
const AirAcceleration = 3
const Deceleration = 4
const AirDeceleration = 2
const JumpPower = -750
const Gravity = 1500
const Jumps = 2

var XVelocity = 0
var YVelocity = 0
var OnGround = false
var CurrentJumps = 0

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Jump") && OnGround:
		YVelocity = JumpPower

func _physics_process(delta: float) -> void:
	var Direction = Input.get_axis("ui_left", "ui_right")
	OnGround = self.is_on_floor()

	if OnGround == true:
		if Direction == 0:
			XVelocity = 0 + (XVelocity - 0) * exp(-Deceleration * delta)
		else:
			var TargetXVelocity = Direction * Speed
			XVelocity = TargetXVelocity + (XVelocity - TargetXVelocity) * exp(-Acceleration * delta)
	else:
		if Direction == 0:
			XVelocity = 0 + (XVelocity - 0) * exp(-AirDeceleration * delta)
		else:
			var TargetXVelocity = Direction * Speed
			XVelocity = TargetXVelocity + (XVelocity - TargetXVelocity) * exp(-AirAcceleration * delta)
		YVelocity += Gravity * delta

	self.velocity = Vector2(XVelocity, YVelocity)
	move_and_slide()
