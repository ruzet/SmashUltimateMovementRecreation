extends CharacterBody2D

const Speed = 600
const AirSpeed = 450
const Acceleration = 7
const AirAcceleration = 3
const Deceleration = 4
const AirDeceleration = 2
const JumpPower = -750
const ShortJumpPower = -450
const DoubleJumpPower = -400
const FallingSpeed = 500
const FastFallingSpeed = 800
const Gravity = 1750
const Jumps = 2

var XVelocity = 0
var YVelocity = 0
var CurrentJumps = 2
var TimeInAir = 0
var OnGround = false
var JumpDebounce = false
var ResetJumpDebounce = false

func ResetJumpDebounceFunction():
	ResetJumpDebounce = true
	await get_tree().create_timer(0.05).timeout
	ResetJumpDebounce = false

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Jump") && CurrentJumps != 0 && !JumpDebounce:
		if CurrentJumps == Jumps:
			YVelocity = JumpPower
		else:
			YVelocity = DoubleJumpPower
		CurrentJumps -= 1
		JumpDebounce = true
		await get_tree().create_timer(0.05).timeout
		JumpDebounce = false
		if !OnGround && Input.get_axis("ui_down", "ui_up") != 1:
			YVelocity = ShortJumpPower

func _physics_process(delta: float) -> void:
	var Direction = Input.get_axis("ui_left", "ui_right")
	OnGround = self.is_on_floor()

	if OnGround == true:
		var TargetXVelocity = Direction * Speed
		if get_floor_angle() < floor_max_angle: self.rotation = get_floor_angle()
		TimeInAir = 0
		if !ResetJumpDebounce:
			CurrentJumps = Jumps
			ResetJumpDebounceFunction()

		var UnrotatedXVelocity = TargetXVelocity
		TargetXVelocity = UnrotatedXVelocity * -get_floor_normal().y
		var SpeedMultiplier = (Direction * Speed) / TargetXVelocity
		if TargetXVelocity == 0: SpeedMultiplier = 1
		TargetXVelocity *= SpeedMultiplier

		if Direction == 0:
			XVelocity = 0 + (XVelocity - 0) * exp(-Deceleration * delta)
		else:
			XVelocity = TargetXVelocity + (XVelocity - TargetXVelocity) * exp(-Acceleration * delta)

		if UnrotatedXVelocity > 0 && self.rotation < self.floor_max_angle:
			YVelocity = (UnrotatedXVelocity * (get_floor_normal().x * Direction)) * SpeedMultiplier
		else:
			if !JumpDebounce:
				if Direction == 0:
					YVelocity = 0 + (YVelocity - 0) * exp(-Deceleration * delta)
	else:
		self.rotation_degrees = 0
		TimeInAir += delta
		if CurrentJumps == Jumps: CurrentJumps -= 1
		if Direction == 0:
			XVelocity = 0 + (XVelocity - 0) * exp(-AirDeceleration * delta)
		else:
			var TargetXVelocity = Direction * Speed
			XVelocity = TargetXVelocity + (XVelocity - TargetXVelocity) * exp(-AirAcceleration * delta)
		if Input.get_axis("ui_down", "ui_up") == -1 && TimeInAir > 0.5:
			YVelocity = FastFallingSpeed
		else:
			if YVelocity > FallingSpeed:
				YVelocity = FallingSpeed
			else:
				YVelocity += Gravity * delta

	self.velocity = Vector2(XVelocity, YVelocity)
	move_and_slide()