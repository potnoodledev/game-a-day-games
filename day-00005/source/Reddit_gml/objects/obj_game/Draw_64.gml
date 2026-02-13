
var _sw = display_get_gui_width();
var _sh = display_get_gui_height();

// Background
draw_set_colour(make_colour_rgb(26, 26, 46));
draw_rectangle(0, 0, _sw, _sh, false);

// Calculate grid layout
var _padding = 16;
var _grid_size = min(_sw - _padding * 2, _sh * 0.7);
var _cell_pad = 6;
var _cell_size = (_grid_size - _cell_pad * 5) / 4;
var _grid_x = (_sw - _grid_size) / 2;
var _grid_y = (_sh - _grid_size) / 2 + 30;

// Score display at top
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(fnt_default);

// Score label
var _score_y = _grid_y - 50;
draw_set_colour(make_colour_rgb(180, 180, 200));
draw_text_ext_transformed(_sw / 2, _score_y - 20, "SCORE", 0, _sw, 1.5, 1.5, 0);
draw_set_colour(c_white);
draw_text_ext_transformed(_sw / 2, _score_y + 10, string(points), 0, _sw, 2.5, 2.5, 0);

// Draw grid background
draw_set_colour(make_colour_rgb(40, 40, 70));
draw_roundrect_ext(_grid_x, _grid_y, _grid_x + _grid_size, _grid_y + _grid_size, 12, 12, false);

// Draw cells
for (var _r = 0; _r < 4; _r++) {
    for (var _c = 0; _c < 4; _c++) {
        var _cx = _grid_x + _cell_pad + _c * (_cell_size + _cell_pad);
        var _cy = _grid_y + _cell_pad + _r * (_cell_size + _cell_pad);
        var _val = grid_get(_r, _c);

        if (_val == 0) {
            // Empty cell
            draw_set_colour(make_colour_rgb(50, 50, 80));
            draw_roundrect_ext(_cx, _cy, _cx + _cell_size, _cy + _cell_size, 8, 8, false);
        } else {
            // Atom tile
            var _col_idx = min(_val, array_length(elem_col) - 1);
            var _tile_col = elem_col[_col_idx];

            // Tile background
            draw_set_colour(_tile_col);
            draw_roundrect_ext(_cx, _cy, _cx + _cell_size, _cy + _cell_size, 8, 8, false);

            // Darker border
            draw_set_colour(merge_colour(_tile_col, c_black, 0.3));
            draw_roundrect_ext(_cx, _cy, _cx + _cell_size, _cy + _cell_size, 8, 8, true);

            // Element symbol (centered)
            var _sym_idx = min(_val, array_length(elem_sym) - 1);
            var _sym = elem_sym[_sym_idx];
            var _mid_x = _cx + _cell_size / 2;
            var _mid_y = _cy + _cell_size / 2;

            // Text color: use brightness to decide
            var _brightness = colour_get_red(_tile_col) * 0.299 + colour_get_green(_tile_col) * 0.587 + colour_get_blue(_tile_col) * 0.114;
            if (_brightness > 150) {
                draw_set_colour(make_colour_rgb(30, 30, 50));
            } else {
                draw_set_colour(c_white);
            }

            // Draw symbol - scale based on cell size
            var _sym_scale = _cell_size / 40;
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_text_ext_transformed(_mid_x, _mid_y - 4, _sym, 0, _cell_size, _sym_scale, _sym_scale, 0);

            // Atomic number (small, top-left corner)
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            var _num_scale = _cell_size / 90;
            draw_text_ext_transformed(_cx + 4, _cy + 2, string(_val), 0, _cell_size, _num_scale, _num_scale, 0);
        }
    }
}

// Hint text below grid
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_set_colour(make_colour_rgb(100, 100, 140));
var _hint_y = _grid_y + _grid_size + 12;
draw_text_ext_transformed(_sw / 2, _hint_y, "Swipe or use arrow keys", 0, _sw, 1.2, 1.2, 0);

// === STATE 0: TITLE OVERLAY ===
if (game_state == 0) {
    // Semi-transparent overlay
    draw_set_alpha(0.85);
    draw_set_colour(make_colour_rgb(26, 26, 46));
    draw_rectangle(0, 0, _sw, _sh, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Title
    draw_set_colour(make_colour_rgb(91, 192, 235));
    draw_text_ext_transformed(_sw / 2, _sh * 0.3, "2048", 0, _sw, 5, 5, 0);

    draw_set_colour(make_colour_rgb(253, 231, 76));
    draw_text_ext_transformed(_sw / 2, _sh * 0.3 + 60, "but Atoms", 0, _sw, 3, 3, 0);

    // Subtitle
    draw_set_colour(make_colour_rgb(180, 180, 200));
    draw_text_ext_transformed(_sw / 2, _sh * 0.55, "Merge atoms to discover elements!", 0, _sw - 40, 1.5, 1.5, 0);
    draw_text_ext_transformed(_sw / 2, _sh * 0.55 + 30, "H + H = He, He + He = Li ...", 0, _sw - 40, 1.3, 1.3, 0);

    // Start prompt
    draw_set_colour(c_white);
    var _pulse = 0.6 + sin(current_time / 400) * 0.4;
    draw_set_alpha(_pulse);
    draw_text_ext_transformed(_sw / 2, _sh * 0.75, "Tap to start", 0, _sw, 2, 2, 0);
    draw_set_alpha(1);
}

// === STATE 2: GAME OVER OVERLAY ===
if (game_state == 2) {
    // Semi-transparent overlay
    draw_set_alpha(0.75);
    draw_set_colour(make_colour_rgb(26, 26, 46));
    draw_rectangle(0, 0, _sw, _sh, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Find highest element reached
    var _max_elem = 0;
    for (var _i = 0; _i < 16; _i++) {
        if (grid[_i] > _max_elem) _max_elem = grid[_i];
    }
    var _max_sym_idx = min(_max_elem, array_length(elem_sym) - 1);
    var _max_name_idx = min(_max_elem, array_length(elem_name) - 1);

    // Game Over text
    draw_set_colour(make_colour_rgb(255, 107, 107));
    draw_text_ext_transformed(_sw / 2, _sh * 0.25, "No more moves!", 0, _sw, 2.5, 2.5, 0);

    // Score
    draw_set_colour(c_white);
    draw_text_ext_transformed(_sw / 2, _sh * 0.4, "Score: " + string(points), 0, _sw, 2.5, 2.5, 0);

    // Highest element
    if (_max_elem > 0) {
        var _elem_col_idx = min(_max_elem, array_length(elem_col) - 1);
        draw_set_colour(elem_col[_elem_col_idx]);
        draw_text_ext_transformed(_sw / 2, _sh * 0.55, "Highest: " + elem_sym[_max_sym_idx] + " (" + elem_name[_max_name_idx] + ")", 0, _sw - 20, 1.8, 1.8, 0);
    }

    // Restart prompt
    draw_set_colour(c_white);
    var _pulse2 = 0.6 + sin(current_time / 400) * 0.4;
    draw_set_alpha(_pulse2);
    draw_text_ext_transformed(_sw / 2, _sh * 0.75, "Tap to retry", 0, _sw, 2, 2, 0);
    draw_set_alpha(1);
}
