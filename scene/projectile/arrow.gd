extends Area2D

const IMPACT_SCENE = preload("res://scene/projectile/arrow_impact.tscn")

@export var speed: float = 500.0
@export var damage: int = 1
@export var shooter_group: String = "player" # "player" atau "enemy"
@export var max_trail_points: int = 16       # Panjang garis trail lurus

var direction: Vector2 = Vector2.RIGHT
var is_destroyed: bool = false

@onready var trail_line: Line2D = $TrailLine


func _ready():
	# Sambungkan deteksi tabrakan
	body_entered.connect(_on_body_entered)

	# Titik awal jejak ekor panah (z_index 2 agar selalu berada di bawah karakter dan tidak menembus tubuh)
	if trail_line:
		trail_line.z_index = 2
		trail_line.clear_points()
		trail_line.add_point(global_position - direction * 16.0)

	# Jika menembak ke arah North (ke atas), panah berada di bawah karakter (z_index 3 < 4)
	# Untuk arah lainnya, panah berada di atas karakter (z_index 5 > 4)
	if direction.y < -0.85:
		$Sprite2D.z_index = 3
	else:
		$Sprite2D.z_index = 5

	# Hapus otomatis jika tidak mengenai apa-apa dalam 3 detik agar game tetap lancar
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self) and not is_destroyed:
		destroy()


func _physics_process(delta: float):
	if is_destroyed:
		return

	# Panah meluncur lurus sesuai arahnya
	var move_step: float = speed * delta
	position += direction * move_step

	# Perbarui garis trail lurus di belakang ekor panah
	if trail_line:
		var tail_pos: Vector2 = global_position - direction * 16.0
		trail_line.add_point(tail_pos)
		while trail_line.get_point_count() > max_trail_points:
			trail_line.remove_point(0)


func destroy():
	if is_destroyed:
		return
	is_destroyed = true

	# Munculkan efek benturan bila ada
	spawn_impact()

	# Nonaktifkan pergerakan dan tabrakan
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.visible = false

	# Fade out halus garis trail sebelum dihapus
	if trail_line and trail_line.get_point_count() > 0:
		var tween = create_tween()
		tween.tween_property(trail_line, "modulate:a", 0.0, 0.08)
		tween.tween_callback(queue_free)
	else:
		queue_free()


func spawn_impact():
	var parent_node = get_parent()
	if not parent_node:
		return

	var impact = IMPACT_SCENE.instantiate()
	impact.global_position = global_position
	impact.global_rotation = global_rotation
	parent_node.add_child(impact)


func _on_body_entered(body):
	if is_destroyed:
		return

	var target = body

	# Jika panah ditembakkan oleh player -> targetnya adalah musuh
	if shooter_group == "player":
		if not target.is_in_group("enemy") and target.get_parent() != null and target.get_parent().is_in_group("enemy"):
			target = target.get_parent()

		if target.is_in_group("enemy"):
			if target.has_method("take_damage"):
				target.take_damage(damage)
			destroy()

	# Jika panah ditembakkan oleh musuh -> targetnya adalah player
	elif shooter_group == "enemy":
		if not target.is_in_group("player") and target.get_parent() != null and target.get_parent().is_in_group("player"):
			target = target.get_parent()

		if target.is_in_group("player") or target.name == "Player_Archer":
			if "is_dead" in target and target.is_dead:
				return
			if target.has_method("take_damage"):
				target.take_damage(damage, global_position)
			destroy()
