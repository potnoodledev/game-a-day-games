/// Day 16: Balancing Act — Physics Puzzle (Wave System)

username = "";
level = 0;
points = 0;
prev_points = 0;

// Game state: 0=loading, 1=wave_intro, 2=playing, 3=holding, 4=wave_clear, 5=game_over
game_state = 0;

// Beam physics
beam_angle = 0;
beam_angular_vel = 0;

// Layout (recalculated in Step_2)
beam_cx = 0;
beam_cy = 0;
beam_half = 200;
beam_thickness = 20;
fulcrum_h = 60;
unit_size = 40;

// Physics tuning
torque_factor = 0.00012;
phys_damping = 0.982;
slide_factor = 0.004;
max_angle = 0.85;       // ~49 deg, tip threshold
warning_angle = 0.35;   // ~20 deg, danger zone
combo_safe = 0.26;      // ~15 deg, combo threshold

// Wave system
wave = 1;
wave_shapes = [];        // shapes for current wave (array of structs)
wave_index = 0;          // next shape to place from wave_shapes
total_placed = 0;        // lifetime total

// Hold phase
hold_timer = 0;
hold_duration = 180;     // 3 seconds at 60fps

// Intro / clear timers
intro_timer = 0;
clear_timer = 0;

// Combo / multiplier
combo = 0;
multiplier = 1;

// Objects on beam
objects_on_beam = [];

// Falling objects (cosmetic)
falling_objects = [];

// Dropping object state
drop_active = false;
drop_type_idx = 0;
drop_weight = 0;
drop_x = 0;
drop_y = 0;
drop_target_x_off = 0;
drop_speed = 0;

// Score popups
score_popups = [];

// Tip animation timer
tip_timer = 0;

// Wind
wind_timer = 300;
wind_force = 0;

// Screen
window_width = 0;
window_height = 0;

// Object colors
obj_colors = [
    make_color_rgb(68, 136, 220),   // 0: box - blue
    make_color_rgb(68, 180, 102),   // 1: plank - green
    make_color_rgb(230, 150, 30),   // 2: column - orange
    make_color_rgb(210, 68, 68),    // 3: ball - red
    make_color_rgb(130, 130, 140),  // 4: anvil - gray
];

// Object type configs (parallel arrays)
obj_cfg_weight =    [2.0, 3.0, 1.5, 2.0, 4.0];
obj_cfg_slide =     [1.0, 1.0, 1.0, 2.0, 1.0];
obj_cfg_color_idx = [0,   1,   2,   3,   4  ];
obj_cfg_label =     ["BOX", "PLNK", "COL", "BALL", "ANVL"];
obj_cfg_w_mult =    [1.0, 1.8, 0.6, 0.9, 0.7];
obj_cfg_h_mult =    [1.0, 0.7, 1.5, 0.9, 0.7];

// Load saved state
api_load_state(function(_status, _ok, _result, _payload) {
    try {
        var _state = json_parse(_result);
        username = _state.username;
        level = _state.level;
        var _d = _state.data;
        if (variable_struct_exists(_d, "points")) points = _d.points;
        if (variable_struct_exists(_d, "wave")) wave = _d.wave;
        if (variable_struct_exists(_d, "total_placed")) total_placed = _d.total_placed;
    }
    catch (_ex) {
        api_save_state(0, { points: 0, wave: 1, total_placed: 0 }, undefined);
    }

    if (wave < 1) wave = 1;

    // Start with wave intro
    game_state = 1;
    intro_timer = 120;

    // Generate shapes for current wave
    wave_shapes = [];
    wave_index = 0;

    // Wave config: count and available types
    var _count = min(2 + wave, 12);
    var _max_type = 1;  // just boxes
    if (wave >= 2) _max_type = 2;  // + planks
    if (wave >= 3) _max_type = 3;  // + columns
    if (wave >= 4) _max_type = 4;  // + balls
    if (wave >= 6) _max_type = 5;  // + anvils

    var _weight_var = 0.2 + wave * 0.05;
    for (var _i = 0; _i < _count; _i++) {
        var _tidx = irandom(_max_type - 1);
        var _wvar = random_range(-_weight_var, _weight_var);
        array_push(wave_shapes, {
            type_idx: _tidx,
            weight: max(0.5, obj_cfg_weight[_tidx] + _wvar),
        });
    }

    alarm[0] = 60;
});
