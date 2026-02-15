
username = "";
level = 0;
points = 0;       // best run score (persisted to leaderboard)
prev_points = 0;

// Game state: 0=waiting, 1=playing, 2=dead
game_state = 0;

// Player
player_lane = 1;          // 0=left, 1=center, 2=right
player_target_lane = 1;
player_x = 0;
player_target_x = 0;

// Speed & distance
base_speed = 5;
game_speed = base_speed;
distance = 0;
session_score = 0;
coin_score = 0;

// Obstacles: array of structs {lane, y, type}
obstacles = [];
obstacle_timer = 0;
obstacle_interval = 90;
min_obstacle_interval = 40;

// Coins: array of structs {lane, y}
coins = [];
coin_timer = 0;
coin_interval = 90;

// Touch / swipe
touch_down = false;
touch_sx = 0;
touch_sy = 0;
swipe_threshold = 30;

// Jump
jumping = false;
jump_timer = 0;
jump_duration = 24;
jump_offset = 0;       // visual y offset (negative = up)

// Train riding
on_train = false;
riding_train = undefined;
dismount_grace = 0;       // invincibility frames after dismount

// Falling (smooth drop after dismount)
falling = false;
fall_y = 0;               // offset from ground (negative = above)
fall_speed = 0;

// Visual
scroll_offset = 0;

// Window
window_width = 0;
window_height = 0;

api_load_state(function(_status, _ok, _result, _payload) {
	try {
		var _state = json_parse(_result);
		username = _state.username;
		level = _state.level;
		points = _state.data.points;
	}
	catch (_ex) {
		api_save_state(0, { points: 0 }, undefined);
	}
	alarm[0] = 60;
});
