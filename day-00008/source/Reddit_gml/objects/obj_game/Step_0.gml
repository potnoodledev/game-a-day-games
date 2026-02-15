
var _w = window_get_width();
var _h = window_get_height();
window_width = _w;
window_height = _h;

if (_w <= 0 || _h <= 0) exit;

var _lane_w = _w / 3;
var _lc0 = _lane_w * 0.5;
var _lc1 = _lane_w * 1.5;
var _lc2 = _lane_w * 2.5;
var _targets = array_create(3);
_targets[0] = _lc0;
_targets[1] = _lc1;
_targets[2] = _lc2;

// === WAITING STATE ===
if (game_state == 0) {
	if (mouse_check_button_pressed(mb_left)) {
		game_state = 1;
		player_lane = 1;
		player_target_lane = 1;
		player_x = _lc1;
		player_target_x = _lc1;
		game_speed = base_speed;
		distance = 0;
		session_score = 0;
		coin_score = 0;
		obstacles = [];
		coins = [];
		obstacle_timer = 40;
		coin_timer = 25;
		jumping = false;
		jump_timer = 0;
		jump_offset = 0;
		on_train = false;
		riding_train = undefined;
		dismount_grace = 0;
		falling = false;
		fall_y = 0;
		fall_speed = 0;
		touch_down = false;
	}
	exit;
}

// === DEAD STATE ===
if (game_state == 2) {
	if (mouse_check_button_pressed(mb_left)) {
		game_state = 0;
	}
	exit;
}

// === PLAYING STATE ===

// --- SWIPE / TAP DETECTION ---
var _swipe_dir = -1;  // -1=none, 0=left, 1=right, 2=up

if (mouse_check_button_pressed(mb_left)) {
	touch_down = true;
	touch_sx = device_mouse_x_to_gui(0);
	touch_sy = device_mouse_y_to_gui(0);
}

// --- KEYBOARD (WASD) ---
if (keyboard_check_pressed(ord("A"))) _swipe_dir = 0;
if (keyboard_check_pressed(ord("D"))) _swipe_dir = 1;
if (keyboard_check_pressed(ord("W"))) _swipe_dir = 2;
if (keyboard_check_pressed(vk_left))  _swipe_dir = 0;
if (keyboard_check_pressed(vk_right)) _swipe_dir = 1;
if (keyboard_check_pressed(vk_up))    _swipe_dir = 2;

if (mouse_check_button_released(mb_left) && touch_down) {
	touch_down = false;
	var _ex = device_mouse_x_to_gui(0);
	var _ey = device_mouse_y_to_gui(0);
	var _dx = _ex - touch_sx;
	var _dy = _ey - touch_sy;

	if (abs(_dx) > swipe_threshold || abs(_dy) > swipe_threshold) {
		if (abs(_dx) > abs(_dy)) {
			if (_dx < 0) _swipe_dir = 0; else _swipe_dir = 1;
		} else {
			if (_dy < 0) _swipe_dir = 2;
			// swipe down = ignore
		}
	} else {
		// Short tap: left/right by position
		if (touch_sx < _w * 0.5) _swipe_dir = 0; else _swipe_dir = 1;
	}
}

// --- GRACE TIMER ---
if (dismount_grace > 0) dismount_grace -= 1;

// --- APPLY INPUT ---
if (_swipe_dir == 0) {
	// Left
	if (on_train) {
		falling = true; fall_y = -_lane_w * 0.2; fall_speed = 0;
		on_train = false; riding_train = undefined; dismount_grace = 15;
	}
	if (player_target_lane > 0) player_target_lane -= 1;
}
else if (_swipe_dir == 1) {
	// Right
	if (on_train) {
		falling = true; fall_y = -_lane_w * 0.2; fall_speed = 0;
		on_train = false; riding_train = undefined; dismount_grace = 15;
	}
	if (player_target_lane < 2) player_target_lane += 1;
}
else if (_swipe_dir == 2) {
	// Jump
	if (on_train) {
		on_train = false;
		riding_train = undefined;
		dismount_grace = 15;
		jumping = true;
		jump_timer = jump_duration;
	} else if (!jumping) {
		jumping = true;
		jump_timer = jump_duration;
	}
}

// --- MOVEMENT ---
player_target_x = _targets[player_target_lane];
player_x = lerp(player_x, player_target_x, 0.2);

// --- JUMP ARC ---
var _jump_ending = false;
if (jumping) {
	jump_timer -= 1;
	var _t = 1 - (jump_timer / jump_duration);
	jump_offset = -sin(_t * pi) * _h * 0.18;
	if (jump_timer <= 0) {
		// Don't end jump yet — collision check needs to run first
		// so we can land on trains instead of dying
		_jump_ending = true;
	}
}

// --- TRAIN RIDING ---
var _ground_y = _h * 0.82;
var _ride_y = _ground_y - _lane_w * 0.2;  // slight elevation when on train
if (on_train && riding_train != undefined) {
	var _train_oh = _lane_w * 2.5;
	var _train_top = riding_train.y - _train_oh * 0.5;
	// Dismount only when the train top has cleared below the player's feet at ground level
	if (_train_top > _ground_y + _lane_w * 0.3) {
		on_train = false;
		riding_train = undefined;
		dismount_grace = 15;
		falling = true;
		fall_y = -_lane_w * 0.2;  // start at ride elevation
		fall_speed = 0;
	}
}

// --- FALLING (after dismount) ---
if (falling) {
	fall_speed += 0.8;  // gravity
	fall_y += fall_speed;
	if (fall_y >= 0) {
		fall_y = 0;
		fall_speed = 0;
		falling = false;
	}
}

// --- SCROLL & SCORING ---
scroll_offset += game_speed;
if (scroll_offset >= 60) scroll_offset -= 60;

distance += game_speed;
session_score = floor(distance / 50) + coin_score;

game_speed = base_speed + floor(distance / 1000) * 0.5;
if (game_speed > 14) game_speed = 14;

obstacle_interval = max(min_obstacle_interval, 90 - floor(distance / 600) * 3);

// === SPAWN OBSTACLES ===
obstacle_timer -= 1;
if (obstacle_timer <= 0) {
	obstacle_timer = obstacle_interval + irandom(20);

	var _num = 1;
	if (distance > 2000 && irandom(3) == 0) _num = 2;

	var _used = array_create(3, false);
	for (var _i = 0; _i < _num; _i++) {
		var _lane = irandom(2);
		var _tries = 0;
		while (_used[_lane] && _tries < 5) {
			_lane = irandom(2);
			_tries++;
		}
		if (!_used[_lane]) {
			_used[_lane] = true;
			var _obs = {};
			_obs.lane = _lane;
			_obs.type = irandom(1);
			if (_obs.type == 1) _obs.y = -_lane_w * 5; else _obs.y = -100;
			array_push(obstacles, _obs);
		}
	}
}

// === SPAWN COINS (waves of 5-10) ===
coin_timer -= 1;
if (coin_timer <= 0) {
	coin_timer = coin_interval + irandom(60);
	var _wave_count = 5 + irandom(5);  // 5 to 10
	var _coin_lane = irandom(2);
	var _coin_spacing = 55;
	// Sometimes spawn on a lane that has a train (riding bonus)
	for (var _ci = 0; _ci < _wave_count; _ci++) {
		var _coin = {};
		_coin.lane = _coin_lane;
		_coin.y = -40 - (_ci * _coin_spacing);
		array_push(coins, _coin);
	}
}

// === MOVE OBSTACLES ===
for (var _i = 0; _i < array_length(obstacles); _i++) {
	obstacles[_i].y += game_speed;
}

// === MOVE COINS ===
for (var _i = 0; _i < array_length(coins); _i++) {
	coins[_i].y += game_speed;
}

// === COLLISION ===
var _pw = _lane_w * 0.35;
var _ph = _lane_w * 0.45;

// Determine player effective y
var _eff_y = _ground_y;
if (on_train) {
	_eff_y = _ride_y;
} else if (falling) {
	_eff_y = _ground_y + fall_y;  // fall_y is negative (above ground), approaches 0
}
_eff_y += jump_offset;

var _px1 = player_x - _pw * 0.5;
var _px2 = player_x + _pw * 0.5;
var _py1 = _eff_y - _ph * 0.5;
var _py2 = _eff_y + _ph * 0.5;

var _dead = false;
var _landed_train = undefined;

for (var _i = 0; _i < array_length(obstacles); _i++) {
	var _o = obstacles[_i];

	// Skip the train we're riding
	if (on_train && riding_train == _o) continue;

	var _ow = _lane_w * 0.4;
	var _oh = _lane_w * 0.5;
	if (_o.type == 1) _oh = _lane_w * 2.5;  // streetcars are long trains

	var _ox = _targets[_o.lane];
	var _ox1 = _ox - _ow * 0.5;
	var _ox2 = _ox + _ow * 0.5;
	var _oy1 = _o.y - _oh * 0.5;
	var _oy2 = _o.y + _oh * 0.5;

	// Horizontal overlap?
	if (_px1 >= _ox2 || _px2 <= _ox1) continue;

	if (jumping && _o.type == 1) {
		// Only land near the very end of the jump (last 15%)
		var _t = 1 - (jump_timer / jump_duration);
		if (_t > 0.85 && _o.y > 0 && _o.y < _h) {
			_landed_train = _o;
		}
		continue;  // airborne — skip collision either way
	}

	if (jumping) {
		// Jumping over barriers
		continue;
	}

	// Ground-level collision (skip during dismount grace)
	if (dismount_grace > 0) continue;

	if (_py1 < _oy2 && _py2 > _oy1) {
		_dead = true;
		break;
	}
}

// Handle landing on a streetcar
if (_landed_train != undefined && !_dead) {
	on_train = true;
	riding_train = _landed_train;
	jumping = false;
	jump_timer = 0;
	jump_offset = 0;
	// Snap to the train's lane
	player_target_lane = _landed_train.lane;
	player_target_x = _targets[player_target_lane];
	player_x = player_target_x;
}

// Finalize jump ending (deferred from arc section)
if (_jump_ending && !on_train) {
	jumping = false;
	jump_offset = 0;
}

if (_dead) {
	if (session_score > points) {
		points = session_score;
	}
	game_state = 2;
	api_submit_score(points, undefined);
	exit;
}

// === COLLISION: COINS ===
var _new_coins = [];
for (var _i = 0; _i < array_length(coins); _i++) {
	var _c = coins[_i];
	if (_c.y > _h + 50) continue;

	var _cx = _targets[_c.lane];
	var _cr = _lane_w * 0.1;
	var _dx = abs(player_x - _cx);
	var _dy = abs(_eff_y - _c.y);

	if (_dx < _pw * 0.5 + _cr && _dy < _ph * 0.5 + _cr) {
		coin_score += 10;
		continue;
	}
	array_push(_new_coins, _c);
}
coins = _new_coins;

// === CLEANUP OFF-SCREEN OBSTACLES ===
var _new_obs = [];
for (var _i = 0; _i < array_length(obstacles); _i++) {
	var _o = obstacles[_i];
	if (_o.y <= _h + 100) {
		array_push(_new_obs, _o);
	} else if (on_train && riding_train == _o) {
		// Train we're on went off screen — dismount
		on_train = false;
		riding_train = undefined;
		dismount_grace = 15;
	}
}
obstacles = _new_obs;
