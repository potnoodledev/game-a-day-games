/// Draw_64 — GUI layer rendering

var _w = window_width;
var _h = window_height;
if (_w == 0 || _h == 0) exit;

var _fscale = max(1.0, _h * 0.0015);
var _cos_a = cos(beam_angle);
var _sin_a = sin(beam_angle);
// "Up" from beam surface
var _ux = _sin_a;
var _uy = -_cos_a;

// =============================
// BACKGROUND
// =============================
draw_clear(make_color_rgb(18, 20, 35));

// Subtle gradient overlay
draw_set_alpha(0.3);
draw_set_color(make_color_rgb(25, 35, 65));
draw_rectangle(0, 0, _w, _h * 0.5, false);
draw_set_alpha(1.0);

// =============================
// TILT INDICATOR (behind fulcrum)
// =============================
var _gauge_r = fulcrum_h + beam_thickness;
var _segments = 30;
for (var _s = 0; _s < _segments; _s++) {
    var _frac = _s / _segments;
    var _ang = -pi * 0.5 + _frac * pi;  // -90 to +90 deg
    var _norm_pos = abs(_frac - 0.5) * 2;  // 0 at center, 1 at edges

    // Color: green center, yellow mid, red edges
    var _r, _g, _b;
    if (_norm_pos < 0.4) {
        _r = floor(lerp(40, 200, _norm_pos / 0.4));
        _g = floor(lerp(180, 200, _norm_pos / 0.4));
        _b = 40;
    } else {
        _r = floor(lerp(200, 220, (_norm_pos - 0.4) / 0.6));
        _g = floor(lerp(200, 40, (_norm_pos - 0.4) / 0.6));
        _b = 40;
    }

    draw_set_color(make_color_rgb(_r, _g, _b));
    draw_set_alpha(0.2);
    var _a1 = _ang;
    var _a2 = _ang + pi / _segments;
    var _x1 = beam_cx + cos(_a1) * _gauge_r * 0.3;
    var _y1 = beam_cy - sin(_a1) * _gauge_r * 0.3;
    var _x2 = beam_cx + cos(_a1) * _gauge_r;
    var _y2 = beam_cy - sin(_a1) * _gauge_r;
    var _x3 = beam_cx + cos(_a2) * _gauge_r;
    var _y3 = beam_cy - sin(_a2) * _gauge_r;
    draw_triangle(_x1, _y1, _x2, _y2, _x3, _y3, false);
}
draw_set_alpha(1.0);

// Tilt needle
var _needle_ang = pi * 0.5 - beam_angle;  // map beam angle to gauge
var _nx = beam_cx + cos(_needle_ang) * _gauge_r * 0.95;
var _ny = beam_cy - sin(_needle_ang) * _gauge_r * 0.95;
draw_set_color(c_white);
draw_line_width(beam_cx, beam_cy, _nx, _ny, max(2, _fscale));

// =============================
// FULCRUM
// =============================
draw_set_color(make_color_rgb(70, 70, 85));
draw_triangle(
    beam_cx, beam_cy,
    beam_cx - beam_thickness * 1.5, beam_cy + fulcrum_h,
    beam_cx + beam_thickness * 1.5, beam_cy + fulcrum_h,
    false
);

// =============================
// BEAM
// =============================
var _bh = beam_thickness * 0.5;
var _bx1 = beam_cx - beam_half * _cos_a + _ux * _bh;
var _by1 = beam_cy - beam_half * _sin_a + _uy * _bh;
var _bx2 = beam_cx + beam_half * _cos_a + _ux * _bh;
var _by2 = beam_cy + beam_half * _sin_a + _uy * _bh;
var _bx3 = beam_cx + beam_half * _cos_a - _ux * _bh;
var _by3 = beam_cy + beam_half * _sin_a - _uy * _bh;
var _bx4 = beam_cx - beam_half * _cos_a - _ux * _bh;
var _by4 = beam_cy - beam_half * _sin_a - _uy * _bh;

// Beam shadow
draw_set_color(make_color_rgb(10, 10, 18));
draw_set_alpha(0.4);
draw_triangle(_bx1 + 3, _by1 + 5, _bx2 + 3, _by2 + 5, _bx3 + 3, _by3 + 5, false);
draw_triangle(_bx1 + 3, _by1 + 5, _bx3 + 3, _by3 + 5, _bx4 + 3, _by4 + 5, false);
draw_set_alpha(1.0);

// Beam body
var _beam_col = make_color_rgb(139, 105, 30);
if (abs(beam_angle) > warning_angle) {
    // Pulse red when dangerous
    var _danger = (abs(beam_angle) - warning_angle) / (max_angle - warning_angle);
    _danger = clamp(_danger, 0, 1);
    var _pulse = 0.5 + sin(current_time * 0.008) * 0.5;
    _beam_col = merge_color(_beam_col, make_color_rgb(200, 50, 30), _danger * _pulse);
}
draw_set_color(_beam_col);
draw_triangle(_bx1, _by1, _bx2, _by2, _bx3, _by3, false);
draw_triangle(_bx1, _by1, _bx3, _by3, _bx4, _by4, false);

// Beam edge highlight (top)
draw_set_color(make_color_rgb(170, 135, 50));
draw_line_width(_bx1, _by1, _bx2, _by2, max(1, _fscale * 0.5));

// End caps
draw_set_color(make_color_rgb(110, 85, 25));
var _cap = beam_thickness * 0.35;
draw_circle(beam_cx - beam_half * _cos_a, beam_cy - beam_half * _sin_a, _cap, false);
draw_circle(beam_cx + beam_half * _cos_a, beam_cy + beam_half * _sin_a, _cap, false);

// =============================
// SIDE BALANCE INDICATORS
// =============================
var _left_weight = 0;
var _right_weight = 0;
var _left_torque = 0;
var _right_torque = 0;
var _left_count = 0;
var _right_count = 0;
for (var _si = 0; _si < array_length(objects_on_beam); _si++) {
    var _sobj = objects_on_beam[_si];
    if (_sobj.x_off < 0) {
        _left_weight += _sobj.weight;
        _left_torque += _sobj.weight * abs(_sobj.x_off);
        _left_count++;
    } else {
        _right_weight += _sobj.weight;
        _right_torque += _sobj.weight * abs(_sobj.x_off);
        _right_count++;
    }
}

// Left side panel
var _panel_w = _fscale * 70;
var _panel_h = _fscale * 65;
var _lpx = beam_cx - beam_half - _panel_w - _fscale * 10;
var _rpx = beam_cx + beam_half + _fscale * 10;
var _ppy = beam_cy - _panel_h * 0.5;

// Left panel bg
draw_set_color(make_color_rgb(40, 50, 80));
draw_set_alpha(0.5);
draw_roundrect(_lpx, _ppy, _lpx + _panel_w, _ppy + _panel_h, false);
draw_set_alpha(1.0);

// Left labels
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_set_color(make_color_rgb(120, 160, 255));
draw_text_transformed(_lpx + _panel_w * 0.5, _ppy + _fscale * 3, "LEFT", _fscale * 0.55, _fscale * 0.55, 0);

draw_set_color(c_white);
var _lw_str = string(round(_left_weight * 10) / 10);
draw_text_transformed(_lpx + _panel_w * 0.5, _ppy + _fscale * 16, _lw_str, _fscale * 1.0, _fscale * 1.0, 0);

draw_set_color(make_color_rgb(160, 160, 180));
draw_text_transformed(_lpx + _panel_w * 0.5, _ppy + _fscale * 34, "torque", _fscale * 0.45, _fscale * 0.45, 0);
var _lt_str = string(round(_left_torque * 10) / 10);
draw_set_color(make_color_rgb(200, 200, 220));
draw_text_transformed(_lpx + _panel_w * 0.5, _ppy + _fscale * 44, _lt_str, _fscale * 0.75, _fscale * 0.75, 0);

// Right panel bg
draw_set_color(make_color_rgb(40, 50, 80));
draw_set_alpha(0.5);
draw_roundrect(_rpx, _ppy, _rpx + _panel_w, _ppy + _panel_h, false);
draw_set_alpha(1.0);

// Right labels
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_set_color(make_color_rgb(255, 160, 120));
draw_text_transformed(_rpx + _panel_w * 0.5, _ppy + _fscale * 3, "RIGHT", _fscale * 0.55, _fscale * 0.55, 0);

draw_set_color(c_white);
var _rw_str = string(round(_right_weight * 10) / 10);
draw_text_transformed(_rpx + _panel_w * 0.5, _ppy + _fscale * 16, _rw_str, _fscale * 1.0, _fscale * 1.0, 0);

draw_set_color(make_color_rgb(160, 160, 180));
draw_text_transformed(_rpx + _panel_w * 0.5, _ppy + _fscale * 34, "torque", _fscale * 0.45, _fscale * 0.45, 0);
var _rt_str = string(round(_right_torque * 10) / 10);
draw_set_color(make_color_rgb(200, 200, 220));
draw_text_transformed(_rpx + _panel_w * 0.5, _ppy + _fscale * 44, _rt_str, _fscale * 0.75, _fscale * 0.75, 0);

// Balance bar between panels (visual diff)
var _bar_y = _ppy + _panel_h + _fscale * 8;
var _bar_w = beam_half * 1.5;
var _bar_h = _fscale * 6;
var _bar_x = beam_cx - _bar_w * 0.5;

// Bar background
draw_set_color(make_color_rgb(30, 35, 55));
draw_set_alpha(0.6);
draw_roundrect(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);
draw_set_alpha(1.0);

// Balance indicator (center = balanced)
var _total_torque = _left_torque + _right_torque;
var _balance = 0;
if (_total_torque > 0) {
    _balance = (_right_torque - _left_torque) / max(_total_torque, 0.01);
}
_balance = clamp(_balance, -1, 1);
var _ind_x = beam_cx + _balance * _bar_w * 0.45;

// Color based on balance: green when centered, yellow/red when skewed
var _bal_abs = abs(_balance);
var _bal_col = make_color_rgb(80, 220, 80);
if (_bal_abs > 0.3) _bal_col = make_color_rgb(220, 200, 60);
if (_bal_abs > 0.6) _bal_col = make_color_rgb(220, 80, 60);

draw_set_color(_bal_col);
draw_circle(_ind_x, _bar_y + _bar_h * 0.5, _fscale * 5, false);

// Center tick mark
draw_set_color(make_color_rgb(100, 100, 120));
draw_line_width(beam_cx, _bar_y - 1, beam_cx, _bar_y + _bar_h + 1, 1);

// =============================
// OBJECTS ON BEAM
// =============================
var _us = unit_size;
for (var _i = 0; _i < array_length(objects_on_beam); _i++) {
    var _obj = objects_on_beam[_i];
    var _d = _obj.x_off * beam_half;
    var _ohw = _us * obj_cfg_w_mult[_obj.type_idx] * 0.5;
    var _ohh = _us * obj_cfg_h_mult[_obj.type_idx] * 0.5;

    // Object center on beam surface
    var _ocx = beam_cx + _d * _cos_a + _ux * (_bh + _ohh);
    var _ocy = beam_cy + _d * _sin_a + _uy * (_bh + _ohh);

    // Shadow
    draw_set_color(make_color_rgb(10, 10, 18));
    draw_set_alpha(0.3);
    draw_circle(_ocx + 2, _ocy + 4, _ohw * 0.8, false);
    draw_set_alpha(1.0);

    var _col = obj_colors[obj_cfg_color_idx[_obj.type_idx]];

    if (obj_cfg_label[_obj.type_idx] == "BALL") {
        // Draw circle for balls
        draw_set_color(_col);
        draw_circle(_ocx, _ocy, _ohw, false);
        // Highlight
        draw_set_color(merge_color(_col, c_white, 0.4));
        draw_circle(_ocx - _ohw * 0.2, _ocy - _ohw * 0.2, _ohw * 0.35, false);
    } else {
        // Draw rotated rectangle
        var _ox1 = _ocx - _ohw * _cos_a + _ux * _ohh;
        var _oy1 = _ocy - _ohw * _sin_a + _uy * _ohh;
        var _ox2 = _ocx + _ohw * _cos_a + _ux * _ohh;
        var _oy2 = _ocy + _ohw * _sin_a + _uy * _ohh;
        var _ox3 = _ocx + _ohw * _cos_a - _ux * _ohh;
        var _oy3 = _ocy + _ohw * _sin_a - _uy * _ohh;
        var _ox4 = _ocx - _ohw * _cos_a - _ux * _ohh;
        var _oy4 = _ocy - _ohw * _sin_a - _uy * _ohh;

        draw_set_color(_col);
        draw_triangle(_ox1, _oy1, _ox2, _oy2, _ox3, _oy3, false);
        draw_triangle(_ox1, _oy1, _ox3, _oy3, _ox4, _oy4, false);

        // Top edge highlight
        draw_set_color(merge_color(_col, c_white, 0.3));
        draw_line_width(_ox1, _oy1, _ox2, _oy2, max(1, _fscale * 0.5));
    }

    // Weight label (big and bold)
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    // Shadow
    draw_set_color(c_black);
    draw_set_alpha(0.5);
    var _wt_text = string(round(_obj.weight * 10) / 10);
    draw_text_transformed(_ocx + 1, _ocy + 1, _wt_text, _fscale * 1.1, _fscale * 1.1, 0);
    draw_set_alpha(1.0);
    // Text
    draw_set_color(c_white);
    draw_text_transformed(_ocx, _ocy, _wt_text, _fscale * 1.1, _fscale * 1.1, 0);
}

// =============================
// DROPPING OBJECT
// =============================
if (drop_active) {
    var _dhw = _us * obj_cfg_w_mult[drop_type_idx] * 0.5;
    var _dhh = _us * obj_cfg_h_mult[drop_type_idx] * 0.5;
    var _dcol = obj_colors[obj_cfg_color_idx[drop_type_idx]];

    // Drop guideline
    draw_set_color(c_white);
    draw_set_alpha(0.15);
    draw_line_width(drop_x, drop_y + _dhh, drop_x, beam_cy, max(1, _fscale * 0.5));
    draw_set_alpha(1.0);

    if (obj_cfg_label[drop_type_idx] == "BALL") {
        draw_set_color(_dcol);
        draw_circle(drop_x, drop_y, _dhw, false);
        draw_set_color(merge_color(_dcol, c_white, 0.4));
        draw_circle(drop_x - _dhw * 0.2, drop_y - _dhw * 0.2, _dhw * 0.35, false);
    } else {
        draw_set_color(_dcol);
        draw_rectangle(drop_x - _dhw, drop_y - _dhh, drop_x + _dhw, drop_y + _dhh, false);
        draw_set_color(merge_color(_dcol, c_white, 0.3));
        draw_line_width(drop_x - _dhw, drop_y - _dhh, drop_x + _dhw, drop_y - _dhh, max(1, _fscale * 0.5));
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_black);
    draw_set_alpha(0.5);
    draw_text_transformed(drop_x + 1, drop_y + 1, string(round(drop_weight * 10) / 10), _fscale * 1.1, _fscale * 1.1, 0);
    draw_set_alpha(1.0);
    draw_set_color(c_white);
    draw_text_transformed(drop_x, drop_y, string(round(drop_weight * 10) / 10), _fscale * 1.1, _fscale * 1.1, 0);
}

// =============================
// FALLING OBJECTS (cosmetic)
// =============================
for (var _i = 0; _i < array_length(falling_objects); _i++) {
    var _fo = falling_objects[_i];
    var _fhw = _us * obj_cfg_w_mult[_fo.type_idx] * 0.5;
    var _fhh = _us * obj_cfg_h_mult[_fo.type_idx] * 0.5;
    var _fcol = obj_colors[obj_cfg_color_idx[_fo.type_idx]];

    var _fa = (1.0 - clamp((_fo.y - beam_cy) / (_h * 0.4), 0, 1)) * 0.7;
    draw_set_alpha(_fa);

    if (obj_cfg_label[_fo.type_idx] == "BALL") {
        draw_set_color(_fcol);
        draw_circle(_fo.x, _fo.y, _fhw, false);
    } else {
        var _fc = cos(_fo.rot);
        var _fs = sin(_fo.rot);
        var _fux = _fs;
        var _fuy = -_fc;

        var _fx1 = _fo.x - _fhw * _fc + _fux * _fhh;
        var _fy1 = _fo.y - _fhw * _fs + _fuy * _fhh;
        var _fx2 = _fo.x + _fhw * _fc + _fux * _fhh;
        var _fy2 = _fo.y + _fhw * _fs + _fuy * _fhh;
        var _fx3 = _fo.x + _fhw * _fc - _fux * _fhh;
        var _fy3 = _fo.y + _fhw * _fs - _fuy * _fhh;
        var _fx4 = _fo.x - _fhw * _fc - _fux * _fhh;
        var _fy4 = _fo.y - _fhw * _fs - _fuy * _fhh;

        draw_set_color(_fcol);
        draw_triangle(_fx1, _fy1, _fx2, _fy2, _fx3, _fy3, false);
        draw_triangle(_fx1, _fy1, _fx3, _fy3, _fx4, _fy4, false);
    }
    draw_set_alpha(1.0);
}

// =============================
// WAVE SHAPES PREVIEW (top)
// =============================
var _remaining = array_length(wave_shapes) - wave_index;
var _show_count = min(5, _remaining);
var _pbox_w = _us * 1.4;
var _pbox_h = _us * 1.4;
var _pbox_gap = _us * 0.3;
var _ptotal_w = _show_count * _pbox_w + max(0, _show_count - 1) * _pbox_gap;
var _pstart_x = (_w - _ptotal_w) * 0.5;
var _pstart_y = _h * 0.03;

// Wave + remaining label
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_set_color(make_color_rgb(255, 220, 80));
draw_text_transformed(_w * 0.5, _pstart_y - _fscale * 12, "WAVE " + string(wave), _fscale * 0.75, _fscale * 0.75, 0);

if (_remaining > 0 && (game_state == 2 || game_state == 1)) {
    for (var _pi = 0; _pi < _show_count; _pi++) {
        var _qi = wave_index + _pi;
        if (_qi >= array_length(wave_shapes)) break;
        var _px = _pstart_x + _pi * (_pbox_w + _pbox_gap) + _pbox_w * 0.5;
        var _py = _pstart_y + _fscale * 8 + _pbox_h * 0.5;
        var _pq = wave_shapes[_qi];

        var _bg_alpha = (_pi == 0) ? 0.25 : 0.1;
        draw_set_color(c_white);
        draw_set_alpha(_bg_alpha);
        draw_roundrect(_px - _pbox_w * 0.5, _py - _pbox_h * 0.5, _px + _pbox_w * 0.5, _py + _pbox_h * 0.5, false);
        draw_set_alpha(1.0);

        if (_pi == 0) {
            draw_set_color(make_color_rgb(255, 220, 80));
            draw_set_alpha(0.6);
            draw_roundrect(_px - _pbox_w * 0.5, _py - _pbox_h * 0.5, _px + _pbox_w * 0.5, _py + _pbox_h * 0.5, true);
            draw_set_alpha(1.0);
        }

        var _pcol = obj_colors[obj_cfg_color_idx[_pq.type_idx]];
        var _pohw = _us * obj_cfg_w_mult[_pq.type_idx] * 0.3;
        var _pohh = _us * obj_cfg_h_mult[_pq.type_idx] * 0.3;

        if (obj_cfg_label[_pq.type_idx] == "BALL") {
            draw_set_color(_pcol);
            draw_circle(_px, _py - _fscale * 2, _pohw, false);
        } else {
            draw_set_color(_pcol);
            draw_rectangle(_px - _pohw, _py - _pohh - _fscale * 2, _px + _pohw, _py + _pohh - _fscale * 2, false);
        }

        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        draw_set_color(c_white);
        draw_text_transformed(_px, _py + _pohh, string(round(_pq.weight * 10) / 10), _fscale * 0.75, _fscale * 0.75, 0);
    }

    // Show "+N more" if there are more shapes
    if (_remaining > _show_count) {
        var _more_x = _pstart_x + _show_count * (_pbox_w + _pbox_gap) + _fscale * 5;
        var _more_y = _pstart_y + _fscale * 8 + _pbox_h * 0.5;
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(160, 160, 180));
        draw_text_transformed(_more_x, _more_y, "+" + string(_remaining - _show_count), _fscale * 0.7, _fscale * 0.7, 0);
    }
}

// =============================
// HUD
// =============================
var _hud_y = _h - _fscale * 50;

// Score
draw_set_halign(fa_left);
draw_set_valign(fa_bottom);
draw_set_color(c_white);
draw_text_transformed(_fscale * 12, _hud_y, "SCORE", _fscale * 0.65, _fscale * 0.65, 0);
draw_text_transformed(_fscale * 12, _hud_y + _fscale * 18, string(points), _fscale * 1.1, _fscale * 1.1, 0);

// Multiplier
if (multiplier > 1) {
    draw_set_color(make_color_rgb(255, 220, 80));
    draw_text_transformed(_fscale * 12, _hud_y + _fscale * 42, "x" + string(multiplier), _fscale * 0.9, _fscale * 0.9, 0);
}

// Combo
if (combo > 0) {
    draw_set_halign(fa_center);
    draw_set_color(make_color_rgb(150, 200, 255));
    draw_text_transformed(_w * 0.5, _hud_y + _fscale * 18, "COMBO " + string(combo), _fscale * 0.7, _fscale * 0.7, 0);
}

// Wave info (right side)
draw_set_halign(fa_right);
draw_set_valign(fa_bottom);
draw_set_color(make_color_rgb(180, 180, 200));
draw_text_transformed(_w - _fscale * 12, _hud_y, "WAVE", _fscale * 0.65, _fscale * 0.65, 0);
draw_set_color(make_color_rgb(255, 220, 80));
draw_text_transformed(_w - _fscale * 12, _hud_y + _fscale * 18, string(wave), _fscale * 1.1, _fscale * 1.1, 0);

// Shapes remaining
var _rem = array_length(wave_shapes) - wave_index;
draw_set_color(make_color_rgb(140, 140, 160));
var _rem_text = string(_rem) + "/" + string(array_length(wave_shapes)) + " left";
draw_text_transformed(_w - _fscale * 12, _hud_y + _fscale * 42, _rem_text, _fscale * 0.55, _fscale * 0.55, 0);

// =============================
// SCORE POPUPS
// =============================
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
for (var _i = 0; _i < array_length(score_popups); _i++) {
    var _sp = score_popups[_i];
    draw_set_alpha(clamp(_sp.alpha, 0, 1));
    if (string_pos("MILESTONE", _sp.text) > 0) {
        draw_set_color(make_color_rgb(255, 220, 80));
        draw_text_transformed(_sp.x, _sp.y, _sp.text, _fscale * 0.9, _fscale * 0.9, 0);
    } else {
        draw_set_color(make_color_rgb(100, 255, 100));
        draw_text_transformed(_sp.x, _sp.y, _sp.text, _fscale * 0.8, _fscale * 0.8, 0);
    }
}
draw_set_alpha(1.0);

// =============================
// WIND INDICATOR
// =============================
if (abs(wind_force) > 0.05) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(150, 200, 255));
    draw_set_alpha(clamp(abs(wind_force) * 0.8, 0, 0.6));
    var _wind_text = (wind_force > 0) ? "WIND >>>" : "<<< WIND";
    draw_text_transformed(_w * 0.5, beam_cy - beam_half * 0.6, _wind_text, _fscale * 0.7, _fscale * 0.7, 0);
    draw_set_alpha(1.0);
}

// =============================
// STATE 1: WAVE INTRO OVERLAY
// =============================
if (game_state == 1) {
    draw_set_alpha(0.5);
    draw_set_color(make_color_rgb(10, 15, 30));
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_set_color(make_color_rgb(255, 220, 80));
    draw_text_transformed(_w * 0.5, _h * 0.28, "WAVE " + string(wave), _fscale * 3.0, _fscale * 3.0, 0);

    draw_set_color(make_color_rgb(180, 200, 220));
    var _shape_count = array_length(wave_shapes);
    draw_text_transformed(_w * 0.5, _h * 0.28 + _fscale * 45, string(_shape_count) + " shapes to balance", _fscale * 1.0, _fscale * 1.0, 0);

    // Show wave features
    var _feat = "";
    if (wave >= 5) _feat = "Wind gusts active!";
    if (wave >= 6) _feat = "Wind gusts + anvils!";
    if (string_length(_feat) > 0) {
        draw_set_color(make_color_rgb(255, 150, 100));
        draw_text_transformed(_w * 0.5, _h * 0.28 + _fscale * 70, _feat, _fscale * 0.8, _fscale * 0.8, 0);
    }

    // Countdown dot
    draw_set_color(make_color_rgb(150, 200, 255));
    var _dots = ceil(intro_timer / 40);
    var _dot_str = "";
    for (var _di = 0; _di < _dots; _di++) _dot_str += ". ";
    draw_text_transformed(_w * 0.5, _h * 0.65, _dot_str, _fscale * 1.5, _fscale * 1.5, 0);
}

// =============================
// STATE 3: HOLD COUNTDOWN
// =============================
if (game_state == 3) {
    // Big countdown timer
    var _secs_left = ceil(hold_timer / 60);
    var _hold_frac = hold_timer / hold_duration;

    // Progress bar at top
    var _pbar_h = _fscale * 8;
    draw_set_color(make_color_rgb(30, 35, 55));
    draw_rectangle(0, 0, _w, _pbar_h, false);

    var _pcol = make_color_rgb(80, 220, 120);
    if (_hold_frac < 0.5) _pcol = make_color_rgb(220, 200, 60);
    if (_hold_frac < 0.25) _pcol = make_color_rgb(220, 80, 60);
    draw_set_color(_pcol);
    draw_rectangle(0, 0, _w * _hold_frac, _pbar_h, false);

    // "HOLD STEADY" text
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(255, 240, 200));
    var _hold_pulse = 0.7 + sin(current_time * 0.006) * 0.3;
    draw_set_alpha(_hold_pulse);
    draw_text_transformed(_w * 0.5, _h * 0.2, "HOLD STEADY!", _fscale * 2.0, _fscale * 2.0, 0);
    draw_set_alpha(1.0);

    // Countdown number
    draw_set_color(c_white);
    draw_text_transformed(_w * 0.5, _h * 0.2 + _fscale * 35, string(_secs_left), _fscale * 2.5, _fscale * 2.5, 0);
}

// =============================
// STATE 4: WAVE CLEAR
// =============================
if (game_state == 4) {
    draw_set_alpha(0.3);
    draw_set_color(make_color_rgb(20, 60, 30));
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_set_color(make_color_rgb(80, 255, 120));
    draw_text_transformed(_w * 0.5, _h * 0.3, "WAVE CLEAR!", _fscale * 2.8, _fscale * 2.8, 0);

    draw_set_color(make_color_rgb(255, 220, 80));
    draw_text_transformed(_w * 0.5, _h * 0.3 + _fscale * 50, "+" + string(50 * wave) + " bonus", _fscale * 1.3, _fscale * 1.3, 0);
}

// =============================
// STATE 5: GAME OVER
// =============================
if (game_state == 5) {
    if (tip_timer < 0) {
        draw_set_alpha(0.7);
        draw_set_color(make_color_rgb(10, 10, 20));
        draw_rectangle(0, 0, _w, _h, false);
        draw_set_alpha(1.0);

        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);

        draw_set_color(make_color_rgb(255, 80, 60));
        draw_text_transformed(_w * 0.5, _h * 0.25, "GAME OVER", _fscale * 2.8, _fscale * 2.8, 0);

        draw_set_color(c_white);
        draw_text_transformed(_w * 0.5, _h * 0.25 + _fscale * 50, "Score: " + string(points), _fscale * 1.5, _fscale * 1.5, 0);

        draw_set_color(make_color_rgb(180, 180, 200));
        draw_text_transformed(_w * 0.5, _h * 0.25 + _fscale * 80, "Reached Wave " + string(wave), _fscale * 1.0, _fscale * 1.0, 0);

        draw_set_color(make_color_rgb(140, 160, 180));
        draw_text_transformed(_w * 0.5, _h * 0.25 + _fscale * 105, string(total_placed) + " objects placed", _fscale * 0.8, _fscale * 0.8, 0);

        draw_set_color(make_color_rgb(150, 200, 255));
        var _pulse = 0.6 + sin(current_time * 0.004) * 0.4;
        draw_set_alpha(_pulse);
        draw_text_transformed(_w * 0.5, _h * 0.7, "Tap to restart", _fscale * 1.1, _fscale * 1.1, 0);
        draw_set_alpha(1.0);
    } else {
        // Brief tipping animation overlay
        draw_set_alpha(0.3);
        draw_set_color(make_color_rgb(200, 30, 30));
        draw_rectangle(0, 0, _w, _h, false);
        draw_set_alpha(1.0);

        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(255, 80, 60));
        draw_text_transformed(_w * 0.5, _h * 0.3, "TIPPED!", _fscale * 2.5, _fscale * 2.5, 0);
    }
}

// Reset draw state
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1.0);
