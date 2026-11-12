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

