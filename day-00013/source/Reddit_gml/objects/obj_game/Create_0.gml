
// === GAME STATE ===
game_state = 0; // 0=loading, 1=playing, 2=game_over
state_loaded = false;

username = "";
level = 1;
points = 0;
prev_points = 0;
lives = 3;
max_lives = 3;
combo = 1;
combo_timer = 0;
combo_max_timer = 180; // 3 seconds at 60fps to keep combo alive
orders_completed = 0;
orders_for_next_level = 5;

// === COLORS ===
// All station colors: blue, green, red, yellow, purple
all_colors = [
    $db9834, // Blue  #3498db (BGR)
    $71cc2e, // Green #2ecc71
    $3c4ce7, // Red   #e74c3c
    $0fc4f1, // Yellow #f1c40f
    $b6599b  // Purple #9b59b6
];
color_names = ["Blue", "Green", "Red", "Yellow", "Purple"];
num_colors = 3; // starts with 3, grows with level

// === ORDERS ===
orders = []; // array of maps: {recipe, timer, max_timer, reward}
max_orders = 4;
order_spawn_timer = 0;
order_spawn_rate = 240; // frames between spawns (4 sec at 60fps)

// === ASSEMBLY BELT ===
assembly = []; // current assembled colors
max_assembly = 6;

// === DIFFICULTY TABLE ===
// [colors, max_recipe_len, order_timer_sec, spawn_rate_sec]
diff_table = [
    [3, 2, 15, 4.0],
    [3, 3, 13, 3.5],
    [4, 3, 12, 3.0],
    [4, 4, 10, 2.5],
    [5, 5,  8, 2.0]
];

// === FLOATING TEXT POPUPS ===
popups = []; // {x, y, text, color, timer, max_timer}

// === LAYOUT (recalculated in Step_2) ===
window_width = 0;
window_height = 0;
layout_dirty = true;

// Layout regions (set by calc_layout)
hud_h = 0;
order_area_y = 0;
order_area_h = 0;
order_row_h = 0;
belt_area_y = 0;
belt_area_h = 0;
station_area_y = 0;
station_area_h = 0;
button_area_y = 0;

// Station button rects: [{x1,y1,x2,y2,color_idx}]
station_buttons = [];
// Ship / Clear button rects
ship_btn = {x1: 0, y1: 0, x2: 0, y2: 0};
clear_btn = {x1: 0, y1: 0, x2: 0, y2: 0};

// Conveyor animation
conveyor_offset = 0;

// Game over
final_score = 0;
final_level = 0;
final_orders = 0;
final_combo = 1;
score_submitted = false;
game_over_tap_delay = 0;

// === LOAD STATE ===
api_load_state(function(_status, _ok, _result, _payload) {
    try {
        var _state = json_parse(_result);
        username = _state.username;
        level = _state.data.level;
        points = _state.data.points;
        lives = _state.data.lives;
        orders_completed = _state.data.orders_completed;
        combo = _state.data.combo;
    }
    catch (_ex) {
        api_save_state(0, { points: 0, level: 1, lives: 3, orders_completed: 0, combo: 1 }, undefined);
    }
    state_loaded = true;
    alarm[0] = 60 * 15; // save every 15 sec
});
