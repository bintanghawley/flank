extends Node

const CURSOR_NORMAL: Texture2D = preload("res://assets/ui/icons/cursor/cursor.png")
const CURSOR_PRESSED: Texture2D = preload("res://assets/ui/icons/cursor/cursor_pressed.png")
const CURSOR_HOTSPOT: Vector2 = Vector2(1, 1)
const MIN_CLICK_HOLD_TIME: float = 0.08

var _is_pressed: bool = false
var _release_tween: Tween = null
var _ripple_layer: CanvasLayer = null

class ClickRipple extends Control:
	var radius: float = 4.0:
		set(val):
			radius = val
			queue_redraw()
	var ring_width: float = 2.4:
		set(val):
			ring_width = val
			queue_redraw()
	var ring_color: Color = Color.WHITE:
		set(val):
			ring_color = val
			queue_redraw()
	var fill_color: Color = Color.TRANSPARENT:
		set(val):
			fill_color = val
			queue_redraw()

	func _draw() -> void:
		if ring_color.a <= 0.001 and fill_color.a <= 0.001:
			return
		# 1. Piringan bayangan & pendar warna inti lembut
		if fill_color.a > 0.001:
			draw_circle(Vector2.ZERO, radius * 0.82, fill_color)
		# 2. Cincin gelombang luar dengan animasi gradasi warna aktif
		if ring_color.a > 0.001:
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, ring_color, ring_width, true)

class GroundMoveIndicator extends Node2D:
	var progress: float = 0.0:
		set(val):
			progress = val
			queue_redraw()
	var alpha: float = 1.0:
		set(val):
			alpha = val
			queue_redraw()

	const CHEVRON_START_DIST: float = 24.0
	const CHEVRON_END_DIST: float = 5.0
	const CHEVRON_ARM: float = 8.0
	const COLOR_MAIN: Color = Color(0.05, 0.95, 1.0) # Neon Electric Cyan
	const COLOR_CORE: Color = Color(0.85, 0.98, 1.0) # Bright Ice White-Cyan Glow

	func _draw() -> void:
		if alpha <= 0.001:
			return

		var col_main := Color(COLOR_MAIN.r, COLOR_MAIN.g, COLOR_MAIN.b, alpha)
		var col_core := Color(COLOR_CORE.r, COLOR_CORE.g, COLOR_CORE.b, alpha)
		var current_dist := lerpf(CHEVRON_START_DIST, CHEVRON_END_DIST, progress)

		# 1. Cincin pulsa tengah khas Dota 2 (mengembang dan menipis cepat)
		var ring_radius := lerpf(3.0, 14.0, progress)
		var ring_alpha := (1.0 - progress) * alpha * 0.75
		if ring_alpha > 0.01:
			var ring_col := Color(COLOR_MAIN.r, COLOR_MAIN.g, COLOR_MAIN.b, ring_alpha)
			draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 28, ring_col, 1.4, true)

		# 2. Titik inti tengah
		var dot_alpha := (1.0 - progress * 0.6) * alpha
		if dot_alpha > 0.01:
			draw_circle(Vector2(0.0, 1.0), 2.5, Color(0.01, 0.08, 0.18, dot_alpha * 0.6))
			draw_circle(Vector2.ZERO, 2.0, Color(COLOR_CORE.r, COLOR_CORE.g, COLOR_CORE.b, dot_alpha))

		# 3. 4 Chevron Panah Konvergen (Dota 2 style: 4 arah yang menunjuk lurus ke pusat)
		var directions: Array[Vector2] = [
			Vector2(0, -1), # Atas -> menunjuk ke bawah
			Vector2(0, 1),  # Bawah -> menunjuk ke atas
			Vector2(1, 0),  # Kanan -> menunjuk ke kiri
			Vector2(-1, 0)  # Kiri -> menunjuk ke kanan
		]

		for dir in directions:
			var norm := Vector2(-dir.y, dir.x)
			var tip := dir * current_dist

			# Sayap panah membentang ke belakang menjauhi pusat
			var wing_l := tip + (dir * CHEVRON_ARM) + (norm * CHEVRON_ARM * 0.7)
			var wing_r := tip + (dir * CHEVRON_ARM) - (norm * CHEVRON_ARM * 0.7)

			# Drop shadow gelap di bawah garis panah (1.5 px ke bawah) agar tajam di semua background
			var col_shadow := Color(0.01, 0.08, 0.18, alpha * 0.75)
			var pts_shadow := PackedVector2Array([
				wing_l + Vector2(0.0, 1.5),
				tip + Vector2(0.0, 1.5),
				wing_r + Vector2(0.0, 1.5)
			])
			draw_polyline(pts_shadow, col_shadow, 2.6, true)

			# Garis utama cyan neon
			var pts_main := PackedVector2Array([wing_l, tip, wing_r])
			draw_polyline(pts_main, col_main, 1.8, true)

			# Highlight putih di ujung tip panah
			draw_circle(tip, 1.2, col_core)

func _ready() -> void:
	# Tetap memproses input kursor meskipun scene tree dalam keadaan paused (Pause Menu)
	process_mode = Node.PROCESS_MODE_ALWAYS as Node.ProcessMode
	
	# Layer paling atas untuk menampilkan efek riak lingkaran klik tanpa tertutup UI/HUD
	_ripple_layer = CanvasLayer.new()
	_ripple_layer.layer = 125
	_ripple_layer.process_mode = Node.PROCESS_MODE_ALWAYS as Node.ProcessMode
	add_child(_ripple_layer)
	
	_apply_cursor(false)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_set_pressed_state(true)
				_spawn_click_ripple(event.position, event.button_index)
			else:
				var still_down: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
				if not still_down:
					_schedule_release()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_set_pressed_state(false)

func _set_pressed_state(pressed: bool) -> void:
	if _release_tween and _release_tween.is_valid():
		_release_tween.kill()
	if _is_pressed != pressed:
		_is_pressed = pressed
		_apply_cursor(_is_pressed)

func _schedule_release() -> void:
	if _release_tween and _release_tween.is_valid():
		_release_tween.kill()
	_release_tween = create_tween()
	_release_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS as Tween.TweenPauseMode)
	_release_tween.tween_interval(MIN_CLICK_HOLD_TIME)
	_release_tween.tween_callback(func():
		var still_down: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		if not still_down:
			_set_pressed_state(false)
	)

func _apply_cursor(is_pressed: bool) -> void:
	var tex: Texture2D = CURSOR_PRESSED if is_pressed else CURSOR_NORMAL
	# Tetapkan kursor kustom untuk panah default (ARROW) dan kursor tombol (POINTING_HAND)
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW as Input.CursorShape, CURSOR_HOTSPOT)
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_POINTING_HAND as Input.CursorShape, CURSOR_HOTSPOT)

func _spawn_click_ripple(click_pos: Vector2, button_index: int) -> void:
	if not _ripple_layer or not is_instance_valid(_ripple_layer):
		return

	# Jika klik kanan di scene Game gameplay, visual indikator dipusatkan pada koordinat dunia (ground)
	if button_index == MOUSE_BUTTON_RIGHT:
		var cur_scene := get_tree().current_scene
		if cur_scene and cur_scene.name == "Game":
			return
	
	var ripple := ClickRipple.new()
	# Pusatkan lingkaran bayangan tepat pada ujung panah kursor yang telah bergerak maju ke depan
	ripple.position = click_pos - CURSOR_HOTSPOT
	ripple.mouse_filter = Control.MOUSE_FILTER_IGNORE as Control.MouseFilter
	ripple.process_mode = Node.PROCESS_MODE_ALWAYS as Node.ProcessMode
	
	_ripple_layer.add_child(ripple)
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS as Tween.TweenPauseMode)
	
	# Dinamika ekspansi lingkaran dan penipisan garis
	tween.tween_property(ripple, "radius", 26.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ripple, "ring_width", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Animasi gradasi warna aktif saat klik
	if button_index == MOUSE_BUTTON_RIGHT:
		# Klik Kanan: Kilau Putih-Cyan terang -> Cyan Langit elektrik -> Biru Azure transparan
		ripple.ring_color = Color(0.88, 1.0, 1.0, 0.98)
		ripple.fill_color = Color(0.35, 0.85, 1.0, 0.40)
		tween.tween_property(ripple, "ring_color", Color(0.10, 0.45, 0.95, 0.0), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(ripple, "fill_color", Color(0.05, 0.10, 0.18, 0.0), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		# Klik Kiri: Kilau Putih-Emas berkilau -> Kuning Emas tajam -> Amber / Bayangan hangat transparan
		ripple.ring_color = Color(1.0, 1.0, 0.88, 0.98)
		ripple.fill_color = Color(1.0, 0.85, 0.35, 0.45)
		tween.tween_property(ripple, "ring_color", Color(0.92, 0.45, 0.10, 0.0), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(ripple, "fill_color", Color(0.15, 0.08, 0.03, 0.0), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.chain().tween_callback(ripple.queue_free)


func spawn_ground_move_indicator(world_pos: Vector2) -> void:
	var cur_scene := get_tree().current_scene
	if not cur_scene or not is_instance_valid(cur_scene):
		return

	var indicator := GroundMoveIndicator.new()
	indicator.global_position = world_pos
	indicator.z_as_relative = false
	indicator.z_index = 2 # Di atas lantai/bayangan, di bawah tubuh karakter (z_index 4)
	indicator.process_mode = Node.PROCESS_MODE_PAUSABLE as Node.ProcessMode
	cur_scene.add_child(indicator)

	var tween: Tween = indicator.create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND as Tween.TweenPauseMode)
	# Ke-4 chevron panah hijau mengunci ke pusat (inward collapse) dalam ~0.26 detik ala Dota 2
	tween.tween_property(indicator, "progress", 1.0, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(indicator, "alpha", 0.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(indicator.queue_free)


func update_ground_move_indicator(_world_pos: Vector2) -> void:
	pass


func hide_ground_move_indicator() -> void:
	pass

