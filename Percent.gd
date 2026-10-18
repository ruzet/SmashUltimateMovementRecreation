extends Label

func _process(_delta: float) -> void:
	var Player = $"../../Player"
	self.text = str(Player.get("Percent")) + "%"
