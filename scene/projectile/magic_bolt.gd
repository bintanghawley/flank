extends Area2D

# =========================================================
# MAGIC BOLT (PROJECTILE MAGE)
# =========================================================

@export var speed: float = 520.0
@export var damage: int = 2
@export var shooter_group: String = "player"
var shooter_node: CharacterBody2D = null

var direction: Vector2 = Vector2.RIGHT
var is_destroyed: bool = false
var has_been_on_screen: bool = false

@onready var trail_line: Line2D = $TrailLine
const MAX_TRAIL_POINTS := 12

func _ready():
	add_to_group("projectile")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	if trail_line:
		trail_line.top_level = true
		trail_line.clear_points()


func _physics_process(delta: float):
	if is_destroyed:
		return

	global_position += direction * speed * delta

	# Update visual trail
	if trail_line:
		trail_line.add_point(global_position)
		if trail_line.get_point_count() > MAX_TRAIL_POINTS:
			trail_line.remove_point(0)

	# Batas kamera / map
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
			if tip_pos.x <= cam.limit_left or tip_pos.x >= cam.limit_right or \
			   tip_pos.y <= cam.limit_top or tip_pos.y >= cam.limit_bottom:
				return true

	var screen_rect: Rect2 = vp.get_visible_rect()
	var screen_pos: Vector2 = vp.get_canvas_transform() * tip_pos
	if screen_rect.has_point(screen_pos):
		has_been_on_screen = true
	elif has_been_on_screen:
		return true

	return false


func _on_body_entered(body: Node2D):
	if is_destroyed or body == null:
		return

	# Jangan tabrak sesama party member
	if body.is_in_group("player"):
		return

	# Tembok / Rintangan
	if body is StaticBody2D or body is TileMapLayer:
		destroy(true)
		return

	var target = body
	if shooter_group == "player":
		if not target.is_in_group("enemy") and target.get_parent() != null and target.get_parent().is_in_group("enemy"):
			target = target.get_parent()

		if target.is_in_group("enemy"):
			if target.has_method("take_damage"):
				target.take_damage(damage, shooter_node)

			# Trigger getaran kamera saat magic bolt mengenai musuh
			var leader = get_tree().get_first_node_in_group("player")
			if leader and is_instance_valid(leader) and leader.has_method("apply_camera_shake"):
				leader.apply_camera_shake(7.0)

			destroy(true)


func _on_area_entered(area: Area2D):
	if is_destroyed or area == null:
		return
	var parent_node = area.get_parent()
	if parent_node and is_instance_valid(parent_node) and parent_node.is_in_group("enemy"):
		_on_body_entered(parent_node)


func destroy(with_impact: bool = false):
	if is_destroyed:
		return
	is_destroyed = true

	if with_impact:
		spawn_impact_burst()

	if trail_line:
		var tw = create_tween()
		tw.tween_property(trail_line, "modulate:a", 0.0, 0.15)
		tw.tween_callback(trail_line.queue_free)

	queue_free()


func spawn_impact_burst():
	if not get_parent():
		return
	# Visual burst spark
	var burst = Node2D.new()
	burst.global_position = global_position
	burst.z_index = 6
	get_parent().add_child(burst)
	
	var ring = Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(0.4, 0.8, 1.0, 0.9)
	var pts: PackedVector2Array = []
	for i in range(9):
		var ang = i * TAU / 8.0
		pts.append(Vector2(cos(ang), sin(ang)) * 6.0)
	ring.points = pts
	burst.add_child(ring)
	
	var tw = burst.create_tween()
	tw.set_parallel(true)
	tw.tween_property(burst, "scale", Vector2(3.5, 3.5), 0.2)
	tw.tween_property(burst, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(burst.queue_free)
