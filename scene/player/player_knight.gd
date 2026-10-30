extends CharacterBody2D

# =========================================================
# PLAYER KNIGHT (KARAKTER BARU, PETARUNG MELEE & SHIELD)
# =========================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shield_sprite: Sprite2D = $ShieldSprite

# =========================
# PARTY / LEADER / FOLLOWER
# =========================
var is_leader: bool = false
var leader_node: CharacterBody2D = null
var queue_slot_index: int = 0
var in_party_combat: bool = false
var ai_attack_timer: float = 0.0
enum PartyCommand { ATTACK, FOLLOW }
var party_command: PartyCommand = PartyCommand.ATTACK
const COMBAT_ATTACK_RANGE: float = 85.0 # Jangkauan serang melee petarung Knight
var is_flanking: bool = false
var flank_wp1: Vector2 = Vector2.ZERO
var flank_wp2: Vector2 = Vector2.ZERO
var flank_stage: int = 1
var flank_timeout: float = 0.0
var facing_debounce_timer: float = 0.0

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
# COMBAT & MELEE SLASH SETTINGS
# =========================
const DUST_SCENE = preload("res://scene/effect/run_dust.tscn")

@export var attack_range: float = 90.0      # Jarak jangkauan tebasan pedang
@export var attack_damage: int = 2          # Damage tebasan melee Knight (lebih bertenaga dari proyektil)
@export var attack_cooldown: float = 1.2    # Jeda tebasan serangan dasar
var attack_stuck_timer: float = 0.0
var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.DOWN

# =========================
# SPECIAL SKILL: SHIELD BLOCK (TOMBOL E)
# =========================
@export var skill_cooldown_max: float = 6.0   # Cooldown tombol E (6 detik)
@export var shield_duration: float = 3.5      # Durasi aktifnya perisai (3.5 detik)
var skill_cooldown_timer: float = 0.0
var shield_timer: float = 0.0
var is_shield_active: bool = false
var is_skill_animating: bool = false
var skill_stuck_timer: float = 0.0
var shield_tween: Tween = null

# =========================
# SPRINT DUST SETTINGS
# =========================
var dust_timer: float = 0.0
const DUST_INTERVAL: float = 0.13

# =========================
# HEALTH & KNOCKBACK
# =========================
@export var max_health: int = 12              # Knight memiliki pertahanan & HP lebih tangguh
@export var respawn_time: float = 3.0
var current_health: int = 12
var is_dead: bool = false
var spawn_position: Vector2

@export var knockback_strength: float = 320.0 # Knight lebih kokoh terhadap dorongan lawan
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 1500.0

# =========================
# CAMERA SHAKE SETTINGS
# =========================
@export var camera_shake_strength: float = 7.0
var shake_intensity: float = 0.0
var shake_decay: float = 35.0


func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	spawn_position = global_position
	target_position = global_position
	play_idle_animation()

	if shield_sprite:
		shield_sprite.visible = false
		shield_sprite.modulate.a = 0.0

	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)


func set_party_command(cmd: int) -> void:
	party_command = cmd as PartyCommand
	if party_command == PartyCommand.FOLLOW:
		is_flanking = false
		flank_wp1 = Vector2.ZERO
		flank_wp2 = Vector2.ZERO
		flank_stage = 1
		flank_timeout = 0.0
		is_attacking = false
		velocity = Vector2.ZERO
		if not is_leader and not is_dead:
			if animated_sprite.animation.begins_with("atk_"):
				play_idle_animation()


func set_as_leader(active: bool, new_leader: CharacterBody2D = null, slot_idx: int = 0) -> void:
	is_leader = active
	leader_node = new_leader
	queue_slot_index = slot_idx
	target_position = global_position
	is_moving = false
	is_attacking = false
	velocity = Vector2.ZERO

	attack_stuck_timer = 0.0
	var game_node = get_tree().current_scene
	if game_node and "current_party_command" in game_node:
		party_command = game_node.current_party_command as PartyCommand

	if is_leader:
		in_party_combat = false
		ai_attack_timer = 0.0
		is_flanking = false
		flank_wp1 = Vector2.ZERO
		flank_wp2 = Vector2.ZERO
		flank_stage = 1
		flank_timeout = 0.0
		facing_debounce_timer = 0.0
		print(name, " maju sebagai Leader (Knight)!")
	else:
		# Catatan: Perisai aktif tetap dipertahankan sampai durasinya habis saat ganti karakter
		ai_attack_timer = randf_range(0.3, 0.7)
		if not is_shield_active and not is_skill_animating:
			play_idle_animation()


func cancel_skill() -> void:
	# Catatan: Perisai aktif tetap dipertahankan sampai durasinya habis sesuai permintaan
	is_skill_animating = false
	if is_attacking:
		is_attacking = false
		attack_stuck_timer = 0.0
	if not is_dead and not is_moving and not is_shield_active:
		play_idle_animation()


func set_party_combat_mode(active: bool) -> void:
	in_party_combat = active
	if in_party_combat:
		ai_attack_timer = randf_range(0.3, 0.7)
	else:
		ai_attack_timer = 0.0
		is_flanking = false
		flank_wp1 = Vector2.ZERO
		flank_wp2 = Vector2.ZERO
		flank_stage = 1
		flank_timeout = 0.0
		facing_debounce_timer = 0.0
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

	# Cooldown timer serangan dasar
	if attack_timer > 0.0:
		attack_timer -= delta

	# Cooldown skill Shield
	if skill_cooldown_timer > 0.0:
		skill_cooldown_timer -= delta

	# Timeout pengaman animasi skill
	if is_skill_animating:
		skill_stuck_timer += delta
		if skill_stuck_timer >= 1.0:
			skill_stuck_timer = 0.0
			is_skill_animating = false
			_deploy_shield()
			if not is_dead and not is_moving:
				play_idle_animation()
	else:
		skill_stuck_timer = 0.0

	# Shield timer & visual update (aktif konsisten baik sebagai Leader maupun Follower)
	if is_shield_active or (shield_sprite and shield_sprite.visible):
		if is_shield_active:
			shield_timer -= delta
			if shield_timer <= 0.0:
				deactivate_shield()
		update_shield_visual()

	# Timeout pengaman animasi attack
	if is_attacking:
		attack_stuck_timer += delta
		if attack_stuck_timer >= 0.75:
			is_attacking = false
			attack_stuck_timer = 0.0
			if not is_dead and not is_moving:
				play_idle_animation()

	# Pemisahan kendali Leader vs Follower
	if is_leader:
		process_leader_movement(delta)
	else:
		if in_party_combat and party_command == PartyCommand.ATTACK:
			process_follower_combat(delta)
		else:
			process_follower_exploring(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not is_leader or is_dead:
		return

	# Tombol E: Aktivasi Skill Shield
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if skill_cooldown_timer <= 0.0 and not is_attacking:
			activate_shield()
			get_viewport().set_input_as_handled()


func process_leader_movement(delta: float) -> void:
	# Serangan dasar klik kiri (Hold / Tap)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if attack_timer <= 0.0 and not is_attacking and not is_skill_animating:
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

		if is_attacking or is_skill_animating:
			move_velocity = Vector2.ZERO
		else:
			move_velocity = input_dir * current_speed
			update_direction_animation(input_dir)
	else:
		is_moving = false
		if not is_attacking and not is_skill_animating and animated_sprite.animation.begins_with("walk_"):
			play_idle_animation()

	velocity = move_velocity + knockback_velocity
	move_and_slide()

	handle_run_dust_cycle(delta)


func handle_run_dust_cycle(delta: float) -> void:
	var current_move_speed := velocity.length()
	if current_move_speed >= (NORMAL_SPEED * 1.35) and not is_attacking and not is_dead:
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
	var feet_y: float = 24.0
	var spawn_pos: Vector2 = global_position + Vector2(0, feet_y) - (move_dir * 8.0)
	dust.global_position = spawn_pos
	dust.scale = Vector2(3.5, 3.5)
	dust.modulate = Color(1.0, 1.0, 1.0, 0.75)
	get_parent().add_child(dust)


# =========================================================
# SERANGAN DASAR (MELEE SWORD SLASH)
# =========================================================

func has_valid_attack_target() -> bool:
	var cam_rect := get_camera_world_rect()
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			if cam_rect.has_point(e.global_position):
				if global_position.distance_to(e.global_position) <= (attack_range * 1.5):
					return true
	return false


func shoot_towards(target_pos: Vector2) -> void:
	if attack_timer > 0.0 or is_attacking or is_dead:
		return

	if is_leader and not has_valid_attack_target():
		return

	is_moving = false
	velocity = Vector2.ZERO

	var center_pos := global_position + Vector2(0.0, 5.0)
	var dir := center_pos.direction_to(target_pos)
	if dir == Vector2.ZERO:
		dir = last_direction

	attack_direction = dir
	last_direction = get_8_direction(dir)

	is_attacking = true
	play_attack_animation()
	attack_timer = attack_cooldown

	execute_melee_slash()


func execute_melee_slash() -> void:
	# Tunggu momen puncak tebasan pedang (~0.2 detik)
	await get_tree().create_timer(0.20).timeout
	if is_dead or not is_instance_valid(self):
		return

	var center_pos := global_position + Vector2(0.0, 5.0)
	var enemies := get_tree().get_nodes_in_group("enemy")
	var hit_any: bool = false

	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			var dist := center_pos.distance_to(e.global_position)
			if dist <= attack_range:
				var to_enemy := center_pos.direction_to(e.global_position)
				# Batasi sudut tebasan melee dalam sudut ~110 derajat di depan arah ayunan
				if attack_direction.dot(to_enemy) >= -0.2:
					hit_any = true
					if e.has_method("take_damage"):
						e.take_damage(attack_damage, self)
					elif "current_health" in e:
						e.current_health -= attack_damage
					if "knockback_velocity" in e:
						e.knockback_velocity = attack_direction * 420.0

	if hit_any:
		apply_camera_shake(camera_shake_strength)


# =========================================================
# SPECIAL SKILL: SHIELD BLOCK
# =========================================================

func activate_shield() -> void:
	if is_dead or is_skill_animating or is_shield_active:
		return
	is_moving = false
	velocity = Vector2.ZERO
	is_skill_animating = true
	skill_cooldown_timer = skill_cooldown_max

	# Sembunyikan perisai terlebih dahulu selama animasi skill berlangsung
	if shield_sprite and not is_shield_active:
		shield_sprite.visible = false

	play_skill_animation()
	print(name, " merapalkan skill Shield Guard! Perisai akan muncul setelah animasi selesai.")


const SHIELD_CENTER_OFFSET: Vector2 = Vector2(0.0, 1.5)

func _deploy_shield() -> void:
	if is_dead:
		return
	# Aktifkan pelindung perisai ke seluruh anggota party (Knight, Mage, Archer)
	var party := get_tree().get_nodes_in_group("player")
	for member in party:
		if is_instance_valid(member) and not ("is_dead" in member and member.is_dead):
			if member.has_method("grant_shield"):
				member.grant_shield(shield_duration)


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

	print(name, " pelindung perisai aktif! Kebal terhadap serangan musuh selama ", duration, " detik.")


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
	if not shield_sprite:
		return
	# Pelindung perisai tegak dan tepat berada di tengah tubuh karakter Knight
	shield_sprite.rotation = 0.0
	var float_y: float = sin(Time.get_ticks_msec() * 0.007) * 0.8
	shield_sprite.position = SHIELD_CENTER_OFFSET + Vector2(0.0, float_y)
	var pulse: float = 0.85 + sin(Time.get_ticks_msec() * 0.009) * 0.03
	shield_sprite.scale = Vector2(pulse, pulse)


# =========================================================
# FOLLOWER BEHAVIOR
# =========================================================

func process_follower_exploring(delta: float) -> void:
	if is_skill_animating:
		velocity = knockback_velocity
		move_and_slide()
		return

	if animated_sprite.animation.begins_with("atk_") and not is_attacking:
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

	# 2. Kondisi Berhenti yang Tegas saat Leader Diam
	if not leader_is_moving and dist_to_slot <= 16.0:
		velocity = Vector2.ZERO
		is_moving = false
		global_position = global_position.move_toward(follow_slot, 50.0 * delta)
		if leader_node and is_instance_valid(leader_node) and "last_direction" in leader_node:
			last_direction = leader_node.last_direction
		play_idle_animation()
		move_and_slide()
		return

	# Sistem Hysteresis Deadzone
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
		move_and_slide()
		global_position = global_position.move_toward(follow_slot, 40.0 * delta)
		if not leader_is_moving and leader_node and is_instance_valid(leader_node) and "last_direction" in leader_node:
			last_direction = leader_node.last_direction
		else:
			last_direction = target_facing
		if not is_attacking and not is_skill_animating:
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

		# 1. Pencegahan Overshoot Jitter (Arrival Clamping)
		var current_speed: float = min(follow_speed, dist_to_slot / max(delta, 0.001))

		velocity = (move_dir * current_speed) + knockback_velocity
		move_and_slide()
		is_moving = true
		last_movement_direction = move_dir
		update_direction_animation(move_dir)


func process_follower_combat(delta: float) -> void:
	if not in_party_combat:
		return
	if is_attacking or is_skill_animating:
		velocity = knockback_velocity
		move_and_slide()
		return

	# Cari musuh hidup terdekat
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
		is_flanking = false
		process_follower_exploring(delta)
		return

	var dist_to_enemy := global_position.distance_to(target_enemy.global_position)

	# Knight menyerang dalam jarak melee (COMBAT_ATTACK_RANGE)
	if dist_to_enemy <= COMBAT_ATTACK_RANGE:
		is_flanking = false
		velocity = knockback_velocity
		is_moving = false
		move_and_slide()
		last_direction = get_cardinal_direction(global_position.direction_to(target_enemy.global_position))
		if not is_attacking and not is_skill_animating:
			play_idle_animation()
		ai_attack_timer -= delta
		if ai_attack_timer <= 0.0 and not is_attacking:
			ai_attack_timer = attack_cooldown
			shoot_towards(target_enemy.global_position)
		return
	else:
		# Dekati musuh ke jarak melee
		var move_dir := global_position.direction_to(target_enemy.global_position)
		velocity = (move_dir * NORMAL_SPEED) + knockback_velocity
		is_moving = true
		move_and_slide()
		last_movement_direction = move_dir
		update_direction_animation(move_dir)


# =========================================================
# DAMAGE, HEALTH & RESPAWN
# =========================================================

func take_damage(amount: int, source_position = null) -> void:
	if is_dead:
		return

	var knockback_dir := Vector2.ZERO
	if source_position is Node2D and is_instance_valid(source_position):
		knockback_dir = source_position.global_position.direction_to(global_position)
	elif source_position is Vector2 and source_position != Vector2.ZERO and source_position != global_position:
		knockback_dir = source_position.direction_to(global_position)
	else:
		knockback_dir = -last_direction

	# Shield Guard: menahan seluruh damage serangan musuh
	if is_shield_active:
		modulate = Color(1.8, 1.8, 2.4)
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)
		knockback_velocity = knockback_dir * 80.0
		apply_camera_shake(3.0)
		print(name, " memblok serangan dengan perisai! 0 damage diterima.")
		return

	current_health -= amount
	knockback_velocity = knockback_dir * knockback_strength

	modulate = Color(1.8, 0.4, 0.4)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)

	# Follower Knight otomatis menyalakan shield jika HP terancam
	if not is_leader and current_health <= 6 and skill_cooldown_timer <= 0.0 and not is_skill_animating and not is_shield_active:
		activate_shield()

	if current_health <= 0:
		die()


func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force


func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	is_moving = false
	is_attacking = false
	deactivate_shield()

	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished

	await get_tree().create_timer(respawn_time).timeout
	_respawn()


func _respawn() -> void:
	global_position = spawn_position
	current_health = max_health
	is_dead = false
	velocity = Vector2.ZERO
	is_moving = false
	is_attacking = false
	deactivate_shield()

	if collision_shape:
		collision_shape.set_deferred("disabled", false)

	modulate.a = 1.0
	play_idle_animation()


# =========================================================
# ANIMATION HELPERS
# =========================================================

func update_direction_animation(dir: Vector2) -> void:
	last_direction = get_cardinal_direction(dir)
	play_walk_animation()


func play_idle_animation() -> void:
	if is_attacking or is_skill_animating or is_dead:
		return
	var facing := get_4_direction_str(last_direction)
	animated_sprite.play("idle_" + facing)


func play_walk_animation() -> void:
	if is_attacking or is_skill_animating or is_dead:
		return
	var facing := get_4_direction_str(last_direction)
	animated_sprite.play("walk_" + facing)


func play_attack_animation() -> void:
	var facing := get_4_direction_str(last_direction)
	animated_sprite.play("atk_" + facing)


func play_skill_animation() -> void:
	var facing := get_4_direction_str(last_direction)
	animated_sprite.play("skill_" + facing)


func _on_animated_sprite_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		attack_stuck_timer = 0.0
		if not is_dead and not is_moving:
			play_idle_animation()

	if is_skill_animating:
		is_skill_animating = false
		_deploy_shield()
		if not is_dead and not is_moving:
			play_idle_animation()


# =========================================================
# UTILITY HELPERS
# =========================================================

func get_cardinal_direction(dir: Vector2) -> Vector2:
	if abs(dir.x) > abs(dir.y):
		return Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if dir.y > 0 else Vector2.UP


func get_4_direction_str(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "e" if dir.x > 0 else "w"
	else:
		return "s" if dir.y > 0 else "n"


func get_8_direction(dir: Vector2) -> Vector2:
	if dir == Vector2.ZERO:
		return Vector2.DOWN
	var angle = dir.angle()
	var octant = round(8 * angle / (2 * PI))
	octant = int(octant) % 8
	if octant < 0:
		octant += 8
	match octant:
		0: return Vector2.RIGHT
		1: return Vector2(1, 1).normalized()
		2: return Vector2.DOWN
		3: return Vector2(-1, 1).normalized()
		4: return Vector2.LEFT
		5: return Vector2(-1, -1).normalized()
		6: return Vector2.UP
		7: return Vector2(1, -1).normalized()
	return Vector2.DOWN


func get_camera_world_rect() -> Rect2:
	var game_node = get_tree().current_scene
	if game_node and game_node.has_method("get_camera_world_rect"):
		return game_node.get_camera_world_rect()
	var vp := get_viewport()
	if not vp:
		return Rect2()
	var cam := vp.get_camera_2d()
	if not cam:
		return Rect2()
	var vp_size: Vector2 = vp.get_visible_rect().size / cam.zoom
	var center: Vector2 = cam.get_screen_center_position()
	return Rect2(center - vp_size * 0.5, vp_size).grow(40.0)


func apply_camera_shake(intensity: float = -1.0) -> void:
	var amount: float = intensity if intensity > 0.0 else camera_shake_strength
	shake_intensity = max(shake_intensity, amount)
	var game = get_tree().current_scene
	if game and game.has_method("apply_camera_shake"):
		game.apply_camera_shake(amount)


func get_controlled_projectile_speed() -> float:
	# Fallback kompatibilitas sistem proyektil saat Knight bertindak sebagai Leader
	return 580.0
