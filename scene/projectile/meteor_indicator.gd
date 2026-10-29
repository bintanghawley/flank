extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
var time_passed: float = 0.0


func _process(delta: float) -> void:
	time_passed += delta
	if sprite:
		# Denyut halus transparansi agar indikator tampak hidup
		sprite.modulate.a = 0.75 + 0.25 * sin(time_passed * 6.0)

