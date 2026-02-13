
username = "";
level = 0;
points = 0;
prev_points = 0;

// Game state: 0=title, 1=playing, 2=game_over, 3=wave_summary
game_state = 0;

// Lives
lives = 3;
max_lives = 3;

// Combo streak
combo = 0;

// Difficulty (driven by wave number)
difficulty = 0;
customers_served = 0;

// Wave system
wave = 1;
wave_total = 3;           // customers to spawn this wave
wave_spawned = 0;          // how many spawned so far
wave_served = 0;           // served this wave (for summary)
wave_lost = 0;             // lost this wave (for summary)
wave_points_start = 0;     // points at wave start (to calc earnings)

// Table upgrades
tables_unlocked = 1;       // starts at 1, max 6
table_cost = 20;           // cost of next table (escalates: 20 * tables_unlocked)

// Seats per table (1-4 each)
table_seats = array_create(6, 1);
table_seats[0] = 2;  // first table starts with 2 seats

// Spawn timer
spawn_timer = 0;
spawn_interval = 180; // frames between spawns (decreases with difficulty)

// Tap cooldown to prevent double-taps
tap_cooldown = 0;

// Customer queue (waiting to be seated)
queue_food = array_create(5, 0);
queue_avatar = array_create(5, 0);
queue_patience = array_create(5, 0);
queue_max_patience = array_create(5, 0);
queue_count = 0;
queue_max = 5;
selected_queue = -1;

// 6 tables, 4 seats each (2D arrays)
// States: 0=empty, 1=waiting_order, 2=in_kitchen, 3=eating, 4=ready_to_pay
for (var _i = 0; _i < 6; _i++) {
    table_state[_i] = array_create(4, 0);
    table_food[_i] = array_create(4, 0);
    table_patience[_i] = array_create(4, 0);
    table_max_patience[_i] = array_create(4, 0);
    table_eat_timer[_i] = array_create(4, 0);
    table_avatar[_i] = array_create(4, 0);
}

// 2 kitchen slots
kitchen_occupied = array_create(2, false);
kitchen_table = array_create(2, -1);
kitchen_seat = array_create(2, -1);
kitchen_food = array_create(2, 0);
kitchen_cook_time = array_create(2, 0);
kitchen_progress = array_create(2, 0);

// Food colors (4 noodle types)
food_colors = [
    make_colour_rgb(220, 70, 50),   // 0: ramen (red-orange)
    make_colour_rgb(80, 170, 60),   // 1: pho (green)
    make_colour_rgb(70, 130, 210),  // 2: udon (blue)
    make_colour_rgb(245, 200, 80),  // 3: mochi (golden)
];

// Bowl colors (darker version for bowl body)
bowl_colors = [
    make_colour_rgb(180, 50, 35),   // 0: ramen bowl
    make_colour_rgb(55, 120, 40),   // 1: pho bowl
    make_colour_rgb(50, 95, 160),   // 2: udon bowl
    make_colour_rgb(200, 160, 55),  // 3: mochi plate
];

/// @function draw_food(_x, _y, _r, _type)
/// @desc Draws a noodle food icon centered at (_x, _y) with radius _r
function draw_food(_x, _y, _r, _type) {
    var _fc = food_colors[_type];
    var _bc = bowl_colors[_type];

    if (_type == 0) {
        // Ramen: bowl + wavy noodles + egg
        draw_set_colour(_bc);
        draw_roundrect(_x - _r, _y - _r * 0.3, _x + _r, _y + _r * 0.8, false);
        draw_set_colour(_fc);
        draw_roundrect(_x - _r, _y - _r * 0.5, _x + _r, _y + _r * 0.1, false);
        // Noodle squiggles
        draw_set_colour(make_colour_rgb(255, 230, 170));
        draw_line_width(_x - _r * 0.5, _y - _r * 0.1, _x, _y + _r * 0.2, max(1, _r * 0.12));
        draw_line_width(_x, _y + _r * 0.2, _x + _r * 0.5, _y - _r * 0.1, max(1, _r * 0.12));
        // Egg
        draw_set_colour(c_white);
        draw_circle(_x + _r * 0.35, _y - _r * 0.15, _r * 0.22, false);
        draw_set_colour(make_colour_rgb(255, 180, 50));
        draw_circle(_x + _r * 0.35, _y - _r * 0.15, _r * 0.12, false);
    }
    else if (_type == 1) {
        // Pho: bowl + herbs + lime wedge
        draw_set_colour(_bc);
        draw_roundrect(_x - _r, _y - _r * 0.3, _x + _r, _y + _r * 0.8, false);
        draw_set_colour(make_colour_rgb(200, 190, 160));
        draw_roundrect(_x - _r * 0.8, _y - _r * 0.4, _x + _r * 0.8, _y + _r * 0.0, false);
        // Herb leaves
        draw_set_colour(_fc);
        draw_circle(_x - _r * 0.3, _y - _r * 0.3, _r * 0.2, false);
        draw_circle(_x + _r * 0.1, _y - _r * 0.35, _r * 0.18, false);
        // Lime wedge
        draw_set_colour(make_colour_rgb(180, 220, 50));
        draw_circle(_x + _r * 0.5, _y - _r * 0.2, _r * 0.18, false);
    }
    else if (_type == 2) {
        // Udon: bowl + thick noodles
        draw_set_colour(_bc);
        draw_roundrect(_x - _r, _y - _r * 0.3, _x + _r, _y + _r * 0.8, false);
        draw_set_colour(make_colour_rgb(180, 200, 230));
        draw_roundrect(_x - _r * 0.8, _y - _r * 0.4, _x + _r * 0.8, _y + _r * 0.0, false);
        // Thick white noodles
        draw_set_colour(make_colour_rgb(245, 240, 220));
        draw_line_width(_x - _r * 0.4, _y - _r * 0.25, _x + _r * 0.2, _y + _r * 0.15, max(2, _r * 0.18));
        draw_line_width(_x - _r * 0.1, _y - _r * 0.3, _x + _r * 0.5, _y + _r * 0.1, max(2, _r * 0.18));
        // Naruto
        draw_set_colour(make_colour_rgb(255, 140, 160));
        draw_circle(_x - _r * 0.3, _y - _r * 0.15, _r * 0.16, false);
    }
    else {
        // Mochi: round pastel ball with face
        draw_set_colour(_fc);
        draw_circle(_x, _y, _r * 0.7, false);
        // Cute face
        draw_set_colour(make_colour_rgb(80, 60, 40));
        draw_circle(_x - _r * 0.2, _y - _r * 0.1, _r * 0.08, false);
        draw_circle(_x + _r * 0.2, _y - _r * 0.1, _r * 0.08, false);
        // Smile
        draw_set_colour(make_colour_rgb(180, 100, 80));
        draw_rectangle(_x - _r * 0.12, _y + _r * 0.15, _x + _r * 0.12, _y + _r * 0.22, false);
    }
};

// Floating text particles
fx_max = 16;
fx_count = 0;
fx_x = array_create(fx_max, 0);
fx_y = array_create(fx_max, 0);
fx_text = array_create(fx_max, "");
fx_life = array_create(fx_max, 0);
fx_max_life = array_create(fx_max, 0);
fx_col = array_create(fx_max, c_white);

/// @function spawn_float_text(_x, _y, _txt, _color, _duration)
function spawn_float_text(_px, _py, _txt, _color, _duration) {
    var _idx = fx_count mod fx_max;
    fx_x[_idx] = _px;
    fx_y[_idx] = _py;
    fx_text[_idx] = _txt;
    fx_life[_idx] = _duration;
    fx_max_life[_idx] = _duration;
    fx_col[_idx] = _color;
    fx_count++;
}

// Screen shake
shake_amount = 0;

// Avatar palettes
skin_colors = [
    make_colour_rgb(255, 219, 172), // light
    make_colour_rgb(234, 185, 139), // medium-light
    make_colour_rgb(198, 134, 88),  // medium
    make_colour_rgb(141, 85, 54),   // medium-dark
    make_colour_rgb(87, 57, 40),    // dark
];
hair_colors = [
    make_colour_rgb(40, 30, 20),    // black
    make_colour_rgb(120, 70, 30),   // brown
    make_colour_rgb(220, 180, 60),  // blonde
    make_colour_rgb(180, 50, 30),   // red
    make_colour_rgb(100, 100, 110), // gray
    make_colour_rgb(60, 100, 180),  // blue (fun)
];

/// @function draw_avatar(_x, _y, _r, _seed)
/// @desc Draws a procedural avatar centered at (_x, _y) with radius _r
function draw_avatar(_x, _y, _r, _seed) {
    var _skin_idx = _seed mod 5;
    var _hair_idx = (_seed div 5) mod 5;
    var _hair_col_idx = (_seed div 25) mod 6;
    var _acc_idx = (_seed div 150) mod 5;

    var _skin = skin_colors[_skin_idx];
    var _hair = hair_colors[_hair_col_idx];
    var _head_r = _r * 0.6;

    // Body/shoulders
    var _shirt = merge_colour(_hair, make_colour_rgb(120, 120, 160), 0.6);
    draw_set_colour(_shirt);
    draw_roundrect(_x - _head_r * 1.1, _y + _head_r * 0.5,
                   _x + _head_r * 1.1, _y + _head_r * 1.2, false);

    // Hair behind head (poof style)
    if (_hair_idx == 3) {
        draw_set_colour(_hair);
        draw_circle(_x, _y - _head_r * 0.2, _head_r * 1.3, false);
    }

    // Head
    draw_set_colour(_skin);
    draw_circle(_x, _y, _head_r, false);

    // Hair front
    draw_set_colour(_hair);
    if (_hair_idx == 1) {
        // Flat-top
        draw_rectangle(_x - _head_r * 0.8, _y - _head_r * 1.15,
                       _x + _head_r * 0.8, _y - _head_r * 0.45, false);
    } else if (_hair_idx == 2) {
        // Spiky - 3 triangles
        var _sw = _head_r * 0.35;
        draw_triangle(_x - _sw, _y - _head_r * 0.5, _x, _y - _head_r * 1.4,
                      _x + _sw, _y - _head_r * 0.5, false);
        draw_triangle(_x - _sw * 2, _y - _head_r * 0.3, _x - _sw, _y - _head_r * 1.1,
                      _x, _y - _head_r * 0.3, false);
        draw_triangle(_x, _y - _head_r * 0.3, _x + _sw, _y - _head_r * 1.1,
                      _x + _sw * 2, _y - _head_r * 0.3, false);
    } else if (_hair_idx == 4) {
        // Side-swept
        draw_rectangle(_x - _head_r * 0.9, _y - _head_r * 1.1,
                       _x + _head_r * 0.3, _y - _head_r * 0.35, false);
    }
    // 0 = bald, 3 = poof (drawn behind)

    // Eyes
    var _eye_dx = _head_r * 0.33;
    var _eye_r = _head_r * 0.16;
    draw_set_colour(c_white);
    draw_circle(_x - _eye_dx, _y - _head_r * 0.08, _eye_r, false);
    draw_circle(_x + _eye_dx, _y - _head_r * 0.08, _eye_r, false);
    draw_set_colour(c_black);
    draw_circle(_x - _eye_dx, _y - _head_r * 0.03, _eye_r * 0.55, false);
    draw_circle(_x + _eye_dx, _y - _head_r * 0.03, _eye_r * 0.55, false);

    // Mouth
    draw_set_colour(make_colour_rgb(180, 80, 80));
    draw_rectangle(_x - _head_r * 0.2, _y + _head_r * 0.38,
                   _x + _head_r * 0.2, _y + _head_r * 0.48, false);

    // Accessories
    if (_acc_idx == 1) {
        // Hat
        draw_set_colour(_hair);
        draw_rectangle(_x - _head_r * 1.0, _y - _head_r * 1.05,
                       _x + _head_r * 1.0, _y - _head_r * 0.8, false);
        draw_rectangle(_x - _head_r * 0.6, _y - _head_r * 1.45,
                       _x + _head_r * 0.6, _y - _head_r * 0.8, false);
    } else if (_acc_idx == 2) {
        // Headband
        draw_set_colour(make_colour_rgb(255, 60, 60));
        draw_rectangle(_x - _head_r * 0.85, _y - _head_r * 0.32,
                       _x + _head_r * 0.85, _y - _head_r * 0.12, false);
    } else if (_acc_idx == 3) {
        // Glasses
        draw_set_colour(make_colour_rgb(40, 40, 40));
        draw_circle(_x - _eye_dx, _y - _head_r * 0.08, _eye_r * 1.5, true);
        draw_circle(_x + _eye_dx, _y - _head_r * 0.08, _eye_r * 1.5, true);
        draw_line_width(_x - _eye_dx + _eye_r * 1.5, _y - _head_r * 0.08,
                        _x + _eye_dx - _eye_r * 1.5, _y - _head_r * 0.08, 1.5);
    } else if (_acc_idx == 4) {
        // Bow
        draw_set_colour(make_colour_rgb(255, 100, 180));
        draw_circle(_x + _head_r * 0.65, _y - _head_r * 0.65, _head_r * 0.2, false);
        draw_circle(_x + _head_r * 0.4, _y - _head_r * 0.75, _head_r * 0.2, false);
    }
}

// Screen dimensions (updated in Step_2)
window_width = 0;
window_height = 0;

/// @function spawn_customer()
/// @desc Adds a new customer to the queue. If queue is full, lose a life.
function spawn_customer() {
    if (queue_count >= queue_max) {
        // Queue overflow — customer turned away
        lives--;
        combo = 0;
        wave_lost++;
        if (lives <= 0) {
            game_state = 2;
            api_submit_score(points, undefined);
        }
        return;
    }

    var _idx = queue_count;
    queue_food[_idx] = irandom(3);
    queue_avatar[_idx] = irandom(9999);
    var _base = 900 - difficulty * 30;
    if (_base < 400) _base = 400;
    queue_max_patience[_idx] = _base;
    queue_patience[_idx] = _base;
    queue_count++;
}

/// @function seat_customer(_qi, _ti, _si)
/// @desc Move queue entry _qi to table _ti, seat _si, compact queue arrays.
function seat_customer(_qi, _ti, _si) {
    // Seat at table
    table_state[_ti][_si] = 1;
    table_food[_ti][_si] = queue_food[_qi];
    table_avatar[_ti][_si] = queue_avatar[_qi];
    var _base = 600 - difficulty * 25;
    if (_base < 240) _base = 240;
    table_max_patience[_ti][_si] = _base;
    table_patience[_ti][_si] = _base;
    table_eat_timer[_ti][_si] = 0;

    // Remove from queue — compact arrays
    for (var _i = _qi; _i < queue_count - 1; _i++) {
        queue_food[_i] = queue_food[_i + 1];
        queue_avatar[_i] = queue_avatar[_i + 1];
        queue_patience[_i] = queue_patience[_i + 1];
        queue_max_patience[_i] = queue_max_patience[_i + 1];
    }
    queue_count--;
    selected_queue = -1;
}

/// @function clear_all_entities()
/// @desc Clears tables, kitchen, and queue. Used by reset_game and between waves.
function clear_all_entities() {
    for (var _i = 0; _i < 6; _i++) {
        for (var _j = 0; _j < 4; _j++) {
            table_state[_i][_j] = 0;
            table_food[_i][_j] = 0;
            table_patience[_i][_j] = 0;
            table_max_patience[_i][_j] = 0;
            table_eat_timer[_i][_j] = 0;
            table_avatar[_i][_j] = 0;
        }
    }
    for (var _i = 0; _i < 2; _i++) {
        kitchen_occupied[_i] = false;
        kitchen_table[_i] = -1;
        kitchen_seat[_i] = -1;
        kitchen_food[_i] = 0;
        kitchen_cook_time[_i] = 0;
        kitchen_progress[_i] = 0;
    }
    for (var _i = 0; _i < queue_max; _i++) {
        queue_food[_i] = 0;
        queue_avatar[_i] = 0;
        queue_patience[_i] = 0;
        queue_max_patience[_i] = 0;
    }
    queue_count = 0;
    selected_queue = -1;
}

/// @function start_wave()
/// @desc Initializes the current wave's parameters.
function start_wave() {
    wave_total = min(2 + wave, 10);
    difficulty = wave - 1;
    wave_spawned = 0;
    wave_served = 0;
    wave_lost = 0;
    wave_points_start = points;
    spawn_timer = 60;
    spawn_interval = max(80, 180 - difficulty * 12);
}

/// @function reset_game()
function reset_game() {
    clear_all_entities();
    lives = max_lives;
    combo = 0;
    difficulty = 0;
    customers_served = 0;
    wave = 1;
    wave_total = 3;
    wave_spawned = 0;
    wave_served = 0;
    wave_lost = 0;
    wave_points_start = 0;
    spawn_timer = 60;
    spawn_interval = 180;
    tables_unlocked = 1;
    table_cost = 20;
    for (var _i = 0; _i < 6; _i++) table_seats[_i] = 1;
    table_seats[0] = 2;
}

reset_game();

// Load saved state
api_load_state(function(_status, _ok, _result, _payload) {
    try {
        var _state = json_parse(_result);
        username = _state.username;
        level = _state.level;
        if (variable_struct_exists(_state.data, "points")) {
            points = _state.data.points;
        }
        if (variable_struct_exists(_state.data, "lives")) {
            lives = _state.data.lives;
            customers_served = _state.data.customers_served;
            if (variable_struct_exists(_state.data, "wave")) {
                wave = _state.data.wave;
            }
            if (variable_struct_exists(_state.data, "tables_unlocked")) {
                tables_unlocked = _state.data.tables_unlocked;
                table_cost = 20 * tables_unlocked;
            }
            if (variable_struct_exists(_state.data, "table_seats")) {
                var _saved_seats = _state.data.table_seats;
                for (var _i = 0; _i < min(array_length(_saved_seats), 6); _i++) {
                    table_seats[_i] = _saved_seats[_i];
                }
            }
            if (lives > 0) {
                game_state = 1;
                start_wave();
            }
        }
    }
    catch (_ex) {
        api_save_state(0, { points: points }, undefined);
    }
    alarm[0] = 60;
});
