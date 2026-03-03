
var _ww = ww;
var _hh = hh;
if (_ww <= 0 || _hh <= 0) exit;

// Background — space
draw_set_colour(col_space);
draw_rectangle(0, 0, _ww, _hh, false);

// ========== TITLE SCREEN ==========
if (game_state == 1) {
    // Draw ship silhouette in background
    draw_set_alpha(0.3);
    draw_set_colour(col_wall);
    draw_rectangle(_ww * 0.2, _hh * 0.3, _ww * 0.8, _hh * 0.7, false);
    draw_set_alpha(1.0);

    // Title
    var _scale = min(_ww, _hh) * 0.005;
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_default);

    // "SPOT THE IMPOSTOR" with pulse
    var _pulse = 0.8 + sin(title_pulse) * 0.2;
    var _ts = _scale * _pulse;

    draw_set_colour(col_danger);
    draw_text_ext_transformed(_ww * 0.5 + 2, _hh * 0.28 + 2, "SPOT THE", 0, _ww, _ts * 0.8, _ts * 0.8, 0);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_ww * 0.5, _hh * 0.28, "SPOT THE", 0, _ww, _ts * 0.8, _ts * 0.8, 0);

    draw_set_colour(col_danger);
    draw_text_ext_transformed(_ww * 0.5 + 2, _hh * 0.42 + 2, "IMPOSTOR", 0, _ww, _ts * 1.2, _ts * 1.2, 0);
    draw_set_colour(make_colour_rgb(255, 50, 50));
    draw_text_ext_transformed(_ww * 0.5, _hh * 0.42, "IMPOSTOR", 0, _ww, _ts * 1.2, _ts * 1.2, 0);

    // Round info
    var _info_scale = _scale * 0.5;
    draw_set_colour(c_white);
    draw_text_ext_transformed(_ww * 0.5, _hh * 0.56, "Round " + string(round_num), 0, _ww, _info_scale, _info_scale, 0);

    // Draw crewmate icons
    var _icon_r = min(_ww, _hh) * 0.03;
    var _icon_y = _hh * 0.65;
    var _cc = min(4 + ((round_num - 1) div 3), crew_max);
    var _total_w = _cc * _icon_r * 3;
    var _start_x = _ww * 0.5 - _total_w * 0.5 + _icon_r * 1.5;
    for (var _i = 0; _i < _cc; _i++) {
        var _cx = _start_x + _i * _icon_r * 3;
        // Body
        draw_set_colour(crew_palette[_i]);
        draw_circle(_cx, _icon_y, _icon_r, false);
        // Visor
        draw_set_colour(col_visor);
        draw_circle(_cx + _icon_r * 0.3, _icon_y - _icon_r * 0.15, _icon_r * 0.35, false);
    }

    // Lives and score
    draw_set_colour(c_ltgray);
    draw_text_ext_transformed(_ww * 0.5, _hh * 0.76, "Lives: " + string(lives) + "  Score: " + string(points), 0, _ww, _info_scale * 0.8, _info_scale * 0.8, 0);

    // Tap to start
    draw_set_colour(c_yellow);
    var _blink = (floor(title_pulse * 2) mod 2 == 0);
    if (_blink) {
        draw_text_ext_transformed(_ww * 0.5, _hh * 0.88, "TAP TO START", 0, _ww, _info_scale * 0.7, _info_scale * 0.7, 0);
    }
    exit;
}

// ========== GAME OVER ==========
if (game_state == 5) {
    var _scale = min(_ww, _hh) * 0.005;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_default);

    // Dead crewmate
    var _dead_r = min(_ww, _hh) * 0.08;
    draw_set_colour(crew_palette[0]);
    draw_circle(_ww * 0.5, _hh * 0.32, _dead_r, false);
    draw_set_colour(col_visor);
    draw_circle(_ww * 0.5 + _dead_r * 0.3, _hh * 0.32 - _dead_r * 0.15, _dead_r * 0.35, false);
    // X eyes
    draw_set_colour(c_red);
    var _ex = _ww * 0.5 + _dead_r * 0.3;
    var _ey = _hh * 0.32 - _dead_r * 0.15;
    var _es = _dead_r * 0.15;
    draw_line_width(_ex - _es, _ey - _es, _ex + _es, _ey + _es, 2);
    draw_line_width(_ex + _es, _ey - _es, _ex - _es, _ey + _es, 2);

    draw_set_colour(col_danger);
    draw_text_ext_transformed(_ww * 0.5, _hh * 0.50, "GAME OVER", 0, _ww, _scale * 1.2, _scale * 1.2, 0);

    draw_set_colour(c_white);
    draw_text_ext_transformed(_ww * 0.5, _hh * 0.62, "Final Score: " + string(points), 0, _ww, _scale * 0.6, _scale * 0.6, 0);
    draw_text_ext_transformed(_ww * 0.5, _hh * 0.70, "Rounds Survived: " + string(round_num - 1), 0, _ww, _scale * 0.5, _scale * 0.5, 0);

    draw_set_colour(c_yellow);
    draw_text_ext_transformed(_ww * 0.5, _hh * 0.85, "TAP TO RETRY", 0, _ww, _scale * 0.5, _scale * 0.5, 0);
    exit;
}

// ========== DRAW MAP (shared by playing/meeting/result states) ==========

// Draw corridors first (behind rooms)
draw_set_colour(col_corridor);
var _corr_w = min(play_w, play_h) * 0.04;
for (var _c = 0; _c < corridor_count; _c++) {
    var _ra = corr_a[_c];
    var _rb = corr_b[_c];
    // Center of each room
    var _ax = play_ox + (room_nx[_ra] + room_nw[_ra] * 0.5) * play_w;
    var _ay = play_oy + (room_ny[_ra] + room_nh[_ra] * 0.5) * play_h;
    var _bx = play_ox + (room_nx[_rb] + room_nw[_rb] * 0.5) * play_w;
    var _by = play_oy + (room_ny[_rb] + room_nh[_rb] * 0.5) * play_h;
    // Draw thick line as corridor
    draw_line_width(_ax, _ay, _bx, _by, _corr_w);
}

// Draw rooms
for (var _r = 0; _r < room_count; _r++) {
    var _rx = play_ox + room_nx[_r] * play_w;
    var _ry = play_oy + room_ny[_r] * play_h;
    var _rw = room_nw[_r] * play_w;
    var _rh = room_nh[_r] * play_h;

    // Wall (border)
    draw_set_colour(col_wall);
    draw_rectangle(_rx - 2, _ry - 2, _rx + _rw + 2, _ry + _rh + 2, false);
    // Floor
    draw_set_colour(col_floor);
    draw_rectangle(_rx, _ry, _rx + _rw, _ry + _rh, false);

    // Room name
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_font(fnt_default);
    draw_set_colour(make_colour_rgb(150, 160, 180));
    var _name_scale = min(_rw, _rh) * 0.006;
    _name_scale = max(0.4, min(_name_scale, 0.8));
    draw_text_ext_transformed(_rx + _rw * 0.5, _ry + 3, room_name[_r], 0, _rw, _name_scale, _name_scale, 0);
}

// Draw vents
for (var _v = 0; _v < vent_count; _v++) {
    var _vr = vent_room[_v];
    var _vrx = play_ox + room_nx[_vr] * play_w;
    var _vry = play_oy + room_ny[_vr] * play_h;
    var _vrw = room_nw[_vr] * play_w;
    var _vrh = room_nh[_vr] * play_h;
    var _vx = _vrx + vent_lx[_v] * _vrw;
    var _vy = _vry + vent_ly[_v] * _vrh;
    var _vs = min(play_w, play_h) * 0.018;

    draw_set_colour(col_vent);
    draw_rectangle(_vx - _vs, _vy - _vs * 0.6, _vx + _vs, _vy + _vs * 0.6, false);
    // Grate lines
    draw_set_colour(make_colour_rgb(40, 40, 40));
    for (var _g = -1; _g <= 1; _g++) {
        draw_line_width(_vx - _vs * 0.8, _vy + _g * _vs * 0.25, _vx + _vs * 0.8, _vy + _g * _vs * 0.25, 1);
    }
}

// Draw task stations
for (var _t = 0; _t < task_count; _t++) {
    var _tr = task_room[_t];
    var _trx = play_ox + room_nx[_tr] * play_w;
    var _try2 = play_oy + room_ny[_tr] * play_h;
    var _trw = room_nw[_tr] * play_w;
    var _trh = room_nh[_tr] * play_h;
    var _tx = _trx + task_lx[_t] * _trw;
    var _ty = _try2 + task_ly[_t] * _trh;
    var _ts = min(play_w, play_h) * 0.012;

    draw_set_colour(col_task);
    draw_rectangle(_tx - _ts, _ty - _ts, _tx + _ts, _ty + _ts, false);
    // Outline
    draw_set_colour(make_colour_rgb(200, 180, 50));
    draw_rectangle(_tx - _ts, _ty - _ts, _tx + _ts, _ty + _ts, true);
}

// Draw crewmates
var _crew_r = min(play_w, play_h) * 0.025;
for (var _i = 0; _i < crew_count; _i++) {
    if (!crew_alive[_i]) continue;

    var _cx = crew_x[_i];
    var _cy = crew_y[_i];

    // Walking bobble
    var _bob = 0;
    if (crew_ai[_i] == "walking" || crew_ai[_i] == "stalking") {
        _bob = sin(crew_bobble[_i]) * _crew_r * 0.15;
    }

    // Body (bean shape — circle + small rectangle bottom)
    draw_set_colour(crew_palette[_i]);
    draw_circle(_cx, _cy - _crew_r * 0.2 + _bob, _crew_r, false);
    draw_roundrect(_cx - _crew_r * 0.7, _cy + _bob, _cx + _crew_r * 0.7, _cy + _crew_r * 0.8 + _bob, false);

    // Backpack bump
    draw_set_colour(merge_colour(crew_palette[_i], c_black, 0.2));
    draw_circle(_cx - _crew_r * 0.85, _cy - _crew_r * 0.1 + _bob, _crew_r * 0.3, false);

    // Visor
    draw_set_colour(col_visor);
    draw_ellipse(_cx + _crew_r * 0.05, _cy - _crew_r * 0.55 + _bob, _cx + _crew_r * 0.7, _cy + _crew_r * 0.05 + _bob, false);

    // Highlight on visor
    draw_set_colour(make_colour_rgb(200, 240, 255));
    draw_set_alpha(0.4);
    draw_circle(_cx + _crew_r * 0.35, _cy - _crew_r * 0.35 + _bob, _crew_r * 0.1, false);
    draw_set_alpha(1.0);

    // Task progress bar (if tasking or faking)
    if (crew_ai[_i] == "tasking" || crew_ai[_i] == "faking") {
        var _bar_w = _crew_r * 2;
        var _bar_h = _crew_r * 0.3;
        var _bar_x = _cx - _bar_w * 0.5;
        var _bar_y = _cy - _crew_r * 1.5;
        // Background
        draw_set_colour(make_colour_rgb(40, 40, 40));
        draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);
        // Fill
        draw_set_colour(col_safe);
        draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * crew_task_progress[_i], _bar_y + _bar_h, false);
        // Border
        draw_set_colour(c_white);
        draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, true);
    }

    // Vent indicator for impostor (subtle)
    if (crew_ai[_i] == "venting" && _i == impostor_id) {
        // Slight red glow
        draw_set_alpha(0.3);
        draw_set_colour(col_danger);
        draw_circle(_cx, _cy + _bob, _crew_r * 1.5, false);
        draw_set_alpha(1.0);
    }
}

// Kill animation
if (kill_active) {
    var _kill_alpha = kill_timer / 60.0;
    draw_set_alpha(_kill_alpha);
    draw_set_colour(col_danger);
    var _kr = min(play_w, play_h) * 0.05 * (1.0 + (1.0 - _kill_alpha) * 2);
    draw_circle(kill_x, kill_y, _kr, false);
    // "!" text
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_default);
    draw_set_colour(c_white);
    var _ks = min(_ww, _hh) * 0.004;
    draw_text_ext_transformed(kill_x, kill_y, "!", 0, 200, _ks, _ks, 0);
    draw_set_alpha(1.0);
}

// ========== HUD ==========
var _hud_h = _hh * 0.08;

// HUD background
draw_set_colour(make_colour_rgb(20, 20, 40));
draw_rectangle(0, 0, _ww, _hud_h, false);
draw_set_colour(make_colour_rgb(50, 50, 80));
draw_line_width(0, _hud_h, _ww, _hud_h, 2);

draw_set_font(fnt_default);
var _hud_scale = _hud_h * 0.03;
_hud_scale = max(0.4, min(_hud_scale, 1.0));

// Lives (left)
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
var _heart_s = _hud_h * 0.25;
for (var _l = 0; _l < max_lives; _l++) {
    var _hx = 10 + _l * (_heart_s * 2.2);
    var _hy = _hud_h * 0.5;
    if (_l < lives) {
        draw_set_colour(col_danger);
    } else {
        draw_set_colour(make_colour_rgb(60, 30, 30));
    }
    // Simple heart as a circle + triangle
    draw_circle(_hx + _heart_s * 0.3, _hy - _heart_s * 0.15, _heart_s * 0.4, false);
    draw_circle(_hx + _heart_s * 0.7, _hy - _heart_s * 0.15, _heart_s * 0.4, false);
    draw_triangle(_hx, _hy, _hx + _heart_s, _hy, _hx + _heart_s * 0.5, _hy + _heart_s * 0.6, false);
}

// Timer (center)
if (game_state == 2) {
    draw_set_halign(fa_center);
    var _time_left = round_timer / 30.0;
    var _time_col = (_time_left < 5) ? col_danger : c_white;
    draw_set_colour(_time_col);
    var _time_str = string_format(_time_left, 2, 1) + "s";
    draw_text_ext_transformed(_ww * 0.5, _hud_h * 0.5, _time_str, 0, _ww, _hud_scale, _hud_scale, 0);
}

// Score (right)
draw_set_halign(fa_right);
draw_set_colour(c_yellow);
draw_text_ext_transformed(_ww - 10, _hud_h * 0.35, string(points), 0, _ww, _hud_scale, _hud_scale, 0);
draw_set_colour(c_ltgray);
draw_text_ext_transformed(_ww - 10, _hud_h * 0.7, "R" + string(round_num), 0, _ww, _hud_scale * 0.6, _hud_scale * 0.6, 0);

// ========== MEETING OVERLAY ==========
if (game_state == 3) {
    // Red flash
    if (meeting_flash > 0) {
        draw_set_alpha(meeting_flash * 0.6);
        draw_set_colour(col_danger);
        draw_rectangle(0, 0, _ww, _hh, false);
        draw_set_alpha(1.0);
    }

    // Dark overlay
    draw_set_alpha(0.5);
    draw_set_colour(c_black);
    draw_rectangle(0, _hud_h, _ww, _hh, false);
    draw_set_alpha(1.0);

    // EMERGENCY MEETING text
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_default);
    var _em_scale = min(_ww, _hh) * 0.005;
    draw_set_colour(c_red);
    draw_text_ext_transformed(_ww * 0.5 + 2, _hh * 0.35 + 2, "EMERGENCY", 0, _ww, _em_scale, _em_scale, 0);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_ww * 0.5, _hh * 0.35, "EMERGENCY", 0, _ww, _em_scale, _em_scale, 0);

    draw_set_colour(c_red);
    draw_text_ext_transformed(_ww * 0.5 + 2, _hh * 0.48 + 2, "MEETING!", 0, _ww, _em_scale, _em_scale, 0);
    draw_set_colour(c_yellow);
    draw_text_ext_transformed(_ww * 0.5, _hh * 0.48, "MEETING!", 0, _ww, _em_scale, _em_scale, 0);

    // Show accused crewmate
    if (meeting_accused >= 0 && meeting_accused < crew_max) {
        var _ac_r = min(_ww, _hh) * 0.06;
        draw_set_colour(crew_palette[meeting_accused]);
        draw_circle(_ww * 0.5, _hh * 0.65, _ac_r, false);
        draw_set_colour(col_visor);
        draw_ellipse(_ww * 0.5 + _ac_r * 0.05, _hh * 0.65 - _ac_r * 0.55, _ww * 0.5 + _ac_r * 0.7, _hh * 0.65 + _ac_r * 0.05, false);

        // "?" above
        draw_set_colour(c_yellow);
        draw_text_ext_transformed(_ww * 0.5, _hh * 0.65 - _ac_r * 1.5, "?", 0, 100, _em_scale * 0.8, _em_scale * 0.8, 0);
    }
}

// ========== RESULT OVERLAY ==========
if (game_state == 4) {
    // Dark overlay
    draw_set_alpha(0.6);
    draw_set_colour(c_black);
    draw_rectangle(0, _hud_h, _ww, _hh, false);
    draw_set_alpha(1.0);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_default);
    var _r_scale = min(_ww, _hh) * 0.004;

    if (meeting_result == 1) {
        // Correct!
        // Show ejected impostor
        var _ej_r = min(_ww, _hh) * 0.05;
        var _ej_y = _hh * 0.38;
        var _ej_rot = (result_duration - result_timer) * 4;
        draw_set_colour(crew_palette[impostor_id]);
        // Spinning crewmate flying off
        var _ej_x = _ww * 0.5 + (result_duration - result_timer) * _ww * 0.005;
        draw_circle(_ej_x, _ej_y, _ej_r, false);
        draw_set_colour(col_visor);
        draw_circle(_ej_x + _ej_r * 0.3, _ej_y - _ej_r * 0.15, _ej_r * 0.35, false);

        draw_set_colour(col_safe);
        draw_text_ext_transformed(_ww * 0.5, _hh * 0.52, "IMPOSTOR EJECTED!", 0, _ww, _r_scale, _r_scale, 0);

        // Score popup
        if (score_popup_timer > 0) {
            draw_set_colour(c_yellow);
            var _pop_scale = _r_scale * 0.8;
            draw_text_ext_transformed(_ww * 0.5, _hh * 0.62, score_popup, 0, _ww, _pop_scale, _pop_scale, 0);
        }
    } else {
        // Wrong!
        draw_set_colour(col_danger);
        draw_text_ext_transformed(_ww * 0.5, _hh * 0.42, "WRONG!", 0, _ww, _r_scale * 1.2, _r_scale * 1.2, 0);

        draw_set_colour(c_ltgray);
        draw_text_ext_transformed(_ww * 0.5, _hh * 0.55, "That was not the impostor...", 0, _ww, _r_scale * 0.5, _r_scale * 0.5, 0);

        // Show who it actually was
        if (impostor_id >= 0 && impostor_id < crew_max) {
            var _real_r = min(_ww, _hh) * 0.04;
            draw_set_colour(crew_palette[impostor_id]);
            draw_circle(_ww * 0.5, _hh * 0.67, _real_r, false);
            draw_set_colour(col_visor);
            draw_circle(_ww * 0.5 + _real_r * 0.3, _hh * 0.67 - _real_r * 0.15, _real_r * 0.35, false);
            draw_set_colour(c_red);
            var _imp_s = _r_scale * 0.4;
            draw_text_ext_transformed(_ww * 0.5, _hh * 0.67 + _real_r * 2, "^ IMPOSTOR", 0, _ww, _imp_s, _imp_s, 0);
        }
    }
}

// Score popup (floating, for playing state too)
if (game_state == 2 && score_popup_timer > 0) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(c_yellow);
    draw_set_alpha(score_popup_timer / 90.0);
    var _pop_y = _hh * 0.5 - (90 - score_popup_timer) * 0.5;
    var _ps = min(_ww, _hh) * 0.003;
    draw_text_ext_transformed(_ww * 0.5, _pop_y, score_popup, 0, _ww, _ps, _ps, 0);
    draw_set_alpha(1.0);
}

// Reset draw state
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1.0);
