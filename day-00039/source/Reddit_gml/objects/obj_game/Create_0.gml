/// @description Word Chain - Day 39

// ── Game state ──
game_state = 0; // 0=loading, 1=playing, 2=gameover
points = 0;
combo = 0;
max_combo = 0;
words_found = 0;
best_word = "";
best_word_pts = 0;

// ── Grid config ──
COLS = 6;
ROWS = 6;
grid = array_create(COLS * ROWS, "");

// ── Letter weights (Scrabble-ish distribution) ──
letter_bag = "EEEEEEEEEEAAAAAAAARRRRRRRIIIIIIIOOOOOOTTTTTTNNNNNNSSSSSSLLLLHHHHDDDDCCCCUUUUMMPPBBGGFFWWYYKKVJXQZ";

// ── Selection state ──
sel_path = [];
is_dragging = false;

// ── Timer ──
timer_max = 90;
timer_left = timer_max;

// ── Visual ──
cell_size = 0;
grid_x = 0;
grid_y = 0;
score_pops = [];
shake_timer = 0;
last_word = "";
last_word_timer = 0;
flash_cells = [];

// ── Combo chain ──
combo_timer = 0;

// ── Cell animation (vertical offset for drop/appear) ──
cell_anim = array_create(COLS * ROWS, 0); // negative = above target, animates to 0

// ── Pending removal (delay drop so flash plays on old tiles) ──
pending_remove_path = [];
pending_remove_timer = 0;

// ── Responsive ──
window_width = 0;
window_height = 0;

// ── Word dictionary (97k English words, 3-7 letters) ──
dict = ds_map_create();
load_dictionary(dict);
show_debug_message("Dictionary loaded: " + string(ds_map_size(dict)) + " words");

// ── Fill the grid ──
randomize();
fill_grid();

// Initial drop-in animation (staggered per row)
for (var _r = 0; _r < ROWS; _r++) {
    for (var _c = 0; _c < COLS; _c++) {
        cell_anim[_r * COLS + _c] = -(ROWS + 2 + _r) * 60;
    }
}

// ── Load saved state ──
api_load_state(function(_status, _ok, _result, _payload) {
    with (obj_game) {
        // _result may be a JSON string on HTML5 — parse it
        if (_ok && is_string(_result)) {
            try {
                var _parsed = json_parse(_result);
                if (is_struct(_parsed) && variable_struct_exists(_parsed, "data")) {
                    // Could restore personal best from _parsed.data
                }
            } catch(_e) {
                // ignore parse errors
            }
        }
        game_state = 1;
        timer_left = timer_max;
    }
});

/// @function fill_grid
function fill_grid() {
    var _bag_len = string_length(letter_bag);
    for (var _i = 0; _i < COLS * ROWS; _i++) {
        if (grid[_i] == "" || grid[_i] == " ") {
            grid[_i] = string_char_at(letter_bag, irandom_range(1, _bag_len));
        }
    }
}

/// @function grid_get(col, row)
function grid_get(_col, _row) {
    return grid[_row * COLS + _col];
}

/// @function grid_set(col, row, val)
function grid_set(_col, _row, _val) {
    grid[_row * COLS + _col] = _val;
}

/// @function is_adjacent(c1, r1, c2, r2)
function is_adjacent(_c1, _r1, _c2, _r2) {
    return (abs(_c1 - _c2) <= 1) && (abs(_r1 - _r2) <= 1) && !(_c1 == _c2 && _r1 == _r2);
}

/// @function path_contains(col, row)
function path_contains(_col, _row) {
    for (var _i = 0; _i < array_length(sel_path); _i++) {
        if (sel_path[_i][0] == _col && sel_path[_i][1] == _row) return true;
    }
    return false;
}

/// @function get_word_from_path
function get_word_from_path() {
    var _word = "";
    for (var _i = 0; _i < array_length(sel_path); _i++) {
        _word += grid_get(sel_path[_i][0], sel_path[_i][1]);
    }
    return _word;
}

/// @function is_valid_word(word)
function is_valid_word(_word) {
    return (string_length(_word) >= 3) && ds_map_exists(dict, string_upper(_word));
}

/// @function score_word(word)
function score_word(_word) {
    var _len = string_length(_word);
    switch (_len) {
        case 3: return 100;
        case 4: return 300;
        case 5: return 600;
        case 6: return 1000;
        default: return 1000 + (_len - 6) * 500;
    }
}

/// @function remove_and_drop
function remove_and_drop() {
    var _cs = max(cell_size, 60); // fallback if cell_size not yet calculated

    // Mark selected cells as empty
    for (var _i = 0; _i < array_length(sel_path); _i++) {
        grid_set(sel_path[_i][0], sel_path[_i][1], "");
    }

    // Process each column: compact down, then fill top
    for (var _c = 0; _c < COLS; _c++) {
        // Compact: move all non-empty cells to the bottom
        var _write = ROWS - 1;
        for (var _r = ROWS - 1; _r >= 0; _r--) {
            var _letter = grid_get(_c, _r);
            if (_letter != "") {
                if (_write != _r) {
                    grid_set(_c, _write, _letter);
                    grid_set(_c, _r, "");
                    // Animate from old position to new
                    cell_anim[_write * COLS + _c] = -(_write - _r) * _cs;
                }
                _write--;
            }
        }

        // _write is now the topmost empty row (or -1 if column is full)
        var _num_empty = _write + 1;

        // Fill empty cells at top with new random letters
        var _bag_len = string_length(letter_bag);
        for (var _r2 = _write; _r2 >= 0; _r2--) {
            grid_set(_c, _r2, string_char_at(letter_bag, irandom_range(1, _bag_len)));
            // Animate: new letters drop in from above the grid
            cell_anim[_r2 * COLS + _c] = -(_num_empty + 1) * _cs;
        }
    }
}

/// @function add_score_pop(x, y, text, color)
function add_score_pop(_x, _y, _text, _color) {
    array_push(score_pops, {
        px: _x,
        py: _y,
        text: _text,
        timer: 60,
        color: _color
    });
}
