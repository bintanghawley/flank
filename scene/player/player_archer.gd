extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D

# =========================
# MOVEMENT SETTINGS
# =========================

const NORMAL_SPEED := 128.0
const SPRINT_SPEED := 220.0

var target_position: Vector2
var is_moving := false

# Arah terakhir karakter
var last_direction := Vector2.DOWN

# =========================
# COMBAT / AUTO-ATTACK
# =========================

const ARROW_SCENE = preload("res://scene/projectile/arrow.tscn")
const TRACE_SCENE = preload("res://scene/projectile/arrow_trace.tscn")
const DUST_SCENE = preload("res://scene/effect/run_dust.tscn")

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
@export var max_skill_range: float = 650.0         # Jarak maksimum indikator (dibatasi 1 viewport)
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

@export var attack_range: float = 300.0    # Jarak jangkauan tembak otomatis (pixel)
@export var attack_cooldown: float = 0.8   # Jeda tembakan (0.8 detik)
var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.RIGHT

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
@export var knockback_strength: float = 380.0 # Kekuatan dorongan saat terkena hit
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 1400.0           # Kecepatan redaman dorongan knockback

# =========================
# CAMERA SHAKE SETTINGS
# =========================
@export var camera_shake_strength: float = 8.0 # Kekuatan getaran kamera saat mengenai lawan
var shake_intensity: float = 0.0
var shake_decay: float = 35.0


func _ready():
	add_to_group("player")
	current_health = max_health
	spawn_position = global_position
	target_position = global_position
	play_idle_animation()
	setup_map_boundaries.call_deferred()

	# Sambungkan sinyal selesainya animasi untuk skill cycle
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)


func _process(delta: float):
	handle_camera_shake(delta)


func apply_camera_shake(intensity: float = -1.0):
	var amount = intensity if intensity > 0.0 else camera_shake_strength
	shake_intensity = max(shake_intensity, amount)


func handle_camera_shake(delta: float):
	if not has_node("Camera2D"):
		return
	var cam: Camera2D = $Camera2D
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
		var center_pos := global_position + Vector2(2.5, 6.0)
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
			if attack_timer <= 0.0 and not is_attacking:
				shoot_towards(get_global_mouse_position())

	# =====================================================
	# HOLD RIGHT CLICK
	# =====================================================
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if not is_skill_locked():
			target_position = get_global_mouse_position()
			if global_position.distance_to(target_position) > 2.0:
				is_moving = true

	# =====================================================
	# KNOCKBACK DECAY
	# =====================================================
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)

	# =====================================================
	# MOVEMENT (WASD / ARROW KEYS / MOUSE)
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
	move_and_slide()

	# =====================================================
	# EFEK DEBU SAAT SPRINT (SHIFT)
	# =====================================================
	var is_sprinting := Input.is_key_pressed(KEY_SHIFT)
	if is_sprinting and move_velocity != Vector2.ZERO and not is_attacking and not is_skill_locked() and not is_dead:
		dust_timer -= delta
		if dust_timer <= 0.0:
			dust_timer = DUST_INTERVAL
			spawn_run_dust(move_velocity.normalized())
	else:
		dust_timer = 0.0

	# =====================================================
	# RESPON SETELAH MELUNCUR / MENABRAK (MOUSE)
	# =====================================================
	if is_moving:
		if global_position.distance_to(target_position) < 4.0:
			global_position = target_position
			is_moving = false
			if not is_attacking and not is_skill_locked():
				play_idle_animation()
		elif not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and get_slide_collision_count() > 0:
			if get_real_velocity().length() < 12.0:
				is_moving = false
				if not is_attacking and not is_skill_locked():
					play_idle_animation()


func spawn_run_dust(move_dir: Vector2):
	if not get_parent():
		return

	var dust = DUST_SCENE.instantiate()
	# Titik pijakan kaki archer disesuaikan dengan arah gerak agar debu selalu menempel pas di kaki
	var feet_y: float = 28.0
	var lag_x: float = 5.0
	var lag_y: float = 2.0

	if move_dir.y < -0.3:
		# Arah atas (North, Northwest, Northeast): kaki visual lebih tinggi
		feet_y = 26.0
		lag_y = 2.0
	elif absf(move_dir.y) <= 0.3:
		# Arah samping murni (West, East): sejajar kaki, trailing horizontal
		feet_y = 28.0
		lag_y = 0.0
	else:
		# Arah bawah (South, Southwest, Southeast)
		feet_y = 32.0
		lag_y = 4.0

	var feet_pos := global_position + Vector2(1.5, feet_y)
	var spawn_pos := feet_pos - Vector2(move_dir.x * lag_x, move_dir.y * lag_y)

	# Sedikit variasi acak agar tampak natural
	spawn_pos += Vector2(randf_range(-3.0, 3.0), randf_range(-1.5, 1.5))

	dust.global_position = spawn_pos
	dust.flip_h = randf() > 0.5
	dust.scale = Vector2(randf_range(3.5, 4.5), randf_range(3.5, 4.5))
	dust.z_index = 2 # Di bawah tubuh karakter (z_index 4)
	get_parent().add_child(dust)


# =========================================================
# INPUT MOUSE
# =========================================================

func _unhandled_input(event: InputEvent):
	if is_dead:
		return

	# Pemicu Aktivasi Skill Mode (Tombol E / ui_skill)
	if is_skill_action_pressed(event):
		if can_activate_skill():
			activate_skill_mode()
		return

	# Penanganan Input Selama Dalam Mode Skill
	if current_skill_state != SkillState.INACTIVE:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					if current_skill_state == SkillState.READY and skill_interval_timer <= 0.0 and skill_charges > 0:
						start_skill_charge()
				else:
					if current_skill_state == SkillState.STARTING:
						skill_release_queued = true
						skill_current_range = min_skill_range
					elif current_skill_state == SkillState.CHARGING:
						execute_skill_release()

			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				if not is_skill_locked():
					target_position = get_global_mouse_position()
					is_moving = true
					var direction := global_position.direction_to(target_position)
					update_direction_animation(direction)
		return

	# Penanganan Input Mode Biasa (Basic Attack & Walk)
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
	# Titik visual tengah tubuh archer (skala 5x, texture center 16.0, 16.0)
	var center_pos := global_position + Vector2(2.5, 6.0)

	# Posisi kemunculan panah tepat di depan busur keluar dari tubuh archer
	var dir := attack_direction if attack_direction != Vector2.ZERO else last_direction
	var forward_dist := 28.0 if last_direction == Vector2.UP else 20.0
	return center_pos + dir * forward_dist


func shoot_towards(target_pos: Vector2):
	if attack_timer > 0.0 or is_attacking:
		return

	# Hentikan pergerakan
	is_moving = false
	velocity = Vector2.ZERO

	# Tentukan arah tembakan saat klik (dihitung dari titik visual tengah karakter)
	var center_pos := global_position + Vector2(2.5, 6.0)
	var dir := center_pos.direction_to(target_pos)

	if dir == Vector2.ZERO:
		dir = last_direction

	# Simpan arah tembakan
	attack_direction = dir

	# Hadap ke arah tembakan
	last_direction = get_8_direction(dir)

	# Mulai animasi attack
	is_attacking = true
	play_attack_animation()

	attack_timer = attack_cooldown

	reset_attack_state()

func shoot_at(target: Node2D):
	if is_instance_valid(target):
		shoot_towards(target.global_position)


func reset_attack_state():
	# Tunggu sampai sekitar frame 3-4 dari animasi attack
	await get_tree().create_timer(0.22).timeout

	if is_dead:
		return

	# Arrow keluar saat Archer melepas busur tepat dari posisi tengah yang presisi
	var spawn_pos := get_arrow_spawn_position()

	var arrow = ARROW_SCENE.instantiate()
	arrow.global_position = spawn_pos
	arrow.direction = attack_direction
	arrow.rotation = attack_direction.angle()
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

	# Tunggu sampai animasi attack selesai
	await animated_sprite.animation_finished

	if is_dead:
		return

	is_attacking = false

	if is_moving:
		var direction := global_position.direction_to(target_position)
		update_direction_animation(direction)
	else:
		play_idle_animation()
# =========================================================
# MENERIMA DAMAGE DARI MUSUH & KNOCKBACK
# =========================================================

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO):
	if is_dead:
		return

	current_health -= amount
	print("Archer terkena serangan! Sisa HP: ", current_health)

	# Tentukan arah dorongan knockback (menjauh dari sumber serangan)
	var knockback_dir := Vector2.ZERO
	if source_position != Vector2.ZERO and source_position != global_position:
		knockback_dir = source_position.direction_to(global_position)
	else:
		# Jika posisi sumber tidak diketahui, dorong ke belakang arah hadap
		knockback_dir = -last_direction

	# Terapkan gaya dorong knockback
	apply_knockback(knockback_dir * knockback_strength)

	# Efek kedip merah saat terkena serangan
	modulate = Color(2.5, 0.3, 0.3)
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self) and not is_dead:
		modulate = Color.WHITE

	# Cek kematian jika darah habis
	if current_health <= 0 and not is_dead:
		current_health = 0
		die()


# =========================================================
# KEMATIAN & RESPAWN ARCHER
# =========================================================

func die():
	if is_dead:
		return

	# Batalkan mode skill dan bersihkan indikator bila archer gugur
	if current_skill_state != SkillState.INACTIVE:
		current_skill_state = SkillState.INACTIVE
		skill_charges = 0
		skill_mode_timer = 0.0
		if skill_indicator_instance and is_instance_valid(skill_indicator_instance):
			skill_indicator_instance.queue_free()
			skill_indicator_instance = null

	is_dead = true
	is_moving = false
	is_attacking = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	shake_intensity = 0.0
	if has_node("Camera2D"):
		$Camera2D.offset = Vector2.ZERO
	print("Archer Kalah! Menunggu respawn...")

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
	# Kembalikan ke posisi awal saat game dimulai
	global_position = spawn_position
	target_position = spawn_position
	current_health = max_health
	is_moving = false
	is_attacking = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO

	# Reset pergerakan kamera agar langsung fokus tanpa lag panning
	if has_node("Camera2D"):
		$Camera2D.reset_smoothing()

	# Nyalakan kembali tabrakan dan masukkan kembali ke grup player
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	add_to_group("player")

	# Tampilkan kembali karakter
	visible = true
	is_dead = false
	play_idle_animation()

	# Efek fade-in halus saat bangkit kembali
	modulate = Color(1.0, 1.0, 1.0, 0.2)
	var respawn_tween = create_tween()
	respawn_tween.tween_property(self, "modulate:a", 1.0, 0.4)

	print("Archer berhasil respawn di titik awal! HP penuh: ", current_health)


# =========================================================
# BATASAN MAP & KAMERA OTOMATIS (WORLD BORDERS)
# =========================================================

func setup_map_boundaries():
	if not get_parent():
		return

	var ground = get_parent().get_node_or_null("Ground") as TileMapLayer
	if not ground:
		ground = get_parent().get_node_or_null("map_region1/Ground") as TileMapLayer
	if not ground:
		ground = get_parent().find_child("Ground", true, false) as TileMapLayer
	if not ground:
		return

	var rect: Rect2i = ground.get_used_rect()
	if rect.size == Vector2i.ZERO:
		return

	# Dapatkan batas koordinat dunia (pixel) dari layer Ground
	var map_min: Vector2 = ground.to_global(Vector2(rect.position.x * 16.0, rect.position.y * 16.0))
	var map_max: Vector2 = ground.to_global(Vector2((rect.position.x + rect.size.x) * 16.0, (rect.position.y + rect.size.y) * 16.0))

	# 1. Sesuaikan batasan Camera2D persis ke tepi map
	if has_node("Camera2D"):
		var cam: Camera2D = $Camera2D
		cam.limit_left = int(map_min.x)
		cam.limit_top = int(map_min.y)
		cam.limit_right = int(map_max.x)
		cam.limit_bottom = int(map_max.y)

	# 2. Buat pembatas fisik (invisible walls) di sekeliling tepi peta
	if not get_parent().has_node("WorldBorders"):
		var borders := StaticBody2D.new()
		borders.name = "WorldBorders"
		borders.collision_layer = 1
		borders.collision_mask = 0

		var thickness := 80.0
		var width := map_max.x - map_min.x
		var height := map_max.y - map_min.y

		# Dinding Atas
		_create_wall_shape(borders, Vector2(map_min.x + width / 2.0, map_min.y - thickness / 2.0), Vector2(width + thickness * 2.0, thickness))
		# Dinding Bawah
		_create_wall_shape(borders, Vector2(map_min.x + width / 2.0, map_max.y + thickness / 2.0), Vector2(width + thickness * 2.0, thickness))
		# Dinding Kiri
		_create_wall_shape(borders, Vector2(map_min.x - thickness / 2.0, map_min.y + height / 2.0), Vector2(thickness, height + thickness * 2.0))
		# Dinding Kanan
		_create_wall_shape(borders, Vector2(map_max.x + thickness / 2.0, map_min.y + height / 2.0), Vector2(thickness, height + thickness * 2.0))

		get_parent().call_deferred("add_child", borders)


func _create_wall_shape(parent: Node2D, pos: Vector2, size: Vector2):
	var col := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	col.shape = rect_shape
	col.position = pos
	parent.add_child(col)


func apply_knockback(force: Vector2):
	knockback_velocity = force
	# Batalkan pergerakan mouse klik satu kali agar dorongan terasa nyata
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
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
	var center_pos := global_position + Vector2(2.5, 6.0)
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

	var center_pos := global_position + Vector2(2.5, 6.0)

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
