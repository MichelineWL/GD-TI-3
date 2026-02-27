# Tutorial 3 – Latihan Mandiri: Eksplorasi Mekanika Pergerakan

## Ikhtisar

Pada latihan mandiri ini, dikembangkan tiga fitur mekanika pergerakan lanjutan dengan karakter pemain menggunakan sprite **Female** dari paket aset Kenney Platform Characters.

Tiga fitur yang diimplementasikan:

| Fitur | Tombol | Deskripsi |
|---|---|---|
| **Double Jump** | `↑` (dua kali) | Karakter dapat melompat sekali lagi di udara |
| **Dashing** | `←←` atau `→→` (double-tap) | Karakter bergerak sangat cepat sebentar ke satu arah |
| **Crouching** | `↓` (tahan) | Karakter jongkok dengan sprite berbeda dan kecepatan lebih lambat |

**Bonus polishing**:
- Sprite karakter **membalik horizontal** sesuai arah gerak (kiri/kanan)
- **Sprite berganti otomatis** sesuai state: idle, berjalan (animasi walk cycle), lompat, jatuh, jongkok, dan dash
---

## Penjelasan Implementasi

### 1. Double Jump

**Ide dasar:** Karakter diperbolehkan melompat maksimal dua kali sebelum mendarat kembali.

**Implementasi:**

```gdscript
var jump_count: int = 0
var max_jumps: int = 2

func _handle_jump() -> void:
    if Input.is_action_just_pressed("ui_up"):
        if is_on_floor():
            velocity.y = jump_speed
            jump_count = 1
        elif jump_count < max_jumps:
            velocity.y = jump_speed
            jump_count += 1

# Reset saat mendarat:
if is_on_floor():
    jump_count = 0
```

- Saat karakter berada di lantai dan menekan `↑`, `jump_count` diset ke `1`.
- Saat karakter di udara dan `jump_count < max_jumps`, karakter masih bisa melompat sekali lagi (double jump).
- `jump_count` direset ke `0` ketika `is_on_floor()` bernilai `true`.

**Referensi:** Godot Docs – [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)

---

### 2. Dashing

**Ide dasar:** Karakter melakukan gerakan cepat horizontal selama durasi singkat ketika pemain menekan tombol arah yang sama dua kali dalam waktu singkat (*double-tap*).

**Implementasi:**

```gdscript
@export var dash_speed: float = 600.0       # kecepatan saat dash
@export var dash_duration: float = 0.18     # lama dash (detik)
@export var dash_cooldown: float = 0.6      # jeda sebelum bisa dash lagi
@export var double_tap_window: float = 0.25 # jendela waktu double-tap

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var last_left_tap: float = -1.0
var last_right_tap: float = -1.0

func _handle_horizontal() -> void:
    var time_now: float = Time.get_ticks_msec() / 1000.0

    if Input.is_action_just_pressed("ui_left"):
        if time_now - last_left_tap < double_tap_window and dash_cooldown_timer <= 0.0:
            _start_dash(-1.0)
        last_left_tap = time_now

    if Input.is_action_just_pressed("ui_right"):
        if time_now - last_right_tap < double_tap_window and dash_cooldown_timer <= 0.0:
            _start_dash(1.0)
        last_right_tap = time_now

func _start_dash(direction: float) -> void:
    is_dashing = true
    dash_direction = direction
    dash_timer = dash_duration
    dash_cooldown_timer = dash_cooldown
    velocity.y = 0  # tidak terpengaruh gravitasi saat dash
```

- Waktu tekan tombol dicatat menggunakan `Time.get_ticks_msec()`.
- Bila selisih waktu antara dua tekanan `< double_tap_window`, dash akan dimulai.
- Selama dash, `velocity.x` dikunci ke `dash_speed * direction` dan gravitasi tidak diterapkan, untuk efek gerakan lurus.
- `dash_cooldown_timer` mencegah dash spam.

**Referensi:**
- Godot Docs – [Time.get_ticks_msec()](https://docs.godotengine.org/en/stable/classes/class_time.html#class-time-method-get-ticks-msec)
- Game Mechanic Explorer – Dash (double tap): https://gamemechanicexplorer.com/

---

### 3. Crouching

**Ide dasar:** Ketika pemain menahan tombol `↓` dan karakter berada di lantai, karakter jongkok dengan sprite `female_duck.png` dan kecepatan yang lebih lambat.

**Implementasi:**

```gdscript
@export var crouch_speed: int = 80  # kecepatan saat jongkok

var is_crouching: bool = false

func _handle_crouch() -> void:
    is_crouching = Input.is_action_pressed("ui_down") and is_on_floor()

# Dalam _handle_horizontal():
var speed: int = crouch_speed if is_crouching else walk_speed
```

- `is_crouching` hanya aktif bila karakter menyentuh lantai (tidak bisa jongkok di udara).
- Kecepatan gerak horizontal dikurangi menjadi `crouch_speed` saat jongkok.
- Sprite otomatis berganti ke `female_duck.png`.

**Referensi:** Kenney.nl Platform Character Pack – https://kenney.nl/assets/platformer-characters-1

---

### 4. Polishing: Sprite Flip & State-Based Sprite

**Sprite Flip (menghadap arah gerak):**

```gdscript
if velocity.x < 0:
    sprite.flip_h = true   # menghadap kiri
elif velocity.x > 0:
    sprite.flip_h = false  # menghadap kanan
```

**State-Based Sprite Animation:**

| State | Kondisi | Texture |
|---|---|---|
| Idle | Di lantai, diam | `female_idle.png` |
| Walk | Di lantai, bergerak | `female_walk1.png` / `female_walk2.png` bergantian |
| Jump | Di udara, `velocity.y < 0` | `female_jump.png` |
| Fall | Di udara, `velocity.y >= 0` | `female_fall.png` |
| Duck | Jongkok | `female_duck.png` |
| Dash | Sedang dash | `female_walk2.png` |

Walk cycle diimplementasikan dengan timer sederhana:

```gdscript
const WALK_ANIM_SPEED: float = 0.15  # detik per frame
var walk_anim_timer: float = 0.0
var walk_anim_frame: int = 0

# Dalam _update_sprite():
walk_anim_timer += delta
if walk_anim_timer >= WALK_ANIM_SPEED:
    walk_anim_timer = 0.0
    walk_anim_frame = (walk_anim_frame + 1) % 2
sprite.texture = tex_walk1 if walk_anim_frame == 0 else tex_walk2
```

---

## Aset yang Digunakan

- **Kenney Platform Characters** oleh Kenney.nl (CC0 / Public Domain)  
  https://kenney.nl/assets/platformer-characters-1
  - `female_idle.png`
  - `female_walk1.png`, `female_walk2.png`
  - `female_jump.png`
  - `female_fall.png`
  - `female_duck.png`

---

## Referensi

1. Godot Engine Documentation – CharacterBody2D:  
   https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html

2. Godot Engine Documentation – Time.get_ticks_msec():  
   https://docs.godotengine.org/en/stable/classes/class_time.html#class-time-method-get-ticks-msec

3. Godot Engine Documentation – Sprite2D (flip_h):  
   https://docs.godotengine.org/en/stable/classes/class_sprite2d.html

4. Kenney.nl – Platformer Characters Pack 1:  
   https://kenney.nl/assets/platformer-characters-1

5. Game Developer – Double Jump Implementation Patterns:  
   https://www.gamedeveloper.com/design/double-jumping-in-platform-games

6. Game Mechanic Explorer:  
   https://gamemechanicexplorer.com/
