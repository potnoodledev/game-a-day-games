
username = "";
level = 0;
points = 0;

prev_points = 0;
prev_grid_string = "";

// Grid: 4x4, stored as flat array of 16 cells
// Value 0 = empty, 1+ = atomic number
grid = array_create(16, 0);

// Game state: 0=title, 1=playing, 2=game over
game_state = 0;

// Swipe tracking
touch_active = false;
touch_sx = 0;
touch_sy = 0;
swipe_threshold = 40;

// Move lock — prevent rapid repeat moves
move_cooldown = 0;

// Element data arrays (index = atomic number, 0 = unused)
elem_sym = ["", "H", "He", "Li", "Be", "B", "C", "N", "O", "F", "Ne", "Na", "Mg", "Al", "Si", "P", "S"];
elem_name = ["", "Hydrogen", "Helium", "Lithium", "Beryllium", "Boron", "Carbon", "Nitrogen", "Oxygen", "Fluorine", "Neon", "Sodium", "Magnesium", "Aluminium", "Silicon", "Phosphorus", "Sulfur"];

// Colors as BGR integers (GameMaker uses BGR format)
elem_col = [
    c_black,
    make_colour_rgb(91, 192, 235),   // 1  H  - light blue
    make_colour_rgb(253, 231, 76),   // 2  He - yellow
    make_colour_rgb(255, 107, 107),  // 3  Li - red
    make_colour_rgb(155, 93, 229),   // 4  Be - purple
    make_colour_rgb(0, 245, 212),    // 5  B  - teal
    make_colour_rgb(74, 74, 74),     // 6  C  - dark gray
    make_colour_rgb(58, 134, 255),   // 7  N  - blue
    make_colour_rgb(255, 0, 110),    // 8  O  - pink
    make_colour_rgb(128, 237, 153),  // 9  F  - green
    make_colour_rgb(255, 183, 3),    // 10 Ne - orange
    make_colour_rgb(230, 57, 70),    // 11 Na - deep red
    make_colour_rgb(255, 215, 0),    // 12 Mg - gold
    make_colour_rgb(218, 165, 32),   // 13 Al - dark gold
    make_colour_rgb(184, 134, 11),   // 14 Si - darker gold
    make_colour_rgb(205, 133, 63),   // 15 P  - peru
    make_colour_rgb(255, 223, 0),    // 16 S  - golden yellow
];

/// @function grid_get(r, c)
function grid_get(_r, _c) {
    return grid[_r * 4 + _c];
}

/// @function grid_set(r, c, v)
function grid_set(_r, _c, _v) {
    grid[_r * 4 + _c] = _v;
}

/// @function spawn_atom()
/// Places a new atom (90% H, 10% He) in a random empty cell
function spawn_atom() {
    // Collect empty cell indices
    var _empties = [];
    for (var _i = 0; _i < 16; _i++) {
        if (grid[_i] == 0) {
            array_push(_empties, _i);
        }
    }
    if (array_length(_empties) == 0) return;

    var _idx = _empties[irandom(array_length(_empties) - 1)];
    grid[_idx] = (random(1) < 0.9) ? 1 : 2;
}

/// @function can_move()
/// Returns true if any valid move exists
function can_move() {
    // If any empty cell, can move
    for (var _i = 0; _i < 16; _i++) {
        if (grid[_i] == 0) return true;
    }
    // Check adjacent pairs (horizontal)
    for (var _r = 0; _r < 4; _r++) {
        for (var _c = 0; _c < 3; _c++) {
            if (grid_get(_r, _c) == grid_get(_r, _c + 1)) return true;
        }
    }
    // Check adjacent pairs (vertical)
    for (var _r = 0; _r < 3; _r++) {
        for (var _c = 0; _c < 4; _c++) {
            if (grid_get(_r, _c) == grid_get(_r + 1, _c)) return true;
        }
    }
    return false;
}

/// @function slide_and_merge(dir)
/// dir: 0=left, 1=right, 2=up, 3=down
/// Returns points earned from merges. Returns -1 if nothing moved.
function slide_and_merge(_dir) {
    var _pts = 0;
    var _moved = false;

    // Process 4 lines (rows for L/R, columns for U/D)
    for (var _line = 0; _line < 4; _line++) {
        // Extract the 4 cells for this line
        var _cells = array_create(4, 0);
        for (var _i = 0; _i < 4; _i++) {
            if (_dir == 0) _cells[_i] = grid_get(_line, _i);          // left: row L->R
            else if (_dir == 1) _cells[_i] = grid_get(_line, 3 - _i); // right: row R->L
            else if (_dir == 2) _cells[_i] = grid_get(_i, _line);     // up: col T->B
            else _cells[_i] = grid_get(3 - _i, _line);                // down: col B->T
        }

        // Compact: remove zeros, slide to front
        var _compact = array_create(4, 0);
        var _pos = 0;
        for (var _i = 0; _i < 4; _i++) {
            if (_cells[_i] != 0) {
                _compact[_pos] = _cells[_i];
                _pos++;
            }
        }

        // Merge adjacent pairs
        var _merged = array_create(4, 0);
        var _mpos = 0;
        var _skip = false;
        for (var _i = 0; _i < 4; _i++) {
            if (_skip) {
                _skip = false;
                continue;
            }
            if (_compact[_i] == 0) continue;
            if (_i + 1 < 4 && _compact[_i] == _compact[_i + 1] && _compact[_i] != 0) {
                // Merge: create next element
                var _new_val = _compact[_i] + 1;
                _merged[_mpos] = _new_val;
                _pts += _new_val;
                _mpos++;
                _skip = true;
            } else {
                _merged[_mpos] = _compact[_i];
                _mpos++;
            }
        }

        // Write back to grid
        for (var _i = 0; _i < 4; _i++) {
            var _old_val = 0;
            if (_dir == 0) _old_val = grid_get(_line, _i);
            else if (_dir == 1) _old_val = grid_get(_line, 3 - _i);
            else if (_dir == 2) _old_val = grid_get(_i, _line);
            else _old_val = grid_get(3 - _i, _line);

            if (_old_val != _merged[_i]) _moved = true;

            if (_dir == 0) grid_set(_line, _i, _merged[_i]);
            else if (_dir == 1) grid_set(_line, 3 - _i, _merged[_i]);
            else if (_dir == 2) grid_set(_i, _line, _merged[_i]);
            else grid_set(3 - _i, _line, _merged[_i]);
        }
    }

    if (!_moved) return -1;
    return _pts;
}

/// @function reset_game()
/// Clear grid and spawn 2 starting atoms
function reset_game() {
    for (var _i = 0; _i < 16; _i++) {
        grid[_i] = 0;
    }
    spawn_atom();
    spawn_atom();
}

/// @function get_grid_string()
/// Serialize grid to string for save comparison
function get_grid_string() {
    var _s = "";
    for (var _i = 0; _i < 16; _i++) {
        _s += string(grid[_i]);
        if (_i < 15) _s += ",";
    }
    return _s;
}

// Place 2 starting atoms
reset_game();

// Screen dimensions (updated each frame)
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
        if (variable_struct_exists(_state.data, "grid")) {
            var _saved_grid = _state.data.grid;
            if (is_array(_saved_grid) && array_length(_saved_grid) == 16) {
                for (var _i = 0; _i < 16; _i++) {
                    grid[_i] = _saved_grid[_i];
                }
                // If saved grid had a game in progress, go straight to playing
                var _has_atoms = false;
                for (var _i = 0; _i < 16; _i++) {
                    if (grid[_i] != 0) { _has_atoms = true; break; }
                }
                if (_has_atoms) game_state = 1;
            }
        }
    }
    catch (_ex) {
        api_save_state(0, { points: points, grid: grid }, undefined);
    }
    alarm[0] = 60;
});
