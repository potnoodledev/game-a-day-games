
// === GAME STATE ===
game_state = 0; // 0=loading, 1=playing, 2=game_over
state_loaded = false;

username = "";
level = 1;
points = 0;
prev_points = 0;
lives = 3;
max_lives = 5;
combo = 1;
combo_timer = 0;
combo_max_timer = 180;
combo_floor = 1; // minimum combo (power-up can raise to 2)
orders_completed = 0;
orders_for_next_level = 5;
best_score = 0;
max_combo = 1;

// === COLORS ===
all_colors = [
    $db9834, // Blue
    $71cc2e, // Green
    $3c4ce7, // Red
    $0fc4f1, // Yellow
    $b6599b  // Purple
];
color_names = ["Blue", "Green", "Red", "Yellow", "Purple"];
num_colors = 3;

// === PRODUCT NAMES ===
product_prefixes = ["Mega", "Nano", "Turbo", "Ultra", "Mini", "Super", "Proto", "Hyper", "Micro", "Deluxe"];
product_suffixes = ["Widget", "Gizmo", "Sprocket", "Gadget", "Module", "Doohickey", "Doodad", "Device", "Core", "Unit"];

// === ORDERS ===
// {recipe, timer, max_timer, reward, is_bonus, name}
orders = [];
max_orders = 4;
order_spawn_timer = 0;
order_spawn_rate = 240;

// === ASSEMBLY BELT ===
assembly = [];
assembly_slide = [];
max_assembly = 6;

// === DIFFICULTY TABLE ===
diff_table = [
    [3, 2, 15, 4.0],
    [3, 3, 13, 3.5],
    [4, 3, 12, 3.0],
    [4, 4, 10, 2.5],
    [5, 5,  8, 2.0]
];

// === POPUPS ===
popups = [];

// === SCREEN EFFECTS ===
shake_timer = 0;
shake_intensity = 0;
shake_x = 0;
shake_y = 0;
red_flash_timer = 0;
red_flash_max = 20;

// === RING FX ===
ring_fx = []; // {x, y, radius, max_radius, timer, max_timer, color}

// === COMPLETION FX ===
complete_fx = []; // {row_y, timer, max_timer}

// === SMOKE PARTICLES ===
smoke_particles = []; // {x, y, alpha, size, vy}
smoke_spawn_timer = 0;

// === STATION TAP FEEDBACK ===
station_flash = [0, 0, 0, 0, 0];

// === WRONG SHIP / BELT FULL FEEDBACK ===
wrong_ship_timer = 0;
belt_full_timer = 0;

// === FREEZE POWER-UP ===
freeze_timer = 0;

// === POWER-UP SELECTION ===
powerup_state = 0; // 0=inactive, 1=choosing
powerup_choices = [0, 1];
powerup_names = ["FREEZE", "EXTRA LIFE", "COMBO LOCK", "TIME WARP"];
powerup_descs = [];
array_push(powerup_descs, "Pause all order timers for 5s");
array_push(powerup_descs, "+1 life (max 5)");
array_push(powerup_descs, "Combo stays at 2x minimum");
array_push(powerup_descs, "+50% time on all orders");
powerup_colors = [];
array_push(powerup_colors, $db9834);
array_push(powerup_colors, $3c4ce7);
array_push(powerup_colors, $71cc2e);
array_push(powerup_colors, $0fc4f1);

// === TUTORIAL ===
tutorial_done = false;

// === LAYOUT ===
window_width = 0;
window_height = 0;
layout_dirty = true;

hud_h = 0;
order_area_y = 0;
order_area_h = 0;
order_row_h = 0;
belt_area_y = 0;
belt_area_h = 0;
station_area_y = 0;
station_area_h = 0;
button_area_y = 0;

station_buttons = [];
ship_btn = {x1: 0, y1: 0, x2: 0, y2: 0};
clear_btn = {x1: 0, y1: 0, x2: 0, y2: 0};
undo_btn = {x1: 0, y1: 0, x2: 0, y2: 0};
powerup_card_1 = {x1: 0, y1: 0, x2: 0, y2: 0};
powerup_card_2 = {x1: 0, y1: 0, x2: 0, y2: 0};

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
        if (variable_struct_exists(_state.data, "best_score")) {
            best_score = _state.data.best_score;
        }
        if (variable_struct_exists(_state.data, "tutorial_done")) {
            tutorial_done = _state.data.tutorial_done;
        }
    }
    catch (_ex) {
        api_save_state(0, { points: 0, level: 1, lives: 3, orders_completed: 0, combo: 1, best_score: 0, tutorial_done: false }, undefined);
    }
    state_loaded = true;
    alarm[0] = 60 * 15;
});
