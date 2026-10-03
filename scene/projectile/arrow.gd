extends Area2D

@export var speed: float = 500.0
@export var damage: int = 1
@export var shooter_group: String = "player" # "player" atau "enemy"

var direction: Vector2 = Vector2.RIGHT


func _ready():
	# Sambungkan deteksi tabrakan
	body_entered.connect(_on_body_entered)
	
	# Hapus otomatis jika tidak mengenai apa-apa dalam 3 detik agar game tetap lancar
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta):
	# Panah meluncur sesuai arahnya
	position += direction * speed * delta

func _on_body_entered(body):
	var target = body

	# Jika panah ditembakkan oleh player -> targetnya adalah musuh
	if shooter_group == "player":
		if not target.is_in_group("enemy") and target.get_parent() != null and target.get_parent().is_in_group("enemy"):
			target = target.get_parent()

		if target.is_in_group("enemy"):
			if target.has_method("take_damage"):
				target.take_damage(damage)
			queue_free()

	# Jika panah ditembakkan oleh musuh -> targetnya adalah player
	elif shooter_group == "enemy":
		if not target.is_in_group("player") and target.get_parent() != null and target.get_parent().is_in_group("player"):
			target = target.get_parent()

		if target.is_in_group("player") or target.name == "Player_Archer":
			if "is_dead" in target and target.is_dead:
				return
			if target.has_method("take_damage"):
				target.take_damage(damage, global_position)
			queue_free()
