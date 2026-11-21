extends CharacterBody2D

# =========================
# STATS & SETTINGS
# =========================
enum EnemyType { ARCHER, KNIGHT }
@export var enemy_type: EnemyType = EnemyType.ARCHER
@export var max_health: int = 550
@export var wander_speed: float = 60.0
@export var chase_speed: float = 135.0
@export var patrol_radius: float = 140.0
@export var contact_damage: int = 25
@export var attack_cooldown: float = 1.0  # Jeda memberi damage saat menyentuh player
@export var respawn_time: float = 5.0     # Waktu tunggu respawn setelah mati (detik)
@export var can_respawn: bool = true
@export var wait_for_arena: bool = false
@export var in_arena_combat: bool = false
@export var is_training_dummy: bool = false
@export var melee_attack_range: float = 120.0
@export var melee_damage: int = 50

# =========================================================
# ALARIC BOSS STATS, ENRAGE & ATTACK PATTERNS
# =========================================================
@export var is_alaric_boss: bool = false
const ALARIC_MAX_HP: int = 600                      # Disesuaikan dengan Basic Attack Knight (40 dmg x 15 tebasan = 600 HP)
const ALARIC_BASE_MOVE_SPEED: float = 220.0         # Seperti karakter lain (SPRINT_SPEED := 220.0)
const ALARIC_ENRAGE_HP_RATIO: float = 0.35          # Enrage aktif pada HP 35% (<= 210 HP)
const ALARIC_ENRAGE_SPEED_MULTIPLIER: float = 1.08  # Movement speed Enrage meningkat 8% (237.6 px/s)
const ALARIC_TILE_SIZE: float = 85.0                # Ukuran 1 petak dunia (skala 5x)

# 1. Basic Attack (3x1 [didepan sekaligus diagonal] karakter) - Tanpa Indikator Serangan
const ALARIC_BASIC_DAMAGE: int = 160
const ALARIC_BASIC_WINDUP: float = 0.45
const ALARIC_BASIC_RECOVERY: float = 0.75
const ALARIC_BASIC_COOLDOWN: float = 1.6

# 2. Triple Advance (3 hit [1 petak di depan] karakter) - Dengan Indikator & Efek Tebasan
const ALARIC_TRIPLE_DAMAGE_PER_HIT: int = 110
const ALARIC_TRIPLE_HIT_COUNT: int = 3
const ALARIC_TRIPLE_WINDUP: float = 0.45
const ALARIC_TRIPLE_RECOVERY: float = 1.1
const ALARIC_TRIPLE_COOLDOWN: float = 4.5
const ALARIC_TRIPLE_HIT_INTERVAL: float = 0.16

# 3. Ground Rupture (1 petak di keliling [setiap arah] karakter) - Dengan Indikator & Efek Tebasan
const ALARIC_RUPTURE_DAMAGE: int = 220
const ALARIC_RUPTURE_WINDUP: float = 0.9
const ALARIC_RUPTURE_RECOVERY: float = 1.3
const ALARIC_RUPTURE_COOLDOWN: float = 7.5

var is_alaric_enraged: bool = false
var alaric_basic_cd_timer: float = 0.0
var alaric_triple_cd_timer: float = 0.0
var alaric_rupture_cd_timer: float = 0.0
var alaric_recovery_timer: float = 0.0
var alaric_attack_token: int = 0
var alaric_active_telegraph: Node2D = null
var alaric_enrage_aura: Node2D = null

# =========================================================
# SKELETON BOSS STATS, ENRAGE (30% HP) & 4 FIRE AOE ATTACKS
# =========================================================
@export var is_skeleton_boss: bool = false
const SKELETON_MAX_HP: int = 5000
const SKELETON_TILE_SIZE: float = 85.0                  # Ukuran 1 tile dunia (skala 5x)
const SKELETON_NORMAL_MOVE_SPEED: float = 176.0         # 2,2 tile/detik (35,2 px * 5x skala dunia)
const SKELETON_ENRAGE_MOVE_SPEED: float = 208.0         # 2,6 tile/detik (41,6 px * 5x skala dunia)
const SKELETON_DAMAGE_REDUCTION: float = 0.10           # Damage Reduction 10%
const SKELETON_ENRAGE_HP_RATIO: float = 0.30            # Enrage aktif pada HP <= 30% (450 HP)
const SKELETON_ATTACK_BREATHING_GAP: float = 2.4        # Jeda terbuka antar serangan agar pemain punya kesempatan menyerang

# A. Ring of Fire (Circular AoE: Radius awal 1 tile -> Radius akhir 3 tile)
const SKELETON_RING_DAMAGE: int = 180
const SKELETON_RING_WINDUP_NORMAL: float = 1.0
const SKELETON_RING_WINDUP_ENRAGE: float = 0.75
const SKELETON_RING_RECOVERY: float = 1.2
const SKELETON_RING_COOLDOWN: float = 7.0
const SKELETON_RING_START_TILES: float = 1.0
const SKELETON_RING_END_TILES: float = 3.0

# B. Flame Pillar (Targeted AoE: 2 karakter bergantian, Radius 1 tile)
const SKELETON_PILLAR_DAMAGE: int = 210
const SKELETON_PILLAR_WINDUP_NORMAL: float = 1.2
const SKELETON_PILLAR_WINDUP_ENRAGE: float = 0.9
const SKELETON_PILLAR_RECOVERY: float = 1.0
const SKELETON_PILLAR_COOLDOWN: float = 8.0
const SKELETON_PILLAR_RADIUS_TILES: float = 1.0
const SKELETON_PILLAR_TARGET_COUNT: int = 2

# C. Infernal Burst (Radial AoE: 4 arah utama Atas/Bawah/Kiri/Kanan, Jangkauan 4 tile)
const SKELETON_BURST_DAMAGE: int = 260
const SKELETON_BURST_WINDUP_NORMAL: float = 1.5
const SKELETON_BURST_WINDUP_ENRAGE: float = 1.2
const SKELETON_BURST_RECOVERY: float = 1.5
const SKELETON_BURST_COOLDOWN: float = 11.0
const SKELETON_BURST_RANGE_TILES: float = 4.0

# D. Fireball Rain (Multi-target AoE: 5 area acak, Radius 1 tile, 150 damage/ledakan)
const SKELETON_RAIN_DAMAGE: int = 150
const SKELETON_RAIN_WINDUP_NORMAL: float = 1.8
const SKELETON_RAIN_WINDUP_ENRAGE: float = 1.4
const SKELETON_RAIN_RECOVERY: float = 1.3
const SKELETON_RAIN_COOLDOWN: float = 13.0
const SKELETON_RAIN_AREA_COUNT: int = 5
const SKELETON_RAIN_RADIUS_TILES: float = 1.0

var is_skeleton_enraged: bool = false
var skeleton_ring_cd_timer: float = 0.0
var skeleton_pillar_cd_timer: float = 0.0
var skeleton_burst_cd_timer: float = 0.0
var skeleton_rain_cd_timer: float = 0.0
var skeleton_recovery_timer: float = 0.0
var skeleton_attack_gap_timer: float = 0.0
var skeleton_attack_token: int = 0
var skeleton_active_telegraphs: Array[Node2D] = []
var skeleton_enrage_aura: Node2D = null
static var _skeleton_sprite_frames_cache: SpriteFrames = null
static var _orange_fireball_frames_cache: SpriteFrames = null
static var _orange_explosion_frames_cache: SpriteFrames = null

# =========================
# RANGED ATTACK / TEMBAKAN MUSUH
# =========================
const ARROW_SCENE = preload("res://scene/projectile/arrow.tscn")
const TRACE_SCENE = preload("res://scene/projectile/arrow_trace.tscn")

# =========================
# AUDIO SFX
# =========================
const SFX_ALERT = preload("res://assets/audio/sfx/enemy/enemy_alert.wav")
const SFX_BOW_SHOOT = preload("res://assets/audio/sfx/enemy/enemy_bow_shoot.wav")
const SFX_CONTACT_HIT = preload("res://assets/audio/sfx/enemy/enemy_contact_hit.wav")
const SFX_HURT = preload("res://assets/audio/sfx/enemy/enemy_hurt.wav")
const SFX_DEATH = preload("res://assets/audio/sfx/enemy/enemy_death.wav")
const SFX_RESPAWN = preload("res://assets/audio/sfx/enemy/enemy_respawn.wav")
const SFX_KNIGHT_SLASH = preload("res://assets/audio/sfx/characters/knight/knight_slash.wav")
const SFX_KNIGHT_SLASH_HIT = preload("res://assets/audio/sfx/characters/knight/knight_slash_hit.wav")
const SFX_FIRE_AIM = preload("res://assets/audio/sfx/characters/mage/mage_skill_meteor_aim.wav")
const SFX_FIRE_CAST = preload("res://assets/audio/sfx/characters/mage/mage_skill_meteor_cast.wav")
const SFX_FIRE_FALL = preload("res://assets/audio/sfx/characters/mage/mage_meteor_fall.wav")
const SFX_FIRE_IMPACT = preload("res://assets/audio/sfx/characters/mage/mage_meteor_impact.wav")

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player_sfx := AudioStreamPlayer2D.new()
	if AudioServer.get_bus_index("SFX") != -1:
		player_sfx.bus = &"SFX"
	player_sfx.stream = stream
	player_sfx.volume_db = volume_db
	player_sfx.global_position = global_position
	if get_parent():
		get_parent().add_child(player_sfx)
	else:
		add_child(player_sfx)
	player_sfx.finished.connect(player_sfx.queue_free)
	player_sfx.play()

@export var shoot_range: float = 500.0       # Jarak tembak musuh (pixel, setara dengan 520px archer pemain)
@export var shoot_cooldown: float = 1.2     # Cooldown tembakan musuh (1.2s, sedikit lebih gesit dari 1.25s archer pemain)
@export var projectile_damage: int = 110      # Damage panah musuh (110 damage, sedikit di atas 95 damage archer pemain)
@export var projectile_speed: float = 580.0 # Kecepatan panah musuh (disamakan 580.0 px/s dengan archer player)
@export var enemy_projectile_ratio: float = 1.0 # Rasio kecepatan panah musuh relatif terhadap speed karakter yang dikendalikan (1.0 = sama persis)

var shoot_timer: float = 0.0
var is_shooting: bool = false

var current_health: int
var player: CharacterBody2D = null
var threat_target: CharacterBody2D = null
var threat_timer: float = 0.0
var is_dead: bool = false

# Arah terakhir musuh (8 arah)
var last_direction := Vector2.DOWN

var is_flanking: bool = false
var flank_wp1: Vector2 = Vector2.ZERO
var flank_wp2: Vector2 = Vector2.ZERO
var flank_stage: int = 1
var flank_timeout: float = 0.0
var facing_debounce_timer: float = 0.0

# Knockback
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 1400.0

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
var touching_players: Array[CharacterBody2D] = []
var stun_timer: float = 0.0
var alert_sfx_cooldown_timer: float = 0.0

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar
@onready var damage_bar: ProgressBar = $DamageBar
@onready var detection_area: Area2D = $DetectionArea
@onready var hitbox: Area2D = $Hitbox
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var damage_tween: Tween = null


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("enemy")
	if "Alaric" in name:
		is_alaric_boss = true
	if "Skeleton" in name:
		is_skeleton_boss = true
	if is_training_dummy:
		max_health = 2500
		can_respawn = false
		contact_damage = 0
		melee_damage = 0
		projectile_damage = 0
	elif is_alaric_boss:
		max_health = ALARIC_MAX_HP
		can_respawn = false
		contact_damage = 0
		melee_damage = ALARIC_BASIC_DAMAGE
		chase_speed = ALARIC_BASE_MOVE_SPEED
		melee_attack_range = 115.0
	elif is_skeleton_boss:
		max_health = SKELETON_MAX_HP
		can_respawn = false
		contact_damage = 0
		melee_damage = SKELETON_RING_DAMAGE
		chase_speed = SKELETON_NORMAL_MOVE_SPEED
		melee_attack_range = 120.0
		collision_layer = 1
		collision_mask = 1
		if animated_sprite:
			animated_sprite.sprite_frames = _get_or_create_skeleton_sprite_frames()
			animated_sprite.modulate = Color.WHITE
			animated_sprite.offset = Vector2(0, 0)
	else:
		max_health = 1
	current_health = max_health
	spawn_position = global_position
	wander_target = spawn_position
	shoot_timer = randf_range(0.5, get_dynamic_shoot_cooldown())

	_setup_player_collision_exceptions.call_deferred()

	setup_health_bar()
	play_idle_animation()

	# Hubungkan sinyal deteksi & hitbox secara otomatis
	if detection_area and not detection_area.body_entered.is_connected(_on_detection_area_body_entered):
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

	if hitbox and not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.body_exited.connect(_on_hitbox_body_exited)


func _setup_player_collision_exceptions() -> void:
	if not is_inside_tree():
		return
	var party := get_tree().get_nodes_in_group("player")
	if is_alaric_boss or is_skeleton_boss:
		# Boss Alaric & Boss Skeleton: Collision TIDAK BISA DITEMBUS oleh karakter pemain
		for p in party:
			if is_instance_valid(p) and p is CollisionObject2D:
				remove_collision_exception_with(p)
				p.remove_collision_exception_with(self)
		return
	for p in party:
		if is_instance_valid(p) and p is CollisionObject2D:
			add_collision_exception_with(p)
			p.add_collision_exception_with(self)


func alert_to_combat(target: CharacterBody2D = null) -> void:
	if is_dead or is_training_dummy:
		return
	wait_for_arena = false
	in_arena_combat = true
	var was_patrolling: bool = (current_state == State.IDLE_PATROL)
	if current_state != State.CHASE:
		current_state = State.CHASE
	var chosen: CharacterBody2D = target if target else get_best_target()
	if chosen:
		player = chosen
	if was_patrolling and alert_sfx_cooldown_timer <= 0.0:
		play_sfx(SFX_ALERT, -2.0)
		alert_sfx_cooldown_timer = 5.0

func get_enemy_center() -> Vector2:
	if has_node("Hurtbox/CollisionShape2D"):
		return $Hurtbox/CollisionShape2D.global_position
	return global_position + Vector2(0.0, 10.0)

func get_target_center(target: Node2D) -> Vector2:
	if not target or not is_instance_valid(target):
		return global_position
	if target.has_node("Hurtbox/CollisionShape2D"):
		return target.get_node("Hurtbox/CollisionShape2D").global_position
	return target.global_position

func get_best_target() -> CharacterBody2D:
	# 1. Prioritaskan karakter yang baru saja memberi damage (threat/aggro priority)
	if threat_timer > 0.0 and threat_target != null and is_instance_valid(threat_target):
		if not ("is_dead" in threat_target and threat_target.is_dead) and threat_target.is_in_group("player") and threat_target.visible:
			return threat_target
		else:
			threat_target = null
			threat_timer = 0.0

	# 2. Karakter terdekat di seluruh anggota party (4 karakter)
	return get_closest_target()

func get_closest_target() -> CharacterBody2D:
	var party := get_tree().get_nodes_in_group("player")
	var closest: CharacterBody2D = null
	var min_d := INF
	var enemy_center := get_enemy_center()
	for p in party:
		if p is CharacterBody2D and is_instance_valid(p) and p.visible and not ("is_dead" in p and p.is_dead):
			var d := enemy_center.distance_to(get_target_center(p))
			if d < min_d:
				min_d = d
				closest = p
	return closest


# Shared static StyleBoxes untuk health bar & damage bar seluruh musuh
static var _style_bg: StyleBoxFlat = null
static var _style_damage_fill: StyleBoxFlat = null
static var _style_empty: StyleBoxEmpty = null
static var _style_fill: StyleBoxFlat = null


static func _init_health_bar_styles() -> void:
	if _style_bg != null:
		return

	# Background bar warna gelap
	_style_bg = StyleBoxFlat.new()
	_style_bg.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	_style_bg.set_corner_radius_all(1)

	# Warna isi damage bar (kuning keemasan terang untuk indikator damage)
	_style_damage_fill = StyleBoxFlat.new()
	_style_damage_fill.bg_color = Color(1.0, 0.85, 0.3, 0.95)
	_style_damage_fill.set_corner_radius_all(1)

	# Background transparan agar damage bar di belakangnya kelihatan saat darah berkurang
	_style_empty = StyleBoxEmpty.new()

	# Isi bar warna merah terang
	_style_fill = StyleBoxFlat.new()
	_style_fill.bg_color = Color(0.9, 0.2, 0.2, 0.95)
	_style_fill.set_corner_radius_all(1)


func setup_health_bar() -> void:
	_init_health_bar_styles()

	# Konfigurasi Bar Belakang (Damage Bar / Buffer yang menunjukkan darah yang hilang)
	if damage_bar:
		damage_bar.max_value = max_health
		damage_bar.value = current_health
		damage_bar.show_percentage = false

		damage_bar.add_theme_stylebox_override("background", _style_bg)
		damage_bar.add_theme_stylebox_override("fill", _style_damage_fill)

	# Konfigurasi Bar Depan (Health Bar utama warna merah)
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.show_percentage = false

		health_bar.add_theme_stylebox_override("background", _style_empty)
		health_bar.add_theme_stylebox_override("fill", _style_fill)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_training_dummy:
		if knockback_velocity != Vector2.ZERO:
			knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * 1.5 * delta)
			velocity = knockback_velocity
			move_and_slide_with_separation()
			if knockback_velocity.length() < 8.0:
				knockback_velocity = Vector2.ZERO
		else:
			velocity = Vector2.ZERO

		if global_position.distance_to(spawn_position) > 100.0:
			global_position = global_position.move_toward(spawn_position, 60.0 * delta)

		play_idle_animation()
		return

	if alert_sfx_cooldown_timer > 0.0:
		alert_sfx_cooldown_timer -= delta

	# Penanganan stun / knockup: musuh diam di tempat secara horizontal tanpa pergeseran
	if stun_timer > 0.0:
		stun_timer -= delta
		velocity = Vector2.ZERO
		knockback_velocity = Vector2.ZERO
		return

	# Reduksi knockback saat terkena dampak ledakan/serangan kuat
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		velocity = knockback_velocity
		move_and_slide_with_separation()
		if knockback_velocity.length() < 8.0:
			knockback_velocity = Vector2.ZERO
		return

	# ---------------------------------------------------------
	# 1. LOGIKA GERAKAN & SERANGAN TEMBAK
	# ---------------------------------------------------------
	if threat_timer > 0.0:
		threat_timer -= delta

	if current_state == State.CHASE:
		# Evaluasi target terbaik dari seluruh 4 anggota party
		var target := get_best_target()
		if target == null:
			player = null
			if not in_arena_combat:
				current_state = State.IDLE_PATROL
			return
		player = target

		var target_center := get_target_center(player)
		var enemy_center := get_enemy_center()
		var dist := enemy_center.distance_to(target_center)
		# Jika pemain kabur terlalu jauh di luar layar (leash limit), musuh kembali patroli (hanya di luar arena)
		if not in_arena_combat and dist > 850.0:
			player = null
			is_flanking = false
			flank_wp1 = Vector2.ZERO
			flank_wp2 = Vector2.ZERO
			flank_stage = 1
			flank_timeout = 0.0
			facing_debounce_timer = 0.0
			current_state = State.IDLE_PATROL
			return

		var dir: Vector2 = (target_center - enemy_center).normalized()
		if dir == Vector2.ZERO:
			dir = last_direction

		# Hitung mundur cooldown tembak & cooldown skill Alaric Boss / Skeleton Boss
		shoot_timer -= delta
		if is_alaric_boss:
			if alaric_basic_cd_timer > 0.0:
				alaric_basic_cd_timer = maxf(0.0, alaric_basic_cd_timer - delta)
			if alaric_triple_cd_timer > 0.0:
				alaric_triple_cd_timer = maxf(0.0, alaric_triple_cd_timer - delta)
			if alaric_rupture_cd_timer > 0.0:
				alaric_rupture_cd_timer = maxf(0.0, alaric_rupture_cd_timer - delta)
			_check_and_update_alaric_enrage()
		elif is_skeleton_boss:
			if not is_shooting:
				if skeleton_ring_cd_timer > 0.0:
					skeleton_ring_cd_timer = maxf(0.0, skeleton_ring_cd_timer - delta)
				if skeleton_pillar_cd_timer > 0.0:
					skeleton_pillar_cd_timer = maxf(0.0, skeleton_pillar_cd_timer - delta)
				if skeleton_burst_cd_timer > 0.0:
					skeleton_burst_cd_timer = maxf(0.0, skeleton_burst_cd_timer - delta)
				if skeleton_rain_cd_timer > 0.0:
					skeleton_rain_cd_timer = maxf(0.0, skeleton_rain_cd_timer - delta)
			_check_and_update_skeleton_enrage()

		var has_los := has_clear_projectile_los_to(player, 12.0)
		var dist_to_player: float = dist

		# 1. Jarak serang & manuver AI Musuh (Alaric Boss vs Skeleton Boss vs Melee Knight vs Ranged Archer)
		if is_alaric_boss:
			_process_alaric_boss_ai(delta, dir, dist_to_player, has_los)
		elif is_skeleton_boss:
			_process_skeleton_boss_ai(delta, dir, dist_to_player, has_los)
		elif enemy_type == EnemyType.KNIGHT:
			if dist_to_player <= melee_attack_range and has_los:
				is_flanking = false
				velocity = Vector2.ZERO
				move_and_slide_with_separation()

				if not is_shooting:
					if shoot_timer <= 0.0:
						execute_melee_attack()
					else:
						last_direction = get_8_direction(dir)
						play_idle_animation()
			elif has_los:
				is_flanking = false
				if is_shooting:
					velocity = Vector2.ZERO
					move_and_slide_with_separation()
				else:
					var move_dir: Vector2 = dir
					velocity = move_dir * chase_speed
					move_and_slide_with_separation()
					apply_smoothed_facing(move_dir, delta)
			else:
				# Terhalang rintangan fisik: navigasi waypoint
				if is_shooting:
					velocity = Vector2.ZERO
					move_and_slide_with_separation()
				else:
					flank_timeout -= delta
					if not is_flanking or flank_timeout <= 0.0:
						calculate_flank_waypoints(player)

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
					velocity = move_dir * chase_speed
					move_and_slide_with_separation()
					apply_smoothed_facing(move_dir, delta)
		elif dist_to_player <= shoot_range and has_los:
			is_flanking = false
			# Jika musuh terlalu dekat (< 80 px), mundur perlahan (kiting) agar tidak menempel ke badan player
			if dist_to_player < 80.0:
				var retreat_dir := -dir
				velocity = retreat_dir * (chase_speed * 0.75)
				move_and_slide_with_separation()
				update_direction_animation(dir)
			else:
				# Berada dalam jarak tembak aman: berhenti melangkah maju dan fokus menembak
				velocity = Vector2.ZERO
				move_and_slide_with_separation()
				update_direction_animation(dir)

			# Eksekusi tembakan musuh sesuai timer shoot_cooldown
			if shoot_timer <= 0.0 and not is_shooting:
				shoot_at_player()
			if not is_shooting and dist_to_player >= 80.0:
				last_direction = get_8_direction(dir)
				play_idle_animation()
		elif dist_to_player <= 140.0:
			# Jarak sudah sangat dekat (<= 140 px): Musuh penembak TIDAK BOLEH memaksakan diri maju menempel ke 0 px!
			# Berhenti melangkah maju, hadap player, dan tembak jika cooldown siap
			is_flanking = false
			if dist_to_player < 80.0:
				var retreat_dir := -dir
				velocity = retreat_dir * (chase_speed * 0.75)
				move_and_slide_with_separation()
				update_direction_animation(dir)
			else:
				velocity = Vector2.ZERO
				move_and_slide_with_separation()
				update_direction_animation(dir)

			if shoot_timer <= 0.0 and not is_shooting:
				shoot_at_player()
			if not is_shooting and dist_to_player >= 80.0:
				last_direction = get_8_direction(dir)
				play_idle_animation()
		elif has_los:
			# Belum masuk shoot_range: dekati player secara langsung
			is_flanking = false
			if is_shooting:
				velocity = Vector2.ZERO
				move_and_slide_with_separation()
			else:
				var move_dir: Vector2 = dir
				velocity = move_dir * chase_speed
				move_and_slide_with_separation()
				apply_smoothed_facing(move_dir, delta)
		else:
			# Terhalang pagar / dinding fisik: navigasi 2-waypoint
			if is_shooting:
				velocity = Vector2.ZERO
				move_and_slide_with_separation()
			else:
				flank_timeout -= delta
				if not is_flanking or flank_timeout <= 0.0:
					calculate_flank_waypoints(player)

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
				velocity = move_dir * chase_speed
				move_and_slide_with_separation()
				apply_smoothed_facing(move_dir, delta)
	else:
		if in_arena_combat:
			var arena_t := get_best_target()
			if arena_t != null:
				current_state = State.CHASE
				player = arena_t
		else:
			# Patroli mutar-mutar santai di area
			handle_idle_patrol(delta)
			move_and_slide_with_separation()

	# ---------------------------------------------------------
	# 2. LOGIKA DAMAGE KONTAK SAAT MENYENTUH HERO
	# ---------------------------------------------------------
	damage_timer -= delta
	if not is_alaric_boss and not is_skeleton_boss and contact_damage > 0:
		var target_touching := update_touching_players_and_get_target()
		if target_touching != null:
			if current_state == State.IDLE_PATROL:
				current_state = State.CHASE
				player = target_touching
				if alert_sfx_cooldown_timer <= 0.0:
					play_sfx(SFX_ALERT, -2.0)
					alert_sfx_cooldown_timer = 5.0
			if damage_timer <= 0.0:
				if target_touching.has_method("take_damage"):
					target_touching.take_damage(contact_damage, global_position)
				play_sfx(SFX_CONTACT_HIT, 0.0)
				damage_timer = attack_cooldown


func handle_idle_patrol(delta: float) -> void:
	if in_arena_combat:
		var t := get_best_target()
		if t != null:
			current_state = State.CHASE
			player = t
			return

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

func get_arrow_spawn_position(dir: Vector2) -> Vector2:
	# Titik visual tengah tubuh archer musuh
	var center_pos := get_enemy_center()

	# Posisi kemunculan panah tepat di depan busur keluar dari tubuh musuh
	var forward_dist := 28.0 if last_direction == Vector2.UP else 20.0
	return center_pos + dir * forward_dist


func calculate_flank_waypoints(target_node: Node2D) -> bool:
	if not target_node or not is_instance_valid(target_node):
		return false
	var space_state := get_world_2d().direct_space_state
	var my_pos: Vector2 = get_enemy_center()
	var target_pos: Vector2 = get_target_center(target_node)
	
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

func get_cardinal_direction(dir: Vector2) -> Vector2:
	if dir == Vector2.ZERO:
		return Vector2.DOWN
	if abs(dir.x) >= abs(dir.y):
		return Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if dir.y > 0 else Vector2.UP

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
	var from_pos: Vector2 = get_enemy_center()
	var to_pos: Vector2 = get_target_center(target_node)
	
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
		return true
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


func get_dynamic_projectile_speed() -> float:
	# Panah musuh menggunakan model Archer, diselaraskan sama persis dengan kecepatan panah Archer pemain
	var party = get_tree().get_nodes_in_group("player")
	for p in party:
		if is_instance_valid(p) and p.name.begins_with("Archer") and "controlled_projectile_speed" in p:
			return p.controlled_projectile_speed * enemy_projectile_ratio
	return projectile_speed


func get_dynamic_shoot_cooldown() -> float:
	# Musuh menggunakan model Archer, diselaraskan cooldown tembakannya dengan Archer pemain (sedikit lebih gesit)
	var party = get_tree().get_nodes_in_group("player")
	for p in party:
		if is_instance_valid(p) and p.name.begins_with("Archer") and "attack_cooldown" in p:
			return minf(shoot_cooldown, p.attack_cooldown * 0.96)
	return shoot_cooldown


func shoot_at_player() -> void:
	if player == null or not is_instance_valid(player) or is_dead or is_shooting:
		return

	is_shooting = true
	var enemy_center := get_enemy_center()
	var target_center := get_target_center(player)
	var dir := (target_center - enemy_center).normalized()
	if dir == Vector2.ZERO:
		dir = last_direction

	# Arah hadap ke player dan mainkan animasi serang sesuai arah
	last_direction = get_8_direction(dir)
	play_attack_animation()

	# Munculkan panah musuh dari posisi keluar yang presisi
	var spawn_pos := get_arrow_spawn_position(dir)

	var arrow = ARROW_SCENE.instantiate()
	arrow.global_position = spawn_pos
	arrow.direction = dir
	arrow.rotation = dir.angle()
	arrow.shooter_group = "enemy"
	projectile_speed = get_dynamic_projectile_speed()
	arrow.speed = projectile_speed
	arrow.damage = projectile_damage
	arrow.modulate = Color(1.8, 0.4, 0.4) # Warna kemerahan agar jelas panah musuh
	if last_direction == Vector2.UP or animated_sprite.animation == "atk_n":
		arrow.get_node("Sprite2D").z_index = 3
	else:
		arrow.get_node("Sprite2D").z_index = 5
	get_parent().add_child(arrow)
	play_sfx(SFX_BOW_SHOOT, -2.0)

	# Munculkan trace indicator panah musuh tepat di titik lepas (dihilangkan jika menghadap North)
	if last_direction != Vector2.UP and animated_sprite.animation != "atk_n":
		var trace = TRACE_SCENE.instantiate()
		trace.global_position = spawn_pos
		trace.rotation = dir.angle()
		trace.scale = Vector2(4, 4)
		trace.z_index = 10
		trace.modulate = Color(1.8, 0.4, 0.4)
		get_parent().add_child(trace)

	shoot_timer = get_dynamic_shoot_cooldown()
	# Sinkronisasi damage kontak agar tembakan panah jarak dekat tidak memicu double damage
	damage_timer = max(damage_timer, 0.6)

	# Tunggu durasi animasi menembak selesai (~0.35 detik), lalu kembali ke idle
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(self) and not is_dead:
		is_shooting = false
		if current_state == State.CHASE and player != null and is_instance_valid(player):
			var chase_dir := (get_target_center(player) - get_enemy_center()).normalized()
			if chase_dir != Vector2.ZERO:
				last_direction = get_8_direction(chase_dir)
		play_idle_animation()


func execute_melee_attack() -> void:
	if player == null or not is_instance_valid(player) or is_dead or is_shooting:
		return

	is_shooting = true
	var enemy_center := get_enemy_center()
	var target_center := get_target_center(player)
	var dir := (target_center - enemy_center).normalized()
	if dir == Vector2.ZERO:
		dir = last_direction

	# Arah hadap ke player dan mainkan animasi serang sesuai arah
	last_direction = get_8_direction(dir)
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("skill_s") and randf() < 0.25:
		play_skill_animation()
	else:
		play_attack_animation()
	play_sfx(SFX_KNIGHT_SLASH, 0.0)

	# Jeda ancang-ancang (~0.18 detik) sebelum tebasan mengenai player
	await get_tree().create_timer(0.18).timeout
	if is_instance_valid(self) and not is_dead and player != null and is_instance_valid(player):
		var cur_dist := global_position.distance_to(player.global_position)
		if cur_dist <= melee_attack_range + 35.0:
			if player.has_method("take_damage"):
				player.take_damage(melee_damage, global_position)
			elif "hp" in player:
				player.hp -= melee_damage
			elif "current_health" in player:
				player.current_health -= melee_damage
			play_sfx(SFX_KNIGHT_SLASH_HIT, -1.0)
			damage_timer = max(damage_timer, 0.6)

	shoot_timer = attack_cooldown
	damage_timer = max(damage_timer, 0.6)

	# Tunggu sisa durasi animasi tebasan (~0.38 detik), lalu kembali ke idle
	await get_tree().create_timer(0.38).timeout
	if is_instance_valid(self) and not is_dead:
		is_shooting = false
		if current_state == State.CHASE and player != null and is_instance_valid(player):
			var chase_dir := (get_target_center(player) - get_enemy_center()).normalized()
			if chase_dir != Vector2.ZERO:
				last_direction = get_8_direction(chase_dir)
		play_idle_animation()


# =========================================================
# UPDATE ARAH ANIMASI
# =========================================================

func update_direction_animation(direction: Vector2) -> void:
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

func play_walk_animation() -> void:
	if not animated_sprite:
		return
	animated_sprite.flip_h = false

	if last_direction == Vector2.UP:
		animated_sprite.play("walk_n")
	elif last_direction == Vector2.DOWN:
		animated_sprite.play("walk_s")
	elif last_direction == Vector2.LEFT:
		animated_sprite.play("walk_w")
		animated_sprite.flip_h = false
	elif last_direction == Vector2.RIGHT:
		animated_sprite.play("walk_e")
		animated_sprite.flip_h = false
	elif last_direction == Vector2(-1, -1):
		animated_sprite.play("walk_w")
		animated_sprite.flip_h = false
	elif last_direction == Vector2(1, -1):
		animated_sprite.play("walk_w")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(-1, 1):
		animated_sprite.play("walk_e")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(1, 1):
		animated_sprite.play("walk_e")
		animated_sprite.flip_h = false


# =========================================================
# IDLE ANIMATION (8 ARAH)
# =========================================================

func play_idle_animation() -> void:
	if not animated_sprite:
		return
	animated_sprite.flip_h = false

	if last_direction == Vector2.UP:
		animated_sprite.play("idle_n")
	elif last_direction == Vector2.DOWN:
		animated_sprite.play("idle_s")
	elif last_direction == Vector2.LEFT:
		animated_sprite.play("idle_w")
		animated_sprite.flip_h = false
	elif last_direction == Vector2.RIGHT:
		animated_sprite.play("idle_e")
		animated_sprite.flip_h = false
	elif last_direction == Vector2(-1, -1):
		animated_sprite.play("idle_w")
		animated_sprite.flip_h = false
	elif last_direction == Vector2(1, -1):
		animated_sprite.play("idle_w")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(-1, 1):
		animated_sprite.play("idle_e")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(1, 1):
		animated_sprite.play("idle_e")
		animated_sprite.flip_h = false


# =========================================================
# ATTACK ANIMATION (8 ARAH)
# =========================================================

func play_attack_animation() -> void:
	if not animated_sprite:
		return
	animated_sprite.flip_h = false

	var anim_suffix: String = ""
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("atk_s_2") and randf() > 0.5:
		anim_suffix = "_2"

	var anim_name: String = "atk_s"
	if last_direction == Vector2.UP:
		anim_name = "atk_n"
	elif last_direction == Vector2.DOWN:
		anim_name = "atk_s"
	elif last_direction == Vector2.LEFT:
		anim_name = "atk_w"
		animated_sprite.flip_h = false
	elif last_direction == Vector2.RIGHT:
		anim_name = "atk_e"
		animated_sprite.flip_h = false
	elif last_direction == Vector2(-1, -1):
		anim_name = "atk_w"
		animated_sprite.flip_h = false
	elif last_direction == Vector2(1, -1):
		anim_name = "atk_e"
		animated_sprite.flip_h = false
	elif last_direction == Vector2(-1, 1):
		anim_name = "atk_w"
		animated_sprite.flip_h = false
	elif last_direction == Vector2(1, 1):
		anim_name = "atk_e"
		animated_sprite.flip_h = false

	var target_anim: String = anim_name + anim_suffix
	if animated_sprite.sprite_frames and not animated_sprite.sprite_frames.has_animation(target_anim):
		target_anim = anim_name

	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(target_anim):
		animated_sprite.stop()
		animated_sprite.play(target_anim)


func play_skill_animation() -> void:
	if not animated_sprite:
		return
	animated_sprite.flip_h = false

	var anim_name: String = "skill_s"
	if last_direction == Vector2.UP:
		anim_name = "skill_n"
	elif last_direction == Vector2.DOWN:
		anim_name = "skill_s"
	elif last_direction == Vector2.LEFT:
		anim_name = "skill_w"
		animated_sprite.flip_h = false
	elif last_direction == Vector2.RIGHT:
		anim_name = "skill_e"
		animated_sprite.flip_h = false
	elif last_direction == Vector2(-1, -1):
		anim_name = "skill_w"
		animated_sprite.flip_h = false
	elif last_direction == Vector2(1, -1):
		anim_name = "skill_e"
		animated_sprite.flip_h = false
	elif last_direction == Vector2(-1, 1):
		anim_name = "skill_w"
		animated_sprite.flip_h = false
	elif last_direction == Vector2(1, 1):
		anim_name = "skill_e"
		animated_sprite.flip_h = false

	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.stop()
		animated_sprite.play(anim_name)


func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force


func apply_knockup(duration: float = 0.65, height: float = 38.0) -> void:
	if is_dead:
		return
	stun_timer = maxf(stun_timer, duration)
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	if animated_sprite:
		var orig_y: float = animated_sprite.position.y
		var tween := create_tween()
		tween.tween_property(animated_sprite, "position:y", orig_y - height, duration * 0.4)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(animated_sprite, "position:y", orig_y, duration * 0.6)\
			.set_trans(Tween.TRANS_BOUNCE)\
			.set_ease(Tween.EASE_OUT)


# =========================================================
# MENERIMA DAMAGE DARI PANAH ARCHER
# =========================================================

func take_damage(amount: int, attacker: CharacterBody2D = null) -> void:
	if is_dead:
		return

	if is_training_dummy:
		current_health = max(1, current_health - amount)
		play_sfx(SFX_HURT, -2.0)

		if health_bar:
			health_bar.value = current_health

		if damage_bar:
			if damage_tween and damage_tween.is_valid():
				damage_tween.kill()
			damage_tween = create_tween()
			damage_tween.tween_interval(0.35)
			damage_tween.tween_property(damage_bar, "value", float(current_health), 0.4)\
				.set_trans(Tween.TRANS_QUAD)\
				.set_ease(Tween.EASE_OUT)

		if animated_sprite:
			animated_sprite.modulate = Color(3.0, 3.0, 3.0)
			var flash_tween := create_tween()
			flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

		if attacker != null and "Bandit" in attacker.name:
			knockback_velocity = Vector2.ZERO
			velocity = Vector2.ZERO

		# Pulihkan darah kembali secara halus jika menipis agar tidak pernah mati
		if current_health <= 100:
			current_health = max_health
			var reset_tween := create_tween()
			reset_tween.tween_interval(0.8)
			reset_tween.tween_property(health_bar, "value", float(max_health), 0.3)
			reset_tween.parallel().tween_property(damage_bar, "value", float(max_health), 0.3)
		return

	wait_for_arena = false
	if is_skeleton_boss:
		# Damage Reduction 10% pada Boss Skeleton
		amount = maxi(1, int(round(float(amount) * (1.0 - SKELETON_DAMAGE_REDUCTION))))
	elif not is_training_dummy and not is_alaric_boss:
		amount = max(amount, current_health)
	current_health = max(0, current_health - amount)
	play_sfx(SFX_HURT, -2.0)

	if is_alaric_boss:
		_check_and_update_alaric_enrage()
	elif is_skeleton_boss:
		_check_and_update_skeleton_enrage()

	# Kamera bergetar (camera shake) saat player mengenai musuh
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and is_instance_valid(player_node) and player_node.has_method("apply_camera_shake"):
		player_node.apply_camera_shake()

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
		var flash_tween := create_tween()
		var default_col: Color = Color.WHITE if ("Alaric" in name or is_alaric_boss or is_skeleton_boss or is_in_group("npc")) else Color(1.3, 0.4, 0.4)
		if is_alaric_boss and is_alaric_enraged:
			default_col = Color(1.22, 0.82, 0.78)
		elif is_skeleton_boss and is_skeleton_enraged:
			default_col = Color(1.35, 0.85, 0.55)
		flash_tween.tween_property(animated_sprite, "modulate", default_col, 0.1)

	# Multi-Target Aggro: Prioritaskan penyerang yang baru memberi damage
	if attacker != null and is_instance_valid(attacker) and attacker.is_in_group("player") and not ("is_dead" in attacker and attacker.is_dead):
		# Jika diserang Bandit dari belakang sementara Knight masih hidup membadani di depan, musuh tetap fokus pada Knight
		var knight_focus: CharacterBody2D = null
		if "Bandit" in attacker.name:
			var party := get_tree().get_nodes_in_group("player")
			for p in party:
				if is_instance_valid(p) and ("Knight" in p.name or "knight" in p.name.to_lower()):
					if not ("is_dead" in p and p.is_dead) and p.visible and global_position.distance_to(p.global_position) <= 160.0:
						knight_focus = p
						break

		if knight_focus:
			threat_target = knight_focus
			player = knight_focus
		else:
			threat_target = attacker
			player = attacker
		threat_timer = 3.0
		current_state = State.CHASE

		# Serangan dan skill Bandit dilarang memberikan knockback horizontal pada musuh
		if "Bandit" in attacker.name:
			knockback_velocity = Vector2.ZERO
			velocity = Vector2.ZERO
	else:
		var best := get_best_target()
		if best:
			player = best
			current_state = State.CHASE

	# Cek kematian
	if current_health <= 0:
		die()


# =========================================================
# KEMATIAN & RESPAWN OTOMATIS
# =========================================================

func die() -> void:
	if is_alaric_boss:
		_cleanup_alaric_combat_effects()
		is_dead = true
		is_shooting = false
		velocity = Vector2.ZERO
		knockback_velocity = Vector2.ZERO
		play_idle_animation()
		return
	if is_skeleton_boss:
		_cleanup_skeleton_combat_effects()
		is_dead = true
		is_shooting = false
		velocity = Vector2.ZERO
		knockback_velocity = Vector2.ZERO
		play_sfx(SFX_DEATH, 0.0)
		play_idle_animation()
		return
	is_dead = true
	play_sfx(SFX_DEATH, 0.0)
	is_shooting = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	is_flanking = false
	flank_wp1 = Vector2.ZERO
	flank_wp2 = Vector2.ZERO
	flank_stage = 1
	flank_timeout = 0.0
	facing_debounce_timer = 0.0
	touching_players.clear()
	is_touching_player = false

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
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", true)

	# Keluarkan dari grup enemy sementara agar tidak bisa ditembak saat mati
	remove_from_group("enemy")

	if not can_respawn:
		return

	if not is_inside_tree():
		return

	# Tunggu waktu respawn (5 detik)
	await get_tree().create_timer(respawn_time).timeout

	if not is_inside_tree():
		return

	# Hidupkan kembali!
	respawn()


func respawn() -> void:
	if not is_inside_tree():
		return

	# Kembalikan ke posisi awal
	global_position = spawn_position
	current_health = max_health
	touching_players.clear()
	is_touching_player = false
	player = null
	is_flanking = false
	flank_wp1 = Vector2.ZERO
	flank_wp2 = Vector2.ZERO
	flank_stage = 1
	flank_timeout = 0.0
	facing_debounce_timer = 0.0
	in_arena_combat = false
	current_state = State.IDLE_PATROL
	wander_target = spawn_position
	wander_timer = 0.0
	damage_timer = 0.0
	threat_target = null
	threat_timer = 0.0
	shoot_timer = randf_range(0.5, get_dynamic_shoot_cooldown())
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
		var default_col: Color = Color.WHITE if ("Alaric" in name or is_in_group("npc")) else Color(1.3, 0.4, 0.4)
		animated_sprite.modulate = default_col
		play_idle_animation()

	# Nyalakan kembali tabrakan dan deteksi
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if hitbox and hitbox.has_node("CollisionShape2D"):
		$Hitbox/CollisionShape2D.set_deferred("disabled", false)
	if detection_area and detection_area.has_node("CollisionShape2D"):
		$DetectionArea/CollisionShape2D.set_deferred("disabled", false)
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", false)

	# Daftarkan kembali ke grup enemy
	add_to_group("enemy")

	# Tampilkan kembali musuh
	visible = true
	set_physics_process(true)
	is_dead = false
	_setup_player_collision_exceptions()

	# Jika tidak sedang menunggu arena dan ada player di sekitar, kejar
	if not wait_for_arena:
		var target := get_closest_target()
		if target:
			alert_to_combat(target)

	# Efek fade-in halus saat respawn
	modulate.a = 0.2
	var tween = create_tween()
	if tween:
		tween.tween_property(self, "modulate:a", 1.0, 0.35)
	play_sfx(SFX_RESPAWN, -2.0)


# =========================================================
# AREA DETEKSI PLAYER
# =========================================================

func _on_detection_area_body_entered(body: Node2D) -> void:
	if is_dead or wait_for_arena:
		return
	if body.is_in_group("player") and not ("is_dead" in body and body.is_dead):
		var was_patrolling: bool = (current_state == State.IDLE_PATROL)
		var target := get_closest_target()
		player = target if target else body
		current_state = State.CHASE
		if was_patrolling and alert_sfx_cooldown_timer <= 0.0:
			play_sfx(SFX_ALERT, -2.0)
			alert_sfx_cooldown_timer = 5.0


func _on_detection_area_body_exited(body: Node2D) -> void:
	if is_dead or wait_for_arena:
		return
	if in_arena_combat:
		var next_target := get_best_target()
		if next_target:
			player = next_target
		return
	if body == player:
		var next_target := get_closest_target()
		if next_target and global_position.distance_to(next_target.global_position) <= 550.0:
			player = next_target
		else:
			player = null
			current_state = State.IDLE_PATROL


# =========================================================
# HITBOX KONTAK & DETEKSI MULTI-HERO
# =========================================================

func update_touching_players_and_get_target(exited_body: Node2D = null) -> CharacterBody2D:
	if exited_body != null and exited_body is CharacterBody2D:
		touching_players.erase(exited_body)

	# Sinkronkan dengan overlap aktual jika tidak sedang dalam pemanggilan body_exited
	if exited_body == null and hitbox and is_instance_valid(hitbox) and not is_dead:
		for b in hitbox.get_overlapping_bodies():
			if b is CharacterBody2D and is_instance_valid(b):
				if not ("is_dead" in b and b.is_dead) and b.is_in_group("player"):
					if b not in touching_players:
						touching_players.append(b)

	# Bersihkan entri yang tidak valid, sudah mati, atau keluar dari grup player
	var valid_touching: Array[CharacterBody2D] = []
	for p in touching_players:
		if is_instance_valid(p) and p is CharacterBody2D:
			if not ("is_dead" in p and p.is_dead) and p.is_in_group("player"):
				if p not in valid_touching:
					valid_touching.append(p)
	touching_players = valid_touching
	is_touching_player = not touching_players.is_empty()

	if touching_players.is_empty():
		return null

	# Pilih hero terdekat dari musuh di antara seluruh hero yang menyentuh hitbox
	var closest: CharacterBody2D = touching_players[0]
	var min_dist: float = global_position.distance_to(closest.global_position)
	for i in range(1, touching_players.size()):
		var d: float = global_position.distance_to(touching_players[i].global_position)
		if d < min_dist:
			min_dist = d
			closest = touching_players[i]
	return closest


func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_dead or is_training_dummy or is_alaric_boss or is_skeleton_boss or contact_damage <= 0 or body == null:
		return
	if body is CharacterBody2D and body.is_in_group("player") and not ("is_dead" in body and body.is_dead):
		if body not in touching_players:
			touching_players.append(body)
		var target_player := update_touching_players_and_get_target()
		if target_player:
			if current_state == State.IDLE_PATROL:
				current_state = State.CHASE
				player = target_player
				if alert_sfx_cooldown_timer <= 0.0:
					play_sfx(SFX_ALERT, -2.0)
					alert_sfx_cooldown_timer = 5.0
			# Langsung berikan damage jika cooldown siap
			if damage_timer <= 0.0:
				if target_player.has_method("take_damage"):
					target_player.take_damage(contact_damage, global_position)
				play_sfx(SFX_CONTACT_HIT, 0.0)
				damage_timer = attack_cooldown


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		update_touching_players_and_get_target(body)


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


# =========================================================
# ALARIC BOSS COMBAT SYSTEM (ATRIBUT, ENRAGE 35%, 3 POLA SERANGAN, INDIKATOR & EFEK TEBASAN)
# =========================================================

func reset_alaric_boss_state() -> void:
	is_alaric_boss = true
	_cleanup_alaric_combat_effects()
	max_health = ALARIC_MAX_HP
	current_health = ALARIC_MAX_HP
	is_dead = false
	is_shooting = false
	is_alaric_enraged = false
	contact_damage = 0
	melee_damage = ALARIC_BASIC_DAMAGE
	melee_attack_range = 115.0
	chase_speed = get_alaric_current_move_speed()
	alaric_basic_cd_timer = 0.0
	alaric_triple_cd_timer = 0.8 # Sedikit jeda pembuka agar variasi kombo mengalir natural
	alaric_rupture_cd_timer = 1.6
	alaric_recovery_timer = 0.0
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		if _style_fill:
			health_bar.add_theme_stylebox_override("fill", _style_fill)
	if damage_bar:
		damage_bar.max_value = max_health
		damage_bar.value = current_health


func _cleanup_alaric_combat_effects() -> void:
	alaric_attack_token += 1
	is_shooting = false
	alaric_recovery_timer = 0.0
	if is_instance_valid(alaric_active_telegraph):
		alaric_active_telegraph.queue_free()
	alaric_active_telegraph = null
	if is_instance_valid(alaric_enrage_aura):
		alaric_enrage_aura.queue_free()
	alaric_enrage_aura = null


func get_alaric_base_character_speed() -> float:
	# Movement speed seperti karakter lain (SPRINT_SPEED := 220.0 pada player_knight / hero lainnya)
	if is_inside_tree():
		var party := get_tree().get_nodes_in_group("player")
		for p in party:
			if is_instance_valid(p) and "SPRINT_SPEED" in p:
				return float(p.SPRINT_SPEED)
	return ALARIC_BASE_MOVE_SPEED


func get_alaric_current_move_speed() -> float:
	var base_spd := get_alaric_base_character_speed()
	if is_alaric_enraged:
		return base_spd * ALARIC_ENRAGE_SPEED_MULTIPLIER # Meningkat 8% saat Enrage
	return base_spd


func get_alaric_ground_origin() -> Vector2:
	return global_position + Vector2(0.0, 22.0)


func get_target_ground_origin(target_node: Node2D) -> Vector2:
	if not is_instance_valid(target_node):
		return get_alaric_ground_origin()
	return target_node.global_position + Vector2(0.0, 22.0)


func _check_and_update_alaric_enrage() -> void:
	if not is_alaric_boss or is_dead or current_health <= 0:
		return
	var enrage_threshold: int = int(float(max_health) * ALARIC_ENRAGE_HP_RATIO) # 35% dari 2600 = 910 HP
	if not is_alaric_enraged and current_health <= enrage_threshold:
		is_alaric_enraged = true
		chase_speed = get_alaric_current_move_speed()
		_trigger_alaric_enrage_visuals()
	else:
		chase_speed = get_alaric_current_move_speed()


func _trigger_alaric_enrage_visuals() -> void:
	play_sfx(SFX_ALERT, 1.5)
	_apply_boss_camera_shake(9.0)

	# Ubah warna bar HP menjadi merah-oranye membara saat Enrage
	if health_bar:
		var enrage_fill := StyleBoxFlat.new()
		enrage_fill.bg_color = Color(1.0, 0.32, 0.12, 0.98)
		enrage_fill.set_corner_radius_all(1)
		health_bar.add_theme_stylebox_override("fill", enrage_fill)

	if animated_sprite:
		animated_sprite.modulate = Color(1.22, 0.82, 0.78)

	# Pasang aura Enrage di bawah kaki Alaric
	if not is_instance_valid(alaric_enrage_aura):
		var aura := AlaricEnrageAuraNode.new()
		aura.name = "AlaricEnrageAura"
		aura.position = Vector2(0.0, 4.4) # Skala lokal 5x -> global +22px
		aura.scale = Vector2(0.2, 0.2)    # Kompensasi scale parent (5x) agar ukuran pixel 1:1
		aura.z_index = -1
		add_child(aura)
		alaric_enrage_aura = aura

	# Tampilkan teks melayang "ENRAGE! (+8% SPD)"
	if get_parent():
		var popup := Node2D.new()
		popup.global_position = global_position + Vector2(0.0, -75.0)
		popup.z_index = 25
		var lbl := Label.new()
		lbl.text = "ENRAGE! (+8% SPEED)"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(-110.0, -14.0)
		lbl.size = Vector2(220.0, 28.0)
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.2, 1.0))
		lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.02, 1.0))
		lbl.add_theme_constant_override("outline_size", 4)
		popup.add_child(lbl)
		get_parent().add_child(popup)

		var tw := popup.create_tween()
		tw.tween_property(popup, "global_position:y", popup.global_position.y - 36.0, 1.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(popup, "modulate:a", 0.0, 1.25).set_delay(0.35)
		tw.tween_callback(popup.queue_free)


func _apply_boss_camera_shake(intensity: float = 8.0) -> void:
	if not is_inside_tree():
		return
	var game_node = get_tree().current_scene
	if game_node and game_node.has_method("apply_camera_shake"):
		game_node.apply_camera_shake(intensity)


func _process_alaric_boss_ai(delta: float, dir: Vector2, _dist_to_player: float, has_los: bool) -> void:
	chase_speed = get_alaric_current_move_speed()

	# 1. Jika sedang dalam Wind-up atau eksekusi tebasan (is_shooting), diam di tempat
	if is_shooting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 2. Jika sedang dalam fase Recovery pasca serangan, diam di tempat sampai recovery selesai
	if alaric_recovery_timer > 0.0:
		alaric_recovery_timer = maxf(0.0, alaric_recovery_timer - delta)
		velocity = Vector2.ZERO
		move_and_slide()
		play_idle_animation()
		return

	# 3. Evaluasi jarak serang ke target
	var my_origin := get_alaric_ground_origin()
	var target_origin := get_target_ground_origin(player)
	var ground_dist := my_origin.distance_to(target_origin)
	var to_target_dir := (target_origin - my_origin).normalized()
	if to_target_dir == Vector2.ZERO:
		to_target_dir = dir

	var engage_range: float = 115.0
	if ground_dist <= engage_range and has_los:
		is_flanking = false
		velocity = Vector2.ZERO
		move_and_slide_with_separation()

		# Prioritas Pemilihan Pola Serangan Alaric sesuai ketersediaan Cooldown:
		# 1) Ground Rupture (1 petak di keliling setiap arah karakter) - CD 7.5s
		if alaric_rupture_cd_timer <= 0.0:
			_execute_alaric_ground_rupture(to_target_dir)
			return
		# 2) Triple Advance (3 hit, 1 petak di depan karakter) - CD 4.5s
		if alaric_triple_cd_timer <= 0.0:
			_execute_alaric_triple_advance(to_target_dir)
			return
		# 3) Basic Attack (3x1 di depan sekaligus diagonal karakter) - CD 1.6s
		if alaric_basic_cd_timer <= 0.0:
			_execute_alaric_basic_attack(to_target_dir)
			return

		# Jika semua serangan sedang cooldown, hadap target dalam posisi siaga
		last_direction = get_cardinal_direction(to_target_dir)
		play_idle_animation()
	elif has_los:
		is_flanking = false
		var move_dir: Vector2 = to_target_dir
		velocity = move_dir * chase_speed
		move_and_slide_with_separation()
		apply_smoothed_facing(move_dir, delta)
	else:
		# Navigasi menghindar rintangan jika terhalang
		flank_timeout -= delta
		if not is_flanking or flank_timeout <= 0.0:
			calculate_flank_waypoints(player)

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
		velocity = move_dir * chase_speed
		move_and_slide_with_separation()
		apply_smoothed_facing(move_dir, delta)


# ---------------------------------------------------------
# POLA SERANGAN 1: BASIC ATTACK (3x1 [didepan sekaligus diagonal] karakter)
# Damage: 160 | Wind-up: 0.45s | Recovery: 0.75s | Cooldown: 1.6s
# Catatan: TIDAK menggunakan indikator area serangan, langsung visual efek tebasan 3x1
# ---------------------------------------------------------
func _execute_alaric_basic_attack(target_dir: Vector2) -> void:
	if is_dead or is_shooting:
		return
	is_shooting = true
	alaric_basic_cd_timer = ALARIC_BASIC_COOLDOWN
	var my_token := alaric_attack_token

	var cardinal_dir := get_cardinal_direction(target_dir)
	last_direction = cardinal_dir

	# Fase Wind-up / Charge (0.45 s) TANPA indikator area serangan
	_play_alaric_windup_pose("atk", false)
	await get_tree().create_timer(ALARIC_BASIC_WINDUP).timeout
	if not is_instance_valid(self) or is_dead or my_token != alaric_attack_token:
		return

	# Eksekusi Tebasan Basic Attack (3x1 petak di depan sekaligus diagonal)
	var origin := get_alaric_ground_origin()
	play_attack_animation()
	play_sfx(SFX_KNIGHT_SLASH, 0.5)

	# Munculkan Visual Efek Tebasan Lebar 3x1 di area depan + diagonal
	_spawn_alaric_slash_vfx(AlaricSlashEffectNode.SlashMode.BASIC_3X1, origin, cardinal_dir, 1)

	# Evaluasi Hit Detection di area 3x1 (1 petak ke depan, 3 petak melebar kiri-tengah-kanan)
	_apply_alaric_box_damage(origin, cardinal_dir, ALARIC_TILE_SIZE, ALARIC_TILE_SIZE * 3.0, ALARIC_BASIC_DAMAGE, false)

	# Tunggu animasi ayunan pedang selesai (~0.25s), lalu masuk fase Recovery (0.75 s)
	alaric_recovery_timer = ALARIC_BASIC_RECOVERY
	await get_tree().create_timer(0.24).timeout
	if not is_instance_valid(self) or is_dead or my_token != alaric_attack_token:
		return

	is_shooting = false
	play_idle_animation()


# ---------------------------------------------------------
# POLA SERANGAN 2: TRIPLE ADVANCE (3 hit [1 petak di depan] karakter)
# Damage: 110/hit (3 hit) | Wind-up: 0.45s | Recovery: 1.1s | Cooldown: 4.5s
# Catatan: Menggunakan Indikator Area 1 petak di depan + 3x Visual Efek Tebasan beruntun
# ---------------------------------------------------------
func _execute_alaric_triple_advance(target_dir: Vector2) -> void:
	if is_dead or is_shooting:
		return
	is_shooting = true
	alaric_triple_cd_timer = ALARIC_TRIPLE_COOLDOWN
	var my_token := alaric_attack_token

	var cardinal_dir := get_cardinal_direction(target_dir)
	last_direction = cardinal_dir
	var origin := get_alaric_ground_origin()

	# 1. Tampilkan Indikator Area Serangan (1 petak tepat di depan karakter) selama Wind-up (0.45 s)
	_spawn_alaric_telegraph(AlaricTelegraphNode.TelegraphMode.TRIPLE_ADVANCE_1X1, origin, cardinal_dir, ALARIC_TRIPLE_WINDUP)
	_play_alaric_windup_pose("atk", true)

	await get_tree().create_timer(ALARIC_TRIPLE_WINDUP).timeout
	if not is_instance_valid(self) or is_dead or my_token != alaric_attack_token:
		return

	# Hapus indikator saat wind-up selesai dan mulai 3 hit beruntun
	if is_instance_valid(alaric_active_telegraph):
		alaric_active_telegraph.queue_free()
		alaric_active_telegraph = null

	# 2. Eksekusi 3 Hit Beruntun (110 damage / hit) pada 1 petak di depan karakter
	for hit_idx in range(1, ALARIC_TRIPLE_HIT_COUNT + 1):
		if not is_instance_valid(self) or is_dead or my_token != alaric_attack_token:
			return

		var cur_origin := get_alaric_ground_origin()
		_play_alaric_combo_swing_animation(hit_idx)
		play_sfx(SFX_KNIGHT_SLASH, 1.0 + float(hit_idx) * 0.4)

		# Visual efek tebasan untuk masing-masing hit di petak depan
		_spawn_alaric_slash_vfx(AlaricSlashEffectNode.SlashMode.TRIPLE_1X1, cur_origin, cardinal_dir, hit_idx)

		# Berikan 110 damage untuk hit ini jika player berada di 1 petak depan (bypass i-frame antar hit kombo)
		_apply_alaric_box_damage(cur_origin, cardinal_dir, ALARIC_TILE_SIZE, ALARIC_TILE_SIZE, ALARIC_TRIPLE_DAMAGE_PER_HIT, true)

		if hit_idx < ALARIC_TRIPLE_HIT_COUNT:
			await get_tree().create_timer(ALARIC_TRIPLE_HIT_INTERVAL).timeout

	if not is_instance_valid(self) or is_dead or my_token != alaric_attack_token:
		return

	# 3. Masuk fase Recovery (1.1 s)
	alaric_recovery_timer = ALARIC_TRIPLE_RECOVERY
	await get_tree().create_timer(0.22).timeout
	if not is_instance_valid(self) or is_dead or my_token != alaric_attack_token:
		return

	is_shooting = false
	play_idle_animation()


# ---------------------------------------------------------
# POLA SERANGAN 3: GROUND RUPTURE (1 petak di keliling [setiap arah] karakter)
# Damage: 220 | Wind-up: 0.9s | Recovery: 1.3s | Cooldown: 7.5s
# Catatan: Menggunakan Indikator Area 1 petak sekeliling (8 arah) + Visual Efek Tebasan Melingkar & Retakan
# ---------------------------------------------------------
func _execute_alaric_ground_rupture(target_dir: Vector2) -> void:
	if is_dead or is_shooting:
		return
	is_shooting = true
	alaric_rupture_cd_timer = ALARIC_RUPTURE_COOLDOWN
	var my_token := alaric_attack_token

	var cardinal_dir := get_cardinal_direction(target_dir)
	last_direction = cardinal_dir
	var origin := get_alaric_ground_origin()

	# 1. Tampilkan Indikator Area Serangan (1 petak di keliling setiap arah karakter) selama Wind-up (0.9 s)
	_spawn_alaric_telegraph(AlaricTelegraphNode.TelegraphMode.GROUND_RUPTURE_3X3, origin, cardinal_dir, ALARIC_RUPTURE_WINDUP)
	_play_alaric_windup_pose("skill", true)

	await get_tree().create_timer(ALARIC_RUPTURE_WINDUP).timeout
	if not is_instance_valid(self) or is_dead or my_token != alaric_attack_token:
		return

	if is_instance_valid(alaric_active_telegraph):
		alaric_active_telegraph.queue_free()
		alaric_active_telegraph = null

	# 2. Eksekusi Hantaman & Tebasan Ground Rupture ke seluruh 1 petak sekeliling (setiap arah)
	var cur_origin := get_alaric_ground_origin()
	play_skill_animation()
	play_sfx(SFX_KNIGHT_SLASH, 2.5)
	play_sfx(SFX_CONTACT_HIT, 1.5)
	_apply_boss_camera_shake(11.5)

	# Visual Efek Tebasan Melingkar & Hantaman Ground Rupture di 8 petak sekeliling
	_spawn_alaric_slash_vfx(AlaricSlashEffectNode.SlashMode.GROUND_RUPTURE_3X3, cur_origin, cardinal_dir, 1)

	# Evaluasi Hit Detection di area 1 petak sekeliling (setiap arah / 3x3 petak berpusat di Alaric)
	_apply_alaric_surrounding_damage(cur_origin, ALARIC_TILE_SIZE * 1.5, ALARIC_RUPTURE_DAMAGE)

	# 3. Masuk fase Recovery (1.3 s)
	alaric_recovery_timer = ALARIC_RUPTURE_RECOVERY
	await get_tree().create_timer(0.32).timeout
	if not is_instance_valid(self) or is_dead or my_token != alaric_attack_token:
		return

	is_shooting = false
	play_idle_animation()


func _play_alaric_windup_pose(mode: String, with_glow: bool) -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	animated_sprite.flip_h = false
	var suffix := "s"
	if last_direction == Vector2.UP:
		suffix = "n"
	elif last_direction == Vector2.LEFT:
		suffix = "w"
	elif last_direction == Vector2.RIGHT:
		suffix = "e"

	var anim_name := ("%s_%s" % [mode, suffix])
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		anim_name = "atk_" + suffix
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		animated_sprite.pause()
		animated_sprite.frame = 1 if animated_sprite.sprite_frames.get_frame_count(anim_name) > 1 else 0

	if with_glow:
		var glow_col := Color(1.45, 0.72, 0.55) if is_alaric_enraged else Color(1.32, 0.92, 0.65)
		animated_sprite.modulate = glow_col


func _play_alaric_combo_swing_animation(hit_idx: int) -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	var default_col := Color(1.22, 0.82, 0.78) if is_alaric_enraged else Color.WHITE
	animated_sprite.modulate = default_col
	animated_sprite.flip_h = false

	var suffix := "s"
	if last_direction == Vector2.UP:
		suffix = "n"
	elif last_direction == Vector2.LEFT:
		suffix = "w"
	elif last_direction == Vector2.RIGHT:
		suffix = "e"

	var anim_name := "atk_%s_1" % suffix
	if hit_idx == 2:
		anim_name = "atk_%s_2" % suffix
	elif hit_idx == 3:
		anim_name = "skill_%s" % suffix

	if not animated_sprite.sprite_frames.has_animation(anim_name):
		anim_name = "atk_%s" % suffix
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.stop()
		animated_sprite.play(anim_name)
		if hit_idx < 3 and animated_sprite.sprite_frames.get_frame_count(anim_name) > 2:
			animated_sprite.frame = 2


func _apply_alaric_box_damage(origin: Vector2, forward_dir: Vector2, depth: float, width: float, dmg: int, bypass_iframe: bool) -> void:
	if not is_inside_tree():
		return
	var f_dir := forward_dir.normalized()
	if f_dir == Vector2.ZERO:
		f_dir = Vector2.DOWN
	var p_dir := Vector2(-f_dir.y, f_dir.x)

	# Area petak di depan karakter dimulai dari tepi depan badan Alaric sejauh 1 petak (depth)
	# Dengan pusat petak berada di origin + f_dir * (depth * 0.85)
	var box_center := origin + f_dir * (depth * 0.85)
	var half_depth := (depth * 0.5) + 22.0 # Toleransi radius hurtbox karakter pemain
	var half_width := (width * 0.5) + 18.0

	var players := get_tree().get_nodes_in_group("player")
	var hit_any := false
	for p in players:
		if not is_instance_valid(p) or not (p is CharacterBody2D) or not p.visible or ("is_dead" in p and p.is_dead):
			continue
		var p_origin := get_target_ground_origin(p)
		var rel := p_origin - box_center
		var local_forward := absf(rel.dot(f_dir))
		var local_lateral := absf(rel.dot(p_dir))

		if local_forward <= half_depth and local_lateral <= half_width:
			if bypass_iframe and "invulnerability_timer" in p:
				p.invulnerability_timer = 0.0
			if p.has_method("take_damage"):
				p.take_damage(dmg, global_position)
			hit_any = true

	if hit_any:
		play_sfx(SFX_KNIGHT_SLASH_HIT, 0.0)
		_apply_boss_camera_shake(6.5)


func _apply_alaric_surrounding_damage(origin: Vector2, half_extent: float, dmg: int) -> void:
	if not is_inside_tree():
		return
	# 1 petak di keliling setiap arah karakter = kotak 3x3 petak berpusat di origin
	var reach := half_extent + 18.0 # +18px toleransi radius hurtbox player
	var players := get_tree().get_nodes_in_group("player")
	var hit_any := false
	for p in players:
		if not is_instance_valid(p) or not (p is CharacterBody2D) or not p.visible or ("is_dead" in p and p.is_dead):
			continue
		var p_origin := get_target_ground_origin(p)
		var diff := p_origin - origin
		if absf(diff.x) <= reach and absf(diff.y) <= reach:
			if p.has_method("take_damage"):
				p.take_damage(dmg, global_position)
			hit_any = true

	if hit_any:
		play_sfx(SFX_KNIGHT_SLASH_HIT, 1.5)


func _spawn_alaric_telegraph(mode: int, origin: Vector2, forward_dir: Vector2, duration: float) -> void:
	if is_instance_valid(alaric_active_telegraph):
		alaric_active_telegraph.queue_free()
		alaric_active_telegraph = null
	if not get_parent():
		return

	var telegraph := AlaricTelegraphNode.new()
	telegraph.setup(mode, origin, forward_dir, ALARIC_TILE_SIZE, duration, is_alaric_enraged)
	get_parent().add_child(telegraph)
	alaric_active_telegraph = telegraph


func _spawn_alaric_slash_vfx(mode: int, origin: Vector2, forward_dir: Vector2, hit_idx: int = 1) -> void:
	if not get_parent():
		return
	var vfx := AlaricSlashEffectNode.new()
	vfx.setup(mode, origin, forward_dir, ALARIC_TILE_SIZE, hit_idx, is_alaric_enraged)
	get_parent().add_child(vfx)


# =========================================================
# VISUAL NODE 1: INDIKATOR AREA SERANGAN ALARIC (TELEGRAPH)
# Digunakan untuk Triple Advance (1 petak di depan) & Ground Rupture (1 petak sekeliling 8 arah)
# =========================================================
class AlaricTelegraphNode extends Node2D:
	enum TelegraphMode { TRIPLE_ADVANCE_1X1, GROUND_RUPTURE_3X3 }

	var mode: int = TelegraphMode.TRIPLE_ADVANCE_1X1
	var forward_dir: Vector2 = Vector2.DOWN
	var tile_size: float = 85.0
	var total_duration: float = 0.45
	var elapsed: float = 0.0
	var enraged: bool = false

	func setup(p_mode: int, p_origin: Vector2, p_dir: Vector2, p_tile_size: float, p_duration: float, p_enraged: bool) -> void:
		mode = p_mode
		global_position = p_origin
		forward_dir = p_dir.normalized() if p_dir != Vector2.ZERO else Vector2.DOWN
		tile_size = p_tile_size
		total_duration = maxf(0.05, p_duration)
		enraged = p_enraged
		z_index = 2 # Di atas permukaan tanah, di bawah kaki karakter (z_index 4)

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= total_duration + 0.15:
			queue_free()

	func _draw() -> void:
		var prog := clampf(elapsed / total_duration, 0.0, 1.0)
		var pulse := 0.5 + 0.5 * sin(elapsed * 22.0)

		var base_fill := Color(0.85, 0.14, 0.12, 0.24) if not enraged else Color(0.95, 0.18, 0.08, 0.30)
		var charge_fill := Color(1.0, 0.32, 0.16, 0.48 + 0.15 * prog) if not enraged else Color(1.0, 0.45, 0.12, 0.55 + 0.18 * prog)
		var border_col := Color(1.0, 0.28, 0.18, 0.88).lerp(Color(1.0, 0.92, 0.45, 1.0), prog * 0.7 + pulse * 0.2)
		var grid_col := Color(1.0, 0.55, 0.30, 0.42)

		if mode == TelegraphMode.TRIPLE_ADVANCE_1X1:
			# 1 petak tepat di depan karakter
			var center_offset := forward_dir * (tile_size * 0.85)
			var angle := forward_dir.angle()
			draw_set_transform(center_offset, angle, Vector2.ONE)

			var half := tile_size * 0.5
			var full_rect := Rect2(Vector2(-half, -half), Vector2(tile_size, tile_size))

			# 1. Latar area bahaya 1 petak
			draw_rect(full_rect, base_fill, true)

			# 2. Pengisian charge progresif dari sisi Alaric ke depan
			var fill_w := tile_size * prog
			var charge_rect := Rect2(Vector2(-half, -half), Vector2(fill_w, tile_size))
			draw_rect(charge_rect, charge_fill, true)

			# 3. Tiga panah chevron (>>>) penanda Triple Advance (3 hit)
			var chevron_col := Color(1.0, 0.90, 0.55, 0.55 + 0.35 * prog)
			for i in range(3):
				var cx := -half * 0.48 + float(i) * (tile_size * 0.26)
				var pts := PackedVector2Array([
					Vector2(cx - 6.0, -14.0),
					Vector2(cx + 7.0, 0.0),
					Vector2(cx - 6.0, 14.0)
				])
				draw_polyline(pts, chevron_col, 2.2)

			# 4. Garis tepi tegas & siku sudut indikator
			draw_rect(full_rect, border_col, false, 2.4)
			var inner_rect := full_rect.grow(-4.0)
			draw_rect(inner_rect, Color(border_col.r, border_col.g, border_col.b, 0.35), false, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		elif mode == TelegraphMode.GROUND_RUPTURE_3X3:
			# 1 petak di keliling setiap arah karakter (grid 3x3 petak di sekitar Alaric)
			var half_total := tile_size * 1.5
			var full_rect := Rect2(Vector2(-half_total, -half_total), Vector2(tile_size * 3.0, tile_size * 3.0))

			# 1. Gambar 8 petak sekeliling + pusat
			for gx in range(-1, 2):
				for gy in range(-1, 2):
					var cell_pos := Vector2(float(gx) * tile_size - tile_size * 0.5, float(gy) * tile_size - tile_size * 0.5)
					var cell_rect := Rect2(cell_pos, Vector2(tile_size, tile_size))
					if gx == 0 and gy == 0:
						draw_rect(cell_rect, Color(base_fill.r, base_fill.g, base_fill.b, 0.14), true)
					else:
						draw_rect(cell_rect, base_fill, true)
						draw_rect(cell_rect.grow(-2.0), grid_col, false, 1.0)

			# 2. Pengisian charge membesar dari pusat ke batas luar 1 petak sekeliling
			var cur_half := half_total * prog
			var charge_rect := Rect2(Vector2(-cur_half, -cur_half), Vector2(cur_half * 2.0, cur_half * 2.0))
			draw_rect(charge_rect, charge_fill, true)
			draw_rect(charge_rect, Color(1.0, 0.85, 0.35, 0.75), false, 1.8)

			# 3. Garis silang diagonal & kardinal penanda 8 arah ledakan
			var line_col := Color(1.0, 0.78, 0.35, 0.38 + 0.35 * prog)
			var dirs: Array[Vector2] = [
				Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP,
				Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
				Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()
			]
			for d in dirs:
				draw_line(d * (tile_size * 0.35), d * (half_total * 0.92), line_col, 1.8)

			# 4. Border luar utama 3x3 petak
			draw_rect(full_rect, border_col, false, 2.8)


# =========================================================
# VISUAL NODE 2: EFEK TEBASAN PEDANG ALARIC (SLASH VFX)
# Menampilkan visual tebasan sesuai bentuk area:
# - BASIC_3X1: Sapuan tebasan sabit lebar 3x1 petak (depan + diagonal kiri & kanan)
# - TRIPLE_1X1: Tebasan beruntun (Hit 1, Hit 2, Hit 3) di dalam 1 petak depan
# - GROUND_RUPTURE_3X3: Gelombang tebasan memutar 360° & retakan energi di 8 petak sekeliling
# =========================================================
class AlaricSlashEffectNode extends Node2D:
	enum SlashMode { BASIC_3X1, TRIPLE_1X1, GROUND_RUPTURE_3X3 }

	var mode: int = SlashMode.BASIC_3X1
	var forward_dir: Vector2 = Vector2.DOWN
	var tile_size: float = 85.0
	var hit_index: int = 1
	var enraged: bool = false
	var elapsed: float = 0.0
	var duration: float = 0.28

	func setup(p_mode: int, p_origin: Vector2, p_dir: Vector2, p_tile_size: float, p_hit_idx: int, p_enraged: bool) -> void:
		mode = p_mode
		global_position = p_origin
		forward_dir = p_dir.normalized() if p_dir != Vector2.ZERO else Vector2.DOWN
		tile_size = p_tile_size
		hit_index = p_hit_idx
		enraged = p_enraged
		z_index = 6 # Di atas karakter agar kilatan tebasan pedang terlihat jelas
		if mode == SlashMode.GROUND_RUPTURE_3X3:
			duration = 0.42
		elif mode == SlashMode.TRIPLE_1X1:
			duration = 0.22
		else:
			duration = 0.28

	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := clampf(elapsed / duration, 0.0, 1.0)
		var alpha := clampf(1.0 - pow(t, 1.6), 0.0, 1.0)

		var core_col := Color(1.0, 0.98, 0.90, alpha)
		var glow_col := Color(1.0, 0.72, 0.22, alpha * 0.88) if not enraged else Color(1.0, 0.35, 0.12, alpha * 0.95)
		var edge_col := Color(0.92, 0.26, 0.16, alpha * 0.65) if not enraged else Color(0.98, 0.12, 0.22, alpha * 0.82)

		if mode == SlashMode.BASIC_3X1:
			# Area 3x1 di depan sekaligus diagonal (kedalaman 1 petak, lebar 3 petak)
			var center_offset := forward_dir * (tile_size * 0.85)
			draw_set_transform(center_offset, forward_dir.angle(), Vector2.ONE)

			var half_d := tile_size * 0.5
			var half_w := tile_size * 1.5

			# Flash tipis penanda area sapuan 3x1 saat tebasan melintas
			var flash_rect := Rect2(Vector2(-half_d, -half_w), Vector2(tile_size, tile_size * 3.0))
			draw_rect(flash_rect, Color(glow_col.r, glow_col.g, glow_col.b, alpha * 0.18), true)
			draw_rect(flash_rect, Color(glow_col.r, glow_col.g, glow_col.b, alpha * 0.42), false, 1.5)

			# Busur tebasan pedang sabit lebar menyapu sepanjang 3 petak (-half_w .. +half_w)
			var outer_pts := PackedVector2Array()
			var inner_pts := PackedVector2Array()
			var steps := 20
			var sweep_prog := clampf(t * 2.2, 0.25, 1.0)
			for i in range(steps + 1):
				var u := -1.0 + 2.0 * (float(i) / float(steps)) * sweep_prog
				var y_pos := u * (half_w * 0.94)
				var curve_x := (1.0 - u * u) * (half_d * 0.85) - half_d * 0.25
				var thickness := (1.0 - u * u) * 22.0 * (1.0 - t * 0.4)
				outer_pts.append(Vector2(curve_x + thickness * 0.5, y_pos))
				inner_pts.append(Vector2(curve_x - thickness * 0.5, y_pos))

			var crescent_poly := PackedVector2Array()
			for pt in outer_pts:
				crescent_poly.append(pt)
			for i in range(inner_pts.size() - 1, -1, -1):
				crescent_poly.append(inner_pts[i])

			if crescent_poly.size() >= 3:
				draw_colored_polygon(crescent_poly, glow_col)
			draw_polyline(outer_pts, core_col, 3.8)
			draw_polyline(inner_pts, edge_col, 2.0)

			# 3 garis kilatan dampak di petak kiri-depan, tengah-depan, dan kanan-depan
			for lane in [-1, 0, 1]:
				var ly := float(lane) * tile_size
				draw_line(Vector2(-half_d * 0.5, ly - 14.0), Vector2(half_d * 0.65, ly + 14.0), Color(core_col.r, core_col.g, core_col.b, alpha * 0.75), 2.2)

			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		elif mode == SlashMode.TRIPLE_1X1:
			# Area 1 petak tepat di depan karakter (3 hit combo)
			var center_offset := forward_dir * (tile_size * 0.85)
			draw_set_transform(center_offset, forward_dir.angle(), Vector2.ONE)

			var half := tile_size * 0.5
			var box_rect := Rect2(Vector2(-half, -half), Vector2(tile_size, tile_size))
			draw_rect(box_rect, Color(glow_col.r, glow_col.g, glow_col.b, alpha * 0.24), true)
			draw_rect(box_rect, Color(core_col.r, core_col.g, core_col.b, alpha * 0.65), false, 2.0)

			var reach := half * 0.86
			if hit_index == 1:
				# Hit 1: Tebasan diagonal tajam dari kanan-atas ke kiri-bawah
				var p1 := Vector2(-reach * 0.7, -reach)
				var p2 := Vector2(reach, reach)
				var ctrl := Vector2(reach * 0.55, -reach * 0.35)
				_draw_curved_blade_slash(p1, ctrl, p2, 16.0 * (1.0 - t * 0.3), core_col, glow_col, edge_col)
			elif hit_index == 2:
				# Hit 2: Tebasan diagonal balasan dari kiri-bawah ke kanan-atas
				var p1 := Vector2(-reach * 0.7, reach)
				var p2 := Vector2(reach, -reach)
				var ctrl := Vector2(reach * 0.55, reach * 0.35)
				_draw_curved_blade_slash(p1, ctrl, p2, 16.0 * (1.0 - t * 0.3), core_col, glow_col, edge_col)
			else:
				# Hit 3: Tebasan silang X + tusukan gelombang depan (Finisher Triple Advance)
				var p1a := Vector2(-reach * 0.8, -reach * 0.85)
				var p2a := Vector2(reach * 0.9, reach * 0.85)
				var p1b := Vector2(-reach * 0.8, reach * 0.85)
				var p2b := Vector2(reach * 0.9, -reach * 0.85)
				_draw_curved_blade_slash(p1a, Vector2(reach * 0.25, 0.0), p2a, 14.0, core_col, glow_col, edge_col)
				_draw_curved_blade_slash(p1b, Vector2(reach * 0.25, 0.0), p2b, 14.0, core_col, glow_col, edge_col)
				draw_line(Vector2(-reach, 0.0), Vector2(reach * 1.05, 0.0), core_col, 4.0)

			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		elif mode == SlashMode.GROUND_RUPTURE_3X3:
			# Area 1 petak di keliling setiap arah karakter (3x3 petak = 8 petak sekeliling)
			var half_total := tile_size * 1.5
			var full_rect := Rect2(Vector2(-half_total, -half_total), Vector2(tile_size * 3.0, tile_size * 3.0))

			# 1. Kilatan petak-petak tanah yang retak di 8 arah sekeliling
			for gx in range(-1, 2):
				for gy in range(-1, 2):
					if gx == 0 and gy == 0:
						continue
					var cell_pos := Vector2(float(gx) * tile_size - tile_size * 0.5, float(gy) * tile_size - tile_size * 0.5)
					var cell_rect := Rect2(cell_pos, Vector2(tile_size, tile_size)).grow(-2.0)
					draw_rect(cell_rect, Color(glow_col.r, glow_col.g, glow_col.b, alpha * 0.25), true)
					draw_rect(cell_rect, Color(edge_col.r, edge_col.g, edge_col.b, alpha * 0.65), false, 1.6)

			# 2. Cincin tebasan putar 360 derajat yang menyapu seluruh 8 petak sekeliling
			var max_r := half_total * 0.98
			var cur_r := lerpf(tile_size * 0.45, max_r, clampf(t * 1.5, 0.0, 1.0))
			draw_arc(Vector2.ZERO, cur_r, 0.0, TAU, 40, glow_col, 14.0 * (1.0 - t * 0.4))
			draw_arc(Vector2.ZERO, cur_r + 4.0, 0.0, TAU, 40, core_col, 3.6)

			# 3. Delapan bilah tebasan & retakan tanah memancar ke setiap petak sekeliling (N, S, E, W, NE, NW, SE, SW)
			var dirs: Array[Vector2] = [
				Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP,
				Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
				Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()
			]
			for d in dirs:
				var perp := Vector2(-d.y, d.x)
				var p_start := d * (tile_size * 0.35)
				var p_tip := d * (half_total * (0.55 + 0.42 * clampf(t * 1.7, 0.0, 1.0)))
				var p_mid := (p_start + p_tip) * 0.5
				var spike_poly := PackedVector2Array([
					p_start,
					p_mid + perp * 11.0 * (1.0 - t * 0.3),
					p_tip,
					p_mid - perp * 11.0 * (1.0 - t * 0.3)
				])
				draw_colored_polygon(spike_poly, glow_col)
				draw_line(p_start, p_tip, core_col, 2.8)

			draw_rect(full_rect, Color(core_col.r, core_col.g, core_col.b, alpha * 0.55), false, 2.2)

	func _draw_curved_blade_slash(p1: Vector2, ctrl: Vector2, p2: Vector2, max_thick: float, core_col: Color, glow_col: Color, edge_col: Color) -> void:
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		var steps := 12
		var dir_norm := (p2 - p1).normalized()
		var perp := Vector2(-dir_norm.y, dir_norm.x)
		for i in range(steps + 1):
			var s := float(i) / float(steps)
			var q0 := p1.lerp(ctrl, s)
			var q1 := ctrl.lerp(p2, s)
			var pt := q0.lerp(q1, s)
			var w := sin(s * PI) * max_thick
			outer.append(pt + perp * (w * 0.55))
			inner.append(pt - perp * (w * 0.45))

		var poly := PackedVector2Array()
		for pt in outer:
			poly.append(pt)
		for i in range(inner.size() - 1, -1, -1):
			poly.append(inner[i])
		if poly.size() >= 3:
			draw_colored_polygon(poly, glow_col)
		draw_polyline(outer, core_col, 3.0)
		draw_polyline(inner, edge_col, 1.6)


# =========================================================
# VISUAL NODE 3: AURA ENRAGE ALARIC (AKTIF PADA HP <= 35%)
# =========================================================
class AlaricEnrageAuraNode extends Node2D:
	var time_passed: float = 0.0

	func _process(delta: float) -> void:
		time_passed += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(time_passed * 7.0)
		var r := 42.0 + pulse * 6.0
		draw_circle(Vector2.ZERO, r, Color(0.95, 0.22, 0.12, 0.18 + pulse * 0.10))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(1.0, 0.48, 0.18, 0.65 + pulse * 0.25), 2.2)


# =========================================================
# SKELETON BOSS COMBAT SYSTEM (7.200 HP, 10% DR, ENRAGE 30%, 4 SERANGAN AOE API & FIREBALL ORANYE)
# =========================================================

static func _get_or_create_skeleton_sprite_frames() -> SpriteFrames:
	if _skeleton_sprite_frames_cache != null:
		return _skeleton_sprite_frames_cache

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	var tex := load("res://assets/enemies/Skeleton.png") as Texture2D
	if not tex:
		_skeleton_sprite_frames_cache = frames
		return frames

	var img := tex.get_image()
	# Layout Skeleton.png (192x320, grid 32x32 -> 6 kolom x 10 baris):
	# Row 0: idle_s (6 frame), Row 1: idle_e (6 frame, flip untuk idle_w), Row 2: idle_n (6 frame)
	# Row 3: walk_s (6 frame), Row 4: walk_e (6 frame, flip untuk walk_w), Row 5: walk_n (6 frame)
	# Row 6: death (4 frame)
	# Row 7: atk_s/skill_s (4 frame), Row 8: atk_e/skill_e (4 frame, flip untuk atk_w/skill_w), Row 9: atk_n/skill_n (4 frame)
	var anim_defs: Array[Dictionary] = [
		{"name": &"idle_s", "row": 0, "count": 6, "speed": 7.0, "loop": true, "flip": false},
		{"name": &"idle_e", "row": 1, "count": 6, "speed": 7.0, "loop": true, "flip": false},
		{"name": &"idle_w", "row": 1, "count": 6, "speed": 7.0, "loop": true, "flip": true},
		{"name": &"idle_n", "row": 2, "count": 6, "speed": 7.0, "loop": true, "flip": false},
		{"name": &"walk_s", "row": 3, "count": 6, "speed": 10.0, "loop": true, "flip": false},
		{"name": &"walk_e", "row": 4, "count": 6, "speed": 10.0, "loop": true, "flip": false},
		{"name": &"walk_w", "row": 4, "count": 6, "speed": 10.0, "loop": true, "flip": true},
		{"name": &"walk_n", "row": 5, "count": 6, "speed": 10.0, "loop": true, "flip": false},
		{"name": &"atk_s", "row": 7, "count": 4, "speed": 10.0, "loop": false, "flip": false},
		{"name": &"atk_e", "row": 8, "count": 4, "speed": 10.0, "loop": false, "flip": false},
		{"name": &"atk_w", "row": 8, "count": 4, "speed": 10.0, "loop": false, "flip": true},
		{"name": &"atk_n", "row": 9, "count": 4, "speed": 10.0, "loop": false, "flip": false},
		{"name": &"skill_s", "row": 7, "count": 4, "speed": 10.0, "loop": false, "flip": false},
		{"name": &"skill_e", "row": 8, "count": 4, "speed": 10.0, "loop": false, "flip": false},
		{"name": &"skill_w", "row": 8, "count": 4, "speed": 10.0, "loop": false, "flip": true},
		{"name": &"skill_n", "row": 9, "count": 4, "speed": 10.0, "loop": false, "flip": false},
	]

	for def in anim_defs:
		var anim_name: StringName = def["name"]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, def["speed"])
		frames.set_animation_loop(anim_name, def["loop"])
		var row: int = def["row"]
		var count: int = def["count"]
		var do_flip: bool = def["flip"]
		for col in range(count):
			if do_flip and img != null:
				var sub_img := img.get_region(Rect2i(col * 32, row * 32, 32, 32))
				sub_img.flip_x()
				var flipped_tex := ImageTexture.create_from_image(sub_img)
				frames.add_frame(anim_name, flipped_tex)
			else:
				var atlas_tex := AtlasTexture.new()
				atlas_tex.atlas = tex
				atlas_tex.region = Rect2(col * 32, row * 32, 32, 32)
				frames.add_frame(anim_name, atlas_tex)

	_skeleton_sprite_frames_cache = frames
	return _skeleton_sprite_frames_cache


static func _recolor_cyan_fire_image_to_orange(src_img: Image) -> Image:
	var out_img := src_img.duplicate() as Image
	var w := out_img.get_width()
	var h := out_img.get_height()
	for y in range(h):
		for x in range(w):
			var c := out_img.get_pixel(x, y)
			if c.a <= 0.01:
				continue
			# Konversi palet api biru/cyan menjadi api oranye-merah-kuning membara
			var lum := clampf(c.b * 0.55 + c.g * 0.35 + c.r * 0.10, 0.0, 1.0)
			var fire_col: Color
			if lum >= 0.88:
				# Inti api putih-kekuningan sangat panas
				fire_col = Color(1.0, 0.96, 0.72, c.a)
			elif lum >= 0.68:
				# Api kuning-oranye terang
				var t := (lum - 0.68) / 0.20
				fire_col = Color(1.0, lerpf(0.58, 0.90, t), lerpf(0.10, 0.42, t), c.a)
			elif lum >= 0.42:
				# Api oranye menyala
				var t := (lum - 0.42) / 0.26
				fire_col = Color(lerpf(0.95, 1.0, t), lerpf(0.28, 0.58, t), lerpf(0.04, 0.10, t), c.a)
			else:
				# Tepi api merah-oranye bara
				var t := lum / 0.42
				fire_col = Color(lerpf(0.65, 0.95, t), lerpf(0.10, 0.28, t), 0.03, c.a)
			out_img.set_pixel(x, y, fire_col)
	return out_img


static func _get_or_create_orange_fireball_frames() -> SpriteFrames:
	if _orange_fireball_frames_cache != null:
		return _orange_fireball_frames_cache
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.set_animation_speed(&"default", 14.0)
		frames.set_animation_loop(&"default", true)
	else:
		frames.add_animation(&"default")
		frames.set_animation_speed(&"default", 14.0)
		frames.set_animation_loop(&"default", true)

	var tex := load("res://assets/skills/mage/fireball/meteor.png") as Texture2D
	if tex and tex.get_image():
		var orange_img := _recolor_cyan_fire_image_to_orange(tex.get_image())
		var orange_tex := ImageTexture.create_from_image(orange_img)
		for i in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = orange_tex
			atlas.region = Rect2(i * 64, 0, 64, 64)
			frames.add_frame(&"default", atlas)
	_orange_fireball_frames_cache = frames
	return _orange_fireball_frames_cache


static func _get_or_create_orange_explosion_frames() -> SpriteFrames:
	if _orange_explosion_frames_cache != null:
		return _orange_explosion_frames_cache
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.set_animation_speed(&"default", 14.0)
		frames.set_animation_loop(&"default", false)
	else:
		frames.add_animation(&"default")
		frames.set_animation_speed(&"default", 14.0)
		frames.set_animation_loop(&"default", false)

	var tex := load("res://assets/skills/mage/fireball/meteor-explode.png") as Texture2D
	if tex and tex.get_image():
		var orange_img := _recolor_cyan_fire_image_to_orange(tex.get_image())
		var orange_tex := ImageTexture.create_from_image(orange_img)
		for i in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = orange_tex
			atlas.region = Rect2(i * 64, 0, 64, 64)
			frames.add_frame(&"default", atlas)
	_orange_explosion_frames_cache = frames
	return _orange_explosion_frames_cache


func reset_skeleton_boss_state() -> void:
	is_skeleton_boss = true
	_cleanup_skeleton_combat_effects()
	max_health = SKELETON_MAX_HP
	current_health = SKELETON_MAX_HP
	is_dead = false
	is_shooting = false
	is_skeleton_enraged = false
	contact_damage = 0
	melee_damage = SKELETON_RING_DAMAGE
	chase_speed = get_skeleton_current_move_speed()
	collision_layer = 1
	collision_mask = 1
	skeleton_ring_cd_timer = 1.6
	skeleton_pillar_cd_timer = 4.2
	skeleton_burst_cd_timer = 7.0
	skeleton_rain_cd_timer = 10.0
	skeleton_recovery_timer = 0.0
	skeleton_attack_gap_timer = 1.4
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	if animated_sprite:
		animated_sprite.sprite_frames = _get_or_create_skeleton_sprite_frames()
		animated_sprite.modulate = Color.WHITE
		animated_sprite.offset = Vector2(0, 0)
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		if _style_fill:
			health_bar.add_theme_stylebox_override("fill", _style_fill)
	if damage_bar:
		damage_bar.max_value = max_health
		damage_bar.value = current_health
	_setup_player_collision_exceptions.call_deferred()


func _cleanup_skeleton_combat_effects() -> void:
	skeleton_attack_token += 1
	is_shooting = false
	skeleton_recovery_timer = 0.0
	for t in skeleton_active_telegraphs:
		if is_instance_valid(t):
			t.queue_free()
	skeleton_active_telegraphs.clear()
	if is_instance_valid(skeleton_enrage_aura):
		skeleton_enrage_aura.queue_free()
	skeleton_enrage_aura = null


func get_skeleton_current_move_speed() -> float:
	if is_skeleton_enraged:
		return SKELETON_ENRAGE_MOVE_SPEED # 2,6 tile/detik
	return SKELETON_NORMAL_MOVE_SPEED     # 2,2 tile/detik


func _check_and_update_skeleton_enrage() -> void:
	if not is_skeleton_boss or is_dead or current_health <= 0:
		return
	var enrage_threshold: int = int(float(max_health) * SKELETON_ENRAGE_HP_RATIO) # 30% dari 7.200 = 2.160 HP
	if not is_skeleton_enraged and current_health <= enrage_threshold:
		is_skeleton_enraged = true
		chase_speed = get_skeleton_current_move_speed()
		_trigger_skeleton_enrage_visuals()
	else:
		chase_speed = get_skeleton_current_move_speed()


func _trigger_skeleton_enrage_visuals() -> void:
	play_sfx(SFX_ALERT, 2.0)
	play_sfx(SFX_FIRE_CAST, 1.0)
	_apply_boss_camera_shake(10.5)

	if health_bar:
		var enrage_fill := StyleBoxFlat.new()
		enrage_fill.bg_color = Color(1.0, 0.42, 0.08, 0.98)
		enrage_fill.set_corner_radius_all(1)
		health_bar.add_theme_stylebox_override("fill", enrage_fill)

	if animated_sprite:
		animated_sprite.modulate = Color(1.35, 0.85, 0.55)

	if not is_instance_valid(skeleton_enrage_aura):
		var aura := SkeletonFireAuraNode.new()
		aura.name = "SkeletonEnrageAura"
		aura.position = Vector2(0.0, 4.4)
		aura.scale = Vector2(0.2, 0.2)
		aura.z_index = -1
		add_child(aura)
		skeleton_enrage_aura = aura

	if get_parent():
		var popup := Node2D.new()
		popup.global_position = global_position + Vector2(0.0, -78.0)
		popup.z_index = 25
		var lbl := Label.new()
		lbl.text = "ENRAGE! (API MEMBARA)"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(-120.0, -14.0)
		lbl.size = Vector2(240.0, 28.0)
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.48, 0.12, 1.0))
		lbl.add_theme_color_override("font_outline_color", Color(0.10, 0.02, 0.01, 1.0))
		lbl.add_theme_constant_override("outline_size", 4)
		popup.add_child(lbl)
		get_parent().add_child(popup)

		var tw := popup.create_tween()
		tw.tween_property(popup, "global_position:y", popup.global_position.y - 38.0, 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(popup, "modulate:a", 0.0, 1.3).set_delay(0.35)
		tw.tween_callback(popup.queue_free)


func _process_skeleton_boss_ai(delta: float, dir: Vector2, _dist_to_player: float, has_los: bool) -> void:
	chase_speed = get_skeleton_current_move_speed()

	# 1. Selama Wind-up / Casting aktif, Skeleton berhenti bergerak
	if is_shooting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 2. Selama fase Recovery pasca-serangan, Skeleton berhenti bergerak (terbuka untuk diserang pemain)
	if skeleton_recovery_timer > 0.0:
		skeleton_recovery_timer = maxf(0.0, skeleton_recovery_timer - delta)
		velocity = Vector2.ZERO
		move_and_slide()
		play_idle_animation()
		return

	# 3. Jeda napas antar serangan: Skeleton hanya bergerak mengejar tanpa langsung mengeluarkan serangan baru bertubi-tubi
	var can_start_new_attack: bool = true
	if skeleton_attack_gap_timer > 0.0:
		skeleton_attack_gap_timer = maxf(0.0, skeleton_attack_gap_timer - delta)
		can_start_new_attack = false

	var my_origin := get_alaric_ground_origin()
	var target_origin := get_target_ground_origin(player)
	var ground_dist := my_origin.distance_to(target_origin)
	var to_target_dir := (target_origin - my_origin).normalized()
	if to_target_dir == Vector2.ZERO:
		to_target_dir = dir

	if can_start_new_attack:
		# Evaluasi pemilihan 4 serangan utama Skeleton berdasarkan ketersediaan Cooldown & jarak:
		# A. Ring of Fire (Circular AoE 1->3 tile = 255 px, CD 7s)
		if skeleton_ring_cd_timer <= 0.0 and ground_dist <= SKELETON_TILE_SIZE * 2.85:
			velocity = Vector2.ZERO
			move_and_slide()
			_execute_skeleton_ring_of_fire(to_target_dir)
			return

		# C. Infernal Burst (Radial AoE 4 arah utama sejauh 4 tile = 340 px, CD 11s)
		if skeleton_burst_cd_timer <= 0.0 and ground_dist <= SKELETON_TILE_SIZE * 3.85:
			velocity = Vector2.ZERO
			move_and_slide()
			_execute_skeleton_infernal_burst(to_target_dir)
			return

		# B. Flame Pillar (Targeted AoE ke 2 karakter bergantian, CD 8s)
		if skeleton_pillar_cd_timer <= 0.0 and ground_dist <= 560.0:
			velocity = Vector2.ZERO
			move_and_slide()
			_execute_skeleton_flame_pillar(to_target_dir)
			return

		# D. Fireball Rain (Multi-target AoE 5 area acak, CD 13s)
		if skeleton_rain_cd_timer <= 0.0 and ground_dist <= 620.0:
			velocity = Vector2.ZERO
			move_and_slide()
			_execute_skeleton_fireball_rain(to_target_dir)
			return

		# Jika target masih agak jauh namun Flame Pillar / Fireball Rain sudah siap, tetap lepaskan
		if skeleton_pillar_cd_timer <= 0.0:
			velocity = Vector2.ZERO
			move_and_slide()
			_execute_skeleton_flame_pillar(to_target_dir)
			return
		if skeleton_rain_cd_timer <= 0.0:
			velocity = Vector2.ZERO
			move_and_slide()
			_execute_skeleton_fireball_rain(to_target_dir)
			return

	# Bergerak mengejar target hingga masuk jarak Ring of Fire / Infernal Burst
	if ground_dist > 95.0:
		if has_los:
			is_flanking = false
			velocity = to_target_dir * chase_speed
			move_and_slide_with_separation()
			apply_smoothed_facing(to_target_dir, delta)
		else:
			flank_timeout -= delta
			if not is_flanking or flank_timeout <= 0.0:
				calculate_flank_waypoints(player)
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
			velocity = move_dir * chase_speed
			move_and_slide_with_separation()
			apply_smoothed_facing(move_dir, delta)
	else:
		velocity = Vector2.ZERO
		move_and_slide_with_separation()
		last_direction = get_cardinal_direction(to_target_dir)
		play_idle_animation()


func _play_skeleton_cast_pose(is_windup: bool) -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	animated_sprite.flip_h = false
	var suffix := "s"
	if last_direction == Vector2.UP:
		suffix = "n"
	elif last_direction == Vector2.LEFT or last_direction == Vector2(-1, -1) or last_direction == Vector2(-1, 1):
		suffix = "w"
	elif last_direction == Vector2.RIGHT or last_direction == Vector2(1, -1) or last_direction == Vector2(1, 1):
		suffix = "e"

	var anim_name := "skill_" + suffix
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		anim_name = "atk_" + suffix
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	if is_windup:
		animated_sprite.modulate = Color(1.55, 0.72, 0.35) if is_skeleton_enraged else Color(1.38, 0.82, 0.48)
	else:
		animated_sprite.modulate = Color(1.35, 0.85, 0.55) if is_skeleton_enraged else Color.WHITE


# ---------------------------------------------------------
# A. RING OF FIRE (Circular AoE: Radius awal 1 tile -> Radius akhir 3 tile)
# Damage: 180 | Wind-up: 1,0s (Enrage: 0,75s) | Recovery: 1,2s | Cooldown: 7s
# ---------------------------------------------------------
func _execute_skeleton_ring_of_fire(target_dir: Vector2) -> void:
	if is_dead or is_shooting:
		return
	is_shooting = true
	skeleton_ring_cd_timer = SKELETON_RING_COOLDOWN
	var my_token := skeleton_attack_token
	var windup_dur: float = SKELETON_RING_WINDUP_ENRAGE if is_skeleton_enraged else SKELETON_RING_WINDUP_NORMAL

	last_direction = get_cardinal_direction(target_dir)
	var origin := get_alaric_ground_origin()

	# 1. Tampilkan indikator lingkaran merah-oranye (Radius 1 tile -> 3 tile)
	var telegraph := SkeletonTelegraphNode.new()
	telegraph.setup_ring_of_fire(origin, SKELETON_TILE_SIZE * SKELETON_RING_START_TILES, SKELETON_TILE_SIZE * SKELETON_RING_END_TILES, windup_dur, is_skeleton_enraged)
	if get_parent():
		get_parent().add_child(telegraph)
	skeleton_active_telegraphs.append(telegraph)

	_play_skeleton_cast_pose(true)
	play_sfx(SFX_FIRE_AIM, -1.0)

	await get_tree().create_timer(windup_dur).timeout
	if not is_instance_valid(self) or is_dead or my_token != skeleton_attack_token:
		return

	if is_instance_valid(telegraph):
		skeleton_active_telegraphs.erase(telegraph)
		telegraph.queue_free()

	# 2. Gelombang api & fireball oranye menyebar dari radius 1 tile ke 3 tile
	var cur_origin := get_alaric_ground_origin()
	_play_skeleton_cast_pose(false)
	play_sfx(SFX_FIRE_CAST, 1.0)
	play_sfx(SFX_FIRE_IMPACT, 0.5)
	_apply_boss_camera_shake(9.5)

	var vfx := SkeletonFireEffectNode.new()
	vfx.setup_ring_of_fire(cur_origin, SKELETON_TILE_SIZE * SKELETON_RING_START_TILES, SKELETON_TILE_SIZE * SKELETON_RING_END_TILES, is_skeleton_enraged, _get_or_create_orange_fireball_frames())
	if get_parent():
		get_parent().add_child(vfx)

	# Berikan 180 damage ke seluruh karakter dalam radius 3 tile
	_apply_skeleton_circle_damage(cur_origin, SKELETON_TILE_SIZE * SKELETON_RING_END_TILES, SKELETON_RING_DAMAGE)

	# 3. Fase Recovery (1,2 detik) + jeda antar serangan
	skeleton_ring_cd_timer = SKELETON_RING_COOLDOWN
	skeleton_recovery_timer = SKELETON_RING_RECOVERY
	skeleton_attack_gap_timer = SKELETON_ATTACK_BREATHING_GAP
	await get_tree().create_timer(0.28).timeout
	if not is_instance_valid(self) or is_dead or my_token != skeleton_attack_token:
		return
	is_shooting = false
	play_idle_animation()


# ---------------------------------------------------------
# B. FLAME PILLAR (Targeted AoE: 2 karakter secara bergantian, Radius 1 tile)
# Damage: 210 | Wind-up: 1,2s (Enrage: 0,9s) | Recovery: 1,0s | Cooldown: 8s
# Indikator mengikuti pergerakan target selama fase persiapan, lalu berhenti & api menyembur
# ---------------------------------------------------------
func _execute_skeleton_flame_pillar(target_dir: Vector2) -> void:
	if is_dead or is_shooting:
		return
	is_shooting = true
	skeleton_pillar_cd_timer = SKELETON_PILLAR_COOLDOWN
	var my_token := skeleton_attack_token
	var windup_dur: float = SKELETON_PILLAR_WINDUP_ENRAGE if is_skeleton_enraged else SKELETON_PILLAR_WINDUP_NORMAL
	var pillar_radius: float = SKELETON_TILE_SIZE * SKELETON_PILLAR_RADIUS_TILES

	last_direction = get_cardinal_direction(target_dir)

	# Pilih 2 karakter pemain yang hidup untuk ditandai secara bergantian
	var targets := _pick_skeleton_flame_pillar_targets(SKELETON_PILLAR_TARGET_COUNT)
	if targets.is_empty():
		is_shooting = false
		return

	for target_idx in range(targets.size()):
		if not is_instance_valid(self) or is_dead or my_token != skeleton_attack_token:
			return
		var t_hero: CharacterBody2D = targets[target_idx]
		if not is_instance_valid(t_hero) or ("is_dead" in t_hero and t_hero.is_dead):
			t_hero = get_best_target()
		if not is_instance_valid(t_hero):
			continue

		var start_pos := get_target_ground_origin(t_hero)
		var to_t := (start_pos - get_alaric_ground_origin()).normalized()
		if to_t != Vector2.ZERO:
			last_direction = get_cardinal_direction(to_t)

		# 1. Spawn lingkaran merah di lokasi karakter target saat ditandai (diam di tempat agar bisa dihindari saat berlari)
		var telegraph := SkeletonTelegraphNode.new()
		telegraph.setup_flame_pillar(start_pos, null, pillar_radius, windup_dur, is_skeleton_enraged)
		if get_parent():
			get_parent().add_child(telegraph)
		skeleton_active_telegraphs.append(telegraph)

		_play_skeleton_cast_pose(true)
		play_sfx(SFX_FIRE_AIM, -0.5)

		await get_tree().create_timer(windup_dur).timeout
		if not is_instance_valid(self) or is_dead or my_token != skeleton_attack_token:
			return

		var locked_impact_pos := start_pos
		if is_instance_valid(telegraph):
			skeleton_active_telegraphs.erase(telegraph)
			telegraph.queue_free()

		# 2. Lingkaran berhenti & semburan pilar api oranye menyembur dari tanah
		_play_skeleton_cast_pose(false)
		play_sfx(SFX_FIRE_IMPACT, 1.0)
		_apply_boss_camera_shake(9.0)

		var vfx := SkeletonFireEffectNode.new()
		vfx.setup_flame_pillar(locked_impact_pos, pillar_radius, is_skeleton_enraged, _get_or_create_orange_fireball_frames(), _get_or_create_orange_explosion_frames())
		if get_parent():
			get_parent().add_child(vfx)

		_apply_skeleton_circle_damage(locked_impact_pos, pillar_radius, SKELETON_PILLAR_DAMAGE)

	# 3. Fase Recovery (1,0 detik) + jeda antar serangan
	skeleton_pillar_cd_timer = SKELETON_PILLAR_COOLDOWN
	skeleton_recovery_timer = SKELETON_PILLAR_RECOVERY
	skeleton_attack_gap_timer = SKELETON_ATTACK_BREATHING_GAP
	await get_tree().create_timer(0.25).timeout
	if not is_instance_valid(self) or is_dead or my_token != skeleton_attack_token:
		return
	is_shooting = false
	play_idle_animation()


# ---------------------------------------------------------
# C. INFERNAL BURST (Radial AoE: 4 arah utama Atas, Bawah, Kiri, Kanan, Jangkauan 4 tile)
# Damage: 260 | Wind-up: 1,5s (Enrage: 1,2s) | Recovery: 1,5s | Cooldown: 11s
# ---------------------------------------------------------
func _execute_skeleton_infernal_burst(target_dir: Vector2) -> void:
	if is_dead or is_shooting:
		return
	is_shooting = true
	skeleton_burst_cd_timer = SKELETON_BURST_COOLDOWN
	var my_token := skeleton_attack_token
	var windup_dur: float = SKELETON_BURST_WINDUP_ENRAGE if is_skeleton_enraged else SKELETON_BURST_WINDUP_NORMAL
	var lane_length: float = SKELETON_TILE_SIZE * SKELETON_BURST_RANGE_TILES
	var lane_width: float = SKELETON_TILE_SIZE

	last_direction = get_cardinal_direction(target_dir)
	var origin := get_alaric_ground_origin()

	# 1. Tampilkan garis-garis merah-oranye ke 4 arah utama (Atas, Bawah, Kiri, Kanan) sejauh 4 tile
	var telegraph := SkeletonTelegraphNode.new()
	telegraph.setup_infernal_burst(origin, SKELETON_TILE_SIZE, SKELETON_BURST_RANGE_TILES, windup_dur, is_skeleton_enraged)
	if get_parent():
		get_parent().add_child(telegraph)
	skeleton_active_telegraphs.append(telegraph)

	_play_skeleton_cast_pose(true)
	play_sfx(SFX_FIRE_AIM, 0.5)

	await get_tree().create_timer(windup_dur).timeout
	if not is_instance_valid(self) or is_dead or my_token != skeleton_attack_token:
		return

	if is_instance_valid(telegraph):
		skeleton_active_telegraphs.erase(telegraph)
		telegraph.queue_free()

	# 2. Lepaskan ledakan api & fireball oranye ke 4 arah utama (Atas, Bawah, Kiri, Kanan)
	var cur_origin := get_alaric_ground_origin()
	_play_skeleton_cast_pose(false)
	play_sfx(SFX_FIRE_CAST, 1.5)
	play_sfx(SFX_FIRE_IMPACT, 1.5)
	_apply_boss_camera_shake(12.0)

	var vfx := SkeletonFireEffectNode.new()
	vfx.setup_infernal_burst(cur_origin, SKELETON_TILE_SIZE, SKELETON_BURST_RANGE_TILES, is_skeleton_enraged, _get_or_create_orange_fireball_frames(), _get_or_create_orange_explosion_frames())
	if get_parent():
		get_parent().add_child(vfx)

	# Berikan 260 damage ke karakter yang berada di jalur Atas, Bawah, Kiri, atau Kanan (area diagonal aman)
	_apply_skeleton_infernal_burst_damage(cur_origin, lane_length, lane_width, SKELETON_BURST_DAMAGE)

	# 3. Fase Recovery (1,5 detik) + jeda antar serangan
	skeleton_burst_cd_timer = SKELETON_BURST_COOLDOWN
	skeleton_recovery_timer = SKELETON_BURST_RECOVERY
	skeleton_attack_gap_timer = SKELETON_ATTACK_BREATHING_GAP
	await get_tree().create_timer(0.32).timeout
	if not is_instance_valid(self) or is_dead or my_token != skeleton_attack_token:
		return
	is_shooting = false
	play_idle_animation()


# ---------------------------------------------------------
# D. FIREBALL RAIN (Multi-target AoE: 5 titik area acak, Radius 1 tile, 150 damage/ledakan)
# Damage: 150/ledakan | Wind-up: 1,8s (Enrage: 1,4s) | Recovery: 1,3s | Cooldown: 13s
# ---------------------------------------------------------
func _execute_skeleton_fireball_rain(target_dir: Vector2) -> void:
	if is_dead or is_shooting:
		return
	is_shooting = true
	skeleton_rain_cd_timer = SKELETON_RAIN_COOLDOWN
	var my_token := skeleton_attack_token
	var windup_dur: float = SKELETON_RAIN_WINDUP_ENRAGE if is_skeleton_enraged else SKELETON_RAIN_WINDUP_NORMAL
	var rain_radius: float = SKELETON_TILE_SIZE * SKELETON_RAIN_RADIUS_TILES

	last_direction = get_cardinal_direction(target_dir)
	var impact_points := _pick_skeleton_fireball_rain_points(SKELETON_RAIN_AREA_COUNT, rain_radius)

	# 1. Tampilkan 5 lingkaran merah-oranye beserta animasi bola api jatuh dari langit di akhir wind-up
	var telegraph := SkeletonTelegraphNode.new()
	telegraph.setup_fireball_rain(impact_points, rain_radius, windup_dur, is_skeleton_enraged, _get_or_create_orange_fireball_frames())
	if get_parent():
		get_parent().add_child(telegraph)
	skeleton_active_telegraphs.append(telegraph)

	_play_skeleton_cast_pose(true)
	play_sfx(SFX_FIRE_AIM, 0.0)
	play_sfx(SFX_FIRE_FALL, -1.0)

	await get_tree().create_timer(windup_dur).timeout
	if not is_instance_valid(self) or is_dead or my_token != skeleton_attack_token:
		return

	if is_instance_valid(telegraph):
		skeleton_active_telegraphs.erase(telegraph)
		telegraph.queue_free()

	# 2. Ke-5 bola api menghantam tanah dan menghasilkan ledakan api oranye di setiap area
	_play_skeleton_cast_pose(false)
	play_sfx(SFX_FIRE_IMPACT, 1.5)
	_apply_boss_camera_shake(11.0)

	var exp_frames := _get_or_create_orange_explosion_frames()
	for pt in impact_points:
		var vfx := SkeletonFireEffectNode.new()
		vfx.setup_fireball_rain_impact(pt, rain_radius, is_skeleton_enraged, exp_frames)
		if get_parent():
			get_parent().add_child(vfx)
		# 150 damage per ledakan
		_apply_skeleton_circle_damage(pt, rain_radius, SKELETON_RAIN_DAMAGE)

	# 3. Fase Recovery (1,3 detik) + jeda antar serangan
	skeleton_rain_cd_timer = SKELETON_RAIN_COOLDOWN
	skeleton_recovery_timer = SKELETON_RAIN_RECOVERY
	skeleton_attack_gap_timer = SKELETON_ATTACK_BREATHING_GAP
	await get_tree().create_timer(0.30).timeout
	if not is_instance_valid(self) or is_dead or my_token != skeleton_attack_token:
		return
	is_shooting = false
	play_idle_animation()


func _pick_skeleton_flame_pillar_targets(count: int) -> Array[CharacterBody2D]:
	var alive_players: Array[CharacterBody2D] = []
	if is_inside_tree():
		for p in get_tree().get_nodes_in_group("player"):
			if is_instance_valid(p) and (p is CharacterBody2D) and p.visible and not ("is_dead" in p and p.is_dead):
				alive_players.append(p)
	if alive_players.is_empty():
		return []

	# Urutkan atau acak agar 2 karakter berbeda terpilih (atau 2x pada karakter yang sama jika solo)
	alive_players.shuffle()
	# Pastikan Leader aktif menjadi salah satu target utama agar pemain selalu merasakan tekanan langsung
	for i in range(alive_players.size()):
		if "is_leader" in alive_players[i] and alive_players[i].is_leader and i > 0:
			var lead := alive_players[i]
			alive_players[i] = alive_players[0]
			alive_players[0] = lead
			break

	var result: Array[CharacterBody2D] = []
	for i in range(count):
		result.append(alive_players[i % alive_players.size()])
	return result


func _pick_skeleton_fireball_rain_points(count: int, radius: float) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	var origin := get_alaric_ground_origin()
	var alive_positions: Array[Vector2] = []
	if is_inside_tree():
		for p in get_tree().get_nodes_in_group("player"):
			if is_instance_valid(p) and (p is CharacterBody2D) and p.visible and not ("is_dead" in p and p.is_dead):
				alive_positions.append(get_target_ground_origin(p))

	var min_bounds := origin - Vector2(420.0, 320.0)
	var max_bounds := origin + Vector2(420.0, 320.0)
	if is_inside_tree():
		var game_node = get_tree().current_scene
		if game_node and "arena_bounds" in game_node and (game_node.arena_bounds as Rect2).size != Vector2.ZERO:
			var ab: Rect2 = (game_node.arena_bounds as Rect2).grow(-95.0)
			min_bounds = ab.position
			max_bounds = ab.end

	# Tempatkan beberapa titik di dekat posisi karakter pemain dan sisanya tersebar acak di sekitar arena
	for i in range(count):
		var candidate := origin
		for _attempt in range(18):
			if i < alive_positions.size() and randf() < 0.78:
				var base_p := alive_positions[i]
				var ang := randf() * TAU
				var dist := randf_range(10.0, 75.0)
				candidate = base_p + Vector2.from_angle(ang) * dist
			else:
				var ref_center := alive_positions[randi() % alive_positions.size()] if not alive_positions.is_empty() else origin
				var ang := randf() * TAU
				var dist := randf_range(65.0, SKELETON_TILE_SIZE * 3.6)
				candidate = ref_center + Vector2.from_angle(ang) * dist

			candidate.x = clampf(candidate.x, min_bounds.x, max_bounds.x)
			candidate.y = clampf(candidate.y, min_bounds.y, max_bounds.y)

			var too_close := false
			for existing in pts:
				if existing.distance_to(candidate) < radius * 1.15:
					too_close = true
					break
			if not too_close:
				break
		pts.append(candidate)
	return pts


func _apply_skeleton_circle_damage(center_pos: Vector2, radius: float, dmg: int) -> void:
	if not is_inside_tree():
		return
	var reach := radius + 16.0
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if not is_instance_valid(p) or not (p is CharacterBody2D) or not p.visible or ("is_dead" in p and p.is_dead):
			continue
		var p_origin := get_target_ground_origin(p)
		if p_origin.distance_to(center_pos) <= reach:
			if p.has_method("take_damage"):
				p.take_damage(dmg, center_pos)


func _apply_skeleton_infernal_burst_damage(origin: Vector2, lane_length: float, lane_width: float, dmg: int) -> void:
	if not is_inside_tree():
		return
	var max_long := lane_length + 16.0
	var half_lat := (lane_width * 0.5) + 14.0
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if not is_instance_valid(p) or not (p is CharacterBody2D) or not p.visible or ("is_dead" in p and p.is_dead):
			continue
		var p_origin := get_target_ground_origin(p)
		var diff := p_origin - origin
		# 4 arah utama: Atas (Y-), Bawah (Y+), Kiri (X-), Kanan (X+) -> bentuk salib (+)
		var in_horizontal_lane: bool = (absf(diff.x) <= max_long and absf(diff.y) <= half_lat)
		var in_vertical_lane: bool = (absf(diff.y) <= max_long and absf(diff.x) <= half_lat)
		if in_horizontal_lane or in_vertical_lane:
			if p.has_method("take_damage"):
				p.take_damage(dmg, origin)


# =========================================================
# VISUAL NODE 4: INDIKATOR AREA SERANGAN SKELETON (TELEGRAPH MERAH-ORANYE)
# =========================================================
class SkeletonTelegraphNode extends Node2D:
	enum Mode { RING_OF_FIRE, FLAME_PILLAR, INFERNAL_BURST, FIREBALL_RAIN }

	var mode: int = Mode.RING_OF_FIRE
	var start_radius: float = 85.0
	var end_radius: float = 255.0
	var tile_size: float = 85.0
	var range_tiles: float = 4.0
	var follow_target: Node2D = null
	var rain_points: Array[Vector2] = []
	var total_duration: float = 1.0
	var elapsed: float = 0.0
	var enraged: bool = false
	var _falling_fireballs: Array[AnimatedSprite2D] = []

	func setup_ring_of_fire(p_origin: Vector2, p_start_r: float, p_end_r: float, p_dur: float, p_enraged: bool) -> void:
		mode = Mode.RING_OF_FIRE
		global_position = p_origin
		start_radius = p_start_r
		end_radius = p_end_r
		total_duration = maxf(0.05, p_dur)
		enraged = p_enraged
		z_index = 2

	func setup_flame_pillar(p_origin: Vector2, p_target: Node2D, p_radius: float, p_dur: float, p_enraged: bool) -> void:
		mode = Mode.FLAME_PILLAR
		global_position = p_origin
		follow_target = p_target
		end_radius = p_radius
		total_duration = maxf(0.05, p_dur)
		enraged = p_enraged
		z_index = 2

	func setup_infernal_burst(p_origin: Vector2, p_tile_size: float, p_range_tiles: float, p_dur: float, p_enraged: bool) -> void:
		mode = Mode.INFERNAL_BURST
		global_position = p_origin
		tile_size = p_tile_size
		range_tiles = p_range_tiles
		total_duration = maxf(0.05, p_dur)
		enraged = p_enraged
		z_index = 2

	func setup_fireball_rain(p_points: Array[Vector2], p_radius: float, p_dur: float, p_enraged: bool, fb_frames: SpriteFrames) -> void:
		mode = Mode.FIREBALL_RAIN
		global_position = Vector2.ZERO
		rain_points = p_points.duplicate()
		end_radius = p_radius
		total_duration = maxf(0.05, p_dur)
		enraged = p_enraged
		z_index = 2

		# Siapkan sprite bola api oranye yang meluncur turun dari atas langit menjelang akhir wind-up
		for pt in rain_points:
			var spr := AnimatedSprite2D.new()
			spr.sprite_frames = fb_frames
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			spr.scale = Vector2(3.4, 3.4)
			spr.z_index = 8
			spr.visible = false
			spr.global_position = pt + Vector2(0.0, -420.0)
			add_child(spr)
			spr.play(&"default")
			_falling_fireballs.append(spr)

	func _process(delta: float) -> void:
		elapsed += delta
		var prog := clampf(elapsed / total_duration, 0.0, 1.0)

		# Fireball Rain: Bola api oranye meluncur turun dari langit pada 35% akhir waktu wind-up
		if mode == Mode.FIREBALL_RAIN:
			var fall_start := 0.62
			if prog >= fall_start:
				var fall_t := clampf((prog - fall_start) / (1.0 - fall_start), 0.0, 1.0)
				for i in range(mini(rain_points.size(), _falling_fireballs.size())):
					var fb := _falling_fireballs[i]
					if is_instance_valid(fb):
						fb.visible = true
						var target_pt := rain_points[i]
						var sky_pt := target_pt + Vector2(0.0, -420.0)
						fb.global_position = sky_pt.lerp(target_pt, fall_t)
						fb.modulate = Color(1.25, 1.05, 0.85, 1.0) if enraged else Color.WHITE

		queue_redraw()
		if elapsed >= total_duration + 0.15:
			queue_free()

	func _draw() -> void:
		var prog := clampf(elapsed / total_duration, 0.0, 1.0)
		var pulse := 0.5 + 0.5 * sin(elapsed * 22.0)

		var base_fill := Color(0.88, 0.18, 0.08, 0.24) if not enraged else Color(1.0, 0.26, 0.05, 0.32)
		var charge_fill := Color(1.0, 0.42, 0.10, 0.45 + 0.18 * prog) if not enraged else Color(1.0, 0.58, 0.12, 0.54 + 0.20 * prog)
		var border_col := Color(1.0, 0.34, 0.12, 0.90).lerp(Color(1.0, 0.92, 0.38, 1.0), prog * 0.72 + pulse * 0.2)

		if mode == Mode.RING_OF_FIRE:
			# Lingkaran luar (3 tile) + gelombang menyebar dari 1 tile ke 3 tile
			draw_circle(Vector2.ZERO, end_radius, base_fill)
			var cur_r := lerpf(start_radius, end_radius, prog)
			draw_circle(Vector2.ZERO, cur_r, charge_fill)
			draw_arc(Vector2.ZERO, start_radius, 0.0, TAU, 48, Color(1.0, 0.65, 0.22, 0.55), 1.8)
			draw_arc(Vector2.ZERO, cur_r, 0.0, TAU, 56, Color(1.0, 0.88, 0.35, 0.88), 2.6)
			draw_arc(Vector2.ZERO, end_radius, 0.0, TAU, 64, border_col, 3.0)

		elif mode == Mode.FLAME_PILLAR:
			# Lingkaran merah-oranye 1 tile yang mengunci target
			draw_circle(Vector2.ZERO, end_radius, base_fill)
			draw_circle(Vector2.ZERO, end_radius * prog, charge_fill)
			draw_arc(Vector2.ZERO, end_radius, 0.0, TAU, 44, border_col, 2.8)
			# Bidikan crosshair api di dalam lingkaran
			var cr := end_radius * 0.68
			var cross_col := Color(1.0, 0.86, 0.40, 0.55 + 0.35 * prog)
			draw_line(Vector2(-cr, 0.0), Vector2(cr, 0.0), cross_col, 2.0)
			draw_line(Vector2(0.0, -cr), Vector2(0.0, cr), cross_col, 2.0)

		elif mode == Mode.INFERNAL_BURST:
			# 4 jalur garis merah-oranye ke Atas, Bawah, Kiri, Kanan sejauh 4 tile
			var dirs: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
			var max_len := tile_size * range_tiles
			var half_w := tile_size * 0.5
			for d in dirs:
				draw_set_transform(Vector2.ZERO, d.angle(), Vector2.ONE)
				var full_rect := Rect2(Vector2(0.0, -half_w), Vector2(max_len, tile_size))
				draw_rect(full_rect, base_fill, true)
				# Pembagian grid 4 petak sepanjang jalur
				for t_idx in range(1, int(range_tiles) + 1):
					var cell_rect := Rect2(Vector2(float(t_idx - 1) * tile_size, -half_w), Vector2(tile_size, tile_size)).grow(-1.5)
					draw_rect(cell_rect, Color(1.0, 0.55, 0.22, 0.36), false, 1.0)
				# Pengisian charge progresif sepanjang 4 tile
				var fill_rect := Rect2(Vector2(0.0, -half_w), Vector2(max_len * prog, tile_size))
				draw_rect(fill_rect, charge_fill, true)
				draw_rect(full_rect, border_col, false, 2.4)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		elif mode == Mode.FIREBALL_RAIN:
			# 5 lingkaran merah-oranye beradius 1 tile
			for pt in rain_points:
				draw_circle(pt, end_radius, base_fill)
				draw_circle(pt, end_radius * prog, charge_fill)
				draw_arc(pt, end_radius, 0.0, TAU, 40, border_col, 2.6)
				draw_arc(pt, end_radius * 0.45, 0.0, TAU, 28, Color(1.0, 0.85, 0.35, 0.45 + 0.35 * prog), 1.6)


# =========================================================
# VISUAL NODE 5: EFEK API & FIREBALL ORANYE SKELETON (FIRE VFX)
# =========================================================
class SkeletonFireEffectNode extends Node2D:
	enum FireMode { RING_OF_FIRE, FLAME_PILLAR, INFERNAL_BURST, FIREBALL_RAIN_IMPACT }

	var mode: int = FireMode.RING_OF_FIRE
	var start_radius: float = 85.0
	var end_radius: float = 255.0
	var tile_size: float = 85.0
	var range_tiles: float = 4.0
	var enraged: bool = false
	var elapsed: float = 0.0
	var duration: float = 0.52
	var _fire_sprites: Array[Node2D] = []
	var _ring_angles: Array[float] = []

	func setup_ring_of_fire(p_origin: Vector2, p_start_r: float, p_end_r: float, p_enraged: bool, fb_frames: SpriteFrames) -> void:
		mode = FireMode.RING_OF_FIRE
		global_position = p_origin
		start_radius = p_start_r
		end_radius = p_end_r
		enraged = p_enraged
		duration = 0.55
		z_index = 6

		# 12 Bola api oranye membara yang menyebar melingkar dari radius 1 tile ke 3 tile
		var count := 12
		for i in range(count):
			var ang := (TAU / float(count)) * float(i)
			_ring_angles.append(ang)
			var spr := AnimatedSprite2D.new()
			spr.sprite_frames = fb_frames
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			spr.scale = Vector2(2.8, 2.8)
			spr.rotation = ang + PI * 0.5
			spr.position = Vector2.from_angle(ang) * start_radius
			if enraged:
				spr.modulate = Color(1.35, 1.12, 0.82, 1.0)
			add_child(spr)
			spr.play(&"default")
			_fire_sprites.append(spr)

	func setup_flame_pillar(p_origin: Vector2, p_radius: float, p_enraged: bool, fb_frames: SpriteFrames, exp_frames: SpriteFrames) -> void:
		mode = FireMode.FLAME_PILLAR
		global_position = p_origin
		end_radius = p_radius
		enraged = p_enraged
		duration = 0.52
		z_index = 6

		# Semburan bola api vertikal + ledakan api oranye dari tanah
		var pillar_spr := AnimatedSprite2D.new()
		pillar_spr.sprite_frames = fb_frames
		pillar_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pillar_spr.scale = Vector2(3.8, 4.6)
		pillar_spr.position = Vector2(0.0, -34.0)
		if enraged:
			pillar_spr.modulate = Color(1.35, 1.12, 0.82, 1.0)
		add_child(pillar_spr)
		pillar_spr.play(&"default")
		_fire_sprites.append(pillar_spr)

		var exp_spr := AnimatedSprite2D.new()
		exp_spr.sprite_frames = exp_frames
		exp_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		exp_spr.scale = Vector2(3.6, 3.6)
		exp_spr.position = Vector2(0.0, -8.0)
		if enraged:
			exp_spr.modulate = Color(1.35, 1.12, 0.82, 1.0)
		add_child(exp_spr)
		exp_spr.play(&"default")
		_fire_sprites.append(exp_spr)

	func setup_infernal_burst(p_origin: Vector2, p_tile_size: float, p_range_tiles: float, p_enraged: bool, fb_frames: SpriteFrames, exp_frames: SpriteFrames) -> void:
		mode = FireMode.INFERNAL_BURST
		global_position = p_origin
		tile_size = p_tile_size
		range_tiles = p_range_tiles
		enraged = p_enraged
		duration = 0.56
		z_index = 6

		# Ledakan bola-bola api oranye beruntun di sepanjang 4 arah utama (Atas, Bawah, Kiri, Kanan) sejauh 4 tile
		var dirs: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		for d in dirs:
			for step in range(1, int(range_tiles) + 1):
				var cell_center := d * (float(step) * tile_size - tile_size * 0.35)
				var exp_spr := AnimatedSprite2D.new()
				exp_spr.sprite_frames = exp_frames if (step % 2 == 0) else fb_frames
				exp_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				exp_spr.scale = Vector2(2.8, 2.8)
				exp_spr.position = cell_center
				if step % 2 == 1:
					exp_spr.rotation = d.angle() + PI * 0.5
				if enraged:
					exp_spr.modulate = Color(1.35, 1.12, 0.82, 1.0)
				add_child(exp_spr)
				exp_spr.play(&"default")
				_fire_sprites.append(exp_spr)

	func setup_fireball_rain_impact(p_origin: Vector2, p_radius: float, p_enraged: bool, exp_frames: SpriteFrames) -> void:
		mode = FireMode.FIREBALL_RAIN_IMPACT
		global_position = p_origin
		end_radius = p_radius
		enraged = p_enraged
		duration = 0.48
		z_index = 6

		var exp_spr := AnimatedSprite2D.new()
		exp_spr.sprite_frames = exp_frames
		exp_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		exp_spr.scale = Vector2(3.6, 3.6)
		exp_spr.position = Vector2(0.0, -6.0)
		if enraged:
			exp_spr.modulate = Color(1.35, 1.12, 0.82, 1.0)
		add_child(exp_spr)
		exp_spr.play(&"default")
		_fire_sprites.append(exp_spr)

	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= duration:
			queue_free()
			return

		var t := clampf(elapsed / duration, 0.0, 1.0)
		var alpha := clampf(1.0 - pow(t, 1.8), 0.0, 1.0)

		if mode == FireMode.RING_OF_FIRE:
			var cur_r := lerpf(start_radius, end_radius, clampf(t * 1.35, 0.0, 1.0))
			for i in range(mini(_fire_sprites.size(), _ring_angles.size())):
				var spr := _fire_sprites[i]
				if is_instance_valid(spr):
					var ang := _ring_angles[i] + t * 0.45
					spr.position = Vector2.from_angle(ang) * cur_r
					spr.modulate.a = alpha
		elif mode == FireMode.FLAME_PILLAR:
			if _fire_sprites.size() > 0 and is_instance_valid(_fire_sprites[0]):
				_fire_sprites[0].position.y = lerpf(-18.0, -62.0, clampf(t * 1.5, 0.0, 1.0))
				_fire_sprites[0].modulate.a = alpha
			if _fire_sprites.size() > 1 and is_instance_valid(_fire_sprites[1]):
				_fire_sprites[1].modulate.a = alpha
		else:
			for spr in _fire_sprites:
				if is_instance_valid(spr):
					spr.modulate.a = alpha

		queue_redraw()

	func _draw() -> void:
		var t := clampf(elapsed / duration, 0.0, 1.0)
		var alpha := clampf(1.0 - pow(t, 1.5), 0.0, 1.0)

		var core_col := Color(1.0, 0.96, 0.72, alpha)
		var flame_col := Color(1.0, 0.52, 0.10, alpha * 0.88) if not enraged else Color(1.0, 0.68, 0.16, alpha * 0.95)
		var ember_col := Color(0.95, 0.22, 0.06, alpha * 0.65)

		if mode == FireMode.RING_OF_FIRE:
			var cur_r := lerpf(start_radius, end_radius, clampf(t * 1.35, 0.0, 1.0))
			draw_arc(Vector2.ZERO, cur_r, 0.0, TAU, 56, ember_col, 24.0 * (1.0 - t * 0.35))
			draw_arc(Vector2.ZERO, cur_r, 0.0, TAU, 56, flame_col, 13.0 * (1.0 - t * 0.3))
			draw_arc(Vector2.ZERO, cur_r, 0.0, TAU, 56, core_col, 4.0)

		elif mode == FireMode.FLAME_PILLAR:
			var r := end_radius * (0.75 + 0.25 * clampf(t * 1.6, 0.0, 1.0))
			draw_circle(Vector2.ZERO, r, Color(flame_col.r, flame_col.g, flame_col.b, alpha * 0.36))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, flame_col, 7.0 * (1.0 - t * 0.4))
			draw_arc(Vector2.ZERO, r * 0.65, 0.0, TAU, 32, core_col, 3.2)
			# Lidah semburan pilar api menjulang ke atas
			var pillar_h := lerpf(35.0, 135.0, clampf(t * 1.8, 0.0, 1.0)) * (1.0 - t * 0.25)
			var half_base := end_radius * 0.55 * (1.0 - t * 0.35)
			var flame_poly := PackedVector2Array([
				Vector2(-half_base, 0.0),
				Vector2(-half_base * 0.55, -pillar_h * 0.65),
				Vector2(0.0, -pillar_h),
				Vector2(half_base * 0.55, -pillar_h * 0.65),
				Vector2(half_base, 0.0)
			])
			draw_colored_polygon(flame_poly, Color(flame_col.r, flame_col.g, flame_col.b, alpha * 0.68))

		elif mode == FireMode.INFERNAL_BURST:
			var dirs: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
			var max_len := tile_size * range_tiles
			var cur_len := lerpf(tile_size * 0.8, max_len, clampf(t * 2.0, 0.0, 1.0))
			var half_w := (tile_size * 0.42) * (1.0 - t * 0.35)
			for d in dirs:
				draw_set_transform(Vector2.ZERO, d.angle(), Vector2.ONE)
				var beam_rect := Rect2(Vector2(0.0, -half_w), Vector2(cur_len, half_w * 2.0))
				draw_rect(beam_rect, Color(ember_col.r, ember_col.g, ember_col.b, alpha * 0.45), true)
				var inner_rect := Rect2(Vector2(0.0, -half_w * 0.55), Vector2(cur_len, half_w * 1.1))
				draw_rect(inner_rect, flame_col, true)
				draw_line(Vector2(0.0, 0.0), Vector2(cur_len, 0.0), core_col, 4.5)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		elif mode == FireMode.FIREBALL_RAIN_IMPACT:
			var r := end_radius * (0.55 + 0.45 * clampf(t * 1.8, 0.0, 1.0))
			draw_circle(Vector2.ZERO, r, Color(flame_col.r, flame_col.g, flame_col.b, alpha * 0.38))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 36, flame_col, 8.0 * (1.0 - t * 0.4))
			draw_arc(Vector2.ZERO, r * 0.6, 0.0, TAU, 28, core_col, 3.0)


# =========================================================
# VISUAL NODE 6: AURA API ENRAGE SKELETON (AKTIF PADA HP <= 30%)
# =========================================================
class SkeletonFireAuraNode extends Node2D:
	var time_passed: float = 0.0

	func _process(delta: float) -> void:
		time_passed += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(time_passed * 9.0)
		var r := 45.0 + pulse * 7.0
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.38, 0.08, 0.22 + pulse * 0.12))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 36, Color(1.0, 0.72, 0.18, 0.75 + pulse * 0.22), 2.6)
