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

# ─── Sprite References ─────────────────────────────────────────────────────────
@onready var sprite: Sprite2D = $Sprite2D

# Sprite textures for each state
var tex_idle: Texture2D
var tex_walk1: Texture2D
var tex_walk2: Texture2D
var tex_jump: Texture2D
var tex_fall: Texture2D
var tex_duck: Texture2D

# Walk animation
var walk_anim_timer: float = 0.0
var walk_anim_frame: int = 0
const WALK_ANIM_SPEED: float = 0.15  # seconds per frame

func _ready() -> void:
	tex_idle  = load("res://assets/kenney_platformercharacters/PNG/Female/Poses/female_idle.png")
	tex_walk1 = load("res://assets/kenney_platformercharacters/PNG/Female/Poses/female_walk1.png")
	tex_walk2 = load("res://assets/kenney_platformercharacters/PNG/Female/Poses/female_walk2.png")
	tex_jump  = load("res://assets/kenney_platformercharacters/PNG/Female/Poses/female_jump.png")
	tex_fall  = load("res://assets/kenney_platformercharacters/PNG/Female/Poses/female_fall.png")
	tex_duck  = load("res://assets/kenney_platformercharacters/PNG/Female/Poses/female_duck.png")


func _physics_process(delta: float) -> void:
	_handle_dash_timers(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_crouch()
	_detect_dash()  # selalu cek double-tap, bahkan saat sedang dash

	if is_dashing:
		velocity.x = dash_direction * dash_speed
	else:
		_handle_horizontal()

	move_and_slide()

	# Reset jump count when landing
	if is_on_floor():
		jump_count = 0

	_update_sprite(delta)


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
	velocity.y = 0  # neutralize gravity during dash


func _handle_dash_timers(delta: float) -> void:
	if dash_timer > 0.0:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta


# ─── Sprite Update ─────────────────────────────────────────────────────────────
func _update_sprite(delta: float) -> void:
	# Flip sprite based on horizontal direction
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

	# Determine and apply sprite state
	if is_crouching:
		sprite.texture = tex_duck
	elif is_dashing:
		# Use walk1 or walk2 alternating quickly to give a "dash blur" feel
		sprite.texture = tex_walk2
	elif not is_on_floor():
		if velocity.y < 0:
			sprite.texture = tex_jump
		else:
			sprite.texture = tex_fall
	elif abs(velocity.x) > 0:
		# Animate walk cycle
		walk_anim_timer += delta
		if walk_anim_timer >= WALK_ANIM_SPEED:
			walk_anim_timer = 0.0
			walk_anim_frame = (walk_anim_frame + 1) % 2
		sprite.texture = tex_walk1 if walk_anim_frame == 0 else tex_walk2
	else:
		sprite.texture = tex_idle
		walk_anim_timer = 0.0
