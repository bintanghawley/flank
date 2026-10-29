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
const TRACE_SCENE = preload("res://scene/projectile/arrow_trace.tscn")

@export var shoot_range: float = 320.0       # Jarak tembak musuh (pixel)
@export var shoot_cooldown: float = 1.6     # Cooldown tembakan musuh (detik)
@export var projectile_damage: int = 1      # Damage panah musuh
@export var projectile_speed: float = 380.0 # Kecepatan panah musuh

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


func alert_to_combat(target: CharacterBody2D = null) -> void:
	if is_dead:
		return
	if current_state != State.CHASE:
		current_state = State.CHASE
	var chosen: CharacterBody2D = target if target else get_best_target()
	if chosen:
		player = chosen

func get_best_target() -> CharacterBody2D:
	# 1. Prioritaskan karakter yang baru saja memberi damage (threat/aggro priority)
	if threat_timer > 0.0 and threat_target != null and is_instance_valid(threat_target):
		if not ("is_dead" in threat_target and threat_target.is_dead) and threat_target.is_in_group("player"):
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
	for p in party:
		if p is CharacterBody2D and is_instance_valid(p) and not ("is_dead" in p and p.is_dead):
			var d := global_position.distance_to(p.global_position)
			if d < min_d:
				min_d = d
				closest = p
	return closest


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

	# Reduksi knockback saat terkena dampak ledakan/serangan kuat
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		velocity = knockback_velocity
		move_and_slide()
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
			current_state = State.IDLE_PATROL
			return
		player = target

		var dist = global_position.distance_to(player.global_position)
		# Jika pemain kabur terlalu jauh di luar layar (leash limit), musuh kembali patroli
		if dist > 850.0:
			player = null
			is_flanking = false
			flank_wp1 = Vector2.ZERO
			flank_wp2 = Vector2.ZERO
			flank_stage = 1
			flank_timeout = 0.0
			facing_debounce_timer = 0.0
			current_state = State.IDLE_PATROL
			return

		var dir: Vector2 = global_position.direction_to(player.global_position)

		# Hitung mundur cooldown tembak
		shoot_timer -= delta

		var has_los := has_clear_projectile_los_to(player, 12.0)
		var dist_to_player: float = global_position.distance_to(player.global_position)

		if has_los:
			is_flanking = false
			if dist_to_player <= shoot_range:
				velocity = Vector2.ZERO
				move_and_slide()
				var look_dir := global_position.direction_to(player.global_position)
				update_direction_animation(look_dir)

				# Eksekusi tembakan musuh sesuai timer shoot_cooldown
				if shoot_timer <= 0.0 and not is_shooting:
					shoot_at_player()
				if not is_shooting:
					last_direction = get_8_direction(look_dir)
					play_idle_animation()
			else:
				# Belum masuk shoot_range: dekati player secara langsung
				if is_shooting:
					velocity = Vector2.ZERO
					move_and_slide()
				else:
					var move_dir: Vector2 = dir
					velocity = move_dir * chase_speed
					move_and_slide()
					apply_smoothed_facing(move_dir, delta)
		else:
			# Terhalang pagar: navigasi 2-waypoint
			if is_shooting:
				velocity = Vector2.ZERO
				move_and_slide()
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
				move_and_slide()
				apply_smoothed_facing(move_dir, delta)
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

func get_arrow_spawn_position(dir: Vector2) -> Vector2:
	# Titik visual tengah tubuh archer (skala 5x, texture center 16.0, 16.0)
	var center_pos := global_position + Vector2(2.5, 6.0)

	# Posisi kemunculan panah tepat di depan busur keluar dari tubuh musuh
	var forward_dist := 28.0 if last_direction == Vector2.UP else 20.0
	return center_pos + dir * forward_dist


func calculate_flank_waypoints(target_node: Node2D) -> bool:
	if not target_node or not is_instance_valid(target_node):
		return false
	var space_state := get_world_2d().direct_space_state
	var my_pos: Vector2 = global_position
	var target_pos: Vector2 = target_node.global_position
	
	# Raycast langsung ke target untuk mendeteksi titik benturan rintangan
	var ray := PhysicsRayQueryParameters2D.create(my_pos, target_pos)
	ray.collision_mask = 1 # Layer 1: dinding / pagar / rintangan fisik
	ray.exclude = [self, target_node]
	var hit := space_state.intersect_ray(ray)
	if hit.is_empty():
		return false
		
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
	var from_pos: Vector2 = global_position
	var to_pos: Vector2 = target_node.global_position
	
	# 1. Ray tengah
	var query_center := PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query_center.collision_mask = 1 # Rintangan / pagar / dinding / tunggul
	query_center.exclude = [self, target_node]
	if not space_state.intersect_ray(query_center).is_empty():
		return false
		
	# 2. Vektor tegak lurus (perpendicular) untuk menguji lebar fisik proyektil
	var fire_dir := (to_pos - from_pos).normalized()
	if fire_dir == Vector2.ZERO:
		return false
	var perp := Vector2(-fire_dir.y, fire_dir.x) * clearance_radius
	
	# 3. Ray sayap kiri (menguji apakah sisi kiri proyektil menyenggol rintangan)
	var query_left := PhysicsRayQueryParameters2D.create(from_pos + perp, to_pos + perp)
	query_left.collision_mask = 1
	query_left.exclude = [self, target_node]
	if not space_state.intersect_ray(query_left).is_empty():
		return false
		
	# 4. Ray sayap kanan (menguji apakah sisi kanan proyektil menyenggol rintangan)
	var query_right := PhysicsRayQueryParameters2D.create(from_pos - perp, to_pos - perp)
	query_right.collision_mask = 1
	query_right.exclude = [self, target_node]
	if not space_state.intersect_ray(query_right).is_empty():
		return false
		
	return true

func has_line_of_sight_to(target_node: Node2D) -> bool:
	return has_clear_projectile_los_to(target_node, 14.0)


func shoot_at_player():
	if player == null or not is_instance_valid(player) or is_dead or is_shooting:
		return

	is_shooting = true
	var center_pos = global_position + Vector2(2.5, 6.0)
	var dir = center_pos.direction_to(player.global_position)

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
	arrow.speed = projectile_speed
	arrow.damage = projectile_damage
	arrow.modulate = Color(1.8, 0.4, 0.4) # Warna kemerahan agar jelas panah musuh
	if last_direction == Vector2.UP or animated_sprite.animation == "atk_n":
		arrow.get_node("Sprite2D").z_index = 3
	else:
		arrow.get_node("Sprite2D").z_index = 5
	get_parent().add_child(arrow)

	# Munculkan trace indicator panah musuh tepat di titik lepas (dihilangkan jika menghadap North)
	if last_direction != Vector2.UP and animated_sprite.animation != "atk_n":
		var trace = TRACE_SCENE.instantiate()
		trace.global_position = spawn_pos
		trace.rotation = dir.angle()
		trace.scale = Vector2(4, 4)
		trace.z_index = 10
		trace.modulate = Color(1.8, 0.4, 0.4)
		get_parent().add_child(trace)

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

func play_idle_animation():
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

func play_attack_animation():
	if not animated_sprite:
		return
	animated_sprite.flip_h = false

	if last_direction == Vector2.UP:
		animated_sprite.play("atk_n")
	elif last_direction == Vector2.DOWN:
		animated_sprite.play("atk_s")
	elif last_direction == Vector2.LEFT:
		animated_sprite.play("atk_w")
		animated_sprite.flip_h = false
	elif last_direction == Vector2.RIGHT:
		animated_sprite.play("atk_e")
		animated_sprite.flip_h = false
	elif last_direction == Vector2(-1, -1):
		animated_sprite.play("atk_w")
		animated_sprite.flip_h = false
	elif last_direction == Vector2(1, -1):
		animated_sprite.play("atk_w")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(-1, 1):
		animated_sprite.play("atk_e")
		animated_sprite.flip_h = true
	elif last_direction == Vector2(1, 1):
		animated_sprite.play("atk_e")
		animated_sprite.flip_h = false


func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force


# =========================================================
# MENERIMA DAMAGE DARI PANAH ARCHER
# =========================================================

func take_damage(amount: int, attacker: CharacterBody2D = null):
	if is_dead:
		return

	current_health -= amount

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
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(animated_sprite) and not is_dead:
			animated_sprite.modulate = Color(1.3, 0.4, 0.4) # Kembali ke warna merah musuh

	# Multi-Target Aggro: Prioritaskan penyerang yang baru memberi damage
	if attacker != null and is_instance_valid(attacker) and attacker.is_in_group("player") and not ("is_dead" in attacker and attacker.is_dead):
		threat_target = attacker
		threat_timer = 3.0
		player = attacker
		current_state = State.CHASE
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

func die():
	is_dead = true
	is_shooting = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	is_flanking = false
	flank_wp1 = Vector2.ZERO
	flank_wp2 = Vector2.ZERO
	flank_stage = 1
	flank_timeout = 0.0
	facing_debounce_timer = 0.0

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
	is_flanking = false
	flank_wp1 = Vector2.ZERO
	flank_wp2 = Vector2.ZERO
	flank_stage = 1
	flank_timeout = 0.0
	facing_debounce_timer = 0.0
	current_state = State.IDLE_PATROL
	wander_target = spawn_position
	wander_timer = 0.0
	damage_timer = 0.0
	threat_target = null
	threat_timer = 0.0
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
		var target := get_closest_target()
		player = target if target else body
		current_state = State.CHASE


func _on_detection_area_body_exited(body):
	if is_dead:
		return
	if body == player:
		var next_target := get_closest_target()
		if next_target and global_position.distance_to(next_target.global_position) <= 550.0:
			player = next_target
		else:
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
