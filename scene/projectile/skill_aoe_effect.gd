extends Area2D

@export var damage: int = 3
@export var shooter_group: String = "player"

var hit_targets: Array[Node] = []

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


var attack_origin: Vector2 = Vector2.ZERO
var attack_dir: Vector2 = Vector2.RIGHT
var attack_length: float = 0.0


func setup(origin: Vector2, dir: Vector2, length: float):
	attack_origin = origin
	attack_dir = dir
	attack_length = length

	# Lebar aktif tekstur serangan adalah 154 pixel (frame 0..7)
	var active_width: float = 154.0
	scale.x = length / active_width
	scale.y = 3.0
	rotation = dir.angle()

	# Posisikan pusat efek tepat di titik tengah antara pangkal karakter dan ujung serangan
	global_position = origin + dir * (length / 2.0)


func _ready():
	if attack_length <= 0.0:
		attack_length = 154.0 * scale.x
		attack_dir = Vector2.RIGHT.rotated(rotation)
		attack_origin = global_position - attack_dir * (attack_length / 2.0)

	# Sambungkan deteksi musuh masuk ke area serangan
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Sambungkan selesainya animasi untuk auto queue_free
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.play("default")

	# Periksa musuh yang sudah berada tepat di dalam area saat efek baru saja di-spawn
	call_deferred("_check_initial_overlaps")


func _check_initial_overlaps():
	for body in get_overlapping_bodies():
		_process_target(body)
	for area in get_overlapping_areas():
		if area.name == "DetectionArea":
			continue
		_process_target(area)


func _on_body_entered(body: Node2D):
	_process_target(body)


func _on_area_entered(area: Area2D):
	# DetectionArea milik musuh adalah area aggro/penglihatan, BUKAN hitbox penerima damage!
	if area.name == "DetectionArea":
		return
	_process_target(area)


func _process_target(node: Node):
	if not is_instance_valid(node):
		return

	var target = node
	if not target.is_in_group("enemy") and target.get_parent() != null and target.get_parent().is_in_group("enemy"):
		target = target.get_parent()

	if target.is_in_group("enemy") and target not in hit_targets:
		# Pastikan musuh tidak berada di belakang karakter pemain
		var to_target: Vector2 = target.global_position - attack_origin
		if to_target.dot(attack_dir) < 0.0:
			return # Musuh berada di belakang karakter pemain, abaikan!

		# Verifikasi posisi target benar-benar berada di dalam rentang jalur serangan ini
		if target is Node2D and not _is_target_in_hitbox(target as Node2D):
			return

		hit_targets.append(target)
		if target.has_method("take_damage"):
			target.take_damage(damage)

		# Kamera bergetar untuk memberikan dampak serangan yang memuaskan
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node and is_instance_valid(player_node) and player_node.has_method("apply_camera_shake"):
			player_node.apply_camera_shake(10.0)


func _is_target_in_hitbox(target: Node2D) -> bool:
	if not is_instance_valid(target):
		return false

	# Vektor dari titik awal serangan (karakter) ke posisi target
	var diff: Vector2 = target.global_position - attack_origin
	var forward_dist: float = diff.dot(attack_dir)
	var lateral_dist: float = absf(diff.cross(attack_dir))

	# Radius toleransi tubuh musuh (musuh berskala 5x dengan hitbox ~40px)
	var tolerance: float = 40.0

	# Target harus berada di antara pangkal serangan dan ujung terjauh serangan
	if forward_dist < -tolerance or forward_dist > (attack_length + tolerance):
		return false

	# Dan berada di dalam batas lebar balok serangan (lebar visual 26 * 3 = 78px, half-width = 39px)
	if lateral_dist > (39.0 + tolerance):
		return false

	return true


func _on_animation_finished():
	queue_free()
