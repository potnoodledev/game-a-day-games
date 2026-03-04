var _ww = max(1, window_get_width());
var _wh = max(1, window_get_height());
var _tile_w = min(_ww, _wh) * 0.16;
var _tile_h = _tile_w * 0.6;
var _height_px = _tile_h * 0.8;

var _cx = play_ox + play_w * 0.5;
var _cy = play_oy + 120;

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

// --- Draw isometric grid (back to front) ---
for (var _row = 0; _row < grid_w + grid_h - 1; _row++) {
    for (var _gx = 0; _gx < grid_w; _gx++) {
        var _gy = _row - _gx;
        if (_gy < 0 || _gy >= grid_h) continue;

        var _h = tile_height[_gx * grid_w + _gy];
        var _sx = _cx + (_gx - _gy) * _tile_w * 0.5 + _shk_x;
        var _sy = _cy + (_gx + _gy) * _tile_h * 0.5 - _h * _height_px + _shk_y;

        // Highlight check
        var _is_move = false;
        var _is_attack = false;
        var _key = _gx * grid_w + _gy;

        if (game_state == 2 && active_unit >= 0 && unit_team[active_unit] == 0) {
            for (var _m = 0; _m < valid_move_count; _m++) {
                if (valid_moves[_m] == _key) { _is_move = true; break; }
            }
            for (var _m = 0; _m < valid_attack_count; _m++) {
                var _tgt = valid_attacks[_m];
                if (unit_gx[_tgt] == _gx && unit_gy[_tgt] == _gy) { _is_attack = true; break; }
            }
        }

        // Tile top color
        var _c = ((_gx + _gy) % 2 == 0) ? col_tile_light : col_tile_dark;
        // Elevated tiles get a stone tint
        if (_h >= 2) _c = merge_colour(_c, make_colour_rgb(160, 150, 130), 0.4);
        else if (_h == 1) _c = merge_colour(_c, make_colour_rgb(140, 140, 110), 0.2);

        if (_is_move) {
            var _mp = 0.4 + sin(current_time * 0.004) * 0.15;
            _c = merge_colour(_c, col_tile_move, _mp);
        }
        if (_is_attack) {
            var _ap = 0.4 + sin(current_time * 0.005) * 0.15;
            _c = merge_colour(_c, col_tile_attack, _ap);
        }

        if (active_unit >= 0 && unit_gx[active_unit] == _gx && unit_gy[active_unit] == _gy && game_state == 2) {
            _c = merge_colour(_c, col_ui_highlight, 0.35);
        }

        // Selected tile cursor
        if (selected_tile_gx == _gx && selected_tile_gy == _gy && game_state == 2) {
            _c = merge_colour(_c, c_white, 0.4 + sin(current_time * 0.008) * 0.15);
        }

        draw_set_colour(_c);
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

        // Side faces (thicker, gradient)
        if (_h > 0) {
            var _side_h = _h * _height_px;
            // Right side
            draw_set_colour(col_tile_side);
            draw_triangle(_rx, _ry, _bx, _by, _bx, _by + _side_h, false);
            draw_triangle(_rx, _ry, _rx, _ry + _side_h, _bx, _by + _side_h, false);
            // Right side darker bottom strip
            draw_set_colour(merge_colour(col_tile_side, c_black, 0.3));
            var _strip = _side_h * 0.3;
            draw_triangle(_rx, _ry + _side_h - _strip, _bx, _by + _side_h - _strip, _bx, _by + _side_h, false);
            draw_triangle(_rx, _ry + _side_h - _strip, _rx, _ry + _side_h, _bx, _by + _side_h, false);
            // Left side
            draw_set_colour(col_tile_side2);
            draw_triangle(_lx, _ly, _bx, _by, _bx, _by + _side_h, false);
            draw_triangle(_lx, _ly, _lx, _ly + _side_h, _bx, _by + _side_h, false);
            // Left side darker bottom strip
            draw_set_colour(merge_colour(col_tile_side2, c_black, 0.3));
            draw_triangle(_lx, _ly + _side_h - _strip, _bx, _by + _side_h - _strip, _bx, _by + _side_h, false);
            draw_triangle(_lx, _ly + _side_h - _strip, _lx, _ly + _side_h, _bx, _by + _side_h, false);
        }

        // Tile outline
        draw_set_colour(make_colour_rgb(60, 60, 40));
        draw_set_alpha(0.4);
        draw_line(_tx, _ty, _rx, _ry);
        draw_line(_rx, _ry, _bx, _by);
        draw_line(_bx, _by, _lx, _ly);
        draw_line(_lx, _ly, _tx, _ty);
        draw_set_alpha(1);

        // Selected tile bright outline
        if (selected_tile_gx == _gx && selected_tile_gy == _gy && game_state == 2) {
            draw_set_colour(c_white);
            draw_set_alpha(0.7 + sin(current_time * 0.006) * 0.3);
            draw_line_width(_tx, _ty, _rx, _ry, 2);
            draw_line_width(_rx, _ry, _bx, _by, 2);
            draw_line_width(_bx, _by, _lx, _ly, 2);
            draw_line_width(_lx, _ly, _tx, _ty, 2);
            draw_set_alpha(1);
            // "Tap again" prompt
            draw_set_halign(fa_center);
            draw_set_valign(fa_bottom);
            draw_set_colour(c_white);
            draw_text(_sx, _ty - 4, "Confirm");
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
        }

        // --- Crystals ---
        for (var _ci = 0; _ci < crystal_count; _ci++) {
            if (crystal_gx[_ci] == _gx && crystal_gy[_ci] == _gy && crystal_timer[_ci] > 0) {
                var _cpulse = 0.6 + sin(crystal_timer[_ci] * 0.1) * 0.4;
                draw_set_alpha(_cpulse);
                draw_set_colour(make_colour_rgb(100, 200, 255));
                var _cs = _tile_w * 0.18;
                draw_triangle(_sx, _sy - _cs, _sx + _cs * 0.6, _sy, _sx, _sy + _cs * 0.3, false);
                draw_triangle(_sx, _sy - _cs, _sx - _cs * 0.6, _sy, _sx, _sy + _cs * 0.3, false);
                // Glow
                draw_set_alpha(_cpulse * 0.3);
                draw_circle(_sx, _sy - _cs * 0.3, _cs * 0.8, false);
                draw_set_alpha(1);
            }
        }

        // --- Draw units on this tile ---
        for (var _u = 0; _u < unit_count; _u++) {
            if (!unit_alive[_u]) continue;
            if (unit_gx[_u] != _gx || unit_gy[_u] != _gy) continue;

            var _ux = _sx;
            var _uy = _sy;

            // Lerp position during move animation
            if (game_state == 3 && anim_type == 1 && _u == anim_unit && anim_timer_max > 0) {
                var _prog = 1.0 - (anim_timer / anim_timer_max);
                _prog = clamp(_prog, 0, 1);
                // Ease out
                _prog = 1 - power(1 - _prog, 2);
                var _sgx = anim_start_gx;
                var _sgy = anim_start_gy;
                var _egx = anim_end_gx;
                var _egy = anim_end_gy;
                var _lerp_gx = _sgx + (_egx - _sgx) * _prog;
                var _lerp_gy = _sgy + (_egy - _sgy) * _prog;
                var _sh_start = tile_height[_sgx * grid_w + _sgy];
                var _sh_end = tile_height[_egx * grid_w + _egy];
                var _lerp_h = _sh_start + (_sh_end - _sh_start) * _prog;
                _ux = _cx + (_lerp_gx - _lerp_gy) * _tile_w * 0.5 + _shk_x;
                _uy = _cy + (_lerp_gx + _lerp_gy) * _tile_h * 0.5 - _lerp_h * _height_px + _shk_y;
            }

            // Active unit bounce
            if (active_unit == _u && game_state == 2) {
                _uy -= abs(sin(current_time * 0.004)) * _tile_h * 0.15;
            }

            // Unit color by class
            var _ucol = col_knight;
            if (unit_class[_u] == 1) _ucol = col_mage;
            if (unit_class[_u] == 2) _ucol = col_archer;
            if (unit_class[_u] == 3) _ucol = col_goblin;
            if (unit_class[_u] == 4) _ucol = col_enemy_archer;

            // --- Chunky unit body ---
            var _bw = _tile_w * 0.32;
            var _bh = _tile_h * 1.1;
            var _body_top = _uy - _bh;
            var _body_bot = _uy - _tile_h * 0.15;

            // Shadow
            draw_set_colour(c_black);
            draw_set_alpha(0.25);
            draw_ellipse(_ux - _bw * 0.6, _body_bot - 2, _ux + _bw * 0.6, _body_bot + 4, false);
            draw_set_alpha(1);

            // Torso (tapered rectangle)
            draw_set_colour(_ucol);
            draw_triangle(_ux - _bw * 0.5, _body_bot, _ux + _bw * 0.5, _body_bot, _ux + _bw * 0.35, _body_top + _bh * 0.4, false);
            draw_triangle(_ux - _bw * 0.5, _body_bot, _ux - _bw * 0.35, _body_top + _bh * 0.4, _ux + _bw * 0.35, _body_top + _bh * 0.4, false);

            // Shoulders
            draw_set_colour(merge_colour(_ucol, c_white, 0.15));
            var _sh_y = _body_top + _bh * 0.35;
            draw_rectangle(_ux - _bw * 0.55, _sh_y, _ux + _bw * 0.55, _sh_y + _bh * 0.12, false);

            // Head
            var _head_r = _bw * 0.38;
            var _head_y = _body_top + _bh * 0.18;
            var _skin = (unit_team[_u] == 0) ? make_colour_rgb(240, 200, 170) : make_colour_rgb(140, 190, 90);
            draw_set_colour(_skin);
            draw_circle(_ux, _head_y, _head_r, false);

            // Helmet/hat for allies, horns for enemies
            if (unit_team[_u] == 0) {
                draw_set_colour(merge_colour(_ucol, c_black, 0.2));
                draw_circle(_ux, _head_y - _head_r * 0.2, _head_r * 1.05, false);
                draw_set_colour(_skin);
                draw_rectangle(_ux - _head_r * 0.7, _head_y - _head_r * 0.1, _ux + _head_r * 0.7, _head_y + _head_r * 0.5, false);
            } else {
                draw_set_colour(make_colour_rgb(100, 60, 30));
                draw_triangle(_ux - _head_r * 0.6, _head_y - _head_r * 0.3, _ux - _head_r * 0.9, _head_y - _head_r * 1.0, _ux - _head_r * 0.3, _head_y - _head_r * 0.5, false);
                draw_triangle(_ux + _head_r * 0.6, _head_y - _head_r * 0.3, _ux + _head_r * 0.9, _head_y - _head_r * 1.0, _ux + _head_r * 0.3, _head_y - _head_r * 0.5, false);
            }

            // Eyes
            draw_set_colour(c_white);
            draw_circle(_ux - _head_r * 0.3, _head_y + _head_r * 0.1, _head_r * 0.18, false);
            draw_circle(_ux + _head_r * 0.3, _head_y + _head_r * 0.1, _head_r * 0.18, false);
            draw_set_colour(c_black);
            draw_circle(_ux - _head_r * 0.25, _head_y + _head_r * 0.15, _head_r * 0.08, false);
            draw_circle(_ux + _head_r * 0.25, _head_y + _head_r * 0.15, _head_r * 0.08, false);

            // --- Weapon by class ---
            var _wpn_x = _ux + _bw * 0.55;
            var _wpn_y = _sh_y;
            if (unit_class[_u] == 0) {
                // Knight: sword
                draw_set_colour(make_colour_rgb(180, 180, 200));
                draw_rectangle(_wpn_x, _wpn_y - _bh * 0.35, _wpn_x + _bw * 0.12, _wpn_y + _bh * 0.15, false);
                draw_set_colour(make_colour_rgb(120, 90, 50));
                draw_rectangle(_wpn_x - _bw * 0.08, _wpn_y + _bh * 0.12, _wpn_x + _bw * 0.2, _wpn_y + _bh * 0.18, false);
                // Shield on left
                draw_set_colour(merge_colour(_ucol, c_white, 0.3));
                draw_circle(_ux - _bw * 0.6, _sh_y + _bh * 0.1, _bw * 0.25, false);
            } else if (unit_class[_u] == 1) {
                // Mage: staff
                draw_set_colour(make_colour_rgb(120, 80, 40));
                draw_rectangle(_wpn_x, _wpn_y - _bh * 0.45, _wpn_x + _bw * 0.08, _wpn_y + _bh * 0.2, false);
                // Orb on top
                draw_set_colour(make_colour_rgb(200, 100, 255));
                draw_circle(_wpn_x + _bw * 0.04, _wpn_y - _bh * 0.48, _bw * 0.14, false);
            } else if (unit_class[_u] == 2) {
                // Archer: bow
                draw_set_colour(make_colour_rgb(140, 100, 50));
                draw_set_alpha(1);
                var _bow_cx = _wpn_x + _bw * 0.1;
                var _bow_top = _wpn_y - _bh * 0.3;
                var _bow_bot = _wpn_y + _bh * 0.15;
                draw_line_width(_bow_cx, _bow_top, _bow_cx + _bw * 0.15, (_bow_top + _bow_bot) * 0.5, 2);
                draw_line_width(_bow_cx, _bow_bot, _bow_cx + _bw * 0.15, (_bow_top + _bow_bot) * 0.5, 2);
                // String
                draw_set_colour(c_white);
                draw_line(_bow_cx, _bow_top, _bow_cx, _bow_bot);
            } else if (unit_class[_u] == 3) {
                // Goblin: club
                draw_set_colour(make_colour_rgb(100, 80, 50));
                draw_rectangle(_wpn_x, _wpn_y - _bh * 0.15, _wpn_x + _bw * 0.1, _wpn_y + _bh * 0.15, false);
                draw_set_colour(make_colour_rgb(80, 60, 40));
                draw_circle(_wpn_x + _bw * 0.05, _wpn_y - _bh * 0.18, _bw * 0.12, false);
            } else if (unit_class[_u] == 4) {
                // Enemy archer: crossbow
                draw_set_colour(make_colour_rgb(100, 60, 30));
                draw_rectangle(_wpn_x, _wpn_y - _bh * 0.05, _wpn_x + _bw * 0.25, _wpn_y + _bh * 0.03, false);
                draw_line_width(_wpn_x, _wpn_y - _bh * 0.15, _wpn_x, _wpn_y + _bh * 0.1, 2);
            }

            // --- HP bar ---
            var _hp_w = _tile_w * 0.4;
            var _hp_h = 4;
            var _hp_y = _head_y - _head_r - 8;
            var _hp_pct = max(0, unit_hp[_u] / unit_max_hp[_u]);
            draw_set_colour(c_black);
            draw_rectangle(_ux - _hp_w * 0.5 - 1, _hp_y - 1, _ux + _hp_w * 0.5 + 1, _hp_y + _hp_h + 1, false);

            var _hp_col = make_colour_rgb(60, 200, 60);
            if (_hp_pct < 0.5) _hp_col = make_colour_rgb(200, 200, 60);
            if (_hp_pct < 0.25) _hp_col = make_colour_rgb(200, 60, 60);
            draw_set_colour(_hp_col);
            if (_hp_pct > 0) {
                draw_rectangle(_ux - _hp_w * 0.5, _hp_y, _ux - _hp_w * 0.5 + _hp_w * _hp_pct, _hp_y + _hp_h, false);
            }

            // Active unit glow ring
            if (active_unit == _u && game_state == 2) {
                var _apulse = 0.3 + sin(current_time * 0.005) * 0.2;
                draw_set_alpha(_apulse);
                draw_set_colour(col_ui_highlight);
                draw_ellipse(_ux - _bw * 0.7, _body_bot - 3, _ux + _bw * 0.7, _body_bot + 5, true);
                draw_ellipse(_ux - _bw * 0.8, _body_bot - 4, _ux + _bw * 0.8, _body_bot + 6, true);
                draw_set_alpha(1);
            }

            // Class label under unit
            draw_set_colour(c_white);
            draw_set_halign(fa_center);
            draw_set_valign(fa_top);
            draw_set_alpha(0.7);
            draw_text(_ux, _body_bot + 2, class_name[unit_class[_u]]);
            draw_set_alpha(1);
        }
    }
}

// --- Attack slash effect ---
if (game_state == 3 && anim_type == 2 && anim_attack_target >= 0 && anim_timer_max > 0) {
    var _tgt = anim_attack_target;
    if (_tgt >= 0 && _tgt < unit_count) {
        var _tgx = unit_gx[_tgt];
        var _tgy = unit_gy[_tgt];
        var _th = tile_height[_tgx * grid_w + _tgy];
        var _atk_sx = _cx + (_tgx - _tgy) * _tile_w * 0.5 + _shk_x;
        var _atk_sy = _cy + (_tgx + _tgy) * _tile_h * 0.5 - _th * _height_px + _shk_y;

        var _aprog = 1.0 - (anim_timer / anim_timer_max);
        _aprog = clamp(_aprog, 0, 1);

        // Flash white on target
        if (_aprog < 0.3) {
            draw_set_alpha(0.6 * (1 - _aprog / 0.3));
            draw_set_colour(c_white);
            draw_circle(_atk_sx, _atk_sy - _tile_h * 0.5, _tile_w * 0.4, false);
            draw_set_alpha(1);
        }

        // Slash lines radiating outward
        if (_aprog > 0.1 && _aprog < 0.7) {
            var _slash_a = (_aprog - 0.1) / 0.6;
            draw_set_alpha(1 - _slash_a);
            draw_set_colour(col_ui_highlight);
            var _sl = _tile_w * 0.5 * _slash_a;
            draw_line_width(_atk_sx - _sl, _atk_sy - _tile_h * 0.5 - _sl, _atk_sx + _sl * 0.3, _atk_sy - _tile_h * 0.5 + _sl * 0.3, 3);
            draw_line_width(_atk_sx + _sl, _atk_sy - _tile_h * 0.5 - _sl * 0.5, _atk_sx - _sl * 0.3, _atk_sy - _tile_h * 0.5 + _sl * 0.8, 3);
            draw_line_width(_atk_sx - _sl * 0.5, _atk_sy - _tile_h * 0.5 + _sl * 0.2, _atk_sx + _sl * 0.5, _atk_sy - _tile_h * 0.5 - _sl * 0.2, 2);
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
var _bar_h = 32;

draw_set_colour(col_ui_bg);
draw_set_alpha(0.85);
draw_rectangle(_bar_x, _bar_y, _ww - 10, _bar_y + _bar_h, false);
draw_set_alpha(1);
draw_set_colour(col_ui_border);
draw_rectangle(_bar_x, _bar_y, _ww - 10, _bar_y + _bar_h, true);

var _ct_order_count = 0;
for (var _i = 0; _i < unit_count; _i++) {
    if (unit_alive[_i]) _ct_order_count++;
}

var _pip_w = min(44, (_ww - 30) / max(1, _ct_order_count));
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

    draw_set_colour(make_colour_rgb(30, 30, 60));
    draw_rectangle(_px, _py, _px + _pip_w - 4, _py + _bar_h - 4, false);

    var _ct_pct = min(1, unit_ct[_i] / 100);
    draw_set_colour(_ucol);
    draw_rectangle(_px, _py + (_bar_h - 4) * (1 - _ct_pct), _px + _pip_w - 4, _py + _bar_h - 4, false);

    if (_i == active_unit) {
        draw_set_colour(col_ui_highlight);
        draw_rectangle(_px - 1, _py - 1, _px + _pip_w - 3, _py + _bar_h - 3, true);
        draw_rectangle(_px - 2, _py - 2, _px + _pip_w - 2, _py + _bar_h - 2, true);
    }

    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _label = "K";
    if (unit_class[_i] == 1) _label = "M";
    if (unit_class[_i] == 2) _label = "A";
    if (unit_class[_i] == 3) _label = "g";
    if (unit_class[_i] == 4) _label = "a";
    draw_text(_px + (_pip_w - 4) * 0.5, _py + (_bar_h - 4) * 0.5, _label);

    _pip_idx++;
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);

// --- End Turn Button ---
if (game_state == 2 && active_unit >= 0 && unit_team[active_unit] == 0) {
    var _btn_w = 110;
    var _btn_h = 40;
    var _btn_x = _ww - _btn_w - 12;
    var _btn_y = _wh - _btn_h - 12;

    draw_set_colour(col_ui_bg);
    draw_set_alpha(0.9);
    draw_rectangle(_btn_x, _btn_y, _btn_x + _btn_w, _btn_y + _btn_h, false);
    draw_set_alpha(1);
    draw_set_colour(col_ui_border);
    draw_rectangle(_btn_x, _btn_y, _btn_x + _btn_w, _btn_y + _btn_h, true);

    draw_set_colour(col_ui_text);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_btn_x + _btn_w * 0.5, _btn_y + _btn_h * 0.5, "End Turn");
}

// --- Unit Info Panel ---
var _show_info = -1;
if (info_unit >= 0 && info_unit < unit_count && unit_alive[info_unit]) _show_info = info_unit;
else if (active_unit >= 0 && active_unit < unit_count && unit_alive[active_unit]) _show_info = active_unit;

if (_show_info >= 0) {
    var _panel_w = min(230, _ww * 0.52);
    var _panel_h = 104;
    var _panel_x = 10;
    var _panel_y = _wh - _panel_h - 12;

    draw_set_colour(col_ui_bg);
    draw_set_alpha(0.9);
    draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _panel_h, false);
    draw_set_alpha(1);
    draw_set_colour(col_ui_border);
    draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _panel_h, true);

    var _u = _show_info;
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    var _ucol = col_knight;
    if (unit_class[_u] == 1) _ucol = col_mage;
    if (unit_class[_u] == 2) _ucol = col_archer;
    if (unit_class[_u] == 3) _ucol = col_goblin;
    if (unit_class[_u] == 4) _ucol = col_enemy_archer;

    draw_set_colour(_ucol);
    draw_text(_panel_x + 8, _panel_y + 6, class_name[unit_class[_u]]);

    draw_set_colour(col_ui_text);
    var _team_str = " (ally)";
    if (unit_team[_u] == 1) _team_str = " (foe)";
    draw_text(_panel_x + 65, _panel_y + 6, _team_str);

    // Stats row 1
    draw_set_colour(col_ui_text);
    draw_text(_panel_x + 8, _panel_y + 26, "HP:" + string(max(0, unit_hp[_u])) + "/" + string(unit_max_hp[_u]));
    draw_text(_panel_x + 120, _panel_y + 26, "ATK:" + string(unit_atk[_u]));

    // Stats row 2
    draw_text(_panel_x + 8, _panel_y + 44, "DEF:" + string(unit_def[_u]));
    draw_text(_panel_x + 120, _panel_y + 44, "SPD:" + string(unit_spd[_u]));

    // Stats row 3 — movement and range
    draw_set_colour(col_tile_move);
    draw_text(_panel_x + 8, _panel_y + 62, "MOV:" + string(unit_move_range[_u]));
    draw_set_colour(col_tile_attack);
    draw_text(_panel_x + 120, _panel_y + 62, "RNG:" + string(unit_atk_range[_u]));

    // Skill description
    draw_set_colour(col_ui_highlight);
    var _skill = "";
    if (unit_class[_u] == 0) _skill = "Shield: +1 DEF";
    if (unit_class[_u] == 1) _skill = "Charge: delayed spell";
    if (unit_class[_u] == 2) _skill = "Snipe: +1 height bonus";
    if (unit_class[_u] == 3) _skill = "Rush: fast melee";
    if (unit_class[_u] == 4) _skill = "Volley: ranged attack";
    draw_text(_panel_x + 8, _panel_y + 82, _skill);
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

// --- Level-Up Screen ---
if (game_state == 6) {
    // Dark overlay
    draw_set_colour(c_black);
    draw_set_alpha(0.6);
    draw_rectangle(0, 0, _ww, _wh, false);
    draw_set_alpha(1);

    if (levelup_phase == 0) {
        // Title
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(col_ui_highlight);
        draw_text(_ww * 0.5, _wh * 0.15, "LEVEL UP");
        draw_set_colour(col_ui_text);
        draw_text(_ww * 0.5, _wh * 0.25, "Choose a unit to upgrade");

        // Unit cards
        var _alive_count = 0;
        for (var _i = 0; _i < unit_count; _i++) {
            if (unit_alive[_i] && unit_team[_i] == 0) _alive_count++;
        }

        var _card_w = min(140, (_ww * 0.8) / max(1, _alive_count));
        var _card_h = 160;
        var _total_w = _alive_count * _card_w + (_alive_count - 1) * 10;
        var _start_x = (_ww - _total_w) * 0.5;
        var _card_y = _wh * 0.4;

        var _pidx = 0;
        for (var _i = 0; _i < unit_count; _i++) {
            if (!unit_alive[_i] || unit_team[_i] != 0) continue;

            var _cx2 = _start_x + _pidx * (_card_w + 10);

            // Card background
            var _ucol2 = col_knight;
            if (unit_class[_i] == 1) _ucol2 = col_mage;
            if (unit_class[_i] == 2) _ucol2 = col_archer;

            draw_set_colour(merge_colour(col_ui_bg, _ucol2, 0.3));
            draw_set_alpha(0.95);
            draw_rectangle(_cx2, _card_y, _cx2 + _card_w, _card_y + _card_h, false);
            draw_set_alpha(1);

            // Border
            draw_set_colour(col_ui_border);
            draw_rectangle(_cx2, _card_y, _cx2 + _card_w, _card_y + _card_h, true);

            // Class name
            draw_set_halign(fa_center);
            draw_set_valign(fa_top);
            draw_set_colour(_ucol2);
            draw_text(_cx2 + _card_w * 0.5, _card_y + 10, class_name[unit_class[_i]]);

            // HP bar
            var _hp_bar_w = _card_w * 0.7;
            var _hp_bar_x = _cx2 + (_card_w - _hp_bar_w) * 0.5;
            var _hp_bar_y = _card_y + 35;
            var _hp_pct = max(0, unit_hp[_i] / unit_max_hp[_i]);
            draw_set_colour(c_black);
            draw_rectangle(_hp_bar_x, _hp_bar_y, _hp_bar_x + _hp_bar_w, _hp_bar_y + 6, false);
            var _hpc = make_colour_rgb(60, 200, 60);
            if (_hp_pct < 0.5) _hpc = make_colour_rgb(200, 200, 60);
            if (_hp_pct < 0.25) _hpc = make_colour_rgb(200, 60, 60);
            draw_set_colour(_hpc);
            if (_hp_pct > 0) draw_rectangle(_hp_bar_x, _hp_bar_y, _hp_bar_x + _hp_bar_w * _hp_pct, _hp_bar_y + 6, false);

            // Stats
            draw_set_halign(fa_left);
            draw_set_colour(col_ui_text);
            var _sx2 = _cx2 + 8;
            draw_text(_sx2, _card_y + 48, "HP:" + string(unit_hp[_i]) + "/" + string(unit_max_hp[_i]));
            draw_text(_sx2, _card_y + 66, "ATK:" + string(unit_atk[_i]));
            draw_text(_sx2, _card_y + 84, "DEF:" + string(unit_def[_i]));
            draw_text(_sx2, _card_y + 102, "SPD:" + string(unit_spd[_i]));
            draw_text(_sx2, _card_y + 120, "MOV:" + string(unit_move_range[_i]));
            draw_text(_sx2, _card_y + 138, "RNG:" + string(unit_atk_range[_i]));

            _pidx++;
        }
    } else if (levelup_phase == 1) {
        // Title
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(col_ui_highlight);
        var _lu_name = class_name[unit_class[levelup_unit]];
        draw_text(_ww * 0.5, _wh * 0.15, _lu_name + " - Choose Upgrade");

        // 3 upgrade cards
        var _card_w2 = min(180, _ww * 0.28);
        var _card_h2 = 100;
        var _total_w2 = 3 * _card_w2 + 2 * 10;
        var _start_x2 = (_ww - _total_w2) * 0.5;
        var _card_y2 = _wh * 0.45;

        for (var _opt = 0; _opt < 3; _opt++) {
            var _ox = _start_x2 + _opt * (_card_w2 + 10);

            var _upg_id = levelup_opt0;
            if (_opt == 1) _upg_id = levelup_opt1;
            if (_opt == 2) _upg_id = levelup_opt2;

            // Card background
            draw_set_colour(col_ui_bg);
            draw_set_alpha(0.95);
            draw_rectangle(_ox, _card_y2, _ox + _card_w2, _card_y2 + _card_h2, false);
            draw_set_alpha(1);

            // Border — highlight if selected
            if (levelup_selected == _opt) {
                draw_set_colour(c_white);
                draw_rectangle(_ox - 1, _card_y2 - 1, _ox + _card_w2 + 1, _card_y2 + _card_h2 + 1, true);
                draw_rectangle(_ox - 2, _card_y2 - 2, _ox + _card_w2 + 2, _card_y2 + _card_h2 + 2, true);
            } else {
                draw_set_colour(col_ui_border);
                draw_rectangle(_ox, _card_y2, _ox + _card_w2, _card_y2 + _card_h2, true);
            }

            // Upgrade name
            draw_set_halign(fa_center);
            draw_set_valign(fa_top);
            draw_set_colour(col_ui_highlight);
            draw_text(_ox + _card_w2 * 0.5, _card_y2 + 12, upgrade_name[_upg_id]);

            // Description
            draw_set_colour(col_ui_text);
            draw_text(_ox + _card_w2 * 0.5, _card_y2 + 38, upgrade_desc[_upg_id]);

            // Confirm prompt if selected
            if (levelup_selected == _opt) {
                draw_set_colour(c_white);
                draw_text(_ox + _card_w2 * 0.5, _card_y2 + _card_h2 - 20, "Tap to Confirm");
            }
        }
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// --- HUD ---
draw_set_halign(fa_right);
draw_set_valign(fa_top);
draw_set_colour(col_ui_text);
draw_text(_ww - 14, 44, "Score: " + string(points));
draw_text(_ww - 14, 60, "Wave: " + string(wave_num));

// --- Hint ---
if (game_state == 2 && active_unit >= 0 && unit_team[active_unit] == 0) {
    draw_set_halign(fa_center);
    if (selected_tile_gx >= 0) {
        draw_set_colour(c_white);
        draw_text(_ww * 0.5, _wh - 58, "Tap again to confirm");
    } else if (valid_move_count > 0 && valid_attack_count > 0) {
        draw_set_colour(col_ui_text);
        draw_text(_ww * 0.5, _wh - 58, "Select a blue or red tile");
    } else if (valid_move_count > 0) {
        draw_set_colour(col_tile_move);
        draw_text(_ww * 0.5, _wh - 58, "Select a blue tile to move");
    } else if (valid_attack_count > 0) {
        draw_set_colour(col_tile_attack);
        draw_text(_ww * 0.5, _wh - 58, "Select a red target to attack");
    }
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
