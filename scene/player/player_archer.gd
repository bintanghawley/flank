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


func _ready():
	add_to_group("player")
	current_health = max_health
	spawn_position = global_position
	target_position = global_position
	play_idle_animation()
	setup_map_boundaries.call_deferred()


# =========================================================
# MOVEMENT & AUTO-ATTACK
# =========================================================

func _physics_process(delta):
	if is_dead:
		return

	# =====================================================
	# ATTACK COOLDOWN
	# =====================================================
	if attack_timer > 0.0:
		attack_timer -= delta

	# =====================================================
	# SHOOT WITH LEFT CLICK (HOLD)
	# =====================================================
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if attack_timer <= 0.0 and not is_attacking:
			shoot_towards(get_global_mouse_position())

	# =====================================================
	# HOLD RIGHT CLICK
	# =====================================================

	# Selama klik kanan ditahan,
	# target akan terus mengikuti posisi mouse
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):

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

	# Input keyboard (WASD / Tombol Panah)
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
		# Prioritas gerakan keyboard (WASD)
		is_moving = false
		target_position = global_position

		if is_attacking:
			move_velocity = Vector2.ZERO
		else:
			move_velocity = input_dir * current_speed
			update_direction_animation(input_dir)

	elif is_moving:
		# Gerakan navigasi mouse (klik kanan)
		if is_attacking:
			move_velocity = Vector2.ZERO
		else:
			var direction := global_position.direction_to(target_position)
			move_velocity = direction * current_speed
			update_direction_animation(direction)

			if global_position.distance_to(target_position) < 4.0:
				global_position = target_position
				is_moving = false
				if not is_attacking:
					play_idle_animation()
	else:
		# Saat diam dan tidak ada input gerak
		if not is_attacking and animated_sprite.animation.begins_with("walk_"):
			play_idle_animation()

	# Gabungkan kecepatan gerakan pemain dan gaya dorong knockback
	velocity = move_velocity + knockback_velocity
	move_and_slide()

	# =====================================================
	# RESPON SETELAH MELUNCUR / MENABRAK (MOUSE)
	# =====================================================
	if is_moving:
		if global_position.distance_to(target_position) < 4.0:
			global_position = target_position
			is_moving = false
			if not is_attacking:
				play_idle_animation()
		# Jika klik satu kali dan membentur rintangan (kecepatan gerak nyata tertahan)
		elif not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and get_slide_collision_count() > 0:
			if get_real_velocity().length() < 12.0:
				is_moving = false
				if not is_attacking:
					play_idle_animation()


# =========================================================
# INPUT MOUSE
# =========================================================

func _unhandled_input(event):
	if is_dead:
		return

	if event is InputEventMouseButton and event.pressed:

		# Klik kanan untuk bergerak
		if event.button_index == MOUSE_BUTTON_RIGHT:
			target_position = get_global_mouse_position()
			is_moving = true

			# Tentukan arah awal
			var direction := global_position.direction_to(target_position)
			if not is_attacking:
				update_direction_animation(direction)

		# Klik kiri untuk menembak ke arah posisi mouse
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if attack_timer <= 0.0 and not is_attacking:
				shoot_towards(get_global_mouse_position())


# =========================================================
# UPDATE ARAH ANIMASI
# =========================================================

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

		animated_sprite.play("walk_nw")
		animated_sprite.flip_h = false


	# KANAN
	elif last_direction == Vector2.RIGHT:

		animated_sprite.play("walk_se")
		animated_sprite.flip_h = false


	# DIAGONAL ↖
	elif last_direction == Vector2(-1, -1):

		animated_sprite.play("walk_nw")
		animated_sprite.flip_h = false


	# DIAGONAL ↗
	elif last_direction == Vector2(1, -1):

		animated_sprite.play("walk_nw")
		animated_sprite.flip_h = true


	# DIAGONAL ↙
	elif last_direction == Vector2(-1, 1):

		animated_sprite.play("walk_se")
		animated_sprite.flip_h = true


	# DIAGONAL ↘
	elif last_direction == Vector2(1, 1):

		animated_sprite.play("walk_se")
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

		animated_sprite.play("idle_nw")
		animated_sprite.flip_h = false


	# KANAN
	elif last_direction == Vector2.RIGHT:

		animated_sprite.play("idle_se")
		animated_sprite.flip_h = false


	# DIAGONAL ↖
	elif last_direction == Vector2(-1, -1):

		animated_sprite.play("idle_nw")
		animated_sprite.flip_h = false


	# DIAGONAL ↗
	elif last_direction == Vector2(1, -1):

		animated_sprite.play("idle_nw")
		animated_sprite.flip_h = true


	# DIAGONAL ↙
	elif last_direction == Vector2(-1, 1):

		animated_sprite.play("idle_se")
		animated_sprite.flip_h = true


	# DIAGONAL ↘
	elif last_direction == Vector2(1, 1):

		animated_sprite.play("idle_se")
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
		animated_sprite.play("atk_nw")
		animated_sprite.flip_h = false

	# KANAN
	elif last_direction == Vector2.RIGHT:
		animated_sprite.play("atk_se")
		animated_sprite.flip_h = false

	# DIAGONAL ↖
	elif last_direction == Vector2(-1, -1):
		animated_sprite.play("atk_nw")
		animated_sprite.flip_h = false

	# DIAGONAL ↗
	elif last_direction == Vector2(1, -1):
		animated_sprite.play("atk_nw")
		animated_sprite.flip_h = true

	# DIAGONAL ↙
	elif last_direction == Vector2(-1, 1):
		animated_sprite.play("atk_se")
		animated_sprite.flip_h = true

	# DIAGONAL ↘
	elif last_direction == Vector2(1, 1):
		animated_sprite.play("atk_se")
		animated_sprite.flip_h = false


# =========================================================
# COMBAT & SHOOT LOGIC (MANUAL KLIK KIRI)
# =========================================================

func get_arrow_spawn_position() -> Vector2:
	# Titik visual tengah tubuh archer (skala 5x, texture center 16.0, 16.0)
	var center_pos := global_position + Vector2(2.5, 6.0)

	# Posisi kemunculan panah dan trace tepat di depan busur keluar dari tubuh archer
	var forward_dist := 20.0
	var dir := attack_direction if attack_direction != Vector2.ZERO else last_direction
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

	is_dead = true
	is_moving = false
	is_attacking = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
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
