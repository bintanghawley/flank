extends CharacterBody2D

# =========================================================
# PLAYER MAGE (KARAKTER BARU & ANGGOTA PARTY)
# =========================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shield_sprite: Sprite2D = get_node_or_null("ShieldSprite")

# =========================
# PARTY SHIELD GUARD (DARI KNIGHT)
# =========================
const SHIELD_CENTER_OFFSET: Vector2 = Vector2(0.0, 3.5)
var is_shield_active: bool = false
var shield_timer: float = 0.0
var shield_tween: Tween = null

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
const COMBAT_ATTACK_RANGE: float = 480.0
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

# Pemisahan Arah Hadap (Visual/Bidikan) vs Arah Tempuh (Langkah Aktual Formasi)
var last_direction := Vector2.DOWN
var last_movement_direction := Vector2.DOWN

# =========================
# COMBAT SETTINGS & BASIC ATTACK PROJECTILE
# =========================
const MAGIC_BOLT_SCENE = preload("res://scene/projectile/magic_bolt.tscn")
const DUST_SCENE = preload("res://scene/effect/run_dust.tscn")

@export var controlled_projectile_speed: float = 500.0 # Kecepatan magic bolt saat Mage dikendalikan pemain (Leader - disesuaikan dikurangi sedikit menjadi 500.0 px/s)
@export var follower_projectile_ratio: float = 1.0   # Rasio kecepatan magic bolt saat Mage menjadi follower (disamakan 1.0 dengan Leader)

@export var attack_range: float = 520.0
var attack_stuck_timer: float = 0.0
@export var attack_cooldown: float = 1.5 # Jeda tembakan serangan dasar (dinaikkan menjadi 1.5s agar basic attack fire rate Mage sedikit lebih lambat dari Archer)
var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.RIGHT

# =========================
# SPECIAL SKILL MODE SETTINGS (METEOR STRIKE)
# =========================
const METEOR_INDICATOR_SCENE = preload("res://scene/projectile/meteor_indicator.tscn")
const METEOR_STRIKE_SCENE = preload("res://scene/projectile/meteor_strike.tscn")

@export var skill_cooldown_max: float = 6.0
var skill_cooldown_timer: float = 0.0
var is_aiming_skill: bool = false
var is_skill_releasing: bool = false
var skill_facing_dir: String = "s"
var active_indicator: Node2D = null

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
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	current_health = max_health
	spawn_position = global_position
	target_position = global_position
	play_idle_animation()
	_setup_shield_sprite()
	_setup_enemy_collision_exceptions.call_deferred()

	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)


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
		print(name, " maju sebagai Leader!")
	else:
		cancel_skill()
		ai_attack_timer = randf_range(0.3, 0.7)
		play_idle_animation()

func cancel_skill() -> void:
	if active_indicator and is_instance_valid(active_indicator):
		active_indicator.queue_free()
		active_indicator = null
	is_aiming_skill = false
	is_skill_releasing = false
	if is_attacking:
		is_attacking = false
		attack_stuck_timer = 0.0
	if not is_dead and not is_moving:
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

	# [PERBAIKAN BUG 5]: Reduksi knockback WAJIB dijalankan untuk SEMUA karakter
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		if knockback_velocity.length() < 8.0:
			knockback_velocity = Vector2.ZERO

	# Cooldown timer serangan dasar untuk SEMUA karakter
	if attack_timer > 0.0:
		attack_timer -= delta

	# Cooldown timer skill aktif
	if skill_cooldown_timer > 0.0:
		skill_cooldown_timer -= delta

	# Shield timer & visual update (aktif konsisten baik sebagai Leader maupun Follower)
	if is_shield_active or (shield_sprite and shield_sprite.visible):
		if is_shield_active:
			shield_timer -= delta
			if shield_timer <= 0.0:
				deactivate_shield()
		update_shield_visual()

	# Pembaruan saat sedang membidik skill
	if is_aiming_skill:
		process_skill_aiming()

	# Watchdog anti-stuck is_attacking (maksimal 0.6 detik)
	if is_attacking:
		attack_stuck_timer += delta
		if attack_stuck_timer >= 0.6:
			is_attacking = false
			attack_stuck_timer = 0.0
			if not is_moving and not is_aiming_skill and not is_skill_releasing:
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

	# Aktivasi Skill Aktif Meteor Strike (Tombol 'E' / ui_skill)
	var is_skill_key := false
	if event.is_action_pressed("ui_skill"):
		is_skill_key = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			is_skill_key = true

	if is_skill_key:
		if not is_aiming_skill and not is_skill_releasing and not is_attacking and skill_cooldown_timer <= 0.0:
			start_skill_aiming()
			if get_viewport():
				get_viewport().set_input_as_handled()
			return

	# Kontrol saat sedang membidik skill
	if is_aiming_skill:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				execute_meteor_strike()
				if get_viewport():
					get_viewport().set_input_as_handled()
				return
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				cancel_skill()
				if get_viewport():
					get_viewport().set_input_as_handled()
				return
		return

	# Jika sedang memutar animasi release skill, klik kanan membatalkan
	if is_skill_releasing:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_skill()
			if get_viewport():
				get_viewport().set_input_as_handled()
		return

	# Serangan dasar klik kiri
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if attack_timer <= 0.0 and not is_attacking:
				shoot_towards(get_global_mouse_position())


# =========================================================
# LEADER MOVEMENT & ATTACK
# =========================================================

func process_leader_movement(delta: float):
	if is_aiming_skill or is_skill_releasing:
		velocity = knockback_velocity
		move_and_slide_with_separation()
		return

	if attack_timer > 0.0:
		attack_timer -= delta

	# Tahan klik kiri untuk serangan berkelanjutan
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if attack_timer <= 0.0 and not is_attacking:
			shoot_towards(get_global_mouse_position())

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
	move_and_slide_with_separation()

	# Respon benturan saat klik mouse
	if is_moving:
		if global_position.distance_to(target_position) < 4.0:
			global_position = target_position
			is_moving = false
			if not is_attacking:
				play_idle_animation()
		elif get_slide_collision_count() > 0:
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
		move_and_slide_with_separation()
		if not is_attacking:
			play_idle_animation()
		return

	# 1. POSISI BERTEMPUR (COMBAT STATE ALA GUARDIAN TALES)
	# HANYA aktif jika party_command == PartyCommand.ATTACK dan in_party_combat == true
	if party_command == PartyCommand.ATTACK and in_party_combat:
		process_follower_combat(delta)
		return

	# 2. POSISI MENGEKOR (EXPLORING STATE - SNAKE BREADCRUMBS)
	process_follower_exploring(delta)


func process_follower_exploring(delta: float) -> void:
	if animated_sprite.animation.begins_with("atk_") and not is_attacking:
		play_idle_animation()

	var slot_info: Dictionary = {}
	var game_node = get_tree().current_scene
	if game_node and game_node.has_method("get_follower_trail_slot"):
		slot_info = game_node.get_follower_trail_slot(queue_slot_index)

	if slot_info.is_empty():
		return

	var follow_slot: Vector2 = slot_info["pos"]
	var target_facing: Vector2 = slot_info.get("dir", leader_node.last_direction)
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
		if "last_direction" in leader_node:
			last_direction = leader_node.last_direction
		play_idle_animation()
		move_and_slide_with_separation()
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
		move_and_slide_with_separation()
		global_position = global_position.move_toward(follow_slot, 40.0 * delta)
		if not leader_is_moving and "last_direction" in leader_node:
			last_direction = leader_node.last_direction
		else:
			last_direction = target_facing
		if not is_attacking:
			play_idle_animation()
	else:
		var move_dir := global_position.direction_to(follow_slot)
		var follow_speed := NORMAL_SPEED
		if Input.is_key_pressed(KEY_SHIFT) or (leader_node and leader_node.velocity.length() > NORMAL_SPEED + 10.0):
			follow_speed = SPRINT_SPEED
		elif dist_to_slot > 180.0:
			follow_speed = SPRINT_SPEED
		elif dist_to_slot > 90.0:
			follow_speed = NORMAL_SPEED * 1.15

		# 1. Pencegahan Overshoot Jitter (Arrival Clamping)
		var current_speed: float = min(follow_speed, dist_to_slot / max(delta, 0.001))

		velocity = (move_dir * current_speed) + knockback_velocity
		move_and_slide_with_separation()
		is_moving = true
		last_movement_direction = move_dir
		update_direction_animation(move_dir)

func process_follower_combat(delta: float) -> void:
	if not in_party_combat:
		return
	if is_attacking:
		velocity = knockback_velocity
		move_and_slide_with_separation()
		return
		
	# 1. Cari musuh hidup terdekat di dalam layar kamera
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
		
	# 2. Uji koridor tembak
	var has_los := has_clear_projectile_los_to(target_enemy, 12.0)
	var dist_to_enemy := global_position.distance_to(target_enemy.global_position)
	
	# 3. KONDISI TEMBAK (STAND & SHOOT): Jika koridor bebas DAN masuk jarak tembak
	if has_los:
		is_flanking = false
		if dist_to_enemy <= COMBAT_ATTACK_RANGE:
			velocity = knockback_velocity
			is_moving = false
			move_and_slide_with_separation()
			last_direction = get_cardinal_direction(global_position.direction_to(target_enemy.global_position))
			if not is_attacking:
				play_idle_animation()
			ai_attack_timer -= delta
			if ai_attack_timer <= 0.0 and not is_attacking:
				ai_attack_timer = attack_cooldown
				shoot_towards(target_enemy.global_position)
			return
		else:
			# Jalur bersih tapi musuh masih agak jauh: dekati langsung
			var move_dir := global_position.direction_to(target_enemy.global_position)
			velocity = (move_dir * NORMAL_SPEED) + knockback_velocity
			is_moving = true
			move_and_slide_with_separation()
			last_movement_direction = move_dir
			apply_smoothed_facing(move_dir, delta)
			return
			
	# 4. KONDISI TERHALANG RINTANGAN (NAVIGASI MEMUTAR):
	flank_timeout -= delta
	if not is_flanking or flank_timeout <= 0.0:
		calculate_flank_waypoints(target_enemy)
		
	var active_wp := flank_wp1
	if flank_stage == 1:
		if global_position.distance_to(flank_wp1) <= 28.0:
			flank_stage = 2
			active_wp = flank_wp2
	else:
		active_wp = flank_wp2
		if global_position.distance_to(flank_wp2) <= 28.0:
			is_flanking = false
			
	var move_dir := global_position.direction_to(active_wp)
	if move_dir == Vector2.ZERO:
		move_dir = last_direction
	velocity = (move_dir * NORMAL_SPEED) + knockback_velocity
	is_moving = true
	move_and_slide_with_separation()
	last_movement_direction = move_dir
	apply_smoothed_facing(move_dir, delta)
func calculate_flank_waypoints(target_node: Node2D) -> bool:
	if not target_node or not is_instance_valid(target_node):
		return false
	var space_state := get_world_2d().direct_space_state
	var my_pos: Vector2 = global_position
	var target_pos: Vector2 = target_node.global_position
	
	var exclude_rids: Array[RID] = [get_rid()]
	if target_node is CollisionObject2D:
		exclude_rids.append(target_node.get_rid())

	# Raycast langsung ke target untuk mendeteksi titik benturan rintangan
	var ray := PhysicsRayQueryParameters2D.create(my_pos, target_pos)
	ray.collision_mask = 1 # Layer 1: dinding / pagar / rintangan fisik
	ray.exclude = exclude_rids
	var hit := space_state.intersect_ray(ray)
	if hit.is_empty():
		return false
		
	var col = hit.get("collider")
	if not (col is TileMapLayer or col is StaticBody2D):
		return false # Bukan dinding fisik, tidak perlu flank
		
	var hit_pos: Vector2 = hit.position
	var to_target: Vector2 = (target_pos - my_pos).normalized()
	if to_target == Vector2.ZERO:
		to_target = Vector2.UP
		
	# Arah tegak lurus melintang terhadap garis bidik target (kiri & kanan murni)
	var dir_left: Vector2 = Vector2(-to_target.y, to_target.x).normalized()
	var dir_right: Vector2 = -dir_left
	
	var probe_distances: Array[float] = [24.0, 48.0, 72.0, 96.0, 128.0, 160.0, 200.0, 260.0, 340.0, 440.0, 560.0, 720.0]
	var open_dist_left: float = INF
	var open_dist_right: float = INF
	
	# Probe sisi kiri untuk mendeteksi ujung rintangan
	for d in probe_distances:
		var p_start := hit_pos + (dir_left * d) - (to_target * 24.0)
		var p_end := hit_pos + (dir_left * d) + (to_target * 24.0)
		var check_ray := PhysicsRayQueryParameters2D.create(p_start, p_end)
		check_ray.collision_mask = 1
		check_ray.exclude = [self]
		if space_state.intersect_ray(check_ray).is_empty():
			open_dist_left = d
			break
			
	# Probe sisi kanan untuk mendeteksi ujung rintangan
	for d in probe_distances:
		var p_start := hit_pos + (dir_right * d) - (to_target * 24.0)
		var p_end := hit_pos + (dir_right * d) + (to_target * 24.0)
		var check_ray := PhysicsRayQueryParameters2D.create(p_start, p_end)
		check_ray.collision_mask = 1
		check_ray.exclude = [self]
		if space_state.intersect_ray(check_ray).is_empty():
			open_dist_right = d
			break
			
	# Pilih sisi terdekat dari posisi karakter saat ini
	var chosen_dir: Vector2 = dir_left
	var chosen_dist: float = 120.0
	var left_valid: bool = (open_dist_left < 1000.0)
	var right_valid: bool = (open_dist_right < 1000.0)
	
	if left_valid and right_valid:
		var pos_left := hit_pos + dir_left * open_dist_left
		var pos_right := hit_pos + dir_right * open_dist_right
		if my_pos.distance_to(pos_left) <= my_pos.distance_to(pos_right):
			chosen_dir = dir_left
			chosen_dist = open_dist_left
		else:
			chosen_dir = dir_right
			chosen_dist = open_dist_right
	elif left_valid:
		chosen_dir = dir_left
		chosen_dist = open_dist_left
	elif right_valid:
		chosen_dir = dir_right
		chosen_dist = open_dist_right
	else:
		var pos_left := hit_pos + dir_left * 80.0
		var pos_right := hit_pos + dir_right * 80.0
		chosen_dir = dir_left if my_pos.distance_to(pos_left) < my_pos.distance_to(pos_right) else dir_right
		chosen_dist = 120.0
		
	# Waypoint 1: 40 px di luar ujung pagar, tetap di sisi karakter (-to_target * 24.0)
	flank_wp1 = hit_pos + (chosen_dir * (chosen_dist + 40.0)) - (to_target * 24.0)
	# Waypoint 2: Melangkah menyeberang ke area seberang (+to_target * 65.0)
	flank_wp2 = flank_wp1 + (to_target * 65.0)
	flank_stage = 1
	is_flanking = true
	flank_timeout = 5.0
	return true

func apply_smoothed_facing(move_dir: Vector2, delta: float) -> void:
	if move_dir.length() < 0.1:
		return
	var target_cardinal := get_cardinal_direction(move_dir)
	if target_cardinal != last_direction:
		facing_debounce_timer -= delta
		if facing_debounce_timer <= 0.0:
			last_direction = target_cardinal
			facing_debounce_timer = 0.15 # Kunci minimal 150ms sebelum boleh ganti arah
	else:
		facing_debounce_timer = 0.15
	update_direction_animation(last_direction)

func has_clear_projectile_los_to(target_node: Node2D, clearance_radius: float = 14.0) -> bool:
	if not target_node or not is_instance_valid(target_node):
		return false
	var space_state := get_world_2d().direct_space_state
	var from_pos: Vector2 = global_position
	var to_pos: Vector2 = target_node.global_position
	
	var exclude_rids: Array[RID] = [get_rid()]
	if target_node is CollisionObject2D:
		exclude_rids.append(target_node.get_rid())

	# 1. Ray tengah
	var query_center := PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query_center.collision_mask = 1 # Rintangan / pagar / dinding / tunggul
	query_center.exclude = exclude_rids
	var hit_center := space_state.intersect_ray(query_center)
	if not hit_center.is_empty():
		var col = hit_center.get("collider")
		if col is TileMapLayer or col is StaticBody2D:
			return false
		
	# 2. Vektor tegak lurus (perpendicular) untuk menguji lebar fisik proyektil
	var fire_dir := (to_pos - from_pos).normalized()
	if fire_dir == Vector2.ZERO:
		return false
	var perp := Vector2(-fire_dir.y, fire_dir.x) * clearance_radius
	
	# 3. Ray sayap kiri (menguji apakah sisi kiri proyektil menyenggol rintangan)
	var query_left := PhysicsRayQueryParameters2D.create(from_pos + perp, to_pos + perp)
	query_left.collision_mask = 1
	query_left.exclude = exclude_rids
	var hit_left := space_state.intersect_ray(query_left)
	if not hit_left.is_empty():
		var col = hit_left.get("collider")
		if col is TileMapLayer or col is StaticBody2D:
			return false
		
	# 4. Ray sayap kanan (menguji apakah sisi kanan proyektil menyenggol rintangan)
	var query_right := PhysicsRayQueryParameters2D.create(from_pos - perp, to_pos - perp)
	query_right.collision_mask = 1
	query_right.exclude = exclude_rids
	var hit_right := space_state.intersect_ray(query_right)
	if not hit_right.is_empty():
		var col = hit_right.get("collider")
		if col is TileMapLayer or col is StaticBody2D:
			return false
		
	return true

func has_line_of_sight_to(target_node: Node2D) -> bool:
	return has_clear_projectile_los_to(target_node, 14.0)


func has_valid_attack_target() -> bool:
	var cam_rect := get_camera_world_rect()
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			if cam_rect.has_point(e.global_position):
				if global_position.distance_to(e.global_position) <= attack_range:
					return true
	return false

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

func shoot_towards(target_pos: Vector2):
	if attack_timer > 0.0 or is_attacking or is_dead or is_aiming_skill or is_skill_releasing:
		return

	# [BATASI SERANGAN KOSONG]: Jika karakter aktif (Leader), wajib ada musuh valid di layar & jangkauan
	if is_leader and not has_valid_attack_target():
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


func get_controlled_projectile_speed() -> float:
	return controlled_projectile_speed


func get_dynamic_projectile_speed() -> float:
	if is_leader:
		return controlled_projectile_speed

	# Kecepatan proyektil magic bolt dibuat sama baik dikendalikan maupun tidak dikendalikan
	return controlled_projectile_speed * follower_projectile_ratio


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
	bolt.speed = get_dynamic_projectile_speed()
	get_tree().current_scene.add_child(bolt)

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
	if direction == Vector2.ZERO or is_aiming_skill or is_skill_releasing:
		return

	last_direction = get_8_direction(direction)

	if not is_attacking:
		play_walk_animation()


func get_cardinal_direction(dir: Vector2) -> Vector2:
	if dir == Vector2.ZERO:
		return Vector2.DOWN
	# Jika komponen horizontal lebih besar atau sama dengan vertikal, prioritaskan horizontal
	if abs(dir.x) >= abs(dir.y):
		return Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if dir.y > 0 else Vector2.UP

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
	if is_aiming_skill or is_skill_releasing:
		return

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
	if is_aiming_skill or is_skill_releasing:
		return

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
	# [PERBAIKAN BUG 2]: Berbasis kecepatan nyata, aktif untuk Leader dan Follower saat sprint
	if current_move_speed >= (NORMAL_SPEED * 1.35) and not is_attacking and not is_aiming_skill and not is_skill_releasing and not is_dead:
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
		# Arah atas (North, Northwest, Northeast): debu tertinggal di belakang kaki (di bawah tubuh)
		feet_y = 38.0
		lag_y = 10.0
		lag_x = 7.0
	elif absf(move_dir.y) <= 0.3:
		# Arah samping murni (West, East): sejajar kaki, trailing horizontal
		feet_y = 36.0
		lag_y = 0.0
		lag_x = 8.0
	else:
		# Arah bawah (South, Southwest, Southeast)
		feet_y = 38.0
		lag_y = 6.0
		lag_x = 6.0

	var feet_pos := global_position + Vector2(0.0, feet_y)
	var spawn_pos := feet_pos - Vector2(move_dir.x * lag_x, move_dir.y * lag_y)
	spawn_pos += Vector2(randf_range(-3.0, 3.0), randf_range(-1.5, 1.5))

	dust.global_position = spawn_pos
	dust.flip_h = randf() > 0.5
	dust.scale = Vector2(randf_range(3.5, 4.5), randf_range(3.5, 4.5))
	dust.z_index = 3 # Di bawah tubuh karakter (z_index 4) namun di atas lantai & bayangan
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
	is_moving = false


func take_damage(amount: int, source_position = null):
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
		apply_knockback(knockback_dir * 80.0)
		apply_camera_shake(3.0)
		print(name, " memblok serangan dengan perisai! 0 damage diterima.")
		return

	# [BUG 1 FIX]: Batalkan serangan dan bebaskan kontrol jika terkena hit
	cancel_skill()

	current_health -= amount
	print("Mage terkena serangan! Sisa HP: ", current_health)

	apply_knockback(knockback_dir * knockback_strength)

	modulate = Color(2.5, 0.3, 0.3)
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self) and not is_dead:
		modulate = Color.WHITE

	if current_health <= 0 and not is_dead:
		current_health = 0
		die()


func die():
	cancel_skill()
	deactivate_shield()
	if is_dead:
		return
	is_dead = true
	is_moving = false
	is_attacking = false
	in_party_combat = false
	ai_attack_timer = 0.0
	is_flanking = false
	flank_wp1 = Vector2.ZERO
	flank_wp2 = Vector2.ZERO
	flank_stage = 1
	flank_timeout = 0.0
	facing_debounce_timer = 0.0
	attack_stuck_timer = 0.0
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	print("Mage Gugur! Menunggu respawn...")

	# Auto-switch jika Leader aktif gugur
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

	visible = false
	await get_tree().create_timer(respawn_time).timeout
	respawn()


func respawn():
	deactivate_shield()
	is_flanking = false
	flank_wp1 = Vector2.ZERO
	flank_wp2 = Vector2.ZERO
	flank_stage = 1
	flank_timeout = 0.0
	facing_debounce_timer = 0.0
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
	var game_node = get_tree().current_scene
	if game_node and "current_party_command" in game_node:
		party_command = game_node.current_party_command as PartyCommand
	if game_node and "current_combat_state" in game_node:
		in_party_combat = (game_node.current_combat_state == game_node.PartyCombatState.COMBAT)
	else:
		in_party_combat = false

	if in_party_combat:
		ai_attack_timer = randf_range(0.3, 0.7)
	else:
		ai_attack_timer = 0.0
	attack_stuck_timer = 0.0
	last_movement_direction = Vector2.DOWN
	last_direction = Vector2.DOWN
	play_idle_animation()

	modulate = Color(1.0, 1.0, 1.0, 0.2)
	var respawn_tween = create_tween()
	respawn_tween.tween_property(self, "modulate:a", 1.0, 0.4)
	print("Mage berhasil respawn!")


# =========================================================
# PARTY SHIELD GUARD (DARI SKILL KNIGHT)
# =========================================================

func _setup_shield_sprite() -> void:
	if not shield_sprite or not is_instance_valid(shield_sprite):
		if has_node("ShieldSprite"):
			shield_sprite = get_node("ShieldSprite") as Sprite2D
		else:
			shield_sprite = Sprite2D.new()
			shield_sprite.name = "ShieldSprite"
			shield_sprite.texture = preload("res://assets/skills/knight/shield/shield.png")
			shield_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			shield_sprite.z_index = 6
			shield_sprite.position = SHIELD_CENTER_OFFSET
			shield_sprite.scale = Vector2(0.85, 0.85)
			shield_sprite.visible = false
			add_child(shield_sprite)
	if shield_sprite:
		shield_sprite.visible = false
		shield_sprite.modulate.a = 0.0


func grant_shield(duration: float) -> void:
	if is_dead:
		return
	is_shield_active = true
	shield_timer = duration

	_setup_shield_sprite()
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

	print(name, " menerima pelindung Shield Guard selama ", duration, " detik!")


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
	# Pelindung perisai tegak dan tepat berada di tengah tubuh karakter Mage (SHIELD_CENTER_OFFSET)
	shield_sprite.rotation = 0.0
	var float_y: float = sin(Time.get_ticks_msec() * 0.007) * 0.8
	shield_sprite.position = SHIELD_CENTER_OFFSET + Vector2(0.0, float_y)
	var pulse: float = 0.85 + sin(Time.get_ticks_msec() * 0.009) * 0.03
	shield_sprite.scale = Vector2(pulse, pulse)


# =========================================================
# SPECIAL SKILL LOGIC (METEOR STRIKE)
# =========================================================

func start_skill_aiming() -> void:
	if not is_leader or is_dead or is_aiming_skill or is_skill_releasing or is_attacking:
		return
	if skill_cooldown_timer > 0.0:
		return

	is_aiming_skill = true
	is_moving = false
	velocity = Vector2.ZERO

	var mouse_pos := get_global_mouse_position()
	var aim_dir := (mouse_pos - global_position).normalized()
	if aim_dir != Vector2.ZERO:
		skill_facing_dir = get_4_direction_str(aim_dir)
		last_direction = get_4_direction_vector(skill_facing_dir)

	animated_sprite.flip_h = false
	animated_sprite.play("skill_start_" + skill_facing_dir)

	spawn_skill_indicator()


func spawn_skill_indicator() -> void:
	if active_indicator and is_instance_valid(active_indicator):
		active_indicator.queue_free()
		active_indicator = null

	active_indicator = METEOR_INDICATOR_SCENE.instantiate()
	var cam_rect := get_camera_world_rect()
	if cam_rect.size == Vector2.ZERO:
		cam_rect = Rect2(global_position - Vector2(640, 360), Vector2(1280, 720))

	var mouse_world := get_global_mouse_position()
	var target_pos := Vector2(
		clampf(mouse_world.x, cam_rect.position.x + 24.0, cam_rect.end.x - 24.0),
		clampf(mouse_world.y, cam_rect.position.y + 24.0, cam_rect.end.y - 24.0)
	)
	active_indicator.global_position = target_pos

	if get_parent():
		get_parent().add_child(active_indicator)
	else:
		get_tree().current_scene.add_child(active_indicator)


func process_skill_aiming() -> void:
	if not active_indicator or not is_instance_valid(active_indicator):
		return

	var cam_rect := get_camera_world_rect()
	if cam_rect.size == Vector2.ZERO:
		cam_rect = Rect2(global_position - Vector2(640, 360), Vector2(1280, 720))

	var mouse_world := get_global_mouse_position()
	var target_pos := Vector2(
		clampf(mouse_world.x, cam_rect.position.x + 24.0, cam_rect.end.x - 24.0),
		clampf(mouse_world.y, cam_rect.position.y + 24.0, cam_rect.end.y - 24.0)
	)
	active_indicator.global_position = target_pos

	var aim_dir := (mouse_world - global_position).normalized()
	if aim_dir != Vector2.ZERO:
		var new_facing := get_4_direction_str(aim_dir)
		if new_facing != skill_facing_dir:
			skill_facing_dir = new_facing
			last_direction = get_4_direction_vector(skill_facing_dir)
			animated_sprite.flip_h = false
			if animated_sprite.animation.begins_with("skill_loop_"):
				animated_sprite.play("skill_loop_" + skill_facing_dir)


func execute_meteor_strike() -> void:
	if not is_aiming_skill:
		return

	var strike_pos: Vector2 = global_position
	if active_indicator and is_instance_valid(active_indicator):
		strike_pos = active_indicator.global_position
		active_indicator.queue_free()
		active_indicator = null

	is_aiming_skill = false
	is_skill_releasing = true
	skill_cooldown_timer = skill_cooldown_max

	var aim_dir := (strike_pos - global_position).normalized()
	if aim_dir != Vector2.ZERO:
		skill_facing_dir = get_4_direction_str(aim_dir)
		last_direction = get_4_direction_vector(skill_facing_dir)

	animated_sprite.flip_h = false
	animated_sprite.play("skill_release_" + skill_facing_dir)

	spawn_falling_meteor(strike_pos)


func spawn_falling_meteor(strike_pos: Vector2) -> void:
	var cam_rect := get_camera_world_rect()
	var offset_y: float = maxf(600.0, cam_rect.size.y * 1.0)
	var spawn_pos: Vector2 = strike_pos + Vector2(0.0, -offset_y)

	var meteor = METEOR_STRIKE_SCENE.instantiate()
	meteor.setup(strike_pos, self, spawn_pos)
	if get_parent():
		get_parent().add_child(meteor)
	else:
		get_tree().current_scene.add_child(meteor)


func _on_animated_sprite_animation_finished() -> void:
	if is_dead:
		return

	var current_anim: String = animated_sprite.animation
	if current_anim.begins_with("skill_start_"):
		if is_aiming_skill:
			animated_sprite.flip_h = false
			animated_sprite.play("skill_loop_" + skill_facing_dir)
		else:
			play_idle_animation()

	elif current_anim.begins_with("skill_release_"):
		is_skill_releasing = false
		if is_moving:
			play_walk_animation()
		else:
			play_idle_animation()


func get_4_direction_str(direction: Vector2) -> String:
	var angle := direction.angle()
	# Kanan (East): [-45 deg, 45 deg]
	if angle >= -PI / 4.0 and angle < PI / 4.0:
		return "e"
	# Bawah (South): [45 deg, 135 deg]
	elif angle >= PI / 4.0 and angle < 3.0 * PI / 4.0:
		return "s"
	# Atas (North): [-135 deg, -45 deg]
	elif angle >= -3.0 * PI / 4.0 and angle < -PI / 4.0:
		return "n"
	# Kiri (West): [135 deg, 180 deg] atau [-180 deg, -135 deg]
	else:
		return "w"


func get_4_direction_vector(dir_str: String) -> Vector2:
	match dir_str:
		"n": return Vector2.UP
		"s": return Vector2.DOWN
		"w": return Vector2.LEFT
		_: return Vector2.RIGHT


func get_separation_vector() -> Vector2:
	var separation := Vector2.ZERO
	var min_sep_dist: float = 55.0 # Jarak personal aman antar karakter

	# 1. Pisahkan diri dari musuh terdekat jika saling menempel
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e != self and is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			var diff: Vector2 = global_position - e.global_position
			var d: float = diff.length()
			if d < min_sep_dist:
				var push_dir: Vector2 = diff.normalized() if d > 0.5 else Vector2(1.0, 0.0)
				separation += push_dir * (min_sep_dist - d)

	# 2. Pisahkan diri dari anggota tim terdekat jika saling menumpuk
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
