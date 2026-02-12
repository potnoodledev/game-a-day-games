
// Camera setup (fixed, no follow — road is drawn procedurally)
var _camera = view_camera[0];
var _w = window_get_width();
var _h = window_get_height();

if (surface_exists(application_surface)) {
    surface_resize(application_surface, _w, _h);
}

var _viewmat = matrix_build_lookat(_w * 0.5, _h * 0.5, -10, _w * 0.5, _h * 0.5, 0, 0, 1, 0);
camera_set_view_mat(_camera, _viewmat);
var _projmat = matrix_build_projection_ortho(_w, _h, 1.0, 32000.0);
camera_set_proj_mat(_camera, _projmat);
view_camera[0] = _camera;

// Game over — tap to restart
if (game_over) {
    if (mouse_check_button_pressed(mb_left)) {
        game_over = false;
        game_active = true;
        game_speed = 4;
        spawn_rate = 50;
        current_lane = 1;
        with (obj_obstacle) instance_destroy();
    }
    exit;
}

if (!game_active) exit;

// Road dimensions
var _road_w = _w * 0.6;
var _road_x = (_w - _road_w) * 0.5;
var _lane_w = _road_w / lane_count;

// Input: touch tap, swipe, and keyboard
touch_left = false;
touch_right = false;
if (touch_cooldown > 0) touch_cooldown--;

// Swipe detection: track touch start → end
if (mouse_check_button_pressed(mb_left)) {
    swipe_start_x = device_mouse_x_to_gui(0);
    swipe_start_y = device_mouse_y_to_gui(0);
    swipe_active = true;
}

if (mouse_check_button_released(mb_left) && swipe_active) {
    swipe_active = false;
    var _end_x = device_mouse_x_to_gui(0);
    var _end_y = device_mouse_y_to_gui(0);
    var _dx = _end_x - swipe_start_x;
    var _dy = _end_y - swipe_start_y;

    // Horizontal swipe (must be more horizontal than vertical)
    if (abs(_dx) > swipe_threshold && abs(_dx) > abs(_dy) && touch_cooldown <= 0) {
        if (_dx < 0) {
            touch_left = true;
        } else {
            touch_right = true;
        }
        touch_cooldown = 8;
    }
    // Short tap — use zone-based input (fallback)
    else if (abs(_dx) < 15 && abs(_dy) < 15 && touch_cooldown <= 0) {
        var _mx = swipe_start_x;
        if (_mx < _w * 0.4) {
            touch_left = true;
            touch_cooldown = 8;
        } else if (_mx > _w * 0.6) {
            touch_right = true;
            touch_cooldown = 8;
        }
    }
}

// Keyboard input
if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) {
    touch_left = true;
}
if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) {
    touch_right = true;
}

// Switch lanes
if (touch_left && current_lane > 0) current_lane--;
if (touch_right && current_lane < lane_count - 1) current_lane++;

// Position player in lane
if (instance_exists(obj_player)) {
    var _target_x = _road_x + _lane_w * current_lane + _lane_w * 0.5;
    obj_player.x += ((_target_x) - obj_player.x) * 0.3;
    obj_player.y = _h - 100;
}

// Increase speed
game_speed = min(max_speed, game_speed + speed_increment);
spawn_rate = max(min_spawn_rate, spawn_rate - spawn_rate_decay);

// Scroll road lines
line_offset += game_speed;

// Score = distance
points += 1;

// Spawn obstacles
spawn_timer++;
if (spawn_timer >= spawn_rate) {
    spawn_timer = 0;
    var _lane = irandom(lane_count - 1);
    var _obs = instance_create_depth(
        _road_x + _lane_w * _lane + _lane_w * 0.5,
        -64,
        0,
        obj_obstacle
    );
    _obs.fall_speed = game_speed;
    _obs.lane = _lane;
}

// Check collisions with obstacles
if (instance_exists(obj_player)) {
    with (obj_obstacle) {
        if (instance_exists(obj_player)) {
            var _dx = abs(x - obj_player.x);
            var _dy = abs(y - obj_player.y);
            if (_dx < 36 && _dy < 48) {
                with (obj_game) {
                    game_over = true;
                    game_active = false;
                    api_submit_score(points, undefined);
                }
            }
        }
    }
}

// Clean up off-screen obstacles
with (obj_obstacle) {
    if (y > _h + 80) instance_destroy();
}
