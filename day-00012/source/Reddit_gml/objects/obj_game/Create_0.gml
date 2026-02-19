// ========================================
// GAME OF LIFE — Create_0.gml (Rogue-like)
// ========================================

// --- Game States ---
// 0=loading, 1=placing, 2=simulating, 3=power_up_select, 4=game_over
game_state = 0;
points = 0;
level = 0;

// --- Grid (24x30, wrapping edges) ---
grid_cols = 24;
grid_rows = 30;
cell_size = 14;
grid_offset_x = 0;
grid_offset_y = 0;

// Grid data: flat arrays (row * cols + col)
grid = array_create(grid_cols * grid_rows, 0);
next_grid = array_create(grid_cols * grid_rows, 0);
wall_grid = array_create(grid_cols * grid_rows, 0);

// --- Targets ---
target_list = []; // array of {col, row, hit}
targets_hit = 0;

// --- Round ---
round_num = 0;
max_rounds = 5;
cells_placed = 0;
cell_budget = 15;
base_budget = 15;

// --- Power-ups ---
extra_budget = 0;        // permanent: from "+3 Budget"
less_walls_next = false;  // one-round: 40% fewer walls
extra_targets_next = 0;   // one-round: extra target count
score_boost_next = false; // one-round: 2x round score
powerup_options = [];     // two indices for current selection

// --- Simulation ---
sim_generation = 0;
sim_max_gens = 200;
sim_speed = 3;
sim_timer = 0;
sim_population = 0;
sim_peak_population = 0;
sim_stable_count = 0;
sim_last_pop = -1;
sim_fast = false;

// --- Scoring ---
round_score = 0;
round_scores = [];
target_bonus = 0;

// --- Visual ---
bg_color = make_color_rgb(10, 10, 20);
grid_bg_color = make_color_rgb(18, 18, 32);
grid_line_color = make_color_rgb(28, 28, 46);
wall_color = make_color_rgb(45, 45, 65);
wall_hi_color = make_color_rgb(58, 58, 80);
cell_alive_color = make_color_rgb(0, 230, 118);
cell_highlight_color = make_color_rgb(120, 255, 200);
target_color = make_color_rgb(255, 200, 50);
target_hit_color = make_color_rgb(255, 215, 0);

// Power-up card colors
pu_colors = [
    make_color_rgb(0, 200, 100),   // +3 Budget (green)
    make_color_rgb(255, 140, 40),  // Less Walls (orange)
    make_color_rgb(255, 200, 50),  // +2 Targets (gold)
    make_color_rgb(170, 100, 255), // 2x Score (purple)
];

// --- Screen ---
scr_w = window_get_width();
scr_h = window_get_height();

// --- Buttons (computed in calc_layout) ---
btn_h = 44;
btn_y = 0;
go_btn_x = 0;
go_btn_w = 0;
clr_btn_x = 0;
clr_btn_w = 0;

// --- Power-up cards (computed in calc_layout) ---
card_x = 0;
card_w = 0;
card_h = 0;
card1_y = 0;
card2_y = 0;

// --- Popups ---
popups = [];

// --- Touch ---
touch_painting = -1;
last_toggled_col = -1;
last_toggled_row = -1;

// --- Score submission ---
score_submitted = false;

// --- Transition timer (prevent accidental taps) ---
transition_timer = 0;

// =========================================
// FUNCTIONS
// =========================================

function calc_layout() {
    scr_w = window_get_width();
    scr_h = window_get_height();

    var _hud_top = max(scr_h * 0.07, 36);
    var _btn_area = max(scr_h * 0.08, 50);
    var _pad = 6;
    var _avail_w = scr_w - _pad * 2;
    var _avail_h = scr_h - _hud_top - _btn_area - _pad;

    cell_size = min(floor(_avail_w / grid_cols), floor(_avail_h / grid_rows));
    cell_size = max(cell_size, 6);

    var _grid_w = grid_cols * cell_size;
    var _grid_h = grid_rows * cell_size;
    grid_offset_x = floor((scr_w - _grid_w) * 0.5);
    grid_offset_y = floor(_hud_top + (_avail_h - _grid_h) * 0.5);

    // Buttons
    btn_h = max(40, scr_h * 0.055);
    btn_y = grid_offset_y + _grid_h + 6;
    go_btn_w = min(scr_w * 0.35, 140);
    clr_btn_w = min(scr_w * 0.22, 90);
    var _gap = 10;
    var _total_w = go_btn_w + clr_btn_w + _gap;
    clr_btn_x = floor((scr_w - _total_w) * 0.5);
    go_btn_x = clr_btn_x + clr_btn_w + _gap;

    // Power-up cards
    card_x = floor(scr_w * 0.08);
    card_w = floor(scr_w * 0.84);
    card_h = floor(min(scr_h * 0.12, 80));
    card1_y = floor(scr_h * 0.45);
    card2_y = floor(scr_h * 0.61);
}

function grid_get(_col, _row) {
    if (_col < 0 || _col >= grid_cols || _row < 0 || _row >= grid_rows) return 0;
    return grid[_row * grid_cols + _col];
}

function grid_set(_col, _row, _val) {
    if (_col >= 0 && _col < grid_cols && _row >= 0 && _row < grid_rows) {
        grid[@ _row * grid_cols + _col] = _val;
    }
}

function is_wall(_col, _row) {
    if (_col < 0 || _col >= grid_cols || _row < 0 || _row >= grid_rows) return false;
    return wall_grid[_row * grid_cols + _col] == 1;
}

function count_neighbors(_col, _row) {
    var _n = 0;
    for (var _dy = -1; _dy <= 1; _dy++) {
        for (var _dx = -1; _dx <= 1; _dx++) {
            if (_dx == 0 && _dy == 0) continue;
            var _c = (_col + _dx + grid_cols) mod grid_cols;
            var _r = (_row + _dy + grid_rows) mod grid_rows;
            var _idx = _r * grid_cols + _c;
            if (wall_grid[_idx] == 1) continue; // walls = dead
            _n += grid[_idx];
        }
    }
    return _n;
}

function clear_grid() {
    for (var _i = 0; _i < grid_cols * grid_rows; _i++) {
        grid[@ _i] = 0;
    }
    cells_placed = 0;
}

function count_population() {
    var _pop = 0;
    for (var _i = 0; _i < grid_cols * grid_rows; _i++) {
        _pop += grid[_i];
    }
    return _pop;
}

function sim_step() {
    var _size = grid_cols * grid_rows;
    for (var _r = 0; _r < grid_rows; _r++) {
        for (var _c = 0; _c < grid_cols; _c++) {
            var _idx = _r * grid_cols + _c;
            // Walls always dead
            if (wall_grid[_idx] == 1) {
                next_grid[@ _idx] = 0;
                continue;
            }
            var _n = count_neighbors(_c, _r);
            var _alive = grid[_idx];
            if (_alive) {
                next_grid[@ _idx] = (_n == 2 || _n == 3) ? 1 : 0;
            } else {
                next_grid[@ _idx] = (_n == 3) ? 1 : 0;
            }
        }
    }
    // Swap grids
    var _tmp = grid;
    grid = next_grid;
    next_grid = _tmp;

    sim_generation++;
    sim_population = count_population();
    if (sim_population > sim_peak_population) {
        sim_peak_population = sim_population;
    }

    // Check targets
    for (var _i = 0; _i < array_length(target_list); _i++) {
        if (!target_list[_i].hit) {
            var _tidx = target_list[_i].row * grid_cols + target_list[_i].col;
            if (grid[_tidx] == 1) {
                target_list[_i].hit = true;
                targets_hit++;
                array_push(popups, {
                    x: grid_offset_x + target_list[_i].col * cell_size + cell_size * 0.5,
                    y: grid_offset_y + target_list[_i].row * cell_size,
                    txt: "TARGET!",
                    t: 40,
                    clr: target_hit_color,
                });
            }
        }
    }

    // Stability detection
    if (sim_population == sim_last_pop) {
        sim_stable_count++;
    } else {
        sim_stable_count = 0;
    }
    sim_last_pop = sim_population;
}

// =========================================
// LEVEL GENERATION
// =========================================

function generate_walls(_num_seeds) {
    for (var _i = 0; _i < grid_cols * grid_rows; _i++) {
        wall_grid[@ _i] = 0;
    }

    var _cx = grid_cols div 2;
    var _cy = grid_rows div 2;
    var _safe = 3; // safe zone radius around center

    for (var _s = 0; _s < _num_seeds; _s++) {
        var _col = irandom_range(1, grid_cols - 2);
        var _row = irandom_range(1, grid_rows - 2);

        // Don't wall off the center (player start area)
        if (abs(_col - _cx) <= _safe && abs(_row - _cy) <= _safe) continue;

        wall_grid[@ _row * grid_cols + _col] = 1;

        // Grow cluster: 0-3 adjacent walls
        var _grow = irandom(3);
        for (var _g = 0; _g < _grow; _g++) {
            var _dx = irandom_range(-1, 1);
            var _dy = irandom_range(-1, 1);
            var _nc = clamp(_col + _dx, 0, grid_cols - 1);
            var _nr = clamp(_row + _dy, 0, grid_rows - 1);
            if (abs(_nc - _cx) <= _safe && abs(_nr - _cy) <= _safe) continue;
            wall_grid[@ _nr * grid_cols + _nc] = 1;
        }
    }
}

function generate_targets(_count) {
    target_list = [];
    targets_hit = 0;

    for (var _i = 0; _i < _count; _i++) {
        var _placed = false;
        var _attempts = 0;
        while (!_placed && _attempts < 100) {
            var _col = irandom_range(2, grid_cols - 3);
            var _row = irandom_range(2, grid_rows - 3);

            // Not on a wall
            if (wall_grid[_row * grid_cols + _col] == 1) {
                _attempts++;
                continue;
            }

            // Not adjacent to too many walls (must be reachable)
            var _wall_count = 0;
            for (var _dy = -1; _dy <= 1; _dy++) {
                for (var _dx = -1; _dx <= 1; _dx++) {
                    if (_dx == 0 && _dy == 0) continue;
                    var _nc = _col + _dx;
                    var _nr = _row + _dy;
                    if (_nc >= 0 && _nc < grid_cols && _nr >= 0 && _nr < grid_rows) {
                        if (wall_grid[_nr * grid_cols + _nc] == 1) _wall_count++;
                    }
                }
            }
            if (_wall_count >= 5) {
                _attempts++;
                continue;
            }

            // Not too close to other targets
            var _ok = true;
            for (var _j = 0; _j < array_length(target_list); _j++) {
                var _tdx = abs(_col - target_list[_j].col);
                var _tdy = abs(_row - target_list[_j].row);
                if (_tdx + _tdy < 6) {
                    _ok = false;
                    break;
                }
            }
            if (!_ok) {
                _attempts++;
                continue;
            }

            array_push(target_list, {col: _col, row: _row, hit: false});
            _placed = true;
            _attempts++;
        }
    }
}

function generate_level() {
    // Wall count scales with round
    var _base_walls = 6 + round_num * 5;
    if (less_walls_next) {
        _base_walls = floor(_base_walls * 0.5);
        less_walls_next = false;
    }
    generate_walls(_base_walls);

    // Target count
    var _base_targets = 3 + floor(round_num * 0.4);
    _base_targets += extra_targets_next;
    extra_targets_next = 0;
    generate_targets(_base_targets);
}

// =========================================
// ROUND MANAGEMENT
// =========================================

function start_round() {
    round_num++;
    clear_grid();

    // Budget: base - round decay + permanent bonus
    cell_budget = max(base_budget - (round_num - 1) * 2, 6) + extra_budget;

    // Generate level terrain
    generate_level();

    sim_generation = 0;
    sim_population = 0;
    sim_peak_population = 0;
    sim_stable_count = 0;
    sim_last_pop = -1;
    sim_timer = 0;
    sim_fast = false;
    round_score = 0;
    target_bonus = 0;
    transition_timer = 0;
    touch_painting = -1;
    game_state = 1;
}

function end_round() {
    // Score = peak × (1 + gens/100) × round_num
    var _survival_mult = 1 + sim_generation * 0.01;
    round_score = floor(sim_peak_population * _survival_mult * round_num);

    // Target bonus
    target_bonus = targets_hit * 25 * round_num;
    round_score += target_bonus;

    // Stability bonus
    if (sim_population > 0 && sim_stable_count >= 15) {
        round_score += 20 * round_num;
    }

    // Score boost power-up
    if (score_boost_next) {
        round_score = round_score * 2;
        score_boost_next = false;
    }

    points += round_score;
    array_push(round_scores, round_score);
    transition_timer = 25;

    if (round_num >= max_rounds) {
        game_state = 4;
        score_submitted = false;
    } else {
        // Go to power-up selection
        pick_powerup_options();
        game_state = 3;
    }
}

function pick_powerup_options() {
    // Pick 2 distinct random power-ups
    var _a = irandom(3);
    var _b = _a;
    while (_b == _a) {
        _b = irandom(3);
    }
    powerup_options = [_a, _b];
}

function get_powerup_name(_id) {
    switch (_id) {
        case 0: return "+3 Budget";
        case 1: return "Less Walls";
        case 2: return "+2 Targets";
        case 3: return "2x Score";
    }
    return "???";
}

function get_powerup_desc(_id) {
    switch (_id) {
        case 0: return "Permanently place 3 more cells";
        case 1: return "50% fewer walls next round";
        case 2: return "2 extra targets next round";
        case 3: return "Double score next round";
    }
    return "";
}

function apply_powerup(_id) {
    switch (_id) {
        case 0: extra_budget += 3; break;
        case 1: less_walls_next = true; break;
        case 2: extra_targets_next += 2; break;
        case 3: score_boost_next = true; break;
    }
}

function reset_game() {
    points = 0;
    round_num = 0;
    round_scores = [];
    score_submitted = false;
    popups = [];
    extra_budget = 0;
    less_walls_next = false;
    extra_targets_next = 0;
    score_boost_next = false;
    start_round();
}

// =========================================
// LOAD STATE
// =========================================
state_loaded = false;
state_data = undefined;
username = "";

api_load_state(function(_status, _ok, _result, _payload) {
    if (_ok && _status >= 200 && _status < 400 && _result != undefined && _result != "") {
        try { self.state_data = json_parse(_result); }
        catch (_ex) { self.state_data = undefined; }
    }
    self.state_loaded = true;
});

calc_layout();
