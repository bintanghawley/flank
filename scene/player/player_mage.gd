extends CharacterBody2D

# =========================================================
# PLAYER MAGE (KARAKTER BARU & ANGGOTA PARTY)
# =========================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# =========================
# PARTY / LEADER / FOLLOWER
# =========================
var is_leader: bool = false
var leader_node: CharacterBody2D = null
var queue_slot_index: int = 0
var in_party_combat: bool = false
var ai_attack_timer: float = 0.0
var strafe_timer: float = 0.0
var strafe_direction: Vector2 = Vector2.ZERO

# =========================
# MOVEMENT SETTINGS
# =========================
const NORMAL_SPEED := 128.0
const SPRINT_SPEED := 220.0

var target_position: Vector2
var is_moving := false

# Pemisahan Arah Hadap (Visual/Bidikan) vs Arah Tempuh (Langkah Aktual Formasi)
var last_direction := Vector2.DOWN
var last_movement_direction := Vector2.DOWN

# =========================
# COMBAT SETTINGS
# =========================
const MAGIC_BOLT_SCENE = preload("res://scene/projectile/magic_bolt.tscn")
const DUST_SCENE = preload("res://scene/effect/run_dust.tscn")

@export var attack_range: float = 520.0
var attack_stuck_timer: float = 0.0
@export var attack_cooldown: float = 0.8
var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.RIGHT

# =========================
# SPRINT DUST SETTINGS
# =========================
var dust_timer: float = 0.0
const DUST_INTERVAL: float = 0.13

# =========================
# HEALTH & KNOCKBACK
# =========================
@export var max_health: int = 10
@export var respawn_time: float = 3.0
var current_health: int = 10
var is_dead: bool = false
var spawn_position: Vector2

@export var knockback_strength: float = 380.0
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 1400.0


func _ready():
	add_to_group("player")
	current_health = max_health
	spawn_position = global_position
	target_position = global_position
	play_idle_animation()


func set_as_leader(active: bool, new_leader: CharacterBody2D = null, slot_idx: int = 0) -> void:
	is_leader = active
	leader_node = new_leader
	queue_slot_index = slot_idx
	target_position = global_position
	is_moving = false
	is_attacking = false
	velocity = Vector2.ZERO

	strafe_timer = 0.0
	attack_stuck_timer = 0.0

	if is_leader:
		in_party_combat = false
		ai_attack_timer = 0.0
		print(name, " maju sebagai Leader!")
	else:
		ai_attack_timer = randf_range(0.3, 0.7)
		play_idle_animation()

func cancel_skill() -> void:
	if is_attacking:
		is_attacking = false
		attack_stuck_timer = 0.0
		if not is_dead and not is_moving:
			play_idle_animation()

func set_party_combat_mode(active: bool) -> void:
	in_party_combat = active
	if in_party_combat:
		ai_attack_timer = randf_range(0.3, 0.7)
		strafe_timer = 0.0
	else:
		ai_attack_timer = 0.0
		strafe_timer = 0.0
		if not is_leader and leader_node and is_instance_valid(leader_node) and "last_direction" in leader_node:
			last_direction = leader_node.last_direction
			play_idle_animation()


# =========================================================
# PROCESS & INPUT
# =========================================================

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# [PERBAIKAN BUG 5]: Reduksi knockback WAJIB dijalankan untuk SEMUA karakter
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		if knockback_velocity.length() < 8.0:
			knockback_velocity = Vector2.ZERO

	# Watchdog anti-stuck is_attacking (maksimal 0.6 detik)
	if is_attacking:
		attack_stuck_timer += delta
		if attack_stuck_timer >= 0.6:
			is_attacking = false
			attack_stuck_timer = 0.0
			if not is_moving:
				play_idle_animation()
	else:
		attack_stuck_timer = 0.0

	if is_leader:
		process_leader_movement(delta)
	else:
		process_follower_logic(delta)

	# [PERBAIKAN BUG 2]: Siklus debu terpusat
	handle_run_dust_cycle(delta)


func _unhandled_input(event: InputEvent):
	if not is_leader or is_dead:
		return

	# Klik kanan untuk bergerak
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			target_position = get_global_mouse_position()
			is_moving = true
			var direction := global_position.direction_to(target_position)
			if not is_attacking:
				update_direction_animation(direction)

		elif event.button_index == MOUSE_BUTTON_LEFT:
			if attack_timer <= 0.0 and not is_attacking:
				shoot_towards(get_global_mouse_position())


# =========================================================
# LEADER MOVEMENT & ATTACK
# =========================================================

func process_leader_movement(delta: float):
	if attack_timer > 0.0:
		attack_timer -= delta

	# Tahan klik kiri untuk serangan berkelanjutan
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if attack_timer <= 0.0 and not is_attacking:
			shoot_towards(get_global_mouse_position())

	# Tahan klik kanan untuk mengarahkan pergerakan
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		target_position = get_global_mouse_position()
		if global_position.distance_to(target_position) > 2.0:
			is_moving = true

	# Input keyboard WASD / Arrow
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
	input_dir = input_dir.normalized()

	var move_velocity := Vector2.ZERO
	var current_speed := NORMAL_SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = SPRINT_SPEED

	if input_dir != Vector2.ZERO:
		is_moving = false
		target_position = global_position
		last_movement_direction = input_dir

		if is_attacking:
			move_velocity = Vector2.ZERO
		else:
			move_velocity = input_dir * current_speed
			update_direction_animation(input_dir)

	elif is_moving:
		if is_attacking:
			move_velocity = Vector2.ZERO
		else:
			var direction := global_position.direction_to(target_position)
			last_movement_direction = direction
			move_velocity = direction * current_speed
			update_direction_animation(direction)

			if global_position.distance_to(target_position) < 4.0:
				global_position = target_position
				is_moving = false
				if not is_attacking:
					play_idle_animation()
	else:
		if not is_attacking and animated_sprite.animation.begins_with("walk_"):
			play_idle_animation()

	velocity = move_velocity + knockback_velocity
	move_and_slide()

	# Respon benturan saat klik mouse
	if is_moving:
		if global_position.distance_to(target_position) < 4.0:
			global_position = target_position
			is_moving = false
			if not is_attacking:
				play_idle_animation()
		elif not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and get_slide_collision_count() > 0:
			if get_real_velocity().length() < 12.0:
				is_moving = false
				if not is_attacking:
					play_idle_animation()


# =========================================================
# FOLLOWER LOGIC (MENGIKUTI LEADER DI BELAKANG)
# =========================================================

func process_follower_logic(delta: float) -> void:
	if not leader_node or not is_instance_valid(leader_node) or ("is_dead" in leader_node and leader_node.is_dead):
		velocity = knockback_velocity
		move_and_slide()
		if not is_attacking:
			play_idle_animation()
		return

	# 1. POSISI BERTEMPUR (COMBAT STATE ALA GUARDIAN TALES)
	if in_party_combat:
		process_follower_combat(delta)
		return

	# Jika sebelumnya memutar animasi attack karena transisi combat, kembalikan ke idle
	if animated_sprite.animation.begins_with("atk_") and not is_attacking:
		play_idle_animation()

	# 2. POSISI BERJALAN & MENJAGA JARAK ANTREAN LEADER (FORMASI TETAP)
	const FOLLOW_DISTANCE: float = 85.0
	const STOP_THRESHOLD: float = 8.0
	const START_THRESHOLD: float = 24.0

	var leader_is_moving: bool = false
	if "velocity" in leader_node and leader_node.velocity.length() > 10.0:
		leader_is_moving = true

	# Hitung anchor_dir secara stabil:
	# Gunakan last_movement_direction jika Leader bergerak, gunakan last_direction jika Leader diam
	var anchor_dir: Vector2 = Vector2.DOWN
	if leader_is_moving:
		if "last_movement_direction" in leader_node and leader_node.last_movement_direction != Vector2.ZERO:
			anchor_dir = leader_node.last_movement_direction
		elif "velocity" in leader_node and leader_node.velocity != Vector2.ZERO:
			anchor_dir = leader_node.velocity
	else:
		if "last_direction" in leader_node and leader_node.last_direction != Vector2.ZERO:
			anchor_dir = leader_node.last_direction
		elif "last_movement_direction" in leader_node and leader_node.last_movement_direction != Vector2.ZERO:
			anchor_dir = leader_node.last_movement_direction

	if anchor_dir == Vector2.ZERO:
		anchor_dir = Vector2.DOWN

	var follow_slot: Vector2 = leader_node.global_position - (anchor_dir.normalized() * (FOLLOW_DISTANCE * queue_slot_index))
	var dist_to_slot: float = global_position.distance_to(follow_slot)

	# Sistem Hysteresis Deadzone:
	# 1. Batas Berhenti (Stop Threshold): <= 8.0 px langsung dianggap TIBA (IDLE)
	# 2. Batas Mulai Bergerak (Start Threshold): Hanya mulai gerak jika dist > 24.0 px ATAU Leader sedang aktif bergerak
	var should_stop: bool = false
	if dist_to_slot <= STOP_THRESHOLD:
		should_stop = true
	elif not is_moving and not leader_is_moving and dist_to_slot <= START_THRESHOLD:
		should_stop = true

	if should_stop:
		velocity = knockback_velocity
		is_moving = false
		# Kunci posisi perlahan ke titik slot presisi (menjamin barisan 100% lurus di satu garis)
		global_position = global_position.move_toward(follow_slot, 40.0 * delta)

		# Sinkronisasi arah hadap persis dengan Leader aktif
		if "last_direction" in leader_node and leader_node.last_direction != Vector2.ZERO:
			last_direction = leader_node.last_direction

		if not is_attacking:
			play_idle_animation()
		move_and_slide()
	else:
		var move_dir := global_position.direction_to(follow_slot)

		# Normalisasi Kecepatan (Cegah 2x Speed, adaptif & proporsional)
		var follow_speed: float = NORMAL_SPEED
		if Input.is_key_pressed(KEY_SHIFT) or (leader_node and leader_node.velocity.length() > NORMAL_SPEED + 10.0):
			follow_speed = SPRINT_SPEED
		elif dist_to_slot > 220.0:
			follow_speed = SPRINT_SPEED
		elif dist_to_slot > 120.0:
			follow_speed = NORMAL_SPEED * 1.15

		velocity = (move_dir * follow_speed) + knockback_velocity
		move_and_slide()
		is_moving = true
		last_movement_direction = move_dir
		update_direction_animation(move_dir)


func process_follower_combat(delta: float) -> void:
	if is_attacking:
		velocity = knockback_velocity
		move_and_slide()
		return

	# 1. Prioritas Target Bersama (Focus fire terkoordinasi berbasis posisi Leader)
	var focus_origin: Vector2 = leader_node.global_position if (leader_node and is_instance_valid(leader_node)) else global_position
	var enemies := get_tree().get_nodes_in_group("enemy")
	var target_enemy: Node2D = null
	var min_dist := INF

	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			var d := focus_origin.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				target_enemy = e

	if not target_enemy:
		# Tidak ada musuh hidup di area
		velocity = knockback_velocity
		move_and_slide()
		if not is_attacking:
			play_idle_animation()
		return

	var dist_to_enemy := global_position.distance_to(target_enemy.global_position)
	var enemy_dir := global_position.direction_to(target_enemy.global_position)

	# 2. Siklus Serang & Strafe Step (Hit-and-Run khas Guardian Tales)
	ai_attack_timer -= delta
	if ai_attack_timer <= 0.0 and dist_to_enemy <= attack_range and not is_attacking:
		ai_attack_timer = randf_range(1.2, 1.6)

		# Tentukan arah strafe reposisi menyamping (45° - 90°)
		var perp := Vector2(-enemy_dir.y, enemy_dir.x)
		if randf() > 0.5:
			perp = -perp
		strafe_direction = (perp + (enemy_dir * randf_range(-0.25, 0.25))).normalized()
		strafe_timer = randf_range(0.4, 0.6)

		# Arah tembak dan orientasi visual tepat ke tubuh musuh
		last_direction = get_8_direction(enemy_dir)
		shoot_towards(target_enemy.global_position)
		return

	# 3. Tethering Ketat ke Leader (Maksimal 240 piksel)
	var move_vector := Vector2.ZERO
	var dist_to_leader: float = 0.0
	var is_tether_broken: bool = false
	if leader_node and is_instance_valid(leader_node):
		dist_to_leader = global_position.distance_to(leader_node.global_position)
		if dist_to_leader > 240.0:
			is_tether_broken = true

	if is_tether_broken:
		# Wajib batalkan kiting dan strafe, langsung berlari mendekat ke arah Leader
		strafe_timer = 0.0
		move_vector = global_position.direction_to(leader_node.global_position)
	else:
		# 4. Dynamic Kiting & Strafe Step
		if dist_to_enemy < 280.0:
			# Terlalu dekat -> Kiting mundur perlahan menjauhi musuh
			move_vector = target_enemy.global_position.direction_to(global_position)
		elif dist_to_enemy > 460.0:
			# Terlalu jauh -> Dekati musuh hingga masuk jarak tembak
			move_vector = enemy_dir
		else:
			# Zona Tembak Ideal (280px - 460px): Reposisi menyamping atau diam membidik
			if strafe_timer > 0.0:
				strafe_timer -= delta
				move_vector = strafe_direction
			else:
				move_vector = Vector2.ZERO
				if not is_attacking:
					last_direction = get_8_direction(enemy_dir)
					play_idle_animation()

	# 5. Soft Separation dari rekan satu party agar tidak saling menumpuk
	var separation := Vector2.ZERO
	var party_nodes := get_tree().get_nodes_in_group("player")
	for ally in party_nodes:
		if ally != self and is_instance_valid(ally):
			var dist_ally := global_position.distance_to(ally.global_position)
			if dist_ally < 48.0 and dist_ally > 0.1:
				separation += (global_position - ally.global_position).normalized() * (48.0 - dist_ally)

	var move_speed := NORMAL_SPEED
	if is_tether_broken:
		if dist_to_leader > 280.0:
			move_speed = SPRINT_SPEED
		else:
			move_speed = NORMAL_SPEED * 1.15
	elif move_vector != Vector2.ZERO:
		move_speed = NORMAL_SPEED * 0.95

	var desired_velocity := (move_vector.normalized() * move_speed) + (separation * 2.5)
	velocity = desired_velocity + knockback_velocity
	move_and_slide()

	if move_vector != Vector2.ZERO and not is_attacking:
		last_movement_direction = move_vector
		update_direction_animation(move_vector)


# =========================================================
# COMBAT & ATTACK METHODS
# =========================================================

func shoot_towards(target_pos: Vector2):
	if attack_timer > 0.0 or is_attacking or is_dead:
		return

	is_moving = false
	velocity = Vector2.ZERO

	# Titik visual tengah karakter
	var center_pos := global_position + Vector2(0.0, 5.0)
	var dir := center_pos.direction_to(target_pos)
	if dir == Vector2.ZERO:
		dir = last_direction

	attack_direction = dir
	last_direction = get_8_direction(dir)

	is_attacking = true
	play_attack_animation()
	attack_timer = attack_cooldown

	# Spawn magic bolt pada momen ayunan tongkat sihir
	reset_attack_state()


func reset_attack_state():
	# Frame ayunan tongkat sihir (~0.25 detik)
	await get_tree().create_timer(0.24).timeout

	if is_dead:
		return

	var spawn_pos := global_position + Vector2(0.0, 5.0) + attack_direction * 22.0
	var bolt = MAGIC_BOLT_SCENE.instantiate()
	bolt.global_position = spawn_pos
	bolt.direction = attack_direction
	bolt.rotation = attack_direction.angle()
	bolt.shooter_node = self
	get_parent().add_child(bolt)

	# Tunggu sampai animasi attack selesai
	await animated_sprite.animation_finished
	if is_dead:
		return

	is_attacking = false
	attack_stuck_timer = 0.0
	if is_moving:
		var direction := global_position.direction_to(target_position)
		update_direction_animation(direction)
	else:
		play_idle_animation()


# =========================================================
# ANIMASI KARAKTER (4 ARAH & DIAGONAL)
# =========================================================

func update_direction_animation(direction: Vector2):
	if direction == Vector2.ZERO:
		return

	last_direction = get_8_direction(direction)

	if not is_attacking:
		play_walk_animation()


func get_8_direction(direction: Vector2) -> Vector2:
	var angle := direction.angle()
	var octant := roundi(angle / (PI / 4.0))

	match octant:
		0:
			return Vector2.RIGHT
		1:
			return Vector2(1, 1)
		2:
			return Vector2.DOWN
		3:
			return Vector2(-1, 1)
		4, -4:
			return Vector2.LEFT
		-3:
			return Vector2(-1, -1)
		-2:
			return Vector2.UP
		-1:
			return Vector2(1, -1)
		_:
			return Vector2.DOWN


func play_walk_animation():
	animated_sprite.flip_h = false

	if last_direction == Vector2.UP:
		animated_sprite.play("walk_n")
	elif last_direction == Vector2.DOWN:
		animated_sprite.play("walk_s")
	elif last_direction == Vector2.LEFT:
		animated_sprite.play("walk_w")
	elif last_direction == Vector2.RIGHT:
		animated_sprite.play("walk_e")
	elif last_direction == Vector2(-1, -1):
		animated_sprite.play("walk_w")
	elif last_direction == Vector2(1, -1):
		animated_sprite.play("walk_w")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(-1, 1):
		animated_sprite.play("walk_e")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(1, 1):
		animated_sprite.play("walk_e")


func play_idle_animation():
	animated_sprite.flip_h = false

	if last_direction == Vector2.UP:
		animated_sprite.play("idle_n")
	elif last_direction == Vector2.DOWN:
		animated_sprite.play("idle_s")
	elif last_direction == Vector2.LEFT:
		animated_sprite.play("idle_w")
	elif last_direction == Vector2.RIGHT:
		animated_sprite.play("idle_e")
	elif last_direction == Vector2(-1, -1):
		animated_sprite.play("idle_w")
	elif last_direction == Vector2(1, -1):
		animated_sprite.play("idle_w")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(-1, 1):
		animated_sprite.play("idle_e")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(1, 1):
		animated_sprite.play("idle_e")


func play_attack_animation():
	animated_sprite.flip_h = false

	if last_direction == Vector2.UP:
		animated_sprite.play("atk_n")
	elif last_direction == Vector2.DOWN:
		animated_sprite.play("atk_s")
	elif last_direction == Vector2.LEFT:
		animated_sprite.play("atk_w")
	elif last_direction == Vector2.RIGHT:
		animated_sprite.play("atk_e")
	elif last_direction == Vector2(-1, -1):
		animated_sprite.play("atk_w")
	elif last_direction == Vector2(1, -1):
		animated_sprite.play("atk_w")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(-1, 1):
		animated_sprite.play("atk_e")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(1, 1):
		animated_sprite.play("atk_e")


# =========================================================
# DUST PARTICLES & DAMAGE
# =========================================================

func handle_run_dust_cycle(delta: float) -> void:
	var current_move_speed := velocity.length()
	# [PERBAIKAN BUG 2]: Berbasis kecepatan nyata, aktif untuk Leader dan Follower
	if current_move_speed >= (NORMAL_SPEED * 1.35) and not is_attacking and not is_dead:
		dust_timer -= delta
		if dust_timer <= 0.0:
			dust_timer = DUST_INTERVAL
			spawn_run_dust(velocity.normalized())
	else:
		dust_timer = 0.0


func spawn_run_dust(move_dir: Vector2):
	if not get_parent():
		return

	var dust = DUST_SCENE.instantiate()
	var feet_pos := global_position + Vector2(0.0, 30.0)
	var spawn_pos := feet_pos - Vector2(move_dir.x * 5.0, move_dir.y * 2.0)
	spawn_pos += Vector2(randf_range(-3.0, 3.0), randf_range(-1.5, 1.5))

	dust.global_position = spawn_pos
	dust.flip_h = randf() > 0.5
	dust.scale = Vector2(randf_range(3.5, 4.5), randf_range(3.5, 4.5))
	dust.z_index = 2
	get_parent().add_child(dust)


func apply_camera_shake(intensity: float = 7.0):
	var leader = get_tree().get_first_node_in_group("player")
	var vp := get_viewport()
	if vp:
		var cam := vp.get_camera_2d()
		if cam and cam.has_method("apply_shake"):
			cam.apply_shake(intensity)
		elif leader and leader != self and leader.has_method("apply_camera_shake"):
			leader.apply_camera_shake(intensity)


func apply_knockback(force: Vector2):
	knockback_velocity = force
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		is_moving = false


func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO):
	if is_dead:
		return

	# [BUG 1 FIX]: Batalkan serangan dan bebaskan kontrol jika terkena hit
	cancel_skill()

	current_health -= amount
	print("Mage terkena serangan! Sisa HP: ", current_health)

	var knockback_dir := Vector2.ZERO
	if source_position != Vector2.ZERO and source_position != global_position:
		knockback_dir = source_position.direction_to(global_position)
	else:
		knockback_dir = -last_direction

	apply_knockback(knockback_dir * knockback_strength)

	modulate = Color(2.5, 0.3, 0.3)
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self) and not is_dead:
		modulate = Color.WHITE

	if current_health <= 0 and not is_dead:
		current_health = 0
		die()


func die():
	if is_dead:
		return
	is_dead = true
	is_moving = false
	is_attacking = false
	in_party_combat = false
	ai_attack_timer = 0.0
	strafe_timer = 0.0
	attack_stuck_timer = 0.0
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	print("Mage Gugur! Menunggu respawn...")

	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	remove_from_group("player")

	var death_tween = create_tween()
	death_tween.tween_property(self, "modulate", Color(0.8, 0.2, 0.2, 0.0), 0.5)
	await death_tween.finished

	visible = false
	await get_tree().create_timer(respawn_time).timeout
	respawn()


func respawn():
	global_position = spawn_position
	target_position = spawn_position
	current_health = max_health
	is_moving = false
	is_attacking = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO

	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	add_to_group("player")

	visible = true
	is_dead = false
	in_party_combat = false
	ai_attack_timer = 0.0
	strafe_timer = 0.0
	attack_stuck_timer = 0.0
	last_movement_direction = Vector2.DOWN
	last_direction = Vector2.DOWN
	play_idle_animation()

	modulate = Color(1.0, 1.0, 1.0, 0.2)
	var respawn_tween = create_tween()
	respawn_tween.tween_property(self, "modulate:a", 1.0, 0.4)
	print("Mage berhasil respawn!")
