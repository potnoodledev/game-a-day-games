
username = "";
level = 0;
points = 0;
prev_points = 0;

// Game states: 0=loading, 1=title, 2=running, 3=battle, 4=result, 5=game over
game_state = 0;

// Round / lives
round_num = 1;
lives = 3;
max_lives = 3;

// Army
troops = 10;
start_troops = 10;

// Enemy
enemy_troops = 0;

// Gate system (max 12 pairs per round)
gate_max = 12;
for (var _i = 0; _i < gate_max; _i++) {
    gate_left_op[_i] = 0;   // 0=add, 1=sub, 2=mul, 3=div
    gate_left_val[_i] = 0;
    gate_right_op[_i] = 0;
    gate_right_val[_i] = 0;
    gate_y[_i] = 0;
    gate_passed[_i] = false;
    gate_choice[_i] = -1;   // -1=not chosen, 0=left, 1=right
}
gate_count = 0;
current_gate = 0;

// Scrolling
scroll_y = 0;
scroll_speed = 2;
gate_spacing = 250;

// Swipe input
touch_start_x = 0;
touch_start_y = 0;
touch_active = false;
swipe_threshold = 40;
pending_swipe = 0;  // -1=left, 0=none, 1=right (persists until consumed)

// Battle animation
battle_timer = 0;
battle_duration = 90;
battle_result = 0;  // 1=win, -1=lose
battle_clash_x = 0;
battle_clash_y = 0;

// Result screen timer
result_timer = 0;
result_duration = 120;

// Title screen animation
title_pulse = 0;
title_stars_timer = 0;

// Garish colors
col_neon_pink = make_colour_rgb(255, 16, 240);
col_neon_green = make_colour_rgb(0, 255, 64);
col_neon_yellow = make_colour_rgb(255, 255, 0);
col_neon_cyan = make_colour_rgb(0, 255, 255);
col_neon_orange = make_colour_rgb(255, 160, 0);
col_deep_red = make_colour_rgb(200, 0, 0);
col_gate_good = make_colour_rgb(0, 200, 50);
col_gate_bad = make_colour_rgb(200, 30, 30);

// Fake ad UI
fake_progress = 0;
fake_progress_target = 0;

// Score popup
score_popup = "";
score_popup_timer = 0;

// Operator symbols
op_symbols[0] = "+";
op_symbols[1] = "-";
op_symbols[2] = "x";
op_symbols[3] = "/";

// Background hue cycle
bg_hue = 0;

// Road lane stripes animation
stripe_offset = 0;

// Army blob particles (visual flair)
blob_count = 20;
for (var _i = 0; _i < blob_count; _i++) {
    blob_x[_i] = random_range(-30, 30);
    blob_y[_i] = random_range(-30, 30);
    blob_r[_i] = random_range(4, 10);
    blob_spd[_i] = random_range(0.3, 1.0);
    blob_col[_i] = choose(c_lime, c_green, c_yellow, c_aqua);
}

// Window size cache
window_width = 0;
window_height = 0;

// Load state
api_load_state(function(_status, _ok, _result, _payload) {
    try {
        var _state = json_parse(_result);
        username = _state.username;
        level = _state.level;
        points = _state.data.points;
        if (variable_struct_exists(_state.data, "round_num")) {
            round_num = _state.data.round_num;
        }
        if (variable_struct_exists(_state.data, "lives")) {
            lives = _state.data.lives;
        }
    }
    catch (_ex) {
        api_save_state(0, { points: points, round_num: round_num, lives: lives }, undefined);
    }
    game_state = 1;
    alarm[0] = 60;
});
