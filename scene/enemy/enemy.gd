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
const ATK_TEXTURE = preload("res://assets/characters/archer/atk-s.png")
const IDLE_TEXTURE = preload("res://assets/characters/archer/idle-s.png")

@export var shoot_range: float = 320.0       # Jarak tembak musuh (pixel)
@export var shoot_cooldown: float = 1.6     # Cooldown tembakan musuh (detik)
@export var projectile_damage: int = 1      # Damage panah musuh
@export var projectile_speed: float = 380.0 # Kecepatan panah musuh

var shoot_timer: float = 0.0
var is_shooting: bool = false

var current_health: int
var player: CharacterBody2D = null
var is_dead: bool = false

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
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $ProgressBar
@onready var detection_area: Area2D = $DetectionArea
@onready var hitbox: Area2D = $Hitbox
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var anim_timer: float = 0.0


func _ready():
	add_to_group("enemy")
	current_health = max_health
	spawn_position = global_position
	wander_target = spawn_position
	shoot_timer = randf_range(0.5, shoot_cooldown)

	setup_health_bar()

	# Hubungkan sinyal deteksi & hitbox secara otomatis
	if detection_area and not detection_area.body_entered.is_connected(_on_detection_area_body_entered):
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

	if hitbox and not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.body_exited.connect(_on_hitbox_body_exited)


func setup_health_bar():
	if not health_bar:
		return
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.show_percentage = false

	# Background bar warna gelap
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style_bg.set_corner_radius_all(1)

	# Isi bar warna merah terang
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.9, 0.2, 0.2, 0.95)
	style_fill.set_corner_radius_all(1)

	health_bar.add_theme_stylebox_override("background", style_bg)
	health_bar.add_theme_stylebox_override("fill", style_fill)


func _process(delta):
	if is_dead:
		return
	# Animasi frame sprite jika spritesheet (seperti archer hframes = 4 atau 8)
	if sprite and sprite.hframes > 1:
		var speed_mult := 12.0 if is_shooting else 6.0
		anim_timer += delta * speed_mult
		sprite.frame = int(anim_timer) % sprite.hframes


func _physics_process(delta):
	if is_dead:
		return

	# ---------------------------------------------------------
	# 1. LOGIKA GERAKAN & SERANGAN TEMBAK
	# ---------------------------------------------------------
	if current_state == State.CHASE and player != null and is_instance_valid(player):
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
			else:
				# Berhenti di jarak tembak yang pas
				velocity = Vector2.ZERO

			# Balik sprite sesuai arah horizontal
			if sprite and dir.x != 0:
				sprite.flip_h = dir.x < 0

	else:
		# Patroli mutar-mutar santai di area
		handle_idle_patrol(delta)

	move_and_slide()

	# ---------------------------------------------------------
	# 2. LOGIKA DAMAGE SAAT MENYENTUH ARCHER
	# ---------------------------------------------------------
	damage_timer -= delta
	if is_touching_player and player != null and is_instance_valid(player):
		if damage_timer <= 0.0:
			if player.has_method("take_damage"):
				player.take_damage(contact_damage)
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
		if sprite and dir.x != 0:
			sprite.flip_h = dir.x < 0
	else:
		# Berhenti sejenak jika sudah sampai
		velocity = Vector2.ZERO


# =========================================================
# RANGED ATTACK LOGIC (MENEMBAK PLAYER)
# =========================================================

func shoot_at_player():
	if player == null or not is_instance_valid(player) or is_dead or is_shooting:
		return

	is_shooting = true
	var dir = global_position.direction_to(player.global_position)

	# Arah hadap sprite ke player
	if sprite and dir.x != 0:
		sprite.flip_h = dir.x < 0

	# Mainkan animasi menembak
	if sprite:
		sprite.texture = ATK_TEXTURE
		sprite.hframes = 8
		sprite.frame = 0
		anim_timer = 0.0

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
		if sprite:
			sprite.texture = IDLE_TEXTURE
			sprite.hframes = 4
			sprite.frame = 0
			anim_timer = 0.0


# =========================================================
# MENERIMA DAMAGE DARI PANAH ARCHER
# =========================================================

func take_damage(amount: int):
	if is_dead:
		return

	current_health -= amount

	# Update Bar HP
	if health_bar:
		health_bar.value = current_health

	# Efek kedip putih saat kena hit
	if sprite:
		sprite.modulate = Color(3.0, 3.0, 3.0)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite) and not is_dead:
			sprite.modulate = Color(1.3, 0.4, 0.4) # Kembali ke warna merah musuh

	# Musuh kaget dan langsung mengejar player
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
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

	# Reset Bar HP
	if health_bar:
		health_bar.value = current_health

	# Reset warna normal & tekstur
	if sprite:
		sprite.texture = IDLE_TEXTURE
		sprite.hframes = 4
		sprite.frame = 0
		anim_timer = 0.0
		sprite.modulate = Color(1.3, 0.4, 0.4)

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
	if body.is_in_group("player") or body.name == "Player_Archer":
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
	if body.is_in_group("player") or body.name == "Player_Archer":
		is_touching_player = true
		player = body
		# Langsung berikan damage jika cooldown siap
		if damage_timer <= 0.0:
			if player.has_method("take_damage"):
				player.take_damage(contact_damage)
			damage_timer = attack_cooldown


func _on_hitbox_body_exited(body):
	if body.is_in_group("player") or body.name == "Player_Archer":
		is_touching_player = false
