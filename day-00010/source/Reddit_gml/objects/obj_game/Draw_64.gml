// ========================================
// GEM FORGE — Draw_64.gml
// ========================================

draw_clear(bg_color);

if (game_state == 0) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_text_transformed(scr_w * 0.5, scr_h * 0.5, "Loading...", 2, 2, 0);
    exit;
}

var _font_s = max(scr_w / 400, 1.2);
var _pad = max(cell_size * 0.08, 2);
var _spr_scale = (cell_size - _pad * 2) / 128;

// ===================== HEADER =====================
var _hdr_y = scr_h * 0.03;

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(make_color_rgb(180, 180, 200));
draw_text_transformed(grid_x, _hdr_y, "Round " + string(round_num), _font_s * 1.1, _font_s * 1.1, 0);

draw_set_halign(fa_right);
draw_set_color(moves_left <= 3 ? make_color_rgb(231, 76, 60) : make_color_rgb(180, 180, 200));
draw_text_transformed(grid_x + GF_COLS * cell_size, _hdr_y, string(moves_left) + " moves", _font_s * 1.1, _font_s * 1.1, 0);

// Progress bar
var _bar_y = _hdr_y + _font_s * 22;
var _bar_w = GF_COLS * cell_size;
var _bar_h = max(cell_size * 0.3, 14);
var _prog = clamp(round_score / max(target_score, 1), 0, 1);

draw_set_color(make_color_rgb(40, 40, 60));
draw_roundrect(grid_x, _bar_y, grid_x + _bar_w, _bar_y + _bar_h, false);
if (_prog > 0.02) {
    draw_set_color(_prog >= 1 ? make_color_rgb(46, 204, 113) : make_color_rgb(52, 152, 219));
    draw_roundrect(grid_x, _bar_y, grid_x + _bar_w * _prog, _bar_y + _bar_h, false);
}

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_text_transformed(grid_x + _bar_w * 0.5, _bar_y + _bar_h * 0.5, string(round_score) + " / " + string(target_score), _font_s * 0.8, _font_s * 0.8, 0);

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(make_color_rgb(241, 196, 15));
draw_text_transformed(grid_x, _bar_y + _bar_h + 4, "Score: " + string(points), _font_s * 0.9, _font_s * 0.9, 0);

// Apply screen shake to grid
var _sx = shake_x;
var _sy = shake_y;
grid_x += _sx;
grid_y += _sy;

// ===================== GRID BG =====================
draw_set_alpha(0.3);
draw_set_color(make_color_rgb(50, 50, 75));
draw_roundrect(grid_x - 4, grid_y - 4, grid_x + GF_COLS * cell_size + 4, grid_y + GF_ROWS * cell_size + 4, false);
draw_set_alpha(1);

// ===================== GEMS =====================
for (var _c = 0; _c < GF_COLS; _c++) {
    for (var _r = 0; _r < GF_ROWS; _r++) {
        if (grid[_c][_r] < 0) continue;
        if ((anim_state == 1 || anim_state == 5) &&
            ((_c == swap_c1 && _r == swap_r1) || (_c == swap_c2 && _r == swap_r2))) continue;

        var _cx = grid_x + _c * cell_size + cell_size * 0.5;
        var _cy = grid_y + _r * cell_size + cell_size * 0.5 + gem_y_off[_c][_r];
        var _s = gem_scale[_c][_r];
        var _gem = grid[_c][_r];
        var _sc = _spr_scale * _s;
        if (_cy + cell_size < grid_y - cell_size) continue;

        var _alpha = marked[_c][_r] ? 0.5 + 0.5 * _s : 1;

        // Draw gem sprite
        draw_sprite_ext(gem_sprites[_gem], 0, _cx, _cy, _sc, _sc, 0, c_white, _alpha);

        // Draw special overlay
        var _sp = special[_c][_r];
        var _rad = (cell_size - _pad * 2) * 0.5 * _s;
        if (_sp == SP_BOMB) {
            // Orange burst lines
            draw_set_color(make_color_rgb(255, 165, 0));
            draw_set_alpha(_alpha * 0.9);
            var _lr = _rad * 0.7;
            for (var _a = 0; _a < 360; _a += 45) {
                var _x1 = _cx + lengthdir_x(_lr * 0.3, _a);
                var _y1 = _cy + lengthdir_y(_lr * 0.3, _a);
                var _x2 = _cx + lengthdir_x(_lr, _a);
                var _y2 = _cy + lengthdir_y(_lr, _a);
                draw_line_width(_x1, _y1, _x2, _y2, 2);
            }
            draw_circle(_cx, _cy, _rad * 0.2, true);
            draw_set_alpha(1);
        }
        if (_sp == SP_LIGHTNING) {
            // Yellow zigzag bolt
            draw_set_color(make_color_rgb(255, 255, 100));
            draw_set_alpha(_alpha * 0.95);
            var _bh = _rad * 0.8;
            draw_line_width(_cx - _rad * 0.15, _cy - _bh, _cx + _rad * 0.1, _cy - _bh * 0.3, 2.5);
            draw_line_width(_cx + _rad * 0.1, _cy - _bh * 0.3, _cx - _rad * 0.15, _cy + _bh * 0.1, 2.5);
            draw_line_width(_cx - _rad * 0.15, _cy + _bh * 0.1, _cx + _rad * 0.1, _cy + _bh, 2.5);
            draw_set_alpha(1);
        }
        if (_sp == SP_MULT) {
            // "2x" text
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_color(c_white);
            draw_set_alpha(_alpha);
            draw_text_transformed(_cx, _cy, "2x", _font_s * 0.7, _font_s * 0.7, 0);
            draw_set_alpha(1);
        }
        if (_sp == SP_CASCADE) {
            // Small outward arrows (4 dots)
            draw_set_color(make_color_rgb(100, 255, 150));
            draw_set_alpha(_alpha * 0.9);
            var _d = _rad * 0.5;
            draw_circle(_cx + _d, _cy, 2, false);
            draw_circle(_cx - _d, _cy, 2, false);
            draw_circle(_cx, _cy + _d, 2, false);
            draw_circle(_cx, _cy - _d, 2, false);
            draw_set_alpha(1);
        }

        // Selection highlight
        if (_c == sel_col && _r == sel_row) {
            draw_set_color(c_white);
            draw_set_alpha(0.5 + sin(current_time * 0.005) * 0.3);
            draw_circle(_cx, _cy, _rad + 3, true);
            draw_circle(_cx, _cy, _rad + 4, true);
            draw_set_alpha(1);
        }
    }
}

// ===================== SWAP ANIM =====================
if (anim_state == 1 || anim_state == 5) {
    var _p = swap_progress;
    var _fc1, _fr1, _fc2, _fr2;
    if (anim_state == 1) { _fc1 = swap_c1; _fr1 = swap_r1; _fc2 = swap_c2; _fr2 = swap_r2; }
    else { _fc1 = swap_c2; _fr1 = swap_r2; _fc2 = swap_c1; _fr2 = swap_r1; }

    var _x1 = grid_x + lerp(_fc1, _fc2, _p) * cell_size + cell_size * 0.5;
    var _y1 = grid_y + lerp(_fr1, _fr2, _p) * cell_size + cell_size * 0.5;
    var _g1 = grid[swap_c1][swap_r1];
    if (_g1 >= 0) draw_sprite_ext(gem_sprites[_g1], 0, _x1, _y1, _spr_scale, _spr_scale, 0, c_white, 1);

    var _x2 = grid_x + lerp(_fc2, _fc1, _p) * cell_size + cell_size * 0.5;
    var _y2 = grid_y + lerp(_fr2, _fr1, _p) * cell_size + cell_size * 0.5;
    var _g2 = grid[swap_c2][swap_r2];
    if (_g2 >= 0) draw_sprite_ext(gem_sprites[_g2], 0, _x2, _y2, _spr_scale, _spr_scale, 0, c_white, 1);
}

// Remove shake offset
grid_x -= _sx;
grid_y -= _sy;

// ===================== FX EFFECTS =====================
for (var _fi = 0; _fi < array_length(fx); _fi++) {
    var _f = fx[_fi];
    var _prog = _f.t / _f.mt;
    var _fxx = _f.x + _sx;
    var _fxy = _f.y + _sy;

    if (_f.type == FX_RING) {
        var _r = _f.sz * _prog;
        var _a = (1 - _prog) * 0.7;
        var _thick = max(3, cell_size * 0.12 * (1 - _prog));
        draw_set_color(_f.clr);
        draw_set_alpha(_a);
        draw_circle(_fxx, _fxy, _r, true);
        draw_circle(_fxx, _fxy, max(_r - _thick, 1), true);
        draw_circle(_fxx, _fxy, max(_r - _thick * 2, 1), true);
        draw_set_alpha(_a * 0.3);
        draw_circle(_fxx, _fxy, _r * 0.4, false);
    }

    if (_f.type == FX_HFLASH) {
        var _a = (1 - _prog) * 0.85;
        var _thick = cell_size * 0.7 * (1 - _prog * 0.6);
        draw_set_color(_f.clr);
        draw_set_alpha(_a);
        draw_rectangle(grid_x + _sx, _fxy - _thick * 0.5, grid_x + _sx + GF_COLS * cell_size, _fxy + _thick * 0.5, false);
        draw_set_color(c_white);
        draw_set_alpha(_a * 0.6);
        draw_rectangle(grid_x + _sx, _fxy - _thick * 0.15, grid_x + _sx + GF_COLS * cell_size, _fxy + _thick * 0.15, false);
    }

    if (_f.type == FX_SPARKLE) {
        var _a = (1 - _prog);
        var _dist = _f.sz * 2.5 * _prog;
        draw_set_color(_f.clr);
        draw_set_alpha(_a);
        for (var _angle = 0; _angle < 360; _angle += 45) {
            var _dx = lengthdir_x(_dist, _angle + _f.t * 4);
            var _dy = lengthdir_y(_dist, _angle + _f.t * 4);
            var _dot_r = max(2, 4 * (1 - _prog));
            draw_circle(_fxx + _dx, _fxy + _dy, _dot_r, false);
        }
    }

    if (_f.type == FX_POP) {
        var _r = _f.sz * (0.3 + _prog * 1.2);
        var _a = (1 - _prog) * 0.6;
        draw_set_color(_f.clr);
        draw_set_alpha(_a);
        draw_circle(_fxx, _fxy, _r, true);
        draw_circle(_fxx, _fxy, max(_r - 2, 1), true);
    }
}
draw_set_alpha(1);

// ===================== ACTIVE MODS =====================
var _mod_y = grid_y + GF_ROWS * cell_size + cell_size * 0.4;
var _mod_s = max(cell_size * 0.35, 12);

if (array_length(active_mods) > 0) {
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(120, 120, 140));
    draw_text_transformed(grid_x, _mod_y, "Modifiers:", _font_s * 0.7, _font_s * 0.7, 0);
    _mod_y += _font_s * 14;

    // Check which mods have been picked
    var _picked = array_create(array_length(mod_defs), false);
    for (var _i = 0; _i < array_length(active_mods); _i++)
        _picked[active_mods[_i]] = true;

    // Remaining gem counts per mod type
    var _remaining = [mod_bomb_count, mod_lightning_count, mod_mult_count, mod_cascade_count, mod_extra_moves];

    var _mx = grid_x;
    for (var _i = 0; _i < array_length(mod_defs); _i++) {
        if (_picked[_i]) {
            var _dim = (_i < 4 && _remaining[_i] <= 0) ? 0.35 : 1.0;
            draw_set_alpha(_dim);
            draw_set_color(mod_icon_colors[_i]);
            draw_circle(_mx + _mod_s * 0.5, _mod_y + _mod_s * 0.5, _mod_s * 0.5, false);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_color(c_white);
            var _label;
            if (_i < 4)
                _label = string(_remaining[_i]);
            else
                _label = "+" + string(_remaining[_i]);
            draw_text_transformed(_mx + _mod_s * 0.5, _mod_y + _mod_s * 0.5, _label, _font_s * 0.5, _font_s * 0.5, 0);
            draw_set_alpha(1);
            _mx += _mod_s + 6;
        }
    }
}

// ===================== POPUPS =====================
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
for (var _i = 0; _i < array_length(popups); _i++) {
    var _pp = popups[_i];
    var _a = clamp(_pp.t / 20, 0, 1);
    draw_set_alpha(_a);
    draw_set_color(c_black);
    draw_text_transformed(_pp.x + _sx + 1, _pp.y + _sy + 1, _pp.txt, _font_s, _font_s, 0);
    draw_set_color(_pp.clr);
    draw_text_transformed(_pp.x + _sx, _pp.y + _sy, _pp.txt, _font_s, _font_s, 0);
}
draw_set_alpha(1);

if (combo_timer > 0) {
    draw_set_alpha(clamp(combo_timer / 15, 0, 1));
    draw_set_color(make_color_rgb(255, 200, 50));
    draw_text_transformed(scr_w * 0.5 + _sx, grid_y + GF_ROWS * cell_size * 0.5 + _sy, combo_text, _font_s * 2, _font_s * 2, 0);
    draw_set_alpha(1);
}

if (round_msg_timer > 0) {
    draw_set_alpha(clamp(round_msg_timer / 15, 0, 1) * 0.85);
    draw_set_color(make_color_rgb(46, 204, 113));
    draw_text_transformed(scr_w * 0.5, grid_y - cell_size * 0.5, round_msg, _font_s * 1.5, _font_s * 1.5, 0);
    draw_set_alpha(1);
}

// ===================== CELEBRATION =====================
if (game_state == 5) {
    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_rectangle(0, 0, scr_w, scr_h, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(46, 204, 113));
    draw_text_transformed(scr_w * 0.5, scr_h * 0.35, "Round Complete!", _font_s * 2, _font_s * 2, 0);
    draw_set_color(make_color_rgb(241, 196, 15));
    draw_text_transformed(scr_w * 0.5, scr_h * 0.45, "Score: " + string(round_score) + " / " + string(target_score), _font_s * 1.2, _font_s * 1.2, 0);

    if (round_msg_timer <= 0) {
        var _pulse = 0.5 + sin(current_time * 0.004) * 0.3;
        draw_set_alpha(_pulse);
        draw_set_color(make_color_rgb(180, 180, 200));
        draw_text_transformed(scr_w * 0.5, scr_h * 0.58, "Tap to continue", _font_s * 1.0, _font_s * 1.0, 0);
        draw_set_alpha(1);
    }

    // Draw confetti
    for (var _ci = 0; _ci < array_length(confetti); _ci++) {
        var _cf = confetti[_ci];
        var _ca = clamp(_cf.life / 30, 0, 1);
        draw_set_alpha(_ca);
        draw_set_color(_cf.clr);
        var _csz = _cf.sz;
        var _rx = _cf.x;
        var _ry = _cf.y;
        var _rot = _cf.rot;
        // Draw rotated rectangle confetti
        var _x1 = _rx + lengthdir_x(_csz, _rot) - lengthdir_x(_csz * 0.4, _rot + 90);
        var _y1 = _ry + lengthdir_y(_csz, _rot) - lengthdir_y(_csz * 0.4, _rot + 90);
        var _x2 = _rx + lengthdir_x(_csz, _rot) + lengthdir_x(_csz * 0.4, _rot + 90);
        var _y2 = _ry + lengthdir_y(_csz, _rot) + lengthdir_y(_csz * 0.4, _rot + 90);
        var _x3 = _rx - lengthdir_x(_csz, _rot) + lengthdir_x(_csz * 0.4, _rot + 90);
        var _y3 = _ry - lengthdir_y(_csz, _rot) + lengthdir_y(_csz * 0.4, _rot + 90);
        var _x4 = _rx - lengthdir_x(_csz, _rot) - lengthdir_x(_csz * 0.4, _rot + 90);
        var _y4 = _ry - lengthdir_y(_csz, _rot) - lengthdir_y(_csz * 0.4, _rot + 90);
        draw_triangle(_x1, _y1, _x2, _y2, _x3, _y3, false);
        draw_triangle(_x1, _y1, _x3, _y3, _x4, _y4, false);
    }
    draw_set_alpha(1);
}

// ===================== CARD SELECTION =====================
if (game_state == 3 || game_state == 6) {
    draw_set_alpha(0.8);
    draw_set_color(c_black);
    draw_rectangle(0, 0, scr_w, scr_h, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    if (game_state == 6)
        draw_set_color(make_color_rgb(46, 204, 113));
    else
        draw_set_color(make_color_rgb(241, 196, 15));
    draw_text_transformed(scr_w * 0.5, scr_h * 0.18, game_state == 6 ? "Modifier Selected!" : "Choose a Modifier", _font_s * 1.6, _font_s * 1.6, 0);

    var _card_w = scr_w * 0.85;
    var _card_h = cell_size * 1.4;
    var _gap = cell_size * 0.3;
    var _total_h = 3 * _card_h + 2 * _gap;
    var _start_y = (scr_h - _total_h) * 0.5;
    var _cx = (scr_w - _card_w) * 0.5;

    for (var _i = 0; _i < array_length(card_options); _i++) {
        var _mid = card_options[_i];
        var _cy = _start_y + _i * (_card_h + _gap);
        var _is_sel = (game_state == 6 && _i == selected_card);

        // Calculate what this pick would give
        var _stacks = 0;
        for (var _j = 0; _j < array_length(active_mods); _j++)
            if (active_mods[_j] == _mid) _stacks++;
        var _offer = get_mod_count(_mid, _stacks);

        if (game_state == 6 && !_is_sel) {
            // Dim non-selected cards
            draw_set_alpha(0.25);
            draw_set_color(make_color_rgb(35, 35, 55));
            draw_roundrect(_cx, _cy, _cx + _card_w, _cy + _card_h, false);
            draw_set_alpha(1);
            continue;
        }

        // Glow effect for selected card
        if (_is_sel) {
            var _glow = 0.5 + sin(current_time * 0.008) * 0.4;
            draw_set_alpha(_glow);
            draw_set_color(mod_icon_colors[_mid]);
            draw_roundrect(_cx - 6, _cy - 6, _cx + _card_w + 6, _cy + _card_h + 6, false);
            draw_set_alpha(1);
        }

        draw_set_color(_is_sel ? make_color_rgb(55, 55, 85) : make_color_rgb(45, 45, 70));
        draw_roundrect(_cx, _cy, _cx + _card_w, _cy + _card_h, false);
        draw_set_color(mod_icon_colors[_mid]);
        draw_roundrect(_cx, _cy, _cx + _card_w, _cy + _card_h, true);

        draw_set_color(mod_icon_colors[_mid]);
        draw_circle(_cx + _card_h * 0.5, _cy + _card_h * 0.5, _card_h * 0.3, false);

        draw_set_halign(fa_left);
        draw_set_color(c_white);
        draw_text_transformed(_cx + _card_h, _cy + _card_h * 0.35, mod_defs[_mid][0], _font_s * 1.1, _font_s * 1.1, 0);
        draw_set_color(make_color_rgb(180, 180, 200));
        var _desc;
        if (_mid < 4)
            _desc = string(_offer) + " " + mod_defs[_mid][1];
        else
            _desc = "+" + string(_offer) + " " + mod_defs[_mid][1];
        draw_text_transformed(_cx + _card_h, _cy + _card_h * 0.7, _desc, _font_s * 0.8, _font_s * 0.8, 0);
    }
}

// ===================== GAME OVER =====================
if (game_state == 4) {
    draw_set_alpha(0.85);
    draw_set_color(c_black);
    draw_rectangle(0, 0, scr_w, scr_h, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_set_color(make_color_rgb(231, 76, 60));
    draw_text_transformed(scr_w * 0.5, scr_h * 0.28, "Game Over", _font_s * 2.2, _font_s * 2.2, 0);
    draw_set_color(c_white);
    draw_text_transformed(scr_w * 0.5, scr_h * 0.40, "Round " + string(round_num), _font_s * 1.3, _font_s * 1.3, 0);
    draw_set_color(make_color_rgb(241, 196, 15));
    draw_text_transformed(scr_w * 0.5, scr_h * 0.48, "Score: " + string(points), _font_s * 1.8, _font_s * 1.8, 0);
    draw_set_color(make_color_rgb(150, 150, 170));
    draw_text_transformed(scr_w * 0.5, scr_h * 0.56, string(round_score) + " / " + string(target_score) + " needed", _font_s * 0.9, _font_s * 0.9, 0);

    var _btn_w = scr_w * 0.5;
    var _btn_h = cell_size * 1.0;
    var _bx = (scr_w - _btn_w) * 0.5;
    var _by = scr_h * 0.65;
    draw_set_color(make_color_rgb(46, 204, 113));
    draw_roundrect(_bx, _by, _bx + _btn_w, _by + _btn_h, false);
    draw_set_color(c_white);
    draw_text_transformed(scr_w * 0.5, _by + _btn_h * 0.5, "Play Again", _font_s * 1.2, _font_s * 1.2, 0);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);
draw_set_color(c_white);
