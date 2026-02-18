// ========================================
// RICOCHET — Draw_64.gml
// ========================================

if (game_state == 0) {
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.5, "Loading...", 0, scr_w, 2, 2, 0);
    exit;
}

var _sx = shake_x;
var _sy = shake_y;

// --- Background ---
draw_set_colour(bg_color);
draw_rectangle(0, 0, scr_w, scr_h, false);

// --- Play area border ---
var _bclr = make_color_rgb(40, 40, 65);
draw_set_colour(_bclr);
draw_rectangle(play_x1 + _sx, play_y1 + _sy, play_x2 + _sx, play_y2 + _sy, true);
draw_rectangle(play_x1 + 1 + _sx, play_y1 + 1 + _sy, play_x2 - 1 + _sx, play_y2 - 1 + _sy, true);

// --- Obstacles ---
draw_set_colour(make_color_rgb(80, 80, 110));
for (var _i = 0; _i < array_length(obstacles); _i++) {
    var _o = obstacles[_i];
    // Draw thick line (3 lines offset)
    for (var _d = -1; _d <= 1; _d++) {
        draw_line(_o.x1 + _sx, _o.y1 + _sy + _d, _o.x2 + _sx, _o.y2 + _sy + _d);
        draw_line(_o.x1 + _sx + _d, _o.y1 + _sy, _o.x2 + _sx + _d, _o.y2 + _sy);
    }
}

// --- Targets ---
for (var _i = 0; _i < array_length(targets); _i++) {
    var _t = targets[_i];
    if (_t.hit) continue;

    var _tx = _t.x + _sx;
    var _ty = _t.y + _sy;
    var _r = _t.r;
    var _pulse_add = _t.pulse * 6;

    // Glow ring
    draw_set_alpha(0.3 + _t.pulse * 0.3);
    draw_set_colour(_t.clr);
    draw_circle(_tx, _ty, _r + 4 + _pulse_add, false);

    // Main circle
    draw_set_alpha(1);
    draw_set_colour(merge_colour(_t.clr, c_black, 0.2));
    draw_circle(_tx, _ty, _r, false);

    // Inner highlight
    draw_set_colour(_t.clr);
    draw_circle(_tx, _ty, _r * 0.7, false);

    // Center dot
    draw_set_colour(c_white);
    draw_set_alpha(0.6);
    draw_circle(_tx - _r * 0.2, _ty - _r * 0.2, _r * 0.2, false);
    draw_set_alpha(1);
}

// --- Hit target ghosts ---
for (var _i = 0; _i < array_length(targets); _i++) {
    var _t = targets[_i];
    if (!_t.hit) continue;
    var _tx = _t.x + _sx;
    var _ty = _t.y + _sy;
    draw_set_alpha(0.15);
    draw_set_colour(_t.clr);
    draw_circle(_tx, _ty, _t.r, true);
    draw_set_alpha(1);
}

// --- Aim preview (during aiming) ---
if (game_state == 1 && aim_active) {
    var _dx = aim_sx - device_mouse_x_to_gui(0);
    var _dy = aim_sy - device_mouse_y_to_gui(0);
    var _dist = sqrt(_dx * _dx + _dy * _dy);
    if (_dist > 5) {
        var _angle = point_direction(0, 0, _dx, _dy);
        var _path = get_preview_path(_angle, RC_PREVIEW_BOUNCES);

        // Draw dotted preview line
        for (var _j = 0; _j < array_length(_path) - 1; _j++) {
            var _alpha = 1 - (_j / max(array_length(_path) - 1, 1)) * 0.7;
            draw_set_alpha(_alpha);
            draw_set_colour(c_white);

            var _x1 = _path[_j][0] + _sx;
            var _y1 = _path[_j][1] + _sy;
            var _x2 = _path[_j + 1][0] + _sx;
            var _y2 = _path[_j + 1][1] + _sy;

            // Dashed line
            var _seg_dx = _x2 - _x1;
            var _seg_dy = _y2 - _y1;
            var _seg_len = sqrt(_seg_dx * _seg_dx + _seg_dy * _seg_dy);
            var _dash = 8;
            var _gap = 6;
            var _steps = floor(_seg_len / (_dash + _gap));
            var _ux = _seg_dx / max(_seg_len, 1);
            var _uy = _seg_dy / max(_seg_len, 1);
            for (var _s = 0; _s < _steps; _s++) {
                var _sx2 = _x1 + _ux * _s * (_dash + _gap);
                var _sy2 = _y1 + _uy * _s * (_dash + _gap);
                draw_line(_sx2, _sy2, _sx2 + _ux * _dash, _sy2 + _uy * _dash);
            }
        }

        // Bounce dots
        for (var _j = 1; _j < array_length(_path) - 1; _j++) {
            draw_set_alpha(0.8);
            draw_set_colour(c_yellow);
            draw_circle(_path[_j][0] + _sx, _path[_j][1] + _sy, 3, false);
        }
        draw_set_alpha(1);
    }
}

// --- Ball trail ---
if (ball_active) {
    for (var _i = 0; _i < array_length(ball_trail); _i++) {
        var _frac = _i / max(array_length(ball_trail), 1);
        draw_set_alpha(_frac * 0.5);
        draw_set_colour(ball_color);
        var _tr = RC_BALL_RADIUS * _frac * 0.6;
        draw_circle(ball_trail[_i][0] + _sx, ball_trail[_i][1] + _sy, _tr, false);
    }
    draw_set_alpha(1);
}

// --- Ball ---
if (game_state == 1 || game_state == 2) {
    var _bx = ball_x + _sx;
    var _by = ball_y + _sy;

    // Outer glow
    draw_set_alpha(0.3);
    draw_set_colour(c_white);
    draw_circle(_bx, _by, RC_BALL_RADIUS + 3, false);

    // Main ball
    draw_set_alpha(1);
    draw_set_colour(ball_color);
    draw_circle(_bx, _by, RC_BALL_RADIUS, false);

    // Highlight
    draw_set_colour(c_white);
    draw_set_alpha(0.5);
    draw_circle(_bx - 2, _by - 2, RC_BALL_RADIUS * 0.4, false);
    draw_set_alpha(1);
}

// --- FX (expanding rings) ---
for (var _i = 0; _i < array_length(fx); _i++) {
    var _f = fx[_i];
    var _prog = _f.t / _f.mt;
    var _r = _f.sz * _prog;
    draw_set_alpha((1 - _prog) * 0.6);
    draw_set_colour(_f.clr);
    draw_circle(_f.x + _sx, _f.y + _sy, _r, true);
    draw_circle(_f.x + _sx, _f.y + _sy, _r * 0.8, true);
}
draw_set_alpha(1);

// --- HUD ---
var _hud_y = play_y1 * 0.5;
var _font_scale = max(scr_w / 500, 1.2);

// Score (left)
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour(c_white);
draw_text_ext_transformed(play_x1 + 8, _hud_y, string(points), 0, scr_w, _font_scale * 1.4, _font_scale * 1.4, 0);

// Round (center)
draw_set_halign(fa_center);
draw_set_colour(make_color_rgb(150, 150, 180));
draw_text_ext_transformed(scr_w * 0.5, _hud_y, "Round " + string(round_num), 0, scr_w, _font_scale, _font_scale, 0);

// Shots left (right) — draw as dots
draw_set_halign(fa_right);
var _dot_r = max(5 * _font_scale * 0.5, 4);
var _dot_spacing = _dot_r * 3;
var _dots_x = play_x2 - 8;
for (var _i = 0; _i < 3; _i++) {
    var _dx2 = _dots_x - _i * _dot_spacing;
    if (_i < shots_left) {
        draw_set_colour(c_white);
        draw_circle(_dx2, _hud_y, _dot_r, false);
    } else {
        draw_set_colour(make_color_rgb(60, 60, 80));
        draw_circle(_dx2, _hud_y, _dot_r, true);
    }
}

// Targets remaining (below round)
var _remaining = 0;
for (var _i = 0; _i < array_length(targets); _i++) {
    if (!targets[_i].hit) _remaining++;
}
draw_set_halign(fa_center);
draw_set_colour(make_color_rgb(100, 100, 130));
draw_text_ext_transformed(scr_w * 0.5, _hud_y + 16 * _font_scale, string(_remaining) + " left", 0, scr_w, _font_scale * 0.7, _font_scale * 0.7, 0);

// --- Popups ---
for (var _i = 0; _i < array_length(popups); _i++) {
    var _p = popups[_i];
    var _alpha = clamp(_p.t / 15, 0, 1);
    draw_set_alpha(_alpha);
    draw_set_colour(_p.clr);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _ps = max(_font_scale * 1.1, 1.3);
    draw_text_ext_transformed(_p.x + _sx, _p.y + _sy, _p.txt, 0, scr_w, _ps, _ps, 0);
}
draw_set_alpha(1);

// --- Combo text ---
if (combo_text != "" && combo_timer > 0) {
    var _ca = clamp(combo_timer / 10, 0, 1);
    draw_set_alpha(_ca);
    draw_set_colour(c_yellow);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _cs = _font_scale * 1.8;
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.15, combo_text, 0, scr_w, _cs, _cs, 0);
    draw_set_alpha(1);
}

// --- Round message ---
if (round_msg != "" && round_msg_timer > 0) {
    var _ra = clamp(round_msg_timer / 15, 0, 1);
    draw_set_alpha(_ra * 0.9);
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _rs = _font_scale * 2.2;
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.4, round_msg, 0, scr_w, _rs, _rs, 0);
    draw_set_alpha(1);
}

// =========================================
// ROUND COMPLETE OVERLAY
// =========================================
if (game_state == 3) {
    // Dark overlay
    draw_set_alpha(0.5);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, scr_w, scr_h, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // "Round Clear!"
    draw_set_colour(make_color_rgb(46, 204, 113));
    var _ts = _font_scale * 2.5;
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.38, "Round Clear!", 0, scr_w, _ts, _ts, 0);

    // Score
    draw_set_colour(c_white);
    var _ts2 = _font_scale * 1.5;
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.48, "Score: " + string(points), 0, scr_w, _ts2, _ts2, 0);

    // "Tap to continue"
    var _pulse = 0.5 + sin(current_time * 0.005) * 0.5;
    draw_set_alpha(_pulse);
    draw_set_colour(c_white);
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.6, "Tap to continue", 0, scr_w, _font_scale, _font_scale, 0);
    draw_set_alpha(1);
}

// =========================================
// GAME OVER OVERLAY
// =========================================
if (game_state == 4) {
    // Dark overlay
    draw_set_alpha(0.6);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, scr_w, scr_h, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // "Game Over"
    draw_set_colour(make_color_rgb(231, 76, 60));
    var _ts = _font_scale * 2.5;
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.32, "Game Over", 0, scr_w, _ts, _ts, 0);

    // Final score
    draw_set_colour(c_white);
    var _ts2 = _font_scale * 1.8;
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.43, string(points), 0, scr_w, _ts2, _ts2, 0);

    // Round reached
    draw_set_colour(make_color_rgb(150, 150, 180));
    var _ts3 = _font_scale * 1.0;
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.52, "Round " + string(round_num), 0, scr_w, _ts3, _ts3, 0);

    // "Tap to play again"
    var _pulse = 0.5 + sin(current_time * 0.005) * 0.5;
    draw_set_alpha(_pulse);
    draw_set_colour(c_white);
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.65, "Tap to play again", 0, scr_w, _font_scale, _font_scale, 0);
    draw_set_alpha(1);
}

// --- Aim hint (when idle in aiming state) ---
if (game_state == 1 && !aim_active && round_msg_timer <= 0) {
    var _pulse = 0.3 + sin(current_time * 0.004) * 0.2;
    draw_set_alpha(_pulse);
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(ball_start_x, ball_start_y + RC_BALL_RADIUS * 4, "Drag to aim", 0, scr_w, _font_scale * 0.9, _font_scale * 0.9, 0);
    draw_set_alpha(1);
}

// Reset draw state
draw_set_alpha(1);
draw_set_colour(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
