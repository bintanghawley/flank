extends Node2D

# =========================================================
# GAME CONTROLLER & 4-CHARACTER PARTY MANAGER
# =========================================================

@onready var camera: Camera2D = $Camera2D
@onready var gameplay_hud = get_node_or_null("GameplayHud")

var party_members: Array[CharacterBody2D] = []
var active_leader_index: int = 0
var inventory_items: Array[Dictionary] = []
var quest_list: Array[Dictionary] = []
var tracked_quest_id: String = "main_01"
const DEFAULT_START_LOCATION: String = "Istana Kerajaan"
var current_location_name: String = DEFAULT_START_LOCATION
var visited_locations: Array[String] = []
var total_playtime: float = 0.0

# State Tempur Party ala Guardian Tales
enum PartyCombatState { EXPLORING, COMBAT }
var current_combat_state: PartyCombatState = PartyCombatState.EXPLORING
var active_combat_targets: Array[Node2D] = []
var aggro_check_timer: float = 0.0
const AGGRO_CHECK_INTERVAL: float = 0.15
var combat_winddown_timer: float = 0.0
const COMBAT_WINDDOWN_DELAY: float = 0.4

# =========================================================
# SISTEM ARENA HALAMAN ISTANA (GUARDIAN TALES STYLE)
# =========================================================
enum ArenaState { INACTIVE, COMBAT, CLEARED }
var arena_state: ArenaState = ArenaState.INACTIVE
var arena_bounds: Rect2 = Rect2(Vector2(3233.85, 601.54), Vector2(1772.31, 996.92))
var arena_trigger_bounds: Rect2 = Rect2(Vector2(3420.0, 750.0), Vector2(1280.0, 680.0))
var arena_center: Vector2 = Vector2(4120.0, 1100.0)
var arena_enemies: Array[CharacterBody2D] = []
var arena_barrier_body: StaticBody2D = null
const CAMERA_ZOOM_EXPLORE: Vector2 = Vector2(0.75, 0.75)
const CAMERA_ZOOM_ARENA: Vector2 = Vector2(0.65, 0.65)
var target_camera_zoom: Vector2 = CAMERA_ZOOM_EXPLORE
var is_camera_locked_to_arena: bool = false
var arena_clear_delay_timer: float = 0.0
var arena_group_respawn_timer: float = 0.0
const ARENA_GROUP_RESPAWN_DELAY: float = 5.0

# =========================
# AUDIO SFX (TACTICAL PARTY)
# =========================
const SFX_PARTY_SWITCH_LEADER = preload("res://assets/audio/sfx/party/party_switch_leader.wav")
var _is_party_initialized: bool = false

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var sfx_player := AudioStreamPlayer.new()
	sfx_player.bus = &"SFX"
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	add_child(sfx_player)
	sfx_player.finished.connect(sfx_player.queue_free)
	sfx_player.play()

# Pengaturan Camera Shake
var shake_intensity: float = 0.0
var shake_decay: float = 35.0

# Indikator segitiga kecil di atas kepala leader yang sedang aktif
const HERO_INDICATOR_TIP_OFFSET_Y: Dictionary = {
	"Knight_1": -58.0,
	"Bandit_1": -38.0,
	"Archer_1": -60.0,
	"Mage_1": -48.0
}
const DEFAULT_INDICATOR_TIP_OFFSET_Y: float = -42.0
var _active_leader_indicator: Node2D = null
var _active_indicator_bob_time: float = 0.0


func _ready() -> void:
	# 1. Daftarkan 4 anggota party dari scene
	# Urutan default: Knight_1 (Arthur), Bandit_1 (Hellene), Archer_1 (Anastasya), Mage_1 (Magnus)
	var names: Array[String] = ["Knight_1", "Bandit_1", "Archer_1", "Mage_1"]
	for n in names:
		var node := get_node_or_null(n) as CharacterBody2D
		if node:
			party_members.append(node)

	# Fallback pencarian fleksibel jika node bernama Player_Knight / Player_Bandit / Player_Archer / Player_Mage
	if party_members.is_empty():
		for child in get_children():
			if child.is_in_group("player") and child is CharacterBody2D:
				party_members.append(child)

	# 2. Nonaktifkan tabrakan fisik antar-seluruh anggota party (4 karakter)
	for i in range(party_members.size()):
		for j in range(i + 1, party_members.size()):
			party_members[i].add_collision_exception_with(party_members[j])
			party_members[j].add_collision_exception_with(party_members[i])

	# 3. Nonaktifkan tabrakan fisik antara anggota party dan musuh agar tidak saling menyeret / mengunci
	setup_party_enemy_collision_exceptions.call_deferred()
	_init_active_leader_indicator()

	# 4. Tentukan karakter awal sebagai Leader (Knight_1 = index 0)
	set_active_leader(0)
	_is_party_initialized = true

	# Pastikan sisa rekan yang tidak aktif benar-benar dicopot dari SceneTree di mode eksplorasi
	for i in range(party_members.size()):
		if i != active_leader_index:
			var member = party_members[i]
			if is_instance_valid(member) and member.is_inside_tree():
				remove_child(member)

	# Inisialisasi item inventory & quest starter
	_init_starter_inventory()
	_init_starter_quests()

	# Hubungkan Gameplay HUD
	if gameplay_hud:
		gameplay_hud.setup(party_members, active_leader_index, inventory_items, quest_list)
		gameplay_hud.skill_activated.connect(_on_hud_skill_activated)
		gameplay_hud.leader_switch_requested.connect(_on_hud_leader_switch_requested)
		if gameplay_hud.has_signal("pause_menu_requested"):
			gameplay_hud.pause_menu_requested.connect(_on_hud_pause_menu_requested)
		if gameplay_hud.has_signal("party_reordered"):
			gameplay_hud.party_reordered.connect(_on_hud_party_reordered)
		if gameplay_hud.has_signal("item_used"):
			gameplay_hud.item_used.connect(_on_hud_item_used)
		if gameplay_hud.has_signal("quest_tracked"):
			gameplay_hud.quest_tracked.connect(_on_hud_quest_tracked)
		if gameplay_hud.has_signal("quest_navigation_requested"):
			gameplay_hud.quest_navigation_requested.connect(_on_hud_quest_navigation_requested)
		if gameplay_hud.has_signal("save_game_requested"):
			gameplay_hud.save_game_requested.connect(_on_hud_save_game_requested)
		if gameplay_hud.has_signal("load_game_requested"):
			gameplay_hud.load_game_requested.connect(_on_hud_load_game_requested)
		if gameplay_hud.has_signal("return_to_title_requested"):
			gameplay_hud.return_to_title_requested.connect(_on_hud_return_to_title_requested)

		# Sembunyikan elemen HUD pertarungan (Party & Skill) saat eksplorasi di luar arena
		if gameplay_hud.has_method("set_combat_hud_visible"):
			gameplay_hud.set_combat_hud_visible(false, false)

		# Sinkronisasi quest aktif pertama ke overlay HUD
		var tracked_q: Dictionary = _get_quest_by_id(tracked_quest_id)
		if not tracked_q.is_empty():
			gameplay_hud.update_hud_quest_display(tracked_q)

	# 5. Inisialisasi kamera dan batasan map
	update_arena_bounds_from_camera()
	setup_camera_and_boundaries.call_deferred()
	_init_arena_barrier.call_deferred()
	_init_arena_enemies.call_deferred()

	# 6. Jalankan efek pembukaan Circular Mask (Iris Open) saat masuk arena game
	play_iris_opening_transition()


func setup_party_enemy_collision_exceptions() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for p in party_members:
		if is_instance_valid(p) and p.is_inside_tree() and p is CollisionObject2D:
			for e in enemies:
				if is_instance_valid(e) and e is CollisionObject2D:
					p.add_collision_exception_with(e)
					e.add_collision_exception_with(p)


func _unhandled_input(event: InputEvent) -> void:
	# Tombol pintasan pergantian karakter, skill, dan perintah party berbasis action mapping
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("switch_character"):
			if arena_state == ArenaState.COMBAT:
				switch_to_next_character()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("skill_1"):
			if arena_state == ArenaState.COMBAT:
				trigger_hero_skill_by_slot(0)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("skill_2"):
			if arena_state == ArenaState.COMBAT:
				trigger_hero_skill_by_slot(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("skill_3"):
			if arena_state == ArenaState.COMBAT:
				trigger_hero_skill_by_slot(2)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("skill_4"):
			if arena_state == ArenaState.COMBAT:
				trigger_hero_skill_by_slot(3)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if gameplay_hud:
				_on_hud_pause_menu_requested()
				gameplay_hud.toggle_pause_menu()
				if get_viewport():
					get_viewport().set_input_as_handled()


func is_character_alive(character: CharacterBody2D) -> bool:
	if not character or not is_instance_valid(character):
		return false
	if "is_dead" in character and character.is_dead:
		return false
	return true


func switch_to_next_character(force: bool = false) -> void:
	if not force and arena_state != ArenaState.COMBAT:
		return
	if party_members.is_empty():
		return

	var count := party_members.size()
	# Cari karakter hidup berikutnya secara siklis mulai dari anggota berikutnya
	for step in range(1, count):
		var target_idx := (active_leader_index + step) % count
		var candidate := party_members[target_idx]
		if is_character_alive(candidate):
			switch_to_character(target_idx, force)
			return

	print("Tidak ada anggota party lain yang masih hidup untuk dipilih.")


func switch_to_character(idx: int, force: bool = false) -> void:
	if not force and arena_state != ArenaState.COMBAT:
		return
	if idx < 0 or idx >= party_members.size() or idx == active_leader_index:
		return

	var target := party_members[idx]
	if not is_character_alive(target):
		print("Karakter [", idx + 1, "] sedang gugur. Pergantian Leader dibatalkan.")
		return

	set_active_leader(idx)


func set_active_leader(idx: int, prev_leader_override: CharacterBody2D = null) -> void:
	if idx < 0 or idx >= party_members.size():
		return

	var prev_leader: CharacterBody2D = prev_leader_override
	if not prev_leader and active_leader_index >= 0 and active_leader_index < party_members.size():
		prev_leader = party_members[active_leader_index]

	# Fallback eksplorasi: jika prev_leader tidak valid atau sama dengan target,
	# cari karakter lain yang saat ini masih aktif berada di dalam SceneTree
	if _is_party_initialized and arena_state != ArenaState.COMBAT:
		var target_candidate := party_members[idx]
		if not prev_leader or prev_leader == target_candidate or not prev_leader.is_inside_tree():
			for member in party_members:
				if is_instance_valid(member) and member != target_candidate and member.is_inside_tree():
					prev_leader = member
					break

	active_leader_index = idx
	var leader := party_members[active_leader_index]
	if not is_instance_valid(leader):
		return

	# Jika berganti karakter saat eksplorasi 1 karakter, posisikan karakter baru tepat di posisi karakter sebelumnya
	if arena_state != ArenaState.COMBAT:
		if prev_leader and is_instance_valid(prev_leader) and prev_leader != leader:
			var prev_pos: Vector2 = prev_leader.global_position
			var prev_last_dir: Vector2 = prev_leader.last_direction if "last_direction" in prev_leader else Vector2.DOWN
			var prev_mov_dir: Vector2 = prev_leader.last_movement_direction if "last_movement_direction" in prev_leader else Vector2.DOWN

			if prev_leader.is_inside_tree():
				remove_child(prev_leader)
			if not leader.is_inside_tree():
				add_child(leader)
			leader.global_position = prev_pos
			if "target_position" in leader:
				leader.target_position = prev_pos
			if "velocity" in leader:
				leader.velocity = Vector2.ZERO
			if "last_direction" in leader:
				leader.last_direction = prev_last_dir
			if "last_movement_direction" in leader:
				leader.last_movement_direction = prev_mov_dir
		elif not leader.is_inside_tree():
			add_child(leader)
		if camera:
			camera.global_position = leader.global_position
			if camera.has_method("reset_smoothing"):
				camera.reset_smoothing()
			if camera.has_method("force_update_scroll"):
				camera.force_update_scroll()

	# Berikan status Leader langsung ke karakter terpilih
	breadcrumbs.clear()
	leader.set_as_leader(true, null, 0)

	# Berikan referensi langsung ke Leader dan nomor urutan slot tetap (1, 2, 3)
	var slot_order: int = 1
	for step in range(1, party_members.size()):
		var follower_idx := (active_leader_index + step) % party_members.size()
		var follower := party_members[follower_idx]
		if is_instance_valid(follower):
			follower.set_as_leader(false, leader, slot_order)
			if arena_state != ArenaState.COMBAT and follower.is_inside_tree():
				remove_child(follower)
		slot_order += 1

	update_party_visibility()

	# Sinkronkan state combat jika pergantian karakter terjadi saat bertempur
	if current_combat_state == PartyCombatState.COMBAT:
		notify_party_combat_state(true)
	else:
		notify_party_combat_state(false)

	if _is_party_initialized:
		play_sfx(SFX_PARTY_SWITCH_LEADER, -2.0)

	if gameplay_hud:
		gameplay_hud.set_active_leader(idx)

	_update_active_leader_indicator(0.0)
	print("Party Switch -> Leader aktif: [", active_leader_index + 1, "] ", leader.name)


func _set_character_collision_active(char_node: CharacterBody2D, active: bool) -> void:
	if not char_node or not is_instance_valid(char_node) or not char_node.is_inside_tree():
		return
	var should_disable: bool = not active
	if char_node.has_node("CollisionShape2D"):
		var col = char_node.get_node("CollisionShape2D") as CollisionShape2D
		if col and col.disabled != should_disable:
			col.set_deferred("disabled", should_disable)
	if char_node.has_node("Hurtbox/CollisionShape2D"):
		var hurt_col = char_node.get_node("Hurtbox/CollisionShape2D") as CollisionShape2D
		if hurt_col and hurt_col.disabled != should_disable:
			hurt_col.set_deferred("disabled", should_disable)


func update_party_visibility() -> void:
	var in_arena_combat: bool = (arena_state == ArenaState.COMBAT)
	for i in range(party_members.size()):
		var member = party_members[i]
		if not is_instance_valid(member):
			continue

		var is_dead_char: bool = ("is_dead" in member and member.is_dead)
		var is_active: bool = false
		if not is_dead_char:
			if i == active_leader_index:
				is_active = true
			elif in_arena_combat:
				is_active = true

		if is_active:
			if not member.is_inside_tree():
				add_child(member)
			if member.process_mode != Node.PROCESS_MODE_INHERIT:
				member.process_mode = Node.PROCESS_MODE_INHERIT
			if not member.visible:
				member.visible = true
			if not member.is_physics_processing():
				member.set_physics_process(true)
			if not member.is_processing():
				member.set_process(true)
			var should_input: bool = (i == active_leader_index)
			if member.is_processing_unhandled_input() != should_input:
				member.set_process_unhandled_input(should_input)
			_set_character_collision_active(member, true)
		else:
			if member.is_inside_tree():
				remove_child(member)
			member.visible = false
			if member.is_physics_processing():
				member.set_physics_process(false)
			if member.is_processing():
				member.set_process(false)
			if member.is_processing_unhandled_input():
				member.set_process_unhandled_input(false)
			if member.velocity != Vector2.ZERO:
				member.velocity = Vector2.ZERO


func trigger_hero_skill_by_slot(slot_idx: int) -> void:
	if arena_state != ArenaState.COMBAT:
		return
	if slot_idx < 0 or slot_idx >= party_members.size():
		return
	# Saat mode eksplorasi 1 karakter, tombol 1-4 tidak digunakan untuk memilih / beralih karakter
	if slot_idx != active_leader_index:
		return
	var target_hero := party_members[slot_idx]
	if not is_instance_valid(target_hero) or not is_character_alive(target_hero):
		return

	# Eksekusi skill jika slot yang ditekan adalah Leader aktif
	execute_hero_skill(target_hero)


func execute_hero_skill(hero: CharacterBody2D) -> void:
	if arena_state != ArenaState.COMBAT:
		return
	if not is_instance_valid(hero) or not is_character_alive(hero):
		return

	if hero.has_method("activate_shield"):
		hero.activate_shield()
	elif hero.has_method("activate_triple_slash"):
		var cd: float = hero.get("skill_cooldown_timer") if "skill_cooldown_timer" in hero else 0.0
		var is_att: bool = hero.get("is_attacking") if "is_attacking" in hero else false
		var is_sk: bool = hero.get("is_skill_active") if "is_skill_active" in hero else false
		var is_lunge: bool = hero.get("is_ambush_lunging") if "is_ambush_lunging" in hero else false
		if cd <= 0.0 and not is_att and not is_sk and not is_lunge:
			hero.activate_triple_slash()
	elif hero.has_method("activate_skill_mode"):
		if hero.has_method("can_activate_skill") and hero.can_activate_skill():
			hero.activate_skill_mode()
	elif hero.has_method("start_skill_aiming"):
		var cd_m: float = hero.get("skill_cooldown_timer") if "skill_cooldown_timer" in hero else 0.0
		var is_aim: bool = hero.get("is_aiming_skill") if "is_aiming_skill" in hero else false
		var is_rel: bool = hero.get("is_skill_releasing") if "is_skill_releasing" in hero else false
		var is_att_m: bool = hero.get("is_attacking") if "is_attacking" in hero else false
		if not is_aim and not is_rel and not is_att_m and cd_m <= 0.0:
			hero.start_skill_aiming()


func _on_hud_skill_activated(slot_idx: int) -> void:
	trigger_hero_skill_by_slot(slot_idx)


func _on_hud_leader_switch_requested(hero_idx: int) -> void:
	if hero_idx >= 0 and hero_idx < party_members.size() and is_character_alive(party_members[hero_idx]):
		switch_to_character(hero_idx)


func _on_hud_pause_menu_requested() -> void:
	var leader := get_active_leader()
	if is_instance_valid(leader) and is_instance_valid(camera):
		camera.global_position = leader.global_position
		if camera.has_method("reset_smoothing"):
			camera.reset_smoothing()
		if camera.has_method("force_update_scroll"):
			camera.force_update_scroll()


func _on_hud_party_reordered(new_party: Array[CharacterBody2D]) -> void:
	if new_party.is_empty():
		return

	# Dapatkan leader lama yang saat ini sedang aktif dimainkan sebelum array party diperbarui
	var old_leader: CharacterBody2D = get_active_leader()
	if not old_leader or not old_leader.is_inside_tree():
		for member in party_members:
			if is_instance_valid(member) and member.is_inside_tree():
				old_leader = member
				break

	party_members = new_party
	# Karakter di slot pertama otomatis menjadi leader
	set_active_leader(0, old_leader)
	update_camera_target(0.0)


func _init_starter_inventory() -> void:
	inventory_items = [
		# Kategori 0: Consumable (13 item untuk menguji scrollbar > 12 slot)
		{
			"id": "potion_hp",
			"name": "Ramuan Pemulihan",
			"category": 0,
			"icon_rect": Rect2(164, 516, 9, 9),
			"description": "Ramuan ajaib merah yang dapat memulihkan 5 HP karakter saat digunakan.",
			"quantity": 5,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 5
		},
		{
			"id": "apple",
			"name": "Apel Hutan",
			"category": 0,
			"icon_rect": Rect2(212, 532, 8, 8),
			"description": "Buah apel segar manis dari perkebunan, memulihkan 2 HP karakter.",
			"quantity": 8,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 2
		},
		{
			"id": "bread",
			"name": "Roti Gandum",
			"category": 0,
			"icon_rect": Rect2(195, 533, 7, 7),
			"description": "Roti gandum padat yang mengenyangkan, memulihkan 3 HP karakter.",
			"quantity": 4,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 3
		},
		{
			"id": "meat",
			"name": "Daging Panggang",
			"category": 0,
			"icon_rect": Rect2(181, 500, 8, 9),
			"description": "Daging panggang lezat kaya protein, memulihkan 6 HP karakter.",
			"quantity": 3,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 6
		},
		{
			"id": "holy_water",
			"name": "Air Suci",
			"category": 0,
			"icon_rect": Rect2(164, 516, 9, 9),
			"description": "Air berkah dari kuil agung, memulihkan 4 HP dan menyegarkan raga.",
			"quantity": 2,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 4
		},
		{
			"id": "herb",
			"name": "Herba Hijau",
			"category": 0,
			"icon_rect": Rect2(212, 532, 8, 8),
			"description": "Tanaman obat liar berkhasiat herbal, memulihkan 1 HP karakter.",
			"quantity": 10,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 1
		},
		{
			"id": "honey",
			"name": "Madu Hutan",
			"category": 0,
			"icon_rect": Rect2(195, 533, 7, 7),
			"description": "Madu murni dari lebah liar hutan, memulihkan 3 HP karakter.",
			"quantity": 5,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 3
		},
		{
			"id": "cheese",
			"name": "Keju Tua",
			"category": 0,
			"icon_rect": Rect2(195, 533, 7, 7),
			"description": "Keju asin yang diawetkan cukup lama, memulihkan 2 HP karakter.",
			"quantity": 6,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 2
		},
		{
			"id": "soup",
			"name": "Sup Jamur",
			"category": 0,
			"icon_rect": Rect2(181, 500, 8, 9),
			"description": "Semangkuk sup hangat lezat beraroma jamur, memulihkan 4 HP karakter.",
			"quantity": 3,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 4
		},
		{
			"id": "big_potion",
			"name": "Ramuan Besar",
			"category": 0,
			"icon_rect": Rect2(164, 516, 9, 9),
			"description": "Konsentrat ramuan pemulih tingkat tinggi, memulihkan 10 HP karakter.",
			"quantity": 2,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 10
		},
		{
			"id": "berry",
			"name": "Buah Beri",
			"category": 0,
			"icon_rect": Rect2(212, 532, 8, 8),
			"description": "Segenggam buah beri merah manis, memulihkan 1 HP karakter.",
			"quantity": 12,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 1
		},
		{
			"id": "soul_elixir",
			"name": "Eliksir Jiwa",
			"category": 0,
			"icon_rect": Rect2(164, 516, 9, 9),
			"description": "Eliksir langka pemurni energi spiritual, memulihkan 8 HP karakter.",
			"quantity": 1,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 8
		},
		{
			"id": "pumpkin_pie",
			"name": "Pai Labu",
			"category": 0,
			"icon_rect": Rect2(195, 533, 7, 7),
			"description": "Pai labu manis hangat buatan koki istana, memulihkan 5 HP karakter.",
			"quantity": 3,
			"max_stack": 99,
			"usable": true,
			"heal_amount": 5
		},

		# Kategori 1: Kunci
		{
			"id": "palace_key",
			"name": "Kunci Istana",
			"category": 1,
			"icon_rect": Rect2(164, 533, 9, 6),
			"description": "Kunci kuno berkarat yang dapat membuka gerbang utama istana kerajaan.",
			"quantity": 1,
			"max_stack": 1,
			"usable": false
		},
		{
			"id": "dungeon_key",
			"name": "Kunci Bawah Tanah",
			"category": 1,
			"icon_rect": Rect2(164, 533, 9, 6),
			"description": "Kunci besi berat untuk membuka pintu sel tahanan di bawah tanah.",
			"quantity": 1,
			"max_stack": 1,
			"usable": false
		},

		# Kategori 2: Collectible
		{
			"id": "ancient_coin",
			"name": "Koin Kuno Emas",
			"category": 2,
			"icon_rect": Rect2(195, 533, 7, 7),
			"description": "Mata uang kuno era kerajaan masa lalu yang bernilai sangat tinggi.",
			"quantity": 15,
			"max_stack": 999,
			"usable": false
		},
		{
			"id": "honor_chalice",
			"name": "Piala Kehormatan",
			"category": 2,
			"icon_rect": Rect2(195, 533, 7, 7),
			"description": "Piala perak bertatahkan permata yang dihadiahkan untuk pahlawan kerajaan.",
			"quantity": 1,
			"max_stack": 1,
			"usable": false
		},

		# Kategori 3: Notes
		{
			"id": "intel_report",
			"name": "Laporan Intelijen",
			"category": 3,
			"icon_rect": Rect2(213, 500, 7, 9),
			"description": "Gulungan dokumen rahasia mengenai pergerakan bandit di sekitar perbatasan.",
			"quantity": 1,
			"max_stack": 1,
			"usable": false
		},
		{
			"id": "soldier_diary",
			"name": "Catatan Harian Prajurit",
			"category": 3,
			"icon_rect": Rect2(213, 500, 7, 9),
			"description": "Catatan usang yang menceritakan pertempuran sengit di benteng utara.",
			"quantity": 1,
			"max_stack": 1,
			"usable": false
		}
	]


func _on_hud_item_used(item_data: Dictionary) -> void:
	if item_data.has("heal_amount"):
		var heal_val: int = item_data.get("heal_amount", 5)
		if active_leader_index >= 0 and active_leader_index < party_members.size():
			var leader = party_members[active_leader_index]
			if is_instance_valid(leader) and "current_health" in leader and "max_health" in leader:
				var old_hp: int = leader.current_health
				leader.current_health = mini(leader.max_health, leader.current_health + heal_val)
				var healed: int = leader.current_health - old_hp
				print("ITEM DIGUNAKAN: %s | +%d HP | Sisa HP: %d/%d" % [item_data.get("name", "Item"), healed, leader.current_health, leader.max_health])
				if gameplay_hud:
					gameplay_hud.show_speech_bubble("+%d HP" % healed)


func _init_starter_quests() -> void:
	quest_list = [
		{
			"id": "main_01",
			"category": "main",
			"title": "Penyelidikan Istana",
			"location": "Istana Kerajaan",
			"objective": "Temui penjaga gerbang istana.",
			"description": "Raja memanggil pasukan kesatria untuk menyelidiki gangguan misterius di perbatasan timur kerajaan.",
			"status": "active",
			"target_position": Vector2(3000, 1000)
		},
		{
			"id": "main_02",
			"category": "main",
			"title": "Patroli Perbatasan",
			"location": "Gerbang Selatan",
			"objective": "Periksa pos penjagaan gerbang selatan.",
			"description": "Laporan pengintai menyebutkan adanya pergerakan mencurigakan di luar tembok kota.",
			"status": "active",
			"target_position": Vector2(3500, 2500)
		},
		{
			"id": "main_03",
			"category": "main",
			"title": "Persiapan Pasukan",
			"location": "Barak Militer",
			"objective": "Kumpulkan perlengkapan senjata dan ramuan.",
			"description": "Pastikan seluruh anggota pasukan dilengkapi perlengkapan tempur yang memadai sebelum ekspedisi.",
			"status": "active",
			"target_position": Vector2(2500, 1500)
		},
		{
			"id": "world_01",
			"category": "world",
			"title": "Bantuan Warga Desa",
			"location": "Desa Oakhaven",
			"objective": "Bicara dengan tetua desa mengenai suplai gandum.",
			"description": "Warga desa membutuhkan perlindungan dari gangguan monster liar di sekitar lumbung pangan.",
			"status": "active",
			"target_position": Vector2(1500, 3000)
		},
		{
			"id": "world_02",
			"category": "world",
			"title": "Perburuan Bandit",
			"location": "Lembah Berkabut",
			"objective": "Tumpas komplotan bandit di lembah.",
			"description": "Kafilah dagang kerajaan dihadang bandit. Pulihkan keamanan jalur perdagangan dari ancaman penjahat.",
			"status": "active",
			"target_position": Vector2(5000, 1800)
		}
	]


func _get_quest_by_id(q_id: String) -> Dictionary:
	for q in quest_list:
		if q.get("id", "") == q_id:
			return q
	return {}


func _on_hud_quest_tracked(quest: Dictionary) -> void:
	tracked_quest_id = quest.get("id", "")
	if gameplay_hud:
		gameplay_hud.update_hud_quest_display(quest)


func _on_hud_quest_navigation_requested(quest: Dictionary) -> void:
	tracked_quest_id = quest.get("id", "")
	if gameplay_hud:
		gameplay_hud.update_hud_quest_display(quest)
		var loc: String = quest.get("location", "")
		if loc != "":
			gameplay_hud.show_speech_bubble("Navigasi: " + loc)


func enter_location(location_name: String) -> void:
	"""Menandai kunjungan lokasi dan memicu banner sekali saat pertama kali masuk."""
	var clean_loc := location_name.strip_edges()
	if clean_loc.is_empty():
		return

	current_location_name = clean_loc
	if visited_locations.has(clean_loc):
		return

	visited_locations.append(clean_loc)
	if gameplay_hud and gameplay_hud.has_method("show_location_banner"):
		gameplay_hud.show_location_banner(clean_loc)


func get_active_leader() -> CharacterBody2D:
	if not party_members.is_empty() and active_leader_index >= 0 and active_leader_index < party_members.size():
		return party_members[active_leader_index]
	return null


func _process(delta: float) -> void:
	total_playtime += delta
	handle_camera_shake(delta)
	update_camera_target(delta)
	update_party_skill_cooldowns(delta)
	if arena_state == ArenaState.INACTIVE:
		check_arena_trigger()
	elif arena_state == ArenaState.COMBAT:
		check_arena_completion(delta)
	elif arena_state == ArenaState.CLEARED:
		handle_arena_group_respawn(delta)
	handle_viewport_aggro_detection(delta)
	update_breadcrumbs()
	check_active_leader_status()
	_update_active_leader_indicator(delta)
	update_party_visibility()


func update_party_skill_cooldowns(delta: float) -> void:
	for member in party_members:
		if not is_instance_valid(member):
			continue
		# Jika karakter sedang tidak di scene tree atau physics_process tidak aktif,
		# game controller yang melanjutkan countdown cooldown skill & perisai
		if not member.is_inside_tree() or not member.is_physics_processing():
			if "skill_cooldown_timer" in member and member.skill_cooldown_timer > 0.0:
				member.skill_cooldown_timer = maxf(0.0, member.skill_cooldown_timer - delta)
			if "shield_timer" in member and member.shield_timer > 0.0:
				member.shield_timer = maxf(0.0, member.shield_timer - delta)
				if member.shield_timer <= 0.0 and member.has_method("deactivate_shield"):
					member.deactivate_shield()


func _physics_process(_delta: float) -> void:
	if arena_state == ArenaState.COMBAT:
		# Fail-safe pembatas koordinat arena agar hero tidak tembus/glitch saat knockback keras
		var min_x := arena_bounds.position.x + 15.0
		var max_x := arena_bounds.end.x - 15.0
		var min_y := arena_bounds.position.y + 15.0
		var max_y := arena_bounds.end.y - 15.0
		for member in party_members:
			if is_instance_valid(member) and member.is_inside_tree() and member.visible:
				member.global_position.x = clampf(member.global_position.x, min_x, max_x)
				member.global_position.y = clampf(member.global_position.y, min_y, max_y)


func check_active_leader_status() -> void:
	var leader := get_active_leader()
	if is_instance_valid(leader) and not is_character_alive(leader):
		switch_to_next_character()


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
	if arena_state != ArenaState.COMBAT:
		return

	aggro_check_timer -= delta
	if aggro_check_timer > 0.0:
		return
	aggro_check_timer = AGGRO_CHECK_INTERVAL

	var alive_arena_enemies: Array[Node2D] = []
	for enemy in arena_enemies:
		if is_instance_valid(enemy) and not ("is_dead" in enemy and enemy.is_dead):
			alive_arena_enemies.append(enemy)

	active_combat_targets = alive_arena_enemies


func notify_party_combat_state(in_combat: bool) -> void:
	for member in party_members:
		if is_instance_valid(member) and member.is_inside_tree() and member.has_method("set_party_combat_mode"):
			member.set_party_combat_mode(in_combat)


func update_camera_target(delta: float = 0.0) -> void:
	if not camera or party_members.is_empty():
		return
	var leader := party_members[active_leader_index]
	if not is_instance_valid(leader):
		return

	# Zoom smoothing dinamis
	if delta > 0.0:
		camera.zoom = camera.zoom.lerp(target_camera_zoom, clampf(delta * 3.0, 0.0, 1.0))
	else:
		camera.zoom = target_camera_zoom

	if is_camera_locked_to_arena and arena_state == ArenaState.COMBAT:
		# Kunci posisi kamera langsung ke tengah arena
		camera.global_position = arena_center
	else:
		# Fokus 100% pada posisi Leader (tepat di pusat inti tubuh karakter)
		var camera_target: Vector2 = leader.global_position
		camera.global_position = camera_target
		if delta == 0.0:
			if camera.has_method("reset_smoothing"):
				camera.reset_smoothing()
			if camera.has_method("force_update_scroll"):
				camera.force_update_scroll()

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

	camera.zoom = CAMERA_ZOOM_EXPLORE
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0

	var ground := get_node_or_null("map_region1/Ground")
	if not ground:
		ground = find_child("Ground", true, false)

	if not ground:
		return

	var map_min := Vector2.ZERO
	var map_max := Vector2.ZERO

	if ground is Sprite2D and ground.texture:
		var tex_size: Vector2 = ground.texture.get_size() * ground.scale
		map_min = ground.global_position
		map_max = ground.global_position + tex_size
	elif ground is TileMapLayer:
		var rect: Rect2i = ground.get_used_rect()
		if rect.size == Vector2i.ZERO:
			return
		map_min = ground.to_global(Vector2(rect.position.x * 16.0, rect.position.y * 16.0))
		map_max = ground.to_global(Vector2((rect.position.x + rect.size.x) * 16.0, (rect.position.y + rect.size.y) * 16.0))
	else:
		return

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
# ARENA HALAMAN ISTANA (INVISIBLE BARRIER & COMBAT TRIGGER)
# =========================================================

func update_arena_bounds_from_camera() -> void:
	var vp_size: Vector2 = Vector2(1152.0, 648.0)
	if is_inside_tree() and get_viewport():
		var actual_size: Vector2 = get_viewport_rect().size
		if actual_size.x > 0.0 and actual_size.y > 0.0:
			vp_size = actual_size
	var world_size: Vector2 = vp_size / CAMERA_ZOOM_ARENA
	arena_bounds = Rect2(arena_center - world_size * 0.5, world_size)


func _init_arena_barrier() -> void:
	if arena_barrier_body != null and is_instance_valid(arena_barrier_body):
		return

	update_arena_bounds_from_camera()

	arena_barrier_body = StaticBody2D.new()
	arena_barrier_body.name = "ArenaInvisibleBarrier"
	arena_barrier_body.collision_layer = 1
	arena_barrier_body.collision_mask = 0

	var thickness := 60.0
	var west_x := arena_bounds.position.x
	var east_x := arena_bounds.end.x
	var north_y := arena_bounds.position.y
	var south_y := arena_bounds.end.y
	var width := arena_bounds.size.x
	var height := arena_bounds.size.y

	# 4 Dinding pembatas arena tanpa visual (barrier invisible) tepat di 4 batas tepi layar kamera
	# Dinding barat (tepat di luar tepi layar kiri)
	_create_barrier_shape(arena_barrier_body, Vector2(west_x - thickness * 0.5, north_y + height * 0.5), Vector2(thickness, height + thickness * 2.0))
	# Dinding timur (tepat di luar tepi layar kanan)
	_create_barrier_shape(arena_barrier_body, Vector2(east_x + thickness * 0.5, north_y + height * 0.5), Vector2(thickness, height + thickness * 2.0))
	# Dinding utara (tepat di luar tepi layar atas)
	_create_barrier_shape(arena_barrier_body, Vector2(west_x + width * 0.5, north_y - thickness * 0.5), Vector2(width + thickness * 2.0, thickness))
	# Dinding selatan (tepat di luar tepi layar bawah)
	_create_barrier_shape(arena_barrier_body, Vector2(west_x + width * 0.5, south_y + thickness * 0.5), Vector2(width + thickness * 2.0, thickness))

	add_child(arena_barrier_body)
	_set_arena_barrier_enabled(false)


func _create_barrier_shape(parent: StaticBody2D, pos: Vector2, size: Vector2) -> void:
	var col := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	col.shape = rect_shape
	col.position = pos
	col.disabled = true
	parent.add_child(col)


func _set_arena_barrier_enabled(enabled: bool) -> void:
	if not arena_barrier_body or not is_instance_valid(arena_barrier_body):
		return
	for child in arena_barrier_body.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", not enabled)


func _init_arena_enemies() -> void:
	arena_enemies.clear()
	update_arena_bounds_from_camera()
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and e is CharacterBody2D:
			if arena_bounds.has_point(e.global_position):
				arena_enemies.append(e)
				if "wait_for_arena" in e:
					e.wait_for_arena = true
				if "can_respawn" in e:
					e.can_respawn = false


func check_arena_trigger() -> void:
	if arena_state != ArenaState.INACTIVE:
		return
	var leader := get_active_leader()
	if not leader or not is_instance_valid(leader):
		return
	if arena_trigger_bounds.has_point(leader.global_position):
		start_arena_battle()


func start_arena_battle() -> void:
	if arena_state != ArenaState.INACTIVE:
		return
	arena_state = ArenaState.COMBAT
	current_combat_state = PartyCombatState.COMBAT
	arena_clear_delay_timer = 0.0

	update_arena_bounds_from_camera()

	# 1. Aktifkan invisible barrier penutup arena
	_set_arena_barrier_enabled(true)

	# 2. Pindahkan target kamera ke tengah arena dan perbesar sudut pandang (zoom out)
	target_camera_zoom = CAMERA_ZOOM_ARENA
	is_camera_locked_to_arena = true

	# 3. Spawn / aktifkan 3 rekan party di sekitar leader
	_deploy_party_for_combat()
	update_party_visibility()
	notify_party_combat_state(true)

	# 4. Bangunkan seluruh musuh di arena untuk langsung mengejar party
	var leader := get_active_leader()
	for enemy in arena_enemies:
		if is_instance_valid(enemy):
			if "wait_for_arena" in enemy:
				enemy.wait_for_arena = false
			if enemy.has_method("alert_to_combat"):
				enemy.alert_to_combat(leader)

	if gameplay_hud and gameplay_hud.has_method("show_speech_bubble"):
		gameplay_hud.show_speech_bubble("Musuh!")

	# Tampilkan elemen HUD pertarungan saat memasuki arena
	if gameplay_hud and gameplay_hud.has_method("set_combat_hud_visible"):
		gameplay_hud.set_combat_hud_visible(true, true)

	print("Arena Battle Dimulai! Kamera fokus ke tengah arena (", arena_center, "), party 4 karakter aktif.")


func _deploy_party_for_combat() -> void:
	var leader := get_active_leader()
	if not leader or not is_instance_valid(leader):
		return

	var offsets: Array[Vector2] = [
		Vector2(-45.0, -30.0),
		Vector2(-45.0, 30.0),
		Vector2(-75.0, 0.0)
	]
	var off_idx: int = 0
	for i in range(party_members.size()):
		if i == active_leader_index:
			continue
		var member = party_members[i]
		if not is_instance_valid(member):
			continue
		if "is_dead" in member and member.is_dead:
			continue

		if not member.is_inside_tree():
			add_child(member)

		var spawn_pos: Vector2 = leader.global_position + (offsets[off_idx] if off_idx < offsets.size() else Vector2(-50.0, 0.0))
		spawn_pos.x = clampf(spawn_pos.x, arena_bounds.position.x + 25.0, arena_bounds.end.x - 25.0)
		spawn_pos.y = clampf(spawn_pos.y, arena_bounds.position.y + 25.0, arena_bounds.end.y - 25.0)
		member.global_position = spawn_pos
		if "target_position" in member:
			member.target_position = spawn_pos
		if "velocity" in member:
			member.velocity = Vector2.ZERO
		off_idx += 1


func check_arena_completion(delta: float) -> void:
	if arena_state != ArenaState.COMBAT:
		return

	var all_dead: bool = true
	for e in arena_enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead) and e.is_in_group("enemy"):
			all_dead = false
			break

	if all_dead:
		arena_clear_delay_timer += delta
		# Jeda 0.6s agar momen kemenangan terasa natural sebelum transisi kembali
		if arena_clear_delay_timer >= 0.6:
			end_arena_battle()
	else:
		arena_clear_delay_timer = 0.0


func end_arena_battle() -> void:
	if arena_state != ArenaState.COMBAT:
		return
	arena_state = ArenaState.CLEARED
	current_combat_state = PartyCombatState.EXPLORING
	arena_group_respawn_timer = ARENA_GROUP_RESPAWN_DELAY

	# 1. Buka batas arena (nonaktifkan barrier)
	_set_arena_barrier_enabled(false)

	# 2. Kembalikan kamera ke mode eksplorasi (zoom explore dan ikuti leader)
	target_camera_zoom = CAMERA_ZOOM_EXPLORE
	is_camera_locked_to_arena = false

	# 3. Kembalikan party ke mode 1 karakter
	notify_party_combat_state(false)
	update_party_visibility()
	breadcrumbs.clear()

	# Sembunyikan kembali elemen HUD pertarungan setelah arena selesai
	if gameplay_hud and gameplay_hud.has_method("set_combat_hud_visible"):
		gameplay_hud.set_combat_hud_visible(false, true)

	if gameplay_hud and gameplay_hud.has_method("show_speech_bubble"):
		gameplay_hud.show_speech_bubble("Aman!")

	print("Arena Cleared! Seluruh musuh kalah. Kamera kembali ke Leader, party kembali 1 karakter. Grup musuh akan muncul lagi dalam 5 detik.")


func handle_arena_group_respawn(delta: float) -> void:
	if arena_state != ArenaState.CLEARED:
		return
	arena_group_respawn_timer -= delta
	if arena_group_respawn_timer <= 0.0:
		_respawn_arena_enemy_group()


func _respawn_arena_enemy_group() -> void:
	for e in arena_enemies:
		if is_instance_valid(e):
			if "wait_for_arena" in e:
				e.wait_for_arena = true
			if e.has_method("respawn"):
				e.respawn()

	arena_state = ArenaState.INACTIVE
	arena_clear_delay_timer = 0.0
	print("Grup musuh arena (2 Knight, 1 Archer) telah muncul kembali di posisinya! Siap untuk pertempuran berikutnya.")


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
		for i in range(1, 60):
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
			for k in range(1, 60):
				breadcrumbs.append({
					"pos": turn_pt - step_dir * (k * BREADCRUMB_INTERVAL),
					"dir": step_dir
				})
		else:
			# Gerakan biasa atau belok 90° (Snake Corner Turn)
			breadcrumbs.push_front({"pos": leader_pos, "dir": step_dir})
			if breadcrumbs.size() > 300:
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


func get_follower_nav_target(slot_index: int, follower_pos: Vector2, space_state: PhysicsDirectSpaceState2D = null) -> Dictionary:
	var slot_info := get_follower_trail_slot(slot_index)
	if slot_info.is_empty():
		return {}

	var final_pos: Vector2 = slot_info["pos"]
	var facing_dir: Vector2 = slot_info.get("dir", Vector2.DOWN)

	# Jika jarak sudah sangat dekat atau tidak ada space_state, langsung ke final_pos
	if follower_pos.distance_to(final_pos) <= 24.0 or not space_state:
		return {
			"target_pos": final_pos,
			"final_slot": final_pos,
			"dir": facing_dir,
			"is_corner_waypoint": false
		}

	# Cek apakah garis langsung ke final_pos terhalang oleh Collision Layer 1 (dinding / bangunan)
	var ray := PhysicsRayQueryParameters2D.create(follower_pos, final_pos)
	ray.collision_mask = 1
	var hit := space_state.intersect_ray(ray)

	if hit.is_empty():
		# Jalur langsung bersih tanpa rintangan
		return {
			"target_pos": final_pos,
			"final_slot": final_pos,
			"dir": facing_dir,
			"is_corner_waypoint": false
		}

	# Jalur terhalang rintangan/sudut bangunan:
	# Cari titik sudut pada breadcrumbs yang terlihat jelas oleh follower (Clear LoS)
	var best_waypoint := final_pos
	var found_clear := false

	var target_dist: float = slot_index * QUEUE_DIST
	var accumulated: float = 0.0
	var prev: Vector2 = party_members[active_leader_index].global_position if (active_leader_index < party_members.size() and is_instance_valid(party_members[active_leader_index])) else Vector2.ZERO
	var slot_bc_index: int = 0

	for i in range(breadcrumbs.size()):
		var cur: Vector2 = breadcrumbs[i]["pos"]
		accumulated += prev.distance_to(cur)
		prev = cur
		if accumulated >= target_dist:
			slot_bc_index = i
			break

	var start_idx: int = clampi(slot_bc_index + 12, 0, breadcrumbs.size() - 1)
	for i in range(start_idx, -1, -1):
		var candidate: Vector2 = breadcrumbs[i]["pos"]
		if candidate.distance_to(follower_pos) < 20.0:
			continue
		var check_ray := PhysicsRayQueryParameters2D.create(follower_pos, candidate)
		check_ray.collision_mask = 1
		if space_state.intersect_ray(check_ray).is_empty():
			best_waypoint = candidate
			found_clear = true
			break

	return {
		"target_pos": best_waypoint if found_clear else final_pos,
		"final_slot": final_pos,
		"dir": facing_dir,
		"is_corner_waypoint": found_clear
	}


func play_iris_opening_transition() -> void:
	var transition_layer := get_node_or_null("TransitionLayer")
	var iris: ColorRect = transition_layer.get_node_or_null("IrisMask") as ColorRect if transition_layer else null
	if iris and (iris.material is ShaderMaterial):
		var mat := iris.material as ShaderMaterial
		mat.set_shader_parameter("center", Vector2(0.5, 0.5))
		mat.set_shader_parameter("radius", 0.0)
		mat.set_shader_parameter("softness", 0.015)

		# Tunggu inisialisasi engine dan scene stabil agar bebas dari frame-drop awal
		await get_tree().process_frame
		await get_tree().process_frame

		# Kunci posisi kamera langsung ke leader tanpa lag smoothing awal
		if is_instance_valid(camera):
			camera.reset_smoothing()

		# Jeda bernapas halus sebelum lingkaran mulai mekar
		await get_tree().create_timer(0.08).timeout

		# Buka circular mask dengan kurva sinusoidal alami (EASE_IN_OUT) yang sangat lembut
		var sfx_iris_open: AudioStream = load("res://assets/audio/sfx/ui/transition_iris_open.wav")
		if sfx_iris_open:
			var sfx_player := AudioStreamPlayer.new()
			sfx_player.stream = sfx_iris_open
			sfx_player.volume_db = -3.0
			add_child(sfx_player)
			sfx_player.finished.connect(sfx_player.queue_free)
			sfx_player.play()

		var tween := create_tween()
		tween.tween_property(mat, "shader_parameter/radius", 1.5, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
	else:
		await get_tree().process_frame

	# Hapus node transisi setelah selesai agar memori dan render pass bersih
	if is_instance_valid(transition_layer):
		transition_layer.queue_free()

	if not is_inside_tree():
		return

	# Munculkan banner lokasi sekali setelah arena terbuka pada kunjungan pertama
	if not visited_locations.has(current_location_name):
		enter_location(current_location_name)


# ==========================================
# SAVE & LOAD GAME SYSTEM (TASK 05C)
# ==========================================

func _on_hud_save_game_requested(slot_id: int) -> void:
	save_game_to_slot(slot_id)


func _on_hud_load_game_requested(slot_id: int) -> void:
	load_game_from_slot(slot_id)


func _on_hud_return_to_title_requested() -> void:
	get_tree().paused = false
	if gameplay_hud and is_instance_valid(gameplay_hud.pause_overlay):
		gameplay_hud.pause_overlay.visible = false
	get_tree().change_scene_to_file("res://scene/ui/menus/start_menu.tscn")


func save_game_to_slot(slot_id: int) -> bool:
	var path_tmp := "user://save_slot_%d.json.tmp" % slot_id
	var _path_final := "user://save_slot_%d.json" % slot_id

	var data := _collect_save_data(slot_id)
	var json_str := JSON.stringify(data, "\t")

	var f := FileAccess.open(path_tmp, FileAccess.WRITE)
	if not f:
		push_error("Gagal membuka file temporary save: " + path_tmp)
		return false
	f.store_string(json_str)
	f.close()

	var dir := DirAccess.open("user://")
	if dir:
		if dir.file_exists("save_slot_%d.json" % slot_id):
			dir.remove("save_slot_%d.json" % slot_id)
		var err := dir.rename("save_slot_%d.json.tmp" % slot_id, "save_slot_%d.json" % slot_id)
		if err != OK:
			push_error("Gagal rename save file: %d" % err)
			return false

	print("GAME SAVED: Slot %d | %s | %s" % [slot_id, data.get("chapter"), data.get("save_time_str")])
	if gameplay_hud and gameplay_hud.has_method("on_save_completed"):
		gameplay_hud.on_save_completed(slot_id, data)
	return true


func load_game_from_slot(slot_id: int) -> bool:
	var path := "user://save_slot_%d.json" % slot_id
	if not FileAccess.file_exists(path):
		push_error("File save tidak ditemukan: " + path)
		return false

	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		push_error("Gagal membuka file save: " + path)
		return false
	var text := f.get_as_text()
	f.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK or not (json.data is Dictionary):
		push_error("Data save rusak atau tidak valid pada Slot %d" % slot_id)
		return false

	var data: Dictionary = json.data
	if not data.has("party") or not data.has("chapter"):
		push_error("Struktur data save tidak lengkap pada Slot %d" % slot_id)
		return false

	# Restore Playtime
	total_playtime = float(data.get("playtime", 0.0))

	# Restore Party Order, Positions, Health
	var restored_party: Array[CharacterBody2D] = []
	for p_info in data.get("party", []):
		var char_name: String = p_info.get("name", "")
		for child in get_children():
			if child is CharacterBody2D and child.name == char_name:
				restored_party.append(child)
				if p_info.has("position"):
					var pos_dict: Dictionary = p_info["position"]
					child.global_position = Vector2(float(pos_dict.get("x", child.global_position.x)), float(pos_dict.get("y", child.global_position.y)))
				if "target_position" in child:
					child.target_position = child.global_position
				if "velocity" in child:
					child.velocity = Vector2.ZERO
				if "max_health" in child and p_info.has("max_hp"):
					child.max_health = int(p_info["max_hp"])
				if "current_health" in child and p_info.has("hp"):
					child.current_health = int(p_info["hp"])
				if "current_health" in child and "is_dead" in child:
					if child.current_health <= 0:
						child.is_dead = true
						child.visible = false
						child.modulate = Color(0.8, 0.2, 0.2, 0.0)
						if "collision_shape" in child and child.collision_shape:
							child.collision_shape.set_deferred("disabled", true)
						if child.has_node("Hurtbox/CollisionShape2D"):
							child.get_node("Hurtbox/CollisionShape2D").set_deferred("disabled", true)
					else:
						child.is_dead = false
						child.visible = true
						child.modulate = Color.WHITE
						if "collision_shape" in child and child.collision_shape:
							child.collision_shape.set_deferred("disabled", false)
						if child.has_node("Hurtbox/CollisionShape2D"):
							child.get_node("Hurtbox/CollisionShape2D").set_deferred("disabled", false)
						if not child.is_in_group("player"):
							child.add_to_group("player")
				if "skill_cooldown_timer" in child:
					child.skill_cooldown_timer = 0.0
				break

	if not restored_party.is_empty():
		party_members = restored_party

	# Restore Leader
	var lead_idx: int = clampi(int(data.get("active_leader_index", 0)), 0, party_members.size() - 1)
	set_active_leader(lead_idx)

	# Reset breadcrumbs and camera smoothing around restored leader position
	var leader := get_active_leader()
	if is_instance_valid(leader):
		breadcrumbs.clear()
		if is_instance_valid(camera):
			camera.reset_smoothing()

	# Restore Inventory
	if data.has("inventory_items") and data["inventory_items"] is Array:
		inventory_items = _deserialize_inventory(data["inventory_items"])

	# Restore Quests
	if data.has("quest_list") and data["quest_list"] is Array:
		quest_list = _deserialize_quests(data["quest_list"])
	if data.has("tracked_quest_id"):
		tracked_quest_id = str(data["tracked_quest_id"])

	# Restore Location & Visited History
	current_location_name = str(data.get("current_location_name", DEFAULT_START_LOCATION)).strip_edges()
	if current_location_name.is_empty():
		current_location_name = DEFAULT_START_LOCATION
	visited_locations.clear()
	if data.has("visited_locations") and data["visited_locations"] is Array:
		for v_loc in data["visited_locations"]:
			var loc_str := str(v_loc).strip_edges()
			if not loc_str.is_empty() and not visited_locations.has(loc_str):
				visited_locations.append(loc_str)
	else:
		visited_locations.append(current_location_name)

	# Sync HUD & Unpause
	get_tree().paused = false
	if gameplay_hud:
		if gameplay_hud.has_method("hide_location_banner"):
			gameplay_hud.hide_location_banner()
		gameplay_hud.setup(party_members, active_leader_index, inventory_items, quest_list)
		gameplay_hud.set_quests(quest_list, tracked_quest_id)
		var tracked_q: Dictionary = _get_quest_by_id(tracked_quest_id)
		if not tracked_q.is_empty():
			gameplay_hud.update_hud_quest_display(tracked_q)
		gameplay_hud.pause_overlay.visible = false
		gameplay_hud.on_load_completed(slot_id, data)

	if not visited_locations.has(current_location_name):
		enter_location(current_location_name)

	# Restore Arena State
	if data.has("arena_state"):
		var saved_arena_val: int = clampi(int(data["arena_state"]), 0, ArenaState.values().size() - 1)
		arena_state = ArenaState.values()[saved_arena_val]
		if arena_state == ArenaState.CLEARED:
			_set_arena_barrier_enabled(false)
			target_camera_zoom = CAMERA_ZOOM_EXPLORE
			is_camera_locked_to_arena = false
		elif arena_state == ArenaState.COMBAT:
			_set_arena_barrier_enabled(true)
			target_camera_zoom = CAMERA_ZOOM_ARENA
			is_camera_locked_to_arena = true

	# Sinkronisasi status HUD pertarungan sesuai arena_state dari save data
	if gameplay_hud and gameplay_hud.has_method("set_combat_hud_visible"):
		gameplay_hud.set_combat_hud_visible(arena_state == ArenaState.COMBAT, false)

	print("GAME LOADED: Slot %d | Leader: %s | HP: %d | Playtime: %f" % [slot_id, String(leader.name) if leader else "None", int(leader.current_health) if (leader and "current_health" in leader) else 0, total_playtime])
	return true


func _collect_save_data(slot_id: int) -> Dictionary:
	var party_data: Array = []
	for p in party_members:
		if is_instance_valid(p):
			var hp_val: int = 100
			var max_hp_val: int = 100
			if "current_health" in p:
				hp_val = p.current_health
			if "max_health" in p:
				max_hp_val = p.max_health
			party_data.append({
				"name": p.name,
				"hp": hp_val,
				"max_hp": max_hp_val,
				"position": {
					"x": p.global_position.x,
					"y": p.global_position.y
				}
			})

	var now_dict := Time.get_datetime_dict_from_system()
	const MONTH_NAMES_ID: Array[String] = [
		"", "Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
	]
	var month_idx: int = clampi(int(now_dict.get("month", 1)), 1, 12)
	var month_str: String = MONTH_NAMES_ID[month_idx]
	var time_str := "%d %s %d, %02d.%02d" % [
		now_dict.get("day", 1),
		month_str,
		now_dict.get("year", 2026),
		now_dict.get("hour", 0),
		now_dict.get("minute", 0)
	]

	var current_location: String = DEFAULT_START_LOCATION
	var cur_q := _get_quest_by_id(tracked_quest_id)
	if not cur_q.is_empty() and cur_q.get("location", "") != "":
		current_location = cur_q.get("location")
	elif not current_location_name.is_empty():
		current_location = current_location_name

	return {
		"slot_id": slot_id,
		"chapter": "Chapter 1.1",
		"arena_state": int(arena_state),
		"location": current_location,
		"current_location_name": current_location_name,
		"visited_locations": visited_locations.duplicate(),
		"playtime": total_playtime,
		"save_time_str": time_str,
		"timestamp": int(Time.get_unix_time_from_system()),
		"active_leader_index": active_leader_index,
		"party": party_data,
		"inventory_items": _serialize_inventory(inventory_items),
		"quest_list": _serialize_quests(quest_list),
		"tracked_quest_id": tracked_quest_id
	}


func _serialize_inventory(items: Array) -> Array:
	var out: Array = []
	for it in items:
		var d: Dictionary = it.duplicate(true)
		if d.has("icon_rect") and d["icon_rect"] is Rect2:
			var r: Rect2 = d["icon_rect"]
			d["icon_rect"] = [r.position.x, r.position.y, r.size.x, r.size.y]
		out.append(d)
	return out


func _deserialize_inventory(items: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for it in items:
		if not (it is Dictionary):
			continue
		var d: Dictionary = it.duplicate(true)
		if d.has("icon_rect"):
			if d["icon_rect"] is Array and d["icon_rect"].size() == 4:
				var a = d["icon_rect"]
				d["icon_rect"] = Rect2(a[0], a[1], a[2], a[3])
		out.append(d)
	return out


func _serialize_quests(quests: Array) -> Array:
	var out: Array = []
	for q in quests:
		var d: Dictionary = q.duplicate(true)
		if d.has("target_position") and d["target_position"] is Vector2:
			var v: Vector2 = d["target_position"]
			d["target_position"] = [v.x, v.y]
		out.append(d)
	return out


func _deserialize_quests(quests: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for q in quests:
		if not (q is Dictionary):
			continue
		var d: Dictionary = q.duplicate(true)
		if d.has("target_position"):
			if d["target_position"] is Array and d["target_position"].size() == 2:
				var a = d["target_position"]
				d["target_position"] = Vector2(a[0], a[1])
		out.append(d)
	return out


func _init_active_leader_indicator() -> void:
	"""Membuat node segitiga kecil di world space untuk menandai karakter aktif."""
	if _active_leader_indicator != null and is_instance_valid(_active_leader_indicator):
		return

	var indicator := Node2D.new()
	indicator.name = "ActiveLeaderIndicator"
	indicator.z_index = 10
	indicator.visible = false

	var outline := Polygon2D.new()
	outline.name = "TriangleOutline"
	outline.polygon = PackedVector2Array([
		Vector2(-13.0, -15.5),
		Vector2(13.0, -15.5),
		Vector2(0.0, 3.0)
	])
	outline.color = Color(0.11, 0.07, 0.08, 1.0)
	indicator.add_child(outline)

	var fill := Polygon2D.new()
	fill.name = "TriangleFill"
	fill.polygon = PackedVector2Array([
		Vector2(-10.0, -13.0),
		Vector2(10.0, -13.0),
		Vector2(0.0, 0.0)
	])
	fill.color = Color(1.0, 0.88, 0.36, 1.0)
	indicator.add_child(fill)

	add_child(indicator)
	_active_leader_indicator = indicator


func _get_leader_indicator_offset_y(leader: CharacterBody2D) -> float:
	"""Mengambil jarak vertikal ujung segitiga agar pas di atas kepala masing-masing karakter."""
	return float(HERO_INDICATOR_TIP_OFFSET_Y.get(leader.name, DEFAULT_INDICATOR_TIP_OFFSET_Y))


func _update_active_leader_indicator(delta: float) -> void:
	"""Menyinkronkan posisi, bobbing halus, dan visibilitas segitiga ke leader yang aktif."""
	if _active_leader_indicator == null or not is_instance_valid(_active_leader_indicator):
		return

	var leader := get_active_leader()
	if leader == null or not is_instance_valid(leader) or not is_character_alive(leader) or not leader.visible:
		_active_leader_indicator.visible = false
		return

	if delta > 0.0:
		_active_indicator_bob_time = fmod(_active_indicator_bob_time + delta * 4.5, TAU)

	var bob_offset: float = sin(_active_indicator_bob_time) * 3.5
	var base_tip_y: float = _get_leader_indicator_offset_y(leader)
	_active_leader_indicator.global_position = leader.global_position + Vector2(0.0, base_tip_y + bob_offset)
	_active_leader_indicator.visible = true
