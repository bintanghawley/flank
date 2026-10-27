extends Node2D

# =========================================================
# GAME CONTROLLER & 4-CHARACTER PARTY MANAGER
# =========================================================

@onready var camera: Camera2D = $Camera2D

var party_members: Array[CharacterBody2D] = []
var active_leader_index: int = 0

# Pengaturan Camera Shake
var shake_intensity: float = 0.0
var shake_decay: float = 35.0


func _ready():
	# 1. Daftarkan 4 anggota party dari scene
	# Urutan: Archer_1, Mage_1, Archer_2, Mage_2
	var names := ["Archer_1", "Mage_1", "Archer_2", "Mage_2"]
	for n in names:
		var node = get_node_or_null(n) as CharacterBody2D
		if node:
			party_members.append(node)

	# Fallback pencarian fleksibel jika node bernama Player_Archer / Player_Mage
	if party_members.is_empty():
		for child in get_children():
			if child.is_in_group("player") and child is CharacterBody2D:
				party_members.append(child)

	# 2. Nonaktifkan tabrakan fisik antar-seluruh anggota party (4 karakter)
	for i in range(party_members.size()):
		for j in range(i + 1, party_members.size()):
			party_members[i].add_collision_exception_with(party_members[j])
			party_members[j].add_collision_exception_with(party_members[i])

	# 3. Tentukan karakter awal sebagai Leader (Archer_1 = index 0)
	set_active_leader(0)

	# 4. Inisialisasi kamera dan batasan map
	setup_camera_and_boundaries.call_deferred()


func _unhandled_input(event: InputEvent):
	# Tombol pintasan pergantian karakter: Tab (siklis) atau angka 1, 2, 3, 4
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
		elif event.keycode == KEY_4:
			switch_to_character(3)
			get_viewport().set_input_as_handled()


func switch_to_next_character():
	if party_members.is_empty():
		return
	var next_idx := (active_leader_index + 1) % party_members.size()
	switch_to_character(next_idx)


func switch_to_character(idx: int):
	if idx < 0 or idx >= party_members.size() or idx == active_leader_index:
		return
	set_active_leader(idx)


func set_active_leader(idx: int):
	if idx < 0 or idx >= party_members.size():
		return

	active_leader_index = idx
	var leader := party_members[active_leader_index]

	# Susun antrean berantai (Chain Queue) untuk 4 karakter:
	# Karakter Leader di depan.
	# Follower 1 mengikuti Leader.
	# Follower 2 mengikuti Follower 1.
	# Follower 3 mengikuti Follower 2.
	leader.set_as_leader(true, null, null)

	var prev_member: CharacterBody2D = leader
	for step in range(1, party_members.size()):
		var follower_idx := (active_leader_index + step) % party_members.size()
		var follower := party_members[follower_idx]
		follower.set_as_leader(false, leader, prev_member)
		prev_member = follower

	print("Party Switch -> Leader aktif: [", active_leader_index + 1, "] ", leader.name)


func _process(delta: float):
	handle_camera_shake(delta)
	update_camera_target()


func update_camera_target():
	if not camera or party_members.is_empty():
		return

	var leader := party_members[active_leader_index]
	if not is_instance_valid(leader):
		return

	# 1. Hitung titik tengah dari seluruh anggota party yang masih hidup
	var total_pos := Vector2.ZERO
	var valid_count := 0
	for member in party_members:
		if is_instance_valid(member) and not ("is_dead" in member and member.is_dead):
			total_pos += member.global_position
			valid_count += 1

	var party_centroid := leader.global_position
	if valid_count > 0:
		party_centroid = total_pos / float(valid_count)

	# 2. Posisi dasar kamera: 60% berpusat pada Leader, 40% pada rata-rata formasi tim
	var base_target: Vector2 = leader.global_position.lerp(party_centroid, 0.4)

	# 3. Dynamic Lookahead & Downward Bias
	# Tambahkan bias ke arah bawah (+45 px) agar area bawah selalu lapang
	var lookahead_offset := Vector2(0.0, 45.0)

	var leader_dir := Vector2.DOWN
	if "last_direction" in leader and leader.last_direction != Vector2.ZERO:
		leader_dir = leader.last_direction.normalized()

	# Jika berjalan / menghadap ke bawah (South), beri ruang pandang bawah ekstra (+70 px)
	# sehingga karakter tidak mepet ke tepi bawah layar
	if leader_dir.y > 0.3:
		lookahead_offset.y += 70.0
	elif leader_dir.y < -0.3:
		lookahead_offset.y -= 25.0

	# Tambahkan sedikit offset horizontal ke arah hadap pemain
	lookahead_offset.x += leader_dir.x * 40.0

	camera.global_position = base_target + lookahead_offset


func apply_camera_shake(intensity: float = 8.0):
	shake_intensity = max(shake_intensity, intensity)


func handle_camera_shake(delta: float):
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


func setup_camera_and_boundaries():
	if not camera:
		return

	# Zoom 0.65x agar layar lapang untuk 4 karakter dan ruang gerak luas
	camera.zoom = Vector2(0.65, 0.65)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0

	var ground = get_node_or_null("map_region1/Ground") as TileMapLayer
	if not ground:
		ground = find_child("Ground", true, false) as TileMapLayer

	if not ground:
		return

	var rect: Rect2i = ground.get_used_rect()
	if rect.size == Vector2i.ZERO:
		return

	var map_min: Vector2 = ground.to_global(Vector2(rect.position.x * 16.0, rect.position.y * 16.0))
	var map_max: Vector2 = ground.to_global(Vector2((rect.position.x + rect.size.x) * 16.0, (rect.position.y + rect.size.y) * 16.0))

	# 1. Sesuaikan batas pergerakan kamera persis ke tepi map
	camera.limit_left = int(map_min.x)
	camera.limit_top = int(map_min.y)
	camera.limit_right = int(map_max.x)
	camera.limit_bottom = int(map_max.y)

	# 2. Buat pembatas fisik (invisible walls) di sekeliling peta
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


func _create_wall_shape(parent: Node2D, pos: Vector2, size: Vector2):
	var col := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	col.shape = rect_shape
	col.position = pos
	parent.add_child(col)
