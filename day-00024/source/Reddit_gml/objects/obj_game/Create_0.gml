
username = "";
level = 0;
points = 0;
prev_points = 0;

// Game states: 0=loading, 1=title, 2=playing, 3=meeting, 4=result, 5=game_over
game_state = 0;

// Round / lives
round_num = 1;
lives = 3;
max_lives = 3;
streak = 0;

// Timer
round_timer = 0;
round_timer_max = 600; // 20s at 30fps

// Window
ww = 0;
hh = 0;

// Map layout — rooms as normalized [x, y, w, h]
room_count = 5;
room_name[0] = "CAFETERIA";
room_name[1] = "ELECTRICAL";
room_name[2] = "MEDBAY";
room_name[3] = "NAVIGATION";
room_name[4] = "SECURITY";

room_nx[0] = 0.30; room_ny[0] = 0.25; room_nw[0] = 0.40; room_nh[0] = 0.22;
room_nx[1] = 0.05; room_ny[1] = 0.12; room_nw[1] = 0.22; room_nh[1] = 0.22;
room_nx[2] = 0.73; room_ny[2] = 0.12; room_nw[2] = 0.22; room_nh[2] = 0.22;
room_nx[3] = 0.05; room_ny[3] = 0.58; room_nw[3] = 0.22; room_nh[3] = 0.22;
room_nx[4] = 0.73; room_ny[4] = 0.58; room_nw[4] = 0.22; room_nh[4] = 0.22;

// Corridors [room_a, room_b]
corridor_count = 6;
corr_a[0] = 0; corr_b[0] = 1;
corr_a[1] = 0; corr_b[1] = 2;
corr_a[2] = 0; corr_b[2] = 3;
corr_a[3] = 0; corr_b[3] = 4;
corr_a[4] = 1; corr_b[4] = 3;
corr_a[5] = 2; corr_b[5] = 4;

// Task stations — 2 per room
task_count = 10;
for (var _i = 0; _i < task_count; _i++) {
    task_room[_i] = _i div 2;
    task_occupied[_i] = -1;
}
task_lx[0] = 0.25; task_ly[0] = 0.25;
task_lx[1] = 0.75; task_ly[1] = 0.75;
task_lx[2] = 0.3;  task_ly[2] = 0.25;
task_lx[3] = 0.7;  task_ly[3] = 0.75;
task_lx[4] = 0.3;  task_ly[4] = 0.25;
task_lx[5] = 0.7;  task_ly[5] = 0.75;
task_lx[6] = 0.3;  task_ly[6] = 0.25;
task_lx[7] = 0.7;  task_ly[7] = 0.75;
task_lx[8] = 0.3;  task_ly[8] = 0.25;
task_lx[9] = 0.7;  task_ly[9] = 0.75;

// Vent locations — one per side room
vent_count = 4;
vent_room[0] = 1; vent_lx[0] = 0.5; vent_ly[0] = 0.5;
vent_room[1] = 2; vent_lx[1] = 0.5; vent_ly[1] = 0.5;
vent_room[2] = 3; vent_lx[2] = 0.5; vent_ly[2] = 0.5;
vent_room[3] = 4; vent_lx[3] = 0.5; vent_ly[3] = 0.5;

// Crewmate arrays (max 8)
crew_max = 8;
crew_count = 4;
impostor_id = 0;

crew_palette[0] = make_colour_rgb(197, 17, 17);   // Red
crew_palette[1] = make_colour_rgb(19, 46, 210);    // Blue
crew_palette[2] = make_colour_rgb(17, 128, 45);    // Green
crew_palette[3] = make_colour_rgb(237, 84, 186);   // Pink
crew_palette[4] = make_colour_rgb(240, 125, 13);   // Orange
crew_palette[5] = make_colour_rgb(246, 246, 87);   // Yellow
crew_palette[6] = make_colour_rgb(63, 71, 78);     // Black (dark grey)
crew_palette[7] = make_colour_rgb(215, 225, 241);  // White

for (var _i = 0; _i < crew_max; _i++) {
    crew_x[_i] = 0;
    crew_y[_i] = 0;
    crew_tx[_i] = 0;
    crew_ty[_i] = 0;
    crew_room_id[_i] = 0;
    crew_alive[_i] = true;
    crew_spd[_i] = 0;
    crew_ai[_i] = "idle";
    crew_ai_timer[_i] = 0;
    crew_task_progress[_i] = 0;
    crew_task_target[_i] = -1;
    crew_bobble[_i] = 0;
}

// Impostor specifics
imp_kill_cd = 0;
imp_kill_cd_max = 300;
imp_stalk_target = -1;
imp_near_vent = false;

// Kill animation
kill_active = false;
kill_timer = 0;
kill_x = 0;
kill_y = 0;
kill_victim = -1;

// Meeting animation
meeting_timer = 0;
meeting_duration = 90;
meeting_result = 0; // 1=correct, -1=wrong
meeting_accused = -1;
meeting_flash = 0;

// Result screen
result_timer = 0;
result_duration = 90;

// Title
title_pulse = 0;

// Touch
touch_active = false;

// Score popup
score_popup = "";
score_popup_timer = 0;

// Colors
col_space = make_colour_rgb(10, 10, 30);
col_wall = make_colour_rgb(50, 55, 70);
col_floor = make_colour_rgb(90, 100, 120);
col_corridor = make_colour_rgb(70, 80, 100);
col_task = make_colour_rgb(255, 230, 80);
col_vent = make_colour_rgb(60, 60, 60);
col_visor = make_colour_rgb(150, 210, 255);
col_danger = make_colour_rgb(200, 30, 30);
col_safe = make_colour_rgb(30, 200, 60);

// Play area offset (leave top for HUD)
play_ox = 0;
play_oy = 0;
play_w = 0;
play_h = 0;

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
        if (variable_struct_exists(_state.data, "streak")) {
            streak = _state.data.streak;
        }
    }
    catch (_ex) {
        api_save_state(0, { points: points, round_num: round_num, lives: lives, streak: streak }, undefined);
    }
    game_state = 1;
    alarm[0] = 60;
});
