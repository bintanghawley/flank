extends CharacterBody2D

# =========================================================
# PLAYER BANDIT (ANGGOTA PARTY KE-2: ROGUE / DUAL-BLADE MELEE)
# =========================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var triple_slash_sprite: AnimatedSprite2D = get_node_or_null("TripleSlashSprite")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shield_sprite: Sprite2D = $ShieldSprite

# =========================
# PARTY / LEADER / FOLLOWER
# =========================
var is_leader: bool = false
var leader_node: CharacterBody2D = null
var queue_slot_index: int = 1
var in_party_combat: bool = false
var ai_attack_timer: float = 0.0
enum PartyCommand { ATTACK, FOLLOW }
var party_command: PartyCommand = PartyCommand.ATTACK
const COMBAT_ATTACK_RANGE: float = 90.0 # Jarak serang melee Bandit

# =========================
# MOVEMENT SETTINGS
# =========================
const NORMAL_SPEED := 128.0
const SPRINT_SPEED := 220.0

var target_position: Vector2
var is_moving := false

var last_direction := Vector2.DOWN
var last_movement_direction := Vector2.DOWN

# =========================
# COMBAT & MELEE SETTINGS
# =========================
const DUST_SCENE = preload("res://scene/effect/run_dust.tscn")
const SFX_FOOTSTEP = preload("res://assets/audio/sfx/characters/universal/footstep_run.wav")
const SFX_HURT = preload("res://assets/audio/sfx/characters/universal/hero_hurt.wav")
const SFX_DEATH = preload("res://assets/audio/sfx/characters/universal/hero_death.wav")
const SFX_RESPAWN = preload("res://assets/audio/sfx/characters/universal/hero_respawn.wav")
const SFX_BANDIT_SLASH_1 = preload("res://assets/audio/sfx/characters/bandit/bandit_slash_1.wav")
const SFX_BANDIT_SLASH_2 = preload("res://assets/audio/sfx/characters/bandit/bandit_slash_2.wav")
const SFX_BANDIT_SLASH_HIT = preload("res://assets/audio/sfx/characters/bandit/bandit_slash_hit.wav")
const SFX_BANDIT_AMBUSH_LUNGE = preload("res://assets/audio/sfx/characters/bandit/bandit_ambush_lunge.wav")
const SFX_BANDIT_AMBUSH_HIT = preload("res://assets/audio/sfx/characters/bandit/bandit_ambush_hit.wav")
const SFX_BANDIT_SKILL_DASH = preload("res://assets/audio/sfx/characters/bandit/bandit_skill_dash.wav")
const SFX_BANDIT_KNOCKUP = preload("res://assets/audio/sfx/characters/bandit/bandit_knockup.wav")
const SFX_BANDIT_TRIPLE_SLASH_HIT = preload("res://assets/audio/sfx/characters/bandit/bandit_triple_slash_hit.wav")
const SFX_BANDIT_TRIPLE_SLASH_FINISH = preload("res://assets/audio/sfx/characters/bandit/bandit_triple_slash_finish.wav")
const SFX_SHIELD_BLOCK = preload("res://assets/audio/sfx/characters/knight/knight_shield_block.wav")
var _footstep_toggle: bool = false
const VISUAL_CENTER_OFFSET: Vector2 = Vector2(0.0, 7.5)

@export var attack_range: float = 115.0     # Jarak jangkauan tebasan dasar
@export var attack_damage: int = 2          # Damage tebasan dasar per ayunan
@export var attack_cooldown: float = 0.85   # Jeda tebasan serangan dasar (lincah & cepat)
var attack_stuck_timer: float = 0.0
var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.DOWN
var attack_token: int = 0
var require_mouse_release: bool = false

var attack_step: int = 0                  # 0: siap mengayun, 1: ayunan 1 selesai, 2: ayunan 2 selesai
var attack_elapsed_timer: float = 0.0
const SWING_1_IMPACT_TIME: float = 0.15   # Timing ayunan pertama (Frame 2)
const SWING_2_IMPACT_TIME: float = 0.40   # Timing ayunan kedua (Frame 6)
const ATTACK_TOTAL_DURATION: float = 0.58 # Total durasi siklus tebasan dasar (8 frame pada 14 FPS)

# =========================
# KEMAMPUAN PASIF: OUT-OF-COMBAT AMBUSH LUNGE
# =========================
const PASSIVE_OUT_OF_COMBAT_TIME: float = 5.0 # 5 detik berturut-turut tanpa menerima/memberikan damage
var passive_timer: float = 0.0
var is_passive_ready: bool = false
const AMBUSH_ENGAGE_RANGE: float = 260.0      # Jangkauan engage pembuka pasif ambush (jauh melebihi melee biasa)
const AMBUSH_BONUS_DAMAGE: int = 3            # Bonus damage serangan pembuka ambush (+3 damage = 5 damage total)
var is_ambush_lunging: bool = false
var ambush_target_enemy: Node2D = null
var ambush_lunge_dir: Vector2 = Vector2.DOWN
var ambush_lunge_timer: float = 0.0
var is_ambush_attack: bool = false
var is_damage_flash_active: bool = false

# =========================
# SPECIAL SKILL: DASH, KNOCKUP & TRIPLE SLASH (TOMBOL E)
# =========================
enum SkillPhase { INACTIVE, DASHING, KNOCKUP_SLASH }
var skill_phase: SkillPhase = SkillPhase.INACTIVE

@export var skill_cooldown_max: float = 5.0   # Cooldown skill Triple Slash (5 detik)
var skill_cooldown_timer: float = 0.0
var is_skill_active: bool = false
var skill_timer: float = 0.0
var skill_slash_step: int = 0
var skill_dash_dir: Vector2 = Vector2.DOWN
var skill_dash_time: float = 0.0
const SKILL_DASH_SPEED: float = 750.0
const MAX_DASH_DURATION: float = 0.32
var skill_target_enemy: Node2D = null
var skill_hit_enemies_step: Array[Node2D] = []
var skill_stuck_timer: float = 0.0

# =========================
# SPRINT DUST SETTINGS
# =========================
var dust_timer: float = 0.0
const DUST_INTERVAL: float = 0.13

# =========================
# HEALTH & KNOCKBACK
# =========================
@export var max_health: int = 10             # Bandit berdarah lincah (10 HP)
@export var respawn_time: float = 3.0
var current_health: int = 10
var is_dead: bool = false
var spawn_position: Vector2

@export var knockback_strength: float = 380.0 # Dorongan wajar saat terkena damage
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 1400.0

@export var invulnerability_duration: float = 0.25 # Proteksi kebal singkat setelah hit
var invulnerability_timer: float = 0.0

# =========================
# SHIELD GUARD (DARI KNIGHT)
# =========================
var is_shield_active: bool = false
var shield_timer: float = 0.0
var shield_tween: Tween = null

# =========================
# CAMERA SHAKE SETTINGS
# =========================
@export var camera_shake_strength: float = 7.0
var shake_intensity: float = 0.0
var shake_decay: float = 35.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	current_health = max_health
	spawn_position = global_position
	target_position = global_position
	play_idle_animation()
	_setup_enemy_collision_exceptions.call_deferred()


func _setup_enemy_collision_exceptions() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and e is CollisionObject2D:
			add_collision_exception_with(e)
			e.add_collision_exception_with(self)


func set_party_command(cmd: int) -> void:
	party_command = cmd as PartyCommand
	if party_command == PartyCommand.FOLLOW:
		if is_attacking or is_ambush_lunging:
			cancel_attack()
		if is_skill_active:
			cancel_skill()
		if not is_leader and not is_dead:
			process_follower_exploring(0.0)


func set_as_leader(active: bool, new_leader: CharacterBody2D = null, slot_idx: int = 1) -> void:
	is_leader = active
	leader_node = new_leader
	queue_slot_index = slot_idx

	var game_node = get_tree().current_scene
	if not game_node or not ("current_party_command" in game_node):
		if get_parent() and ("current_party_command" in get_parent()):
			game_node = get_parent()
	if game_node and "current_party_command" in game_node:
		party_command = game_node.current_party_command as PartyCommand

	if is_leader:
		in_party_combat = false
		ai_attack_timer = 0.0
		if not is_attacking and not is_skill_active and not is_ambush_lunging:
			play_idle_animation()
		print(name, " maju sebagai Leader aktif!")
	else:
		if is_skill_active:
			cancel_skill()
		ai_attack_timer = randf_range(0.3, 0.7)
		if not is_attacking and not is_skill_active and not is_ambush_lunging:
			play_idle_animation()


func cancel_skill() -> void:
	attack_token += 1
	is_skill_active = false
	skill_phase = SkillPhase.INACTIVE
	skill_timer = 0.0
	skill_dash_time = 0.0
	skill_slash_step = 0
	skill_stuck_timer = 0.0
	skill_target_enemy = null
	skill_hit_enemies_step.clear()
	if triple_slash_sprite:
		triple_slash_sprite.visible = false
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		require_mouse_release = true
	if not is_dead and not is_moving and not is_attacking and not is_ambush_lunging:
		play_idle_animation()


func cancel_attack() -> void:
	attack_token += 1
	is_attacking = false
	is_ambush_lunging = false
	is_ambush_attack = false
	attack_step = 0
	attack_elapsed_timer = 0.0
	attack_stuck_timer = 0.0
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		require_mouse_release = true
	if not is_dead and not is_moving and not is_skill_active:
		play_idle_animation()


func set_party_combat_mode(active: bool) -> void:
	in_party_combat = active
	if in_party_combat:
		ai_attack_timer = randf_range(0.2, 0.5)
	else:
		ai_attack_timer = 0.0
		if not is_leader and leader_node and is_instance_valid(leader_node) and "last_direction" in leader_node:
			last_direction = leader_node.last_direction
			play_idle_animation()


# =========================================================
# PROCESS & INPUT
# =========================================================

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Reduksi knockback
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		if knockback_velocity.length() < 8.0:
			knockback_velocity = Vector2.ZERO

	# Cooldown invulnerability frame
	if invulnerability_timer > 0.0:
		invulnerability_timer -= delta

	# Cooldown serangan dasar
	if attack_timer > 0.0:
		attack_timer -= delta

	# Cooldown skill Triple Slash
	if skill_cooldown_timer > 0.0:
		skill_cooldown_timer -= delta

	# Penghitungan Pasif Out-of-Combat Ambush Lunge (5 detik)
	if not is_passive_ready:
		passive_timer += delta
		if passive_timer >= PASSIVE_OUT_OF_COMBAT_TIME:
			is_passive_ready = true
			passive_timer = PASSIVE_OUT_OF_COMBAT_TIME
			print(name, " [Pasif Siap] Ambush Lunge siap dilancarkan!")

	update_passive_visual(delta)

	# Penanganan aktif skill Dash & Triple Slash
	if is_skill_active:
		process_triple_slash_skill(delta)

	# Penanganan aktif melesat cepat pasif (Ambush Lunge)
	if is_ambush_lunging:
		process_ambush_lunge(delta)

	# Shield timer & visual update (dari Knight)
	if is_shield_active or (shield_sprite and shield_sprite.visible):
		if is_shield_active:
			shield_timer -= delta
			if shield_timer <= 0.0:
				deactivate_shield()
		update_shield_visual()

	# Timing ayunan tebasan dasar (Double Swing: Ayunan 1 pada ~0.15s, Ayunan 2 pada ~0.40s)
	if is_attacking:
		attack_elapsed_timer += delta
		attack_stuck_timer += delta

		# Ayunan 1 (Frame 2)
		if attack_step == 0 and attack_elapsed_timer >= SWING_1_IMPACT_TIME:
			attack_step = 1
			play_sfx(SFX_BANDIT_SLASH_1, -3.0)
			execute_slash_damage(attack_direction, 1)

		# Ayunan 2 (Frame 6)
		elif attack_step == 1 and attack_elapsed_timer >= SWING_2_IMPACT_TIME:
			attack_step = 2
			play_sfx(SFX_BANDIT_SLASH_2, -3.0)
			execute_slash_damage(attack_direction, 2)

		# Selesai setelah siklus 8 frame tuntas (~0.58s)
		if attack_elapsed_timer >= ATTACK_TOTAL_DURATION or attack_stuck_timer >= 0.75:
			is_attacking = false
			is_ambush_attack = false
			attack_step = 0
			attack_elapsed_timer = 0.0
			attack_stuck_timer = 0.0
			attack_token += 1
			if not is_dead and not is_moving and not is_skill_active and not is_ambush_lunging:
				play_idle_animation()
	else:
		attack_stuck_timer = 0.0

	# Pemisahan kendali Leader vs Follower
	if is_leader:
		process_leader_movement(delta)
	else:
		if in_party_combat and party_command == PartyCommand.ATTACK:
			process_follower_combat(delta)
		else:
			process_follower_exploring(delta)

	# Debu lari saat sprint
	handle_run_dust_cycle(delta)


func update_passive_visual(_delta: float) -> void:
	if is_dead:
		return
	if is_passive_ready and not is_attacking and not is_skill_active and not is_ambush_lunging and not is_damage_flash_active:
		# Denyut aura tipis bayangan (shimmer biru-violet) penanda pasif siap
		var pulse: float = (sin(Time.get_ticks_msec() * 0.007) + 1.0) * 0.5
		modulate = Color(0.85 + 0.3 * pulse, 0.95 + 0.15 * pulse, 1.35 + 0.35 * pulse, 1.0)
	elif not is_passive_ready and not is_damage_flash_active:
		if modulate != Color.WHITE:
			modulate = Color.WHITE


func is_skill_action_pressed(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_skill"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if not is_leader or is_dead:
		return

	# Tombol E: Aktivasi Skill Triple Slash (HANYA Leader)
	if is_skill_action_pressed(event):
		if skill_cooldown_timer <= 0.0 and not is_attacking and not is_skill_active and not is_ambush_lunging:
			activate_triple_slash()
			get_viewport().set_input_as_handled()
		return

	# Serangan dasar klik kiri
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if not require_mouse_release and attack_timer <= 0.0 and not is_attacking and not is_skill_active and not is_ambush_lunging:
					shoot_towards(get_global_mouse_position())
			else:
				require_mouse_release = false


func process_leader_movement(_delta: float) -> void:
	if is_skill_active or is_ambush_lunging:
		return

	# Reset require_mouse_release jika mouse kiri dilepas
	if require_mouse_release:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			require_mouse_release = false

	# Serangan dasar klik kiri (Hold / Tap)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not require_mouse_release and attack_timer <= 0.0 and not is_attacking and not is_skill_active and not is_ambush_lunging:
			shoot_towards(get_global_mouse_position())

	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1

	input_dir = input_dir.normalized()
	var is_sprinting: bool = Input.is_key_pressed(KEY_SHIFT)
	var current_speed: float = SPRINT_SPEED if is_sprinting else NORMAL_SPEED

	var move_velocity := Vector2.ZERO

	if input_dir != Vector2.ZERO:
		is_moving = true
		last_movement_direction = input_dir

		if is_attacking or is_skill_active or is_ambush_lunging:
			move_velocity = Vector2.ZERO
		else:
			move_velocity = input_dir * current_speed
			update_direction_animation(input_dir)
	else:
		is_moving = false
		if not is_attacking and not is_skill_active and not is_ambush_lunging and animated_sprite.animation.begins_with("walk_"):
			play_idle_animation()

	velocity = move_velocity + knockback_velocity
	move_and_slide_with_separation()


# =========================================================
# SPECIAL SKILL: DASH, KNOCKUP & TRIPLE SLASH (TOMBOL E)
# =========================================================

func activate_triple_slash(target_pos: Vector2 = Vector2.ZERO) -> void:
	# Skill E HANYA boleh digunakan saat Bandit menjadi karakter aktif (Leader)
	if not is_leader or is_skill_active or is_dead or is_attacking or is_ambush_lunging or skill_cooldown_timer > 0.0:
		return

	is_skill_active = true
	is_moving = false
	is_attacking = false
	is_ambush_lunging = false
	skill_phase = SkillPhase.DASHING
	skill_timer = 0.0
	skill_dash_time = 0.0
	skill_slash_step = 0
	skill_stuck_timer = 0.0
	skill_target_enemy = null
	skill_hit_enemies_step.clear()

	var mouse_pos := get_global_mouse_position() if target_pos == Vector2.ZERO else target_pos
	var dir := global_position.direction_to(mouse_pos).normalized()
	if dir == Vector2.ZERO:
		dir = last_direction

	skill_dash_dir = dir
	attack_direction = dir
	last_direction = get_cardinal_direction(dir)

	# Mainkan animasi karakter skill_[e|w|n|s] saat meluncur dash
	var dir_str := get_direction_string(last_direction)
	if animated_sprite:
		animated_sprite.flip_h = false
		animated_sprite.play("skill_" + dir_str)

	spawn_run_dust(skill_dash_dir)
	apply_camera_shake(3.0)
	play_sfx(SFX_BANDIT_SKILL_DASH, -1.0)
	print(name, " memulai DASH TRIPLE SLASH dengan animasi skill_", dir_str, "!")


func process_triple_slash_skill(delta: float) -> void:
	skill_timer += delta
	skill_stuck_timer += delta

	# FASE 1: DASH CEPAT MENCARI TARGET MUSUH PERTAMA
	if skill_phase == SkillPhase.DASHING:
		skill_dash_time += delta

		# Pastikan animasi skill tetap aktif dan tidak tertimpa
		var dir_str := get_direction_string(last_direction)
		if animated_sprite and not animated_sprite.animation.begins_with("skill_"):
			animated_sprite.flip_h = false
			animated_sprite.play("skill_" + dir_str)

		velocity = skill_dash_dir * SKILL_DASH_SPEED
		move_and_slide_with_separation()

		# Deteksi benturan dinding/struktur solid selama dash untuk mencegah jittering di depan dinding
		if get_slide_collision_count() > 0:
			for i in range(get_slide_collision_count()):
				var col := get_slide_collision(i)
				var collider = col.get_collider()
				if collider is StaticBody2D or collider is TileMapLayer:
					var normal := col.get_normal()
					if skill_dash_dir.dot(normal) < -0.4:
						velocity = Vector2.ZERO
						skill_dash_time = MAX_DASH_DURATION
						apply_camera_shake(2.0)
						break

		# Deteksi apakah ada musuh yang tertabrak di jalur dash
		var hit_enemy := check_dash_collision_enemy()
		if hit_enemy:
			# Dash berhenti tepat pada musuh pertama yang tertabrak!
			velocity = Vector2.ZERO
			skill_target_enemy = hit_enemy
			skill_phase = SkillPhase.KNOCKUP_SLASH
			skill_timer = 0.0
			skill_slash_step = 0

			# Hadap ke arah musuh yang tertabrak
			var to_enemy: Vector2 = hit_enemy.global_position - global_position
			if to_enemy != Vector2.ZERO:
				skill_dash_dir = to_enemy.normalized()
				attack_direction = skill_dash_dir
				last_direction = get_cardinal_direction(skill_dash_dir)

			# 1. Musuh yang tertabrak terkena efek KNOCKUP (terangkat ke udara dan stun singkat)
			apply_knockup_to_enemy(hit_enemy, 0.70, 40.0)

			# 2. HENTIKAN DAN BERSIHKAN VISUAL DASH SEKETIKA:
			# Karakter beralih secara bersih 100% ke animasi kombo Triple Slash pada AnimatedSprite2D tunggal
			if animated_sprite:
				animated_sprite.stop()
				animated_sprite.flip_h = (last_direction == Vector2.LEFT)
				animated_sprite.play("triple_slash")

			if triple_slash_sprite:
				triple_slash_sprite.visible = false

			apply_camera_shake(5.0)
			play_sfx(SFX_BANDIT_KNOCKUP, 0.0)
			print(name, " menabrak ", hit_enemy.name, " -> KNOCKUP & Memulai TRIPLE SLASH!")
			return

		# Jika batas durasi dash tercapai tanpa menabrak musuh (Miss Dash)
		if skill_dash_time >= MAX_DASH_DURATION:
			velocity = Vector2.ZERO
			# Biarkan frame visual animasi skill tuntas secara mulus sebelum kembali ke idle/run
			var is_anim_finished: bool = true
			if animated_sprite and animated_sprite.animation.begins_with("skill_"):
				# skill_* memiliki 4 frame (0-3) pada speed 10 (durasi 0.40s).
				# Jika belum mencapai frame terakhir dan masih dalam window toleransi (hingga 0.42s), biarkan tuntas.
				if animated_sprite.is_playing() and animated_sprite.frame < 3 and skill_dash_time < 0.42:
					is_anim_finished = false

			if is_anim_finished:
				is_skill_active = false
				skill_phase = SkillPhase.INACTIVE
				skill_cooldown_timer = skill_cooldown_max
				velocity = Vector2.ZERO
				if not is_dead:
					if is_moving:
						var move_dir := last_movement_direction if last_movement_direction != Vector2.ZERO else last_direction
						update_direction_animation(move_dir)
					else:
						play_idle_animation()
				print(name, " dash miss tuntas dengan animasi selesai. Cooldown aktif.")
				return

	# FASE 2: KNOCKUP & EKSEKUSI TRIPLE SLASH (3X HIT BERUNTUN)
	elif skill_phase == SkillPhase.KNOCKUP_SLASH:
		velocity = Vector2.ZERO

		# 3x Hit beruntun selaras dengan animasi triple_slash (12 frames pada 16 FPS, total ~0.65s):
		# Slash 1: ~0.10s
		# Slash 2: ~0.26s
		# Slash 3: ~0.42s
		if skill_slash_step == 0 and skill_timer >= 0.10:
			skill_slash_step = 1
			execute_triple_slash_step(1, 2, 135.0, 4.0)
		elif skill_slash_step == 1 and skill_timer >= 0.26:
			skill_slash_step = 2
			execute_triple_slash_step(2, 2, 140.0, 4.5)
		elif skill_slash_step == 2 and skill_timer >= 0.42:
			skill_slash_step = 3
			execute_triple_slash_step(3, 2, 150.0, 7.5)

		# Selesai setelah siklus animasi tuntas (~0.65s)
		if skill_timer >= 0.65 or skill_stuck_timer >= 1.0:
			is_skill_active = false
			skill_phase = SkillPhase.INACTIVE
			skill_timer = 0.0
			skill_slash_step = 0
			skill_stuck_timer = 0.0
			skill_cooldown_timer = skill_cooldown_max # Cooldown 5.0s dimulai setelah eksekusi selesai
			if triple_slash_sprite:
				triple_slash_sprite.visible = false
			if not is_dead and not is_moving:
				play_idle_animation()
			print(name, " menyelesaikan Triple Slash. Cooldown: ", skill_cooldown_max, " detik.")


func check_dash_collision_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var closest_e: Node2D = null
	var min_d: float = 60.0

	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			var enemy_node := e as Node2D
			if not enemy_node:
				continue
			var d: float = global_position.distance_to(enemy_node.global_position)
			if d <= min_d:
				var to_e: Vector2 = (enemy_node.global_position - global_position).normalized()
				if skill_dash_dir.dot(to_e) > 0.1 or d <= 38.0:
					min_d = d
					closest_e = enemy_node
	return closest_e


func apply_knockup_to_enemy(enemy_node: Node2D, duration: float = 0.70, height: float = 40.0) -> void:
	if not enemy_node or not is_instance_valid(enemy_node):
		return
	if enemy_node.has_method("apply_knockup"):
		enemy_node.apply_knockup(duration, height)
	else:
		if "velocity" in enemy_node:
			enemy_node.velocity = Vector2.ZERO
		var sprite = enemy_node.get_node_or_null("AnimatedSprite2D")
		if sprite:
			var orig_y: float = sprite.position.y
			var tween := create_tween()
			tween.tween_property(sprite, "position:y", orig_y - height, duration * 0.4)\
				.set_trans(Tween.TRANS_QUAD)\
				.set_ease(Tween.EASE_OUT)
			tween.tween_property(sprite, "position:y", orig_y, duration * 0.6)\
				.set_trans(Tween.TRANS_BOUNCE)\
				.set_ease(Tween.EASE_OUT)


func execute_triple_slash_step(step: int, damage: int, range_dist: float, shake_amount: float) -> void:
	skill_hit_enemies_step.clear()
	apply_camera_shake(shake_amount)

	var slash_center := global_position + VISUAL_CENTER_OFFSET
	var enemies := get_tree().get_nodes_in_group("enemy")

	for e in enemies:
		if not is_instance_valid(e) or ("is_dead" in e and e.is_dead):
			continue

		var to_enemy: Vector2 = e.global_position - slash_center
		var dist: float = to_enemy.length()

		if dist <= range_dist:
			var angle_diff: float = absf(skill_dash_dir.angle_to(to_enemy))
			if angle_diff <= deg_to_rad(110.0) or dist <= 65.0 or e == skill_target_enemy:
				if has_line_of_sight_to(e) or e == skill_target_enemy:
					skill_hit_enemies_step.append(e)
					if e.has_method("take_damage"):
						e.take_damage(damage, self)

	# Reset timer pasif saat memberikan damage
	if not skill_hit_enemies_step.is_empty():
		passive_timer = 0.0
		is_passive_ready = false
		if step == 3:
			play_sfx(SFX_BANDIT_TRIPLE_SLASH_FINISH, 0.0)
		else:
			play_sfx(SFX_BANDIT_TRIPLE_SLASH_HIT, -2.0)
	else:
		if step == 3:
			play_sfx(SFX_BANDIT_SLASH_2, -2.0)
		else:
			play_sfx(SFX_BANDIT_SLASH_1, -3.0)

	print(name, " [Triple Slash ", step, "/3] mengenai ", skill_hit_enemies_step.size(), " musuh (Damage: ", damage, ")")


# =========================================================
# SERANGAN DASAR (DOUBLE SLASH DAGGER & AMBUSH LUNGE)
# =========================================================

func shoot_towards(target_pos: Vector2) -> void:
	if attack_timer > 0.0 or is_attacking or is_dead or is_skill_active or is_ambush_lunging:
		return

	# [BATASI SERANGAN KOSONG]: Jika karakter aktif (Leader), wajib ada musuh valid di layar & jangkauan
	if is_leader and not has_valid_attack_target():
		return

	is_moving = false
	velocity = knockback_velocity

	var bandit_center := global_position + VISUAL_CENTER_OFFSET
	var dir := bandit_center.direction_to(target_pos)
	if dir == Vector2.ZERO:
		dir = last_direction

	attack_direction = dir
	last_direction = get_cardinal_direction(dir)

	# Cek apakah Pasif Ambush Lunge siap
	if is_passive_ready:
		var target_enemy := find_ambush_target_in_range(target_pos, AMBUSH_ENGAGE_RANGE)
		if target_enemy:
			start_ambush_lunge(target_enemy)
			return

	# Serangan dasar normal
	start_normal_attack(false)


func find_ambush_target_in_range(target_pos: Vector2, max_range: float) -> Node2D:
	var cam_rect := get_camera_world_rect()
	var enemies := get_tree().get_nodes_in_group("enemy")
	var best_enemy: Node2D = null
	var min_cursor_dist: float = 120.0
	var min_dist: float = max_range

	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			if cam_rect.has_point(e.global_position):
				var d_char: float = global_position.distance_to(e.global_position)
				if d_char <= max_range:
					var d_cursor: float = target_pos.distance_to(e.global_position)
					if d_cursor < min_cursor_dist:
						min_cursor_dist = d_cursor
						min_dist = d_char
						best_enemy = e
					elif best_enemy == null and d_char < min_dist:
						min_dist = d_char
						best_enemy = e
	return best_enemy


func start_ambush_lunge(target_enemy: Node2D) -> void:
	is_ambush_lunging = true
	ambush_target_enemy = target_enemy
	ambush_lunge_timer = 0.0
	ambush_lunge_dir = global_position.direction_to(target_enemy.global_position).normalized()
	if ambush_lunge_dir == Vector2.ZERO:
		ambush_lunge_dir = last_direction

	attack_direction = ambush_lunge_dir
	last_direction = get_cardinal_direction(ambush_lunge_dir)
	play_attack_animation()
	spawn_run_dust(ambush_lunge_dir)
	apply_camera_shake(3.0)
	play_sfx(SFX_BANDIT_AMBUSH_LUNGE, -2.0)
	print(name, " melancarkan AMBUSH LUNGE ke arah musuh!")


func process_ambush_lunge(delta: float) -> void:
	ambush_lunge_timer += delta
	var dist_to_target: float = INF
	if ambush_target_enemy and is_instance_valid(ambush_target_enemy):
		dist_to_target = global_position.distance_to(ambush_target_enemy.global_position)
		ambush_lunge_dir = global_position.direction_to(ambush_target_enemy.global_position).normalized()
		attack_direction = ambush_lunge_dir
		last_direction = get_cardinal_direction(ambush_lunge_dir)

	velocity = ambush_lunge_dir * 680.0
	move_and_slide_with_separation()

	# Jika sudah dalam jarak jangkauan tebasan (<= 70 px) atau batas waktu lunge tercapai (0.22s)
	if dist_to_target <= 70.0 or ambush_lunge_timer >= 0.22:
		is_ambush_lunging = false
		velocity = Vector2.ZERO
		start_normal_attack(true)


func start_normal_attack(with_ambush: bool) -> void:
	is_attacking = true
	is_ambush_attack = with_ambush
	attack_step = 0
	attack_elapsed_timer = 0.0
	attack_stuck_timer = 0.0
	attack_token += 1
	play_attack_animation()
	attack_timer = attack_cooldown


func execute_slash_damage(attack_dir: Vector2, swing_number: int = 1) -> void:
	var current_swing_hits: Array[Node2D] = []
	var shake_val: float = 3.5
	var base_dmg: int = attack_damage

	# Serangan pembuka dari pasif Ambush memberikan damage bonus
	if is_ambush_attack and swing_number == 1:
		base_dmg += AMBUSH_BONUS_DAMAGE # 2 + 3 = 5 damage pembuka
		shake_val = 6.0
		# Pasif dikonsumsi
		is_passive_ready = false
		passive_timer = 0.0
		if not is_damage_flash_active:
			modulate = Color.WHITE
		print(name, " [AMBUSH STRIKE LANDED!] Damage pembuka bertambah: ", base_dmg)

	apply_camera_shake(shake_val)

	var slash_range: float = attack_range
	var slash_arc_deg: float = 160.0
	var close_contact_radius: float = 75.0
	var center_offset: Vector2 = VISUAL_CENTER_OFFSET

	if attack_dir.y > 0.3:
		slash_range = 140.0
		close_contact_radius = 85.0
		slash_arc_deg = 180.0
		center_offset = Vector2(0.0, 20.0)

	var bandit_center := global_position + center_offset
	var enemies := get_tree().get_nodes_in_group("enemy")

	for e in enemies:
		if not is_instance_valid(e) or ("is_dead" in e and e.is_dead):
			continue

		var to_enemy: Vector2 = e.global_position - bandit_center
		var dist: float = to_enemy.length()
		var is_hit: bool = false

		if dist <= close_contact_radius or (is_ambush_attack and e == ambush_target_enemy):
			is_hit = true
		elif dist <= slash_range:
			var angle_diff: float = absf(attack_dir.angle_to(to_enemy))
			if angle_diff <= deg_to_rad(slash_arc_deg * 0.5):
				if has_line_of_sight_to(e):
					is_hit = true

		if is_hit:
			current_swing_hits.append(e)
			if e.has_method("take_damage"):
				e.take_damage(base_dmg, self)

	# Reset timer pasif saat memberikan damage
	if not current_swing_hits.is_empty():
		passive_timer = 0.0
		is_passive_ready = false
		if is_ambush_attack and swing_number == 1:
			play_sfx(SFX_BANDIT_AMBUSH_HIT, -1.0)
		else:
			play_sfx(SFX_BANDIT_SLASH_HIT, -2.0)

	print(name, " [Double Slash Swing ", swing_number, "/2] mengenai ", current_swing_hits.size(), " musuh (Damage: ", base_dmg, ")")


func has_valid_attack_target() -> bool:
	var cam_rect := get_camera_world_rect()
	var enemies := get_tree().get_nodes_in_group("enemy")
	var range_limit := AMBUSH_ENGAGE_RANGE if is_passive_ready else (attack_range * 1.5)
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			if cam_rect.has_point(e.global_position):
				if global_position.distance_to(e.global_position) <= range_limit:
					return true
	return false


func has_line_of_sight_to(target_node: Node2D) -> bool:
	if not target_node or not is_instance_valid(target_node):
		return false
	var space_state := get_world_2d().direct_space_state
	var bandit_center := global_position + VISUAL_CENTER_OFFSET
	var exclude_rids: Array[RID] = [get_rid()]
	if target_node is CollisionObject2D:
		exclude_rids.append(target_node.get_rid())

	# Kecualikan seluruh anggota party player agar raycast tidak terhalang rekan atau perisai
	var party := get_tree().get_nodes_in_group("player")
	for p in party:
		if is_instance_valid(p) and p is CollisionObject2D:
			exclude_rids.append(p.get_rid())

	var query := PhysicsRayQueryParameters2D.create(bandit_center, target_node.global_position)
	query.collision_mask = 1
	query.exclude = exclude_rids
	var hit := space_state.intersect_ray(query)
	if not hit.is_empty():
		var col = hit.get("collider")
		if col is TileMapLayer or col is StaticBody2D:
			return false
	return true


# =========================================================
# FOLLOWER LOGIC (EXPLORING & COMBAT)
# =========================================================

func process_follower_exploring(delta: float) -> void:
	if not leader_node or not is_instance_valid(leader_node) or ("is_dead" in leader_node and leader_node.is_dead):
		velocity = knockback_velocity
		move_and_slide_with_separation()
		if not is_attacking and not is_skill_active and not is_ambush_lunging:
			play_idle_animation()
		return

	if animated_sprite.animation.begins_with("attack_") and not is_attacking:
		play_idle_animation()

	var game_node = get_tree().current_scene
	var nav_info: Dictionary = {}
	if game_node and game_node.has_method("get_follower_nav_target"):
		var space_state := get_world_2d().direct_space_state
		nav_info = game_node.get_follower_nav_target(queue_slot_index, global_position, space_state)
	elif game_node and game_node.has_method("get_follower_trail_slot"):
		var slot_info = game_node.get_follower_trail_slot(queue_slot_index)
		if not slot_info.is_empty():
			nav_info = {
				"target_pos": slot_info["pos"],
				"final_slot": slot_info["pos"],
				"dir": slot_info.get("dir", Vector2.DOWN),
				"is_corner_waypoint": false
			}

	if nav_info.is_empty():
		return

	var target_pos: Vector2 = nav_info["target_pos"]
	var follow_slot: Vector2 = nav_info["final_slot"]
	var target_facing: Vector2 = nav_info.get("dir", leader_node.last_direction if (leader_node and is_instance_valid(leader_node) and "last_direction" in leader_node) else Vector2.DOWN)
	var dist_to_target := global_position.distance_to(target_pos)
	var dist_to_slot := global_position.distance_to(follow_slot)

	# --- PROTEKSI ANTI-STUCK & CATCH-UP ---
	if leader_node and is_instance_valid(leader_node):
		var dist_to_leader := global_position.distance_to(leader_node.global_position)
		if dist_to_leader > 650.0:
			global_position = follow_slot
			velocity = Vector2.ZERO
			is_moving = false
			modulate.a = 0.3
			var tw = create_tween()
			tw.tween_property(self, "modulate:a", 1.0, 0.3)
			return

	var leader_is_moving := false
	if leader_node and is_instance_valid(leader_node):
		if "is_moving" in leader_node and leader_node.is_moving:
			leader_is_moving = true
		elif "velocity" in leader_node and leader_node.velocity.length() >= 10.0:
			leader_is_moving = true

	# Kondisi berhenti tegas saat Leader diam
	if not leader_is_moving and dist_to_slot <= 16.0:
		if knockback_velocity != Vector2.ZERO:
			velocity = knockback_velocity
			move_and_slide_with_separation()
			return
		velocity = Vector2.ZERO
		is_moving = false
		global_position = global_position.move_toward(follow_slot, 50.0 * delta)
		if leader_node and is_instance_valid(leader_node) and "last_direction" in leader_node:
			last_direction = leader_node.last_direction
		play_idle_animation()
		move_and_slide_with_separation()
		return

	# Hysteresis deadzone
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
		if not leader_is_moving and leader_node and is_instance_valid(leader_node) and "last_direction" in leader_node:
			last_direction = leader_node.last_direction
		else:
			last_direction = target_facing
		if not is_attacking and not is_skill_active and not is_ambush_lunging:
			play_idle_animation()
	else:
		var aim_pos: Vector2 = target_pos
		if nav_info.get("is_corner_waypoint", false) and dist_to_target <= 20.0:
			aim_pos = follow_slot

		var move_dir := global_position.direction_to(aim_pos)
		var follow_speed := NORMAL_SPEED
		if Input.is_key_pressed(KEY_SHIFT) or (leader_node and is_instance_valid(leader_node) and leader_node.velocity.length() > NORMAL_SPEED + 10.0):
			follow_speed = SPRINT_SPEED
		elif dist_to_slot > 180.0:
			follow_speed = SPRINT_SPEED
		elif dist_to_slot > 90.0:
			follow_speed = NORMAL_SPEED * 1.15

		var current_speed: float = min(follow_speed, dist_to_target / max(delta, 0.001))
		velocity = (move_dir * current_speed) + knockback_velocity
		move_and_slide_with_separation()

		# Corner-Slide Assist: jika terhalang dinding saat berbelok, meluncur di sepanjang bidang normal
		if get_slide_collision_count() > 0 and velocity.length() < current_speed * 0.4:
			var col := get_slide_collision(0)
			var n := col.get_normal()
			var tangent := Vector2(-n.y, n.x)
			if move_dir.dot(tangent) < 0.0:
				tangent = -tangent
			velocity = tangent * (current_speed * 0.8) + knockback_velocity
			move_and_slide()

		is_moving = true
		last_movement_direction = move_dir
		update_direction_animation(move_dir)


func process_follower_combat(delta: float) -> void:
	if not in_party_combat:
		return
	if is_attacking or is_skill_active or is_ambush_lunging:
		velocity = knockback_velocity
		move_and_slide_with_separation()
		return

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
		process_follower_exploring(delta)
		return

	var dist_to_enemy := global_position.distance_to(target_enemy.global_position)
	var engage_threshold := AMBUSH_ENGAGE_RANGE if is_passive_ready else COMBAT_ATTACK_RANGE

	if dist_to_enemy <= engage_threshold:
		velocity = knockback_velocity
		is_moving = false
		move_and_slide_with_separation()
		last_direction = get_cardinal_direction(global_position.direction_to(target_enemy.global_position))
		if not is_attacking and not is_skill_active and not is_ambush_lunging:
			play_idle_animation()
		ai_attack_timer -= delta
		if ai_attack_timer <= 0.0 and not is_attacking and not is_ambush_lunging:
			ai_attack_timer = attack_cooldown
			# Follower Bandit HANYA menggunakan serangan dasar melee (dilarang menggunakan skill otomatis)
			shoot_towards(target_enemy.global_position)
		return
	else:
		var move_dir := global_position.direction_to(target_enemy.global_position)
		velocity = (move_dir * NORMAL_SPEED) + knockback_velocity
		move_and_slide_with_separation()

		# Corner-Slide Assist saat mengejar musuh melewati sudut bangunan
		if get_slide_collision_count() > 0 and velocity.length() < NORMAL_SPEED * 0.4:
			var col := get_slide_collision(0)
			var n := col.get_normal()
			var tangent := Vector2(-n.y, n.x)
			if move_dir.dot(tangent) < 0.0:
				tangent = -tangent
			velocity = tangent * (NORMAL_SPEED * 0.8) + knockback_velocity
			move_and_slide()

		last_movement_direction = move_dir
		update_direction_animation(move_dir)


# =========================================================
# DAMAGE, HEALTH, KNOCKBACK & RESPAWN
# =========================================================

func has_super_armor() -> bool:
	return is_skill_active or is_ambush_lunging or (is_attacking and is_ambush_attack)


func take_damage(amount: int, source_position = null) -> void:
	if is_dead or invulnerability_timer > 0.0:
		return
	invulnerability_timer = invulnerability_duration

	var in_super_armor: bool = has_super_armor()

	var knockback_dir := Vector2.ZERO
	if source_position is Node2D and is_instance_valid(source_position):
		knockback_dir = source_position.global_position.direction_to(global_position)
	elif source_position is Vector2 and source_position != Vector2.ZERO:
		if source_position.distance_squared_to(global_position) > 0.1:
			knockback_dir = source_position.direction_to(global_position)

	if knockback_dir == Vector2.ZERO:
		knockback_dir = -last_direction
	if knockback_dir == Vector2.ZERO:
		knockback_dir = Vector2.UP

	# 1. SHIELD GUARD (DARI KNIGHT): Menahan 100% damage serangan musuh
	if is_shield_active:
		modulate = Color(1.8, 1.8, 2.4)
		var shield_flash_tween = create_tween()
		shield_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
		apply_camera_shake(3.0)
		play_sfx(SFX_SHIELD_BLOCK, 0.0)
		# Jika sedang memiliki super armor atau sedang melancarkan serangan, dilarang knockback dan dilarang membatalkan aksi!
		if not in_super_armor and not is_attacking:
			apply_knockback(knockback_dir * 80.0)
		print(name, " memblok serangan dengan perisai! 0 damage diterima. Aksi berlanjut.")
		return

	# 2. DAMAGE NORMAL
	current_health = max(0, current_health - amount)
	play_sfx(SFX_HURT, -4.0)
	print(name, " terkena serangan! Sisa HP: ", current_health)

	# Efek kedip merah saat terkena serangan (Tween non-blocking)
	is_damage_flash_active = true
	modulate = Color(2.5, 0.3, 0.3)
	var hit_tween = create_tween()
	hit_tween.tween_property(self, "modulate", Color.WHITE, 0.12)
	hit_tween.tween_callback(func(): is_damage_flash_active = false)

	# Cek kematian
	if current_health <= 0:
		cancel_attack()
		cancel_skill()
		die()
		return

	# 3. SUPER ARMOR / POISE: Jika sedang dalam aksi pasif lunge atau skill 'E', dilarang terinterupsi!
	if in_super_armor:
		print(name, " [SUPER ARMOR AKTIF]: Menerima damage namun aksi lunge/skill dilarang batal!")
		return

	# 4. JIKA TIDAK MEMILIKI SUPER ARMOR: Batalkan aksi dan terapkan knockback
	passive_timer = 0.0
	is_passive_ready = false
	cancel_attack()
	cancel_skill()
	apply_knockback(knockback_dir * knockback_strength)


func apply_knockback(force: Vector2) -> void:
	if force == Vector2.ZERO:
		return
	knockback_velocity = force
	is_moving = false


func die() -> void:
	if is_dead:
		return
	is_dead = true
	play_sfx(SFX_DEATH, -2.0)
	velocity = Vector2.ZERO
	is_moving = false
	is_attacking = false
	is_ambush_lunging = false
	is_ambush_attack = false
	attack_step = 0
	attack_elapsed_timer = 0.0
	attack_stuck_timer = 0.0
	is_skill_active = false
	skill_phase = SkillPhase.INACTIVE
	passive_timer = 0.0
	is_passive_ready = false
	deactivate_shield()
	ai_attack_timer = 0.0
	knockback_velocity = Vector2.ZERO
	if triple_slash_sprite:
		triple_slash_sprite.visible = false
	print("Bandit Gugur! Menunggu respawn...")

	if is_leader:
		var game_node = get_tree().current_scene
		if not game_node or not game_node.has_method("switch_to_next_character"):
			if get_parent() and get_parent().has_method("switch_to_next_character"):
				game_node = get_parent()
		if game_node and game_node.has_method("switch_to_next_character"):
			game_node.switch_to_next_character()

	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	remove_from_group("player")

	var death_tween = create_tween()
	death_tween.tween_property(self, "modulate", Color(0.8, 0.2, 0.2, 0.0), 0.5)
	await death_tween.finished

	await get_tree().create_timer(respawn_time).timeout
	respawn()


func respawn() -> void:
	deactivate_shield()
	var game_node = get_tree().current_scene

	# Tentukan posisi respawn: muncul di dekat Leader yang masih hidup
	var respawn_pos := spawn_position
	var target_leader: CharacterBody2D = null
	if leader_node and is_instance_valid(leader_node) and not ("is_dead" in leader_node and leader_node.is_dead):
		target_leader = leader_node
	elif game_node and game_node.has_method("get_active_leader"):
		var active_lead = game_node.get_active_leader()
		if active_lead and is_instance_valid(active_lead) and active_lead != self and not ("is_dead" in active_lead and active_lead.is_dead):
			target_leader = active_lead

	if target_leader:
		var offset_dir := Vector2.UP
		if "last_direction" in target_leader and target_leader.last_direction != Vector2.ZERO:
			offset_dir = -target_leader.last_direction
		elif "last_movement_direction" in target_leader and target_leader.last_movement_direction != Vector2.ZERO:
			offset_dir = -target_leader.last_movement_direction
		respawn_pos = target_leader.global_position + offset_dir * 70.0

	global_position = respawn_pos
	target_position = respawn_pos
	current_health = max_health
	play_sfx(SFX_RESPAWN, -2.0)
	invulnerability_timer = 1.5
	is_moving = false
	is_attacking = false
	is_ambush_lunging = false
	is_ambush_attack = false
	attack_step = 0
	attack_elapsed_timer = 0.0
	attack_stuck_timer = 0.0
	is_skill_active = false
	skill_phase = SkillPhase.INACTIVE
	is_dead = false
	knockback_velocity = Vector2.ZERO
	passive_timer = 0.0
	is_passive_ready = false

	add_to_group("player")
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", false)

	modulate = Color(1.0, 1.0, 1.0, 0.0)
	visible = true
	var respawn_tween = create_tween()
	respawn_tween.tween_property(self, "modulate", Color.WHITE, 0.6)
	play_idle_animation()
	print(name, " bangkit kembali di arena pertarungan!")


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


# =========================================================
# SHIELD GUARD INTEGRATION (DARI KNIGHT)
# =========================================================

func grant_shield(duration: float) -> void:
	if is_dead:
		return
	is_shield_active = true
	shield_timer = duration

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
	if shield_sprite and shield_sprite.visible:
		shield_sprite.position = Vector2(0.0, 1.5)


# =========================================================
# RUN DUST & CAMERA SHAKE HELPERS
# =========================================================

func handle_run_dust_cycle(delta: float) -> void:
	var current_move_speed := velocity.length()
	if current_move_speed >= (NORMAL_SPEED * 1.35) and not is_attacking and not is_skill_active and not is_dead:
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
		feet_y = 38.0
		lag_y = 10.0
		lag_x = 7.0
	elif absf(move_dir.y) <= 0.3:
		feet_y = 36.0
		lag_y = 0.0
		lag_x = 8.0
	else:
		feet_y = 38.0
		lag_y = 6.0
		lag_x = 6.0

	var feet_pos := global_position + Vector2(0.0, feet_y)
	var spawn_pos := feet_pos - Vector2(move_dir.x * lag_x, move_dir.y * lag_y)
	spawn_pos += Vector2(randf_range(-3.0, 3.0), randf_range(-1.5, 1.5))

	dust.global_position = spawn_pos
	dust.flip_h = randf() > 0.5
	dust.scale = Vector2(randf_range(3.5, 4.5), randf_range(3.5, 4.5))
	dust.z_index = 3
	get_parent().add_child(dust)

	if is_leader:
		_footstep_toggle = not _footstep_toggle
		if _footstep_toggle:
			play_sfx(SFX_FOOTSTEP, -14.0)


func apply_camera_shake(intensity: float = -1.0) -> void:
	var amount = intensity if intensity > 0.0 else camera_shake_strength
	shake_intensity = max(shake_intensity, amount)
	if get_parent() and get_parent().has_method("apply_camera_shake"):
		get_parent().apply_camera_shake(amount)


func get_camera_world_rect() -> Rect2:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if not cam:
		return Rect2()
	var vp_size: Vector2 = get_viewport_rect().size / cam.zoom
	var center: Vector2 = cam.get_screen_center_position()
	return Rect2(center - vp_size * 0.5, vp_size).grow(50.0)


func get_cardinal_direction(dir: Vector2) -> Vector2:
	if abs(dir.x) > abs(dir.y):
		return Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if dir.y > 0 else Vector2.UP


func get_direction_string(dir: Vector2) -> String:
	var c := get_cardinal_direction(dir)
	if c == Vector2.UP:
		return "n"
	elif c == Vector2.DOWN:
		return "s"
	elif c == Vector2.RIGHT:
		return "e"
	else:
		return "w"


func play_idle_animation() -> void:
	if animated_sprite:
		var dir_str := get_direction_string(last_direction)
		animated_sprite.flip_h = false
		animated_sprite.play("idle_" + dir_str)


func update_direction_animation(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	last_direction = get_cardinal_direction(dir)
	var dir_str := get_direction_string(last_direction)
	if animated_sprite:
		animated_sprite.flip_h = false
		animated_sprite.play("walk_" + dir_str)


func play_attack_animation() -> void:
	if animated_sprite:
		var dir_str := get_direction_string(attack_direction)
		animated_sprite.flip_h = false
		animated_sprite.play("attack_" + dir_str)


# =========================================================
# BOID SEPARATION (MENCEGAH PENUMPUKAN ANTAR-HERO & MUSUH)
# =========================================================

func get_separation_vector() -> Vector2:
	var separation := Vector2.ZERO
	const min_sep_dist: float = 38.0
	var diff: Vector2 = Vector2.ZERO
	var d: float = 0.0
	var push_dir: Vector2 = Vector2.ZERO

	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e != self and is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			diff = global_position - e.global_position
			d = diff.length()
			if d < min_sep_dist:
				push_dir = diff.normalized() if d > 0.5 else Vector2(1.0, 0.0)
				separation += push_dir * (min_sep_dist - d)

	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if p != self and is_instance_valid(p) and not ("is_dead" in p and p.is_dead):
			diff = global_position - p.global_position
			d = diff.length()
			if d < 35.0:
				push_dir = diff.normalized() if d > 0.5 else Vector2(-1.0, 0.0)
				separation += push_dir * ((35.0 - d) * 0.5)

	return separation


func move_and_slide_with_separation() -> void:
	var sep := get_separation_vector()
	if sep != Vector2.ZERO:
		velocity += sep.limit_length(35.0) * 4.0
	move_and_slide()
