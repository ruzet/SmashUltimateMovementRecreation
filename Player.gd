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

const DashTime = 0.5
const DashDistance = 300
const AirDodgeXVelocity = 650 #this is set every frame so make it lower when fine turning
const AirDodgeYVelocity = -700

@export var OverallSpeedMultiplier = 1
@export var OverallJumpMultiplier = 1
@export var OverallFallingSpeedMultiplier = 1
@export var OverallGravityMultiplier = 1
@export var OverallAirDodgeMultiplier = 1
@export var OverallKnockbackMultiplier = 1
@export var OverallHitstunMultiplier = 1
@export var OverallHitlagMultiplier = 1

@export var Angle = 45
@export var Damage = 8
@export var Weight = 100
@export var KnockbackScaling = 1
@export var BaseKnockback = 80
@export var UnitMultiplier = 1
@export var Percent = 0.0

var KBLaunchScale = 0.03 * 60.0 * 3.0
var KBDecayPerSecond = 0.051 * 3600.0 * 4.0
var KBHitstunGravity = Gravity * 0.8

var XVelocity = 0
var YVelocity = 0
var CurrentJumps = 2
var TimeInAir = 0
var DashSpeed = 0
var DashDecel = 0
var DashDirection = 0
var HitstunTimer = 0
var HitlagTimer = 0
var StartingHitlagTimer = 0
var ShakeOffset = 0
var ShakeDirection = 1
var KnockbackVelocity = Vector2.ZERO
var DashFloorNormal = Vector2.UP
var DashTangent = Vector2.RIGHT
var OnGround = false
var Dodging = false
var AirDodging = false
var JumpDebounce = false
var ResetJumpDebounce = false
var DodgeDebounce = false
var IsJumping = false
var Hitlag = false
var Hitstun = false
var WasHitstun = false

func ResetJumpDebounceFunction():
	ResetJumpDebounce = true
	await get_tree().create_timer(0.05).timeout
	ResetJumpDebounce = false

func ProcessHitlag():
	var HitlagFrames = floor((Damage * 0.65 + 6) * OverallHitlagMultiplier)
	StartingHitlagTimer = HitlagFrames / 60
	HitlagTimer = StartingHitlagTimer
	Hitlag = true

func ProcessKnockback():
	var KnockbackUnits = ((((((Percent / 10.0) + ((Percent * Damage) / 20.0)) * (200.0 / (Weight + 100)) * 1.4) + 18) * KnockbackScaling) + BaseKnockback) * UnitMultiplier
	Dodging = false
	AirDodging = false
	$"ColorRect".rotation_degrees = 0
	$"ColorRect".color = Color.from_rgba8(236, 86, 140)
	var Dir = Vector2(cos(deg_to_rad(Angle)), -sin(deg_to_rad(Angle)))
	KnockbackVelocity = Dir * KnockbackUnits * KBLaunchScale
	HitstunTimer = (floor(KnockbackUnits * 0.4) - 1) / 60.0
	Hitstun = true
	XVelocity = 0
	YVelocity = 0

func Attack():
	Percent += Damage
	ProcessKnockback()
	ProcessHitlag()

func UpdateValues():
	KBLaunchScale = 0.03 * 60.0 * 3.0 * OverallKnockbackMultiplier
	KBDecayPerSecond = 0.051 * 3600.0 * 4.0 * OverallKnockbackMultiplier
	KBHitstunGravity = Gravity * OverallGravityMultiplier * 0.8 * OverallKnockbackMultiplier

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
	if VectorDirection.x != 0: XVelocity = AirDodgeXVelocity * OverallAirDodgeMultiplier * VectorDirection.x
	if VectorDirection.y != 0: YVelocity = AirDodgeYVelocity * OverallAirDodgeMultiplier * VectorDirection.y
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

func _input(event: InputEvent) -> void:
	UpdateValues()
	var Direction = Input.get_axis("ui_left", "ui_right")
	if event.is_action_pressed("Jump"):
		IsJumping = true
	elif event.is_action_released("Jump"):
		IsJumping = false

	if event.is_action_pressed("Jump") && CurrentJumps != 0 && !JumpDebounce && !Dodging && !AirDodging:
		if CurrentJumps == Jumps:
			YVelocity = JumpPower * OverallJumpMultiplier
		else:
			YVelocity = DoubleJumpPower * OverallJumpMultiplier
		CurrentJumps -= 1
		JumpDebounce = true
		await get_tree().create_timer(0.15).timeout
		JumpDebounce = false
		if !OnGround && IsJumping == false && YVelocity < ShortJumpPower * OverallJumpMultiplier:
			YVelocity = ShortJumpPower * OverallJumpMultiplier
	elif event.is_action_pressed("Dodge") && !DodgeDebounce:
		if OnGround:
			if Direction != 0: Dash(Direction)
		else:
			AirDodge()
	elif event.is_action_pressed("Knockback"):
		Attack()
	elif event.is_action_pressed("Reset"):
		KnockbackVelocity = Vector2.ZERO
		DashFloorNormal = Vector2.UP
		DashTangent = Vector2.RIGHT
		Percent = 0
		XVelocity = 0
		YVelocity = 0
		HitlagTimer = 0
		HitstunTimer = 0
		Hitlag = false
		Hitstun = false
		AirDodging = false
		self.velocity = Vector2.ZERO
		self.position = Vector2(935.0, 400)

func _physics_process(delta: float) -> void:
	var Direction = Input.get_axis("ui_left", "ui_right")
	OnGround = self.is_on_floor()
	if HitstunTimer > 0:
		if !Hitlag:
			$"ColorRect".rotation_degrees = 0
			$"ColorRect".color = Color.from_rgba8(236, 86, 140)
			HitstunTimer -= delta
	else:
		if $"ColorRect".color == Color.from_rgba8(236, 86, 140):
			$"ColorRect".color = Color.from_rgba8(23, 151, 255)
	if HitlagTimer > 0:
		ShakeOffset = max(remap(HitlagTimer, StartingHitlagTimer * 0.4, StartingHitlagTimer, 0, 10), 0)
		$"ColorRect".color = Color.from_rgba8(23, 151, 255)
		$"ColorRect".rotation_degrees = 30 * KnockbackVelocity.sign().x
		$"ColorRect".position.x = ShakeOffset * ShakeDirection
		ShakeDirection = -ShakeDirection
		HitlagTimer -= delta
	else:
		$"ColorRect".position.x = -25

	Hitstun = HitstunTimer > 0
	Hitlag = HitlagTimer > 0

	if WasHitstun && !Hitstun:
		var Carry = Vector2(XVelocity, YVelocity) + KnockbackVelocity
		Carry = Carry.limit_length(1200)
		if OnGround:
			Carry.y = 0
		XVelocity = Carry.x
		YVelocity = Carry.y
		KnockbackVelocity = Vector2.ZERO
	WasHitstun = Hitstun

	if !Dodging && !Hitstun && !Hitlag:
		if OnGround == true:
			if AirDodging:
				AirDodging = false
				$"ColorRect".rotation_degrees = 0
				$"ColorRect".color = Color.from_rgba8(23, 151, 255) 
			var TargetXVelocity = Direction * Speed * OverallSpeedMultiplier
			if get_floor_angle() < floor_max_angle: self.rotation = get_floor_angle()
			TimeInAir = 0
			if !ResetJumpDebounce:
				CurrentJumps = Jumps
				ResetJumpDebounceFunction()

			var UnrotatedXVelocity = TargetXVelocity
			TargetXVelocity = UnrotatedXVelocity * -get_floor_normal().y
			var SpeedMultiplier = (Direction * Speed * OverallSpeedMultiplier) / TargetXVelocity
			if TargetXVelocity == 0: SpeedMultiplier = 1
			TargetXVelocity *= SpeedMultiplier

			if Direction == 0 && !AirDodging:
				XVelocity = 0 + (XVelocity - 0) * exp(-Deceleration * delta)
			elif !AirDodging:
				XVelocity = TargetXVelocity + (XVelocity - TargetXVelocity) * exp(-Acceleration * delta)

			if !JumpDebounce:
				if Direction != 0 && self.rotation < self.floor_max_angle:
					YVelocity = (UnrotatedXVelocity * (get_floor_normal().x * Direction)) * SpeedMultiplier
				elif Direction == 0:
					YVelocity = 0 + (YVelocity - 0) * exp(-Deceleration * delta)
				else:
					YVelocity = 0
		else:
			self.rotation_degrees = 0
			TimeInAir += delta
			if CurrentJumps == Jumps: CurrentJumps -= 1
			if Direction == 0 && !AirDodging:
				XVelocity = 0 + (XVelocity - 0) * exp(-AirDeceleration * delta)
			elif !AirDodging:
				var TargetXVelocity = Direction * Speed * OverallSpeedMultiplier
				XVelocity = TargetXVelocity + (XVelocity - TargetXVelocity) * exp(-AirAcceleration * delta)
			if Input.get_axis("ui_down", "ui_up") == -1 && TimeInAir > 0.5 && !AirDodging:
				YVelocity = (FastFallingSpeed * OverallFallingSpeedMultiplier)
			else:
				if YVelocity > FallingSpeed * OverallFallingSpeedMultiplier:
					YVelocity = FallingSpeed * OverallFallingSpeedMultiplier
				else:
					YVelocity += Gravity * OverallGravityMultiplier * delta
	elif Dodging && !Hitstun && !Hitlag:
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
	elif Hitstun && !Hitlag:
		XVelocity = 0
		if OnGround and YVelocity > 0:
			YVelocity = 0
		else:
			YVelocity = min(YVelocity + KBHitstunGravity * delta, (FallingSpeed * OverallFallingSpeedMultiplier) * OverallKnockbackMultiplier)

	var Decay = KBDecayPerSecond * delta
	if KnockbackVelocity.length() > Decay:
		KnockbackVelocity -= KnockbackVelocity.normalized() * Decay
	else:
		KnockbackVelocity = Vector2.ZERO
	
	self.velocity = Vector2(XVelocity, YVelocity) + KnockbackVelocity
	if!Hitlag: move_and_slide()

	if Hitstun:
		for Collision in get_slide_collision_count():
			var Normal = get_slide_collision(Collision).get_normal()
			if KnockbackVelocity.dot(Normal) < 0:
				var IsFloor = Normal.y < -0.7
				if KnockbackVelocity.length() > 300 && HitstunTimer > 0.1:
					KnockbackVelocity = KnockbackVelocity.bounce(Normal) * (0.6 if IsFloor else 0.95)
				else:
					KnockbackVelocity = KnockbackVelocity.slide(Normal)
