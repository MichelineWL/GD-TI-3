extends CharacterBody2D

# ─── Movement Parameters ───────────────────────────────────────────────────────
@export var gravity: float = 200.0
@export var walk_speed: int = 200
@export var jump_speed: float = -300.0
@export var crouch_speed: int = 80          # speed while crouching
@export var dash_speed: float = 600.0       # horizontal speed during dash
@export var dash_duration: float = 0.3      # seconds the dash lasts
@export var dash_cooldown: float = 0.6      # seconds before next dash allowed
@export var double_tap_window: float = 0.25 # seconds between two taps to trigger dash

# ─── Double-Jump State ─────────────────────────────────────────────────────────
var jump_count: int = 0
var max_jumps: int = 2

# ─── Dash State ────────────────────────────────────────────────────────────────
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: float = 0.0

# Double-tap detection
var last_left_tap: float = -1.0
var last_right_tap: float = -1.0

# ─── Crouch State ──────────────────────────────────────────────────────────────
var is_crouching: bool = false

# ─── Animation Reference ───────────────────────────────────────────────────────
# Using a flexible reference to handle different possible node names in the tutorial
@onready var animplayer: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	if animplayer == null:
		animplayer = get_node_or_null("AnimatedSprite")
	
	if animplayer == null:
		push_warning("AnimatedSprite2D node not found! Please check your scene tree.")

func _physics_process(delta: float) -> void:
	_handle_dash_timers(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_crouch()
	_detect_dash()

	if is_dashing:
		velocity.x = dash_direction * dash_speed
	else:
		_handle_horizontal()

	move_and_slide()

	if is_on_floor():
		jump_count = 0

	_update_animation()

# ─── Gravity ───────────────────────────────────────────────────────────────────
func _apply_gravity(delta: float) -> void:
	if not is_dashing:
		velocity.y += delta * gravity

# ─── Jump (Double Jump) ────────────────────────────────────────────────────────
func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = jump_speed
			jump_count = 1
		elif jump_count < max_jumps:
			velocity.y = jump_speed
			jump_count += 1

# ─── Crouch ────────────────────────────────────────────────────────────────────
func _handle_crouch() -> void:
	is_crouching = Input.is_action_pressed("ui_down") and is_on_floor()

# ─── Dash Detection (double-tap) ─────────────────────────────────────────────
func _detect_dash() -> void:
	var time_now: float = Time.get_ticks_msec() / 1000.0

	if Input.is_action_just_pressed("ui_left"):
		if time_now - last_left_tap < double_tap_window and dash_cooldown_timer <= 0.0:
			_start_dash(-1.0)
		last_left_tap = time_now

	if Input.is_action_just_pressed("ui_right"):
		if time_now - last_right_tap < double_tap_window and dash_cooldown_timer <= 0.0:
			_start_dash(1.0)
		last_right_tap = time_now

# ─── Horizontal Movement ──────────────────────────────────────────────────────
func _handle_horizontal() -> void:
	var speed: int = crouch_speed if is_crouching else walk_speed

	if Input.is_action_pressed("ui_left"):
		velocity.x = -speed
	elif Input.is_action_pressed("ui_right"):
		velocity.x = speed
	else:
		velocity.x = 0

# ─── Dash ──────────────────────────────────────────────────────────────────────
func _start_dash(direction: float) -> void:
	is_dashing = true
	dash_direction = direction
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	velocity.y = 0

func _handle_dash_timers(delta: float) -> void:
	if dash_timer > 0.0:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

# ─── Animation Update ──────────────────────────────────────────────────────────
func _update_animation() -> void:
	if animplayer == null:
		return

	if velocity.x < 0:
		animplayer.flip_h = true
	elif velocity.x > 0:
		animplayer.flip_h = false

	var animation_name = "idle"
	
	if is_crouching:
		animation_name = "duck"
	elif is_dashing:
		animation_name = "walk right"
	elif not is_on_floor():
		if velocity.y < 0:
			animation_name = "jump"
		else:
			animation_name = "fall"
	elif abs(velocity.x) > 0:
		animation_name = "walk right"
	else:
		animation_name = "idle"

	if animplayer.animation != animation_name:
		if animplayer.sprite_frames.has_animation(animation_name):
			animplayer.play(animation_name)
		else:
			# Safety fallback logic
			if abs(velocity.x) > 0:
				animplayer.play("walk right")
			else:
				animplayer.play("idle")
