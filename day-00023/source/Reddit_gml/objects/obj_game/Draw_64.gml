
var _w = window_get_width();
var _h = window_get_height();
if (_w < 10 || _h < 10) exit;

draw_set_font(fnt_default);

// ============ BACKGROUND ============
// Cycling neon gradient
var _hue1 = bg_hue;
var _hue2 = (bg_hue + 120) mod 360;
var _col_top = make_colour_hsv(_hue1 * 255 / 360, 200, 255);
var _col_bot = make_colour_hsv(_hue2 * 255 / 360, 200, 255);
draw_rectangle_colour(0, 0, _w, _h, _col_top, _col_top, _col_bot, _col_bot, false);

// ============ STATE 0: LOADING ============
if (game_state == 0) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_w * 0.5, _h * 0.5, "LOADING...", 0, _w, 3, 3, 0);
    exit;
}

// ============ STATE 1: TITLE SCREEN ============
if (game_state == 1) {
    // Garish title background overlay
    draw_set_alpha(0.3);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);

    var _cx = _w * 0.5;

    // Fake app icon
    var _icon_size = min(_w, _h) * 0.2;
    var _icon_x = _cx - _icon_size * 0.5;
    var _icon_y = _h * 0.08;
    draw_set_colour(col_neon_green);
    draw_roundrect(_icon_x, _icon_y, _icon_x + _icon_size, _icon_y + _icon_size, false);
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(_cx, _icon_y + _icon_size * 0.5, "CR", 0, _icon_size, _icon_size * 0.015, _icon_size * 0.015, 0);

    // Game title
    var _title_y = _icon_y + _icon_size + _h * 0.03;
    var _title_scale = min(_w / 200, 4);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);

    // Shadow
    draw_set_colour(c_black);
    draw_text_ext_transformed(_cx + 3, _title_y + 3, "CROWD RUNNER", 0, _w, _title_scale, _title_scale, 0);
    // Main
    draw_set_colour(col_neon_yellow);
    draw_text_ext_transformed(_cx, _title_y, "CROWD RUNNER", 0, _w, _title_scale, _title_scale, 0);

    // Subtitle
    var _sub_y = _title_y + _title_scale * 18;
    var _sub_scale = _title_scale * 0.5;
    draw_set_colour(c_white);
    draw_text_ext_transformed(_cx, _sub_y, "THE #1 GAME IN THE WORLD!!", 0, _w, _sub_scale, _sub_scale, 0);

    // Fake 5-star rating
    var _star_y = _sub_y + _sub_scale * 22;
    var _star_scale = _title_scale * 0.6;
    draw_set_colour(col_neon_yellow);
    draw_text_ext_transformed(_cx, _star_y, "* * * * *", 0, _w, _star_scale, _star_scale, 0);
    draw_set_colour(c_white);
    var _rating_y = _star_y + _star_scale * 16;
    draw_text_ext_transformed(_cx, _rating_y, "4.9  (2.3M reviews)", 0, _w, _sub_scale * 0.7, _sub_scale * 0.7, 0);

    // "FREE" badge
    var _free_y = _rating_y + _sub_scale * 16;
    var _badge_w = min(_w * 0.3, 120);
    var _badge_h = _badge_w * 0.4;
    draw_set_colour(col_deep_red);
    draw_roundrect(_cx - _badge_w * 0.5, _free_y, _cx + _badge_w * 0.5, _free_y + _badge_h, false);
    draw_set_colour(c_white);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(_cx, _free_y + _badge_h * 0.5, "FREE!", 0, _badge_w, _sub_scale * 1.2, _sub_scale * 1.2, 0);

    // Pulsing "DOWNLOAD NOW" / "TAP TO PLAY" button
    var _btn_y = _h * 0.68;
    var _pulse = 1.0 + sin(title_pulse * 3) * 0.1;
    var _btn_w = min(_w * 0.75, 400) * _pulse;
    var _btn_h = min(_h * 0.08, 60) * _pulse;
    draw_set_colour(col_neon_green);
    draw_roundrect(_cx - _btn_w * 0.5, _btn_y - _btn_h * 0.5, _cx + _btn_w * 0.5, _btn_y + _btn_h * 0.5, false);
    draw_set_colour(c_white);
    var _btn_scale = min(_btn_w / 140, 3);
    draw_text_ext_transformed(_cx, _btn_y, "DOWNLOAD NOW!!!", 0, _btn_w, _btn_scale, _btn_scale, 0);

    // Stats line
    var _stats_y = _h * 0.78;
    var _stats_scale = max(1.0, _title_scale * 0.4);
    draw_set_colour(col_neon_cyan);
    draw_set_valign(fa_top);
    var _stats_text = "Round " + string(round_num) + "  |  Score: " + string(points) + "  |  Lives: " + string(lives);
    draw_text_ext_transformed(_cx, _stats_y, _stats_text, 0, _w, _stats_scale, _stats_scale, 0);

    // Fake tiny X button (top right)
    var _x_size = max(20, _w * 0.06);
    draw_set_colour(make_colour_rgb(80, 80, 80));
    draw_circle(_w - _x_size - 10, _x_size + 10, _x_size * 0.5, false);
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(_w - _x_size - 10, _x_size + 10, "X", 0, _x_size, _x_size * 0.04, _x_size * 0.04, 0);

    // "NOT A REAL AD" watermark
    draw_set_alpha(0.15);
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(_cx, _h * 0.92, "NOT A REAL AD", 0, _w, _title_scale * 0.8, _title_scale * 0.8, 30);
    draw_set_alpha(1.0);

    exit;
}

// ============ STATE 2: RUNNING (GAMEPLAY) ============
if (game_state == 2) {
    // --- Draw the road ---
    var _road_left = _w * 0.15;
    var _road_right = _w * 0.85;
    var _road_center = _w * 0.5;

    // Road surface
    draw_set_colour(make_colour_rgb(60, 60, 80));
    draw_rectangle(_road_left, 0, _road_right, _h, false);

    // Center divider line
    draw_set_colour(col_neon_yellow);
    var _line_w = max(2, _w * 0.005);
    draw_rectangle(_road_center - _line_w, 0, _road_center + _line_w, _h, false);

    // Lane stripes (scrolling dashes)
    draw_set_colour(make_colour_rgb(100, 100, 120));
    var _dash_h = 30;
    var _dash_gap = 40;
    for (var _sy = -_dash_gap + (stripe_offset mod (_dash_h + _dash_gap)); _sy < _h; _sy += _dash_h + _dash_gap) {
        draw_rectangle(_road_left + 5, _sy, _road_left + 8, _sy + _dash_h, false);
        draw_rectangle(_road_right - 8, _sy, _road_right - 5, _sy + _dash_h, false);
    }

    // --- Draw gates ---
    for (var _g = 0; _g < gate_count; _g++) {
        var _gy = gate_y[_g];

        // Only draw if on screen
        if (_gy < -80 || _gy > _h + 80) continue;

        var _gate_h = 60;
        var _gate_alpha = 1.0;
        if (gate_passed[_g]) _gate_alpha = 0.25;

        draw_set_alpha(_gate_alpha);

        // Left gate
        var _lop = gate_left_op[_g];
        var _lval = gate_left_val[_g];
        var _lcol = (_lop == 0 || _lop == 2) ? col_gate_good : col_gate_bad;

        draw_set_colour(_lcol);
        draw_roundrect(_road_left + 5, _gy - _gate_h * 0.5, _road_center - 5, _gy + _gate_h * 0.5, false);

        // Gate text
        draw_set_colour(c_white);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        var _left_text = op_symbols[_lop] + string(_lval);
        var _gate_scale = min((_road_center - _road_left) / 80, 3);
        draw_text_ext_transformed((_road_left + _road_center) * 0.5, _gy, _left_text, 0, _road_center - _road_left, _gate_scale, _gate_scale, 0);

        // Right gate
        var _rop = gate_right_op[_g];
        var _rval = gate_right_val[_g];
        var _rcol = (_rop == 0 || _rop == 2) ? col_gate_good : col_gate_bad;

        draw_set_colour(_rcol);
        draw_roundrect(_road_center + 5, _gy - _gate_h * 0.5, _road_right - 5, _gy + _gate_h * 0.5, false);

        draw_set_colour(c_white);
        var _right_text = op_symbols[_rop] + string(_rval);
        draw_text_ext_transformed((_road_center + _road_right) * 0.5, _gy, _right_text, 0, _road_right - _road_center, _gate_scale, _gate_scale, 0);

        // Choice indicator (arrow on chosen side)
        if (gate_passed[_g] && gate_choice[_g] >= 0) {
            draw_set_colour(c_white);
            if (gate_choice[_g] == 0) {
                // Left was chosen - checkmark
                draw_text_ext_transformed((_road_left + _road_center) * 0.5, _gy + _gate_h * 0.5 + 12, ">>", 0, 100, 1.5, 1.5, 0);
            } else {
                draw_text_ext_transformed((_road_center + _road_right) * 0.5, _gy + _gate_h * 0.5 + 12, ">>", 0, 100, 1.5, 1.5, 0);
            }
        }

        draw_set_alpha(1.0);
    }

    // --- Draw enemy horde (at the end) ---
    if (current_gate >= gate_count - 2) {
        var _enemy_base_y = gate_y[gate_count - 1] - gate_spacing * 0.8;
        if (_enemy_base_y > -200 && _enemy_base_y < _h) {
            // Enemy blob
            var _enemy_size = min(_w * 0.25, 80);
            draw_set_colour(col_deep_red);
            draw_circle(_road_center, _enemy_base_y, _enemy_size, false);
            draw_set_colour(make_colour_rgb(255, 50, 50));
            draw_circle(_road_center, _enemy_base_y, _enemy_size * 0.85, false);

            // Enemy number
            draw_set_colour(c_white);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            var _enemy_scale = min(_enemy_size / 20, 4);
            draw_text_ext_transformed(_road_center, _enemy_base_y, string(enemy_troops), 0, _enemy_size * 2, _enemy_scale, _enemy_scale, 0);

            // "BOSS" label
            draw_set_colour(col_neon_yellow);
            draw_text_ext_transformed(_road_center, _enemy_base_y - _enemy_size - 10, "BOSS", 0, 200, _enemy_scale * 0.6, _enemy_scale * 0.6, 0);
        }
    }

    // --- Draw army (player) ---
    var _army_x = _road_center;
    var _army_y = _h * 0.78;
    var _army_size = min(_w * 0.18, 60) + min(troops * 0.3, 30);

    // Army blob particles
    for (var _b = 0; _b < blob_count; _b++) {
        var _bx = _army_x + blob_x[_b] * (_army_size / 40);
        var _by = _army_y + blob_y[_b] * (_army_size / 40);
        draw_set_colour(blob_col[_b]);
        draw_circle(_bx, _by, blob_r[_b] * (_army_size / 50), false);
    }

    // Main army circle
    draw_set_colour(col_neon_green);
    draw_circle(_army_x, _army_y, _army_size * 0.6, false);
    draw_set_colour(c_white);
    draw_circle(_army_x, _army_y, _army_size * 0.55, false);
    draw_set_colour(col_neon_green);
    draw_circle(_army_x, _army_y, _army_size * 0.48, false);

    // Troop count
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _troop_scale = min(_army_size / 18, 5);
    // Shadow
    draw_set_colour(c_black);
    draw_text_ext_transformed(_army_x + 2, _army_y + 2, string(troops), 0, _army_size * 2, _troop_scale, _troop_scale, 0);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_army_x, _army_y, string(troops), 0, _army_size * 2, _troop_scale, _troop_scale, 0);

    // Swipe hint arrows
    if (current_gate < gate_count && !gate_passed[current_gate]) {
        draw_set_alpha(0.5 + sin(current_time * 0.005) * 0.3);
        draw_set_colour(c_white);
        var _arrow_scale = max(1.5, _troop_scale * 0.5);
        draw_text_ext_transformed(_road_left * 0.5, _army_y, "<<", 0, 100, _arrow_scale, _arrow_scale, 0);
        draw_text_ext_transformed(_w - _road_left * 0.5, _army_y, ">>", 0, 100, _arrow_scale, _arrow_scale, 0);
        draw_set_alpha(1.0);
    }

    // --- Score popup ---
    if (score_popup_timer > 0) {
        var _pop_alpha = score_popup_timer / 40;
        draw_set_alpha(_pop_alpha);
        var _pop_y = _army_y - 50 - (40 - score_popup_timer) * 1.5;
        var _pop_scale = min(_w / 150, 3);
        if (string_char_at(score_popup, 1) == "+") {
            draw_set_colour(col_neon_green);
        } else if (string_char_at(score_popup, 1) == "-") {
            draw_set_colour(col_deep_red);
        } else {
            draw_set_colour(col_neon_yellow);
        }
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text_ext_transformed(_army_x, _pop_y, score_popup, 0, _w, _pop_scale, _pop_scale, 0);
        draw_set_alpha(1.0);
    }

    // --- HUD ---
    // Level indicator (top center)
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    var _hud_scale = min(_w / 180, 3);

    // Level background bar
    draw_set_colour(make_colour_rgb(0, 0, 0));
    draw_set_alpha(0.5);
    draw_rectangle(0, 0, _w, _hud_scale * 22, false);
    draw_set_alpha(1.0);

    draw_set_colour(col_neon_yellow);
    draw_text_ext_transformed(_w * 0.5, 5, "LEVEL " + string(round_num), 0, _w, _hud_scale, _hud_scale, 0);

    // Lives (hearts) - top left
    draw_set_halign(fa_left);
    var _heart_scale = _hud_scale * 0.8;
    var _heart_text = "";
    for (var _li = 0; _li < lives; _li++) {
        _heart_text += "<3 ";
    }
    draw_set_colour(col_neon_pink);
    draw_text_ext_transformed(10, 5, _heart_text, 0, _w * 0.3, _heart_scale, _heart_scale, 0);

    // Score - top right
    draw_set_halign(fa_right);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_w - 10, 5, string(points), 0, _w * 0.3, _hud_scale * 0.7, _hud_scale * 0.7, 0);

    // Fake progress bar (bottom)
    var _bar_h = max(8, _h * 0.015);
    var _bar_y = _h - _bar_h - 5;
    draw_set_colour(make_colour_rgb(40, 40, 40));
    draw_rectangle(10, _bar_y, _w - 10, _bar_y + _bar_h, false);
    draw_set_colour(col_neon_green);
    var _bar_fill = 10 + (_w - 20) * fake_progress;
    draw_rectangle(10, _bar_y, _bar_fill, _bar_y + _bar_h, false);

    // "SKIP AD >>" top right fake button
    draw_set_halign(fa_right);
    draw_set_valign(fa_top);
    draw_set_alpha(0.4);
    draw_set_colour(c_white);
    var _skip_scale = max(1.0, _hud_scale * 0.4);
    draw_text_ext_transformed(_w - 10, _hud_scale * 22 + 5, "Skip Ad >>", 0, 200, _skip_scale, _skip_scale, 0);
    draw_set_alpha(1.0);

    exit;
}

// ============ STATE 3: BATTLE ============
if (game_state == 3) {
    var _cx = _w * 0.5;
    var _cy = _h * 0.45;
    var _progress = min(battle_timer / battle_duration, 1.0);

    // Road background
    var _road_left = _w * 0.15;
    var _road_right = _w * 0.85;
    draw_set_colour(make_colour_rgb(60, 60, 80));
    draw_rectangle(_road_left, 0, _road_right, _h, false);

    // Army approaching from bottom
    var _army_start_y = _h * 0.85;
    var _army_end_y = _cy + 10;
    var _army_y = lerp(_army_start_y, _army_end_y, min(_progress * 2, 1.0));
    var _army_size = min(_w * 0.18, 60) + min(troops * 0.3, 30);

    // Enemy at top
    var _enemy_start_y = _h * 0.1;
    var _enemy_end_y = _cy - 10;
    var _enemy_y = lerp(_enemy_start_y, _enemy_end_y, min(_progress * 2, 1.0));
    var _enemy_size = min(_w * 0.25, 80);

    // Draw army blob
    draw_set_colour(col_neon_green);
    draw_circle(_cx, _army_y, _army_size * 0.6, false);
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _num_scale = min(_army_size / 18, 5);
    draw_text_ext_transformed(_cx, _army_y, string(troops), 0, _army_size * 2, _num_scale, _num_scale, 0);

    // Draw enemy blob
    draw_set_colour(col_deep_red);
    draw_circle(_cx, _enemy_y, _enemy_size, false);
    draw_set_colour(make_colour_rgb(255, 50, 50));
    draw_circle(_cx, _enemy_y, _enemy_size * 0.85, false);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_cx, _enemy_y, string(enemy_troops), 0, _enemy_size * 2, _num_scale, _num_scale, 0);

    // Clash effect (when they meet)
    if (_progress > 0.5) {
        var _clash_progress = (_progress - 0.5) * 2;
        var _spark_size = _clash_progress * min(_w, _h) * 0.3;

        // Starburst
        draw_set_colour(col_neon_yellow);
        draw_set_alpha(1.0 - _clash_progress * 0.5);
        draw_circle(_cx, _cy, _spark_size, false);

        // "VS" text
        draw_set_colour(c_white);
        draw_set_alpha(1.0);
        var _vs_scale = min(_w / 60, 6) * (1.0 + _clash_progress * 0.5);
        draw_text_ext_transformed(_cx, _cy, "VS", 0, _w, _vs_scale, _vs_scale, 0);

        // Result text fading in
        if (_clash_progress > 0.5) {
            var _res_alpha = (_clash_progress - 0.5) * 2;
            draw_set_alpha(_res_alpha);
            if (battle_result == 1) {
                draw_set_colour(col_neon_green);
                draw_text_ext_transformed(_cx, _cy + 80, "CRUSH!", 0, _w, _vs_scale * 0.6, _vs_scale * 0.6, 0);
            } else {
                draw_set_colour(col_deep_red);
                draw_text_ext_transformed(_cx, _cy + 80, "DEFEATED!", 0, _w, _vs_scale * 0.6, _vs_scale * 0.6, 0);
            }
            draw_set_alpha(1.0);
        }
    }

    // HUD
    draw_set_alpha(0.5);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _w, 30, false);
    draw_set_alpha(1.0);
    draw_set_colour(col_neon_yellow);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    var _hud_scale = min(_w / 180, 3);
    draw_text_ext_transformed(_cx, 5, "LEVEL " + string(round_num) + " BOSS!", 0, _w, _hud_scale, _hud_scale, 0);

    exit;
}

// ============ STATE 4: RESULT ============
if (game_state == 4) {
    var _cx = _w * 0.5;
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    if (battle_result == 1) {
        // WIN screen
        var _title_scale = min(_w / 100, 6);

        // Pulsing background
        draw_set_colour(col_neon_green);
        draw_set_alpha(0.2 + sin(title_pulse * 4) * 0.1);
        draw_rectangle(0, 0, _w, _h, false);
        draw_set_alpha(1.0);

        // "YOU DID IT!!!" garish text
        draw_set_colour(c_black);
        draw_text_ext_transformed(_cx + 3, _h * 0.2 + 3, "YOU DID IT!!!", 0, _w, _title_scale, _title_scale, 0);
        draw_set_colour(col_neon_yellow);
        draw_text_ext_transformed(_cx, _h * 0.2, "YOU DID IT!!!", 0, _w, _title_scale, _title_scale, 0);

        // Stats
        var _stat_scale = min(_w / 200, 3);
        draw_set_colour(c_white);
        draw_text_ext_transformed(_cx, _h * 0.38, "Your Army: " + string(troops), 0, _w, _stat_scale, _stat_scale, 0);
        draw_set_colour(col_deep_red);
        draw_text_ext_transformed(_cx, _h * 0.46, "Enemy: " + string(enemy_troops), 0, _w, _stat_scale, _stat_scale, 0);

        draw_set_colour(col_neon_green);
        var _surplus = troops - enemy_troops;
        draw_text_ext_transformed(_cx, _h * 0.54, "Surplus: +" + string(_surplus), 0, _w, _stat_scale, _stat_scale, 0);

        // Score
        draw_set_colour(col_neon_yellow);
        draw_text_ext_transformed(_cx, _h * 0.64, "SCORE: " + string(points), 0, _w, _stat_scale * 1.2, _stat_scale * 1.2, 0);

        // "Tap for next level" button
        if (result_timer > 60) {
            var _btn_pulse = 1.0 + sin(title_pulse * 3) * 0.08;
            var _btn_w = min(_w * 0.7, 350) * _btn_pulse;
            var _btn_h = min(_h * 0.07, 50) * _btn_pulse;
            draw_set_colour(col_neon_green);
            draw_roundrect(_cx - _btn_w * 0.5, _h * 0.78 - _btn_h * 0.5, _cx + _btn_w * 0.5, _h * 0.78 + _btn_h * 0.5, false);
            draw_set_colour(c_white);
            var _btn_scale = min(_btn_w / 150, 2.5);
            draw_text_ext_transformed(_cx, _h * 0.78, "NEXT LEVEL >>", 0, _btn_w, _btn_scale, _btn_scale, 0);
        }

        // Fake confetti (just colored dots)
        for (var _c = 0; _c < 15; _c++) {
            var _conf_x = _w * (0.1 + 0.8 * ((_c * 73 + floor(title_pulse * 100)) mod 100) / 100);
            var _conf_y = _h * (((_c * 37 + floor(title_pulse * 60)) mod 100) / 100);
            draw_set_colour(choose(col_neon_pink, col_neon_yellow, col_neon_cyan, col_neon_green, col_neon_orange));
            draw_circle(_conf_x, _conf_y, 4, false);
        }
    } else {
        // LOSE screen
        var _title_scale = min(_w / 100, 6);

        draw_set_colour(col_deep_red);
        draw_set_alpha(0.3);
        draw_rectangle(0, 0, _w, _h, false);
        draw_set_alpha(1.0);

        draw_set_colour(c_black);
        draw_text_ext_transformed(_cx + 3, _h * 0.2 + 3, "FAIL!", 0, _w, _title_scale, _title_scale, 0);
        draw_set_colour(col_deep_red);
        draw_text_ext_transformed(_cx, _h * 0.2, "FAIL!", 0, _w, _title_scale, _title_scale, 0);

        var _stat_scale = min(_w / 200, 3);
        draw_set_colour(c_white);
        draw_text_ext_transformed(_cx, _h * 0.4, "Your Army: " + string(troops), 0, _w, _stat_scale, _stat_scale, 0);
        draw_set_colour(col_deep_red);
        draw_text_ext_transformed(_cx, _h * 0.48, "Enemy: " + string(enemy_troops), 0, _w, _stat_scale, _stat_scale, 0);

        // Lives remaining
        draw_set_colour(col_neon_pink);
        if (lives > 0) {
            draw_text_ext_transformed(_cx, _h * 0.58, "Lives Left: " + string(lives), 0, _w, _stat_scale, _stat_scale, 0);
        } else {
            draw_text_ext_transformed(_cx, _h * 0.58, "NO LIVES LEFT!", 0, _w, _stat_scale, _stat_scale, 0);
        }

        if (result_timer > 60) {
            var _btn_pulse = 1.0 + sin(title_pulse * 3) * 0.08;
            var _btn_w = min(_w * 0.7, 350) * _btn_pulse;
            var _btn_h = min(_h * 0.07, 50) * _btn_pulse;
            draw_set_colour(col_neon_orange);
            draw_roundrect(_cx - _btn_w * 0.5, _h * 0.75 - _btn_h * 0.5, _cx + _btn_w * 0.5, _h * 0.75 + _btn_h * 0.5, false);
            draw_set_colour(c_white);
            var _btn_scale = min(_btn_w / 120, 2.5);
            if (lives > 0) {
                draw_text_ext_transformed(_cx, _h * 0.75, "TRY AGAIN", 0, _btn_w, _btn_scale, _btn_scale, 0);
            } else {
                draw_text_ext_transformed(_cx, _h * 0.75, "CONTINUE", 0, _btn_w, _btn_scale, _btn_scale, 0);
            }
        }
    }

    // Score popup floating up
    if (score_popup_timer > 0) {
        var _pop_alpha = score_popup_timer / 90;
        draw_set_alpha(_pop_alpha);
        var _pop_y = _h * 0.3 - (90 - score_popup_timer) * 0.5;
        draw_set_colour(col_neon_yellow);
        var _pop_scale = min(_w / 120, 4);
        draw_text_ext_transformed(_cx, _pop_y, score_popup, 0, _w, _pop_scale, _pop_scale, 0);
        draw_set_alpha(1.0);
    }

    exit;
}

// ============ STATE 5: GAME OVER ============
if (game_state == 5) {
    var _cx = _w * 0.5;
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Dark overlay
    draw_set_colour(c_black);
    draw_set_alpha(0.6);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);

    // "GAME OVER" title
    var _title_scale = min(_w / 80, 7);
    draw_set_colour(c_black);
    draw_text_ext_transformed(_cx + 3, _h * 0.12 + 3, "GAME OVER", 0, _w, _title_scale, _title_scale, 0);
    draw_set_colour(col_deep_red);
    draw_text_ext_transformed(_cx, _h * 0.12, "GAME OVER", 0, _w, _title_scale, _title_scale, 0);

    // Final score
    var _score_scale = min(_w / 120, 5);
    draw_set_colour(col_neon_yellow);
    draw_text_ext_transformed(_cx, _h * 0.28, "FINAL SCORE", 0, _w, _score_scale * 0.6, _score_scale * 0.6, 0);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_cx, _h * 0.36, string(points), 0, _w, _score_scale, _score_scale, 0);

    // Rounds survived
    var _stat_scale = min(_w / 200, 3);
    draw_set_colour(col_neon_cyan);
    draw_text_ext_transformed(_cx, _h * 0.46, "Rounds Cleared: " + string(max(0, round_num - 1)), 0, _w, _stat_scale, _stat_scale, 0);

    // Fake "RATE 5 STARS TO CONTINUE!" (garish parody)
    var _rate_y = _h * 0.56;
    var _rate_w = min(_w * 0.85, 420);
    var _rate_h = _stat_scale * 20;
    draw_set_colour(col_neon_orange);
    draw_roundrect(_cx - _rate_w * 0.5, _rate_y, _cx + _rate_w * 0.5, _rate_y + _rate_h, false);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_cx, _rate_y + _rate_h * 0.5, "RATE 5 STARS TO CONTINUE!", 0, _rate_w, _stat_scale * 0.8, _stat_scale * 0.8, 0);

    // Fake stars
    draw_set_colour(col_neon_yellow);
    draw_text_ext_transformed(_cx, _rate_y + _rate_h + _stat_scale * 12, "* * * * *", 0, _w, _stat_scale * 1.2, _stat_scale * 1.2, 0);

    // Fake "BUY EXTRA LIVES $4.99" button
    var _buy_y = _h * 0.72;
    var _buy_w = min(_w * 0.75, 380);
    var _buy_h = _stat_scale * 18;
    draw_set_colour(col_neon_pink);
    draw_roundrect(_cx - _buy_w * 0.5, _buy_y, _cx + _buy_w * 0.5, _buy_y + _buy_h, false);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_cx, _buy_y + _buy_h * 0.5, "BUY EXTRA LIVES $4.99", 0, _buy_w, _stat_scale * 0.7, _stat_scale * 0.7, 0);

    // Real "Tap to restart" text (small, at bottom)
    draw_set_colour(c_white);
    draw_set_alpha(0.6 + sin(title_pulse * 2) * 0.3);
    var _restart_scale = max(1.2, _stat_scale * 0.6);
    draw_text_ext_transformed(_cx, _h * 0.9, "tap anywhere to restart", 0, _w, _restart_scale, _restart_scale, 0);
    draw_set_alpha(1.0);

    // "NOT A REAL AD" watermark (rotated)
    draw_set_alpha(0.1);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_cx, _h * 0.5, "NOT A REAL AD", 0, _w, _title_scale * 0.6, _title_scale * 0.6, 25);
    draw_set_alpha(1.0);
}
