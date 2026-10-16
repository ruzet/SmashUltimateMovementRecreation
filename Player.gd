extends CharacterBody2D

const Speed = 600
const AirSpeed = 450
const Acceleration = 7
const AirAcceleration = 3
const Deceleration = 4
const AirDeceleration = 2
const JumpPower = -750
const ShortJumpPower = -450
const DoubleJumpPower = -600
const FallingSpeed = 500
const FastFallingSpeed = 800
const Gravity = 1750
const Jumps = 2

const DashTime = 0.4
const DashDistance = 275
const AirDodgeXVelocity = 500 #this is set every frame so make it lower when fine turning
const AirDodgeYVelocity = -700

var XVelocity = 0
var YVelocity = 0
var CurrentJumps = 2
var TimeInAir = 0
var DashSpeed = 0
var DashDecel = 0
var DashDirection = 0
var DashFloorNormal = Vector2.UP
var DashTangent = Vector2.RIGHT
var OnGround = false
var Dodging = false
var AirDodging = false
var JumpDebounce = false
var ResetJumpDebounce = false
var DodgeDebounce = false

func ResetJumpDebounceFunction():
	ResetJumpDebounce = true
	await get_tree().create_timer(0.05).timeout
	ResetJumpDebounce = false

func Dash(ParamDashDirection):
	DashFloorNormal = get_floor_normal()
	DashDirection = sign(ParamDashDirection)
	DashTangent = Vector2(-DashFloorNormal.y, DashFloorNormal.x) * DashDirection
	$"ColorRect".color = Color.from_rgba8(115, 184, 255)
	Dodging = true
	DashSpeed = 2 * DashDistance / DashTime
	DashDecel = DashSpeed / DashTime
	await get_tree().create_timer(DashTime).timeout
	$"ColorRect".color = Color.from_rgba8(23, 151, 255)
	Dodging = false

func AirDodge():
	var VectorDirection = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_down", "ui_up")).normalized()
	AirDodging = true
	$"ColorRect".color = Color.from_rgba8(115, 184, 255)
	$"ColorRect".rotation_degrees = 45
	if VectorDirection.x != 0: XVelocity = AirDodgeXVelocity * VectorDirection.x
	if VectorDirection.y != 0: YVelocity = AirDodgeYVelocity * VectorDirection.y
	await get_tree().create_timer(0.5).timeout
	$"ColorRect".rotation_degrees = 0
	$"ColorRect".color = Color.from_rgba8(23, 151, 255) 
	AirDodging = false

func Raycast():
	var SpaceState = get_world_2d().direct_space_state
	var Radius = $"CollisionShape2D".shape.radius
	var HalfOfPlayer = Radius / 2
	var Forward = DashTangent
	var Down = -DashFloorNormal
	var RightEdge = self.global_position + Forward * HalfOfPlayer
	var CheckedPosition1 = RightEdge + Forward * 0.1
	var CheckedPosition2 = RightEdge + Down * (Radius + 2)
	var Ray3Start = self.global_position + Forward * (HalfOfPlayer + 4)
	var CheckedPosition3 = Ray3Start + Down * (Radius * 1.5)
	var Query1 = PhysicsRayQueryParameters2D.create(RightEdge, CheckedPosition1)
	var Query2 = PhysicsRayQueryParameters2D.create(RightEdge, CheckedPosition2)
	var Query3 = PhysicsRayQueryParameters2D.create(Ray3Start, CheckedPosition3)
	Query1.exclude = [get_rid()]
	Query2.exclude = [get_rid()]
	Query3.exclude = [get_rid()]
	var Result1 = SpaceState.intersect_ray(Query1)
	var Result2 = SpaceState.intersect_ray(Query2)
	var Result3 = SpaceState.intersect_ray(Query3)

	if Result1:
		return "Stop"
	elif !Result2:
		return "Stop"
	elif Result3:
		if abs(Result3.normal.angle_to(DashFloorNormal)) > 0.05:
			return "Stop"
	else:
		return


func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	var Direction = Input.get_axis("ui_left", "ui_right")
	if event.is_action_pressed("Jump") && CurrentJumps != 0 && !JumpDebounce && !Dodging && !AirDodging:
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
	elif event.is_action_pressed("Dodge") && !DodgeDebounce:
		if OnGround:
			if Direction != 0: Dash(Direction)
		else:
			AirDodge()

func _physics_process(delta: float) -> void:
	var Direction = Input.get_axis("ui_left", "ui_right")
	OnGround = self.is_on_floor()

	if !Dodging:
		if OnGround == true:
			if AirDodging:
				AirDodging = false
				$"ColorRect".rotation_degrees = 0
				$"ColorRect".color = Color.from_rgba8(23, 151, 255) 
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

			if Direction == 0 && !AirDodging:
				XVelocity = 0 + (XVelocity - 0) * exp(-Deceleration * delta)
			elif !AirDodging:
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
			if Direction == 0 && !AirDodging:
				XVelocity = 0 + (XVelocity - 0) * exp(-AirDeceleration * delta)
			elif !AirDodging:
				var TargetXVelocity = Direction * Speed
				XVelocity = TargetXVelocity + (XVelocity - TargetXVelocity) * exp(-AirAcceleration * delta)
			if Input.get_axis("ui_down", "ui_up") == -1 && TimeInAir > 0.5 && !AirDodging:
				YVelocity = FastFallingSpeed
			else:
				if YVelocity > FallingSpeed:
					YVelocity = FallingSpeed
				else:
					YVelocity += Gravity * delta
	else:
		var NextDashSpeed = max(DashSpeed - DashDecel * delta, 0)
		var Result = Raycast()

		if Result == "Stop":
			XVelocity = 0
			YVelocity = 0
			DashSpeed = 0
		else:
			var DashVelocity = DashTangent * (DashSpeed + NextDashSpeed) * 0.5
			XVelocity = DashVelocity.x
			YVelocity = DashVelocity.y
			DashSpeed = NextDashSpeed
	self.velocity = Vector2(XVelocity, YVelocity)
	move_and_slide()