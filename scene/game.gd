extends Node2D

# =========================================================
# GAME CONTROLLER & 3-CHARACTER PARTY MANAGER
# =========================================================

@onready var camera: Camera2D = $Camera2D

var party_members: Array[CharacterBody2D] = []
var active_leader_index: int = 0

# State Tempur Party ala Guardian Tales
enum PartyCombatState { EXPLORING, COMBAT }
var current_combat_state: PartyCombatState = PartyCombatState.EXPLORING
var active_combat_targets: Array[Node2D] = []
var aggro_check_timer: float = 0.0
const AGGRO_CHECK_INTERVAL: float = 0.15
var combat_winddown_timer: float = 0.0
const COMBAT_WINDDOWN_DELAY: float = 0.4

# Command Party Input (Tombol 'C' untuk Follow & 'V' untuk Attack)
enum PartyCommand { ATTACK, FOLLOW }
var current_party_command: PartyCommand = PartyCommand.ATTACK

# Pengaturan Camera Shake
var shake_intensity: float = 0.0
var shake_decay: float = 35.0


func _ready() -> void:
	# 1. Daftarkan 3 anggota party dari scene
	# Urutan: Knight_1, Mage_1, Archer_1
	var names: Array[String] = ["Knight_1", "Mage_1", "Archer_1"]
	for n in names:
		var node := get_node_or_null(n) as CharacterBody2D
		if node:
			party_members.append(node)

	# Fallback pencarian fleksibel jika node bernama Player_Knight / Player_Mage / Player_Archer
	if party_members.is_empty():
		for child in get_children():
			if child.is_in_group("player") and child is CharacterBody2D:
				party_members.append(child)

	# 2. Nonaktifkan tabrakan fisik antar-seluruh anggota party (3 karakter)
	for i in range(party_members.size()):
		for j in range(i + 1, party_members.size()):
			party_members[i].add_collision_exception_with(party_members[j])
			party_members[j].add_collision_exception_with(party_members[i])

	# 3. Nonaktifkan tabrakan fisik antara anggota party dan musuh agar tidak saling menyeret / mengunci
	setup_party_enemy_collision_exceptions.call_deferred()

	# 4. Tentukan karakter awal sebagai Leader (Knight_1 = index 0)
	set_active_leader(0)

	# 5. Inisialisasi kamera dan batasan map
	setup_camera_and_boundaries.call_deferred()


func setup_party_enemy_collision_exceptions() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for p in party_members:
		if is_instance_valid(p) and p is CollisionObject2D:
			for e in enemies:
				if is_instance_valid(e) and e is CollisionObject2D:
					p.add_collision_exception_with(e)
					e.add_collision_exception_with(p)


func _unhandled_input(event: InputEvent) -> void:
	# Tombol pintasan pergantian karakter: Tab (siklis) atau angka 1, 2, 3
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			switch_to_next_character()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1:
			switch_to_character(0)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			switch_to_character(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3:
			switch_to_character(2)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C:
			set_party_command(PartyCommand.FOLLOW)
			if get_viewport():
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_V:
			set_party_command(PartyCommand.ATTACK)
			if get_viewport():
				get_viewport().set_input_as_handled()


func set_party_command(cmd: PartyCommand) -> void:
	current_party_command = cmd
	for member in party_members:
		if is_instance_valid(member) and member.has_method("set_party_command"):
			member.set_party_command(cmd)

	if cmd == PartyCommand.ATTACK:
		if not active_combat_targets.is_empty():
			current_combat_state = PartyCombatState.COMBAT
			notify_party_combat_state(true)
	elif cmd == PartyCommand.FOLLOW:
		notify_party_combat_state(false)

	print("Party Command -> ", "FOLLOW (Tombol C)" if cmd == PartyCommand.FOLLOW else "ATTACK (Tombol V)")

func switch_to_next_character() -> void:
	if party_members.is_empty():
		return
	var next_idx := (active_leader_index + 1) % party_members.size()
	switch_to_character(next_idx)


func switch_to_character(idx: int) -> void:
	if idx < 0 or idx >= party_members.size() or idx == active_leader_index:
		return
	set_active_leader(idx)


func set_active_leader(idx: int) -> void:
	if idx < 0 or idx >= party_members.size():
		return

	active_leader_index = idx
	var leader := party_members[active_leader_index]

	# Berikan status Leader langsung ke karakter terpilih
	breadcrumbs.clear()
	leader.set_as_leader(true, null, 0)

	# Berikan referensi langsung ke Leader dan nomor urutan slot tetap (1, 2, 3)
	var slot_order: int = 1
	for step in range(1, party_members.size()):
		var follower_idx := (active_leader_index + step) % party_members.size()
		var follower := party_members[follower_idx]
		follower.set_as_leader(false, leader, slot_order)
		if follower.has_method("set_party_command"):
			follower.set_party_command(current_party_command)
		slot_order += 1

	# Sinkronkan state combat jika pergantian karakter terjadi saat bertempur
	if current_combat_state == PartyCombatState.COMBAT:
		notify_party_combat_state(true)
	else:
		notify_party_combat_state(false)

	print("Party Switch -> Leader aktif: [", active_leader_index + 1, "] ", leader.name)


func get_active_leader() -> CharacterBody2D:
	if not party_members.is_empty() and active_leader_index >= 0 and active_leader_index < party_members.size():
		return party_members[active_leader_index]
	return null


func get_controlled_projectile_speed() -> float:
	var leader := get_active_leader()
	if leader and is_instance_valid(leader) and leader.has_method("get_controlled_projectile_speed"):
		return leader.get_controlled_projectile_speed()
	return 580.0


func _process(delta: float) -> void:
	handle_camera_shake(delta)
	update_camera_target()
	handle_viewport_aggro_detection(delta)
	update_breadcrumbs()


# =========================================================
# CAMERA VIEWPORT AGGRO & COMBAT STATE ALA GUARDIAN TALES
# =========================================================

func get_camera_world_rect() -> Rect2:
	if not camera:
		return Rect2()
	var vp_size: Vector2 = get_viewport_rect().size / camera.zoom
	var center: Vector2 = camera.get_screen_center_position()
	# Buffer 50px agar musuh di tepian layar langsung terdeteksi
	return Rect2(center - vp_size * 0.5, vp_size).grow(50.0)


func handle_viewport_aggro_detection(delta: float) -> void:
	aggro_check_timer -= delta
	if aggro_check_timer > 0.0:
		return
	aggro_check_timer = AGGRO_CHECK_INTERVAL

	var cam_rect := get_camera_world_rect()
	var enemies := get_tree().get_nodes_in_group("enemy")
	var found_enemies: Array[Node2D] = []

	for enemy in enemies:
		if is_instance_valid(enemy) and not ("is_dead" in enemy and enemy.is_dead):
			if cam_rect.has_point(enemy.global_position):
				found_enemies.append(enemy)

	active_combat_targets = found_enemies
	var should_be_combat := not found_enemies.is_empty()

	if should_be_combat:
		combat_winddown_timer = COMBAT_WINDDOWN_DELAY
		if current_party_command == PartyCommand.FOLLOW:
			# Saat pemain mengaktifkan PartyCommand.FOLLOW, jangan paksa anggota party masuk mode tempur
			pass
		elif current_combat_state == PartyCombatState.EXPLORING:
			current_combat_state = PartyCombatState.COMBAT
			notify_party_combat_state(true)
		else:
			# Pastikan seluruh anggota party yang valid dan hidup selalu dipastikan bernilai in_party_combat = true
			# jika tidak dalam mode FOLLOW
			for member in party_members:
				if is_instance_valid(member) and not ("is_dead" in member and member.is_dead):
					if "in_party_combat" in member and not member.in_party_combat:
						if member.has_method("set_party_combat_mode"):
							member.set_party_combat_mode(true)
						else:
							member.in_party_combat = true

		# [BUG 2 FIX]: Alert seluruh musuh di dalam viewport ke mode tempur
		for enemy in found_enemies:
			if is_instance_valid(enemy) and enemy.has_method("alert_to_combat"):
				enemy.alert_to_combat()
	else:
		# Combat Clear: Beri jeda 0.4 detik (wind-down) sebelum kembali ke mode EXPLORING
		if current_combat_state == PartyCombatState.COMBAT:
			combat_winddown_timer -= AGGRO_CHECK_INTERVAL
			if combat_winddown_timer <= 0.0:
				combat_winddown_timer = 0.0
				current_combat_state = PartyCombatState.EXPLORING
				notify_party_combat_state(false)


func notify_party_combat_state(in_combat: bool) -> void:
	for member in party_members:
		if is_instance_valid(member) and member.has_method("set_party_combat_mode"):
			member.set_party_combat_mode(in_combat)


func update_camera_target() -> void:
	if not camera or party_members.is_empty():
		return
	var leader := party_members[active_leader_index]
	if not is_instance_valid(leader):
		return

	# Fokus 100% pada posisi Leader dengan sedikit offset vertikal ke bawah (+45 px)
	var camera_target: Vector2 = leader.global_position + Vector2(0.0, 45.0)
	camera.global_position = camera_target

func apply_camera_shake(intensity: float = 8.0) -> void:
	shake_intensity = max(shake_intensity, intensity)


func handle_camera_shake(delta: float) -> void:
	if not camera:
		return

	if shake_intensity > 0.0:
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta)
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO


func setup_camera_and_boundaries() -> void:
	if not camera:
		return

	camera.zoom = Vector2(0.65, 0.65)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0

	var ground := get_node_or_null("map_region1/Ground") as TileMapLayer
	if not ground:
		ground = find_child("Ground", true, false) as TileMapLayer

	if not ground:
		return

	var rect: Rect2i = ground.get_used_rect()
	if rect.size == Vector2i.ZERO:
		return

	var map_min: Vector2 = ground.to_global(Vector2(rect.position.x * 16.0, rect.position.y * 16.0))
	var map_max: Vector2 = ground.to_global(Vector2((rect.position.x + rect.size.x) * 16.0, (rect.position.y + rect.size.y) * 16.0))

	camera.limit_left = int(map_min.x)
	camera.limit_top = int(map_min.y)
	camera.limit_right = int(map_max.x)
	camera.limit_bottom = int(map_max.y)

	if not has_node("WorldBorders"):
		var borders := StaticBody2D.new()
		borders.name = "WorldBorders"
		borders.collision_layer = 1
		borders.collision_mask = 0

		var thickness := 80.0
		var width := map_max.x - map_min.x
		var height := map_max.y - map_min.y

		_create_wall_shape(borders, Vector2(map_min.x + width / 2.0, map_min.y - thickness / 2.0), Vector2(width + thickness * 2.0, thickness))
		_create_wall_shape(borders, Vector2(map_min.x + width / 2.0, map_max.y + thickness / 2.0), Vector2(width + thickness * 2.0, thickness))
		_create_wall_shape(borders, Vector2(map_min.x - thickness / 2.0, map_min.y + height / 2.0), Vector2(thickness, height + thickness * 2.0))
		_create_wall_shape(borders, Vector2(map_max.x + thickness / 2.0, map_min.y + height / 2.0), Vector2(thickness, height + thickness * 2.0))

		call_deferred("add_child", borders)


func _create_wall_shape(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	var col := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	col.shape = rect_shape
	col.position = pos
	parent.add_child(col)


# =========================================================
# BREADCRUMB HISTORY & SNAKE FORMATION (CASCADE SWAP 180°)
# =========================================================

var breadcrumbs: Array[Dictionary] = []
const BREADCRUMB_INTERVAL: float = 8.0
const QUEUE_DIST: float = 85.0

func update_breadcrumbs() -> void:
	if party_members.is_empty() or active_leader_index >= party_members.size():
		return
	var leader := party_members[active_leader_index]
	if not is_instance_valid(leader) or ("is_dead" in leader and leader.is_dead):
		return

	var leader_pos: Vector2 = leader.global_position
	var leader_dir: Vector2 = Vector2.DOWN
	if "last_movement_direction" in leader and leader.last_movement_direction != Vector2.ZERO:
		leader_dir = leader.last_movement_direction
	elif "last_direction" in leader and leader.last_direction != Vector2.ZERO:
		leader_dir = leader.last_direction

	if breadcrumbs.is_empty():
		breadcrumbs.append({"pos": leader_pos, "dir": leader_dir})
		for i in range(1, 45):
			breadcrumbs.append({
				"pos": leader_pos - leader_dir * (i * BREADCRUMB_INTERVAL),
				"dir": leader_dir
			})
		return

	var head_pos: Vector2 = breadcrumbs[0]["pos"]
	var dist_from_head := leader_pos.distance_to(head_pos)

	if dist_from_head >= BREADCRUMB_INTERVAL:
		var step_dir := (leader_pos - head_pos).normalized()
		var last_trail_dir := leader_dir
		if breadcrumbs.size() >= 2:
			last_trail_dir = (breadcrumbs[0]["pos"] - breadcrumbs[1]["pos"]).normalized()

		# Deteksi putar balik 180° (Cascade Swap)
		if last_trail_dir != Vector2.ZERO and step_dir.dot(last_trail_dir) < -0.7:
			# Leader berbalik 180° melewati barisannya sendiri!
			# Balikkan jalur antrean ke belakang titik belok secara estafet
			var turn_pt := head_pos
			breadcrumbs.clear()
			breadcrumbs.append({"pos": leader_pos, "dir": step_dir})
			breadcrumbs.append({"pos": turn_pt, "dir": step_dir})
			for k in range(1, 50):
				breadcrumbs.append({
					"pos": turn_pt - step_dir * (k * BREADCRUMB_INTERVAL),
					"dir": step_dir
				})
		else:
			# Gerakan biasa atau belok 90° (Snake Corner Turn)
			breadcrumbs.push_front({"pos": leader_pos, "dir": step_dir})
			if breadcrumbs.size() > 65:
				breadcrumbs.pop_back()


func get_follower_trail_slot(slot_index: int) -> Dictionary:
	if party_members.is_empty() or active_leader_index >= party_members.size():
		return {}
	var leader := party_members[active_leader_index]
	if not is_instance_valid(leader):
		return {}

	var target_dist: float = slot_index * QUEUE_DIST
	if breadcrumbs.is_empty():
		return {"pos": leader.global_position - Vector2.DOWN * target_dist, "dir": Vector2.DOWN}

	var accumulated_dist: float = 0.0
	var prev_pt: Vector2 = leader.global_position

	for i in range(breadcrumbs.size()):
		var cur_pt: Vector2 = breadcrumbs[i]["pos"]
		var seg_len: float = prev_pt.distance_to(cur_pt)
		if accumulated_dist + seg_len >= target_dist:
			var remain := target_dist - accumulated_dist
			var t := remain / maxf(seg_len, 0.001)
			var interp_pos := prev_pt.lerp(cur_pt, t)
			var seg_dir: Vector2 = cur_pt.direction_to(prev_pt)
			if seg_dir == Vector2.ZERO:
				seg_dir = breadcrumbs[i]["dir"]
			return {"pos": interp_pos, "dir": seg_dir}
		accumulated_dist += seg_len
		prev_pt = cur_pt

	var last_bc: Dictionary = breadcrumbs.back()
	var fallback_dir: Vector2 = last_bc.get("dir", Vector2.DOWN)
	var needed: float = target_dist - accumulated_dist
	return {
		"pos": prev_pt - fallback_dir * needed,
		"dir": fallback_dir
	}
