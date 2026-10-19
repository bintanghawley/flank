extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

@export var pulse_speed: float = 7.0

var current_length: float = 0.0
var time_passed: float = 0.0


func _process(delta: float):
	time_passed += delta
	if sprite:
		# Denyut halus pada transparansi indikator agar tampak dinamis
		var alpha: float = 0.75 + 0.25 * sin(time_passed * pulse_speed)
		sprite.modulate.a = alpha


func update_indicator(origin: Vector2, dir: Vector2, p_current_length: float, progress: float = 0.0):
	# Simpan panjang aktual panah saat ini
	current_length = p_current_length

	# 1. Pangkal indikator selalu menempel di posisi karakter
	global_position = origin

	# 2. Rotasi mengarah ke sudut bidikan vektor mouse
	rotation = dir.angle()

	# 3. Panjang visual panah tepat sepanjang current_length
	if not sprite and has_node("Sprite2D"):
		sprite = $Sprite2D
	# Tekstur 160px memiliki 5px padding di kiri dan 5px padding di kanan (lebar panah aktif = 149px)
	var active_width: float = 149.0
	if sprite and sprite.texture:
		var raw_w: float = float(sprite.texture.get_width())
		active_width = max(32.0, raw_w - 11.0)
	scale.x = current_length / active_width
	scale.y = 3.0

	# 4. Umpan balik visual intensitas warna saat charge
	if sprite:
		var clamped: float = clampf(progress, 0.0, 1.0)
		sprite.modulate.r = 1.0 + clamped * 0.4
		sprite.modulate.g = 1.0 + clamped * 0.2
		sprite.modulate.b = 1.0


func set_aim(origin: Vector2, dir: Vector2, dist: float):
	update_indicator(origin, dir, dist, 0.0)


func set_charge_progress(prog: float):
	if sprite:
		var clamped: float = clampf(prog, 0.0, 1.0)
		sprite.modulate.r = 1.0 + clamped * 0.4
		sprite.modulate.g = 1.0 + clamped * 0.2
		sprite.modulate.b = 1.0


func get_tip_position() -> Vector2:
	return global_position + Vector2.RIGHT.rotated(rotation) * current_length
