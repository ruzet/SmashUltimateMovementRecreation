extends CanvasLayer

const Multipliers = {
	"Speed": [0.01, 9999],
	"Jump": [0.01, 9999],
	"FallingSpeed": [0.01, 9999],
	"AirDodge": [0.01, 9999],
	"Gravity": [0.01, 9999],
	"Knockback": [0.01, 9999],
	"Hitstun": [0.01, 9999],
	"Hitlag": [0.01, 9999],
}

const KnockbackSettings = {
	"Angle": [-360, 360],
	"Damage": [0, 9999],
	"Weight": [-9999, 9999],
	"KnockbackScaling": [-9999, 9999],
	"BaseKnockback": [-9999, 9999],
	"UnitMultiplier": [-9999, 9999],
}

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("MultiplierMenu"):
		$"Panel".visible = !$"Panel".visible

func _ready() -> void:
	var Player = $"../Player"
	var TitleTemplate = $"Panel/ScrollContainer/VBoxContainer/Title"
	var StatTemplate = $"Panel/ScrollContainer/VBoxContainer/Template"
	var NewTitle1 = TitleTemplate.duplicate()
	$"Panel/ScrollContainer/VBoxContainer".add_child(NewTitle1)
	NewTitle1.name = "Multipliers"
	NewTitle1.text = "Multipliers"

	for Key in Multipliers:
		var NewStat = StatTemplate.duplicate()
		var StatLabel = NewStat.find_child("Label", true, false)
		var StatLineEdit: LineEdit = NewStat.find_child("LineEdit", true, false)
		$"Panel/ScrollContainer/VBoxContainer".add_child(NewStat)
		NewStat.name = Key
		StatLabel.text = Key
		StatLineEdit.text = str(Player.get("Overall" + Key + "Multiplier"))

		StatLineEdit.text_submitted.connect(func(Text):
			if float(Text) && float(Text) > Multipliers[Key][0] && float(Text) < Multipliers[Key][1]:
				Player.set("Overall" + Key + "Multiplier", float(Text))
			else:
				StatLineEdit.text = "1"
				Player.set("Overall" + Key + "Multiplier", 1)
			)

	var NewTitle2 = TitleTemplate.duplicate()
	$"Panel/ScrollContainer/VBoxContainer".add_child(NewTitle2)
	NewTitle2.name = "Knockback Settings"
	NewTitle2.text = "Knockback Settings"

	for Key in KnockbackSettings:
		var NewStat = StatTemplate.duplicate()
		var StatLabel = NewStat.find_child("Label", true, false)
		var StatLineEdit: LineEdit = NewStat.find_child("LineEdit", true, false)
		$"Panel/ScrollContainer/VBoxContainer".add_child(NewStat)
		NewStat.name = Key
		StatLabel.text = Key
		StatLineEdit.text = str(Player.get(Key))

		StatLineEdit.text_submitted.connect(func(Text):
			if float(Text) && float(Text) > KnockbackSettings[Key][0] && float(Text) < KnockbackSettings[Key][1]:
				Player.set(Key, float(Text))
			else:
				StatLineEdit.text = "1"
				Player.set(Key, 1)
			)
	TitleTemplate.visible = false
	StatTemplate.visible = false
