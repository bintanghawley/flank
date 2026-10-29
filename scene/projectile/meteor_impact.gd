extends AnimatedSprite2D

const AOE_RADIUS: float = 210.0
const DAMAGE: int = 4
const KNOCKBACK_FORCE: float = 450.0

var caster: CharacterBody2D = null


func _ready() -> void:
	play("default")
	animation_finished.connect(queue_free)
	apply_aoe_damage()
	trigger_camera_shake()


func apply_aoe_damage() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if "is_dead" in enemy and enemy.is_dead:
			continue

		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= AOE_RADIUS:
			if enemy.has_method("take_damage"):
				if caster != null and is_instance_valid(caster):
					enemy.take_damage(DAMAGE, caster)
				else:
					enemy.take_damage(DAMAGE)

			var knock_dir: Vector2 = (enemy.global_position - global_position).normalized()
			if knock_dir == Vector2.ZERO:
				knock_dir = Vector2.DOWN

			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(knock_dir * KNOCKBACK_FORCE)
			elif "knockback_velocity" in enemy:
				enemy.knockback_velocity = knock_dir * KNOCKBACK_FORCE


func trigger_camera_shake() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and player.has_method("apply_camera_shake"):
		player.apply_camera_shake(12.0)
