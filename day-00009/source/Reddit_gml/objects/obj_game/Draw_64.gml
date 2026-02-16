
// === PILATES FLOW — Draw_64 ===
// States: 0=title, 1=preview, 2=pose_intro, 3=minigame, 4=result, 5=gameover

var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
if (_gw <= 0 || _gh <= 0) exit;

var _scale = max(1, _gh / 700);
var _sx = 0;
var _sy = 0;
if (shake > 0) {
    _sx = irandom_range(-round(shake), round(shake));
    _sy = irandom_range(-round(shake), round(shake));
}

// === BACKGROUND ===
draw_rectangle_colour(0, 0, _gw, _gh, bg_top, bg_top, bg_bot, bg_bot, false);

// === DRAW STICK FIGURE ===
var _fx = _gw / 2 + _sx;
var _fy = _gh * 0.42 + _sy;
var _fs = _gh * 0.055; // figure scale
var _lw = max(2, _scale * 2.0);
var _fig = fig_display;

// Joint pixel positions
var _hx = _fx + _fig[0] * _fs;  var _hy = _fy + _fig[1] * _fs;  // head
var _cx = _fx + _fig[2] * _fs;  var _cy = _fy + _fig[3] * _fs;  // chest
var _px = _fx + _fig[4] * _fs;  var _py = _fy + _fig[5] * _fs;  // hip
var _lhx = _fx + _fig[6] * _fs; var _lhy = _fy + _fig[7] * _fs; // left hand
var _rhx = _fx + _fig[8] * _fs; var _rhy = _fy + _fig[9] * _fs; // right hand
var _lex = _fx + _fig[10]* _fs; var _ley = _fy + _fig[11]* _fs; // left elbow
var _rex = _fx + _fig[12]* _fs; var _rey = _fy + _fig[13]* _fs; // right elbow
var _lfx = _fx + _fig[14]* _fs; var _lfy = _fy + _fig[15]* _fs; // left foot
var _rfx = _fx + _fig[16]* _fs; var _rfy = _fy + _fig[17]* _fs; // right foot
var _lkx = _fx + _fig[18]* _fs; var _lky = _fy + _fig[19]* _fs; // left knee
var _rkx = _fx + _fig[20]* _fs; var _rky = _fy + _fig[21]* _fs; // right knee

draw_set_colour(fig_col);
// Head
draw_circle(_hx, _hy, _fs * 0.55, true);
// Neck: head → chest
draw_line_width(_hx, _hy + _fs * 0.4, _cx, _cy, _lw);
// Torso: chest → hip
draw_line_width(_cx, _cy, _px, _py, _lw);
// Left arm: chest → elbow → hand
draw_line_width(_cx, _cy, _lex, _ley, _lw);
draw_line_width(_lex, _ley, _lhx, _lhy, _lw);
// Right arm: chest → elbow → hand
draw_line_width(_cx, _cy, _rex, _rey, _lw);
draw_line_width(_rex, _rey, _rhx, _rhy, _lw);
// Left leg: hip → knee → foot
draw_line_width(_px, _py, _lkx, _lky, _lw);
draw_line_width(_lkx, _lky, _lfx, _lfy, _lw);
// Right leg: hip → knee → foot
draw_line_width(_px, _py, _rkx, _rky, _lw);
draw_line_width(_rkx, _rky, _rfx, _rfy, _lw);

// === MINIGAME UI (state 3) ===
if (game_state == 3) {

    // --- HOLD UI ---
    if (minigame_type == 0) {
        // Setup ring
        if (mg_phase == 0) {
            var _ring_frac = hold_setup_timer / 60;
            var _ring_r = _fs * 6 * _ring_frac + _fs * 2;
            draw_set_alpha(0.3);
            draw_set_colour(zone_blue);
            draw_circle(_fx, _fy, _ring_r, true);
            draw_set_alpha(1);

            // "Get Ready" text
            draw_set_font(fnt_default);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(text_dark);
            var _ts = _scale * 0.8;
            draw_text_ext_transformed(_gw/2, _gh * 0.78, "Get Ready...", 0, _gw, _ts, _ts, 0);
        }
        else if (mg_phase == 1) {
            // Hold bar
            var _bar_w = _gw * 0.65;
            var _bar_h = max(14, 16 * _scale);
            var _bar_x = (_gw - _bar_w) / 2;
            var _bar_y = _gh * 0.78;

            // Zone backgrounds
            // Red (0 - 0.3)
            draw_set_colour(zone_red);
            draw_set_alpha(0.5);
            draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * 0.3, _bar_y + _bar_h, false);
            // Yellow (0.3 - green_start)
            draw_set_colour(zone_yellow);
            draw_rectangle(_bar_x + _bar_w * 0.3, _bar_y, _bar_x + _bar_w * hold_green_start, _bar_y + _bar_h, false);
            // Green (green_start - green_end)
            draw_set_colour(zone_green);
            draw_set_alpha(0.7);
            draw_rectangle(_bar_x + _bar_w * hold_green_start, _bar_y, _bar_x + _bar_w * hold_green_end, _bar_y + _bar_h, false);
            // Red (green_end - 1.0)
            draw_set_colour(zone_red);
            draw_set_alpha(0.5);
            draw_rectangle(_bar_x + _bar_w * hold_green_end, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);
            draw_set_alpha(1);

            // Bar border
            draw_set_colour(merge_colour(text_dark, bg_top, 0.5));
            draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, true);

            // Fill indicator
            if (hold_holding) {
                var _fill = clamp(hold_timer / hold_max, 0, 1);
                var _ind_x = _bar_x + _bar_w * _fill;
                draw_set_colour(c_white);
                draw_line_width(_ind_x, _bar_y - 6, _ind_x, _bar_y + _bar_h + 6, max(3, 4 * _scale));

                // Glow ring around figure while holding
                var _glow = 0.2 + sin(current_time * 0.008) * 0.15;
                draw_set_alpha(_glow);
                draw_set_colour(zone_blue);
                draw_circle(_fx, _fy, _fs * 2.5, true);
                draw_set_alpha(1);
            }

            // Text
            draw_set_font(fnt_default);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            var _ts = _scale * 0.9;
            if (!hold_holding) {
                var _blink = 0.4 + sin(current_time * 0.006) * 0.6;
                draw_set_alpha(max(0, _blink));
                draw_set_colour(text_dark);
                draw_text_ext_transformed(_gw/2, _gh * 0.72, "TAP & HOLD!", 0, _gw, _ts, _ts, 0);
                draw_set_alpha(1);
            } else {
                draw_set_colour(zone_green);
                draw_text_ext_transformed(_gw/2, _gh * 0.72, "HOLDING...", 0, _gw, _ts * 0.7, _ts * 0.7, 0);
            }
        }
    }

    // --- BREATHE UI ---
    else if (minigame_type == 1) {
        var _br_max_r = min(_gw, _gh) * 0.38;
        var _br_cx = _gw / 2 + _sx;
        var _br_cy = _gh * 0.42 + _sy;

        // Target ring with scoring zone indicators
        var _target_r = (br_target - br_center + br_amplitude) / (2 * br_amplitude) * _br_max_r * 2;

        // Outer ring (+2 zone)
        draw_set_alpha(0.15);
        draw_set_colour(zone_yellow);
        draw_circle(_br_cx, _br_cy, _target_r + 18 * _scale, true);
        draw_circle(_br_cx, _br_cy, _target_r - 18 * _scale, true);

        // Mid ring (+3 zone)
        draw_set_alpha(0.25);
        draw_set_colour(zone_green);
        draw_circle(_br_cx, _br_cy, _target_r + 8 * _scale, true);
        draw_circle(_br_cx, _br_cy, _target_r - 8 * _scale, true);

        // Perfect ring (+5 zone — bright)
        draw_set_alpha(0.45);
        draw_set_colour(gold_col);
        draw_circle(_br_cx, _br_cy, _target_r + 3 * _scale, true);
        draw_circle(_br_cx, _br_cy, _target_r - 3 * _scale, true);
        draw_set_alpha(1);

        // Active breathing circle
        var _cur_r = (br_radius - br_center + br_amplitude) / (2 * br_amplitude) * _br_max_r * 2;
        var _br_col = zone_blue;
        if (br_crossing_active) _br_col = zone_green;

        draw_set_alpha(0.25);
        draw_set_colour(_br_col);
        draw_circle(_br_cx, _br_cy, _cur_r, false);
        draw_set_alpha(0.6);
        draw_circle(_br_cx, _br_cy, _cur_r, true);
        draw_set_alpha(1);

        // Inhale/Exhale label
        draw_set_font(fnt_default);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        var _ts = _scale * 0.6;
        var _is_expanding = (sin(br_phase) < sin(br_phase + br_speed));
        draw_set_colour(merge_colour(text_dark, bg_top, 0.4));
        if (_is_expanding) {
            draw_text_ext_transformed(_gw/2, _gh * 0.78, "INHALE", 0, _gw, _ts, _ts, 0);
        } else {
            draw_text_ext_transformed(_gw/2, _gh * 0.78, "EXHALE", 0, _gw, _ts, _ts, 0);
        }

        // Hit counter
        draw_set_colour(zone_green);
        var _cs = _scale * 0.7;
        draw_text_ext_transformed(_gw/2, _gh * 0.85, string(br_hits) + " / " + string(br_crossings_done), 0, _gw, _cs, _cs, 0);

        // Crossing flash
        if (br_crossing_active && !br_crossing_tapped) {
            var _flash = br_crossing_timer / max(1, round(br_window / difficulty));
            draw_set_alpha(_flash * 0.15);
            draw_set_colour(zone_green);
            draw_circle(_br_cx, _br_cy, _target_r + 20, false);
            draw_set_alpha(1);
        }
    }

    // --- BALANCE UI ---
    else if (minigame_type == 2) {
        // Balance line
        var _line_w = _gw * 0.7;
        var _line_x = (_gw - _line_w) / 2;
        var _line_y = _gh * 0.75 + _sy;

        // Center zone
        var _zone_w = _line_w * bal_zone_size;
        draw_set_alpha(0.2);
        draw_set_colour(zone_green);
        draw_rectangle(_gw/2 - _zone_w + _sx, _line_y - 10, _gw/2 + _zone_w + _sx, _line_y + 10, false);
        draw_set_alpha(1);

        // Line
        draw_set_colour(merge_colour(text_dark, bg_top, 0.5));
        draw_line_width(_line_x + _sx, _line_y, _line_x + _line_w + _sx, _line_y, max(2, 2 * _scale));

        // Center mark
        draw_set_colour(zone_green);
        draw_line_width(_gw/2 + _sx, _line_y - 8, _gw/2 + _sx, _line_y + 8, max(2, 2 * _scale));

        // Balance dot
        var _dot_x = _gw/2 + bal_x * (_line_w / 2) + _sx;
        var _dot_col = (abs(bal_x) < bal_zone_size) ? zone_green : zone_red;
        draw_set_colour(_dot_col);
        draw_circle(_dot_x, _line_y, max(6, 8 * _scale), false);

        // Timer bar
        var _total_dur = round(bal_duration / max(1, difficulty * 0.8));
        var _time_frac = clamp(bal_timer / max(1, _total_dur), 0, 1);
        var _timer_w = _line_w * _time_frac;
        draw_set_alpha(0.3);
        draw_set_colour(zone_blue);
        draw_rectangle(_line_x + _sx, _line_y + 20, _line_x + _timer_w + _sx, _line_y + 26, false);
        draw_set_alpha(1);

        // Instruction
        draw_set_font(fnt_default);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        var _ts = _scale * 0.6;
        draw_set_colour(merge_colour(text_dark, bg_top, 0.4));
        draw_text_ext_transformed(_gw/2, _gh * 0.85, "Tap to balance", 0, _gw, _ts, _ts, 0);
    }
}

// === PARTICLES ===
for (var _i = 0; _i < part_count; _i++) {
    var _ppx = part_x[_i] * _gw;
    var _ppy = part_y[_i] * _gh;
    var _alpha = part_life[_i] / max(1, part_max_life[_i]);

    draw_set_font(fnt_default);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _ts = _scale * 0.9;

    draw_set_alpha(_alpha * 0.5);
    draw_set_colour(c_black);
    draw_text_ext_transformed(_ppx + 2, _ppy + 2, part_text[_i], 0, 400, _ts, _ts, 0);
    draw_set_alpha(_alpha);
    draw_set_colour(part_col[_i]);
    draw_text_ext_transformed(_ppx, _ppy, part_text[_i], 0, 400, _ts, _ts, 0);
    draw_set_alpha(1);
}

// === FLASH ===
if (flash_timer > 0) {
    draw_set_alpha(flash_timer / 10 * 0.2);
    draw_set_colour(c_white);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
}

// === HUD (active gameplay: states 2-4) ===
if (game_state >= 2 && game_state <= 4) {
    draw_set_font(fnt_default);

    // Session timer (top center)
    var _secs = ceil(session_timer / 60);
    var _timer_s = _scale * 1.2;
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    var _timer_col = text_dark;
    if (_secs <= 10) _timer_col = zone_red;
    else if (_secs <= 20) _timer_col = zone_yellow;
    draw_set_colour(_timer_col);
    draw_text_ext_transformed(_gw/2, 12, string(_secs) + "s", 0, 200, _timer_s, _timer_s, 0);

    // Score (top left)
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    var _ss = _scale * 1.5;
    draw_set_colour(c_white);
    draw_text_ext_transformed(17, 17, string(run_score), 0, 200, _ss, _ss, 0);
    draw_set_colour(text_dark);
    draw_text_ext_transformed(16, 16, string(run_score), 0, 200, _ss, _ss, 0);
    var _ls = _scale * 0.5;
    draw_set_colour(merge_colour(text_dark, bg_top, 0.4));
    draw_text_ext_transformed(16, 16 + _ss * 18, "pts", 0, 200, _ls, _ls, 0);

    // Pose name (during intro or minigame)
    if (game_state == 2 || game_state == 3) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        var _ns = _scale * 0.7;
        draw_set_colour(text_dark);
        draw_text_ext_transformed(_gw/2, _gh * 0.06, pose_name_list[current_pose_id], 0, _gw, _ns, _ns, 0);

        // Type label
        if (game_state == 3 && minigame_type >= 0 && minigame_type <= 2) {
            var _tl = _scale * 0.45;
            draw_set_colour(merge_colour(text_dark, bg_top, 0.4));
            draw_text_ext_transformed(_gw/2, _gh * 0.06 + _ns * 18, mg_type_names[minigame_type], 0, _gw, _tl, _tl, 0);
        }
    }

    // Pose counter
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    var _cs = _scale * 0.45;
    draw_set_colour(merge_colour(text_dark, bg_top, 0.4));
    draw_text_ext_transformed(16, 16 + _ss * 18 + _ls * 18, "Pose " + string(poses_completed + 1), 0, 200, _cs, _cs, 0);
}

// === TITLE OVERLAY ===
if (game_state == 0) {
    draw_set_alpha(0.88);
    draw_set_colour(make_colour_rgb(242, 246, 255));
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    draw_set_font(fnt_default);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Title
    var _ts = _scale * 2.2;
    draw_set_colour(text_dark);
    draw_text_ext_transformed(_gw/2, _gh * 0.12, "PILATES", 0, _gw, _ts, _ts, 0);
    var _ts2 = _scale * 1.8;
    draw_set_colour(make_colour_rgb(200, 160, 190));
    draw_text_ext_transformed(_gw/2, _gh * 0.12 + _ts * 18, "FLOW", 0, _gw, _ts2, _ts2, 0);

    // Draw the stick figure on top of overlay
    draw_set_colour(fig_col);
    draw_circle(_hx, _hy, _fs * 0.55, true);
    draw_line_width(_hx, _hy + _fs * 0.4, _cx, _cy, _lw);
    draw_line_width(_cx, _cy, _px, _py, _lw);
    draw_line_width(_cx, _cy, _lex, _ley, _lw);
    draw_line_width(_lex, _ley, _lhx, _lhy, _lw);
    draw_line_width(_cx, _cy, _rex, _rey, _lw);
    draw_line_width(_rex, _rey, _rhx, _rhy, _lw);
    draw_line_width(_px, _py, _lkx, _lky, _lw);
    draw_line_width(_lkx, _lky, _lfx, _lfy, _lw);
    draw_line_width(_px, _py, _rkx, _rky, _lw);
    draw_line_width(_rkx, _rky, _rfx, _rfy, _lw);

    // Instructions
    var _is = _scale * 0.65;
    draw_set_colour(text_dark);
    draw_text_ext_transformed(_gw/2, _gh * 0.68, "Hold poses. Match your breath.", 0, _gw * 0.9, _is, _is, 0);
    draw_text_ext_transformed(_gw/2, _gh * 0.68 + _is * 20, "Find your balance.", 0, _gw * 0.9, _is, _is, 0);

    var _is2 = _scale * 0.5;
    draw_set_colour(merge_colour(text_dark, bg_top, 0.35));
    draw_text_ext_transformed(_gw/2, _gh * 0.78, "40 second sessions  |  HOLD / BREATHE / BALANCE", 0, _gw * 0.9, _is2, _is2, 0);

    if (points > 0) {
        draw_set_colour(gold_col);
        draw_text_ext_transformed(_gw/2, _gh * 0.84, "Best: " + string(points) + " pts", 0, _gw, _is * 0.9, _is * 0.9, 0);
    }

    var _blink = 0.4 + sin(current_time * 0.004) * 0.6;
    draw_set_alpha(max(0, _blink));
    draw_set_colour(text_dark);
    var _tap_s = _scale * 0.7;
    draw_text_ext_transformed(_gw/2, _gh * 0.92, "Tap to Start", 0, _gw, _tap_s, _tap_s, 0);
    draw_set_alpha(1);
}

// === SESSION PREVIEW OVERLAY (state 1) ===
if (game_state == 1) {
    draw_set_alpha(0.88);
    draw_set_colour(make_colour_rgb(242, 246, 255));
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    draw_set_font(fnt_default);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // "Your Session" header
    var _ts = _scale * 1.4;
    draw_set_colour(text_dark);
    draw_text_ext_transformed(_gw/2, _gh * 0.06, "YOUR SESSION", 0, _gw, _ts, _ts, 0);

    // Draw the animated figure on top
    draw_set_colour(fig_col);
    draw_circle(_hx, _hy, _fs * 0.55, true);
    draw_line_width(_hx, _hy + _fs * 0.4, _cx, _cy, _lw);
    draw_line_width(_cx, _cy, _px, _py, _lw);
    draw_line_width(_cx, _cy, _lex, _ley, _lw);
    draw_line_width(_lex, _ley, _lhx, _lhy, _lw);
    draw_line_width(_cx, _cy, _rex, _rey, _lw);
    draw_line_width(_rex, _rey, _rhx, _rhy, _lw);
    draw_line_width(_px, _py, _lkx, _lky, _lw);
    draw_line_width(_lkx, _lky, _lfx, _lfy, _lw);
    draw_line_width(_px, _py, _rkx, _rky, _lw);
    draw_line_width(_rkx, _rky, _rfx, _rfy, _lw);

    // Pose list below figure
    var _list_y = _gh * 0.72;
    var _ns = _scale * 0.55;
    var _gap = _ns * 22;
    var _total_h = array_length(pose_queue) * _gap;
    var _start_y = _list_y - _total_h / 2;

    for (var _i = 0; _i < array_length(pose_queue); _i++) {
        var _pid = pose_queue[_i];
        var _yy = _start_y + _i * _gap;
        var _is_current = (_i == preview_pose_idx);

        if (_is_current) {
            // Highlight current preview pose
            draw_set_colour(text_dark);
            draw_set_alpha(1);
            var _cs = _ns * 1.15;
            draw_text_ext_transformed(_gw/2, _yy, "> " + pose_name_list[_pid] + " <", 0, _gw, _cs, _cs, 0);
        } else if (_i < preview_pose_idx) {
            // Already previewed — dim
            draw_set_colour(merge_colour(text_dark, bg_top, 0.5));
            draw_set_alpha(0.5);
            draw_text_ext_transformed(_gw/2, _yy, pose_name_list[_pid], 0, _gw, _ns, _ns, 0);
        } else {
            // Upcoming — muted
            draw_set_colour(merge_colour(text_dark, bg_top, 0.3));
            draw_set_alpha(0.7);
            draw_text_ext_transformed(_gw/2, _yy, pose_name_list[_pid], 0, _gw, _ns, _ns, 0);
        }
        draw_set_alpha(1);
    }
}

// === POSE INTRO OVERLAY (state 2) ===
if (game_state == 2) {
    // Pose name announcement
    var _intro_alpha = clamp(intro_timer / 30, 0, 1);
    draw_set_font(fnt_default);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    var _ns = _scale * 1.5;
    draw_set_alpha(_intro_alpha);
    draw_set_colour(text_dark);
    draw_text_ext_transformed(_gw/2, _gh * 0.2, pose_name_list[current_pose_id], 0, _gw, _ns, _ns, 0);

    var _tl = _scale * 0.7;
    draw_set_colour(merge_colour(text_dark, bg_top, 0.3));
    draw_text_ext_transformed(_gw/2, _gh * 0.2 + _ns * 18, mg_type_names[pose_types[current_pose_id]], 0, _gw, _tl, _tl, 0);
    draw_set_alpha(1);
}

// === GAME OVER OVERLAY (state 5) ===
if (game_state == 5) {
    draw_set_alpha(0.75);
    draw_set_colour(make_colour_rgb(30, 30, 45));
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    draw_set_font(fnt_default);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    var _ts = _scale * 1.6;
    draw_set_colour(c_white);
    draw_text_ext_transformed(_gw/2, _gh * 0.18, "SESSION COMPLETE", 0, _gw, _ts, _ts, 0);

    // Score
    var _ss = _scale * 2.5;
    draw_set_colour(gold_col);
    draw_text_ext_transformed(_gw/2, _gh * 0.35, string(run_score), 0, _gw, _ss, _ss, 0);
    var _ls = _scale * 0.6;
    draw_set_colour(make_colour_rgb(180, 180, 200));
    draw_text_ext_transformed(_gw/2, _gh * 0.35 + _ss * 16, "points", 0, _gw, _ls, _ls, 0);

    // Stats
    var _is = _scale * 0.7;
    draw_set_colour(make_colour_rgb(200, 200, 220));
    draw_text_ext_transformed(_gw/2, _gh * 0.53, string(poses_completed) + " poses completed", 0, _gw, _is * 0.8, _is * 0.8, 0);

    if (points > run_score) {
        draw_set_colour(make_colour_rgb(160, 160, 180));
        draw_text_ext_transformed(_gw/2, _gh * 0.6, "Personal Best: " + string(points), 0, _gw, _is * 0.8, _is * 0.8, 0);
    }
    else if (points == run_score && run_score > 0) {
        draw_set_colour(gold_col);
        draw_text_ext_transformed(_gw/2, _gh * 0.6, "NEW BEST!", 0, _gw, _is, _is, 0);
    }

    var _blink = 0.4 + sin(current_time * 0.004) * 0.6;
    draw_set_alpha(max(0, _blink));
    draw_set_colour(c_white);
    draw_text_ext_transformed(_gw/2, _gh * 0.82, "Tap to Retry", 0, _gw, _is * 0.9, _is * 0.9, 0);
    draw_set_alpha(1);
}

// Reset
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
