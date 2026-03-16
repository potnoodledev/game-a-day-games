
username = "";
level = 0;
points = 0;
prev_points = 0;

// Game state: 0=title, 1=playing, 2=game over
game_state = 0;
state_timer = 0;
title_pulse = 0;

// Screen
window_width = 0;
window_height = 0;

// === GRID ===
grid_cols = 7;
grid_rows = 5;
grid_type = array_create(grid_cols * grid_rows, 0);
grid_hp = array_create(grid_cols * grid_rows, 0);
grid_hp_max = array_create(grid_cols * grid_rows, 0);
grid_shake_x = array_create(grid_cols * grid_rows, 0);
grid_shake_y = array_create(grid_cols * grid_rows, 0);
grid_braced = array_create(grid_cols * grid_rows, false);
grid_flash = array_create(grid_cols * grid_rows, 0);

// Building stats: [empty, house, apartment, tower]
build_hp =    [0, 3, 5, 8];
build_value = [0, 1, 3, 5];
build_names = ["", "House", "Apt", "Tower"];

// Fault proximity multiplier per column (distance from fault_col=3)
// col: 0=3away, 1=2away, 2=1away, 3=on fault, 4=1away, 5=2away, 6=3away
// Multipliers: on fault=3x, adjacent=2x, 2away=1.5x, edge=1x
fault_mult = [1.0, 1.5, 2.0, 3.0, 2.0, 1.5, 1.0];

// === FAULT LINE ===
fault_col = 3;
fault_width = 0.3;

// === EARTHQUAKES ===
quake_active = false;
quake_timer = 0;
quake_duration = 90;
quake_intensity = 0;
quake_epicenter_col = 3;
quake_number = 0;
next_quake = 360;
quake_interval = 600;
quake_shake_x = 0;
quake_shake_y = 0;
quake_wave_x = -1;
quake_wave_speed = 6;
quake_warning_dir = 0; // -1=left, 0=center, 1=right

// === AFTERSHOCKS ===
aftershock_queue = 0;     // number of aftershocks remaining
aftershock_timer = 0;     // frames until next aftershock
aftershock_intensity = 0; // base intensity for aftershocks

// === GAME TIMER ===
game_timer = 60 * 60;
game_timer_max = 60 * 60;

// === INCOME (cumulative scoring) ===
income = 0;          // points earned per income tick
income_timer = 0;    // counts up, ticks every 60 frames (1 sec)
income_accumulated = 0; // total points from income this game

// === BUILD MODE ===
build_selection = 1;

// === BRACING ===
brace_target = -1;

// === POPULATION ===
population = 0;

// === FX: debris ===
max_debris = 50;
debris_x = array_create(max_debris, 0);
debris_y = array_create(max_debris, 0);
debris_vx = array_create(max_debris, 0);
debris_vy = array_create(max_debris, 0);
debris_age = array_create(max_debris, -1);
debris_col = array_create(max_debris, c_white);
debris_next = 0;

// === FX: cracks ===
max_cracks = 30;
crack_x1 = array_create(max_cracks, 0);
crack_y1 = array_create(max_cracks, 0);
crack_x2 = array_create(max_cracks, 0);
crack_y2 = array_create(max_cracks, 0);
crack_age = array_create(max_cracks, -1);
crack_next = 0;

// === FX: ripple rings from tap ===
max_ripples = 6;
ripple_x = array_create(max_ripples, 0);
ripple_y = array_create(max_ripples, 0);
ripple_age = array_create(max_ripples, -1);
ripple_next = 0;

// === FX: income float text ===
max_floats = 10;
float_x = array_create(max_floats, 0);
float_y = array_create(max_floats, 0);
float_text = array_create(max_floats, "");
float_age = array_create(max_floats, -1);
float_next = 0;

// === TOUCH ===
touch_pressed = false;
touch_released = false;
prev_touch = false;

// Warning
warning_timer = 0;

// Repair flash
repair_flash = array_create(grid_cols * grid_rows, 0);

// Upgrade indicator
grid_upgrade_ready = array_create(grid_cols * grid_rows, false);

// Load state
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
