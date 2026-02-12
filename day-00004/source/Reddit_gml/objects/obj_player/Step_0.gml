
// Only move when game is playing
if (!instance_exists(obj_game)) exit;
if (obj_game.game_state != 1) exit;

// Apply gravity
vy += gravity_force;
if (vy > max_fall_speed) vy = max_fall_speed;

// Move
y += vy;

// Tilt based on velocity
if (vy < 0) {
    target_angle = 25;  // tilt up when flapping
} else {
    target_angle = -min(vy * 8, 70);  // tilt down when falling
}
image_angle += (target_angle - image_angle) * 0.15;

// Check collision with pipes
if (place_meeting(x, y, obj_pipe)) {
    with (obj_game) {
        game_die();
    }
}

// Check floor/ceiling (using game's screen bounds)
var _screen_h = obj_game.screen_h;
var _screen_top = 0;
var _screen_bottom = _screen_h;

if (y + 16 > _screen_bottom || y - 16 < _screen_top) {
    // Clamp position
    y = clamp(y, _screen_top + 16, _screen_bottom - 16);
    with (obj_game) {
        game_die();
    }
}
