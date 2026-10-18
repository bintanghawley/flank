extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

@export var pulse_speed: float = 7.0
var time_passed: float = 0.0


func _process(delta: float):
	time_passed += delta
	if sprite:
		# Denyut halus pada transparansi indikator agar terlihat dinamis
		var alpha: float = 0.75 + 0.25 * sin(time_passed * pulse_speed)
		sprite.modulate.a = alpha


func set_aim(origin: Vector2, dir: Vector2, dist: float):
	global_position = origin + dir * dist
	rotation = dir.angle()


func set_charge_progress(prog: float):
	if sprite:
		var clamped: float = clampf(prog, 0.0, 1.0)
		# Menambahkan intensitas warna saat pengecasan mendekati maksimal
		sprite.modulate.r = 1.0 + clamped * 0.4
		sprite.modulate.g = 1.0 + clamped * 0.2
		sprite.modulate.b = 1.0
