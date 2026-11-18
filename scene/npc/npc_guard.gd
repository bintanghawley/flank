extends CharacterBody2D

enum State {
	PATROL_MOVE,
	PATROL_WAIT
}

@export var patrol_points: Array[Vector2] = []
@export var move_speed: float = 65.0
@export var wait_time_at_point: float = 1.5
@export var reach_threshold: float = 8.0

var current_state: State = State.PATROL_MOVE
var current_point_idx: int = 0
var wait_timer: float = 0.0
var facing_direction: String = "s"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("npc")

	if not patrol_points.is_empty():
		# Temukan waypoint terdekat dari posisi awal saat spawn
		var closest_dist: float = INF
		var closest_idx: int = 0
		for i in range(patrol_points.size()):
			var d := global_position.distance_to(patrol_points[i])
			if d < closest_dist:
				closest_dist = d
				closest_idx = i
		current_point_idx = closest_idx

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

			if dist <= reach_threshold:
				# Sampai di waypoint, berhenti sejenak
				velocity = Vector2.ZERO
				current_state = State.PATROL_WAIT
				wait_timer = wait_time_at_point
				current_point_idx = (current_point_idx + 1) % patrol_points.size()
				_play_idle_animation(facing_direction)
			else:
				var dir := (target_pos - global_position).normalized()
				velocity = dir * move_speed
				move_and_slide()

				_update_facing_and_idle_anim(dir)

		State.PATROL_WAIT:
			velocity = Vector2.ZERO
			wait_timer -= delta
			_play_idle_animation(facing_direction)
			if wait_timer <= 0.0:
				current_state = State.PATROL_MOVE


func _update_facing_and_idle_anim(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing_direction = "e" if dir.x > 0 else "w"
	else:
		facing_direction = "s" if dir.y > 0 else "n"

	_play_idle_animation(facing_direction)


func _play_idle_animation(dir_code: String) -> void:
	if not is_instance_valid(animated_sprite):
		return

	var anim_name := "idle_" + dir_code
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)
		elif not animated_sprite.is_playing():
			animated_sprite.play(anim_name)
