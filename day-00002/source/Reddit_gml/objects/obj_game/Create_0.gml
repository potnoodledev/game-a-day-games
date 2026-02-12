
username = "";
level = 0;
points = 0;
prev_points = 0;

// Coin Rain game state
game_active = true;
game_over = false;
spawn_timer = 0;
spawn_rate = 60; // frames between spawns (starts at 1 per second)
min_spawn_rate = 10;
difficulty_timer = 0;
difficulty_interval = 300; // ramp up every 5 seconds
coins_caught = 0;
coins_missed = 0;
max_misses = 5;
bomb_chance = 0.15;
fall_speed_base = 3;
fall_speed_max = 10;

// Touch controls
touch_left = false;
touch_right = false;

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
