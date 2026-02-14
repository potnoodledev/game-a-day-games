
username = "";
level = 0;
points = 0;
prev_points = 0;

// Game state: 0=title, 1=playing, 2=game_over
game_state = 0;

// Grid: 5x5, flat 1D arrays (index = row*5 + col)
grid_size = 5;
grid_total = 25;
grid_type = array_create(25, -1);   // -1=empty, 0=sword, 1=shield, 2=heart, 3=coin
grid_level = array_create(25, 0);   // 1-4 (4 = super)

// Player stats
player_hp = 20;
player_max_hp = 20;
shield_turns = 0;

// Enemy / floor
floor_num = 1;
enemy_hp = 12;
enemy_max_hp = 12;
enemy_atk = 1;

// Current + next tile preview
current_tile_type = 0;
current_tile_level = 1;
next_tile_type = 0;
next_tile_level = 1;

// Tap cooldown
tap_cooldown = 0;

// Animation: enemy hurt flash
enemy_hurt_timer = 0;
// Animation: player hurt flash
player_hurt_timer = 0;
// Animation: merge flash on cells
merge_flash_timer = 0;
// Screen shake
shake_amount = 0;

// Tile type colors
tile_colors = [
    make_colour_rgb(255, 68, 68),    // 0: sword (red)
    make_colour_rgb(68, 136, 255),   // 1: shield (blue)
    make_colour_rgb(255, 102, 153),  // 2: heart (pink)
    make_colour_rgb(255, 204, 0),    // 3: coin (gold)
];

// Tile type dark colors (for cell bg when occupied)
tile_dark_colors = [
    make_colour_rgb(120, 30, 30),    // sword dark
    make_colour_rgb(30, 60, 120),    // shield dark
    make_colour_rgb(120, 40, 70),    // heart dark
    make_colour_rgb(120, 100, 20),   // coin dark
];

// Dungeon palette
col_bg = make_colour_rgb(26, 26, 46);
col_cell_empty = make_colour_rgb(15, 52, 96);
col_cell_border = make_colour_rgb(30, 80, 130);
col_hud_bg = make_colour_rgb(16, 16, 36);
col_enemy_bg = make_colour_rgb(40, 20, 50);
col_hp_red = make_colour_rgb(220, 50, 50);
col_hp_green = make_colour_rgb(50, 200, 80);
col_shield_blue = make_colour_rgb(80, 160, 255);

// Floating text particles
fx_max = 20;
fx_count = 0;
fx_x = array_create(20, 0);
fx_y = array_create(20, 0);
fx_text = array_create(20, "");
fx_life = array_create(20, 0);
fx_max_life = array_create(20, 0);
fx_col = array_create(20, c_white);

/// @function spawn_float_text(_px, _py, _txt, _color, _duration)
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

/// @function generate_tile()
/// @desc Returns a random tile type (weighted)
function generate_tile() {
    var _r = irandom(99);
    if (_r < 35) return 0;       // sword: 35%
    else if (_r < 55) return 1;  // shield: 20%
    else if (_r < 75) return 2;  // heart: 20%
    else return 3;               // coin: 25%
}

/// @function roll_next_tile()
/// @desc Shift next into current, generate new next
function roll_next_tile() {
    current_tile_type = next_tile_type;
    current_tile_level = next_tile_level;
    next_tile_type = generate_tile();
    next_tile_level = 1;
}

/// @function find_connected(_idx, _type, _lvl)
/// @desc Flood fill to find all connected cells of same type+level
function find_connected(_idx, _type, _lvl) {
    var _visited = array_create(grid_total, false);
    var _stack = array_create(grid_total, 0);
    var _stack_top = 0;
    var _result = array_create(grid_total, 0);
    var _result_count = 0;

    _stack[0] = _idx;
    _stack_top = 1;
    _visited[_idx] = true;

    while (_stack_top > 0) {
        _stack_top--;
        var _ci = _stack[_stack_top];
        _result[_result_count] = _ci;
        _result_count++;

        var _row = _ci div grid_size;
        var _col = _ci mod grid_size;

        // Check 4 neighbors
        // Up
        if (_row > 0) {
            var _ni = (_row - 1) * grid_size + _col;
            if (!_visited[_ni] && grid_type[_ni] == _type && grid_level[_ni] == _lvl) {
                _visited[_ni] = true;
                _stack[_stack_top] = _ni;
                _stack_top++;
            }
        }
        // Down
        if (_row < grid_size - 1) {
            var _ni = (_row + 1) * grid_size + _col;
            if (!_visited[_ni] && grid_type[_ni] == _type && grid_level[_ni] == _lvl) {
                _visited[_ni] = true;
                _stack[_stack_top] = _ni;
                _stack_top++;
            }
        }
        // Left
        if (_col > 0) {
            var _ni = _row * grid_size + (_col - 1);
            if (!_visited[_ni] && grid_type[_ni] == _type && grid_level[_ni] == _lvl) {
                _visited[_ni] = true;
                _stack[_stack_top] = _ni;
                _stack_top++;
            }
        }
        // Right
        if (_col < grid_size - 1) {
            var _ni = _row * grid_size + (_col + 1);
            if (!_visited[_ni] && grid_type[_ni] == _type && grid_level[_ni] == _lvl) {
                _visited[_ni] = true;
                _stack[_stack_top] = _ni;
                _stack_top++;
            }
        }
    }

    // Return as struct with count
    return { cells: _result, count: _result_count };
}

/// @function apply_merge_effect(_type, _lvl, _cx, _cy)
/// @desc Apply the effect of a merged tile
function apply_merge_effect(_type, _lvl, _cx, _cy) {
    if (_type == 0) {
        // Sword: damage enemy
        var _dmg_table = [0, 5, 12, 25, 50];
        var _dmg = _dmg_table[_lvl];
        enemy_hp -= _dmg;
        enemy_hurt_timer = 15;
        shake_amount = 4;
        spawn_float_text(_cx, _cy, $"-{_dmg} HP", tile_colors[0], 50);
    }
    else if (_type == 1) {
        // Shield: block turns
        var _block_table = [0, 2, 4, 7, 12];
        var _turns = _block_table[_lvl];
        shield_turns += _turns;
        spawn_float_text(_cx, _cy, $"+{_turns} Shield", tile_colors[1], 50);
    }
    else if (_type == 2) {
        // Heart: heal
        var _heal_table = [0, 3, 8, 15, 0];
        if (_lvl == 4) {
            // Full heal
            player_hp = player_max_hp;
            spawn_float_text(_cx, _cy, "FULL HEAL!", tile_colors[2], 60);
        } else {
            var _heal = _heal_table[_lvl];
            player_hp = min(player_hp + _heal, player_max_hp);
            spawn_float_text(_cx, _cy, $"+{_heal} HP", tile_colors[2], 50);
        }
    }
    else if (_type == 3) {
        // Coin: points
        var _pts_table = [0, 10, 25, 50, 150];
        var _pts = _pts_table[_lvl];
        points += _pts;
        spawn_float_text(_cx, _cy, $"+{_pts}", tile_colors[3], 50);
    }
}

/// @function do_merge(_placed_idx)
/// @desc Check for merges at _placed_idx, chain recursively
function do_merge(_placed_idx) {
    if (grid_type[_placed_idx] == -1) return;

    var _type = grid_type[_placed_idx];
    var _lvl = grid_level[_placed_idx];

    // Can't merge level 4 (super)
    if (_lvl >= 4) return;

    var _result = find_connected(_placed_idx, _type, _lvl);
    var _count = _result.count;

    if (_count >= 3) {
        // Clear all connected cells
        for (var _i = 0; _i < _count; _i++) {
            var _ci = _result.cells[_i];
            grid_type[_ci] = -1;
            grid_level[_ci] = 0;
        }

        // Place upgraded tile at the original placement
        var _new_lvl = _lvl + 1;
        grid_type[_placed_idx] = _type;
        grid_level[_placed_idx] = _new_lvl;

        merge_flash_timer = 12;

        // Calculate center position for float text (use grid center)
        var _row = _placed_idx div grid_size;
        var _col = _placed_idx mod grid_size;
        var _gw = display_get_gui_width();
        var _gh = display_get_gui_height();
        var _grid_avail_h = _gh * 0.40;
        var _cell_size = min((_gw * 0.9) / grid_size, _grid_avail_h / grid_size);
        var _grid_w = _cell_size * grid_size;
        var _grid_top = _gh * 0.32;
        var _grid_left = (_gw - _grid_w) * 0.5;
        var _fx_x = _grid_left + _col * _cell_size + _cell_size * 0.5;
        var _fx_y = _grid_top + _row * _cell_size + _cell_size * 0.5;

        // Apply effect
        apply_merge_effect(_type, _new_lvl, _fx_x, _fx_y);

        // Chain: check if the upgraded tile can merge further
        do_merge(_placed_idx);
    }
}

/// @function setup_enemy()
/// @desc Set enemy stats based on floor_num
function setup_enemy() {
    enemy_max_hp = 8 + 4 * floor_num;
    enemy_hp = enemy_max_hp;
    enemy_atk = 1 + floor(floor_num / 3);
}

/// @function enemy_attack()
/// @desc Enemy attacks the player (called after placing a tile)
function enemy_attack() {
    if (shield_turns > 0) {
        shield_turns--;
        // Blocked!
        var _gw = display_get_gui_width();
        var _gh = display_get_gui_height();
        spawn_float_text(_gw * 0.5, _gh * 0.82, "BLOCKED!", col_shield_blue, 40);
    } else {
        player_hp -= enemy_atk;
        player_hurt_timer = 15;
        shake_amount = 3;
        var _gw = display_get_gui_width();
        var _gh = display_get_gui_height();
        spawn_float_text(_gw * 0.5, _gh * 0.82, $"-{enemy_atk}", col_hp_red, 40);
    }
}

/// @function check_enemy_dead()
/// @desc Check if enemy is dead, advance floor
function check_enemy_dead() {
    if (enemy_hp <= 0) {
        floor_num++;
        setup_enemy();
        // Bonus points for clearing a floor
        var _bonus = floor_num * 5;
        points += _bonus;
        var _gw = display_get_gui_width();
        var _gh = display_get_gui_height();
        spawn_float_text(_gw * 0.5, _gh * 0.18, $"Floor {floor_num}!", make_colour_rgb(255, 255, 100), 70);
        spawn_float_text(_gw * 0.5, _gh * 0.24, $"+{_bonus} pts", tile_colors[3], 50);
    }
}

/// @function check_grid_full()
/// @desc Returns true if no empty cells remain
function check_grid_full() {
    for (var _i = 0; _i < grid_total; _i++) {
        if (grid_type[_i] == -1) return false;
    }
    return true;
}

/// @function clear_grid()
/// @desc Reset all grid cells to empty
function clear_grid() {
    for (var _i = 0; _i < grid_total; _i++) {
        grid_type[_i] = -1;
        grid_level[_i] = 0;
    }
}

/// @function reset_game()
function reset_game() {
    clear_grid();
    player_hp = player_max_hp;
    shield_turns = 0;
    floor_num = 1;
    setup_enemy();
    next_tile_type = generate_tile();
    next_tile_level = 1;
    roll_next_tile();
}

/// @function get_save_data()
function get_save_data() {
    return {
        points: points,
        floor_num: floor_num,
        player_hp: player_hp,
        shield_turns: shield_turns,
        enemy_hp: enemy_hp,
        enemy_max_hp: enemy_max_hp,
        enemy_atk: enemy_atk,
        grid_type: grid_type,
        grid_level: grid_level,
        current_tile_type: current_tile_type,
        current_tile_level: current_tile_level,
        next_tile_type: next_tile_type,
        next_tile_level: next_tile_level,
    };
}

// Initialize
reset_game();

// Screen dimensions (updated in Step_2)
window_width = 0;
window_height = 0;

// Load saved state
api_load_state(function(_status, _ok, _result, _payload) {
    try {
        var _state = json_parse(_result);
        username = _state.username;
        level = _state.level;
        if (variable_struct_exists(_state.data, "points")) {
            points = _state.data.points;
        }
        if (variable_struct_exists(_state.data, "floor_num")) {
            floor_num = _state.data.floor_num;
            player_hp = _state.data.player_hp;
            shield_turns = _state.data.shield_turns;
            enemy_hp = _state.data.enemy_hp;
            enemy_max_hp = _state.data.enemy_max_hp;
            enemy_atk = _state.data.enemy_atk;
            // Restore grid
            var _saved_type = _state.data.grid_type;
            var _saved_level = _state.data.grid_level;
            for (var _i = 0; _i < min(array_length(_saved_type), 25); _i++) {
                grid_type[_i] = _saved_type[_i];
                grid_level[_i] = _saved_level[_i];
            }
            current_tile_type = _state.data.current_tile_type;
            current_tile_level = _state.data.current_tile_level;
            next_tile_type = _state.data.next_tile_type;
            next_tile_level = _state.data.next_tile_level;
            if (player_hp > 0 && !check_grid_full()) {
                game_state = 1;
            }
        }
    }
    catch (_ex) {
        api_save_state(0, { points: points }, undefined);
    }
    alarm[0] = 60;
});
