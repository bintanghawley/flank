extends Area2D

# =========================================================
# MAGIC BOLT / FIREBALL (PROJECTILE MAGE)
# =========================================================

const FIREBALL_IMPACT_SCENE = preload("res://scene/projectile/fireball_impact.tscn")

@export var speed: float = 500.0 # Kecepatan dasar magic bolt (disesuaikan dikurangi sedikit menjadi 500.0 px/s)
@export var damage: int = 1 # Rebalanced: seimbang dengan panah Archer
@export var shooter_group: String = "player"
var shooter_node: CharacterBody2D = null

var direction: Vector2 = Vector2.RIGHT
var is_destroyed: bool = false
var has_been_on_screen: bool = false

@onready var trail_line: Line2D = $TrailLine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
const MAX_TRAIL_POINTS := 12

func _ready() -> void:
	add_to_group("projectile")
	# Sambungkan deteksi tabrakan fisik saja (Body Entered)
	# JANGAN sambungkan area_entered agar tidak terkena DetectionArea musuh dari kejauhan/tembok
	body_entered.connect(_on_body_entered)

	rotation = direction.angle()
	if animated_sprite:
		animated_sprite.play("default")

	var vp := get_viewport()
	if vp:
		var screen_pos: Vector2 = vp.get_canvas_transform() * global_position
		if vp.get_visible_rect().has_point(screen_pos):
			has_been_on_screen = true

	if trail_line:
		trail_line.top_level = true
		trail_line.clear_points()
		trail_line.add_point(global_position - direction * 14.0)

	# Hapus otomatis jika meluncur terlalu lama
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self) and not is_destroyed:
		destroy(false)


func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	global_position += direction * speed * delta
	rotation = direction.angle()

	# Update visual trail
	if trail_line:
		var tail_pos: Vector2 = global_position - direction * 14.0
		trail_line.add_point(tail_pos)
		if trail_line.get_point_count() > MAX_TRAIL_POINTS:
			trail_line.remove_point(0)

	# Batas kamera / batas limit peta
	if is_outside_camera_or_limits():
		destroy(false)


func is_outside_camera_or_limits() -> bool:
	var vp := get_viewport()
	if not vp:
		return false

	var tip_pos: Vector2 = global_position + direction * 20.0

	var cam := vp.get_camera_2d()
	if cam:
		if cam.limit_left > -1000000 and cam.limit_right < 1000000:
			if (tip_pos.x <= cam.limit_left or tip_pos.x >= cam.limit_right or
			   tip_pos.y <= cam.limit_top or tip_pos.y >= cam.limit_bottom):
				return true

	var screen_rect: Rect2 = vp.get_visible_rect()
	var screen_pos: Vector2 = vp.get_canvas_transform() * tip_pos
	if screen_rect.has_point(screen_pos):
		has_been_on_screen = true
	elif has_been_on_screen:
		return true

	return false


func _on_body_entered(body: Node2D) -> void:
	if is_destroyed or body == null:
		return

	# Jangan tabrak sesama anggota party
	if body.is_in_group("player"):
		return

	# Tabrakan fisik dengan rintangan dunia (TileMap dinding, pagar, batu, WorldBorders)
	if body is StaticBody2D or body is TileMapLayer:
		destroy(true)
		return

	var target = body

	# Serangan pemain -> Mengenai musuh secara fisik
	if shooter_group == "player":
		if not target.is_in_group("enemy") and target.get_parent() != null and target.get_parent().is_in_group("enemy"):
			target = target.get_parent()

		if target.is_in_group("enemy"):
			if target.has_method("take_damage"):
				target.take_damage(damage, shooter_node)

			# Trigger getaran kamera saat magic bolt mengenai musuh
			var leader = get_tree().get_first_node_in_group("player")
			if leader and is_instance_valid(leader) and leader.has_method("apply_camera_shake"):
				leader.apply_camera_shake(6.0)

			destroy(true)

	# Serangan musuh -> Mengenai player
	elif shooter_group == "enemy":
		if not target.is_in_group("player") and target.get_parent() != null and target.get_parent().is_in_group("player"):
			target = target.get_parent()

		if target.is_in_group("player") or target.name == "Player_Archer" or target.name == "Player_Mage":
			if "is_dead" in target and target.is_dead:
				return
			if target.has_method("take_damage"):
				target.take_damage(damage, global_position)
			destroy(true)


func destroy(with_impact: bool = false) -> void:
	if is_destroyed:
		return
	is_destroyed = true

	set_physics_process(false)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	if animated_sprite:
		animated_sprite.visible = false

	if with_impact:
		spawn_impact()

	# Fade out halus garis trail sebelum dihapus
	if trail_line and trail_line.get_point_count() > 0:
		var tween = create_tween()
		tween.tween_property(trail_line, "modulate:a", 0.0, 0.08)
		tween.tween_callback(queue_free)
	else:
		queue_free()


func spawn_impact() -> void:
	var parent_node := get_parent()
	if not parent_node:
		return

	var impact = FIREBALL_IMPACT_SCENE.instantiate()
	impact.global_position = global_position
	impact.global_rotation = rotation
	parent_node.add_child(impact)
