extends CharacterBody2D

# =========================================================
# PLAYER BANDIT (ANGGOTA PARTY KE-2: ROGUE / DUAL-BLADE MELEE)
# =========================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shield_sprite: Sprite2D = $ShieldSprite

# =========================
# PARTY / LEADER / FOLLOWER
# =========================
var is_leader: bool = false
var leader_node: CharacterBody2D = null
var queue_slot_index: int = 1
var in_party_combat: bool = false
var ai_attack_timer: float = 0.0
enum PartyCommand { ATTACK, FOLLOW }
var party_command: PartyCommand = PartyCommand.ATTACK
const COMBAT_ATTACK_RANGE: float = 90.0 # Jarak serang melee Bandit
var is_flanking: bool = false

# =========================
# MOVEMENT SETTINGS
# =========================
const NORMAL_SPEED := 128.0
const SPRINT_SPEED := 220.0

var target_position: Vector2
var is_moving := false

var last_direction := Vector2.DOWN
var last_movement_direction := Vector2.DOWN

# =========================
# COMBAT & MELEE SETTINGS
# =========================
const DUST_SCENE = preload("res://scene/effect/run_dust.tscn")
const VISUAL_CENTER_OFFSET: Vector2 = Vector2(0.0, 0.0)

@export var attack_range: float = 115.0     # Jarak jangkauan tebasan dasar
@export var attack_damage: int = 2          # Damage tebasan dasar Bandit
@export var attack_cooldown: float = 0.85   # Jeda tebasan serangan dasar (lincah & cepat)
var attack_stuck_timer: float = 0.0
var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.DOWN

var attack_step: int = 0                  # 0: siap mengayun, 1: ayunan 1 selesai, 2: ayunan 2 selesai
var attack_elapsed_timer: float = 0.0
const SWING_1_IMPACT_TIME: float = 0.15   # Timing ayunan pertama (Frame 2)
const SWING_2_IMPACT_TIME: float = 0.43   # Timing ayunan kedua (Frame 6, double damage)
const ATTACK_TOTAL_DURATION: float = 0.58 # Total durasi siklus tebasan dasar (8 frame pada 14 FPS)

# =========================
# SPECIAL SKILL: TRIPLE SLASH (TOMBOL E)
# =========================
@export var skill_cooldown_max: float = 5.0 # Cooldown skill Triple Slash (5 detik)
var skill_cooldown_timer: float = 0.0
var is_skill_active: bool = false
var skill_timer: float = 0.0
var skill_slash_step: int = 0
var skill_attack_dir: Vector2 = Vector2.DOWN
var skill_hit_enemies_step: Array[Node2D] = []
var skill_stuck_timer: float = 0.0

# =========================
# SPRINT DUST SETTINGS
# =========================
var dust_timer: float = 0.0
const DUST_INTERVAL: float = 0.13

# =========================
# HEALTH & KNOCKBACK
# =========================
@export var max_health: int = 10             # Bandit berdarah lincah (10 HP)
@export var respawn_time: float = 3.0
var current_health: int = 10
var is_dead: bool = false
var spawn_position: Vector2

@export var knockback_strength: float = 0.0 # Knockback dinonaktifkan saat terkena damage (0.0)
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 1500.0

@export var invulnerability_duration: float = 0.25 # Proteksi kebal singkat setelah hit
var invulnerability_timer: float = 0.0

# =========================
# SHIELD GUARD (DARI KNIGHT)
# =========================
var is_shield_active: bool = false
var shield_timer: float = 0.0
var shield_tween: Tween = null

# =========================
# CAMERA SHAKE SETTINGS
# =========================
@export var camera_shake_strength: float = 7.0
var shake_intensity: float = 0.0
var shake_decay: float = 35.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	current_health = max_health
	spawn_position = global_position
	target_position = global_position
	play_idle_animation()
	_setup_enemy_collision_exceptions.call_deferred()


func _setup_enemy_collision_exceptions() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and e is CollisionObject2D:
			add_collision_exception_with(e)
			e.add_collision_exception_with(self)


func set_party_command(cmd: int) -> void:
	party_command = cmd as PartyCommand
	if party_command == PartyCommand.FOLLOW:
		is_flanking = false
		if is_attacking:
			cancel_attack()
		if is_skill_active:
			cancel_skill()
		if not is_leader and not is_dead:
			process_follower_exploring(0.0)


func set_as_leader(active: bool, new_leader: CharacterBody2D = null, slot_idx: int = 1) -> void:
	is_leader = active
	leader_node = new_leader
	queue_slot_index = slot_idx

	var game_node = get_tree().current_scene
	if not game_node or not ("current_party_command" in game_node):
		if get_parent() and ("current_party_command" in get_parent()):
			game_node = get_parent()
	if game_node and "current_party_command" in game_node:
		party_command = game_node.current_party_command as PartyCommand

	if is_leader:
		in_party_combat = false
		is_flanking = false
		ai_attack_timer = 0.0
		if not is_attacking and not is_skill_active:
			play_idle_animation()
		print(name, " maju sebagai Leader aktif!")
	else:
		ai_attack_timer = randf_range(0.3, 0.7)
		if not is_attacking and not is_skill_active:
			play_idle_animation()


func cancel_skill() -> void:
	is_skill_active = false
	skill_timer = 0.0
	skill_slash_step = 0
	skill_stuck_timer = 0.0
	skill_hit_enemies_step.clear()
	if not is_dead and not is_moving:
		play_idle_animation()


func cancel_attack() -> void:
	is_attacking = false
	attack_step = 0
	attack_elapsed_timer = 0.0
	attack_stuck_timer = 0.0
	if not is_dead and not is_moving and not is_skill_active:
		play_idle_animation()


func set_party_combat_mode(active: bool) -> void:
	in_party_combat = active
	if in_party_combat:
		ai_attack_timer = randf_range(0.2, 0.5)
	else:
		ai_attack_timer = 0.0
		is_flanking = false
		if not is_leader and leader_node and is_instance_valid(leader_node) and "last_direction" in leader_node:
			last_direction = leader_node.last_direction
			play_idle_animation()


# =========================================================
# PROCESS & INPUT
# =========================================================

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Reduksi knockback
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		if knockback_velocity.length() < 8.0:
			knockback_velocity = Vector2.ZERO

	# Cooldown invulnerability frame
	if invulnerability_timer > 0.0:
		invulnerability_timer -= delta

	# Cooldown serangan dasar
	if attack_timer > 0.0:
		attack_timer -= delta

	# Cooldown skill Triple Slash
	if skill_cooldown_timer > 0.0:
		skill_cooldown_timer -= delta

	# Penanganan aktif skill Triple Slash
	if is_skill_active:
		process_triple_slash_skill(delta)

	# Shield timer & visual update (dari Knight)
	if is_shield_active or (shield_sprite and shield_sprite.visible):
		if is_shield_active:
			shield_timer -= delta
			if shield_timer <= 0.0:
				deactivate_shield()
		update_shield_visual()

	# Timing ayunan tebasan dasar (Double Swing: Ayunan 1 pada ~0.15s, Ayunan 2 pada ~0.43s)
	if is_attacking:
		attack_elapsed_timer += delta
		attack_stuck_timer += delta

		# Ayunan 1 (Frame 2)
		if attack_step == 0 and attack_elapsed_timer >= SWING_1_IMPACT_TIME:
			attack_step = 1
			execute_slash_damage(attack_direction, 1)

		# Ayunan 2 (Frame 6) - Double damage swing
		elif attack_step == 1 and attack_elapsed_timer >= SWING_2_IMPACT_TIME:
			attack_step = 2
			execute_slash_damage(attack_direction, 2)

		# Selesai setelah siklus 8 frame tuntas (~0.58s)
		if attack_elapsed_timer >= ATTACK_TOTAL_DURATION or attack_stuck_timer >= 0.75:
			is_attacking = false
			attack_step = 0
			attack_elapsed_timer = 0.0
			attack_stuck_timer = 0.0
			if not is_dead and not is_moving and not is_skill_active:
				play_idle_animation()
	else:
		attack_stuck_timer = 0.0

	# Pemisahan kendali Leader vs Follower
	if is_leader:
		process_leader_movement(delta)
	else:
		if in_party_combat and party_command == PartyCommand.ATTACK:
			process_follower_combat(delta)
		else:
			process_follower_exploring(delta)

	# Debu lari saat sprint
	handle_run_dust_cycle(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not is_leader or is_dead:
		return

	# Tombol E: Aktivasi Skill Triple Slash
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if skill_cooldown_timer <= 0.0 and not is_attacking and not is_skill_active:
			activate_triple_slash()
			get_viewport().set_input_as_handled()


func process_leader_movement(_delta: float) -> void:
	if is_skill_active:
		return

	# Serangan dasar klik kiri (Hold / Tap)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if attack_timer <= 0.0 and not is_attacking and not is_skill_active:
			shoot_towards(get_global_mouse_position())

	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1

	input_dir = input_dir.normalized()
	var is_sprinting: bool = Input.is_key_pressed(KEY_SHIFT)
	var current_speed: float = SPRINT_SPEED if is_sprinting else NORMAL_SPEED

	var move_velocity := Vector2.ZERO

	if input_dir != Vector2.ZERO:
		is_moving = true
		last_movement_direction = input_dir

		if is_attacking or is_skill_active:
			move_velocity = Vector2.ZERO
		else:
			move_velocity = input_dir * current_speed
			update_direction_animation(input_dir)
	else:
		is_moving = false
		if not is_attacking and not is_skill_active and animated_sprite.animation.begins_with("walk_"):
			play_idle_animation()

	velocity = move_velocity + knockback_velocity
	move_and_slide_with_separation()


# =========================================================
# SPECIAL SKILL: TRIPLE SLASH
# =========================================================

func activate_triple_slash(target_pos: Vector2 = Vector2.ZERO) -> void:
	if is_skill_active or is_dead:
		return

	is_skill_active = true
	is_moving = false
	is_attacking = false
	skill_timer = 0.0
	skill_slash_step = 0
	skill_stuck_timer = 0.0
	skill_cooldown_timer = skill_cooldown_max
	skill_hit_enemies_step.clear()

	if target_pos != Vector2.ZERO:
		skill_attack_dir = global_position.direction_to(target_pos)
	elif is_leader:
		skill_attack_dir = global_position.direction_to(get_global_mouse_position())
	else:
		skill_attack_dir = last_direction

	if skill_attack_dir == Vector2.ZERO:
		skill_attack_dir = last_direction

	attack_direction = skill_attack_dir
	last_direction = get_cardinal_direction(skill_attack_dir)

	# Mainkan animasi triple_slash (12 frames)
	play_triple_slash_animation()
	print(name, " mengeksekusi skill TRIPLE SLASH!")


func play_triple_slash_animation() -> void:
	if animated_sprite:
		# Hadap kiri jika mengarah ke kiri
		animated_sprite.flip_h = (skill_attack_dir.x < -0.1)
		animated_sprite.play("triple_slash")


func process_triple_slash_skill(delta: float) -> void:
	skill_timer += delta
	skill_stuck_timer += delta

	# Tiga tebasan berturut-turut pada timeline 12 frame (16 FPS, total durasi 0.75s):
	# Slash 1: frame 2 (~0.12s)
	# Slash 2: frame 6 (~0.36s)
	# Slash 3: frame 10 (~0.60s)
	if skill_slash_step == 0 and skill_timer >= 0.12:
		skill_slash_step = 1
		execute_triple_slash_step(1, 2, 130.0, 4.0)
	elif skill_slash_step == 1 and skill_timer >= 0.36:
		skill_slash_step = 2
		execute_triple_slash_step(2, 2, 135.0, 4.0)
	elif skill_slash_step == 2 and skill_timer >= 0.60:
		skill_slash_step = 3
		execute_triple_slash_step(3, 2, 145.0, 7.0)

	# Lunge dorongan maju halus saat menebas
	if skill_timer < 0.65:
		velocity = skill_attack_dir * 120.0
		move_and_slide_with_separation()
	else:
		velocity = Vector2.ZERO

	# Selesai setelah siklus 12 frame tuntas (~0.75s)
	if skill_timer >= 0.75 or skill_stuck_timer >= 1.0:
		is_skill_active = false
		skill_timer = 0.0
		skill_slash_step = 0
		skill_stuck_timer = 0.0
		skill_hit_enemies_step.clear()
		if not is_dead and not is_moving:
			play_idle_animation()


func execute_triple_slash_step(step: int, damage: int, range_dist: float, shake_amount: float) -> void:
	skill_hit_enemies_step.clear()
	apply_camera_shake(shake_amount)

	var slash_center := global_position + VISUAL_CENTER_OFFSET
	var enemies := get_tree().get_nodes_in_group("enemy")

	for e in enemies:
		if not is_instance_valid(e) or ("is_dead" in e and e.is_dead):
			continue

		var to_enemy: Vector2 = e.global_position - slash_center
		var dist: float = to_enemy.length()

		if dist <= range_dist:
			var angle_diff: float = absf(skill_attack_dir.angle_to(to_enemy))
			if angle_diff <= deg_to_rad(95.0) or dist <= 65.0:
				if has_line_of_sight_to(e):
					skill_hit_enemies_step.append(e)
					if e.has_method("take_damage"):
						e.take_damage(damage, self)

	print(name, " [Triple Slash ", step, "/3] mengenai ", skill_hit_enemies_step.size(), " musuh!")


# =========================================================
# SERANGAN DASAR (MELEE BLADE SLASH)
# =========================================================

func shoot_towards(target_pos: Vector2) -> void:
	if attack_timer > 0.0 or is_attacking or is_dead or is_skill_active:
		return

	is_moving = false
	velocity = knockback_velocity

	var bandit_center := global_position + VISUAL_CENTER_OFFSET
	var dir := bandit_center.direction_to(target_pos)
	if dir == Vector2.ZERO:
		dir = last_direction

	attack_direction = dir
	last_direction = get_cardinal_direction(dir)

	is_attacking = true
	attack_step = 0
	attack_elapsed_timer = 0.0
	attack_stuck_timer = 0.0
	play_attack_animation()
	attack_timer = attack_cooldown


func execute_slash_damage(attack_dir: Vector2, swing_number: int = 1) -> void:
	var current_swing_hits: Array[Node2D] = []
	apply_camera_shake(3.5)

	var slash_range: float = attack_range
	var slash_arc_deg: float = 160.0
	var close_contact_radius: float = 60.0
	var center_offset: Vector2 = VISUAL_CENTER_OFFSET

	if attack_dir.y > 0.3:
		slash_range = 140.0
		close_contact_radius = 75.0
		slash_arc_deg = 180.0
		center_offset = Vector2(0.0, 20.0)

	var bandit_center := global_position + center_offset
	var enemies := get_tree().get_nodes_in_group("enemy")

	for e in enemies:
		if not is_instance_valid(e) or ("is_dead" in e and e.is_dead):
			continue

		var to_enemy: Vector2 = e.global_position - bandit_center
		var dist: float = to_enemy.length()
		var is_hit: bool = false

		if dist <= close_contact_radius:
			is_hit = true
		elif dist <= slash_range:
			var angle_diff: float = absf(attack_dir.angle_to(to_enemy))
			if angle_diff <= deg_to_rad(slash_arc_deg * 0.5):
				if has_line_of_sight_to(e):
					is_hit = true

		if is_hit:
			current_swing_hits.append(e)
			if e.has_method("take_damage"):
				e.take_damage(attack_damage, self)

	print(name, " [Basic Attack Swing ", swing_number, "/2] mengenai ", current_swing_hits.size(), " musuh (Damage: ", attack_damage, ")")


func has_line_of_sight_to(target_node: Node2D) -> bool:
	if not target_node or not is_instance_valid(target_node):
		return false
	var space_state := get_world_2d().direct_space_state
	var bandit_center := global_position + VISUAL_CENTER_OFFSET
	var exclude_rids: Array[RID] = [get_rid()]
	if target_node is CollisionObject2D:
		exclude_rids.append(target_node.get_rid())
	var query := PhysicsRayQueryParameters2D.create(bandit_center, target_node.global_position)
	query.collision_mask = 1
	query.exclude = exclude_rids
	var hit := space_state.intersect_ray(query)
	if not hit.is_empty():
		var col = hit.get("collider")
		if col is TileMapLayer or col is StaticBody2D:
			return false
	return true


# =========================================================
# FOLLOWER LOGIC (EXPLORING & COMBAT)
# =========================================================

func process_follower_exploring(delta: float) -> void:
	if not leader_node or not is_instance_valid(leader_node) or ("is_dead" in leader_node and leader_node.is_dead):
		velocity = knockback_velocity
		move_and_slide_with_separation()
		if not is_attacking and not is_skill_active:
			play_idle_animation()
		return

	if animated_sprite.animation.begins_with("attack_") and not is_attacking:
		play_idle_animation()

	var slot_info: Dictionary = {}
	var game_node = get_tree().current_scene
	if game_node and game_node.has_method("get_follower_trail_slot"):
		slot_info = game_node.get_follower_trail_slot(queue_slot_index)

	if slot_info.is_empty():
		return

	var follow_slot: Vector2 = slot_info["pos"]
	var target_facing: Vector2 = slot_info.get("dir", leader_node.last_direction if (leader_node and is_instance_valid(leader_node) and "last_direction" in leader_node) else Vector2.DOWN)
	var dist_to_slot := global_position.distance_to(follow_slot)

	var leader_is_moving := false
	if leader_node and is_instance_valid(leader_node):
		if "is_moving" in leader_node and leader_node.is_moving:
			leader_is_moving = true
		elif "velocity" in leader_node and leader_node.velocity.length() >= 10.0:
			leader_is_moving = true

	# Kondisi berhenti tegas saat Leader diam
	if not leader_is_moving and dist_to_slot <= 16.0:
		if knockback_velocity != Vector2.ZERO:
			velocity = knockback_velocity
			move_and_slide_with_separation()
			return
		velocity = Vector2.ZERO
		is_moving = false
		global_position = global_position.move_toward(follow_slot, 50.0 * delta)
		if leader_node and is_instance_valid(leader_node) and "last_direction" in leader_node:
			last_direction = leader_node.last_direction
		play_idle_animation()
		move_and_slide_with_separation()
		return

	# Hysteresis deadzone
	const STOP_THRESHOLD := 6.0
	const START_THRESHOLD := 16.0

	var should_stop := false
	if not is_moving and dist_to_slot < START_THRESHOLD:
		should_stop = true
	elif is_moving and dist_to_slot <= STOP_THRESHOLD:
		should_stop = true

	if should_stop:
		velocity = knockback_velocity
		is_moving = false
		move_and_slide_with_separation()
		if knockback_velocity == Vector2.ZERO:
			global_position = global_position.move_toward(follow_slot, 40.0 * delta)
		if not leader_is_moving and leader_node and is_instance_valid(leader_node) and "last_direction" in leader_node:
			last_direction = leader_node.last_direction
		else:
			last_direction = target_facing
		if not is_attacking and not is_skill_active:
			play_idle_animation()
	else:
		var move_dir := global_position.direction_to(follow_slot)
		var follow_speed := NORMAL_SPEED
		if Input.is_key_pressed(KEY_SHIFT) or (leader_node and is_instance_valid(leader_node) and leader_node.velocity.length() > NORMAL_SPEED + 10.0):
			follow_speed = SPRINT_SPEED
		elif dist_to_slot > 180.0:
			follow_speed = SPRINT_SPEED
		elif dist_to_slot > 90.0:
			follow_speed = NORMAL_SPEED * 1.15

		var current_speed: float = min(follow_speed, dist_to_slot / max(delta, 0.001))
		velocity = (move_dir * current_speed) + knockback_velocity
		move_and_slide_with_separation()
		is_moving = true
		last_movement_direction = move_dir
		update_direction_animation(move_dir)


func process_follower_combat(delta: float) -> void:
	if not in_party_combat:
		return
	if is_attacking or is_skill_active:
		velocity = knockback_velocity
		move_and_slide_with_separation()
		return

	var cam_rect := get_camera_world_rect()
	var enemies := get_tree().get_nodes_in_group("enemy")
	var target_enemy: Node2D = null
	var min_dist: float = INF

	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			if cam_rect.has_point(e.global_position):
				var d: float = global_position.distance_to(e.global_position)
				if d < min_dist:
					min_dist = d
					target_enemy = e

	if not target_enemy:
		process_follower_exploring(delta)
		return

	var dist_to_enemy := global_position.distance_to(target_enemy.global_position)

	if dist_to_enemy <= COMBAT_ATTACK_RANGE:
		velocity = knockback_velocity
		is_moving = false
		move_and_slide_with_separation()
		last_direction = get_cardinal_direction(global_position.direction_to(target_enemy.global_position))
		if not is_attacking and not is_skill_active:
			play_idle_animation()
		ai_attack_timer -= delta
		if ai_attack_timer <= 0.0 and not is_attacking:
			ai_attack_timer = attack_cooldown
			# Follower Bandit memprioritaskan Triple Slash jika cooldown siap!
			if skill_cooldown_timer <= 0.0:
				activate_triple_slash(target_enemy.global_position)
			else:
				shoot_towards(target_enemy.global_position)
		return
	else:
		var move_dir := global_position.direction_to(target_enemy.global_position)
		velocity = (move_dir * NORMAL_SPEED) + knockback_velocity
		is_moving = true
		move_and_slide_with_separation()
		last_movement_direction = move_dir
		update_direction_animation(move_dir)


# =========================================================
# DAMAGE, HEALTH & RESPAWN
# =========================================================

func take_damage(amount: int, _source_position = null) -> void:
	if is_dead or invulnerability_timer > 0.0:
		return

	# Kebal 100% jika perisai Knight sedang aktif
	if is_shield_active:
		apply_camera_shake(3.0)
		return

	invulnerability_timer = invulnerability_duration
	current_health = max(0, current_health - amount)
	apply_camera_shake(camera_shake_strength)

	modulate = Color(1.0, 0.4, 0.4)
	var hit_flash_tween = create_tween()
	hit_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.25)

	if current_health <= 0:
		die()


func apply_knockback(force: Vector2) -> void:
	if force == Vector2.ZERO:
		return
	knockback_velocity = force
	is_moving = false


func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	is_moving = false
	is_attacking = false
	attack_step = 0
	attack_elapsed_timer = 0.0
	attack_stuck_timer = 0.0
	is_skill_active = false
	deactivate_shield()
	ai_attack_timer = 0.0
	knockback_velocity = Vector2.ZERO
	print("Bandit Gugur! Menunggu respawn...")

	if is_leader:
		var game_node = get_tree().current_scene
		if not game_node or not game_node.has_method("switch_to_next_character"):
			if get_parent() and get_parent().has_method("switch_to_next_character"):
				game_node = get_parent()
		if game_node and game_node.has_method("switch_to_next_character"):
			game_node.switch_to_next_character()

	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	remove_from_group("player")

	var death_tween = create_tween()
	death_tween.tween_property(self, "modulate", Color(0.8, 0.2, 0.2, 0.0), 0.5)
	await death_tween.finished

	await get_tree().create_timer(respawn_time).timeout
	respawn()


func respawn() -> void:
	deactivate_shield()
	global_position = spawn_position
	target_position = spawn_position
	current_health = max_health
	is_moving = false
	is_attacking = false
	attack_step = 0
	attack_elapsed_timer = 0.0
	attack_stuck_timer = 0.0
	is_skill_active = false
	is_dead = false
	knockback_velocity = Vector2.ZERO

	add_to_group("player")
	if collision_shape:
		collision_shape.set_deferred("disabled", false)

	modulate = Color(1.0, 1.0, 1.0, 0.0)
	var respawn_tween = create_tween()
	respawn_tween.tween_property(self, "modulate", Color.WHITE, 0.6)
	play_idle_animation()
	print(name, " bangkit kembali di arena pertarungan!")


# =========================================================
# SHIELD GUARD INTEGRATION (DARI KNIGHT)
# =========================================================

func grant_shield(duration: float) -> void:
	if is_dead:
		return
	is_shield_active = true
	shield_timer = duration

	if shield_sprite:
		shield_sprite.visible = true
		shield_sprite.modulate.a = 0.0
		update_shield_visual()
		if shield_tween and shield_tween.is_valid():
			shield_tween.kill()
		shield_tween = create_tween()
		shield_tween.tween_property(shield_sprite, "modulate:a", 1.0, 0.25)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)


func deactivate_shield() -> void:
	if not is_shield_active and not (shield_sprite and shield_sprite.visible):
		return
	is_shield_active = false
	shield_timer = 0.0

	if shield_sprite and shield_sprite.visible:
		if shield_tween and shield_tween.is_valid():
			shield_tween.kill()
		shield_tween = create_tween()
		shield_tween.tween_property(shield_sprite, "modulate:a", 0.0, 0.35)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN)
		await shield_tween.finished
		if not is_shield_active and shield_sprite:
			shield_sprite.visible = false


func update_shield_visual() -> void:
	if shield_sprite and shield_sprite.visible:
		shield_sprite.position = Vector2(0.0, 1.5)


# =========================================================
# RUN DUST & CAMERA SHAKE HELPERS
# =========================================================

func handle_run_dust_cycle(delta: float) -> void:
	var current_move_speed := velocity.length()
	if current_move_speed >= (NORMAL_SPEED * 1.35) and not is_attacking and not is_skill_active and not is_dead:
		dust_timer -= delta
		if dust_timer <= 0.0:
			dust_timer = DUST_INTERVAL
			spawn_run_dust(velocity.normalized())
	else:
		dust_timer = 0.0


func spawn_run_dust(move_dir: Vector2) -> void:
	if not get_parent():
		return

	var dust = DUST_SCENE.instantiate()
	var feet_y: float = 36.0
	var lag_x: float = 6.0
	var lag_y: float = 4.0

	if move_dir.y < -0.3:
		feet_y = 38.0
		lag_y = 10.0
		lag_x = 7.0
	elif absf(move_dir.y) <= 0.3:
		feet_y = 36.0
		lag_y = 0.0
		lag_x = 8.0
	else:
		feet_y = 38.0
		lag_y = 6.0
		lag_x = 6.0

	var feet_pos := global_position + Vector2(0.0, feet_y)
	var spawn_pos := feet_pos - Vector2(move_dir.x * lag_x, move_dir.y * lag_y)
	spawn_pos += Vector2(randf_range(-3.0, 3.0), randf_range(-1.5, 1.5))

	dust.global_position = spawn_pos
	dust.flip_h = randf() > 0.5
	dust.scale = Vector2(randf_range(3.5, 4.5), randf_range(3.5, 4.5))
	dust.z_index = 3
	get_parent().add_child(dust)


func apply_camera_shake(intensity: float = -1.0) -> void:
	var amount = intensity if intensity > 0.0 else camera_shake_strength
	shake_intensity = max(shake_intensity, amount)
	if get_parent() and get_parent().has_method("apply_camera_shake"):
		get_parent().apply_camera_shake(amount)


func get_camera_world_rect() -> Rect2:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if not cam:
		return Rect2()
	var vp_size: Vector2 = get_viewport_rect().size / cam.zoom
	var center: Vector2 = cam.get_screen_center_position()
	return Rect2(center - vp_size * 0.5, vp_size).grow(50.0)


func get_cardinal_direction(dir: Vector2) -> Vector2:
	if abs(dir.x) > abs(dir.y):
		return Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if dir.y > 0 else Vector2.UP


func get_direction_string(dir: Vector2) -> String:
	var c := get_cardinal_direction(dir)
	if c == Vector2.UP:
		return "n"
	elif c == Vector2.DOWN:
		return "s"
	elif c == Vector2.RIGHT:
		return "e"
	else:
		return "w"


func play_idle_animation() -> void:
	if animated_sprite:
		var dir_str := get_direction_string(last_direction)
		animated_sprite.flip_h = false
		animated_sprite.play("idle_" + dir_str)


func update_direction_animation(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	last_direction = get_cardinal_direction(dir)
	var dir_str := get_direction_string(last_direction)
	if animated_sprite:
		animated_sprite.flip_h = false
		animated_sprite.play("walk_" + dir_str)


func play_attack_animation() -> void:
	if animated_sprite:
		var dir_str := get_direction_string(attack_direction)
		animated_sprite.flip_h = false
		animated_sprite.play("attack_" + dir_str)


func get_controlled_projectile_speed() -> float:
	return 580.0


# =========================================================
# BOID SEPARATION (MENCEGAH PENUMPUKAN ANTAR-HERO & MUSUH)
# =========================================================

func get_separation_vector() -> Vector2:
	var separation := Vector2.ZERO
	const min_sep_dist: float = 38.0

	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e != self and is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			var diff: Vector2 = global_position - e.global_position
			var d: float = diff.length()
			if d < min_sep_dist:
				var push_dir: Vector2 = diff.normalized() if d > 0.5 else Vector2(1.0, 0.0)
				separation += push_dir * (min_sep_dist - d)

	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if p != self and is_instance_valid(p) and not ("is_dead" in p and p.is_dead):
			var diff: Vector2 = global_position - p.global_position
			var d: float = diff.length()
			if d < min_sep_dist:
				var push_dir: Vector2 = diff.normalized() if d > 0.5 else Vector2(-1.0, 0.0)
				separation += push_dir * (min_sep_dist - d)

	return separation


func move_and_slide_with_separation() -> void:
	var sep := get_separation_vector()
	if sep != Vector2.ZERO:
		velocity += sep.limit_length(55.0) * 8.0
	move_and_slide()

