extends AnimatedSprite2D

const SFX_METEOR_IMPACT = preload("res://assets/audio/sfx/characters/mage/mage_meteor_impact.wav")

const AOE_RADIUS: float = 210.0
const DAMAGE: int = 4
const KNOCKBACK_FORCE: float = 450.0

var caster: CharacterBody2D = null


func _ready() -> void:
	play("default")
	animation_finished.connect(queue_free)
	apply_aoe_damage()
	trigger_camera_shake()
	play_sfx(SFX_METEOR_IMPACT, 1.0)


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream or not get_parent():
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.global_position = global_position
	get_parent().add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


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
	var game = get_tree().current_scene
	if game and game.has_method("apply_camera_shake"):
		game.apply_camera_shake(12.0)
	elif get_parent() and get_parent().has_method("apply_camera_shake"):
		get_parent().apply_camera_shake(12.0)
	else:
		var player = get_tree().get_first_node_in_group("player")
		if player and is_instance_valid(player) and player.has_method("apply_camera_shake"):
			player.apply_camera_shake(12.0)
