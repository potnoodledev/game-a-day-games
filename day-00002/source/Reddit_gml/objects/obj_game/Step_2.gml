
// Camera: fixed center view
var _camera = view_camera[0];
var _w = window_get_width();
var _h = window_get_height();

if (surface_exists(application_surface)) {
    surface_resize(application_surface, _w, _h);
}

var _cx = _w * 0.5;
var _cy = _h * 0.5;
var _viewmat = matrix_build_lookat(_cx, _cy, -10, _cx, _cy, 0, 0, 1, 0);
camera_set_view_mat(_camera, _viewmat);

var _projmat = matrix_build_projection_ortho(_w, _h, 1.0, 32000.0);
camera_set_proj_mat(_camera, _projmat);
view_camera[0] = _camera;

// Game over: check restart
if (game_over) {
	if (mouse_check_button_pressed(mb_left)) {
		game_over = false;
		game_active = true;
		coins_caught = 0;
		coins_missed = 0;
		spawn_timer = 0;
		spawn_rate = 60;
		difficulty_timer = 0;
		fall_speed_base = 3;
		bomb_chance = 0.15;
		with (obj_coin) instance_destroy();
		with (obj_bomb) instance_destroy();
		with (obj_player) {
			x = _w * 0.5;
			y = _h - 60;
		}
	}
	exit;
}

if (!game_active) exit;

// Touch input
touch_left = false;
touch_right = false;
if (mouse_check_button(mb_left)) {
	var _mx = device_mouse_x_to_gui(0);
	if (_mx < _w * 0.4) touch_left = true;
	else if (_mx > _w * 0.6) touch_right = true;
}

// Spawn falling objects
spawn_timer++;
if (spawn_timer >= spawn_rate) {
	spawn_timer = 0;
	var _spawn_x = irandom_range(40, _w - 40);
	if (random(1) < bomb_chance) {
		var _b = instance_create_depth(_spawn_x, -32, 0, obj_bomb);
		_b.fall_speed = fall_speed_base + random(2);
	} else {
		var _c = instance_create_depth(_spawn_x, -32, 0, obj_coin);
		_c.fall_speed = fall_speed_base + random(2);
	}
}

// Difficulty ramp
difficulty_timer++;
if (difficulty_timer >= difficulty_interval) {
	difficulty_timer = 0;
	spawn_rate = max(min_spawn_rate, spawn_rate - 5);
	fall_speed_base = min(fall_speed_max, fall_speed_base + 0.3);
	bomb_chance = min(0.35, bomb_chance + 0.02);
}

// Game over check
if (coins_missed >= max_misses) {
	game_over = true;
	game_active = false;
	api_submit_score(points, undefined);
}
