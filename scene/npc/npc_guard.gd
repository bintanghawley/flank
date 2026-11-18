extends CharacterBody2D

enum State {
	PATROL_MOVE,
	PATROL_WAIT
}

@export var patrol_points: Array[Vector2] = []
@export var move_speed: float = 75.0
@export var reach_threshold: float = 20.0
@export var facing_direction: String = "s"

# Pengaturan jeda patroli agar terasa natural
@export_range(0.0, 1.0) var idle_chance: float = 0.85
@export var min_wait_time: float = 1.5
@export var max_wait_time: float = 2.5

var current_state: State = State.PATROL_MOVE
var current_point_idx: int = 0
var wait_timer: float = 0.0
var stuck_timer: float = 0.0
var last_pos: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("npc")
	call_deferred("_setup_player_collision_exceptions")

	if not patrol_points.is_empty():
		# Temukan waypoint terdekat dari posisi awal saat spawn
		var closest_dist: float = INF
		var closest_idx: int = 0
		for i in range(patrol_points.size()):
			var d := global_position.distance_to(patrol_points[i])
			if d < closest_dist:
				closest_dist = d
				closest_idx = i
		# Jika sudah tepat berada di titik terdekat, langsung targetkan titik berikutnya
		if closest_dist <= reach_threshold:
			current_point_idx = (closest_idx + 1) % patrol_points.size()
		else:
			current_point_idx = closest_idx

	last_pos = global_position
	_play_idle_animation(facing_direction)


func _physics_process(delta: float) -> void:
	if patrol_points.is_empty():
		velocity = Vector2.ZERO
		_play_idle_animation(facing_direction)
		return

	match current_state:
		State.PATROL_MOVE:
			var target_pos := patrol_points[current_point_idx]
			var dist := global_position.distance_to(target_pos)

			# Deteksi stuck collision untuk auto recovery
			if global_position.distance_to(last_pos) < (move_speed * delta * 0.4):
				stuck_timer += delta
			else:
				stuck_timer = 0.0
			last_pos = global_position

			# Sampai di waypoint atau terhalang selama > 0.8s
			if dist <= reach_threshold or stuck_timer >= 0.8:
				stuck_timer = 0.0
				velocity = Vector2.ZERO
				if randf() <= idle_chance:
					current_state = State.PATROL_WAIT
					wait_timer = randf_range(min_wait_time, max_wait_time)
					_play_idle_animation(facing_direction)
				else:
					current_point_idx = (current_point_idx + 1) % patrol_points.size()
					current_state = State.PATROL_MOVE
			else:
				var dir := (target_pos - global_position).normalized()
				velocity = dir * move_speed
				move_and_slide()

				# Proteksi collision dengan player saat berpapasan
				for i in range(get_slide_collision_count()):
					var col := get_slide_collision(i)
					var collider := col.get_collider()
					if collider and collider.is_in_group("player"):
						add_collision_exception_with(collider)
						if collider is CollisionObject2D:
							collider.add_collision_exception_with(self)

				_update_facing_and_walk_anim(dir)

		State.PATROL_WAIT:
			velocity = Vector2.ZERO
			wait_timer -= delta
			_play_idle_animation(facing_direction)
			if wait_timer <= 0.0:
				current_point_idx = (current_point_idx + 1) % patrol_points.size()
				current_state = State.PATROL_MOVE
				stuck_timer = 0.0
				last_pos = global_position


func _update_facing_and_walk_anim(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing_direction = "e" if dir.x > 0 else "w"
	else:
		facing_direction = "s" if dir.y > 0 else "n"

	_play_walk_animation(facing_direction)


func _play_walk_animation(dir_code: String) -> void:
	if not is_instance_valid(animated_sprite):
		return

	var anim_name := "walk_" + dir_code
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)
		elif not animated_sprite.is_playing():
			animated_sprite.play(anim_name)


func _play_idle_animation(dir_code: String) -> void:
	if not is_instance_valid(animated_sprite):
		return

	var anim_name := "idle_" + dir_code
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)
		elif not animated_sprite.is_playing():
			animated_sprite.play(anim_name)


func _setup_player_collision_exceptions() -> void:
	if not is_inside_tree():
		return
	var party := get_tree().get_nodes_in_group("player")
	for p in party:
		if is_instance_valid(p) and p is CollisionObject2D:
			add_collision_exception_with(p)
			p.add_collision_exception_with(self)
