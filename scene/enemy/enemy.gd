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

		# Hitung mundur cooldown tembak & cooldown skill Alaric Boss
		shoot_timer -= delta
		if is_alaric_boss:
			if alaric_basic_cd_timer > 0.0:
				alaric_basic_cd_timer = maxf(0.0, alaric_basic_cd_timer - delta)
			if alaric_triple_cd_timer > 0.0:
				alaric_triple_cd_timer = maxf(0.0, alaric_triple_cd_timer - delta)
			if alaric_rupture_cd_timer > 0.0:
				alaric_rupture_cd_timer = maxf(0.0, alaric_rupture_cd_timer - delta)
			_check_and_update_alaric_enrage()

		var has_los := has_clear_projectile_los_to(player, 12.0)
		var dist_to_player: float = dist

		# 1. Jarak serang & manuver AI Musuh (Alaric Boss vs Melee Knight vs Ranged Archer)
		if is_alaric_boss:
			_process_alaric_boss_ai(delta, dir, dist_to_player, has_los)
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
	if not is_alaric_boss and contact_damage > 0:
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
	if not is_training_dummy and not is_alaric_boss:
		amount = max(amount, current_health)
	current_health = max(0, current_health - amount)
	play_sfx(SFX_HURT, -2.0)

	if is_alaric_boss:
		_check_and_update_alaric_enrage()

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
		var default_col: Color = Color.WHITE if ("Alaric" in name or is_alaric_boss or is_in_group("npc")) else Color(1.3, 0.4, 0.4)
		if is_alaric_boss and is_alaric_enraged:
			default_col = Color(1.22, 0.82, 0.78)
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
	if is_dead or is_training_dummy or is_alaric_boss or contact_damage <= 0 or body == null:
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


func _process_alaric_boss_ai(delta: float, dir: Vector2, dist_to_player: float, has_los: bool) -> void:
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

