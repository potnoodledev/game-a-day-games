/// @description Word Chain - Input handling

if (game_state != 1) exit;

// ── Timer ──
timer_left -= 1 / 60;
if (timer_left <= 0) {
    timer_left = 0;
    game_state = 2;
    // Submit score
    api_submit_score(points, undefined);
    api_save_state(0, { points: points, words: words_found, best_word: best_word, combo: max_combo }, undefined);
    exit;
}

// ── Pending tile removal (delayed to let flash play) ──
if (pending_remove_timer > 0) {
    pending_remove_timer--;
    if (pending_remove_timer == 0 && array_length(pending_remove_path) > 0) {
        sel_path = pending_remove_path;
        remove_and_drop();
        sel_path = [];
        pending_remove_path = [];
    }
}

// ── Combo decay ──
combo_timer++;
if (combo_timer > 120) { // 2 seconds without a word
    combo = 0;
}

// ── Score pop timers ──
for (var _i = array_length(score_pops) - 1; _i >= 0; _i--) {
    score_pops[_i].timer--;
    score_pops[_i].py -= 1;
    if (score_pops[_i].timer <= 0) {
        array_delete(score_pops, _i, 1);
    }
}

// ── Flash cell timers ──
for (var _i = array_length(flash_cells) - 1; _i >= 0; _i--) {
    flash_cells[_i].timer--;
    if (flash_cells[_i].timer <= 0) {
        array_delete(flash_cells, _i, 1);
    }
}

// ── Shake timer ──
if (shake_timer > 0) shake_timer--;

// ── Cell drop animation (lerp toward 0) ──
for (var _i = 0; _i < COLS * ROWS; _i++) {
    if (cell_anim[_i] != 0) {
        cell_anim[_i] = lerp(cell_anim[_i], 0, 0.2);
        if (abs(cell_anim[_i]) < 0.5) cell_anim[_i] = 0;
    }
}

// ── Last word display ──
if (last_word_timer > 0) last_word_timer--;

// ── Touch / Mouse Input ──
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _pressed = device_mouse_check_button_pressed(0, mb_left);
var _held = device_mouse_check_button(0, mb_left);
var _released = device_mouse_check_button_released(0, mb_left);

// Convert mouse to nearest cell center (radius-based for easier diagonals)
var _col = floor((_mx - grid_x) / cell_size);
var _row = floor((_my - grid_y) / cell_size);
var _in_grid = (_col >= 0 && _col < COLS && _row >= 0 && _row < ROWS);

// Find closest cell by distance to center (checks all adjacent cells)
// This makes diagonals much easier to hit
var _best_col = _col;
var _best_row = _row;
var _best_dist = 99999;
var _hit_radius = cell_size * 0.55; // generous radius

for (var _rc = max(0, _row - 1); _rc <= min(ROWS - 1, _row + 1); _rc++) {
    for (var _cc = max(0, _col - 1); _cc <= min(COLS - 1, _col + 1); _cc++) {
        var _cx = grid_x + _cc * cell_size + cell_size / 2;
        var _cy = grid_y + _rc * cell_size + cell_size / 2;
        var _d = point_distance(_mx, _my, _cx, _cy);
        if (_d < _best_dist && _d < _hit_radius) {
            _best_dist = _d;
            _best_col = _cc;
            _best_row = _rc;
        }
    }
}

// Also check if mouse is broadly in grid area
var _in_grid_area = (_mx >= grid_x - cell_size * 0.3 && _mx <= grid_x + COLS * cell_size + cell_size * 0.3
                  && _my >= grid_y - cell_size * 0.3 && _my <= grid_y + ROWS * cell_size + cell_size * 0.3);

// Start drag
if (_pressed && _in_grid) {
    is_dragging = true;
    sel_path = [];
    array_push(sel_path, [_col, _row]);
}

// Continue drag — use center-based nearest cell
if (_held && is_dragging && _in_grid_area && _best_dist < _hit_radius) {
    var _path_len = array_length(sel_path);
    if (_path_len > 0) {
        var _last_col = sel_path[_path_len - 1][0];
        var _last_row = sel_path[_path_len - 1][1];

        if (!(_best_col == _last_col && _best_row == _last_row)) {
            // Add if adjacent and not already in path
            if (is_adjacent(_last_col, _last_row, _best_col, _best_row) && !path_contains(_best_col, _best_row)) {
                array_push(sel_path, [_best_col, _best_row]);
            }
            // Allow backtracking: if hovering second-to-last cell, remove last
            if (_path_len >= 2) {
                var _prev_col = sel_path[_path_len - 2][0];
                var _prev_row = sel_path[_path_len - 2][1];
                if (_best_col == _prev_col && _best_row == _prev_row) {
                    array_pop(sel_path);
                }
            }
        }
    }
}

// Release drag - submit word
if (_released && is_dragging) {
    is_dragging = false;
    var _word = get_word_from_path();

    if (is_valid_word(_word)) {
        // Score it
        var _base = score_word(_word);
        combo++;
        combo_timer = 0;
        if (combo > max_combo) max_combo = combo;

        var _mult = 1;
        if (combo >= 3) _mult = 2;
        if (combo >= 6) _mult = 3;

        var _total = _base * _mult;
        points += _total;
        words_found++;

        if (_total > best_word_pts) {
            best_word_pts = _total;
            best_word = _word;
        }

        last_word = _word;
        last_word_timer = 90;

        // Flash cells green
        for (var _i = 0; _i < array_length(sel_path); _i++) {
            array_push(flash_cells, {
                col: sel_path[_i][0],
                row: sel_path[_i][1],
                timer: 12,
                color: $00FF88
            });
        }

        // Score pop at center of word
        var _mid = floor(array_length(sel_path) / 2);
        var _px = grid_x + sel_path[_mid][0] * cell_size + cell_size / 2;
        var _py = grid_y + sel_path[_mid][1] * cell_size;
        var _pop_text = "+" + string(_total);
        if (_mult > 1) _pop_text += " x" + string(_mult);
        add_score_pop(_px, _py, _pop_text, $00FF88);

        // Queue removal — delay so flash plays on old tiles first
        pending_remove_path = array_create(array_length(sel_path));
        for (var _i = 0; _i < array_length(sel_path); _i++) {
            pending_remove_path[_i] = [sel_path[_i][0], sel_path[_i][1]];
        }
        pending_remove_timer = 10; // frames to wait before dropping
    } else if (string_length(_word) >= 3) {
        // Invalid word — shake
        shake_timer = 10;
        for (var _i = 0; _i < array_length(sel_path); _i++) {
            array_push(flash_cells, {
                col: sel_path[_i][0],
                row: sel_path[_i][1],
                timer: 15,
                color: $0000FF
            });
        }
    }

    sel_path = [];
}
