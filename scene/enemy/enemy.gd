extends CharacterBody2D

# =========================
# STATS & SETTINGS
# =========================
@export var max_health: int = 5
@export var wander_speed: float = 40.0
@export var chase_speed: float = 75.0
@export var patrol_radius: float = 140.0
@export var contact_damage: int = 1
@export var attack_cooldown: float = 1.0  # Jeda memberi damage saat menyentuh player
@export var respawn_time: float = 4.0     # Waktu tunggu respawn setelah mati (detik)

# =========================
# RANGED ATTACK / TEMBAKAN MUSUH
# =========================
const ARROW_SCENE = preload("res://scene/projectile/arrow.tscn")

@export var shoot_range: float = 320.0       # Jarak tembak musuh (pixel)
@export var shoot_cooldown: float = 1.6     # Cooldown tembakan musuh (detik)
@export var projectile_damage: int = 1      # Damage panah musuh
@export var projectile_speed: float = 380.0 # Kecepatan panah musuh

var shoot_timer: float = 0.0
var is_shooting: bool = false

var current_health: int
var player: CharacterBody2D = null
var is_dead: bool = false

# Arah terakhir musuh (8 arah)
var last_direction := Vector2.DOWN

# State AI Musuh
enum State { IDLE_PATROL, CHASE }
var current_state = State.IDLE_PATROL

# Variabel Patroli Acak
var spawn_position: Vector2
var wander_target: Vector2
var wander_timer: float = 0.0

# Variabel Kontak & Serangan
var damage_timer: float = 0.0
var is_touching_player: bool = false

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar
@onready var damage_bar: ProgressBar = $DamageBar
@onready var detection_area: Area2D = $DetectionArea
@onready var hitbox: Area2D = $Hitbox
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var damage_tween: Tween = null


func _ready():
	add_to_group("enemy")
	current_health = max_health
	spawn_position = global_position
	wander_target = spawn_position
	shoot_timer = randf_range(0.5, shoot_cooldown)

	setup_health_bar()
	play_idle_animation()

	# Hubungkan sinyal deteksi & hitbox secara otomatis
	if detection_area and not detection_area.body_entered.is_connected(_on_detection_area_body_entered):
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

	if hitbox and not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.body_exited.connect(_on_hitbox_body_exited)


func setup_health_bar():
	# Konfigurasi Bar Belakang (Damage Bar / Buffer yang menunjukkan darah yang hilang)
	if damage_bar:
		damage_bar.max_value = max_health
		damage_bar.value = current_health
		damage_bar.show_percentage = false

		# Background bar warna gelap
		var style_bg = StyleBoxFlat.new()
		style_bg.bg_color = Color(0.1, 0.1, 0.1, 0.85)
		style_bg.set_corner_radius_all(1)

		# Warna isi damage bar (kuning keemasan terang untuk indikator damage)
		var style_damage_fill = StyleBoxFlat.new()
		style_damage_fill.bg_color = Color(1.0, 0.85, 0.3, 0.95)
		style_damage_fill.set_corner_radius_all(1)

		damage_bar.add_theme_stylebox_override("background", style_bg)
		damage_bar.add_theme_stylebox_override("fill", style_damage_fill)

	# Konfigurasi Bar Depan (Health Bar utama warna merah)
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.show_percentage = false

		# Background transparan agar damage bar di belakangnya kelihatan saat darah berkurang
		health_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())

		# Isi bar warna merah terang
		var style_fill = StyleBoxFlat.new()
		style_fill.bg_color = Color(0.9, 0.2, 0.2, 0.95)
		style_fill.set_corner_radius_all(1)

		health_bar.add_theme_stylebox_override("fill", style_fill)


func _physics_process(delta):
	if is_dead:
		return

	# ---------------------------------------------------------
	# 1. LOGIKA GERAKAN & SERANGAN TEMBAK
	# ---------------------------------------------------------
	if current_state == State.CHASE and player != null and is_instance_valid(player):
		# Jika player mati atau keluar dari grup player, musuh berhenti mengejar
		if ("is_dead" in player and player.is_dead) or not player.is_in_group("player"):
			player = null
			current_state = State.IDLE_PATROL
			return

		var dist = global_position.distance_to(player.global_position)
		var dir = global_position.direction_to(player.global_position)

		# Hitung mundur cooldown tembak
		shoot_timer -= delta

		# Jika dalam jangkauan tembak dan cooldown siap, tembak player!
		if dist <= shoot_range and shoot_timer <= 0.0 and not is_shooting:
			shoot_at_player()

		# Saat animasi menembak, musuh berhenti melangkah (seperti archer pemain)
		if is_shooting:
			velocity = Vector2.ZERO
		else:
			# Jika masih jauh dari jangkauan tembak ideal, dekati player
			if dist > 180.0:
				velocity = dir * chase_speed
				update_direction_animation(dir)
			else:
				# Berhenti di jarak tembak yang pas dan hadap player
				velocity = Vector2.ZERO
				last_direction = get_8_direction(dir)
				play_idle_animation()

	else:
		# Patroli mutar-mutar santai di area
		handle_idle_patrol(delta)

	move_and_slide()

	# ---------------------------------------------------------
	# 2. LOGIKA DAMAGE SAAT MENYENTUH ARCHER
	# ---------------------------------------------------------
	damage_timer -= delta
	if is_touching_player and player != null and is_instance_valid(player):
		if ("is_dead" in player and player.is_dead) or not player.is_in_group("player"):
			is_touching_player = false
		elif damage_timer <= 0.0:
			if player.has_method("take_damage"):
				player.take_damage(contact_damage, global_position)
			damage_timer = attack_cooldown


func handle_idle_patrol(delta):
	wander_timer -= delta

	# Pilih titik acak baru setiap beberapa detik
	if wander_timer <= 0.0:
		var random_offset = Vector2(
			randf_range(-patrol_radius, patrol_radius),
			randf_range(-patrol_radius, patrol_radius)
		)
		wander_target = spawn_position + random_offset
		wander_timer = randf_range(2.5, 4.5)

	# Berjalan menuju titik target patroli
	if global_position.distance_to(wander_target) > 8.0:
		var dir = global_position.direction_to(wander_target)
		velocity = dir * wander_speed
		update_direction_animation(dir)
	else:
		# Berhenti sejenak jika sudah sampai
		velocity = Vector2.ZERO
		if not is_shooting:
			play_idle_animation()


# =========================================================
# RANGED ATTACK LOGIC (MENEMBAK PLAYER)
# =========================================================

func shoot_at_player():
	if player == null or not is_instance_valid(player) or is_dead or is_shooting:
		return

	is_shooting = true
	var dir = global_position.direction_to(player.global_position)

	# Arah hadap ke player dan mainkan animasi serang sesuai arah
	last_direction = get_8_direction(dir)
	play_attack_animation()

	# Munculkan panah musuh
	var arrow = ARROW_SCENE.instantiate()
	arrow.global_position = global_position
	arrow.direction = dir
	arrow.rotation = dir.angle()
	arrow.shooter_group = "enemy"
	arrow.speed = projectile_speed
	arrow.damage = projectile_damage
	arrow.modulate = Color(1.8, 0.4, 0.4) # Warna kemerahan agar jelas panah musuh
	get_parent().add_child(arrow)

	shoot_timer = shoot_cooldown

	# Tunggu durasi animasi menembak selesai (~0.35 detik), lalu kembali ke idle
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(self) and not is_dead:
		is_shooting = false
		if current_state == State.CHASE and player != null and is_instance_valid(player):
			var chase_dir = global_position.direction_to(player.global_position)
			last_direction = get_8_direction(chase_dir)
		play_idle_animation()


# =========================================================
# UPDATE ARAH ANIMASI
# =========================================================

func update_direction_animation(direction: Vector2):
	if direction == Vector2.ZERO:
		return
	last_direction = get_8_direction(direction)
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
# WALK ANIMATION (8 ARAH)
# =========================================================

func play_walk_animation():
	if not animated_sprite:
		return
	animated_sprite.flip_h = false

	if last_direction == Vector2.UP:
		animated_sprite.play("walk_n")
	elif last_direction == Vector2.DOWN:
		animated_sprite.play("walk_s")
	elif last_direction == Vector2.LEFT:
		animated_sprite.play("walk_nw")
		animated_sprite.flip_h = false
	elif last_direction == Vector2.RIGHT:
		animated_sprite.play("walk_se")
		animated_sprite.flip_h = false
	elif last_direction == Vector2(-1, -1):
		animated_sprite.play("walk_nw")
		animated_sprite.flip_h = false
	elif last_direction == Vector2(1, -1):
		animated_sprite.play("walk_nw")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(-1, 1):
		animated_sprite.play("walk_se")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(1, 1):
		animated_sprite.play("walk_se")
		animated_sprite.flip_h = false


# =========================================================
# IDLE ANIMATION (8 ARAH)
# =========================================================

func play_idle_animation():
	if not animated_sprite:
		return
	animated_sprite.flip_h = false

	if last_direction == Vector2.UP:
		animated_sprite.play("idle_n")
	elif last_direction == Vector2.DOWN:
		animated_sprite.play("idle_s")
	elif last_direction == Vector2.LEFT:
		animated_sprite.play("idle_nw")
		animated_sprite.flip_h = false
	elif last_direction == Vector2.RIGHT:
		animated_sprite.play("idle_se")
		animated_sprite.flip_h = false
	elif last_direction == Vector2(-1, -1):
		animated_sprite.play("idle_nw")
		animated_sprite.flip_h = false
	elif last_direction == Vector2(1, -1):
		animated_sprite.play("idle_nw")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(-1, 1):
		animated_sprite.play("idle_se")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(1, 1):
		animated_sprite.play("idle_se")
		animated_sprite.flip_h = false


# =========================================================
# ATTACK ANIMATION (8 ARAH)
# =========================================================

func play_attack_animation():
	if not animated_sprite:
		return
	animated_sprite.flip_h = false

	if last_direction == Vector2.UP:
		animated_sprite.play("atk_n")
	elif last_direction == Vector2.DOWN:
		animated_sprite.play("atk_s")
	elif last_direction == Vector2.LEFT:
		animated_sprite.play("atk_nw")
		animated_sprite.flip_h = false
	elif last_direction == Vector2.RIGHT:
		animated_sprite.play("atk_se")
		animated_sprite.flip_h = false
	elif last_direction == Vector2(-1, -1):
		animated_sprite.play("atk_nw")
		animated_sprite.flip_h = false
	elif last_direction == Vector2(1, -1):
		animated_sprite.play("atk_nw")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(-1, 1):
		animated_sprite.play("atk_se")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(1, 1):
		animated_sprite.play("atk_se")
		animated_sprite.flip_h = false


# =========================================================
# MENERIMA DAMAGE DARI PANAH ARCHER
# =========================================================

func take_damage(amount: int):
	if is_dead:
		return

	current_health -= amount

	# Update Bar HP utama (merah) langsung turun ke HP sekarang
	if health_bar:
		health_bar.value = current_health

	# Animasi Catch-up Bar (Kuning) menunjukkan potongan darah yang baru saja berkurang
	if damage_bar:
		if damage_tween and damage_tween.is_valid():
			damage_tween.kill()

		damage_tween = create_tween()
		# Tahan sesaat (0.35s) agar terlihat jelas darah awalnya berkurang seberapa banyak
		damage_tween.tween_interval(0.35)
		# Lalu susutkan secara halus mengejar sisa darah merah
		damage_tween.tween_property(damage_bar, "value", float(current_health), 0.4)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)

	# Efek kedip putih saat kena hit
	if animated_sprite:
		animated_sprite.modulate = Color(3.0, 3.0, 3.0)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(animated_sprite) and not is_dead:
			animated_sprite.modulate = Color(1.3, 0.4, 0.4) # Kembali ke warna merah musuh

	# Musuh kaget dan langsung mengejar player jika player masih hidup
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and not ("is_dead" in player_node and player_node.is_dead):
		player = player_node
		current_state = State.CHASE

	# Cek kematian
	if current_health <= 0:
		die()


# =========================================================
# KEMATIAN & RESPAWN OTOMATIS
# =========================================================

func die():
	is_dead = true
	is_shooting = false
	velocity = Vector2.ZERO

	# Sembunyikan visual dan matikan proses
	visible = false
	set_physics_process(false)

	# Matikan tabrakan dan deteksi
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hitbox and hitbox.has_node("CollisionShape2D"):
		$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	if detection_area and detection_area.has_node("CollisionShape2D"):
		$DetectionArea/CollisionShape2D.set_deferred("disabled", true)

	# Keluarkan dari grup enemy sementara agar tidak bisa ditembak saat mati
	remove_from_group("enemy")

	# Tunggu waktu respawn
	await get_tree().create_timer(respawn_time).timeout

	# Hidupkan kembali!
	respawn()


func respawn():
	# Kembalikan ke posisi awal
	global_position = spawn_position
	current_health = max_health
	is_touching_player = false
	player = null
	current_state = State.IDLE_PATROL
	wander_target = spawn_position
	wander_timer = 0.0
	damage_timer = 0.0
	shoot_timer = randf_range(0.5, shoot_cooldown)
	is_shooting = false
	last_direction = Vector2.DOWN

	# Reset Bar HP
	if damage_tween and damage_tween.is_valid():
		damage_tween.kill()
	if damage_bar:
		damage_bar.value = current_health
	if health_bar:
		health_bar.value = current_health

	# Reset warna normal
	if animated_sprite:
		animated_sprite.modulate = Color(1.3, 0.4, 0.4)
		play_idle_animation()

	# Nyalakan kembali tabrakan dan deteksi
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if hitbox and hitbox.has_node("CollisionShape2D"):
		$Hitbox/CollisionShape2D.set_deferred("disabled", false)
	if detection_area and detection_area.has_node("CollisionShape2D"):
		$DetectionArea/CollisionShape2D.set_deferred("disabled", false)

	# Daftarkan kembali ke grup enemy
	add_to_group("enemy")

	# Tampilkan kembali musuh
	visible = true
	set_physics_process(true)
	is_dead = false

	# Efek fade-in halus saat respawn
	modulate.a = 0.2
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.35)


# =========================================================
# AREA DETEKSI PLAYER
# =========================================================

func _on_detection_area_body_entered(body):
	if is_dead:
		return
	if (body.is_in_group("player") or body.name == "Player_Archer") and not ("is_dead" in body and body.is_dead):
		player = body
		current_state = State.CHASE


func _on_detection_area_body_exited(body):
	if is_dead:
		return
	if body == player:
		player = null
		current_state = State.IDLE_PATROL


# =========================================================
# HITBOX KONTAK
# =========================================================

func _on_hitbox_body_entered(body):
	if is_dead:
		return
	if (body.is_in_group("player") or body.name == "Player_Archer") and not ("is_dead" in body and body.is_dead):
		is_touching_player = true
		player = body
		# Langsung berikan damage jika cooldown siap
		if damage_timer <= 0.0:
			if player.has_method("take_damage"):
				player.take_damage(contact_damage, global_position)
			damage_timer = attack_cooldown


func _on_hitbox_body_exited(body):
	if body.is_in_group("player") or body.name == "Player_Archer":
		is_touching_player = false
