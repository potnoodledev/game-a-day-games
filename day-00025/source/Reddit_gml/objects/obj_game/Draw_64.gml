var _ww = max(1, window_get_width());
var _wh = max(1, window_get_height());
var _tile_w = min(_ww, _wh) * 0.12;
var _tile_h = _tile_w * 0.6;
var _height_px = _tile_h * 0.7;

var _cx = play_ox + play_w * 0.5;
var _cy = play_oy + 80;

// Camera shake offset
var _shk_x = 0;
var _shk_y = 0;
if (camera_shake > 0) {
    _shk_x = irandom_range(-round(camera_shake), round(camera_shake));
    _shk_y = irandom_range(-round(camera_shake), round(camera_shake));
}

// --- Background ---
draw_set_colour(make_colour_rgb(16, 16, 48));
draw_rectangle(0, 0, _ww, _wh, false);

// --- Title screen ---
if (game_state == 1) {
    // Draw grid preview (dimmed)
    draw_set_alpha(0.4);
    for (var _gx = 0; _gx < grid_w; _gx++) {
        for (var _gy = 0; _gy < grid_h; _gy++) {
            var _sx = _cx + (_gx - _gy) * _tile_w * 0.5;
            var _sy = _cy + (_gx + _gy) * _tile_h * 0.5 - tile_height[_gx * grid_w + _gy] * _height_px;

            var _c = ((_gx + _gy) % 2 == 0) ? col_tile_light : col_tile_dark;
            draw_set_colour(_c);
            draw_triangle(_sx, _sy - _tile_h * 0.5, _sx + _tile_w * 0.5, _sy, _sx, _sy + _tile_h * 0.5, false);
            draw_triangle(_sx, _sy - _tile_h * 0.5, _sx - _tile_w * 0.5, _sy, _sx, _sy + _tile_h * 0.5, false);
        }
    }
    draw_set_alpha(1);

    // Title
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(col_ui_highlight);
    draw_text(_ww * 0.5, _wh * 0.3, "FINAL FANTASY");
    draw_text(_ww * 0.5, _wh * 0.3 + 24, "TACTICS");

    var _pulse = 0.5 + sin(title_pulse) * 0.5;
    draw_set_alpha(_pulse);
    draw_set_colour(col_ui_text);
    draw_text(_ww * 0.5, _wh * 0.65, "TAP TO BEGIN");
    draw_set_alpha(1);

    draw_set_colour(make_colour_rgb(120, 120, 180));
    draw_text(_ww * 0.5, _wh * 0.8, "Wave " + string(wave_num));

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    exit;
}

// --- Game Over ---
if (game_state == 5) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(make_colour_rgb(200, 40, 40));
    draw_text(_ww * 0.5, _wh * 0.35, "DEFEAT");
    draw_set_colour(col_ui_text);
    draw_text(_ww * 0.5, _wh * 0.45, "Score: " + string(points));
    draw_text(_ww * 0.5, _wh * 0.52, "Waves: " + string(wave_num - 1));

    draw_set_colour(col_ui_highlight);
    draw_text(_ww * 0.5, _wh * 0.65, "TAP TO RETRY");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    exit;
}

// --- Draw isometric grid ---
// Draw back to front for proper overlapping
for (var _row = 0; _row < grid_w + grid_h - 1; _row++) {
    for (var _gx = 0; _gx < grid_w; _gx++) {
        var _gy = _row - _gx;
        if (_gy < 0 || _gy >= grid_h) continue;

        var _h = tile_height[_gx * grid_w + _gy];
        var _sx = _cx + (_gx - _gy) * _tile_w * 0.5 + _shk_x;
        var _sy = _cy + (_gx + _gy) * _tile_h * 0.5 - _h * _height_px + _shk_y;

        // Check if highlighted (move or attack)
        var _is_move = false;
        var _is_attack = false;
        var _key = _gx * grid_w + _gy;

        if (game_state == 2 && turn_phase == 1) {
            for (var _m = 0; _m < valid_move_count; _m++) {
                if (valid_moves[_m] == _key) { _is_move = true; break; }
            }
        }
        if (game_state == 2 && turn_phase == 2) {
            for (var _m = 0; _m < valid_attack_count; _m++) {
                var _tgt = valid_attacks[_m];
                if (unit_gx[_tgt] == _gx && unit_gy[_tgt] == _gy) { _is_attack = true; break; }
            }
        }

        // Tile top face
        var _c = ((_gx + _gy) % 2 == 0) ? col_tile_light : col_tile_dark;
        if (_is_move) _c = merge_colour(_c, col_tile_move, 0.5);
        if (_is_attack) _c = merge_colour(_c, col_tile_attack, 0.5);

        // Active unit's tile
        if (active_unit >= 0 && unit_gx[active_unit] == _gx && unit_gy[active_unit] == _gy && game_state == 2) {
            _c = merge_colour(_c, col_ui_highlight, 0.3);
        }

        draw_set_colour(_c);
        // Diamond: top, right, bottom, left
        var _tx = _sx;
        var _ty = _sy - _tile_h * 0.5;
        var _rx = _sx + _tile_w * 0.5;
        var _ry = _sy;
        var _bx = _sx;
        var _by = _sy + _tile_h * 0.5;
        var _lx = _sx - _tile_w * 0.5;
        var _ly = _sy;

        draw_triangle(_tx, _ty, _rx, _ry, _bx, _by, false);
        draw_triangle(_tx, _ty, _lx, _ly, _bx, _by, false);

        // Side faces for height
        if (_h > 0) {
            var _side_h = _h * _height_px;
            // Right side
            draw_set_colour(col_tile_side);
            draw_triangle(_rx, _ry, _bx, _by, _bx, _by + _side_h, false);
            draw_triangle(_rx, _ry, _rx, _ry + _side_h, _bx, _by + _side_h, false);
            // Left side
            draw_set_colour(col_tile_side2);
            draw_triangle(_lx, _ly, _bx, _by, _bx, _by + _side_h, false);
            draw_triangle(_lx, _ly, _lx, _ly + _side_h, _bx, _by + _side_h, false);
        }

        // Tile outline
        draw_set_colour(make_colour_rgb(60, 60, 40));
        draw_set_alpha(0.3);
        draw_line(_tx, _ty, _rx, _ry);
        draw_line(_rx, _ry, _bx, _by);
        draw_line(_bx, _by, _lx, _ly);
        draw_line(_lx, _ly, _tx, _ty);
        draw_set_alpha(1);

        // --- Draw crystals on this tile ---
        for (var _ci = 0; _ci < crystal_count; _ci++) {
            if (crystal_gx[_ci] == _gx && crystal_gy[_ci] == _gy && crystal_timer[_ci] > 0) {
                var _cpulse = 0.6 + sin(crystal_timer[_ci] * 0.1) * 0.4;
                draw_set_alpha(_cpulse);
                draw_set_colour(make_colour_rgb(100, 200, 255));
                var _cs = _tile_w * 0.15;
                draw_triangle(_sx, _sy - _cs, _sx + _cs * 0.6, _sy, _sx, _sy + _cs * 0.3, false);
                draw_triangle(_sx, _sy - _cs, _sx - _cs * 0.6, _sy, _sx, _sy + _cs * 0.3, false);
                draw_set_alpha(1);
            }
        }

        // --- Draw units on this tile ---
        for (var _u = 0; _u < unit_count; _u++) {
            if (!unit_alive[_u]) continue;
            if (unit_gx[_u] != _gx || unit_gy[_u] != _gy) continue;

            var _ux = _sx;
            var _uy = _sy - _tile_h * 0.3;

            // Unit color by class
            var _ucol = col_knight;
            if (unit_class[_u] == 1) _ucol = col_mage;
            if (unit_class[_u] == 2) _ucol = col_archer;
            if (unit_class[_u] == 3) _ucol = col_goblin;
            if (unit_class[_u] == 4) _ucol = col_enemy_archer;

            // Body - small rectangle
            var _bw = _tile_w * 0.2;
            var _bh = _tile_h * 0.7;
            draw_set_colour(_ucol);
            draw_rectangle(_ux - _bw * 0.5, _uy - _bh, _ux + _bw * 0.5, _uy, false);

            // Head - circle
            var _head_r = _bw * 0.45;
            var _skin = (unit_team[_u] == 0) ? make_colour_rgb(240, 200, 170) : make_colour_rgb(120, 180, 80);
            draw_set_colour(_skin);
            draw_circle(_ux, _uy - _bh - _head_r * 0.5, _head_r, false);

            // Class indicator on body
            draw_set_colour(c_white);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            var _label = "";
            if (unit_class[_u] == 0) _label = "K";
            if (unit_class[_u] == 1) _label = "M";
            if (unit_class[_u] == 2) _label = "A";
            if (unit_class[_u] == 3) _label = "g";
            if (unit_class[_u] == 4) _label = "a";
            draw_text(_ux, _uy - _bh * 0.5, _label);

            // HP bar
            var _hp_w = _tile_w * 0.35;
            var _hp_h = 3;
            var _hp_y = _uy - _bh - _head_r - 6;
            var _hp_pct = max(0, unit_hp[_u] / unit_max_hp[_u]);
            draw_set_colour(c_black);
            draw_rectangle(_ux - _hp_w * 0.5 - 1, _hp_y - 1, _ux + _hp_w * 0.5 + 1, _hp_y + _hp_h + 1, false);

            var _hp_col = make_colour_rgb(60, 200, 60);
            if (_hp_pct < 0.5) _hp_col = make_colour_rgb(200, 200, 60);
            if (_hp_pct < 0.25) _hp_col = make_colour_rgb(200, 60, 60);
            draw_set_colour(_hp_col);
            draw_rectangle(_ux - _hp_w * 0.5, _hp_y, _ux - _hp_w * 0.5 + _hp_w * _hp_pct, _hp_y + _hp_h, false);

            // Active unit indicator (pulsing ring)
            if (active_unit == _u && game_state == 2) {
                var _apulse = 0.4 + sin(current_time * 0.005) * 0.3;
                draw_set_alpha(_apulse);
                draw_set_colour(col_ui_highlight);
                draw_circle(_ux, _uy - _bh * 0.5, _bw * 1.2, true);
                draw_set_alpha(1);
            }

            // Facing arrow
            draw_set_colour(c_white);
            draw_set_alpha(0.6);
            var _arr_len = _tile_w * 0.12;
            var _arr_x = _ux;
            var _arr_y = _uy + 2;
            if (unit_facing[_u] == 0) draw_triangle(_arr_x, _arr_y, _arr_x - _arr_len, _arr_y + _arr_len * 0.5, _arr_x - _arr_len, _arr_y - _arr_len * 0.5, false);
            if (unit_facing[_u] == 1) draw_triangle(_arr_x, _arr_y + _arr_len, _arr_x - _arr_len * 0.5, _arr_y, _arr_x + _arr_len * 0.5, _arr_y, false);
            if (unit_facing[_u] == 2) draw_triangle(_arr_x, _arr_y, _arr_x + _arr_len, _arr_y + _arr_len * 0.5, _arr_x + _arr_len, _arr_y - _arr_len * 0.5, false);
            if (unit_facing[_u] == 3) draw_triangle(_arr_x, _arr_y - _arr_len, _arr_x - _arr_len * 0.5, _arr_y, _arr_x + _arr_len * 0.5, _arr_y, false);
            draw_set_alpha(1);
        }
    }
}

// --- Damage popups ---
for (var _i = 0; _i < popup_count; _i++) {
    var _pa = min(1, popup_timer[_i] / 20);
    draw_set_alpha(_pa);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    if (popup_is_heal[_i]) {
        draw_set_colour(make_colour_rgb(60, 255, 60));
        draw_text(popup_x[_i] + _shk_x, popup_y[_i] + _shk_y, "+" + string(popup_val[_i]));
    } else {
        draw_set_colour(col_ui_highlight);
        draw_text(popup_x[_i] + _shk_x, popup_y[_i] + _shk_y, string(popup_val[_i]));
    }
    draw_set_alpha(1);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);

// --- CT Turn Order Bar (top) ---
var _bar_x = 10;
var _bar_y = 6;
var _bar_h = 28;

draw_set_colour(col_ui_bg);
draw_set_alpha(0.8);
draw_rectangle(_bar_x, _bar_y, _ww - 10, _bar_y + _bar_h, false);
draw_set_alpha(1);
draw_set_colour(col_ui_border);
draw_rectangle(_bar_x, _bar_y, _ww - 10, _bar_y + _bar_h, true);

// Show each alive unit's CT as a pip
var _ct_order_count = 0;
for (var _i = 0; _i < unit_count; _i++) {
    if (unit_alive[_i]) _ct_order_count++;
}

var _pip_w = min(40, (_ww - 30) / max(1, _ct_order_count));
var _pip_idx = 0;
for (var _i = 0; _i < unit_count; _i++) {
    if (!unit_alive[_i]) continue;

    var _px = _bar_x + 4 + _pip_idx * _pip_w;
    var _py = _bar_y + 2;

    var _ucol = col_knight;
    if (unit_class[_i] == 1) _ucol = col_mage;
    if (unit_class[_i] == 2) _ucol = col_archer;
    if (unit_class[_i] == 3) _ucol = col_goblin;
    if (unit_class[_i] == 4) _ucol = col_enemy_archer;

    // CT fill bar
    draw_set_colour(make_colour_rgb(30, 30, 60));
    draw_rectangle(_px, _py, _px + _pip_w - 4, _py + _bar_h - 4, false);

    var _ct_pct = min(1, unit_ct[_i] / 100);
    draw_set_colour(_ucol);
    draw_rectangle(_px, _py + (_bar_h - 4) * (1 - _ct_pct), _px + _pip_w - 4, _py + _bar_h - 4, false);

    // Active highlight
    if (_i == active_unit) {
        draw_set_colour(col_ui_highlight);
        draw_rectangle(_px - 1, _py - 1, _px + _pip_w - 3, _py + _bar_h - 3, true);
    }

    // Label
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _label = "";
    if (unit_class[_i] == 0) _label = "K";
    if (unit_class[_i] == 1) _label = "M";
    if (unit_class[_i] == 2) _label = "A";
    if (unit_class[_i] == 3) _label = "g";
    if (unit_class[_i] == 4) _label = "a";
    draw_text(_px + (_pip_w - 4) * 0.5, _py + (_bar_h - 4) * 0.5, _label);

    _pip_idx++;
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);

// --- Action Menu (player turn, select_action) ---
if (game_state == 2 && active_unit >= 0 && unit_team[active_unit] == 0 && turn_phase == 0) {
    var _menu_x = _ww - 140;
    var _menu_y = _wh - 200;
    var _menu_w = 130;
    var _menu_item_h = 36;

    draw_set_colour(col_ui_bg);
    draw_set_alpha(0.9);
    draw_rectangle(_menu_x, _menu_y, _menu_x + _menu_w, _menu_y + 30 + 3 * _menu_item_h, false);
    draw_set_alpha(1);
    draw_set_colour(col_ui_border);
    draw_rectangle(_menu_x, _menu_y, _menu_x + _menu_w, _menu_y + 30 + 3 * _menu_item_h, true);

    // Title
    draw_set_colour(col_ui_highlight);
    draw_set_halign(fa_center);
    draw_text(_menu_x + _menu_w * 0.5, _menu_y + 6, "ACTION");

    // Options
    var _options_0 = "Move";
    var _options_1 = "Attack";
    var _options_2 = "Wait";
    for (var _m = 0; _m < 3; _m++) {
        var _oy = _menu_y + 30 + _m * _menu_item_h;
        var _enabled = true;
        if (_m == 0 && unit_moved[active_unit]) _enabled = false;
        if (_m == 1 && unit_acted[active_unit]) _enabled = false;

        if (_enabled) {
            draw_set_colour(col_ui_text);
        } else {
            draw_set_colour(make_colour_rgb(80, 80, 100));
        }
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        var _txt = _options_0;
        if (_m == 1) _txt = _options_1;
        if (_m == 2) _txt = _options_2;
        draw_text(_menu_x + _menu_w * 0.5, _oy + _menu_item_h * 0.5, _txt);
    }
}

// --- Unit Info Panel (bottom) ---
var _show_info = -1;
if (info_unit >= 0 && info_unit < unit_count && unit_alive[info_unit]) _show_info = info_unit;
else if (active_unit >= 0 && active_unit < unit_count && unit_alive[active_unit]) _show_info = active_unit;

if (_show_info >= 0) {
    var _panel_w = min(200, _ww * 0.45);
    var _panel_h = 70;
    var _panel_x = 10;
    var _panel_y = _wh - _panel_h - 10;

    draw_set_colour(col_ui_bg);
    draw_set_alpha(0.9);
    draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _panel_h, false);
    draw_set_alpha(1);
    draw_set_colour(col_ui_border);
    draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _panel_h, true);

    var _u = _show_info;
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    // Class name
    var _ucol = col_knight;
    if (unit_class[_u] == 1) _ucol = col_mage;
    if (unit_class[_u] == 2) _ucol = col_archer;
    if (unit_class[_u] == 3) _ucol = col_goblin;
    if (unit_class[_u] == 4) _ucol = col_enemy_archer;

    draw_set_colour(_ucol);
    draw_text(_panel_x + 8, _panel_y + 6, class_name[unit_class[_u]]);

    // Team indicator
    draw_set_colour(col_ui_text);
    var _team_str = " (ally)";
    if (unit_team[_u] == 1) _team_str = " (foe)";
    draw_text(_panel_x + 60, _panel_y + 6, _team_str);

    // Stats
    draw_set_colour(col_ui_text);
    draw_text(_panel_x + 8, _panel_y + 24, "HP:" + string(max(0, unit_hp[_u])) + "/" + string(unit_max_hp[_u]));
    draw_text(_panel_x + 100, _panel_y + 24, "ATK:" + string(unit_atk[_u]));
    draw_text(_panel_x + 8, _panel_y + 42, "DEF:" + string(unit_def[_u]));
    draw_text(_panel_x + 100, _panel_y + 42, "SPD:" + string(unit_spd[_u]));
}

// --- Wave Banner ---
if (game_state == 4) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(col_ui_highlight);
    draw_text(_ww * 0.5, _wh * 0.4, "WAVE " + string(wave_num) + " CLEAR!");
    draw_set_colour(col_ui_text);
    draw_text(_ww * 0.5, _wh * 0.5, "+" + string(wave_num * 100) + " points");
}

// --- HUD: Score & Wave ---
draw_set_halign(fa_right);
draw_set_valign(fa_top);
draw_set_colour(col_ui_text);
draw_text(_ww - 14, 40, "Score: " + string(points));
draw_text(_ww - 14, 56, "Wave: " + string(wave_num));

// --- Move/Attack phase labels ---
if (game_state == 2 && turn_phase == 1) {
    draw_set_halign(fa_center);
    draw_set_colour(col_tile_move);
    draw_text(_ww * 0.5, _wh - 24, "Tap blue tile to move");
}
if (game_state == 2 && turn_phase == 2) {
    draw_set_halign(fa_center);
    draw_set_colour(col_tile_attack);
    draw_text(_ww * 0.5, _wh - 24, "Tap red target to attack");
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
