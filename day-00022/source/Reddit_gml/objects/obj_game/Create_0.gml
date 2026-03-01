
username = "";
level = 0;
points = 0;
prev_points = 0;

// === GAME STATE ===
// 0=loading, 1=playing, 2=dead, 3=round_clear, 4=upgrade_select, 5=game_over
game_state = 0;

// === MAZE CONFIG ===
MAZE_W = 11;
MAZE_H = 15;
maze = array_create(MAZE_W * MAZE_H, 0);
dots = array_create(MAZE_W * MAZE_H, 0);

total_dots = 0;
dots_eaten = 0;

// === PLAYER STATE ===
// Tile-to-tile movement: gx/gy = current cell, progress = 0..1 toward next cell
pac_gx = 5;
pac_gy = 13;
pac_progress = 0; // 0 = at cell center, 0→1 = moving toward next cell in pac_dir
pac_dir = 0;      // 0=right,1=up,2=left,3=down
pac_next_dir = -1; // buffered direction from input
pac_moving = false;
pac_speed_mult = 1.0;
pac_mouth_angle = 0;
pac_mouth_dir = 1;

lives = 3;
round_num = 1;
invincible_timer = 0;

// === GHOST CONFIG ===
MAX_GHOSTS = 4;
ghost_gx = array_create(MAX_GHOSTS, 0);
ghost_gy = array_create(MAX_GHOSTS, 0);
ghost_progress = array_create(MAX_GHOSTS, 0);
ghost_dir = array_create(MAX_GHOSTS, 0);
ghost_type = array_create(MAX_GHOSTS, 0);
ghost_state = array_create(MAX_GHOSTS, 0); // 0=chase,1=scatter,2=frightened,3=eaten
ghost_active = array_create(MAX_GHOSTS, false);
ghost_speed_mult = 1.0;
ghost_slow_bonus = 0;
ghost_spawn_timer = array_create(MAX_GHOSTS, 0);
num_ghosts = 2;

ghost_colors = [make_colour_rgb(50, 200, 50), make_colour_rgb(180, 50, 200), make_colour_rgb(50, 180, 220), make_colour_rgb(220, 140, 30)];

// Chase/scatter
chase_timer = 0;
chase_phase = 0;
chase_durations = [7*60, 20*60, 7*60, 20*60, 5*60, 20*60, 5*60];
chase_phase_index = 0;

scatter_targets_x = [MAZE_W - 2, 1, MAZE_W - 2, 1];
scatter_targets_y = [1, 1, MAZE_H - 2, MAZE_H - 2];

// === POWER-UP STATE ===
fright_timer = 0;
fright_duration_base = 300;
fright_duration_bonus = 0;
speed_boost_timer = 0;
freeze_timer = 0;
ghost_eat_combo = 0;

// === UPGRADES ===
upgrade_choices = [0, 0];
upgrade_selected = -1;
magnet_range = 0;
wall_phase_count = 0;
wall_phase_max = 0;

// === SWIPE INPUT ===
touch_start_x = 0;
touch_start_y = 0;
touch_active = false;
SWIPE_THRESHOLD = 20;

// === RENDERING ===
knight_bob = 0;
cell_size = 0;
maze_offset_x = 0;
maze_offset_y = 0;

// === WINDOW ===
window_width = 0;
window_height = 0;

// Direction vectors: right, up, left, down
dir_dx = [1, 0, -1, 0];
dir_dy = [0, -1, 0, 1];

round_clear_timer = 0;
dead_timer = 0;
game_over_timer = 0;

// === LOAD STATE ===
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

randomize();
