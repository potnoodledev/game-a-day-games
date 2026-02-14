
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _ss = max(1, _gh / 600);


// Screen shake offset
var _sx = 0;
var _sy = 0;
if (shake_amount > 0) {
    _sx = irandom_range(-shake_amount, shake_amount);
    _sy = irandom_range(-shake_amount, shake_amount);
}

// === BACKGROUND ===
draw_set_colour(col_bg);
draw_rectangle(0, 0, _gw, _gh, false);

// === HUD BAR (top 8%) ===
var _hud_h = _gh * 0.08;
draw_set_colour(col_hud_bg);
draw_rectangle(0, 0, _gw, _hud_h, false);

draw_set_font(fnt_default);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour(make_colour_rgb(200, 180, 255));
draw_text_ext_transformed(_gw * 0.04 + _sx, _hud_h * 0.5 + _sy, $"Floor {floor_num}", 0, _gw, _ss * 1.3, _ss * 1.3, 0);

draw_set_halign(fa_right);
draw_set_colour(tile_colors[3]);
draw_text_ext_transformed(_gw * 0.96 + _sx, _hud_h * 0.5 + _sy, $"{points} pts", 0, _gw, _ss * 1.3, _ss * 1.3, 0);

// === ENEMY SECTION (8% - 30%) ===
var _enemy_top = _hud_h;
var _enemy_bottom = _gh * 0.30;
var _enemy_h = _enemy_bottom - _enemy_top;
var _ecx = _gw * 0.5 + _sx;
var _ecy = _enemy_top + _enemy_h * 0.45 + _sy;
var _er = min(_enemy_h * 0.3, _gw * 0.12);

// Enemy body (dark circle)
var _enemy_body_col = make_colour_rgb(100, 40, 120);
if (enemy_hurt_timer > 0) {
    _enemy_body_col = c_white;
}
draw_set_colour(_enemy_body_col);
draw_circle(_ecx, _ecy, _er, false);

// Enemy eyes
var _eye_r = _er * 0.2;
var _eye_dx = _er * 0.35;
draw_set_colour(make_colour_rgb(255, 50, 50));
draw_circle(_ecx - _eye_dx, _ecy - _er * 0.15, _eye_r, false);
draw_circle(_ecx + _eye_dx, _ecy - _er * 0.15, _eye_r, false);
// Pupils
draw_set_colour(c_black);
draw_circle(_ecx - _eye_dx, _ecy - _er * 0.1, _eye_r * 0.5, false);
draw_circle(_ecx + _eye_dx, _ecy - _er * 0.1, _eye_r * 0.5, false);

// Enemy mouth (jagged)
draw_set_colour(make_colour_rgb(200, 30, 60));
var _mw = _er * 0.6;
var _my = _ecy + _er * 0.3;
draw_rectangle(_ecx - _mw, _my - _er * 0.08, _ecx + _mw, _my + _er * 0.08, false);
// Teeth
draw_set_colour(c_white);
var _tw = _mw * 0.25;
for (var _i = 0; _i < 4; _i++) {
    var _tx = _ecx - _mw + _tw * 0.5 + _i * _tw * 1.3;
    draw_triangle(_tx, _my - _er * 0.08, _tx + _tw * 0.5, _my + _er * 0.06, _tx - _tw * 0.5, _my + _er * 0.06, false);
}

// Enemy HP bar
var _bar_w = _gw * 0.5;
var _bar_h = _ss * 8;
var _bar_x = _gw * 0.5 - _bar_w * 0.5;
var _bar_y = _enemy_bottom - _bar_h - _ss * 6;

// Bar background
draw_set_colour(make_colour_rgb(40, 10, 10));
draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);

// Bar fill
var _hp_ratio = clamp(enemy_hp / enemy_max_hp, 0, 1);
var _fill_col = merge_colour(col_hp_red, make_colour_rgb(180, 30, 30), 0.3);
draw_set_colour(_fill_col);
draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * _hp_ratio, _bar_y + _bar_h, false);

// Bar border
draw_set_colour(make_colour_rgb(80, 30, 30));
draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, true);

// Enemy HP text
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(c_white);
draw_text_ext_transformed(_gw * 0.5, _bar_y + _bar_h * 0.5, $"{max(0, enemy_hp)}/{enemy_max_hp}", 0, _gw, _ss * 0.9, _ss * 0.9, 0);

// Enemy attack indicator
draw_set_halign(fa_right);
draw_set_colour(make_colour_rgb(255, 100, 100));
draw_text_ext_transformed(_bar_x + _bar_w, _bar_y - _ss * 8, $"ATK: {enemy_atk}", 0, _gw, _ss * 0.85, _ss * 0.85, 0);

// === GRID (32% - 72%) ===
var _grid_avail_h = _gh * 0.40;
var _cell_size = min((_gw * 0.9) / grid_size, _grid_avail_h / grid_size);
var _grid_w = _cell_size * grid_size;
var _grid_top = _gh * 0.32 + _sy;
var _grid_left = (_gw - _grid_w) * 0.5 + _sx;
var _gap = _cell_size * 0.06;
var _inner = _cell_size - _gap * 2;

for (var _row = 0; _row < grid_size; _row++) {
    for (var _col = 0; _col < grid_size; _col++) {
        var _idx = _row * grid_size + _col;
        var _cx = _grid_left + _col * _cell_size + _gap;
        var _cy = _grid_top + _row * _cell_size + _gap;

        if (grid_type[_idx] == -1) {
            // Empty cell
            draw_set_colour(col_cell_empty);
            draw_roundrect(_cx, _cy, _cx + _inner, _cy + _inner, false);
            draw_set_colour(col_cell_border);
            draw_roundrect(_cx, _cy, _cx + _inner, _cy + _inner, true);
        } else {
            // Occupied cell — draw tile
            var _t = grid_type[_idx];
            var _l = grid_level[_idx];

            // Cell background (dark version of tile color)
            draw_set_colour(tile_dark_colors[_t]);
            draw_roundrect(_cx, _cy, _cx + _inner, _cy + _inner, false);

            // Tile colored center
            var _inset = _inner * 0.1;
            var _tcol = tile_colors[_t];
            if (merge_flash_timer > 0) {
                _tcol = merge_colour(_tcol, c_white, merge_flash_timer / 12);
            }
            draw_set_colour(_tcol);
            draw_roundrect(_cx + _inset, _cy + _inset, _cx + _inner - _inset, _cy + _inner - _inset, false);

            // Draw tile symbol
            var _mid_x = _cx + _inner * 0.5;
            var _mid_y = _cy + _inner * 0.5;
            var _sym_r = _inner * 0.22;
            draw_set_colour(c_white);

            if (_t == 0) {
                // Sword: vertical line + crossbar
                draw_line_width(_mid_x, _mid_y - _sym_r, _mid_x, _mid_y + _sym_r, max(2, _ss * 1.5));
                draw_line_width(_mid_x - _sym_r * 0.6, _mid_y - _sym_r * 0.1, _mid_x + _sym_r * 0.6, _mid_y - _sym_r * 0.1, max(2, _ss * 1.5));
            }
            else if (_t == 1) {
                // Shield: rounded rect outline
                var _shr = _sym_r * 0.8;
                draw_roundrect(_mid_x - _shr, _mid_y - _shr, _mid_x + _shr, _mid_y + _shr * 0.6, true);
                // Point at bottom
                draw_line_width(_mid_x - _shr, _mid_y + _shr * 0.6, _mid_x, _mid_y + _shr * 1.1, max(1, _ss));
                draw_line_width(_mid_x + _shr, _mid_y + _shr * 0.6, _mid_x, _mid_y + _shr * 1.1, max(1, _ss));
            }
            else if (_t == 2) {
                // Heart: two circles + triangle
                var _hr = _sym_r * 0.4;
                draw_circle(_mid_x - _hr, _mid_y - _hr * 0.3, _hr, false);
                draw_circle(_mid_x + _hr, _mid_y - _hr * 0.3, _hr, false);
                draw_triangle(_mid_x - _sym_r * 0.7, _mid_y, _mid_x + _sym_r * 0.7, _mid_y, _mid_x, _mid_y + _sym_r * 0.8, false);
            }
            else if (_t == 3) {
                // Coin: circle with $ sign
                draw_circle(_mid_x, _mid_y, _sym_r * 0.65, true);
                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                draw_text_ext_transformed(_mid_x, _mid_y, "$", 0, _gw, _ss * 0.9, _ss * 0.9, 0);
            }

            // Level number (top-right corner)
            draw_set_halign(fa_right);
            draw_set_valign(fa_top);
            var _lvl_str = "";
            if (_l == 4) _lvl_str = "S";
            else _lvl_str = string(_l);

            // Level badge background
            var _badge_r = _inner * 0.14;
            var _badge_x = _cx + _inner - _inset;
            var _badge_y = _cy + _inset;
            draw_set_colour(make_colour_rgb(20, 20, 40));
            draw_circle(_badge_x - _badge_r, _badge_y + _badge_r, _badge_r, false);
            draw_set_colour(c_white);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_text_ext_transformed(_badge_x - _badge_r, _badge_y + _badge_r, _lvl_str, 0, _gw, _ss * 0.7, _ss * 0.7, 0);
        }
    }
}

// === PREVIEW + PLAYER HP (72% - 90%) ===
var _preview_y = _gh * 0.74 + _sy;
var _bar_area_h = _gh * 0.16;

// Current tile preview
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour(make_colour_rgb(150, 140, 180));
draw_text_ext_transformed(_gw * 0.04 + _sx, _preview_y + _ss * 2, "NEXT:", 0, _gw, _ss * 0.9, _ss * 0.9, 0);

// Draw current tile preview box
var _prev_size = _bar_area_h * 0.55;
var _prev_x = _gw * 0.18 + _sx;
var _prev_y = _preview_y - _prev_size * 0.3;

// Current tile box
draw_set_colour(tile_dark_colors[current_tile_type]);
draw_roundrect(_prev_x, _prev_y, _prev_x + _prev_size, _prev_y + _prev_size, false);
draw_set_colour(tile_colors[current_tile_type]);
var _pi = _prev_size * 0.1;
draw_roundrect(_prev_x + _pi, _prev_y + _pi, _prev_x + _prev_size - _pi, _prev_y + _prev_size - _pi, false);

// Tile symbol in preview
var _pmx = _prev_x + _prev_size * 0.5;
var _pmy = _prev_y + _prev_size * 0.5;
var _psr = _prev_size * 0.2;
draw_set_colour(c_white);
if (current_tile_type == 0) {
    draw_line_width(_pmx, _pmy - _psr, _pmx, _pmy + _psr, max(2, _ss * 1.5));
    draw_line_width(_pmx - _psr * 0.6, _pmy - _psr * 0.1, _pmx + _psr * 0.6, _pmy - _psr * 0.1, max(2, _ss * 1.5));
} else if (current_tile_type == 1) {
    var _shr = _psr * 0.8;
    draw_roundrect(_pmx - _shr, _pmy - _shr, _pmx + _shr, _pmy + _shr * 0.6, true);
    draw_line_width(_pmx - _shr, _pmy + _shr * 0.6, _pmx, _pmy + _shr * 1.1, max(1, _ss));
    draw_line_width(_pmx + _shr, _pmy + _shr * 0.6, _pmx, _pmy + _shr * 1.1, max(1, _ss));
} else if (current_tile_type == 2) {
    var _hr = _psr * 0.4;
    draw_circle(_pmx - _hr, _pmy - _hr * 0.3, _hr, false);
    draw_circle(_pmx + _hr, _pmy - _hr * 0.3, _hr, false);
    draw_triangle(_pmx - _psr * 0.7, _pmy, _pmx + _psr * 0.7, _pmy, _pmx, _pmy + _psr * 0.8, false);
} else {
    draw_circle(_pmx, _pmy, _psr * 0.65, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(_pmx, _pmy, "$", 0, _gw, _ss * 0.8, _ss * 0.8, 0);
}

// Next tile (smaller, to the right)
var _next_size = _prev_size * 0.6;
var _next_x = _prev_x + _prev_size + _gw * 0.03;
var _next_y = _prev_y + (_prev_size - _next_size) * 0.5;
draw_set_alpha(0.5);
draw_set_colour(tile_dark_colors[next_tile_type]);
draw_roundrect(_next_x, _next_y, _next_x + _next_size, _next_y + _next_size, false);
draw_set_colour(tile_colors[next_tile_type]);
draw_roundrect(_next_x + _pi * 0.6, _next_y + _pi * 0.6, _next_x + _next_size - _pi * 0.6, _next_y + _next_size - _pi * 0.6, false);
draw_set_alpha(1.0);

// Player HP bar (right side)
var _php_w = _gw * 0.32;
var _php_h = _ss * 10;
var _php_x = _gw * 0.96 - _php_w + _sx;
var _php_y = _preview_y + _sy;

// Label
draw_set_halign(fa_right);
draw_set_valign(fa_bottom);
draw_set_colour(make_colour_rgb(150, 140, 180));
draw_text_ext_transformed(_php_x + _php_w, _php_y - _ss * 2, "YOUR HP", 0, _gw, _ss * 0.8, _ss * 0.8, 0);

// Bar bg
draw_set_colour(make_colour_rgb(40, 10, 10));
draw_rectangle(_php_x, _php_y, _php_x + _php_w, _php_y + _php_h, false);

// Bar fill
var _php_ratio = clamp(player_hp / player_max_hp, 0, 1);
var _php_col = col_hp_green;
if (_php_ratio < 0.3) _php_col = col_hp_red;
else if (_php_ratio < 0.6) _php_col = make_colour_rgb(220, 180, 40);
if (player_hurt_timer > 0) _php_col = c_white;
draw_set_colour(_php_col);
draw_rectangle(_php_x, _php_y, _php_x + _php_w * _php_ratio, _php_y + _php_h, false);

// Bar border
draw_set_colour(make_colour_rgb(30, 80, 30));
draw_rectangle(_php_x, _php_y, _php_x + _php_w, _php_y + _php_h, true);

// HP text
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(c_white);
draw_text_ext_transformed(_php_x + _php_w * 0.5, _php_y + _php_h * 0.5, $"{max(0, player_hp)}/{player_max_hp}", 0, _gw, _ss * 0.85, _ss * 0.85, 0);

// Shield indicator
if (shield_turns > 0) {
    draw_set_halign(fa_right);
    draw_set_valign(fa_top);
    draw_set_colour(col_shield_blue);
    draw_text_ext_transformed(_php_x + _php_w, _php_y + _php_h + _ss * 3, $"Shield: {shield_turns}", 0, _gw, _ss * 0.85, _ss * 0.85, 0);
}

// === FLOATING TEXT ===
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
for (var _i = 0; _i < fx_max; _i++) {
    if (fx_life[_i] > 0) {
        var _alpha = fx_life[_i] / fx_max_life[_i];
        draw_set_alpha(_alpha);
        draw_set_colour(fx_col[_i]);
        draw_text_ext_transformed(fx_x[_i], fx_y[_i], fx_text[_i], 0, _gw, _ss * 1.2, _ss * 1.2, 0);
    }
}
draw_set_alpha(1.0);


// === TITLE OVERLAY (state 0) ===
if (game_state == 0) {
    // Dim overlay
    draw_set_alpha(0.7);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1.0);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Title
    draw_set_colour(make_colour_rgb(255, 200, 100));
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.3, "DUNGEON MERGE", 0, _gw, _ss * 2.5, _ss * 2.5, 0);

    // Subtitle
    draw_set_colour(make_colour_rgb(180, 160, 220));
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.38, "Match 3 tiles to fight", 0, _gw * 0.9, _ss * 1.1, _ss * 1.1, 0);
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.43, "through the dungeon!", 0, _gw * 0.9, _ss * 1.1, _ss * 1.1, 0);

    // Tile legend
    var _legend_y = _gh * 0.52;
    var _legend_spacing = _ss * 22;
    var _type_names = ["SWORD = Damage", "SHIELD = Block", "HEART = Heal", "COIN = Points"];
    for (var _i = 0; _i < 4; _i++) {
        draw_set_colour(tile_colors[_i]);
        draw_circle(_gw * 0.3, _legend_y + _i * _legend_spacing, _ss * 5, false);
        draw_set_halign(fa_left);
        draw_set_colour(c_white);
        draw_text_ext_transformed(_gw * 0.35, _legend_y + _i * _legend_spacing, _type_names[_i], 0, _gw, _ss * 0.9, _ss * 0.9, 0);
        draw_set_halign(fa_center);
    }

    // Tap to start
    var _blink = (current_time div 500) mod 2;
    if (_blink == 0) {
        draw_set_colour(c_white);
        draw_text_ext_transformed(_gw * 0.5, _gh * 0.82, "TAP TO START", 0, _gw, _ss * 1.5, _ss * 1.5, 0);
    }
}

// === GAME OVER OVERLAY (state 2) ===
if (game_state == 2) {
    // Dim overlay
    draw_set_alpha(0.8);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1.0);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_set_colour(col_hp_red);
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.32, "GAME OVER", 0, _gw, _ss * 2.5, _ss * 2.5, 0);

    draw_set_colour(make_colour_rgb(200, 180, 255));
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.43, $"Reached Floor {floor_num}", 0, _gw, _ss * 1.3, _ss * 1.3, 0);

    draw_set_colour(tile_colors[3]);
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.52, $"Score: {points}", 0, _gw, _ss * 1.5, _ss * 1.5, 0);

    var _blink = (current_time div 500) mod 2;
    if (_blink == 0) {
        draw_set_colour(c_white);
        draw_text_ext_transformed(_gw * 0.5, _gh * 0.72, "TAP TO RETRY", 0, _gw, _ss * 1.3, _ss * 1.3, 0);
    }
}
