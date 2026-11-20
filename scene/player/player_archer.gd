extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var shield_sprite: Sprite2D = get_node_or_null("ShieldSprite")

# =========================
# PARTY SHIELD GUARD (DARI KNIGHT)
# =========================
const SHIELD_CENTER_OFFSET: Vector2 = Vector2(0.0, -0.5)
const SHIELD_DIRECTIONAL_OFFSETS: Dictionary = {
	"n": Vector2(0.0, -0.5),
	"s": Vector2(0.0, -0.5),
	"e": Vector2(0.0, -0.5),
	"w": Vector2(0.0, -0.5)
}
const BOW_DIRECTIONAL_OFFSETS: Dictionary = {
	"e": Vector2(30.0, 12.0),
	"w": Vector2(-40.0, 12.0),
	"s": Vector2(0.0, 32.0),
	"n": Vector2(0.0, -22.0),
	"ne": Vector2(26.0, -6.0),
	"nw": Vector2(-34.0, -6.0),
	"se": Vector2(24.0, 24.0),
	"sw": Vector2(-32.0, 24.0)
}
const VISUAL_CENTER_OFFSET: Vector2 = Vector2(0.0, 6.0)
# Titik tengah proyektil panah diselaraskan pas dengan posisi anak panah pada busur Archer
const BASIC_ATTACK_ARROW_OFFSET: Vector2 = Vector2(0.0, 6.0)
var is_shield_active: bool = false
var shield_timer: float = 0.0
var shield_tween: Tween = null

# =========================
# PARTY / LEADER / FOLLOWER
# =========================
var is_leader: bool = true
var is_movement_locked: bool = false
var leader_node: CharacterBody2D = null
var queue_slot_index: int = 0
var in_party_combat: bool = false
var ai_attack_timer: float = 0.0
const COMBAT_ATTACK_RANGE: float = 540.0
var is_flanking: bool = false
var flank_wp1: Vector2 = Vector2.ZERO
var flank_wp2: Vector2 = Vector2.ZERO
var flank_stage: int = 1
var flank_timeout: float = 0.0
var facing_debounce_timer: float = 0.0

func set_as_leader(active: bool, new_leader: CharacterBody2D = null, slot_idx: int = 0) -> void:
	if is_dead or current_health <= 0:
		is_leader = false
		leader_node = new_leader
		queue_slot_index = slot_idx
		return

	is_leader = active
	leader_node = new_leader
	queue_slot_index = slot_idx
	if not active:
		if not has_pending_click_move:
			target_position = global_position
			is_moving = false
			velocity = Vector2.ZERO
			if CursorManager.has_method("hide_ground_move_indicator"):
				CursorManager.hide_ground_move_indicator()
	else:
		has_pending_click_move = false

	attack_stuck_timer = 0.0

	if is_leader:
		var game_node = get_tree().current_scene if is_inside_tree() else null
		if game_node and "current_combat_state" in game_node and "PartyCombatState" in game_node:
			in_party_combat = (game_node.current_combat_state == game_node.PartyCombatState.COMBAT)
		elif not in_party_combat:
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

func reset_combat_skills() -> void:
	if current_skill_state != SkillState.INACTIVE:
		deactivate_skill_mode()
	cancel_skill()
	skill_cooldown_timer = 0.0
	attack_timer = 0.0
	is_attacking = false
	attack_stuck_timer = 0.0
	if not is_dead and not is_moving:
		play_idle_animation()


func set_party_combat_mode(active: bool) -> void:
	in_party_combat = active
	if in_party_combat:
		if not is_leader:
			ai_attack_timer = randf_range(0.3, 0.7)
	else:
		ai_attack_timer = 0.0
		is_flanking = false
		flank_wp1 = Vector2.ZERO
		flank_wp2 = Vector2.ZERO
		flank_stage = 1
		flank_timeout = 0.0
		facing_debounce_timer = 0.0
		reset_combat_skills()
		if not is_leader and leader_node and is_instance_valid(leader_node) and "last_direction" in leader_node:
			last_direction = leader_node.last_direction
			play_idle_animation()


func is_in_combat_mode() -> bool:
	if in_party_combat:
		return true
	var game_node = get_tree().current_scene if is_inside_tree() else null
	if game_node:
		if "current_combat_state" in game_node and "PartyCombatState" in game_node:
			if game_node.current_combat_state == game_node.PartyCombatState.COMBAT:
				return true
		if "arena_state" in game_node and "ArenaState" in game_node:
			if game_node.arena_state == game_node.ArenaState.COMBAT:
				return true
		if "is_in_training_arena" in game_node and game_node.is_in_training_arena:
			return true
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			if "wait_for_arena" in e and e.wait_for_arena:
				continue
			if global_position.distance_to(e.global_position) <= 650.0:
				return true
	return false


func is_in_arena() -> bool:
	var game_node = get_tree().current_scene if is_inside_tree() else null
	if not game_node:
		return false
	if "arena_state" in game_node and "ArenaState" in game_node:
		if game_node.arena_state == game_node.ArenaState.COMBAT:
			return true
	if "is_in_training_arena" in game_node and game_node.is_in_training_arena:
		return true
	if "arena_bounds" in game_node and game_node.arena_bounds.size != Vector2.ZERO:
		if game_node.arena_bounds.grow(40.0).has_point(global_position):
			return true
	if "TRAINING_ARENA_BOUNDS" in game_node and game_node.TRAINING_ARENA_BOUNDS.size != Vector2.ZERO:
		if game_node.TRAINING_ARENA_BOUNDS.grow(40.0).has_point(global_position):
			return true
	return false


func get_active_arena_bounds() -> Rect2:
	var game_node = get_tree().current_scene if is_inside_tree() else null
	if not game_node:
		return Rect2()
	if "is_in_training_arena" in game_node and game_node.is_in_training_arena:
		if "TRAINING_ARENA_BOUNDS" in game_node:
			return game_node.TRAINING_ARENA_BOUNDS
	if "arena_bounds" in game_node:
		return game_node.arena_bounds
	return Rect2()

# =========================
# MOVEMENT SETTINGS
# =========================

const NORMAL_SPEED := 128.0
const SPRINT_SPEED := 220.0
const FEET_OFFSET_Y: float = 36.0

var target_position: Vector2
var is_moving := false
var has_pending_click_move: bool = false
var click_move_stuck_timer: float = 0.0
var hold_indicator_timer: float = 0.0
var last_indicator_pos: Vector2 = Vector2.ZERO

# Pemisahan Arah Hadap (Visual/Bidikan) vs Arah Tempuh (Langkah Aktual Formasi)
var last_direction := Vector2.DOWN
var last_movement_direction := Vector2.DOWN

# =========================
# COMBAT / AUTO-ATTACK
# =========================

const ARROW_SCENE = preload("res://scene/projectile/arrow.tscn")
const TRACE_SCENE = preload("res://scene/projectile/arrow_trace.tscn")
const DUST_SCENE = preload("res://scene/effect/run_dust.tscn")
const GHOST_SCENE = preload("res://scene/effect/death_ghost.tscn")
const SFX_FOOTSTEP = preload("res://assets/audio/sfx/characters/universal/footstep_run.wav")
const SFX_HURT = preload("res://assets/audio/sfx/characters/universal/hero_hurt.wav")
const SFX_DEATH = preload("res://assets/audio/sfx/characters/universal/hero_death.wav")
const SFX_RESPAWN = preload("res://assets/audio/sfx/characters/universal/hero_respawn.wav")
const SFX_ARCHER_BOW_SHOOT = preload("res://assets/audio/sfx/characters/archer/archer_bow_shoot.wav")
const SFX_ARCHER_SKILL_MODE_ACTIVATE = preload("res://assets/audio/sfx/characters/archer/archer_skill_mode_activate.wav")
const SFX_ARCHER_SKILL_CHARGE = preload("res://assets/audio/sfx/characters/archer/archer_skill_charge.wav")
const SFX_ARCHER_SKILL_RELEASE = preload("res://assets/audio/sfx/characters/archer/archer_skill_release.wav")
const SFX_SHIELD_BLOCK = preload("res://assets/audio/sfx/characters/knight/knight_shield_block.wav")
var _footstep_toggle: bool = false

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
@export var skill_cooldown_time: float = 9.0       # Cooldown tombol E (9 detik)
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
var skill_stuck_timer: float = 0.0

@export var attack_range: float = 520.0    # Jarak jangkauan tembak ranged (pixel)
var attack_stuck_timer: float = 0.0
@export var attack_damage: int = 95        # Damage Basic Attack Archer (95 damage)
@export var attack_cooldown: float = 1.25  # Attack Speed 0.8 serangan/dtk (~1.25s jeda tembakan)
var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.RIGHT
var attack_target_pos: Vector2 = Vector2.ZERO
var attack_token: int = 0
var require_mouse_release: bool = false

# =========================
# HEALTH & RESPAWN SETTINGS
# =========================
@export var max_health: int = 450          # HP Maksimal Archer: 450 (Sniper/DPS)
@export var respawn_time: float = 3.0      # Waktu tunggu respawn setelah mati (detik)
var current_health: int = 450
var is_dead: bool = false
var spawn_position: Vector2
var shield_points: int = 0

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


func _ready() -> void:
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
	if not is_inside_tree():
		return
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and e is CollisionObject2D:
			add_collision_exception_with(e)
			e.add_collision_exception_with(self)


func get_camera() -> Camera2D:
	if has_node("Camera2D"):
		return $Camera2D
	return get_viewport().get_camera_2d()


func apply_camera_shake(intensity: float = -1.0) -> void:
	var amount: float = intensity if intensity > 0.0 else camera_shake_strength
	if get_parent() and get_parent().has_method("apply_camera_shake"):
		get_parent().apply_camera_shake(amount)


# =========================================================
# MOVEMENT & AUTO-ATTACK
# =========================================================

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_movement_locked:
		velocity = Vector2.ZERO
		is_moving = false
		if has_method("play_idle_animation"):
			play_idle_animation()
		move_and_slide()
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

	# Cooldown timer skill aktif untuk SEMUA kondisi (Leader maupun Follower)
	if skill_cooldown_timer > 0.0:
		skill_cooldown_timer -= delta

	if skill_interval_timer > 0.0:
		skill_interval_timer -= delta

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
	# Watchdog anti-stuck animasi rilis skill Archer
	if current_skill_state == SkillState.RELEASING:
		skill_stuck_timer += delta
		if skill_stuck_timer >= 0.8:
			skill_stuck_timer = 0.0
			on_skill_release_finished()
	else:
		skill_stuck_timer = 0.0

	# Pastikan skill mode otomatis reset jika tidak dalam mode combat
	if current_skill_state != SkillState.INACTIVE and not is_in_combat_mode():
		reset_combat_skills()

	if current_skill_state != SkillState.INACTIVE:
		skill_mode_timer -= delta
		if skill_mode_timer <= 0.0:
			if current_skill_state == SkillState.READY:
				deactivate_skill_mode()
			elif current_skill_state == SkillState.STARTING or current_skill_state == SkillState.CHARGING:
				execute_skill_release()

	# Hardware polling penanganan input skill Archer
	if current_skill_state == SkillState.READY:
		if require_mouse_release:
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				require_mouse_release = false

		if not require_mouse_release and skill_interval_timer <= 0.0 and skill_charges > 0:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				start_skill_charge()

	elif current_skill_state == SkillState.STARTING or current_skill_state == SkillState.CHARGING:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			cancel_skill()

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
			var allowed_range := get_max_allowed_range()
			var prog: float = (skill_current_range - min_skill_range) / max(1.0, allowed_range - min_skill_range)
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
	# Hanya aktif di luar Special Skill Mode dan saat mode tempur (ada musuh)
	# =====================================================
	if current_skill_state == SkillState.INACTIVE:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if is_in_combat_mode() and not require_mouse_release and attack_timer <= 0.0 and not is_attacking:
				shoot_towards(get_global_mouse_position())

	# =====================================================
	# MOVEMENT (CLICK TO MOVE / HOLD TO MOVE - MOUSE KLIK KANAN)
	# =====================================================
	if hold_indicator_timer > 0.0:
		hold_indicator_timer -= delta

	if current_skill_state == SkillState.INACTIVE:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if not is_attacking and not is_skill_locked():
				var mouse_pos := get_global_mouse_position()
				target_position = mouse_pos
				is_moving = true
				has_pending_click_move = true
				click_move_stuck_timer = 0.0
				if hold_indicator_timer <= 0.0 and mouse_pos.distance_to(last_indicator_pos) > 28.0:
					hold_indicator_timer = 0.22
					last_indicator_pos = mouse_pos
					if CursorManager.has_method("spawn_ground_move_indicator"):
						CursorManager.spawn_ground_move_indicator(mouse_pos)

	var current_speed: float = SPRINT_SPEED
	var move_velocity := Vector2.ZERO

	if is_moving:
		var current_feet_pos := global_position + Vector2(0.0, FEET_OFFSET_Y)
		var dist := current_feet_pos.distance_to(target_position)
		if dist > 6.0:
			var direction := current_feet_pos.direction_to(target_position)
			last_movement_direction = direction
			if is_attacking or is_skill_locked():
				move_velocity = Vector2.ZERO
			else:
				move_velocity = direction * current_speed
				update_direction_animation(direction)
		else:
			is_moving = false
			has_pending_click_move = false
			click_move_stuck_timer = 0.0
			target_position = current_feet_pos
			if CursorManager.has_method("hide_ground_move_indicator"):
				CursorManager.hide_ground_move_indicator()
			if not is_attacking and not is_skill_locked() and animated_sprite.animation.begins_with("walk_"):
				play_idle_animation()
	else:
		if not is_attacking and not is_skill_locked() and animated_sprite.animation.begins_with("walk_"):
			play_idle_animation()

	velocity = move_velocity + knockback_velocity
	move_and_slide_with_separation()

	# [PERBAIKAN BUG 2]: Siklus debu terpusat untuk Leader
	handle_run_dust_cycle(delta)

	# Corner-Slide Assist & anti-stuck di dinding saat bergerak menggunakan klik mouse
	if is_moving and not is_attacking and not is_skill_locked() and get_slide_collision_count() > 0:
		if velocity.length() < current_speed * 0.4:
			var col := get_slide_collision(0)
			var n := col.get_normal()
			var tangent := Vector2(-n.y, n.x)
			var current_feet_pos := global_position + Vector2(0.0, FEET_OFFSET_Y)
			var dir_to_target := current_feet_pos.direction_to(target_position)
			if dir_to_target.dot(tangent) < 0.0:
				tangent = -tangent
			velocity = tangent * (current_speed * 0.8) + knockback_velocity
			move_and_slide()
		var is_colliding_with_enemy := false
		for c_idx in range(get_slide_collision_count()):
			var c := get_slide_collision(c_idx)
			var collider := c.get_collider()
			if collider and (collider.is_in_group("enemy") or (collider is CharacterBody2D and collider != self)):
				is_colliding_with_enemy = true
				break

		# Jangan batalkan jalan jika diserang atau bersenggolan dengan musuh; hanya batalkan jika mentok dinding statis > 0.5 detik
		if not is_colliding_with_enemy and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and get_real_velocity().length() < 10.0:
			click_move_stuck_timer += delta
			if click_move_stuck_timer >= 0.5:
				is_moving = false
				has_pending_click_move = false
				click_move_stuck_timer = 0.0
				if CursorManager.has_method("hide_ground_move_indicator"):
					CursorManager.hide_ground_move_indicator()
				if animated_sprite.animation.begins_with("walk_"):
					play_idle_animation()
		else:
			click_move_stuck_timer = 0.0


func process_pending_click_move(delta: float) -> bool:
	if not has_pending_click_move:
		return false

	if is_dead or is_movement_locked:
		has_pending_click_move = false
		return false

	if is_attacking or is_skill_locked():
		return false

	var current_feet_pos := global_position + Vector2(0.0, FEET_OFFSET_Y)
	var dist := current_feet_pos.distance_to(target_position)

	if dist <= 8.0:
		has_pending_click_move = false
		is_moving = false
		click_move_stuck_timer = 0.0
		velocity = knockback_velocity
		move_and_slide_with_separation()
		play_idle_animation()
		return false

	is_moving = true
	var move_dir := current_feet_pos.direction_to(target_position)
	last_movement_direction = move_dir
	var current_speed: float = SPRINT_SPEED
	var clamped_speed: float = minf(current_speed, dist / maxf(delta, 0.001))
	velocity = (move_dir * clamped_speed) + knockback_velocity
	move_and_slide_with_separation()
	update_direction_animation(move_dir)

	if get_slide_collision_count() > 0:
		if velocity.length() < current_speed * 0.4:
			var col := get_slide_collision(0)
			var n := col.get_normal()
			var tangent := Vector2(-n.y, n.x)
			if move_dir.dot(tangent) < 0.0:
				tangent = -tangent
			velocity = tangent * (current_speed * 0.8) + knockback_velocity
			move_and_slide()

		if get_real_velocity().length() < 10.0:
			click_move_stuck_timer += delta
			if click_move_stuck_timer >= 0.4:
				has_pending_click_move = false
				is_moving = false
				click_move_stuck_timer = 0.0
				play_idle_animation()
				return false
		else:
			click_move_stuck_timer = 0.0
	else:
		click_move_stuck_timer = 0.0

	return true


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

	if is_leader:
		_footstep_toggle = not _footstep_toggle
		if _footstep_toggle:
			play_sfx(SFX_FOOTSTEP, 5.0)


# =========================================================
# INPUT MOUSE
# =========================================================

func _unhandled_input(event: InputEvent) -> void:
	if not is_leader or is_dead:
		return

	if is_movement_locked:
		return

	# Pemicu Aktivasi / Deaktivasi Skill Mode (Tombol E / ui_skill)
	if is_skill_action_pressed(event):
		if is_in_combat_mode() and can_activate_skill():
			activate_skill_mode()
		elif current_skill_state == SkillState.READY:
			deactivate_skill_mode()
		return

	# Penanganan Input Selama Dalam Mode Skill
	if current_skill_state != SkillState.INACTIVE:
		if not is_in_combat_mode():
			reset_combat_skills()
			return
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

	# Penanganan Input Mode Biasa (Basic Attack & Pergerakan Klik Kanan)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_in_combat_mode() and not require_mouse_release and attack_timer <= 0.0 and not is_attacking:
					shoot_towards(get_global_mouse_position())
			else:
				require_mouse_release = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if not is_attacking and not is_skill_locked():
				target_position = get_global_mouse_position()
				is_moving = true
				has_pending_click_move = true
				click_move_stuck_timer = 0.0
				hold_indicator_timer = 0.22
				last_indicator_pos = target_position
				if CursorManager.has_method("spawn_ground_move_indicator"):
					CursorManager.spawn_ground_move_indicator(target_position)
				if get_viewport():
					get_viewport().set_input_as_handled()


# =========================================================
# FOLLOWER LOGIC (MENGIKUTI LEADER DI BELAKANG)
# =========================================================

func process_follower_logic(delta: float) -> void:
	if process_pending_click_move(delta):
		return

	if not leader_node or not is_instance_valid(leader_node) or ("is_dead" in leader_node and leader_node.is_dead):
		velocity = knockback_velocity
		move_and_slide_with_separation()
		if not is_attacking:
			play_idle_animation()
		return

	# 1. POSISI BERTEMPUR (COMBAT STATE ALA GUARDIAN TALES)
	if in_party_combat:
		process_follower_combat(delta)
		return

	# 2. POSISI MENGEKOR (EXPLORING STATE - SNAKE BREADCRUMBS)
	process_follower_exploring(delta)


func process_follower_exploring(delta: float) -> void:
	if animated_sprite.animation.begins_with("atk_") and not is_attacking:
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
			last_direction = get_cardinal_direction(target_facing)
		if not is_attacking:
			play_idle_animation()
	else:
		var aim_pos: Vector2 = target_pos
		if nav_info.get("is_corner_waypoint", false) and dist_to_target <= 20.0:
			aim_pos = follow_slot

		var move_dir := global_position.direction_to(aim_pos)
		var follow_speed := SPRINT_SPEED
		if dist_to_slot > 180.0:
			follow_speed = SPRINT_SPEED * 1.15

		# 1. Pencegahan Overshoot Jitter (Arrival Clamping)
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
	if is_attacking:
		velocity = knockback_velocity
		move_and_slide_with_separation()
		return
		
	# 1. Cari musuh hidup terdekat di dalam arena atau layar kamera
	var cam_rect := get_camera_world_rect()
	var enemies := get_tree().get_nodes_in_group("enemy")
	var target_enemy: Node2D = null
	var min_dist: float = INF
	
	var in_arena := is_in_arena()
	var arena_rect := get_active_arena_bounds()

	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			var is_candidate := false
			if in_arena and arena_rect.size != Vector2.ZERO:
				is_candidate = arena_rect.grow(40.0).has_point(e.global_position)
			if not is_candidate:
				is_candidate = cam_rect.has_point(e.global_position)
			if is_candidate:
				var d: float = global_position.distance_to(e.global_position)
				if d < min_dist:
					min_dist = d
					target_enemy = e
					
	if not target_enemy:
		is_flanking = false
		velocity = knockback_velocity
		is_moving = false
		move_and_slide_with_separation()
		if not is_attacking:
			play_idle_animation()
		return
		
	# 2. Uji koridor tembak dan jarak tempur ideal Archer (Di arena: jangkauan tak terbatas)
	var has_los := has_clear_projectile_los_to(target_enemy, 12.0)
	var dist_to_enemy := global_position.distance_to(target_enemy.global_position)
	var max_attack_dist: float = INF if in_arena else 540.0

	# 3. KONDISI TEMBAK (STAND & SHOOT JAUH): Jika koridor tembak bebas
	if has_los:
		is_flanking = false
		if dist_to_enemy > max_attack_dist:
			# Musuh masih terlalu jauh: mendekat ke jarak tembak dengan bias sayap kiri agar tidak berdempetan dengan Mage
			var to_enemy := target_enemy.global_position - global_position
			var left_wing := Vector2(-to_enemy.y, to_enemy.x).normalized() * 0.35
			var approach_dir := (to_enemy.normalized() + left_wing).normalized()
			velocity = (approach_dir * SPRINT_SPEED) + knockback_velocity
			is_moving = true
			move_and_slide_with_separation()
			last_movement_direction = approach_dir
			apply_smoothed_facing(approach_dir, delta)
			return
		else:
			# Berada dalam jarak tembak (bebas jarak sejauh apapun di arena): berdiri di tempat, bidik dan tembak
			velocity = knockback_velocity
			is_moving = false
			move_and_slide_with_separation()
			last_direction = get_cardinal_aim_direction((global_position + BASIC_ATTACK_ARROW_OFFSET).direction_to(target_enemy.global_position))
			if not is_attacking:
				play_idle_animation()
			ai_attack_timer -= delta
			if ai_attack_timer <= 0.0 and not is_attacking:
				ai_attack_timer = attack_cooldown
				shoot_towards(target_enemy.global_position)
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
	velocity = (move_dir * SPRINT_SPEED) + knockback_velocity
	is_moving = true
	move_and_slide_with_separation()
	last_movement_direction = move_dir
	apply_smoothed_facing(move_dir, delta)
func update_direction_animation(direction: Vector2) -> void:

	if direction == Vector2.ZERO:
		return


	# Simpan arah terakhir (prioritas horizontal untuk diagonal WD, WA, SA, SD)
	last_direction = get_cardinal_direction(direction)


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

func get_cardinal_aim_direction(dir: Vector2) -> Vector2:
	if dir == Vector2.ZERO:
		return Vector2.DOWN
	var angle := dir.angle()
	# Kanan (East): [-45 deg, 45 deg)
	if angle >= -PI * 0.25 and angle < PI * 0.25:
		return Vector2.RIGHT
	# Bawah (South): [45 deg, 135 deg)
	elif angle >= PI * 0.25 and angle < PI * 0.75:
		return Vector2.DOWN
	# Atas (North): [-135 deg, -45 deg)
	elif angle >= -PI * 0.75 and angle < -PI * 0.25:
		return Vector2.UP
	# Kiri (West): [-180, -135 deg) atau [135 deg, 180 deg]
	else:
		return Vector2.LEFT

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

func play_walk_animation() -> void:

	# Reset flip
	animated_sprite.flip_h = false


	# ATAS
	if last_direction == Vector2.UP:

		animated_sprite.play("walk_n")


	# BAWAH
	elif last_direction == Vector2.DOWN:

		animated_sprite.play("walk_s")


	# KIRI (dan diagonal kiri WA / SA)
	elif last_direction == Vector2.LEFT or last_direction == Vector2(-1, -1) or last_direction == Vector2(-1, 1):
		animated_sprite.play("walk_w")
		animated_sprite.flip_h = false

	# KANAN (dan diagonal kanan WD / SD)
	elif last_direction == Vector2.RIGHT or last_direction == Vector2(1, -1) or last_direction == Vector2(1, 1):
		animated_sprite.play("walk_e")
		animated_sprite.flip_h = false
	else:
		var cardinal := get_cardinal_direction(last_direction)
		if cardinal == Vector2.UP:
			animated_sprite.play("walk_n")
		elif cardinal == Vector2.DOWN:
			animated_sprite.play("walk_s")
		elif cardinal == Vector2.LEFT:
			animated_sprite.play("walk_w")
			animated_sprite.flip_h = false
		else:
			animated_sprite.play("walk_e")
			animated_sprite.flip_h = false


# =========================================================
# IDLE ANIMATION
# =========================================================

func play_idle_animation() -> void:

	# Reset flip
	animated_sprite.flip_h = false


	# ATAS
	if last_direction == Vector2.UP:

		animated_sprite.play("idle_n")


	# BAWAH
	elif last_direction == Vector2.DOWN:

		animated_sprite.play("idle_s")


	# KIRI (dan diagonal kiri WA / SA)
	elif last_direction == Vector2.LEFT or last_direction == Vector2(-1, -1) or last_direction == Vector2(-1, 1):
		animated_sprite.play("idle_w")
		animated_sprite.flip_h = false

	# KANAN (dan diagonal kanan WD / SD)
	elif last_direction == Vector2.RIGHT or last_direction == Vector2(1, -1) or last_direction == Vector2(1, 1):
		animated_sprite.play("idle_e")
		animated_sprite.flip_h = false
	else:
		var cardinal := get_cardinal_direction(last_direction)
		if cardinal == Vector2.UP:
			animated_sprite.play("idle_n")
		elif cardinal == Vector2.DOWN:
			animated_sprite.play("idle_s")
		elif cardinal == Vector2.LEFT:
			animated_sprite.play("idle_w")
			animated_sprite.flip_h = false
		else:
			animated_sprite.play("idle_e")
			animated_sprite.flip_h = false


# =========================================================
# ATTACK ANIMATION
# =========================================================

func play_attack_animation() -> void:
	# Reset flip
	animated_sprite.flip_h = false

	if last_direction == Vector2.UP:
		animated_sprite.play("atk_n")
	elif last_direction == Vector2.DOWN:
		animated_sprite.play("atk_s")
	elif last_direction == Vector2.LEFT:
		animated_sprite.play("atk_w")
	elif last_direction == Vector2.RIGHT:
		animated_sprite.play("atk_e")
	else:
		animated_sprite.play("atk_s")


# =========================================================
# COMBAT & SHOOT LOGIC (MANUAL KLIK KIRI)
# =========================================================

func get_bow_offset(dir: Vector2 = Vector2.ZERO) -> Vector2:
	var use_dir := dir if dir != Vector2.ZERO else last_direction
	var d_cardinal := get_cardinal_aim_direction(use_dir)
	var d_str := "s"
	if d_cardinal == Vector2.UP:
		d_str = "n"
	elif d_cardinal == Vector2.DOWN:
		d_str = "s"
	elif d_cardinal == Vector2.LEFT:
		d_str = "w"
	elif d_cardinal == Vector2.RIGHT:
		d_str = "e"
	return BOW_DIRECTIONAL_OFFSETS.get(d_str, BASIC_ATTACK_ARROW_OFFSET)


func get_arrow_spawn_position() -> Vector2:
	# Titik visual busur panah archer di ruang dunia (diselaraskan pas tepat di anak panah yang nempel di busur)
	return global_position + get_bow_offset(last_direction)



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
		return false
		
	# Waypoint 1: 40 px di luar ujung rintangan, tetap di sisi karakter (-to_target * 24.0)
	flank_wp1 = hit_pos + (chosen_dir * (chosen_dist + 40.0)) - (to_target * 24.0)
	# Waypoint 2: Melangkah menyeberang ke area seberang jika jalur seberang bersih dari rintangan
	var candidate_wp2: Vector2 = flank_wp1 + (to_target * 65.0)
	var ray_wp2 := PhysicsRayQueryParameters2D.create(flank_wp1, candidate_wp2)
	ray_wp2.collision_mask = 1
	if space_state.intersect_ray(ray_wp2).is_empty():
		flank_wp2 = candidate_wp2
	else:
		flank_wp2 = flank_wp1
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
	return is_in_combat_mode()

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

func shoot_towards(target_pos: Vector2) -> void:
	if attack_timer > 0.0 or is_attacking or is_dead:
		return

	# Hanya dapat menembak saat mode tempur (ada musuh) tanpa batasan jarak
	if is_leader and not is_in_combat_mode():
		return

	# Hentikan pergerakan
	is_moving = false
	has_pending_click_move = false
	click_move_stuck_timer = 0.0
	velocity = knockback_velocity

	# Simpan target posisi klik kursor
	attack_target_pos = target_pos

	# Tentukan arah hadap tembakan saat klik (dihitung dari titik visual busur panah karakter)
	var bow_pos := global_position + BASIC_ATTACK_ARROW_OFFSET
	var dir := bow_pos.direction_to(target_pos)

	if dir == Vector2.ZERO:
		dir = last_direction

	# Simpan arah tembakan awal
	attack_direction = dir

	# Hadap ke arah tembakan secara alami (4 kuadran: UP, DOWN, LEFT, RIGHT)
	last_direction = get_cardinal_aim_direction(dir)

	attack_token += 1
	var token := attack_token

	# Mulai animasi attack
	is_attacking = true
	play_attack_animation()

	attack_timer = attack_cooldown

	reset_attack_state(token)

func shoot_at(target: Node2D) -> void:
	if is_instance_valid(target):
		shoot_towards(target.global_position)


func get_dynamic_projectile_speed() -> float:
	if is_leader:
		return controlled_projectile_speed

	# Kecepatan panah Archer dibuat sama baik dikendalikan maupun tidak dikendalikan (580.0 px/s)
	return controlled_projectile_speed * follower_projectile_ratio


func reset_attack_state(token: int) -> void:
	# Tunggu sampai sekitar frame 3-4 dari animasi attack
	await get_tree().create_timer(0.22).timeout

	# Jika terinterupsi saat windup (terkena damage/knockback atau mati), batalkan spawn proyektil
	if is_dead or attack_token != token or not is_attacking:
		return

	# Arrow keluar saat Archer melepas busur tepat dari posisi tengah yang presisi
	var spawn_pos := get_arrow_spawn_position()
	var bow_pos := global_position + BASIC_ATTACK_ARROW_OFFSET
	var aim_forward := bow_pos.direction_to(attack_target_pos)
	if aim_forward == Vector2.ZERO:
		aim_forward = attack_direction if attack_direction != Vector2.ZERO else last_direction

	# Hitung lintasan akurat langsung dari titik spawn busur menuju koordinat klik kursor
	var to_target: Vector2 = attack_target_pos - spawn_pos
	var shoot_dir: Vector2 = aim_forward
	if to_target.dot(aim_forward) > 10.0:
		shoot_dir = to_target.normalized()
	else:
		var far_target := bow_pos + aim_forward * maxf(bow_pos.distance_to(attack_target_pos), 300.0)
		shoot_dir = spawn_pos.direction_to(far_target)

	attack_direction = shoot_dir

	var arrow = ARROW_SCENE.instantiate()
	arrow.global_position = spawn_pos
	arrow.direction = shoot_dir
	arrow.rotation = shoot_dir.angle()
	arrow.shooter_node = self
	arrow.speed = get_dynamic_projectile_speed()
	arrow.damage = attack_damage
	if last_direction == Vector2.UP or animated_sprite.animation == "atk_n":
		arrow.get_node("Sprite2D").z_index = 3
	else:
		arrow.get_node("Sprite2D").z_index = 5
	get_parent().add_child(arrow)
	play_sfx(SFX_ARCHER_BOW_SHOOT, -2.0)

	# Spawn indicator trace arrow tepat di posisi spawn panah (dihilangkan jika menghadap North)
	if last_direction != Vector2.UP and animated_sprite.animation != "atk_n":
		var trace = TRACE_SCENE.instantiate()
		trace.global_position = spawn_pos
		trace.rotation = shoot_dir.angle()
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
		var current_feet_pos := global_position + Vector2(0.0, FEET_OFFSET_Y)
		var move_dir := current_feet_pos.direction_to(target_position) if is_leader else (velocity.normalized() if velocity != Vector2.ZERO else last_movement_direction)
		update_direction_animation(move_dir)
	else:
		play_idle_animation()
# =========================================================
# MENERIMA DAMAGE DARI MUSUH & KNOCKBACK
# =========================================================

func take_damage(amount: int, _source_position = null) -> void:
	if is_dead or invulnerability_timer > 0.0:
		return
	invulnerability_timer = invulnerability_duration

	# Shield Guard: menahan damage dengan Shield Points (+300)
	if is_shield_active:
		modulate = Color(1.8, 1.8, 2.4)
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)
		apply_camera_shake(3.0)
		play_sfx(SFX_SHIELD_BLOCK, 0.0)
		if shield_points > 0:
			if amount <= shield_points:
				shield_points -= amount
				print(name, " menahan serangan dengan perisai! Sisa Shield: ", shield_points)
				return
			else:
				var absorbed: int = shield_points
				shield_points = 0
				amount -= absorbed
				deactivate_shield()
				print(name, " perisai pecah! Menerima sisa damage: ", amount)
		else:
			return

	current_health -= amount
	play_sfx(SFX_HURT, -4.0)
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

func die() -> void:
	attack_token += 1
	deactivate_shield()
	if is_dead:
		return

	# Batalkan mode skill dan bersihkan indikator bila archer gugur
	if current_skill_state != SkillState.INACTIVE:
		deactivate_skill_mode()

	is_dead = true
	play_sfx(SFX_DEATH, -2.0)
	is_moving = false
	has_pending_click_move = false
	click_move_stuck_timer = 0.0
	if is_leader and CursorManager.has_method("hide_ground_move_indicator"):
		CursorManager.hide_ground_move_indicator()
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
	var cam: Camera2D = get_camera()
	if cam:
		cam.offset = Vector2.ZERO
	play_idle_animation()
	print("Archer Kalah! Menunggu respawn...")

	# 1. Matikan tabrakan dan keluarkan sementara dari grup player
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	remove_from_group("player")

	# 2. Munculkan arwah terbang seketika di posisi tubuh hero gugur
	spawn_death_ghost()

	# 3. Efek visual kekalahan: karakter memudar (fade-out)
	var death_tween := create_tween()
	if death_tween:
		death_tween.tween_property(self, "modulate", Color(0.9, 0.25, 0.25, 0.0), 0.5)

	# 4. Auto-switch jika Leader aktif gugur: segera reorganisasi roster dan naikkan karakter hidup berikutnya
	var was_leader := is_leader
	if was_leader:
		var game_node = get_tree().current_scene if is_inside_tree() else null
		if not game_node or not game_node.has_method("rearrange_dead_members_to_back"):
			if get_parent() and get_parent().has_method("rearrange_dead_members_to_back"):
				game_node = get_parent()
		if game_node and game_node.has_method("rearrange_dead_members_to_back"):
			game_node.rearrange_dead_members_to_back()
		elif game_node and game_node.has_method("switch_to_next_character"):
			game_node.switch_to_next_character(true)

	if death_tween:
		await death_tween.finished

	visible = false


func spawn_death_ghost() -> void:
	var tree := get_tree()
	var spawn_parent: Node = null
	if tree and tree.current_scene:
		spawn_parent = tree.current_scene
	elif get_parent():
		spawn_parent = get_parent()

	if not spawn_parent:
		return

	var ghost = GHOST_SCENE.instantiate()
	ghost.global_position = global_position + Vector2(0.0, -15.0)
	spawn_parent.add_child(ghost)


func respawn() -> void:
	deactivate_shield()
	is_flanking = false
	flank_wp1 = Vector2.ZERO
	flank_wp2 = Vector2.ZERO
	flank_stage = 1
	flank_timeout = 0.0
	facing_debounce_timer = 0.0
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
	is_moving = false
	if is_leader and CursorManager.has_method("hide_ground_move_indicator"):
		CursorManager.hide_ground_move_indicator()
	is_attacking = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	invulnerability_timer = 1.5

	# Reset pergerakan kamera agar langsung fokus tanpa lag panning
	var cam: Camera2D = get_camera()
	if cam:
		cam.reset_smoothing()

	# Nyalakan kembali tabrakan dan masukkan kembali ke grup player
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", false)
	add_to_group("player")

	modulate = Color(1.0, 1.0, 1.0, 0.0)
	visible = true
	var respawn_tween = create_tween()
	respawn_tween.tween_property(self, "modulate:a", 1.0, 0.4)
	is_dead = false
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

	print("Archer berhasil respawn di titik awal! HP penuh: ", current_health)


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func apply_knockback(force: Vector2) -> void:
	if force == Vector2.ZERO:
		return
	knockback_velocity = force
	if not has_pending_click_move:
		is_moving = false


# =========================================================
# ARCHER SPECIAL SKILL MODE METHODS
# =========================================================

func is_skill_action_pressed(event: InputEvent) -> bool:
	if InputMap.has_action("use_skill") and event.is_action_pressed("use_skill"):
		return true
	if InputMap.has_action("ui_skill") and event.is_action_pressed("ui_skill"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			return true
	return false


func can_activate_skill() -> bool:
	return (not is_dead and 
			skill_cooldown_timer <= 0.0 and 
			current_skill_state == SkillState.INACTIVE and
			is_in_combat_mode())


func is_skill_locked() -> bool:
	return (current_skill_state == SkillState.STARTING or 
			current_skill_state == SkillState.CHARGING or 
			current_skill_state == SkillState.RELEASING)


func activate_skill_mode() -> void:
	if not is_in_combat_mode():
		return

	# Jika sedang melancarkan basic attack, batalkan seketika agar skill langsung siap dipakai
	if is_attacking:
		attack_token += 1
		is_attacking = false
		attack_stuck_timer = 0.0
		if not is_moving:
			play_idle_animation()

	current_skill_state = SkillState.READY
	skill_charges = skill_max_charges
	skill_mode_timer = skill_mode_duration
	skill_interval_timer = 0.0
	skill_release_queued = false

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		require_mouse_release = true

	# Buat/instansiasi node indikator namun sembunyikan sampai klik kiri ditekan
	if skill_indicator_instance == null or not is_instance_valid(skill_indicator_instance):
		skill_indicator_instance = SKILL_INDICATOR_SCENE.instantiate()
		skill_indicator_instance.visible = false
		get_parent().add_child(skill_indicator_instance)
	else:
		skill_indicator_instance.visible = false

	print("Special Skill Mode Aktif! Kuota tembakan: ", skill_charges, " | Durasi: ", skill_mode_duration, " detik")
	play_sfx(SFX_ARCHER_SKILL_MODE_ACTIVATE, -1.0)


func deactivate_skill_mode() -> void:
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


func start_skill_charge() -> void:
	if not is_in_combat_mode():
		reset_combat_skills()
		return
	current_skill_state = SkillState.STARTING
	skill_release_queued = false

	# Karakter langsung berhenti dan terkunci
	is_moving = false
	has_pending_click_move = false
	click_move_stuck_timer = 0.0
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
	play_sfx(SFX_ARCHER_SKILL_CHARGE, -2.0)


func execute_skill_release() -> void:
	if not is_in_combat_mode():
		reset_combat_skills()
		return
	if current_skill_state == SkillState.RELEASING or is_dead:
		return

	current_skill_state = SkillState.RELEASING
	require_mouse_release = true

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
	play_sfx(SFX_ARCHER_SKILL_RELEASE, 0.0)


func on_skill_release_finished() -> void:
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


func _on_animated_sprite_animation_finished() -> void:
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
	if is_in_arena():
		return 2400.0 # Mampu menjangkau seluruh sudut arena terjauh
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
			shield_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST as CanvasItem.TextureFilter
			shield_sprite.z_index = 6
			shield_sprite.position = SHIELD_CENTER_OFFSET
			shield_sprite.scale = Vector2(0.85, 0.85)
			shield_sprite.visible = false
			add_child(shield_sprite)
	if shield_sprite:
		shield_sprite.visible = false
		shield_sprite.modulate.a = 0.0


func grant_shield(duration: float, points: int = 300) -> void:
	if is_dead:
		return
	is_shield_active = true
	shield_timer = duration
	shield_points = points

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

	print(name, " menerima pelindung Shield Guard (+", points, " Shield Point) selama ", duration, " detik!")


func deactivate_shield() -> void:
	if not is_shield_active and not (shield_sprite and shield_sprite.visible):
		return
	is_shield_active = false
	shield_timer = 0.0
	shield_points = 0

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


func get_shield_center_offset() -> Vector2:
	var d_str: String = ""
	if animated_sprite and animated_sprite.animation != "":
		var anim_name: String = animated_sprite.animation
		for suffix in ["_n", "_s", "_e", "_w"]:
			if anim_name.ends_with(suffix):
				d_str = suffix.substr(1)
				break
	if d_str == "":
		d_str = get_4_direction_str(last_direction)
	return SHIELD_DIRECTIONAL_OFFSETS.get(d_str, SHIELD_CENTER_OFFSET)


func update_shield_visual() -> void:
	if not shield_sprite:
		return
	# Pelindung perisai tegak dan presisi di tengah tubuh karakter Archer sesuai arah pandang
	shield_sprite.rotation = 0.0
	var float_y: float = sin(Time.get_ticks_msec() * 0.007) * 0.8
	var center_offset: Vector2 = get_shield_center_offset()
	shield_sprite.position = center_offset + Vector2(0.0, float_y)
	var pulse: float = 0.85 + sin(Time.get_ticks_msec() * 0.009) * 0.03
	shield_sprite.scale = Vector2(pulse, pulse)


func get_separation_vector() -> Vector2:
	if not is_inside_tree():
		return Vector2.ZERO
	var separation := Vector2.ZERO
	var min_sep_dist: float = 55.0 # Jarak personal aman antar karakter
	var diff: Vector2 = Vector2.ZERO
	var d: float = 0.0
	var push_dir: Vector2 = Vector2.ZERO

	# 1. Pisahkan diri dari musuh terdekat jika saling menempel
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e != self and is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			diff = global_position - e.global_position
			d = diff.length()
			if d < min_sep_dist:
				push_dir = diff.normalized() if d > 0.5 else Vector2(1.0, 0.0)
				separation += push_dir * (min_sep_dist - d)

	# 2. Pisahkan diri dari rekan tim (jarak renggang saat mode tempur agar tidak berdempetan)
	var min_teammate_dist: float = 75.0 if in_party_combat else 38.0
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if p != self and is_instance_valid(p) and p.visible and not ("is_dead" in p and p.is_dead):
			diff = global_position - p.global_position
			d = diff.length()
			if d < min_teammate_dist:
				push_dir = diff.normalized() if d > 0.5 else Vector2(-1.0, 0.0)
				separation += push_dir * ((min_teammate_dist - d) * 0.8)

	return separation


func move_and_slide_with_separation() -> void:
	if not is_inside_tree() or not is_physics_processing():
		return
	var sep := get_separation_vector()
	if sep != Vector2.ZERO:
		velocity += sep.limit_length(35.0) * 4.0
	move_and_slide()
