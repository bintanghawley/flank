extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var shield_sprite: Sprite2D = get_node_or_null("ShieldSprite")

# =========================
# PARTY SHIELD GUARD (DARI KNIGHT)
# =========================
const SHIELD_CENTER_OFFSET: Vector2 = Vector2(0.0, 4.0)
const VISUAL_CENTER_OFFSET: Vector2 = Vector2(2.5, 26.0)
# Titik tengah proyektil basic attack panah diselaraskan pas dengan busur di tangan Archer (Y diturunkan dari 26.0 menjadi 35.0)
const BASIC_ATTACK_ARROW_OFFSET: Vector2 = Vector2(2.5, 35.0)
var is_shield_active: bool = false
var shield_timer: float = 0.0
var shield_tween: Tween = null

# =========================
# PARTY / LEADER / FOLLOWER
# =========================
var is_leader: bool = true
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
		if current_skill_state != SkillState.INACTIVE:
			deactivate_skill_mode()
		is_attacking = false
		ai_attack_timer = randf_range(0.3, 0.7)
		play_idle_animation()

func cancel_skill() -> void:
	attack_token += 1
	is_attacking = false
	attack_stuck_timer = 0.0
	skill_release_queued = false

	if skill_indicator_instance and is_instance_valid(skill_indicator_instance):
		skill_indicator_instance.visible = false

	if current_skill_state != SkillState.INACTIVE:
		# Kembalikan ke READY agar Archer tidak terkunci (is_skill_locked menjadi false)
		current_skill_state = SkillState.READY
		skill_current_range = min_skill_range

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		require_mouse_release = true

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
# COMBAT / AUTO-ATTACK
# =========================

const ARROW_SCENE = preload("res://scene/projectile/arrow.tscn")
const TRACE_SCENE = preload("res://scene/projectile/arrow_trace.tscn")
const DUST_SCENE = preload("res://scene/effect/run_dust.tscn")

# =========================
# BASIC ATTACK PROJECTILE SETTINGS
# =========================
@export var controlled_projectile_speed: float = 580.0 # Kecepatan panah saat Archer dikendalikan pemain (Leader)
@export var follower_projectile_ratio: float = 1.0   # Rasio kecepatan panah saat Archer menjadi follower (disamakan 1.0 dengan Leader)

# =========================
# SPRINT DUST SETTINGS
# =========================
var dust_timer: float = 0.0
const DUST_INTERVAL: float = 0.13 # Jeda kemunculan kepulan debu saat sprint (detik)

# =========================
# SPECIAL SKILL MODE SETTINGS
# =========================
const SKILL_INDICATOR_SCENE = preload("res://scene/projectile/skill_indicator.tscn")
const SKILL_AOE_SCENE = preload("res://scene/projectile/skill_aoe_effect.tscn")

enum SkillState {
	INACTIVE,
	READY,
	STARTING,
	CHARGING,
	RELEASING
}

var current_skill_state: SkillState = SkillState.INACTIVE

@export var skill_mode_duration: float = 10.0      # Durasi mode skill (10 detik)
@export var skill_cooldown_time: float = 5.0       # Cooldown tombol E (5 detik)
@export var skill_max_charges: int = 3             # Kuota tembakan per mode skill (3 kali)
@export var min_skill_range: float = 180.0         # Jarak minimum indikator di depan karakter
@export var max_skill_range: float = 1050.0        # Jarak maksimum indikator (dibatasi 1 viewport zoom 0.65x)
@export var charge_speed: float = 680.0            # Kecepatan pertambahan jarak pengecasan (pixel/detik)
@export var skill_shot_interval: float = 0.4       # Jeda internal antar tembakan skill (detik)

var skill_mode_timer: float = 0.0
var skill_cooldown_timer: float = 0.0
var skill_charges: int = 0
var skill_interval_timer: float = 0.0

var skill_current_range: float = 0.0
var skill_aim_dir: Vector2 = Vector2.RIGHT
var skill_facing_dir: String = "e"
var skill_target_pos: Vector2 = Vector2.ZERO
var skill_indicator_instance: Node2D = null
var skill_release_queued: bool = false

@export var attack_range: float = 520.0    # Jarak jangkauan tembak ranged (pixel)
var attack_stuck_timer: float = 0.0
@export var attack_cooldown: float = 1.4   # Jeda tembakan serangan dasar (dinaikkan menjadi 1.4s agar basic attack fire rate Archer berkurang sedikit)
var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.RIGHT
var attack_token: int = 0
var require_mouse_release: bool = false

# =========================
# HEALTH & RESPAWN SETTINGS
# =========================
@export var max_health: int = 10
@export var respawn_time: float = 3.0          # Waktu tunggu respawn setelah mati (detik)
var current_health: int = 10
var is_dead: bool = false
var spawn_position: Vector2

# Node references
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# =========================
# KNOCKBACK SETTINGS
# =========================
@export var knockback_strength: float = 0.0 # Knockback dinonaktifkan saat terkena damage (0.0)
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 1400.0           # Kecepatan redaman dorongan knockback

@export var invulnerability_duration: float = 0.25 # Durasi proteksi kebal singkat setelah terkena hit (mencegah double hit)
var invulnerability_timer: float = 0.0

# =========================
# CAMERA SHAKE SETTINGS
# =========================
@export var camera_shake_strength: float = 8.0 # Kekuatan getaran kamera saat mengenai lawan
var shake_intensity: float = 0.0
var shake_decay: float = 35.0


func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	current_health = max_health
	spawn_position = global_position
	target_position = global_position
	play_idle_animation()
	_setup_shield_sprite()
	_setup_enemy_collision_exceptions.call_deferred()

	# Sambungkan sinyal selesainya animasi untuk skill cycle
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)


func _setup_enemy_collision_exceptions() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and e is CollisionObject2D:
			add_collision_exception_with(e)
			e.add_collision_exception_with(self)


func _process(delta: float):
	handle_camera_shake(delta)


func get_camera() -> Camera2D:
	if has_node("Camera2D"):
		return $Camera2D
	return get_viewport().get_camera_2d()


func apply_camera_shake(intensity: float = -1.0):
	var amount = intensity if intensity > 0.0 else camera_shake_strength
	shake_intensity = max(shake_intensity, amount)
	if get_parent() and get_parent().has_method("apply_camera_shake"):
		get_parent().apply_camera_shake(amount)


func handle_camera_shake(delta: float):
	if get_parent() and get_parent().has_method("apply_camera_shake"):
		return
	var cam: Camera2D = get_camera()
	if not cam:
		return
	if shake_intensity > 0.0:
		cam.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta)
	elif cam.offset != Vector2.ZERO:
		cam.offset = Vector2.ZERO


# =========================================================
# MOVEMENT & AUTO-ATTACK
# =========================================================

func _physics_process(delta: float):
	if is_dead:
		return

	# [PERBAIKAN BUG 5]: Reduksi knockback WAJIB dijalankan untuk SEMUA karakter
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		if knockback_velocity.length() < 8.0:
			knockback_velocity = Vector2.ZERO

	# Cooldown invulnerability frame pasca terkena serangan
	if invulnerability_timer > 0.0:
		invulnerability_timer -= delta

	# Cooldown timer serangan dasar untuk SEMUA karakter
	if attack_timer > 0.0:
		attack_timer -= delta

	# Shield timer & visual update (aktif konsisten baik sebagai Leader maupun Follower)
	if is_shield_active or (shield_sprite and shield_sprite.visible):
		if is_shield_active:
			shield_timer -= delta
			if shield_timer <= 0.0:
				deactivate_shield()
		update_shield_visual()

	# Watchdog anti-stuck is_attacking (maksimal 0.6 detik)
	if is_attacking:
		attack_stuck_timer += delta
		if attack_stuck_timer >= 0.6:
			is_attacking = false
			attack_stuck_timer = 0.0
			attack_token += 1
			if not is_moving and not is_skill_locked():
				play_idle_animation()
	else:
		attack_stuck_timer = 0.0

	if not is_leader:
		process_follower_logic(delta)
		handle_run_dust_cycle(delta)
		return

	# Reset require_mouse_release jika tombol mouse kiri sudah dilepas
	if require_mouse_release:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			require_mouse_release = false

	# =====================================================
	# SKILL MODE TIMERS & STATE UPDATES
	# =====================================================
	if skill_cooldown_timer > 0.0:
		skill_cooldown_timer -= delta

	if skill_interval_timer > 0.0:
		skill_interval_timer -= delta

	if current_skill_state != SkillState.INACTIVE:
		skill_mode_timer -= delta
		if skill_mode_timer <= 0.0:
			if current_skill_state == SkillState.READY:
				deactivate_skill_mode()
			elif current_skill_state == SkillState.STARTING or current_skill_state == SkillState.CHARGING:
				execute_skill_release()

	# Pembaruan saat sedang menahan pengecasan skill
	if current_skill_state == SkillState.CHARGING or current_skill_state == SkillState.STARTING:
		# Jika tombol mouse dilepas secara mendadak / di luar jendela
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if current_skill_state == SkillState.CHARGING:
				execute_skill_release()
			elif current_skill_state == SkillState.STARTING:
				skill_release_queued = true
				skill_current_range = min_skill_range

		# Update arah vektor tembakan mengikuti kursor mouse
		var center_pos := global_position + VISUAL_CENTER_OFFSET
		var mouse_pos := get_global_mouse_position()
		var new_aim_dir := (mouse_pos - center_pos).normalized()
		if new_aim_dir != Vector2.ZERO:
			skill_aim_dir = new_aim_dir

		# Perbarui arah animasi karakter jika berpindah kuadran
		var new_facing := get_4_direction_str(skill_aim_dir)
		if new_facing != skill_facing_dir:
			skill_facing_dir = new_facing
			last_direction = get_4_direction_vector(skill_facing_dir)
			animated_sprite.flip_h = false
			if current_skill_state == SkillState.CHARGING:
				animated_sprite.play("skill_charge_" + skill_facing_dir)

		# Pada fase CHARGING, jarak indikator bertambah secara gradual HANYA jika bukan quick-tap
		if current_skill_state == SkillState.CHARGING and not skill_release_queued:
			var max_allowed := get_max_allowed_range()
			skill_current_range = move_toward(skill_current_range, max_allowed, charge_speed * delta)
			if skill_current_range >= max_allowed:
				execute_skill_release()

		# Jika quick-tap ditandai saat STARTING, pastikan jarak tetap terkunci di min_skill_range
		if skill_release_queued:
			skill_current_range = min_skill_range

		# Update indikator: pangkal selalu menempel di center_pos dan memanjang ke arah depan
		if skill_indicator_instance and is_instance_valid(skill_indicator_instance):
			skill_target_pos = center_pos + skill_aim_dir * skill_current_range
			var max_allowed := get_max_allowed_range()
			var prog: float = (skill_current_range - min_skill_range) / max(1.0, max_allowed - min_skill_range)
			if skill_indicator_instance.has_method("update_indicator"):
				skill_indicator_instance.update_indicator(center_pos, skill_aim_dir, skill_current_range, prog)
			else:
				skill_indicator_instance.global_position = center_pos
				skill_indicator_instance.rotation = skill_aim_dir.angle()

	# =====================================================
	# ATTACK COOLDOWN (NORMAL BASIC ATTACK)
	# =====================================================
	if attack_timer > 0.0:
		attack_timer -= delta

	# =====================================================
	# SHOOT WITH LEFT CLICK (HOLD) - BASIC ATTACK
	# Hanya aktif di luar Special Skill Mode
	# =====================================================
	if current_skill_state == SkillState.INACTIVE:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not require_mouse_release and attack_timer <= 0.0 and not is_attacking:
				shoot_towards(get_global_mouse_position())

	# =====================================================
	# MOVEMENT (WASD / ARROW KEYS)
	# =====================================================
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

		if is_attacking or is_skill_locked():
			move_velocity = Vector2.ZERO
		else:
			move_velocity = input_dir * current_speed
			update_direction_animation(input_dir)

	elif is_moving:
		if is_attacking or is_skill_locked():
			move_velocity = Vector2.ZERO
		else:
			var direction := global_position.direction_to(target_position)
			last_movement_direction = direction
			move_velocity = direction * current_speed
			update_direction_animation(direction)

			if global_position.distance_to(target_position) < 4.0:
				global_position = target_position
				is_moving = false
				if not is_attacking and not is_skill_locked():
					play_idle_animation()
	else:
		if not is_attacking and not is_skill_locked() and animated_sprite.animation.begins_with("walk_"):
			play_idle_animation()

	velocity = move_velocity + knockback_velocity
	move_and_slide_with_separation()

	# [PERBAIKAN BUG 2]: Siklus debu terpusat untuk Leader
	handle_run_dust_cycle(delta)

	# =====================================================
	# RESPON SETELAH MELUNCUR / MENABRAK (MOUSE)
	# =====================================================
	if is_moving:
		if global_position.distance_to(target_position) < 4.0:
			global_position = target_position
			is_moving = false
			if not is_attacking and not is_skill_locked():
				play_idle_animation()
		elif get_slide_collision_count() > 0:
			if get_real_velocity().length() < 12.0:
				is_moving = false
				if not is_attacking and not is_skill_locked():
					play_idle_animation()


func handle_run_dust_cycle(delta: float) -> void:
	var current_move_speed := velocity.length()
	# [PERBAIKAN BUG 2]: Berbasis kecepatan nyata, aktif untuk Leader dan Follower
	if current_move_speed >= (NORMAL_SPEED * 1.35) and not is_attacking and not is_skill_locked() and not is_dead:
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
	# Titik pijakan kaki archer disesuaikan dengan arah gerak agar debu selalu menempel pas di kaki
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

	# Sedikit variasi acak agar tampak natural
	spawn_pos += Vector2(randf_range(-3.0, 3.0), randf_range(-1.5, 1.5))

	dust.global_position = spawn_pos
	dust.flip_h = randf() > 0.5
	dust.scale = Vector2(randf_range(3.5, 4.5), randf_range(3.5, 4.5))
	dust.z_index = 3 # Di bawah tubuh karakter (z_index 4) namun di atas lantai & bayangan
	get_parent().add_child(dust)


# =========================================================
# INPUT MOUSE
# =========================================================

func _unhandled_input(event: InputEvent):
	if not is_leader or is_dead:
		return

	# Pemicu Aktivasi / Deaktivasi Skill Mode (Tombol E / ui_skill)
	if is_skill_action_pressed(event):
		if can_activate_skill():
			activate_skill_mode()
		elif current_skill_state == SkillState.READY:
			deactivate_skill_mode()
		return

	# Penanganan Input Selama Dalam Mode Skill
	if current_skill_state != SkillState.INACTIVE:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					if not require_mouse_release and current_skill_state == SkillState.READY and skill_interval_timer <= 0.0 and skill_charges > 0:
						start_skill_charge()
				else:
					require_mouse_release = false
					if current_skill_state == SkillState.STARTING:
						skill_release_queued = true
						skill_current_range = min_skill_range
					elif current_skill_state == SkillState.CHARGING:
						execute_skill_release()
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				if current_skill_state == SkillState.STARTING or current_skill_state == SkillState.CHARGING:
					cancel_skill()
				elif current_skill_state == SkillState.READY:
					deactivate_skill_mode()
		return

	# Penanganan Input Mode Biasa (Basic Attack)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if not require_mouse_release and attack_timer <= 0.0 and not is_attacking:
					shoot_towards(get_global_mouse_position())
			else:
				require_mouse_release = false


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
		if knockback_velocity != Vector2.ZERO:
			velocity = knockback_velocity
			move_and_slide_with_separation()
			return
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
		if knockback_velocity == Vector2.ZERO:
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
			var approach_dir := global_position.direction_to(target_enemy.global_position)
			velocity = (approach_dir * NORMAL_SPEED) + knockback_velocity
			is_moving = true
			move_and_slide_with_separation()
			last_movement_direction = approach_dir
			apply_smoothed_facing(approach_dir, delta)
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
func update_direction_animation(direction: Vector2):

	if direction == Vector2.ZERO:
		return


	# Simpan arah terakhir
	last_direction = get_8_direction(direction)


	# Jalankan animasi walk
	play_walk_animation()


# =========================================================
# KONVERSI ARAH MENJADI 8 ARAH
# =========================================================

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


	# KANAN
	if angle >= -PI / 8 and angle < PI / 8:

		return Vector2.RIGHT


	# KANAN BAWAH ↘
	elif angle >= PI / 8 and angle < 3 * PI / 8:

		return Vector2(1, 1)


	# BAWAH
	elif angle >= 3 * PI / 8 and angle < 5 * PI / 8:

		return Vector2.DOWN


	# KIRI BAWAH ↙
	elif angle >= 5 * PI / 8 and angle < 7 * PI / 8:

		return Vector2(-1, 1)


	# KIRI
	elif angle >= 7 * PI / 8 or angle < -7 * PI / 8:

		return Vector2.LEFT


	# KIRI ATAS ↖
	elif angle >= -7 * PI / 8 and angle < -5 * PI / 8:

		return Vector2(-1, -1)


	# ATAS
	elif angle >= -5 * PI / 8 and angle < -3 * PI / 8:

		return Vector2.UP


	# KANAN ATAS ↗
	else:

		return Vector2(1, -1)


# =========================================================
# WALK ANIMATION
# =========================================================

func play_walk_animation():

	# Reset flip
	animated_sprite.flip_h = false


	# ATAS
	if last_direction == Vector2.UP:

		animated_sprite.play("walk_n")


	# BAWAH
	elif last_direction == Vector2.DOWN:

		animated_sprite.play("walk_s")


	# KIRI
	elif last_direction == Vector2.LEFT:

		animated_sprite.play("walk_w")
		animated_sprite.flip_h = false


	# KANAN
	elif last_direction == Vector2.RIGHT:

		animated_sprite.play("walk_e")
		animated_sprite.flip_h = false


	# DIAGONAL ↖
	elif last_direction == Vector2(-1, -1):

		animated_sprite.play("walk_w")
		animated_sprite.flip_h = false


	# DIAGONAL ↗
	elif last_direction == Vector2(1, -1):

		animated_sprite.play("walk_w")
		animated_sprite.flip_h = true


	# DIAGONAL ↙
	elif last_direction == Vector2(-1, 1):

		animated_sprite.play("walk_e")
		animated_sprite.flip_h = true


	# DIAGONAL ↘
	elif last_direction == Vector2(1, 1):

		animated_sprite.play("walk_e")
		animated_sprite.flip_h = false


# =========================================================
# IDLE ANIMATION
# =========================================================

func play_idle_animation():

	# Reset flip
	animated_sprite.flip_h = false


	# ATAS
	if last_direction == Vector2.UP:

		animated_sprite.play("idle_n")


	# BAWAH
	elif last_direction == Vector2.DOWN:

		animated_sprite.play("idle_s")


	# KIRI
	elif last_direction == Vector2.LEFT:

		animated_sprite.play("idle_w")
		animated_sprite.flip_h = false


	# KANAN
	elif last_direction == Vector2.RIGHT:

		animated_sprite.play("idle_e")
		animated_sprite.flip_h = false


	# DIAGONAL ↖
	elif last_direction == Vector2(-1, -1):

		animated_sprite.play("idle_w")
		animated_sprite.flip_h = false


	# DIAGONAL ↗
	elif last_direction == Vector2(1, -1):

		animated_sprite.play("idle_w")
		animated_sprite.flip_h = true


	# DIAGONAL ↙
	elif last_direction == Vector2(-1, 1):

		animated_sprite.play("idle_e")
		animated_sprite.flip_h = true


	# DIAGONAL ↘
	elif last_direction == Vector2(1, 1):

		animated_sprite.play("idle_e")
		animated_sprite.flip_h = false


# =========================================================
# ATTACK ANIMATION
# =========================================================

func play_attack_animation():

	# Reset flip
	animated_sprite.flip_h = false

	# ATAS
	if last_direction == Vector2.UP:
		animated_sprite.play("atk_n")

	# BAWAH
	elif last_direction == Vector2.DOWN:
		animated_sprite.play("atk_s")

	# KIRI
	elif last_direction == Vector2.LEFT:
		animated_sprite.play("atk_w")
		animated_sprite.flip_h = false

	# KANAN
	elif last_direction == Vector2.RIGHT:
		animated_sprite.play("atk_e")
		animated_sprite.flip_h = false

	# DIAGONAL ↖
	elif last_direction == Vector2(-1, -1):
		animated_sprite.play("atk_w")
		animated_sprite.flip_h = false

	# DIAGONAL ↗
	elif last_direction == Vector2(1, -1):
		animated_sprite.play("atk_w")
		animated_sprite.flip_h = true

	# DIAGONAL ↙
	elif last_direction == Vector2(-1, 1):
		animated_sprite.play("atk_e")
		animated_sprite.flip_h = true

	# DIAGONAL ↘
	elif last_direction == Vector2(1, 1):
		animated_sprite.play("atk_e")
		animated_sprite.flip_h = false


# =========================================================
# COMBAT & SHOOT LOGIC (MANUAL KLIK KIRI)
# =========================================================

func get_arrow_spawn_position() -> Vector2:
	# Titik visual busur panah archer di ruang dunia (diselaraskan pas dengan senjata busur di tangan)
	var bow_pos := global_position + BASIC_ATTACK_ARROW_OFFSET

	# Posisi kemunculan panah tepat di depan busur keluar dari tubuh archer
	var dir := attack_direction if attack_direction != Vector2.ZERO else last_direction
	var forward_dist := 28.0 if last_direction == Vector2.UP else 20.0
	return bow_pos + dir * forward_dist



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
	if attack_timer > 0.0 or is_attacking or is_dead:
		return

	# [BATASI SERANGAN KOSONG]: Jika karakter aktif (Leader), wajib ada musuh valid di layar & jangkauan
	if is_leader and not has_valid_attack_target():
		return

	# Hentikan pergerakan
	is_moving = false
	velocity = knockback_velocity

	# Tentukan arah tembakan saat klik (dihitung dari titik visual busur panah karakter)
	var bow_pos := global_position + BASIC_ATTACK_ARROW_OFFSET
	var dir := bow_pos.direction_to(target_pos)

	if dir == Vector2.ZERO:
		dir = last_direction

	# Simpan arah tembakan
	attack_direction = dir

	# Hadap ke arah tembakan
	last_direction = get_8_direction(dir)

	attack_token += 1
	var token := attack_token

	# Mulai animasi attack
	is_attacking = true
	play_attack_animation()

	attack_timer = attack_cooldown

	reset_attack_state(token)

func shoot_at(target: Node2D):
	if is_instance_valid(target):
		shoot_towards(target.global_position)


func get_controlled_projectile_speed() -> float:
	return controlled_projectile_speed


func get_dynamic_projectile_speed() -> float:
	if is_leader:
		return controlled_projectile_speed

	# Kecepatan panah Archer dibuat sama baik dikendalikan maupun tidak dikendalikan (580.0 px/s)
	return controlled_projectile_speed * follower_projectile_ratio


func reset_attack_state(token: int):
	# Tunggu sampai sekitar frame 3-4 dari animasi attack
	await get_tree().create_timer(0.22).timeout

	# Jika terinterupsi saat windup (terkena damage/knockback atau mati), batalkan spawn proyektil
	if is_dead or attack_token != token or not is_attacking:
		return

	# Arrow keluar saat Archer melepas busur tepat dari posisi tengah yang presisi
	var spawn_pos := get_arrow_spawn_position()

	var arrow = ARROW_SCENE.instantiate()
	arrow.global_position = spawn_pos
	arrow.direction = attack_direction
	arrow.rotation = attack_direction.angle()
	arrow.shooter_node = self
	arrow.speed = get_dynamic_projectile_speed()
	if last_direction == Vector2.UP or animated_sprite.animation == "atk_n":
		arrow.get_node("Sprite2D").z_index = 3
	else:
		arrow.get_node("Sprite2D").z_index = 5
	get_parent().add_child(arrow)

	# Spawn indicator trace arrow tepat di posisi spawn panah (dihilangkan jika menghadap North)
	if last_direction != Vector2.UP and animated_sprite.animation != "atk_n":
		var trace = TRACE_SCENE.instantiate()
		trace.global_position = spawn_pos
		trace.rotation = attack_direction.angle()
		trace.scale = Vector2(4, 4)
		trace.z_index = 10
		get_parent().add_child(trace)

	# Tunggu sampai animasi attack selesai dengan timeout cadangan agar tidak deadlock
	var timer := get_tree().create_timer(0.35)
	while is_instance_valid(self) and not is_dead and attack_token == token and animated_sprite.is_playing() and animated_sprite.animation.begins_with("atk_") and timer.time_left > 0.0:
		await get_tree().process_frame

	if is_dead or attack_token != token:
		return

	is_attacking = false
	attack_stuck_timer = 0.0

	if is_moving:
		var direction := global_position.direction_to(target_position)
		update_direction_animation(direction)
	else:
		play_idle_animation()
# =========================================================
# MENERIMA DAMAGE DARI MUSUH & KNOCKBACK
# =========================================================

func take_damage(amount: int, _source_position = null):
	if is_dead or invulnerability_timer > 0.0:
		return
	invulnerability_timer = invulnerability_duration

	# Batalkan tembakan/skill aktif agar Archer bebas bergerak
	cancel_skill()

	# Shield Guard: menahan seluruh damage serangan musuh
	if is_shield_active:
		modulate = Color(1.8, 1.8, 2.4)
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)
		apply_camera_shake(3.0)
		print(name, " memblok serangan dengan perisai! 0 damage diterima.")
		return

	current_health -= amount
	print("Archer terkena serangan! Sisa HP: ", current_health)

	# Efek kedip merah saat terkena serangan (Tween non-blocking)
	modulate = Color(2.5, 0.3, 0.3)
	var hit_tween = create_tween()
	hit_tween.tween_property(self, "modulate", Color.WHITE, 0.12)

	# Cek kematian jika darah habis
	if current_health <= 0 and not is_dead:
		current_health = 0
		die()


# =========================================================
# KEMATIAN & RESPAWN ARCHER
# =========================================================

func die():
	attack_token += 1
	deactivate_shield()
	if is_dead:
		return

	# Batalkan mode skill dan bersihkan indikator bila archer gugur
	if current_skill_state != SkillState.INACTIVE:
		deactivate_skill_mode()

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
	invulnerability_timer = 0.0
	shake_intensity = 0.0
	var cam: Camera2D = get_camera()
	if cam:
		cam.offset = Vector2.ZERO
	print("Archer Kalah! Menunggu respawn...")

	# Auto-switch jika Leader aktif gugur
	if is_leader:
		var game_node = get_tree().current_scene
		if not game_node or not game_node.has_method("switch_to_next_character"):
			if get_parent() and get_parent().has_method("switch_to_next_character"):
				game_node = get_parent()
		if game_node and game_node.has_method("switch_to_next_character"):
			game_node.switch_to_next_character()

	# Matikan tabrakan dan keluarkan sementara dari grup player
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	remove_from_group("player")

	# Efek visual kekalahan: karakter memudar (fade-out)
	var death_tween = create_tween()
	death_tween.tween_property(self, "modulate", Color(0.8, 0.2, 0.2, 0.0), 0.5)
	await death_tween.finished

	visible = false

	# Tunggu waktu respawn
	await get_tree().create_timer(respawn_time).timeout

	# Bangkitkan kembali archer
	respawn()


func respawn():
	deactivate_shield()
	is_flanking = false
	flank_wp1 = Vector2.ZERO
	flank_wp2 = Vector2.ZERO
	flank_stage = 1
	flank_timeout = 0.0
	facing_debounce_timer = 0.0
	# Kembalikan ke posisi awal saat game dimulai
	global_position = spawn_position
	target_position = spawn_position
	current_health = max_health
	is_moving = false
	is_attacking = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	invulnerability_timer = 0.0

	# Reset pergerakan kamera agar langsung fokus tanpa lag panning
	var cam: Camera2D = get_camera()
	if cam:
		cam.reset_smoothing()

	# Nyalakan kembali tabrakan dan masukkan kembali ke grup player
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	add_to_group("player")

	# Tampilkan kembali karakter
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

	# Efek fade-in halus saat bangkit kembali
	modulate = Color(1.0, 1.0, 1.0, 0.2)
	var respawn_tween = create_tween()
	respawn_tween.tween_property(self, "modulate:a", 1.0, 0.4)

	print("Archer berhasil respawn di titik awal! HP penuh: ", current_health)


func apply_knockback(force: Vector2):
	if force == Vector2.ZERO:
		return
	knockback_velocity = force
	is_moving = false


# =========================================================
# ARCHER SPECIAL SKILL MODE METHODS
# =========================================================

func is_skill_action_pressed(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_skill"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			return true
	return false


func can_activate_skill() -> bool:
	return (not is_dead and 
			not is_attacking and 
			skill_cooldown_timer <= 0.0 and 
			current_skill_state == SkillState.INACTIVE)


func is_skill_locked() -> bool:
	return (current_skill_state == SkillState.STARTING or 
			current_skill_state == SkillState.CHARGING or 
			current_skill_state == SkillState.RELEASING)


func activate_skill_mode():
	current_skill_state = SkillState.READY
	skill_charges = skill_max_charges
	skill_mode_timer = skill_mode_duration
	skill_interval_timer = 0.0
	skill_release_queued = false

	# Buat/instansiasi node indikator namun sembunyikan sampai klik kiri ditekan
	if skill_indicator_instance == null or not is_instance_valid(skill_indicator_instance):
		skill_indicator_instance = SKILL_INDICATOR_SCENE.instantiate()
		skill_indicator_instance.visible = false
		get_parent().add_child(skill_indicator_instance)
	else:
		skill_indicator_instance.visible = false

	print("Special Skill Mode Aktif! Kuota tembakan: ", skill_charges, " | Durasi: ", skill_mode_duration, " detik")


func deactivate_skill_mode():
	current_skill_state = SkillState.INACTIVE
	skill_charges = 0
	skill_mode_timer = 0.0
	skill_release_queued = false

	# Bersihkan node indikator jika masih ada di scene tree
	if skill_indicator_instance and is_instance_valid(skill_indicator_instance):
		skill_indicator_instance.queue_free()
		skill_indicator_instance = null

	# Mulai Cooldown Skill selama 5.0 detik
	skill_cooldown_timer = skill_cooldown_time
	print("Special Skill Mode Selesai! Cooldown: ", skill_cooldown_time, " detik")

	# Kembalikan mode serangan ke panah biasa dan reset status animasi
	if not is_dead and not is_attacking:
		if is_moving:
			play_walk_animation()
		else:
			play_idle_animation()


func start_skill_charge():
	current_skill_state = SkillState.STARTING
	skill_release_queued = false

	# Karakter langsung berhenti dan terkunci
	is_moving = false
	velocity = Vector2.ZERO
	target_position = global_position

	# Tentukan arah hadap berdasarkan sudut posisi kursor mouse
	var center_pos := global_position + VISUAL_CENTER_OFFSET
	var mouse_pos := get_global_mouse_position()
	var dir := (mouse_pos - center_pos).normalized()
	if dir != Vector2.ZERO:
		skill_aim_dir = dir
	else:
		skill_aim_dir = last_direction

	skill_facing_dir = get_4_direction_str(skill_aim_dir)
	last_direction = get_4_direction_vector(skill_facing_dir)

	# Jarak minimum indikator di depan karakter
	skill_current_range = min_skill_range
	skill_target_pos = center_pos + skill_aim_dir * skill_current_range

	# Munculkan skill_indicator: pangkal menempel di center_pos dan memanjang ke arah depan
	if skill_indicator_instance and is_instance_valid(skill_indicator_instance):
		if skill_indicator_instance.has_method("update_indicator"):
			skill_indicator_instance.update_indicator(center_pos, skill_aim_dir, skill_current_range, 0.0)
		else:
			skill_indicator_instance.global_position = center_pos
			skill_indicator_instance.rotation = skill_aim_dir.angle()
		skill_indicator_instance.visible = true

	# Putar animasi karakter: skill_start_{direction}
	animated_sprite.flip_h = false
	animated_sprite.play("skill_start_" + skill_facing_dir)


func execute_skill_release():
	if current_skill_state == SkillState.RELEASING or is_dead:
		return

	current_skill_state = SkillState.RELEASING

	# Pastikan saat quick-tap, nilai skill_current_range benar-benar terkunci pada min_skill_range
	if skill_release_queued:
		skill_current_range = min_skill_range

	var center_pos := global_position + VISUAL_CENTER_OFFSET

	# Pastikan indikator terupdate tepat pada posisi dan jarak rilis sebelum mengambil get_tip_position
	if skill_indicator_instance and is_instance_valid(skill_indicator_instance) and skill_indicator_instance.has_method("update_indicator"):
		var max_allowed := get_max_allowed_range()
		var prog: float = (skill_current_range - min_skill_range) / max(1.0, max_allowed - min_skill_range)
		skill_indicator_instance.update_indicator(center_pos, skill_aim_dir, skill_current_range, prog)

	# Kunci posisi target akhir dari ujung panah indikator
	var final_target_pos: Vector2
	if skill_indicator_instance and is_instance_valid(skill_indicator_instance) and skill_indicator_instance.has_method("get_tip_position"):
		final_target_pos = skill_indicator_instance.get_tip_position()
	else:
		final_target_pos = center_pos + skill_aim_dir * skill_current_range
	var final_aim_dir := skill_aim_dir
	var final_facing := skill_facing_dir

	# Sembunyikan indikator
	if skill_indicator_instance and is_instance_valid(skill_indicator_instance):
		skill_indicator_instance.visible = false

	# 1. Putar animasi skill_release_{direction} pada karakter
	animated_sprite.flip_h = false
	animated_sprite.play("skill_release_" + final_facing)

	# 2. Spawn skill_aoe_effect.tscn menutupi seluruh jalur serangan sampai ujung indikator
	var aoe_effect = SKILL_AOE_SCENE.instantiate()
	if aoe_effect.has_method("setup"):
		aoe_effect.setup(center_pos, final_aim_dir, skill_current_range)
	else:
		aoe_effect.global_position = final_target_pos
		aoe_effect.rotation = final_aim_dir.angle()
	get_parent().add_child(aoe_effect)

	# Efek getaran kamera saat skill dilepaskan
	apply_camera_shake(6.0)


func on_skill_release_finished():
	if is_dead:
		return

	skill_release_queued = false
	skill_current_range = min_skill_range

	# Kurangi kuota tembakan
	skill_charges -= 1
	print("Tembakan skill berhasil dilepas! Sisa kuota: ", skill_charges)

	# Berikan jeda waktu / internal cooldown (0.4 detik) sebelum pemain bisa mulai klik kiri lagi
	skill_interval_timer = skill_shot_interval

	# Cek apakah kuota habis
	if skill_charges <= 0:
		deactivate_skill_mode()
	else:
		# Karakter kembali bisa bergerak bebas
		current_skill_state = SkillState.READY
		if is_moving:
			play_walk_animation()
		else:
			play_idle_animation()


func _on_animated_sprite_animation_finished():
	if is_dead:
		return

	if current_skill_state == SkillState.STARTING:
		if skill_release_queued or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			# Jika klik cepat (tanpa tahan), kunci pada min_skill_range dan langsung release
			skill_release_queued = true
			skill_current_range = min_skill_range
			execute_skill_release()
		else:
			# Transisi ke animasi loop: skill_charge_{direction}
			current_skill_state = SkillState.CHARGING
			animated_sprite.flip_h = false
			animated_sprite.play("skill_charge_" + skill_facing_dir)

	elif current_skill_state == SkillState.RELEASING:
		on_skill_release_finished()


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


func get_max_allowed_range() -> float:
	var allowed := max_skill_range
	var vp := get_viewport()
	if vp:
		var cam := vp.get_camera_2d()
		var v_size: Vector2 = vp.get_visible_rect().size
		var max_vp_dist: float = max(v_size.x, v_size.y)
		if cam:
			var cam_zoom: Vector2 = cam.zoom
			if cam_zoom.x > 0.0 and cam_zoom.y > 0.0:
				max_vp_dist = max(v_size.x / cam_zoom.x, v_size.y / cam_zoom.y)
		allowed = min(allowed, max_vp_dist)
	return allowed


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
	# Pelindung perisai tegak dan tepat berada di tengah tubuh karakter Archer (SHIELD_CENTER_OFFSET)
	shield_sprite.rotation = 0.0
	var float_y: float = sin(Time.get_ticks_msec() * 0.007) * 0.8
	shield_sprite.position = SHIELD_CENTER_OFFSET + Vector2(0.0, float_y)
	var pulse: float = 0.85 + sin(Time.get_ticks_msec() * 0.009) * 0.03
	shield_sprite.scale = Vector2(pulse, pulse)


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
