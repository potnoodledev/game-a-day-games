
username = "";
level = 0;
points = 0;
prev_points = 0;

// Racing game state
game_active = true;
game_over = false;
road_scroll = 0;
game_speed = 4;          // initial obstacle speed
max_speed = 14;
speed_increment = 0.003; // speed increase per frame

// Lane system (3 lanes)
lane_count = 3;
current_lane = 1;        // 0=left, 1=center, 2=right

// Spawning
spawn_timer = 0;
spawn_rate = 50;         // frames between obstacles
min_spawn_rate = 18;
spawn_rate_decay = 0.02;

// Touch + swipe
touch_left = false;
touch_right = false;
touch_cooldown = 0;
swipe_start_x = -1;
swipe_start_y = -1;
swipe_active = false;
swipe_threshold = 30;  // min pixels for a swipe

// Road line animation
line_offset = 0;

api_load_state(function(_status, _ok, _result, _payload) {
	try {
		var _state = json_parse(_result);
		username = _state.username;
		level = _state.level;
		points = _state.data.points;
	}
	catch (_ex) {
		api_save_state(0, { points }, undefined);
	}
	alarm[0] = 60;
});

window_width = 0;
window_height = 0;
