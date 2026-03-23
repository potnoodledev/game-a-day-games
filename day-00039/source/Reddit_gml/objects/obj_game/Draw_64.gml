/// @description Word Chain - Render

var _w = window_width;
var _h = window_height;
if (_w == 0 || _h == 0) exit;

var _shake_x = 0;
var _shake_y = 0;
if (shake_timer > 0) {
    _shake_x = irandom_range(-3, 3);
    _shake_y = irandom_range(-3, 3);
}

// ── Background ──
draw_set_alpha(1);
draw_set_colour($1A0A0A);
draw_rectangle(0, 0, _w, _h, false);

// ── Top bar: Timer + Score ──
var _bar_h = 8;
var _bar_y = 20;
var _bar_pad = 24;
var _bar_w = _w - _bar_pad * 2;

// Timer bar background
draw_set_colour($333333);
draw_roundrect_ext(_bar_pad, _bar_y, _bar_pad + _bar_w, _bar_y + _bar_h, 4, 4, false);

// Timer bar fill
var _frac = clamp(timer_left / timer_max, 0, 1);
var _timer_color = merge_colour($00FF88, $0000FF, 1 - _frac); // green to red
draw_set_colour(_timer_color);
if (_frac > 0) {
    draw_roundrect_ext(_bar_pad, _bar_y, _bar_pad + _bar_w * _frac, _bar_y + _bar_h, 4, 4, false);
}

// Timer text
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour($888888);
draw_text_ext_transformed(_bar_pad, _bar_y + 14, string(ceil(timer_left)) + "s", 0, 400, 1.5, 1.5, 0);

// Score
draw_set_halign(fa_right);
draw_set_colour($FFFFFF);
draw_text_ext_transformed(_w - _bar_pad, _bar_y + 14, string(points), 0, 400, 2.5, 2.5, 0);

// Combo indicator
if (combo >= 2 && game_state == 1) {
    draw_set_halign(fa_right);
    draw_set_colour($00DDFF);
    var _combo_text = "x" + string(combo) + " CHAIN";
    if (combo >= 6) {
        draw_set_colour($FF44FF);
        _combo_text = "x" + string(combo) + " FRENZY!";
    } else if (combo >= 3) {
        draw_set_colour($44FF88);
        _combo_text = "x" + string(combo) + " COMBO!";
    }
    draw_text_ext_transformed(_w - _bar_pad, _bar_y + 48, _combo_text, 0, 400, 1.5, 1.5, 0);
}

// ── Grid ──
var _gx = grid_x + _shake_x;
var _gy = grid_y + _shake_y;
var _cs = cell_size;
var _gap = 3;
var _tile_size = _cs - _gap * 2;
var _corner = max(4, _tile_size * 0.15);

for (var _r = 0; _r < ROWS; _r++) {
    for (var _c = 0; _c < COLS; _c++) {
        var _anim_off = cell_anim[_r * COLS + _c];
        var _tx = _gx + _c * _cs + _gap;
        var _ty = _gy + _r * _cs + _gap + _anim_off;
        var _letter = grid_get(_c, _r);

        // Check if this cell is selected
        var _selected = false;
        var _sel_idx = -1;
        for (var _i = 0; _i < array_length(sel_path); _i++) {
            if (sel_path[_i][0] == _c && sel_path[_i][1] == _r) {
                _selected = true;
                _sel_idx = _i;
                break;
            }
        }

        // Check flash
        var _flash_col = -1;
        for (var _i = 0; _i < array_length(flash_cells); _i++) {
            if (flash_cells[_i].col == _c && flash_cells[_i].row == _r) {
                _flash_col = flash_cells[_i].color;
                break;
            }
        }

        // Tile background
        if (_flash_col >= 0) {
            draw_set_colour(_flash_col);
            draw_set_alpha(0.5);
        } else if (_selected) {
            draw_set_colour($FF9933); // warm orange for selected
            draw_set_alpha(0.85);
        } else {
            draw_set_colour($2A1A2A);
            draw_set_alpha(1);
        }
        draw_roundrect_ext(_tx, _ty, _tx + _tile_size, _ty + _tile_size, _corner, _corner, false);
        draw_set_alpha(1);

        // Tile border
        if (_selected) {
            draw_set_colour($FFCC66);
        } else {
            draw_set_colour($3A2A3A);
        }
        draw_roundrect_ext(_tx, _ty, _tx + _tile_size, _ty + _tile_size, _corner, _corner, true);

        // Letter
        if (_letter != "" && _letter != " ") {
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            var _font_scale = _tile_size / 28;
            if (_selected) {
                draw_set_colour($FFFFFF);
            } else {
                draw_set_colour($DDCCDD);
            }
            draw_text_ext_transformed(
                _tx + _tile_size / 2,
                _ty + _tile_size / 2,
                _letter, 0, 200,
                _font_scale, _font_scale, 0
            );
        }
    }
}

// ── Draw path line ──
if (array_length(sel_path) >= 2 && is_dragging) {
    draw_set_colour($FFCC66);
    draw_set_alpha(0.6);
    for (var _i = 0; _i < array_length(sel_path) - 1; _i++) {
        var _x1 = _gx + sel_path[_i][0] * _cs + _cs / 2;
        var _y1 = _gy + sel_path[_i][1] * _cs + _cs / 2;
        var _x2 = _gx + sel_path[_i + 1][0] * _cs + _cs / 2;
        var _y2 = _gy + sel_path[_i + 1][1] * _cs + _cs / 2;
        // Draw thick line (multiple offsets)
        var _lw = 3;
        draw_line_width(_x1, _y1, _x2, _y2, _lw);
    }
    draw_set_alpha(1);
}

// ── Current word being spelled (shown above grid) ──
if (is_dragging && array_length(sel_path) >= 1) {
    var _cur_word = get_word_from_path();
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    var _valid = is_valid_word(_cur_word);
    if (_valid) {
        draw_set_colour($00FF88);
    } else if (string_length(_cur_word) >= 3) {
        draw_set_colour($FF6644);
    } else {
        draw_set_colour($888888);
    }
    draw_text_ext_transformed(_w / 2, _gy - 8, _cur_word, 0, 400, 2.5, 2.5, 0);
}

// ── Last word found ──
if (last_word_timer > 0 && !is_dragging) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_colour($00FF88);
    draw_set_alpha(min(1, last_word_timer / 30));
    draw_text_ext_transformed(_w / 2, _gy - 8, last_word, 0, 400, 2, 2, 0);
    draw_set_alpha(1);
}

// ── Score pops ──
for (var _i = 0; _i < array_length(score_pops); _i++) {
    var _pop = score_pops[_i];
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(_pop.color);
    draw_set_alpha(clamp(_pop.timer / 30, 0, 1));
    var _pop_scale = 1.5 + (60 - _pop.timer) * 0.02;
    draw_text_ext_transformed(_pop.px, _pop.py, _pop.text, 0, 400, _pop_scale, _pop_scale, 0);
    draw_set_alpha(1);
}

// ── Bottom stats ──
var _bot_y = _gy + ROWS * _cs + 16;
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour($666666);
draw_text_ext_transformed(_bar_pad, _bot_y, "Words: " + string(words_found), 0, 400, 1.3, 1.3, 0);
draw_set_halign(fa_right);
draw_text_ext_transformed(_w - _bar_pad, _bot_y, "Best: " + best_word, 0, 400, 1.3, 1.3, 0);

// ── Game Over overlay ──
if (game_state == 2) {
    // Dim background
    draw_set_alpha(0.8);
    draw_set_colour($000000);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1);

    var _cy = _h * 0.3;
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Title
    draw_set_colour($FFFFFF);
    draw_text_ext_transformed(_w / 2, _cy, "TIME'S UP!", 0, 400, 3, 3, 0);

    // Score
    _cy += 60;
    draw_set_colour($00FF88);
    draw_text_ext_transformed(_w / 2, _cy, string(points) + " pts", 0, 400, 3.5, 3.5, 0);

    // Stats
    _cy += 60;
    draw_set_colour($AAAAAA);
    draw_text_ext_transformed(_w / 2, _cy, string(words_found) + " words found", 0, 400, 1.8, 1.8, 0);

    _cy += 35;
    if (best_word != "") {
        draw_set_colour($FFCC66);
        draw_text_ext_transformed(_w / 2, _cy, "Best: " + best_word + " (+" + string(best_word_pts) + ")", 0, 400, 1.5, 1.5, 0);
    }

    _cy += 35;
    if (max_combo >= 3) {
        draw_set_colour($44FF88);
        draw_text_ext_transformed(_w / 2, _cy, "Max chain: " + string(max_combo), 0, 400, 1.5, 1.5, 0);
    }

    // Tap to replay
    _cy += 60;
    draw_set_colour($888888);
    var _blink = (current_time div 500) mod 2;
    if (_blink == 0) {
        draw_text_ext_transformed(_w / 2, _cy, "Tap to play again", 0, 400, 1.5, 1.5, 0);
    }

    // Handle tap to restart
    if (device_mouse_check_button_pressed(0, mb_left)) {
        game_state = 1;
        points = 0;
        combo = 0;
        max_combo = 0;
        words_found = 0;
        best_word = "";
        best_word_pts = 0;
        timer_left = timer_max;
        last_word = "";
        last_word_timer = 0;
        sel_path = [];
        score_pops = [];
        flash_cells = [];
        combo_timer = 0;
        // Refill grid with drop animation
        for (var _i = 0; _i < COLS * ROWS; _i++) grid[_i] = "";
        fill_grid();
        for (var _r = 0; _r < ROWS; _r++) {
            for (var _c = 0; _c < COLS; _c++) {
                cell_anim[_r * COLS + _c] = -(ROWS + 2 + _r) * 60;
            }
        }
    }
}

// ── Loading state ──
if (game_state == 0) {
    draw_set_alpha(0.8);
    draw_set_colour($000000);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour($FFFFFF);
    draw_text_ext_transformed(_w / 2, _h / 2, "Loading...", 0, 400, 2, 2, 0);
}
