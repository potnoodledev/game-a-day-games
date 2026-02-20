
var _w = window_width;
var _h = window_height;
if (_w <= 0 || _h <= 0) exit;

var _pad = max(8, _w * 0.03);

// === BACKGROUND ===
draw_set_colour($2e1a1a); // dark blue-gray #1a1a2e
draw_rectangle(0, 0, _w, _h, false);

// Darker panel for order area
draw_set_colour($3e2116); // #16213e
draw_rectangle(_pad * 0.5, order_area_y - 4, _w - _pad * 0.5, order_area_y + order_area_h + 4, false);

// === HUD ===
draw_set_font(fnt_default);
var _hud_scale = max(1.5, min(_w, _h) / 400);

// Score
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour($0fc4f1); // yellow
draw_text_ext_transformed(_pad, hud_h * 0.3, "SCORE: " + string(points), 0, _w, _hud_scale, _hud_scale, 0);

// Level
draw_set_halign(fa_right);
draw_set_colour($ffffff);
draw_text_ext_transformed(_w - _pad, hud_h * 0.3, "LEVEL " + string(level), 0, _w, _hud_scale, _hud_scale, 0);

// Lives (hearts)
draw_set_halign(fa_left);
draw_set_colour($3c4ce7); // red
var _heart_text = "";
var _li = 0;
while (_li < lives) {
    _heart_text += "* ";
    _li += 1;
}
draw_text_ext_transformed(_pad, hud_h * 0.7, "LIVES: " + _heart_text, 0, _w, _hud_scale * 0.8, _hud_scale * 0.8, 0);

// Combo
if (combo > 1) {
    draw_set_halign(fa_right);
    draw_set_colour($71cc2e); // green
    draw_text_ext_transformed(_w - _pad, hud_h * 0.7, "COMBO x" + string(combo), 0, _w, _hud_scale * 0.9, _hud_scale * 0.9, 0);
}

// === ORDER QUEUE ===
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
var _circle_r = min(order_row_h * 0.25, _w * 0.035);
var _oi = 0;
while (_oi < array_length(orders)) {
    var _order = orders[_oi];
    var _row_y = order_area_y + _oi * order_row_h;
    var _row_cy = _row_y + order_row_h * 0.5;

    // Timer bar background
    var _bar_x = _pad;
    var _bar_w = _w - _pad * 2;
    var _bar_h = max(4, order_row_h * 0.08);
    var _bar_y = _row_y + order_row_h - _bar_h - 2;
    draw_set_colour($333333);
    draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);

    // Timer bar fill (green → yellow → red)
    var _ratio = _order.timer / _order.max_timer;
    if (_ratio > 0.5) {
        draw_set_colour($71cc2e); // green
    } else if (_ratio > 0.25) {
        draw_set_colour($0fc4f1); // yellow
    } else {
        draw_set_colour($3c4ce7); // red
    }
    draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * _ratio, _bar_y + _bar_h, false);

    // Recipe circles
    var _recipe = _order.recipe;
    var _rx = _pad + _circle_r + 4;
    var _ri = 0;
    while (_ri < array_length(_recipe)) {
        var _col_idx = _recipe[_ri];
        draw_set_colour(all_colors[_col_idx]);
        draw_circle(_rx, _row_cy - _circle_r * 0.3, _circle_r, false);
        draw_set_colour($ffffff);
        draw_circle(_rx, _row_cy - _circle_r * 0.3, _circle_r, true);

        _rx += _circle_r * 2 + 4;
        // Arrow between items
        if (_ri < array_length(_recipe) - 1) {
            draw_set_colour($aaaaaa);
            draw_set_halign(fa_center);
            draw_text_ext_transformed(_rx, _row_cy - _circle_r * 0.3, ">", 0, 100, _hud_scale * 0.6, _hud_scale * 0.6, 0);
            draw_set_halign(fa_left);
            _rx += _circle_r + 4;
        }
        _ri += 1;
    }

    // Reward text
    draw_set_halign(fa_right);
    draw_set_colour($0fc4f1); // yellow
    var _reward_scale = _hud_scale * 0.7;
    draw_text_ext_transformed(_w - _pad, _row_cy - _circle_r * 0.3, "$" + string(_order.reward), 0, _w, _reward_scale, _reward_scale, 0);
    draw_set_halign(fa_left);

    // Timer text
    var _time_left = ceil(_order.timer / 60);
    draw_set_colour($cccccc);
    draw_text_ext_transformed(_w - _pad - 80 * (_reward_scale / 1.5), _row_cy - _circle_r * 0.3, string(_time_left) + "s", 0, _w, _reward_scale, _reward_scale, 0);

    _oi += 1;
}

// "ORDERS" label if no orders
if (array_length(orders) == 0 && game_state == 1) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour($666666);
    draw_text_ext_transformed(_w * 0.5, order_area_y + order_area_h * 0.5, "Waiting for orders...", 0, _w, _hud_scale, _hud_scale, 0);
}

// === ASSEMBLY BELT ===
// Conveyor background
draw_set_colour($6a4a4a); // conveyor gray #4a4a6a
draw_rectangle(_pad * 0.5, belt_area_y, _w - _pad * 0.5, belt_area_y + belt_area_h, false);

// Conveyor stripes
draw_set_colour($5a3a3a); // darker stripe
var _stripe_x = _pad * 0.5 + conveyor_offset - 20;
while (_stripe_x < _w - _pad * 0.5) {
    draw_rectangle(_stripe_x, belt_area_y, _stripe_x + 6, belt_area_y + belt_area_h, false);
    _stripe_x += 20;
}

// Belt label
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour($999999);
draw_text_ext_transformed(_pad + 4, belt_area_y + 2, "ASSEMBLY", 0, _w, _hud_scale * 0.5, _hud_scale * 0.5, 0);

// Assembly items
var _belt_cy = belt_area_y + belt_area_h * 0.55;
var _belt_circle_r = min(belt_area_h * 0.3, _w * 0.045);
var _belt_start_x = _pad + _belt_circle_r + 10;
var _belt_spacing = _belt_circle_r * 2.5;
var _ai = 0;
while (_ai < array_length(assembly)) {
    var _ax = _belt_start_x + _ai * _belt_spacing;
    var _col_idx = assembly[_ai];
    draw_set_colour(all_colors[_col_idx]);
    draw_circle(_ax, _belt_cy, _belt_circle_r, false);
    draw_set_colour($ffffff);
    draw_circle(_ax, _belt_cy, _belt_circle_r, true);
    _ai += 1;
}

// Empty slots
while (_ai < max_assembly) {
    var _ax = _belt_start_x + _ai * _belt_spacing;
    draw_set_colour($444444);
    draw_circle(_ax, _belt_cy, _belt_circle_r, true);
    _ai += 1;
}

// === STATION BUTTONS ===
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var _si = 0;
while (_si < array_length(station_buttons)) {
    var _btn = station_buttons[_si];
    var _cx = (_btn.x1 + _btn.x2) * 0.5;
    var _cy = (_btn.y1 + _btn.y2) * 0.5;
    var _br = (_btn.x2 - _btn.x1) * 0.5;

    // Button background
    draw_set_colour(all_colors[_btn.color_idx]);
    draw_circle(_cx, _cy, _br, false);

    // Button outline
    draw_set_colour($ffffff);
    draw_circle(_cx, _cy, _br, true);
    draw_circle(_cx, _cy, _br - 1, true);

    // Color initial
    draw_set_colour($ffffff);
    var _initial = string_char_at(color_names[_btn.color_idx], 1);
    draw_text_ext_transformed(_cx, _cy, _initial, 0, 100, _hud_scale * 1.2, _hud_scale * 1.2, 0);

    _si += 1;
}

// === SHIP & CLEAR BUTTONS ===
// Ship button
var _has_match = false;
if (array_length(assembly) > 0) {
    var _ci = 0;
    while (_ci < array_length(orders)) {
        var _recipe = orders[_ci].recipe;
        if (array_length(_recipe) == array_length(assembly)) {
            var _match = true;
            var _cri = 0;
            while (_cri < array_length(_recipe)) {
                if (_recipe[_cri] != assembly[_cri]) {
                    _match = false;
                    break;
                }
                _cri += 1;
            }
            if (_match) {
                _has_match = true;
                break;
            }
        }
        _ci += 1;
    }
}

// Ship button color depends on match
if (_has_match) {
    draw_set_colour($71cc2e); // bright green when match found
} else {
    draw_set_colour($3e2116); // dark when no match
}
draw_rectangle(ship_btn.x1, ship_btn.y1, ship_btn.x2, ship_btn.y2, false);
draw_set_colour($ffffff);
draw_rectangle(ship_btn.x1, ship_btn.y1, ship_btn.x2, ship_btn.y2, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var _ship_cx = (ship_btn.x1 + ship_btn.x2) * 0.5;
var _ship_cy = (ship_btn.y1 + ship_btn.y2) * 0.5;
draw_text_ext_transformed(_ship_cx, _ship_cy, "SHIP", 0, _w, _hud_scale * 1.0, _hud_scale * 1.0, 0);

// Clear button
draw_set_colour($222244);
draw_rectangle(clear_btn.x1, clear_btn.y1, clear_btn.x2, clear_btn.y2, false);
draw_set_colour($aaaaaa);
draw_rectangle(clear_btn.x1, clear_btn.y1, clear_btn.x2, clear_btn.y2, true);
var _clear_cx = (clear_btn.x1 + clear_btn.x2) * 0.5;
var _clear_cy = (clear_btn.y1 + clear_btn.y2) * 0.5;
draw_text_ext_transformed(_clear_cx, _clear_cy, "CLEAR", 0, _w, _hud_scale * 0.9, _hud_scale * 0.9, 0);

// === FLOATING POPUPS ===
var _pi = 0;
while (_pi < array_length(popups)) {
    var _pop = popups[_pi];
    var _alpha = _pop.timer / _pop.max_timer;
    draw_set_alpha(_alpha);
    draw_set_colour(_pop.color);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _pop_scale = _hud_scale * 1.2 * (1.0 + (1.0 - _alpha) * 0.3);
    draw_text_ext_transformed(_pop.x, _pop.y, _pop.text, 0, _w, _pop_scale, _pop_scale, 0);
    draw_set_alpha(1.0);
    _pi += 1;
}

// === LOADING STATE ===
if (game_state == 0) {
    draw_set_colour($000000);
    draw_set_alpha(0.7);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);
    draw_set_colour($ffffff);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(_w * 0.5, _h * 0.5, "Loading...", 0, _w, _hud_scale * 1.5, _hud_scale * 1.5, 0);
}

// === GAME OVER OVERLAY ===
if (game_state == 2) {
    draw_set_colour($000000);
    draw_set_alpha(0.75);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Title
    draw_set_colour($3c4ce7); // red
    draw_text_ext_transformed(_w * 0.5, _h * 0.3, "GAME OVER", 0, _w, _hud_scale * 2, _hud_scale * 2, 0);

    // Stats
    draw_set_colour($ffffff);
    var _stat_scale = _hud_scale * 1.0;
    var _stat_y = _h * 0.42;
    var _stat_gap = _hud_scale * 24;
    draw_text_ext_transformed(_w * 0.5, _stat_y, "Score: " + string(final_score), 0, _w, _stat_scale, _stat_scale, 0);
    draw_text_ext_transformed(_w * 0.5, _stat_y + _stat_gap, "Level: " + string(final_level), 0, _w, _stat_scale, _stat_scale, 0);
    draw_text_ext_transformed(_w * 0.5, _stat_y + _stat_gap * 2, "Orders: " + string(final_orders), 0, _w, _stat_scale, _stat_scale, 0);
    draw_text_ext_transformed(_w * 0.5, _stat_y + _stat_gap * 3, "Max Combo: x" + string(final_combo), 0, _w, _stat_scale, _stat_scale, 0);

    // Tap to restart
    if (game_over_tap_delay <= 0) {
        draw_set_colour($aaaaaa);
        draw_text_ext_transformed(_w * 0.5, _h * 0.75, "Tap to restart", 0, _w, _stat_scale * 0.9, _stat_scale * 0.9, 0);
    }
}

// Reset draw state
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour($ffffff);
draw_set_alpha(1.0);
