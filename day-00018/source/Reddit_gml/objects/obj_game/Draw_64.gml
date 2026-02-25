
var _w = window_width;
var _h = window_height;
if (_w <= 0 || _h <= 0) exit;

// --- Screen Shake Offset ---
var _shk_x = 0;
var _shk_y = 0;
if (shake_amount > 0) {
    _shk_x = random_range(-shake_amount, shake_amount);
    _shk_y = random_range(-shake_amount, shake_amount);
}

// --- Background ---
draw_rectangle_colour(0, 0, _w, _h,
    col_bg_top, col_bg_top, col_bg_bot, col_bg_bot, false);

if (game_state == 0) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(c_white);
    draw_text_transformed(_w * 0.5, _h * 0.5, "Loading...", 2.5, 2.5, 0);
    exit;
}

// --- Draw Grid ---
var _first_row = floor(scroll_y / cell_size) - 1;
var _last_row = _first_row + visible_rows + 3;
_first_row = max(0, _first_row);
_last_row = min(grid_rows - 1, _last_row);

var _cs = cell_size;
var _bv = bevel;
var _gcols = grid_cols;
var _grows = grid_rows;

// Draw empty cell backgrounds (sky/cave)
for (var _r = _first_row; _r <= _last_row; _r++) {
    var _dy = grid_oy + _r * _cs - scroll_y + _shk_y;
    if (_dy > _h || _dy + _cs < hud_h) continue;
    for (var _c = 0; _c < _gcols; _c++) {
        if (grid[_c][_r] == EMPTY) {
            var _dx = grid_ox + _c * _cs + _shk_x;
            draw_set_colour(cave_bg[_r]);
            draw_rectangle(_dx, _dy, _dx + _cs - 1, _dy + _cs - 1, false);
        }
    }
}

// Draw blocks
for (var _r = _first_row; _r <= _last_row; _r++) {
    var _dy = grid_oy + _r * _cs - scroll_y + _shk_y;
    if (_dy > _h || _dy + _cs < hud_h) continue;
    for (var _c = 0; _c < _gcols; _c++) {
        var _block = grid[_c][_r];
        if (_block == EMPTY) continue;

        var _dx = grid_ox + _c * _cs + _shk_x;

        // --- Fog of War: check if revealed (within 2 cells of EMPTY) ---
        var _revealed = false;
        if (_r > 0 && grid[_c][_r - 1] == EMPTY) _revealed = true;
        if (!_revealed && _r < _grows - 1 && grid[_c][_r + 1] == EMPTY) _revealed = true;
        if (!_revealed && _c > 0 && grid[_c - 1][_r] == EMPTY) _revealed = true;
        if (!_revealed && _c < _gcols - 1 && grid[_c + 1][_r] == EMPTY) _revealed = true;
        if (!_revealed && _r > 1 && grid[_c][_r - 2] == EMPTY) _revealed = true;
        if (!_revealed && _r < _grows - 2 && grid[_c][_r + 2] == EMPTY) _revealed = true;
        if (!_revealed && _c > 1 && grid[_c - 2][_r] == EMPTY) _revealed = true;
        if (!_revealed && _c < _gcols - 2 && grid[_c + 2][_r] == EMPTY) _revealed = true;
        if (!_revealed && _r > 0 && _c > 0 && grid[_c - 1][_r - 1] == EMPTY) _revealed = true;
        if (!_revealed && _r > 0 && _c < _gcols - 1 && grid[_c + 1][_r - 1] == EMPTY) _revealed = true;
        if (!_revealed && _r < _grows - 1 && _c > 0 && grid[_c - 1][_r + 1] == EMPTY) _revealed = true;
        if (!_revealed && _r < _grows - 1 && _c < _gcols - 1 && grid[_c + 1][_r + 1] == EMPTY) _revealed = true;

        // Pick colors based on revealed state
        var _col_f = col_hidden;
        var _col_t = col_hidden_top;
        var _col_d = col_hidden_dark;

        if (_revealed) {
            _col_f = block_color[_block];
            _col_t = block_color_top[_block];
            _col_d = block_color_dark[_block];

            if (_block == LAVA) {
                var _pulse = 0.5 + 0.5 * sin(lava_pulse + _c * 0.5 + _r * 0.7);
                _col_f = merge_colour(col_lava_a, col_lava_b, _pulse);
                _col_t = merge_colour(_col_f, c_white, 0.3);
                _col_d = merge_colour(_col_f, c_black, 0.35);
            }

            if (_block == DIAMOND) {
                var _spark = 0.5 + 0.5 * sin(sparkle_time * 2 + _c * 1.3 + _r * 0.9);
                _col_f = merge_colour(block_color[DIAMOND], c_white, _spark * 0.4);
                _col_t = merge_colour(_col_f, c_white, 0.35);
                _col_d = merge_colour(_col_f, c_black, 0.2);
            }
        }

        // --- LADDER: special drawing ---
        if (_block == LADDER) {
            // Background (cave bg shows through)
            draw_set_colour(cave_bg[_r]);
            draw_rectangle(_dx, _dy, _dx + _cs - 1, _dy + _cs - 1, false);
            // Two vertical rails
            var _rail_w = max(2, floor(_cs * 0.12));
            draw_set_colour(col_ladder_rail);
            draw_rectangle(_dx + _rail_w, _dy, _dx + _rail_w + _rail_w - 1, _dy + _cs - 1, false);
            draw_rectangle(_dx + _cs - _rail_w * 2, _dy, _dx + _cs - _rail_w - 1, _dy + _cs - 1, false);
            // Three horizontal rungs
            var _rung_h = max(2, floor(_cs * 0.1));
            draw_set_colour(col_ladder_rung);
            draw_rectangle(_dx + _rail_w, _dy + floor(_cs * 0.15), _dx + _cs - _rail_w - 1, _dy + floor(_cs * 0.15) + _rung_h - 1, false);
            draw_rectangle(_dx + _rail_w, _dy + floor(_cs * 0.45), _dx + _cs - _rail_w - 1, _dy + floor(_cs * 0.45) + _rung_h - 1, false);
            draw_rectangle(_dx + _rail_w, _dy + floor(_cs * 0.75), _dx + _cs - _rail_w - 1, _dy + floor(_cs * 0.75) + _rung_h - 1, false);
            // Outline
            draw_set_colour(c_black);
            draw_set_alpha(0.25);
            draw_rectangle(_dx, _dy, _dx + _cs - 1, _dy + _cs - 1, true);
            draw_set_alpha(1.0);
        }
        else {
            // 3D cube: right face (dark)
            draw_set_colour(_col_d);
            draw_rectangle(_dx + _cs - _bv, _dy + _bv, _dx + _cs - 1, _dy + _cs - 1, false);

            // Top face (light)
            draw_set_colour(_col_t);
            draw_rectangle(_dx, _dy, _dx + _cs - _bv - 1, _dy + _bv - 1, false);

            // Top-right corner
            draw_set_colour(merge_colour(_col_t, _col_d, 0.5));
            draw_rectangle(_dx + _cs - _bv, _dy, _dx + _cs - 1, _dy + _bv - 1, false);

            // Front face
            draw_set_colour(_col_f);
            draw_rectangle(_dx, _dy + _bv, _dx + _cs - _bv - 1, _dy + _cs - 1, false);

            // Outline
            draw_set_colour(c_black);
            draw_set_alpha(0.4);
            draw_rectangle(_dx, _dy, _dx + _cs - 1, _dy + _cs - 1, true);
            draw_set_alpha(1.0);

            // Inner 3D edge lines
            draw_set_colour(c_black);
            draw_set_alpha(0.2);
            draw_line(_dx, _dy + _bv, _dx + _cs - _bv, _dy + _bv);
            draw_line(_dx + _cs - _bv, _dy, _dx + _cs - _bv, _dy + _cs);
            draw_set_alpha(1.0);

            // --- Bedrock X-mark pattern ---
            if (_revealed && _block == BEDROCK) {
                draw_set_colour(c_black);
                draw_set_alpha(0.4);
                // X pattern
                draw_line(_dx + 3, _dy + 3, _dx + _cs - 4, _dy + _cs - 4);
                draw_line(_dx + _cs - 4, _dy + 3, _dx + 3, _dy + _cs - 4);
                // Second X offset for a denser crosshatch
                draw_line(_dx + floor(_cs * 0.5), _dy + 2, _dx + _cs - 3, _dy + floor(_cs * 0.5));
                draw_line(_dx + 2, _dy + floor(_cs * 0.5), _dx + floor(_cs * 0.5), _dy + _cs - 3);
                draw_set_alpha(1.0);
                // Small bright specks (crystal-like)
                draw_set_colour(make_colour_rgb(120, 80, 160));
                draw_set_alpha(0.6);
                draw_rectangle(_dx + floor(_cs * 0.25), _dy + floor(_cs * 0.3), _dx + floor(_cs * 0.25) + 2, _dy + floor(_cs * 0.3) + 2, false);
                draw_rectangle(_dx + floor(_cs * 0.65), _dy + floor(_cs * 0.6), _dx + floor(_cs * 0.65) + 2, _dy + floor(_cs * 0.6) + 2, false);
                draw_set_alpha(1.0);
            }

            // --- Crack overlay on damaged blocks ---
            if (_revealed && _block != BEDROCK && _block != LAVA) {
                var _max_hp = block_hp[_block];
                var _cur_hp = durability[_c][_r];
                if (_cur_hp < _max_hp && _cur_hp > 0) {
                    var _dmg_frac = 1.0 - (_cur_hp / _max_hp);
                    draw_set_colour(c_black);
                    draw_set_alpha(0.25 + _dmg_frac * 0.3);
                    // Crack lines — more cracks as damage increases
                    draw_line(_dx + floor(_cs * 0.3), _dy + floor(_cs * 0.2), _dx + floor(_cs * 0.5), _dy + floor(_cs * 0.55));
                    draw_line(_dx + floor(_cs * 0.5), _dy + floor(_cs * 0.55), _dx + floor(_cs * 0.7), _dy + floor(_cs * 0.4));
                    if (_dmg_frac >= 0.5) {
                        draw_line(_dx + floor(_cs * 0.5), _dy + floor(_cs * 0.55), _dx + floor(_cs * 0.35), _dy + floor(_cs * 0.8));
                        draw_line(_dx + floor(_cs * 0.15), _dy + floor(_cs * 0.5), _dx + floor(_cs * 0.3), _dy + floor(_cs * 0.2));
                        draw_line(_dx + floor(_cs * 0.7), _dy + floor(_cs * 0.4), _dx + floor(_cs * 0.85), _dy + floor(_cs * 0.7));
                    }
                    draw_set_alpha(1.0);
                }
            }

            // Minable highlight — only blocks adjacent to PLAYER
            if (_revealed && _block != BEDROCK) {
                var _adj_player = (abs(_c - player_col) + abs(_r - player_row) == 1);
                if (_adj_player) {
                    draw_set_colour(c_white);
                    draw_set_alpha(0.18 + 0.07 * sin(current_time * 0.005));
                    draw_rectangle(_dx + 1, _dy + 1, _dx + _cs - 2, _dy + _cs - 2, false);
                    draw_set_alpha(1.0);
                }
            }
        }
    }
}

// --- Draw Stalactite Crusher Zone ---
// Use the float stalactite_y for smooth movement (not snapped to rows)
var _crush_pixel_y = grid_oy + (stalactite_y + 1) * _cs - scroll_y + _shk_y;

// Always draw tips even when crush zone is above screen (they poke in from top)
// Fill everything above the front with dark stone
if (_crush_pixel_y > 0) {
    var _crush_top_y = grid_oy + _first_row * _cs - scroll_y + _shk_y - _cs;
    draw_set_colour(col_stalactite);
    draw_set_alpha(0.85);
    draw_rectangle(grid_ox + _shk_x, min(_crush_top_y, 0), grid_ox + grid_cols * _cs + _shk_x, _crush_pixel_y, false);
    draw_set_alpha(1.0);
}

// Stalactite tips — draw if any part visible (tip bottom = _crush_pixel_y + 0.7*_cs)
if (_crush_pixel_y + _cs * 0.7 > hud_h) {
    var _tip_draw_y = max(_crush_pixel_y, hud_h - _cs * 0.3);
    for (var _sc = 0; _sc < grid_cols; _sc++) {
        var _sx = grid_ox + _sc * _cs + _shk_x;
        var _tip_len = _cs * (0.3 + 0.4 * abs(sin(_sc * 2.7 + 0.5)));
        var _tip_cx = _sx + _cs * 0.5;

        draw_set_colour(col_stalactite);
        draw_triangle(_sx, _crush_pixel_y, _sx + _cs, _crush_pixel_y, _tip_cx, _crush_pixel_y + _tip_len, false);
        draw_set_colour(col_stalactite_tip);
        draw_triangle(_sx + _cs * 0.3, _crush_pixel_y, _sx + _cs * 0.7, _crush_pixel_y, _tip_cx, _crush_pixel_y + _tip_len * 0.7, false);
    }
}

// --- Draw Cute Digger Character ---
if (game_state != 2) {
    var _pdx = grid_ox + player_draw_col * _cs + _shk_x;
    var _pdy = grid_oy + player_draw_row * _cs - scroll_y + _shk_y;
    var _cx = _pdx + floor(_cs * 0.5);
    var _facing = player_facing;

    // Inset slightly so character fits within cell
    var _margin = max(1, floor(_cs * 0.08));
    var _left = _pdx + _margin;
    var _right = _pdx + _cs - _margin - 1;
    var _top = _pdy + _margin;
    var _bot = _pdy + _cs - _margin - 1;
    var _mid_y = _top + floor((_bot - _top) * 0.45);

    // --- Boots (bottom strip) ---
    var _boot_top = _bot - floor(_cs * 0.15);
    draw_set_colour(make_colour_rgb(80, 50, 25));
    draw_rectangle(_left + 1, _boot_top, _cx - 2, _bot, false);
    draw_rectangle(_cx + 1, _boot_top, _right - 1, _bot, false);

    // --- Overalls / Body ---
    draw_set_colour(col_digger_body);
    draw_rectangle(_left, _mid_y, _right, _boot_top - 1, false);
    draw_set_colour(col_digger_body_dark);
    draw_rectangle(_right - floor(_cs * 0.12), _mid_y, _right, _boot_top - 1, false);
    draw_set_colour(col_digger_belt);
    var _belt_h = max(2, floor(_cs * 0.06));
    draw_rectangle(_left, _mid_y, _right, _mid_y + _belt_h - 1, false);
    draw_set_colour(make_colour_rgb(200, 180, 60));
    draw_rectangle(_cx - 2, _mid_y, _cx + 1, _mid_y + _belt_h - 1, false);

    // --- Face / Skin ---
    var _face_top = _top + floor(_cs * 0.2);
    draw_set_colour(col_digger_skin);
    draw_rectangle(_left + 1, _face_top, _right - 1, _mid_y - 1, false);
    draw_set_colour(col_digger_skin_dark);
    draw_rectangle(_right - floor(_cs * 0.12), _face_top, _right - 1, _mid_y - 1, false);

    // --- Hard Hat ---
    draw_set_colour(col_digger_hat);
    var _hat_bot = _face_top;
    draw_rectangle(_left - 1, _top, _right + 1, _hat_bot - 1, false);
    draw_set_colour(col_digger_hat_dark);
    draw_rectangle(_left - 2, _hat_bot - max(2, floor(_cs * 0.05)), _right + 2, _hat_bot - 1, false);
    draw_set_colour(merge_colour(col_digger_hat, c_white, 0.4));
    draw_rectangle(_left, _top, _right - floor(_cs * 0.15), _top + max(1, floor(_cs * 0.06)), false);
    draw_set_colour(make_colour_rgb(255, 255, 200));
    var _lamp_x = _cx + _facing * floor(_cs * 0.05);
    var _lamp_r = max(1, floor(_cs * 0.06));
    draw_circle(_lamp_x, _top + floor(_cs * 0.1), _lamp_r, false);

    // --- Eyes ---
    var _eye_y = _face_top + floor((_mid_y - _face_top) * 0.35);
    var _eye_space = floor(_cs * 0.12);
    var _eye_r = max(1, floor(_cs * 0.06));
    draw_set_colour(c_white);
    draw_circle(_cx - _eye_space, _eye_y, _eye_r + 1, false);
    draw_circle(_cx + _eye_space, _eye_y, _eye_r + 1, false);
    draw_set_colour(col_digger_eye);
    draw_circle(_cx - _eye_space + _facing, _eye_y, _eye_r, false);
    draw_circle(_cx + _eye_space + _facing, _eye_y, _eye_r, false);

    // --- Mouth (small smile) ---
    var _mouth_y = _eye_y + floor(_cs * 0.1);
    draw_set_colour(make_colour_rgb(180, 100, 80));
    draw_rectangle(_cx - floor(_cs * 0.06), _mouth_y, _cx + floor(_cs * 0.06), _mouth_y + 1, false);

    // --- Pickaxe (held on facing side) ---
    var _pick_x = _facing > 0 ? _right + 1 : _left - floor(_cs * 0.2);
    var _pick_y = _mid_y - floor(_cs * 0.05);
    draw_set_colour(make_colour_rgb(120, 80, 30));
    var _handle_w = max(2, floor(_cs * 0.06));
    draw_rectangle(_pick_x, _pick_y, _pick_x + _handle_w - 1, _pick_y + floor(_cs * 0.3), false);
    draw_set_colour(col_digger_pick);
    var _head_off = _facing * floor(_cs * 0.1);
    draw_rectangle(_pick_x - floor(_cs * 0.06) + _head_off, _pick_y - floor(_cs * 0.04),
                   _pick_x + _handle_w + floor(_cs * 0.06) + _head_off, _pick_y + floor(_cs * 0.04), false);

    // --- Character outline ---
    draw_set_colour(c_black);
    draw_set_alpha(0.35);
    draw_rectangle(_left - 1, _top, _right + 1, _bot, true);
    draw_set_alpha(1.0);
}
else {
    // === DEATH ANIMATION ===
    var _dt = gameover_timer;
    var _ds = _cs * 0.9;

    // --- Flying hat (spins away) ---
    if (_dt < 90) {
        var _hat_a = clamp(1.0 - _dt / 90.0, 0, 1);
        var _hat_sz = _ds * 0.4;
        draw_set_alpha(_hat_a);
        // Rotate hat around its center
        var _hx = death_hat_x + _shk_x;
        var _hy = death_hat_y + _shk_y;
        var _hr = death_hat_rot;
        var _cos_h = dcos(_hr);
        var _sin_h = dsin(_hr);
        // Draw rotated hat (4-point quad approximation)
        draw_set_colour(col_digger_hat);
        // Simple: draw hat as a rectangle with rotation faked via offset
        var _hhs = _hat_sz * 0.5;
        draw_rectangle(_hx - _hhs, _hy - _hhs * 0.6, _hx + _hhs, _hy + _hhs * 0.3, false);
        draw_set_colour(col_digger_hat_dark);
        draw_rectangle(_hx - _hhs - 2, _hy + _hhs * 0.1, _hx + _hhs + 2, _hy + _hhs * 0.3, false);
        // Lamp
        draw_set_colour(make_colour_rgb(255, 255, 200));
        draw_circle(_hx, _hy - _hhs * 0.3, max(1, _hat_sz * 0.1), false);
        draw_set_alpha(1.0);
    }

    // --- Flying pickaxe (tumbles away) ---
    if (_dt < 90) {
        var _pk_a = clamp(1.0 - _dt / 90.0, 0, 1);
        var _pk_sz = _ds * 0.35;
        draw_set_alpha(_pk_a);
        var _pkx = death_pick_x + _shk_x;
        var _pky = death_pick_y + _shk_y;
        // Handle
        draw_set_colour(make_colour_rgb(120, 80, 30));
        draw_rectangle(_pkx - 1, _pky, _pkx + 1, _pky + _pk_sz, false);
        // Head
        draw_set_colour(col_digger_pick);
        draw_rectangle(_pkx - _pk_sz * 0.4, _pky - 2, _pkx + _pk_sz * 0.4, _pky + 2, false);
        draw_set_alpha(1.0);
    }

    // --- Cute ghost (rises from death spot) ---
    if (_dt > 15) {
        var _ghost_a = clamp(1.0 - (_dt - 15) / 75.0, 0, 0.7);
        var _gx = death_x + sin(_dt * 0.08) * _cs * 0.3 + _shk_x;
        var _gy = death_y - death_ghost_y + _shk_y;
        var _gs = _ds * 0.45;

        draw_set_alpha(_ghost_a);

        // Ghost body (rounded blob)
        draw_set_colour(c_white);
        draw_circle(_gx, _gy, _gs, false);
        // Wavy bottom tail
        draw_rectangle(_gx - _gs, _gy, _gx + _gs, _gy + _gs * 0.6, false);
        // Wavy edge bumps
        draw_circle(_gx - _gs * 0.6, _gy + _gs * 0.6, _gs * 0.35, false);
        draw_circle(_gx + _gs * 0.6, _gy + _gs * 0.6, _gs * 0.35, false);
        draw_circle(_gx, _gy + _gs * 0.7, _gs * 0.3, false);

        // X eyes
        draw_set_colour(c_black);
        var _ge_sp = _gs * 0.35;
        var _ge_sz = _gs * 0.18;
        var _gey = _gy - _gs * 0.15;
        // Left X
        draw_line_width(_gx - _ge_sp - _ge_sz, _gey - _ge_sz, _gx - _ge_sp + _ge_sz, _gey + _ge_sz, 2);
        draw_line_width(_gx - _ge_sp + _ge_sz, _gey - _ge_sz, _gx - _ge_sp - _ge_sz, _gey + _ge_sz, 2);
        // Right X
        draw_line_width(_gx + _ge_sp - _ge_sz, _gey - _ge_sz, _gx + _ge_sp + _ge_sz, _gey + _ge_sz, 2);
        draw_line_width(_gx + _ge_sp + _ge_sz, _gey - _ge_sz, _gx + _ge_sp - _ge_sz, _gey + _ge_sz, 2);

        // Little "o" mouth
        draw_circle(_gx, _gy + _gs * 0.2, _gs * 0.12, true);

        draw_set_alpha(1.0);
    }

    // --- Stars spinning around death spot ---
    if (_dt < 60) {
        var _star_a = clamp(1.0 - _dt / 60.0, 0, 0.9);
        draw_set_alpha(_star_a);
        draw_set_colour(c_yellow);
        for (var _si = 0; _si < 5; _si++) {
            var _sa = _dt * 4 + _si * 72;
            var _sr = _cs * 0.5 + _dt * 0.3;
            var _star_x = death_x + lengthdir_x(_sr, _sa) + _shk_x;
            var _star_y = death_y + lengthdir_y(_sr, _sa) + _shk_y - _dt * 0.5;
            var _ssz = max(2, 4 - _dt * 0.05);
            draw_circle(_star_x, _star_y, _ssz, false);
        }
        draw_set_alpha(1.0);
    }
}

// --- Particles ---
for (var _i = 0; _i < p_count; _i++) {
    var _sz = 3 + 3 * p_life[_i];
    draw_set_colour(p_col[_i]);
    draw_set_alpha(p_life[_i]);
    draw_rectangle(p_x[_i] - _sz * 0.5 + _shk_x, p_y[_i] - _sz * 0.5 + _shk_y,
                   p_x[_i] + _sz * 0.5 + _shk_x, p_y[_i] + _sz * 0.5 + _shk_y, false);
    draw_set_alpha(1.0);
}

// --- Float Text ---
draw_set_font(fnt_default);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
for (var _i = 0; _i < f_count; _i++) {
    var _a = f_life[_i];
    var _sc = 1.5 + (1 - _a) * 0.5;
    draw_set_alpha(_a);
    draw_set_colour(c_black);
    draw_text_transformed(f_x[_i] + 1 + _shk_x, f_y[_i] + 1 + _shk_y, f_text[_i], _sc, _sc, 0);
    draw_set_colour(f_col[_i]);
    draw_text_transformed(f_x[_i] + _shk_x, f_y[_i] + _shk_y, f_text[_i], _sc, _sc, 0);
    draw_set_alpha(1.0);
}

// --- Screen Flash ---
if (flash_alpha > 0) {
    draw_set_colour(c_red);
    draw_set_alpha(flash_alpha);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);
}

// --- Cave-In Flash ---
if (collapse_flash > 0) {
    draw_set_colour(c_white);
    draw_set_alpha(collapse_flash * 0.3);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);
}

// --- HUD ---
draw_set_colour(c_black);
draw_set_alpha(0.75);
draw_rectangle(0, 0, _w, hud_h, false);
draw_set_alpha(1.0);

// Score (left)
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour(c_yellow);
draw_text_transformed(15, hud_h * 0.5, string(points), 2, 2, 0);

// Depth (center)
draw_set_halign(fa_center);
draw_set_colour(c_white);
draw_text_transformed(_w * 0.5, hud_h * 0.3, "DEPTH", 1.1, 1.1, 0);
draw_set_colour(col_hud_depth);
draw_text_transformed(_w * 0.5, hud_h * 0.7, string(max_depth) + "m", 1.6, 1.6, 0);

// Lives (right) — red cubes
draw_set_halign(fa_right);
draw_set_colour(c_white);
draw_text_transformed(_w - 15, hud_h * 0.25, "LIVES", 1.1, 1.1, 0);
for (var _i = 0; _i < lives; _i++) {
    var _lx = _w - 15 - _i * 22;
    var _ly = hud_h * 0.5;
    var _ls = 14;
    var _lb = 3;
    draw_set_colour(merge_colour(col_life, c_black, 0.3));
    draw_rectangle(_lx - _ls + _lb, _ly + _lb, _lx - 1, _ly + _ls - 1, false);
    draw_set_colour(col_life_hi);
    draw_rectangle(_lx - _ls, _ly, _lx - _lb - 1, _ly + _lb - 1, false);
    draw_set_colour(col_life);
    draw_rectangle(_lx - _ls, _ly + _lb, _lx - _lb - 1, _ly + _ls - 1, false);
}

// --- Cave-In Timer Bar ---
var _bar_h = 8;
var _bar_y = hud_h + 2;
var _bar_frac = clamp(collapse_timer / collapse_max, 0, 1);
var _bar_w = floor(_w * _bar_frac);

// Bar background
draw_set_colour(c_black);
draw_set_alpha(0.5);
draw_rectangle(0, _bar_y, _w, _bar_y + _bar_h, false);
draw_set_alpha(1.0);

// Bar fill — green to yellow to red
var _bar_col = c_lime;
if (_bar_frac < 0.25) {
    _bar_col = merge_colour(c_red, c_yellow, _bar_frac / 0.25);
} else if (_bar_frac < 0.5) {
    _bar_col = merge_colour(c_yellow, c_lime, (_bar_frac - 0.25) / 0.25);
}

draw_set_colour(_bar_col);
draw_rectangle(0, _bar_y, _bar_w, _bar_y + _bar_h, false);

// Bright edge on bar
draw_set_colour(merge_colour(_bar_col, c_white, 0.4));
draw_rectangle(0, _bar_y, _bar_w, _bar_y + 2, false);

// --- Warning Text (when timer < 3 seconds / 180 frames) ---
if (collapse_timer < 180 && collapse_timer > 0 && !collapsing) {
    var _warn_a = 0.5 + 0.5 * sin(current_time * 0.01);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_alpha(_warn_a);
    draw_set_colour(c_black);
    draw_text_transformed(_w * 0.5 + 2, _h * 0.5 + 2, "WARNING", 3, 3, 0);
    draw_set_colour(c_red);
    draw_text_transformed(_w * 0.5, _h * 0.5, "WARNING", 3, 3, 0);
    draw_set_alpha(1.0);
}

// --- "CAVE IN!" Text During Collapse ---
if (collapsing) {
    var _ci_a = 0.7 + 0.3 * sin(current_time * 0.008);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_alpha(_ci_a);
    draw_set_colour(c_black);
    draw_text_transformed(_w * 0.5 + 3, _h * 0.5 + 3, "CAVE IN!", 4, 4, 0);
    draw_set_colour(c_orange);
    draw_text_transformed(_w * 0.5, _h * 0.5, "CAVE IN!", 4, 4, 0);
    draw_set_alpha(1.0);
}

// Combo indicator
if (combo_count >= 3 && combo_timer > 0) {
    var _cm = 2;
    if (combo_count >= 8) _cm = 4;
    else if (combo_count >= 5) _cm = 3;

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    var _ca = clamp(combo_timer / 30, 0, 1);
    draw_set_alpha(_ca);
    draw_set_colour(c_black);
    draw_text_transformed(_w * 0.5 + 2, hud_h + _bar_h + 12, "COMBO x" + string(_cm), 1.8, 1.8, 0);
    draw_set_colour(c_orange);
    draw_text_transformed(_w * 0.5, hud_h + _bar_h + 10, "COMBO x" + string(_cm), 1.8, 1.8, 0);
    draw_set_alpha(1.0);
}

// --- Game Over Overlay ---
if (game_state == 2) {
    draw_set_alpha(0.6);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_set_colour(c_maroon);
    draw_text_transformed(_w * 0.5 + 2, _h * 0.28 + 2, "GAME OVER", 3.5, 3.5, 0);
    draw_set_colour(c_red);
    draw_text_transformed(_w * 0.5, _h * 0.28, "GAME OVER", 3.5, 3.5, 0);

    draw_set_colour(c_yellow);
    draw_text_transformed(_w * 0.5, _h * 0.42, "Score: " + string(points), 2.5, 2.5, 0);

    draw_set_colour(col_hud_depth);
    draw_text_transformed(_w * 0.5, _h * 0.52, "Depth: " + string(max_depth) + "m", 2, 2, 0);

    if (gameover_timer > 60) {
        var _blink = 0.5 + 0.5 * sin(current_time * 0.005);
        draw_set_alpha(_blink);
        draw_set_colour(c_white);
        draw_text_transformed(_w * 0.5, _h * 0.68, "Tap to play again", 2, 2, 0);
        draw_set_alpha(1.0);
    }
}
