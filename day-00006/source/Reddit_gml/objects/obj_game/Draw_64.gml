
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();

// === Screen shake offset ===
var _shake_x = 0;
var _shake_y = 0;
if (shake_amount > 0) {
    _shake_x = irandom_range(-shake_amount, shake_amount);
    _shake_y = irandom_range(-shake_amount, shake_amount);
    shake_amount -= 0.5;
    if (shake_amount < 0) shake_amount = 0;
}

// === Background (warm dark brown) ===
draw_set_colour(make_colour_rgb(42, 32, 28));
draw_rectangle(0, 0, _gw, _gh, false);

// === Layout constants (must match Step_0) ===
var _pad = _gw * 0.03;
var _hud_h = _gh * 0.10;
var _queue_w = _gw * 0.12;
var _queue_x = _pad;
var _table_left = _pad + _queue_w + _pad;
var _table_area_top = _hud_h + _pad;
var _table_area_bottom = _gh * 0.75;
var _table_area_h = _table_area_bottom - _table_area_top;
var _table_w = (_gw - _table_left - _pad) / 3 - _pad;
var _table_h = (_table_area_h - _pad) / 2;
var _scale = max(1, _gh / 600);

// === HUD (dark walnut) ===
draw_set_colour(make_colour_rgb(55, 40, 35));
draw_rectangle(0 + _shake_x, 0 + _shake_y, _gw + _shake_x, _hud_h + _shake_y, false);

draw_set_font(fnt_default);
var _hud_y = _hud_h * 0.5 + _shake_y;

// Score
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour(make_colour_rgb(255, 230, 190));
draw_text_ext_transformed(_pad + _shake_x, _hud_y, $"Score: {points}", 0, 400, _scale, _scale, 0);

// Lives (noodle bowls instead of hearts)
draw_set_halign(fa_right);
var _heart_r = _scale * 5;
for (var _i = 0; _i < max_lives; _i++) {
    var _hx = _gw - _pad - _i * (_heart_r * 3) + _shake_x;
    if (_i < lives) {
        draw_set_colour(make_colour_rgb(255, 100, 70));
    } else {
        draw_set_colour(make_colour_rgb(70, 55, 48));
    }
    draw_circle(_hx, _hud_y, _heart_r, false);
}

// Wave
draw_set_halign(fa_center);
draw_set_colour(make_colour_rgb(200, 180, 155));
draw_text_ext_transformed(_gw * 0.5 + _shake_x, _hud_y, $"Wave {wave}  ({wave_spawned}/{wave_total})", 0, 400, _scale * 0.8, _scale * 0.8, 0);

// === Combo indicator with fire effect ===
if (combo >= 3 && game_state == 1) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);

    // Fire glow particles behind text
    var _combo_x = _gw * 0.5 + _shake_x;
    var _combo_y = _hud_h + 2 + _shake_y;
    var _t = current_time * 0.01;
    for (var _fi = 0; _fi < 5; _fi++) {
        var _fx = _combo_x + sin(_t + _fi * 1.3) * _scale * 12;
        var _fy = _combo_y - abs(sin(_t * 1.5 + _fi * 0.9)) * _scale * 8;
        var _fr = _scale * (3 + sin(_t + _fi) * 1.5);
        draw_set_alpha(0.5);
        if (_fi mod 2 == 0) {
            draw_set_colour(make_colour_rgb(255, 120, 30));
        } else {
            draw_set_colour(make_colour_rgb(255, 200, 50));
        }
        draw_circle(_fx, _fy, _fr, false);
    }
    draw_set_alpha(1);

    draw_set_colour(make_colour_rgb(255, 200, 50));
    draw_text_ext_transformed(_combo_x, _combo_y, $"Combo x{combo}!", 0, 300, _scale * 0.9, _scale * 0.9, 0);
}

// === Queue Strip (warm wood panel) ===
draw_set_colour(make_colour_rgb(52, 40, 35));
draw_roundrect(_queue_x + _shake_x, _table_area_top + _shake_y, _queue_x + _queue_w + _shake_x, _table_area_bottom + _shake_y, false);
draw_set_colour(make_colour_rgb(85, 65, 55));
draw_roundrect(_queue_x + _shake_x, _table_area_top + _shake_y, _queue_x + _queue_w + _shake_x, _table_area_bottom + _shake_y, true);

// "QUEUE" label
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_set_colour(make_colour_rgb(160, 140, 115));
draw_text_ext_transformed(_queue_x + _queue_w * 0.5 + _shake_x, _table_area_top + 4 + _shake_y, "QUEUE", 0, _queue_w, _scale * 0.55, _scale * 0.55, 0);

var _queue_slot_h = _table_area_h / queue_max;

for (var _i = 0; _i < queue_max; _i++) {
    var _qy = _table_area_top + _i * _queue_slot_h;
    var _slot_inner_pad = 3;
    var _qsx = _queue_x + _shake_x;
    var _qsy = _qy + _shake_y;

    if (_i < queue_count) {
        var _patience_ratio = queue_patience[_i] / max(1, queue_max_patience[_i]);

        if (_patience_ratio < 0.25) {
            draw_set_colour(make_colour_rgb(90, 35, 30));
        } else {
            draw_set_colour(make_colour_rgb(60, 48, 42));
        }
        draw_roundrect(_qsx + _slot_inner_pad, _qsy + _slot_inner_pad,
                       _qsx + _queue_w - _slot_inner_pad, _qsy + _queue_slot_h - _slot_inner_pad, false);

        if (selected_queue == _i) {
            draw_set_colour(make_colour_rgb(255, 200, 50));
            draw_roundrect(_qsx + _slot_inner_pad, _qsy + _slot_inner_pad,
                           _qsx + _queue_w - _slot_inner_pad, _qsy + _queue_slot_h - _slot_inner_pad, true);
            draw_roundrect(_qsx + _slot_inner_pad + 1, _qsy + _slot_inner_pad + 1,
                           _qsx + _queue_w - _slot_inner_pad - 1, _qsy + _queue_slot_h - _slot_inner_pad - 1, true);
        }

        // Avatar
        var _acx = _qsx + _queue_w * 0.5;
        var _acy = _qsy + _queue_slot_h * 0.35;
        var _ar = min(_queue_w, _queue_slot_h) * 0.25;
        draw_avatar(_acx, _acy, _ar, queue_avatar[_i]);

        // Food icon (noodle drawing instead of dot)
        var _food_r = _ar * 0.45;
        draw_food(_acx, _acy + _ar * 1.0, _food_r, queue_food[_i]);

        // Mini patience bar
        var _bar_w = _queue_w * 0.7;
        var _bar_h = max(3, _queue_slot_h * 0.06);
        var _bar_x = _qsx + (_queue_w - _bar_w) * 0.5;
        var _bar_y = _qsy + _queue_slot_h - _slot_inner_pad - _bar_h - 4;

        draw_set_colour(make_colour_rgb(30, 22, 18));
        draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);

        if (_patience_ratio > 0.6) draw_set_colour(make_colour_rgb(80, 200, 80));
        else if (_patience_ratio > 0.3) draw_set_colour(make_colour_rgb(220, 180, 50));
        else draw_set_colour(make_colour_rgb(220, 50, 50));
        draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * _patience_ratio, _bar_y + _bar_h, false);
    } else {
        draw_set_colour(make_colour_rgb(45, 35, 30));
        draw_roundrect(_qsx + _slot_inner_pad, _qsy + _slot_inner_pad,
                       _qsx + _queue_w - _slot_inner_pad, _qsy + _queue_slot_h - _slot_inner_pad, false);
    }
}

// === 6 Tables (2 rows x 3 cols) ===
for (var _i = 0; _i < 6; _i++) {
    var _col = _i mod 3;
    var _row = _i div 3;
    var _tx = _table_left + _col * (_table_w + _pad) + _shake_x;
    var _ty = _table_area_top + _row * (_table_h + _pad) + _shake_y;
    var _cx = _tx + _table_w * 0.5;
    var _cy = _ty + _table_h * 0.5;

    // --- Locked table ---
    if (_i >= tables_unlocked) {
        draw_set_colour(make_colour_rgb(35, 28, 24));
        draw_roundrect(_tx, _ty, _tx + _table_w, _ty + _table_h, false);
        draw_set_colour(make_colour_rgb(58, 48, 42));
        draw_roundrect(_tx, _ty, _tx + _table_w, _ty + _table_h, true);

        var _lock_r = min(_table_w, _table_h) * 0.1;
        draw_set_colour(make_colour_rgb(80, 65, 55));
        draw_rectangle(_cx - _lock_r, _cy - _lock_r * 0.2, _cx + _lock_r, _cy + _lock_r * 1.2, false);
        draw_circle(_cx, _cy - _lock_r * 0.2, _lock_r * 0.7, true);

        var _unlock_cost = 20 * (_i + 1);
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        draw_set_colour(make_colour_rgb(120, 100, 80));
        draw_text_ext_transformed(_cx, _cy + _lock_r * 1.6, $"{_unlock_cost} pts", 0, _table_w, _scale * 0.6, _scale * 0.6, 0);

        continue;
    }

    // --- Unlocked table: warm wood surface ---
    draw_set_colour(make_colour_rgb(65, 50, 40));
    draw_roundrect(_tx, _ty, _tx + _table_w, _ty + _table_h, false);
    draw_set_colour(make_colour_rgb(95, 75, 60));
    draw_roundrect(_tx, _ty, _tx + _table_w, _ty + _table_h, true);

    // Table number label
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(make_colour_rgb(110, 90, 70));
    draw_text_ext_transformed(_tx + 4, _ty + 2, $"T{_i + 1}", 0, 50, _scale * 0.5, _scale * 0.5, 0);

    // --- Draw 2x2 seat grid ---
    var _seat_w = _table_w * 0.5;
    var _seat_h = _table_h * 0.5;
    var _seat_pad = 2;

    for (var _si = 0; _si < 4; _si++) {
        var _sc = _si mod 2;
        var _sr = _si div 2;
        var _sx = _tx + _sc * _seat_w;
        var _sy = _ty + _sr * _seat_h;
        var _scx = _sx + _seat_w * 0.5;
        var _scy = _sy + _seat_h * 0.5;

        // --- Locked seat ---
        if (_si >= table_seats[_i]) {
            draw_set_colour(make_colour_rgb(32, 25, 22));
            draw_rectangle(_sx + _seat_pad, _sy + _seat_pad,
                           _sx + _seat_w - _seat_pad, _sy + _seat_h - _seat_pad, false);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(make_colour_rgb(55, 45, 38));
            draw_text_ext_transformed(_scx, _scy, "-", 0, 50, _scale * 0.6, _scale * 0.6, 0);
            continue;
        }

        var _st = table_state[_i][_si];

        // --- Empty unlocked seat ---
        if (_st == 0) {
            if (selected_queue >= 0) {
                draw_set_colour(make_colour_rgb(50, 62, 42));
            } else {
                draw_set_colour(make_colour_rgb(55, 44, 38));
            }
            draw_rectangle(_sx + _seat_pad, _sy + _seat_pad,
                           _sx + _seat_w - _seat_pad, _sy + _seat_h - _seat_pad, false);
            continue;
        }

        // --- Occupied seat background ---
        var _bg = make_colour_rgb(60, 48, 42);
        if (_st == 1) _bg = make_colour_rgb(68, 55, 50);
        else if (_st == 4) _bg = make_colour_rgb(58, 70, 45);
        draw_set_colour(_bg);
        draw_rectangle(_sx + _seat_pad, _sy + _seat_pad,
                       _sx + _seat_w - _seat_pad, _sy + _seat_h - _seat_pad, false);

        // Avatar (top half of quadrant)
        var _icon_r = min(_seat_w, _seat_h) * 0.22;
        var _avatar_cy = _scy - _icon_r * 0.5;
        draw_avatar(_scx, _avatar_cy, _icon_r * 0.65, table_avatar[_i][_si]);

        // State icon (bottom half)
        var _icon_cy = _scy + _icon_r * 0.7;
        var _state_r = _icon_r * 0.5;

        if (_st == 1) {
            // Waiting — food icon with "!"
            draw_food(_scx, _icon_cy, _state_r, table_food[_i][_si]);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(c_white);
            draw_text_ext_transformed(_scx + _state_r * 0.9, _icon_cy - _state_r * 0.8, "!", 0, 50, _scale * 0.55, _scale * 0.55, 0);
        }
        else if (_st == 2) {
            // In kitchen — grey icon
            draw_set_colour(make_colour_rgb(100, 85, 75));
            draw_circle(_scx, _icon_cy, _state_r, false);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(make_colour_rgb(180, 165, 150));
            draw_text_ext_transformed(_scx, _icon_cy, "..", 0, 80, _scale * 0.5, _scale * 0.5, 0);
        }
        else if (_st == 3) {
            // Eating — food icon with "~"
            draw_food(_scx, _icon_cy, _state_r, table_food[_i][_si]);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(c_white);
            draw_text_ext_transformed(_scx, _icon_cy + _state_r * 1.2, "~", 0, 50, _scale * 0.5, _scale * 0.5, 0);
        }
        else if (_st == 4) {
            // Ready to pay — gold coin
            draw_set_colour(make_colour_rgb(255, 215, 0));
            draw_circle(_scx, _icon_cy, _state_r, false);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(make_colour_rgb(160, 130, 0));
            draw_text_ext_transformed(_scx, _icon_cy, "$", 0, 50, _scale * 0.7, _scale * 0.7, 0);
        }

        // Patience bar (states 1 and 2)
        if (_st == 1 || _st == 2) {
            var _bar_w = (_seat_w - _seat_pad * 2) * 0.8;
            var _bar_h = max(2, _seat_h * 0.06);
            var _bar_x = _scx - _bar_w * 0.5;
            var _bar_y = _sy + _seat_h - _seat_pad - _bar_h - 2;

            draw_set_colour(make_colour_rgb(30, 22, 18));
            draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);

            var _ratio = table_patience[_i][_si] / max(1, table_max_patience[_i][_si]);
            if (_ratio > 0.6) draw_set_colour(make_colour_rgb(80, 200, 80));
            else if (_ratio > 0.3) draw_set_colour(make_colour_rgb(220, 180, 50));
            else draw_set_colour(make_colour_rgb(220, 50, 50));
            draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * _ratio, _bar_y + _bar_h, false);
        }
    }
}

// === Kitchen Area (warm steel) ===
var _kit_top = _table_area_bottom + _pad + _shake_y;
var _kit_h = _gh - (_table_area_bottom + _pad) - _pad;
var _kit_w = _gw - _pad * 2;
var _kit_x = _pad + _shake_x;

draw_set_colour(make_colour_rgb(50, 42, 38));
draw_roundrect(_kit_x, _kit_top, _kit_x + _kit_w, _kit_top + _kit_h, false);
draw_set_colour(make_colour_rgb(80, 68, 58));
draw_roundrect(_kit_x, _kit_top, _kit_x + _kit_w, _kit_top + _kit_h, true);

// Kitchen label
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(make_colour_rgb(155, 135, 110));
draw_text_ext_transformed(_kit_x + 8, _kit_top + 4, "KITCHEN", 0, 200, _scale * 0.7, _scale * 0.7, 0);

var _label_h = _scale * 14;
var _slot_gap = _pad;
var _slot_w = (_kit_w - _slot_gap * 3) / 2;
var _slot_h = _kit_h - _label_h - _pad;
var _slot_y = _kit_top + _label_h;

for (var _i = 0; _i < 2; _i++) {
    var _sx = _kit_x + _slot_gap + _i * (_slot_w + _slot_gap);

    draw_set_colour(make_colour_rgb(38, 30, 26));
    draw_roundrect(_sx, _slot_y, _sx + _slot_w, _slot_y + _slot_h, false);

    if (kitchen_occupied[_i]) {
        var _food_col = food_colors[kitchen_food[_i]];

        // Food icon (noodle drawing)
        var _ir = min(_slot_w, _slot_h) * 0.22;
        draw_food(_sx + _slot_w * 0.5, _slot_y + _slot_h * 0.35, _ir, kitchen_food[_i]);

        // Steam wisps (rising puffs)
        var _t = current_time * 0.001;
        var _prog = kitchen_progress[_i] / max(1, kitchen_cook_time[_i]);
        var _steam_count = 2 + floor(_prog * 4);
        var _bowl_top = _slot_y + _slot_h * 0.22;
        var _rise_h = _slot_h * 0.25;
        for (var _wi = 0; _wi < _steam_count; _wi++) {
            // Each wisp has its own phase offset so they stagger
            var _phase = _t * 1.2 + _wi * 3.7;
            // Rise is 0..1, looping — frac gives sawtooth
            var _rise = frac(_phase * 0.15);
            // Gentle horizontal drift as it rises
            var _drift = sin(_phase * 0.8 + _wi) * _slot_w * 0.08;
            var _steam_x = _sx + _slot_w * 0.5 + _drift;
            var _steam_y = _bowl_top - _rise * _rise_h;
            // Fade out as it rises, grow slightly
            var _alpha = (1.0 - _rise) * (0.2 + _prog * 0.35);
            var _r = _scale * (2.0 + _rise * 2.5);
            draw_set_alpha(_alpha);
            draw_set_colour(make_colour_rgb(210, 205, 195));
            draw_circle(_steam_x, _steam_y, _r, false);
        }
        draw_set_alpha(1);

        // Table+Seat label
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(make_colour_rgb(180, 165, 140));
        draw_text_ext_transformed(_sx + _slot_w * 0.5, _slot_y + _slot_h * 0.6, $"T{kitchen_table[_i] + 1}-S{kitchen_seat[_i] + 1}", 0, 100, _scale * 0.5, _scale * 0.5, 0);

        // Progress bar
        var _pb_x = _sx + _slot_w * 0.1;
        var _pb_w = _slot_w * 0.8;
        var _pb_y = _slot_y + _slot_h * 0.75;
        var _pb_h = max(4, _slot_h * 0.12);

        draw_set_colour(make_colour_rgb(25, 20, 16));
        draw_rectangle(_pb_x, _pb_y, _pb_x + _pb_w, _pb_y + _pb_h, false);

        draw_set_colour(_food_col);
        draw_rectangle(_pb_x, _pb_y, _pb_x + _pb_w * _prog, _pb_y + _pb_h, false);
    }
    else {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(make_colour_rgb(65, 55, 48));
        draw_text_ext_transformed(_sx + _slot_w * 0.5, _slot_y + _slot_h * 0.5, "Empty", 0, _slot_w, _scale * 0.7, _scale * 0.7, 0);
    }
}

// === Floating text particles ===
var _fx_ss = max(1, _gh / 400);
for (var _i = 0; _i < min(fx_count, fx_max); _i++) {
    if (fx_life[_i] > 0) {
        var _progress = 1.0 - (fx_life[_i] / fx_max_life[_i]);
        var _alpha = 1.0 - _progress;
        var _rise = _progress * _gh * 0.06;

        draw_set_alpha(_alpha);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(fx_col[_i]);
        draw_text_ext_transformed(fx_x[_i] + _shake_x, fx_y[_i] - _rise + _shake_y, fx_text[_i], 0, 200, _fx_ss * 1.2, _fx_ss * 1.2, 0);

        fx_life[_i]--;
    }
}
draw_set_alpha(1);

// === TITLE OVERLAY ===
if (game_state == 0) {
    draw_set_alpha(0.88);
    draw_set_colour(make_colour_rgb(25, 18, 14));
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    var _ts = max(2.5, _gh / 220);
    draw_set_colour(make_colour_rgb(255, 180, 60));
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.28, "NOODLE RUSH", 0, _gw, _ts, _ts, 0);

    var _ss = max(1, _gh / 500);
    draw_set_colour(make_colour_rgb(200, 180, 155));
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.42, "Customers line up at the door.", 0, _gw * 0.9, _ss, _ss, 0);
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.50, "Tap a customer, then tap an empty seat!", 0, _gw * 0.9, _ss, _ss, 0);
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.58, "Tap orders to cook, tap coins to collect.", 0, _gw * 0.9, _ss, _ss, 0);

    // Decorative food icons on title
    var _dr = _gh * 0.04;
    draw_food(_gw * 0.2, _gh * 0.7, _dr, 0);
    draw_food(_gw * 0.4, _gh * 0.72, _dr, 1);
    draw_food(_gw * 0.6, _gh * 0.72, _dr, 2);
    draw_food(_gw * 0.8, _gh * 0.7, _dr, 3);

    draw_set_colour(c_white);
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.84, "Tap to Start", 0, _gw, _ss * 1.3, _ss * 1.3, 0);
}

// === WAVE SUMMARY OVERLAY ===
if (game_state == 3) {
    draw_set_alpha(0.88);
    draw_set_colour(make_colour_rgb(25, 18, 14));
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Title (18%)
    var _ws = max(2.2, _gh / 250);
    draw_set_colour(make_colour_rgb(255, 215, 0));
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.18, $"WAVE {wave} COMPLETE!", 0, _gw, _ws, _ws, 0);

    var _ss = max(1, _gh / 500);
    var _wave_earnings = points - wave_points_start;

    // Served/Lost (30%)
    draw_set_colour(make_colour_rgb(255, 230, 190));
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.30, $"Served: {wave_served}  |  Lost: {wave_lost}", 0, _gw, _ss * 1.1, _ss * 1.1, 0);

    // Tips earned (38%)
    draw_set_colour(make_colour_rgb(255, 215, 0));
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.38, $"Tips earned: +{_wave_earnings}", 0, _gw, _ss * 1.1, _ss * 1.1, 0);

    // Lives (45%)
    draw_set_colour(make_colour_rgb(200, 180, 155));
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.45, $"Lives: {lives}/{max_lives}", 0, _gw, _ss, _ss, 0);

    // Buy table button (53%)
    if (tables_unlocked < 6) {
        var _btn_w = _gw * 0.55;
        var _btn_h = _ss * 28;
        var _btn_x = _gw * 0.5 - _btn_w * 0.5;
        var _btn_y = _gh * 0.53 - _btn_h * 0.5;

        if (points >= table_cost) {
            draw_set_colour(make_colour_rgb(160, 130, 30));
            draw_roundrect(_btn_x, _btn_y, _btn_x + _btn_w, _btn_y + _btn_h, false);
            draw_set_colour(make_colour_rgb(255, 215, 0));
            draw_roundrect(_btn_x, _btn_y, _btn_x + _btn_w, _btn_y + _btn_h, true);

            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(c_white);
            draw_text_ext_transformed(_gw * 0.5, _gh * 0.53, $"+ Table: {table_cost} pts", 0, _btn_w, _ss * 1.1, _ss * 1.1, 0);
        } else {
            var _need = table_cost - points;
            draw_set_colour(make_colour_rgb(48, 38, 32));
            draw_roundrect(_btn_x, _btn_y, _btn_x + _btn_w, _btn_y + _btn_h, false);
            draw_set_colour(make_colour_rgb(72, 58, 48));
            draw_roundrect(_btn_x, _btn_y, _btn_x + _btn_w, _btn_y + _btn_h, true);

            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(make_colour_rgb(120, 100, 80));
            draw_text_ext_transformed(_gw * 0.5, _gh * 0.53, $"+ Table: {table_cost} pts (need {_need})", 0, _btn_w, _ss * 0.9, _ss * 0.9, 0);
        }
    }

    // Seat upgrade row (63%)
    var _row_w = _gw * 0.7;
    var _row_x = _gw * 0.5 - _row_w * 0.5;
    var _row_y = _gh * 0.63 - _ss * 14;
    var _row_h = _ss * 28;
    var _box_w = _row_w / 6;

    for (var _ti = 0; _ti < 6; _ti++) {
        var _bx = _row_x + _ti * _box_w;
        var _box_pad = 2;

        if (_ti >= tables_unlocked) {
            draw_set_colour(make_colour_rgb(30, 24, 20));
            draw_roundrect(_bx + _box_pad, _row_y + _box_pad, _bx + _box_w - _box_pad, _row_y + _row_h - _box_pad, false);
            draw_set_colour(make_colour_rgb(48, 38, 32));
            draw_roundrect(_bx + _box_pad, _row_y + _box_pad, _bx + _box_w - _box_pad, _row_y + _row_h - _box_pad, true);
        } else {
            var _cur_seats = table_seats[_ti];
            var _can_buy = (_cur_seats < 4 && points >= 10 * _cur_seats);

            draw_set_colour(make_colour_rgb(48, 38, 32));
            draw_roundrect(_bx + _box_pad, _row_y + _box_pad, _bx + _box_w - _box_pad, _row_y + _row_h - _box_pad, false);

            if (_can_buy) {
                draw_set_colour(make_colour_rgb(255, 215, 0));
            } else {
                draw_set_colour(make_colour_rgb(72, 58, 48));
            }
            draw_roundrect(_bx + _box_pad, _row_y + _box_pad, _bx + _box_w - _box_pad, _row_y + _row_h - _box_pad, true);

            draw_set_halign(fa_center);
            draw_set_valign(fa_top);
            draw_set_colour(make_colour_rgb(140, 120, 95));
            draw_text_ext_transformed(_bx + _box_w * 0.5, _row_y + _box_pad + 1, $"T{_ti + 1}", 0, _box_w, _scale * 0.4, _scale * 0.4, 0);

            var _dot_r = max(2, _ss * 3);
            var _dot_cx = _bx + _box_w * 0.5;
            var _dot_cy = _row_y + _row_h * 0.6;
            var _dot_gap = _dot_r * 1.8;

            for (var _ds = 0; _ds < 4; _ds++) {
                var _dc = _ds mod 2;
                var _dr = _ds div 2;
                var _dx = _dot_cx + (_dc - 0.5) * _dot_gap;
                var _dy = _dot_cy + (_dr - 0.5) * _dot_gap;

                if (_ds < _cur_seats) {
                    draw_set_colour(make_colour_rgb(80, 200, 80));
                } else {
                    draw_set_colour(make_colour_rgb(45, 36, 30));
                }
                draw_circle(_dx, _dy, _dot_r, false);
            }
        }
    }

    // Cost label under seat row (68%)
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_colour(make_colour_rgb(140, 120, 95));
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.68, "Tap table to buy seat", 0, _gw, _ss * 0.7, _ss * 0.7, 0);

    // Tap prompt (80%)
    draw_set_colour(c_white);
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.80, $"Tap to Start Wave {wave + 1}", 0, _gw, _ss * 1.3, _ss * 1.3, 0);
}

// === GAME OVER OVERLAY ===
if (game_state == 2) {
    draw_set_alpha(0.88);
    draw_set_colour(make_colour_rgb(25, 18, 14));
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    var _gs = max(2.2, _gh / 250);
    draw_set_colour(make_colour_rgb(220, 60, 60));
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.28, "GAME OVER", 0, _gw, _gs, _gs, 0);

    var _ps = max(1.5, _gh / 350);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.43, $"Score: {points}", 0, _gw, _ps, _ps, 0);

    var _ds = max(1, _gh / 500);
    draw_set_colour(make_colour_rgb(200, 180, 155));
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.54, $"Served: {customers_served}  |  Wave: {wave}", 0, _gw, _ds, _ds, 0);

    draw_set_colour(c_white);
    draw_text_ext_transformed(_gw * 0.5, _gh * 0.70, "Tap to Retry", 0, _gw, _ds * 1.3, _ds * 1.3, 0);
}
