
var _w = window_width;
var _h = window_height;
if (_w <= 0 || _h <= 0) exit;

var _pad = max(8, _w * 0.03);
var _sx = shake_x;
var _sy = shake_y;

// === BACKGROUND ===
draw_set_colour($2e1a1a); // dark blue-gray #1a1a2e
draw_rectangle(0, 0, _w, _h, false);

// Darker panel for order area
draw_set_colour($3e2116); // #16213e
draw_rectangle(_pad * 0.5 + _sx, order_area_y - 4 + _sy, _w - _pad * 0.5 + _sx, order_area_y + order_area_h + 4 + _sy, false);

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

// Combo text + decay bar
if (combo > 1) {
    draw_set_halign(fa_right);
    draw_set_colour($71cc2e); // green
    draw_text_ext_transformed(_w - _pad, hud_h * 0.65, "COMBO x" + string(combo), 0, _w, _hud_scale * 0.9, _hud_scale * 0.9, 0);

    // Combo decay bar
    var _combo_bar_w = min(120, _w * 0.25);
    var _combo_bar_h = max(3, _hud_scale * 2);
    var _combo_bar_x = _w - _pad - _combo_bar_w;
    var _combo_bar_y = hud_h * 0.82;
    var _combo_ratio = combo_timer / combo_max_timer;
    // Background
    draw_set_colour($333333);
    draw_rectangle(_combo_bar_x, _combo_bar_y, _combo_bar_x + _combo_bar_w, _combo_bar_y + _combo_bar_h, false);
    // Fill — green to red as it drains
    if (_combo_ratio > 0.5) {
        draw_set_colour($71cc2e);
    } else if (_combo_ratio > 0.25) {
        draw_set_colour($0fc4f1);
    } else {
        draw_set_colour($3c4ce7);
    }
    draw_rectangle(_combo_bar_x, _combo_bar_y, _combo_bar_x + _combo_bar_w * _combo_ratio, _combo_bar_y + _combo_bar_h, false);
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
    var _ratio = _order.timer / _order.max_timer;

    // Order pulse/shake when below 25% timer
    var _order_shake_x = 0;
    if (_ratio < 0.25) {
        _order_shake_x = sin(current_time * 0.03) * 3;
    }

    // Bonus order glow: pulsing gold background
    if (_order.is_bonus) {
        var _glow_alpha = 0.15 + sin(current_time * 0.005) * 0.08;
        draw_set_alpha(_glow_alpha);
        draw_set_colour($00d4ff); // gold BGR
        draw_rectangle(_pad * 0.5 + _sx, _row_y + _sy, _w - _pad * 0.5 + _sx, _row_y + order_row_h + _sy, false);
        draw_set_alpha(1.0);
    }

    // Timer bar background
    var _bar_x = _pad + _sx + _order_shake_x;
    var _bar_w = _w - _pad * 2;
    var _bar_h = max(4, order_row_h * 0.08);
    var _bar_y = _row_y + order_row_h - _bar_h - 2 + _sy;
    draw_set_colour($333333);
    draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);

    // Timer bar fill (green -> yellow -> red)
    if (_ratio > 0.5) {
        draw_set_colour($71cc2e); // green
    } else if (_ratio > 0.25) {
        draw_set_colour($0fc4f1); // yellow
    } else {
        draw_set_colour($3c4ce7); // red
    }
    draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * _ratio, _bar_y + _bar_h, false);

    // Recipe circles with partial match highlighting
    var _recipe = _order.recipe;
    var _rx = _pad + _circle_r + 4 + _sx + _order_shake_x;
    var _draw_cy = _row_cy - _circle_r * 0.3 + _sy;

    // Compute how many items match from start of assembly
    var _match_count = 0;
    if (array_length(assembly) > 0 && array_length(assembly) <= array_length(_recipe)) {
        _match_count = array_length(assembly); // assume all match
        var _ci = 0;
        while (_ci < array_length(assembly)) {
            if (_ci >= array_length(_recipe) || assembly[_ci] != _recipe[_ci]) {
                _match_count = _ci;
                _ci = array_length(assembly); // break
            }
            _ci += 1;
        }
    }

    var _ri = 0;
    while (_ri < array_length(_recipe)) {
        var _col_idx = _recipe[_ri];
        draw_set_colour(all_colors[_col_idx]);
        draw_circle(_rx, _draw_cy, _circle_r, false);

        // Highlight matched items with bright green outline
        if (_ri < _match_count) {
            draw_set_colour($71cc2e); // green checkmark outline
            draw_circle(_rx, _draw_cy, _circle_r + 2, true);
            draw_circle(_rx, _draw_cy, _circle_r + 1, true);
        } else {
            draw_set_colour($ffffff);
            draw_circle(_rx, _draw_cy, _circle_r, true);
        }

        _rx += _circle_r * 2 + 4;
        // Arrow between items
        if (_ri < array_length(_recipe) - 1) {
            draw_set_colour($aaaaaa);
            draw_set_halign(fa_center);
            draw_text_ext_transformed(_rx, _draw_cy, ">", 0, 100, _hud_scale * 0.6, _hud_scale * 0.6, 0);
            draw_set_halign(fa_left);
            _rx += _circle_r + 4;
        }
        _ri += 1;
    }

    // Reward text — gold for bonus orders
    draw_set_halign(fa_right);
    if (_order.is_bonus) {
        draw_set_colour($00d4ff); // gold
    } else {
        draw_set_colour($0fc4f1); // yellow
    }
    var _reward_scale = _hud_scale * 0.7;
    var _reward_text = "$" + string(_order.reward);
    if (_order.is_bonus) {
        _reward_text += "!";
    }
    draw_text_ext_transformed(_w - _pad + _sx + _order_shake_x, _draw_cy, _reward_text, 0, _w, _reward_scale, _reward_scale, 0);
    draw_set_halign(fa_left);

    // Timer text
    var _time_left = ceil(_order.timer / 60);
    if (_ratio < 0.25) {
        draw_set_colour($3c4ce7); // red when critical
    } else {
        draw_set_colour($cccccc);
    }
    draw_text_ext_transformed(_w - _pad - 80 * (_reward_scale / 1.5) + _sx + _order_shake_x, _draw_cy, string(_time_left) + "s", 0, _w, _reward_scale, _reward_scale, 0);

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
draw_set_colour($6a4a4a); // conveyor gray
draw_rectangle(_pad * 0.5 + _sx, belt_area_y + _sy, _w - _pad * 0.5 + _sx, belt_area_y + belt_area_h + _sy, false);

// Conveyor stripes
draw_set_colour($5a3a3a);
var _stripe_x = _pad * 0.5 + conveyor_offset - 20 + _sx;
while (_stripe_x < _w - _pad * 0.5 + _sx) {
    draw_rectangle(_stripe_x, belt_area_y + _sy, _stripe_x + 6, belt_area_y + belt_area_h + _sy, false);
    _stripe_x += 20;
}

// Belt label
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour($999999);
draw_text_ext_transformed(_pad + 4 + _sx, belt_area_y + 2 + _sy, "ASSEMBLY", 0, _w, _hud_scale * 0.5, _hud_scale * 0.5, 0);

// Assembly items with slide-in animation
var _belt_cy = belt_area_y + belt_area_h * 0.55 + _sy;
var _belt_circle_r = min(belt_area_h * 0.3, _w * 0.045);
var _belt_start_x = _pad + _belt_circle_r + 10 + _sx;
var _belt_spacing = _belt_circle_r * 2.5;
var _ai = 0;
while (_ai < array_length(assembly)) {
    var _slide_offset = 0;
    if (_ai < array_length(assembly_slide)) {
        _slide_offset = assembly_slide[_ai];
    }
    var _ax = _belt_start_x + _ai * _belt_spacing;
    var _ay = _belt_cy + _slide_offset;
    var _col_idx = assembly[_ai];
    draw_set_colour(all_colors[_col_idx]);
    draw_circle(_ax, _ay, _belt_circle_r, false);
    draw_set_colour($ffffff);
    draw_circle(_ax, _ay, _belt_circle_r, true);
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

    // Tap flash — expand radius briefly
    var _flash = 0;
    if (_btn.color_idx < 5) {
        _flash = station_flash[_btn.color_idx];
    }
    var _flash_scale = 1.0;
    if (_flash > 0) {
        _flash_scale = 1.0 + (_flash / 12.0) * 0.2;
    }
    var _draw_r = _br * _flash_scale;

    // Flash glow ring
    if (_flash > 0) {
        draw_set_alpha(_flash / 12.0 * 0.5);
        draw_set_colour($ffffff);
        draw_circle(_cx, _cy, _draw_r + 6, false);
        draw_set_alpha(1.0);
    }

    // Button background
    draw_set_colour(all_colors[_btn.color_idx]);
    draw_circle(_cx, _cy, _draw_r, false);

    // Button outline
    draw_set_colour($ffffff);
    draw_circle(_cx, _cy, _draw_r, true);
    draw_circle(_cx, _cy, _draw_r - 1, true);

    // Color initial
    draw_set_colour($ffffff);
    var _initial = string_char_at(color_names[_btn.color_idx], 1);
    draw_text_ext_transformed(_cx, _cy, _initial, 0, 100, _hud_scale * 1.2 * _flash_scale, _hud_scale * 1.2 * _flash_scale, 0);

    _si += 1;
}

// === UNDO, SHIP & CLEAR BUTTONS ===

// Undo button
if (array_length(assembly) > 0) {
    draw_set_colour($3a2244); // muted purple
} else {
    draw_set_colour($1a1a2e); // dim
}
draw_rectangle(undo_btn.x1, undo_btn.y1, undo_btn.x2, undo_btn.y2, false);
draw_set_colour($aaaaaa);
draw_rectangle(undo_btn.x1, undo_btn.y1, undo_btn.x2, undo_btn.y2, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var _undo_cx = (undo_btn.x1 + undo_btn.x2) * 0.5;
var _undo_cy = (undo_btn.y1 + undo_btn.y2) * 0.5;
draw_set_colour($ffffff);
draw_text_ext_transformed(_undo_cx, _undo_cy, "UNDO", 0, _w, _hud_scale * 0.8, _hud_scale * 0.8, 0);

// Ship button — check for match
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

// Ship button color
if (wrong_ship_timer > 0) {
    draw_set_colour($3c4ce7); // red flash on wrong ship
} else if (_has_match) {
    // Pulsing green when match found
    var _pulse = 0.85 + sin(current_time * 0.01) * 0.15;
    draw_set_alpha(_pulse);
    draw_set_colour($71cc2e); // bright green
} else {
    draw_set_colour($3e2116); // dark when no match
}
draw_rectangle(ship_btn.x1, ship_btn.y1, ship_btn.x2, ship_btn.y2, false);
draw_set_alpha(1.0);
draw_set_colour($ffffff);
draw_rectangle(ship_btn.x1, ship_btn.y1, ship_btn.x2, ship_btn.y2, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var _ship_cx = (ship_btn.x1 + ship_btn.x2) * 0.5;
var _ship_cy = (ship_btn.y1 + ship_btn.y2) * 0.5;
draw_text_ext_transformed(_ship_cx, _ship_cy, "SHIP", 0, _w, _hud_scale * 1.1, _hud_scale * 1.1, 0);

// Clear button
draw_set_colour($222244);
draw_rectangle(clear_btn.x1, clear_btn.y1, clear_btn.x2, clear_btn.y2, false);
draw_set_colour($aaaaaa);
draw_rectangle(clear_btn.x1, clear_btn.y1, clear_btn.x2, clear_btn.y2, true);
var _clear_cx = (clear_btn.x1 + clear_btn.x2) * 0.5;
var _clear_cy = (clear_btn.y1 + clear_btn.y2) * 0.5;
draw_set_colour($ffffff);
draw_text_ext_transformed(_clear_cx, _clear_cy, "CLEAR", 0, _w, _hud_scale * 0.8, _hud_scale * 0.8, 0);

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

// === RED FLASH OVERLAY (on expired order) ===
if (red_flash_timer > 0) {
    var _flash_alpha = (red_flash_timer / red_flash_max) * 0.3;
    draw_set_alpha(_flash_alpha);
    draw_set_colour($0000cc); // red tint
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);
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
    draw_text_ext_transformed(_w * 0.5, _h * 0.25, "GAME OVER", 0, _w, _hud_scale * 2, _hud_scale * 2, 0);

    // Stats
    draw_set_colour($ffffff);
    var _stat_scale = _hud_scale * 1.0;
    var _stat_y = _h * 0.37;
    var _stat_gap = _hud_scale * 22;
    draw_text_ext_transformed(_w * 0.5, _stat_y, "Score: " + string(final_score), 0, _w, _stat_scale, _stat_scale, 0);

    // Personal best
    if (best_score > 0) {
        if (final_score >= best_score) {
            draw_set_colour($0fc4f1); // yellow for new best
            draw_text_ext_transformed(_w * 0.5, _stat_y + _stat_gap, "NEW BEST!", 0, _w, _stat_scale * 0.8, _stat_scale * 0.8, 0);
        } else {
            draw_set_colour($888888);
            draw_text_ext_transformed(_w * 0.5, _stat_y + _stat_gap, "Best: " + string(best_score), 0, _w, _stat_scale * 0.8, _stat_scale * 0.8, 0);
        }
    }

    draw_set_colour($ffffff);
    draw_text_ext_transformed(_w * 0.5, _stat_y + _stat_gap * 2, "Level: " + string(final_level), 0, _w, _stat_scale, _stat_scale, 0);
    draw_text_ext_transformed(_w * 0.5, _stat_y + _stat_gap * 3, "Orders: " + string(final_orders), 0, _w, _stat_scale, _stat_scale, 0);
    draw_text_ext_transformed(_w * 0.5, _stat_y + _stat_gap * 4, "Max Combo: x" + string(final_combo), 0, _w, _stat_scale, _stat_scale, 0);

    // Tap to restart
    if (game_over_tap_delay <= 0) {
        var _blink = (current_time mod 1000) < 600;
        if (_blink) {
            draw_set_colour($aaaaaa);
            draw_text_ext_transformed(_w * 0.5, _h * 0.78, "Tap to restart", 0, _w, _stat_scale * 0.9, _stat_scale * 0.9, 0);
        }
    }
}

// Reset draw state
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour($ffffff);
draw_set_alpha(1.0);
