extends Area2D

@export var damage: int = 3
@export var shooter_group: String = "player"

var hit_targets: Array[Node] = []

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready():
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
		# Verifikasi posisi target benar-benar berada di dalam radius / batas CollisionShape2D efek ini
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
	if not is_instance_valid(target) or not is_instance_valid(collision_shape):
		return false

	# Konversi posisi global target ke posisi lokal node efek ini
	var local_pos: Vector2 = to_local(target.global_position)

	# Periksa apakah posisi lokal target berada dalam rentang collision shape milik efek ini
	var shape = collision_shape.shape
	if shape is RectangleShape2D:
		var half_extents = shape.size / 2.0
		# Berikan toleransi secukupnya untuk radius fisik tubuh musuh
		var tolerance: float = 25.0
		if absf(local_pos.x) <= (half_extents.x + tolerance) and absf(local_pos.y) <= (half_extents.y + tolerance):
			return true
		return false
	elif shape is CircleShape2D:
		return local_pos.length() <= (shape.radius + 25.0)

	# Fallback jarak global jika shape lain (maksimal sepanjang rentang visual efek)
	return global_position.distance_to(target.global_position) <= 220.0


func _on_animation_finished():
	queue_free()
