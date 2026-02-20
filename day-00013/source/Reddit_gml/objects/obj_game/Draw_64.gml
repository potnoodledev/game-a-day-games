
var _w = window_width;
var _h = window_height;
if (_w <= 0 || _h <= 0) exit;

var _pad = max(8, _w * 0.03);
var _sx = shake_x;
var _sy = shake_y;

// === BACKGROUND ===
draw_set_colour($2e1a1a);
draw_rectangle(0, 0, _w, _h, false);

// Darker panel for order area
draw_set_colour($3e2116);
draw_rectangle(_pad * 0.5 + _sx, order_area_y - 4 + _sy, _w - _pad * 0.5 + _sx, order_area_y + order_area_h + 4 + _sy, false);

// === SMOKE PARTICLES (behind everything) ===
var _spi = 0;
while (_spi < array_length(smoke_particles)) {
    var _sp = smoke_particles[_spi];
    draw_set_alpha(_sp.alpha);
    draw_set_colour($888888);
    draw_circle(_sp.x + _sx, _sp.y + _sy, _sp.size, false);
    _spi += 1;
}
draw_set_alpha(1.0);

// === HUD ===
draw_set_font(fnt_default);
var _hud_scale = max(1.5, min(_w, _h) / 400);

draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour($0fc4f1);
draw_text_ext_transformed(_pad, hud_h * 0.3, "SCORE: " + string(points), 0, _w, _hud_scale, _hud_scale, 0);

draw_set_halign(fa_right);
draw_set_colour($ffffff);
draw_text_ext_transformed(_w - _pad, hud_h * 0.3, "LEVEL " + string(level), 0, _w, _hud_scale, _hud_scale, 0);

// Lives
draw_set_halign(fa_left);
draw_set_colour($3c4ce7);
var _heart_text = "";
var _li = 0;
while (_li < lives) {
    _heart_text += "* ";
    _li += 1;
}
draw_text_ext_transformed(_pad, hud_h * 0.7, "LIVES: " + _heart_text, 0, _w, _hud_scale * 0.8, _hud_scale * 0.8, 0);

// Combo + decay bar
if (combo > combo_floor) {
    draw_set_halign(fa_right);
    draw_set_colour($71cc2e);
    draw_text_ext_transformed(_w - _pad, hud_h * 0.65, "COMBO x" + string(combo), 0, _w, _hud_scale * 0.9, _hud_scale * 0.9, 0);

    var _combo_bar_w = min(120, _w * 0.25);
    var _combo_bar_h = max(3, _hud_scale * 2);
    var _combo_bar_x = _w - _pad - _combo_bar_w;
    var _combo_bar_y = hud_h * 0.82;
    var _combo_ratio = combo_timer / combo_max_timer;
    draw_set_colour($333333);
    draw_rectangle(_combo_bar_x, _combo_bar_y, _combo_bar_x + _combo_bar_w, _combo_bar_y + _combo_bar_h, false);
    if (_combo_ratio > 0.5) {
        draw_set_colour($71cc2e);
    } else if (_combo_ratio > 0.25) {
        draw_set_colour($0fc4f1);
    } else {
        draw_set_colour($3c4ce7);
    }
    draw_rectangle(_combo_bar_x, _combo_bar_y, _combo_bar_x + _combo_bar_w * _combo_ratio, _combo_bar_y + _combo_bar_h, false);
} else if (combo_floor >= 2) {
    // Show locked combo indicator
    draw_set_halign(fa_right);
    draw_set_colour($447744);
    draw_text_ext_transformed(_w - _pad, hud_h * 0.65, "COMBO x" + string(combo) + " LOCKED", 0, _w, _hud_scale * 0.7, _hud_scale * 0.7, 0);
}

// Freeze indicator
if (freeze_timer > 0) {
    draw_set_halign(fa_center);
    draw_set_colour($db9834);
    var _freeze_pulse = 0.7 + sin(current_time * 0.01) * 0.3;
    draw_set_alpha(_freeze_pulse);
    draw_text_ext_transformed(_w * 0.5, hud_h * 0.5, "FROZEN " + string(ceil(freeze_timer / 60)) + "s", 0, _w, _hud_scale * 1.2, _hud_scale * 1.2, 0);
    draw_set_alpha(1.0);
}

// === COMPLETION FX (green flash on order rows) ===
var _cfi = 0;
while (_cfi < array_length(complete_fx)) {
    var _cf = complete_fx[_cfi];
    var _cf_alpha = _cf.timer / _cf.max_timer;
    var _slide = (1.0 - _cf_alpha) * _w * 0.15;
    draw_set_alpha(_cf_alpha * 0.5);
    draw_set_colour($71cc2e);
    draw_rectangle(_pad * 0.5 + _slide + _sx, _cf.row_y + _sy, _w - _pad * 0.5 + _slide + _sx, _cf.row_y + order_row_h + _sy, false);
    draw_set_alpha(1.0);
    _cfi += 1;
}

// === ORDER QUEUE ===
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
var _circle_r = min(order_row_h * 0.22, _w * 0.03);
var _oi = 0;
while (_oi < array_length(orders)) {
    var _order = orders[_oi];
    var _row_y = order_area_y + _oi * order_row_h;
    var _row_cy = _row_y + order_row_h * 0.5;
    var _ratio = _order.timer / _order.max_timer;

    // Shake when critical
    var _order_shake_x = 0;
    if (_ratio < 0.25) {
        _order_shake_x = sin(current_time * 0.03) * 3;
    }

    // Bonus glow
    if (_order.is_bonus) {
        var _glow_alpha = 0.12 + sin(current_time * 0.005) * 0.06;
        draw_set_alpha(_glow_alpha);
        draw_set_colour($00d4ff);
        draw_rectangle(_pad * 0.5 + _sx, _row_y + _sy, _w - _pad * 0.5 + _sx, _row_y + order_row_h + _sy, false);
        draw_set_alpha(1.0);
    }

    // Product name (small, above recipe)
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    if (_order.is_bonus) {
        draw_set_colour($00d4ff);
    } else {
        draw_set_colour($777777);
    }
    var _name_scale = _hud_scale * 0.45;
    draw_text_ext_transformed(_pad + 2 + _sx + _order_shake_x, _row_y + 2 + _sy, _order.name, 0, _w, _name_scale, _name_scale, 0);

    // Timer bar
    draw_set_valign(fa_middle);
    var _bar_x = _pad + _sx + _order_shake_x;
    var _bar_w = _w - _pad * 2;
    var _bar_h = max(3, order_row_h * 0.06);
    var _bar_y = _row_y + order_row_h - _bar_h - 2 + _sy;
    draw_set_colour($333333);
    draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);
    if (_ratio > 0.5) {
        draw_set_colour($71cc2e);
    } else if (_ratio > 0.25) {
        draw_set_colour($0fc4f1);
    } else {
        draw_set_colour($3c4ce7);
    }
    draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * _ratio, _bar_y + _bar_h, false);

    // Recipe circles with partial match
    var _recipe = _order.recipe;
    var _draw_cy = _row_cy + _circle_r * 0.2 + _sy;
    var _rx = _pad + _circle_r + 4 + _sx + _order_shake_x;

    // Compute match count from assembly start
    var _match_count = 0;
    if (array_length(assembly) > 0 && array_length(assembly) <= array_length(_recipe)) {
        _match_count = array_length(assembly);
        var _ci = 0;
        while (_ci < array_length(assembly)) {
            if (_ci >= array_length(_recipe) || assembly[_ci] != _recipe[_ci]) {
                _match_count = _ci;
                _ci = array_length(assembly);
            }
            _ci += 1;
        }
    }

    var _ri = 0;
    while (_ri < array_length(_recipe)) {
        var _col_idx = _recipe[_ri];
        draw_set_colour(all_colors[_col_idx]);
        draw_circle(_rx, _draw_cy, _circle_r, false);

        if (_ri < _match_count) {
            draw_set_colour($71cc2e);
            draw_circle(_rx, _draw_cy, _circle_r + 2, true);
            draw_circle(_rx, _draw_cy, _circle_r + 1, true);
        } else {
            draw_set_colour($ffffff);
            draw_circle(_rx, _draw_cy, _circle_r, true);
        }

        _rx += _circle_r * 2 + 4;
        if (_ri < array_length(_recipe) - 1) {
            draw_set_colour($aaaaaa);
            draw_set_halign(fa_center);
            draw_text_ext_transformed(_rx, _draw_cy, ">", 0, 100, _hud_scale * 0.5, _hud_scale * 0.5, 0);
            draw_set_halign(fa_left);
            _rx += _circle_r + 4;
        }
        _ri += 1;
    }

    // Match fraction indicator
    if (_match_count > 0 && _match_count < array_length(_recipe)) {
        draw_set_colour($71cc2e);
        draw_text_ext_transformed(_rx + 8, _draw_cy, string(_match_count) + "/" + string(array_length(_recipe)), 0, 100, _hud_scale * 0.55, _hud_scale * 0.55, 0);
    } else if (_match_count == array_length(_recipe)) {
        draw_set_colour($71cc2e);
        draw_text_ext_transformed(_rx + 8, _draw_cy, "READY!", 0, 100, _hud_scale * 0.55, _hud_scale * 0.55, 0);
    }

    // Reward + timer text (right side)
    draw_set_halign(fa_right);
    if (_order.is_bonus) {
        draw_set_colour($00d4ff);
    } else {
        draw_set_colour($0fc4f1);
    }
    var _reward_scale = _hud_scale * 0.65;
    var _reward_text = "$" + string(_order.reward);
    if (_order.is_bonus) _reward_text += "!";
    draw_text_ext_transformed(_w - _pad + _sx + _order_shake_x, _draw_cy, _reward_text, 0, _w, _reward_scale, _reward_scale, 0);

    var _time_left = ceil(_order.timer / 60);
    if (_ratio < 0.25) {
        draw_set_colour($3c4ce7);
    } else {
        draw_set_colour($cccccc);
    }
    draw_text_ext_transformed(_w - _pad - 70 * (_reward_scale / 1.5) + _sx + _order_shake_x, _draw_cy, string(_time_left) + "s", 0, _w, _reward_scale, _reward_scale, 0);
    draw_set_halign(fa_left);

    _oi += 1;
}

if (array_length(orders) == 0 && game_state == 1 && powerup_state == 0 && tutorial_done) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour($666666);
    draw_text_ext_transformed(_w * 0.5, order_area_y + order_area_h * 0.5, "Waiting for orders...", 0, _w, _hud_scale, _hud_scale, 0);
}

// === ASSEMBLY BELT ===
draw_set_colour($6a4a4a);
draw_rectangle(_pad * 0.5 + _sx, belt_area_y + _sy, _w - _pad * 0.5 + _sx, belt_area_y + belt_area_h + _sy, false);

// Conveyor stripes
draw_set_colour($5a3a3a);
var _stripe_x = _pad * 0.5 + conveyor_offset - 20 + _sx;
while (_stripe_x < _w - _pad * 0.5 + _sx) {
    draw_rectangle(_stripe_x, belt_area_y + _sy, _stripe_x + 6, belt_area_y + belt_area_h + _sy, false);
    _stripe_x += 20;
}

// Belt full flash
if (belt_full_timer > 0) {
    draw_set_alpha(belt_full_timer / 15 * 0.3);
    draw_set_colour($0000cc);
    draw_rectangle(_pad * 0.5 + _sx, belt_area_y + _sy, _w - _pad * 0.5 + _sx, belt_area_y + belt_area_h + _sy, false);
    draw_set_alpha(1.0);
}

// Belt label
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour($999999);
draw_text_ext_transformed(_pad + 4 + _sx, belt_area_y + 2 + _sy, "ASSEMBLY", 0, _w, _hud_scale * 0.45, _hud_scale * 0.45, 0);

// Assembly items with slide-in + conveyor bob
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
    var _bob = sin((conveyor_offset + _ai * 5) * 0.3) * 1.5;
    var _ax = _belt_start_x + _ai * _belt_spacing;
    var _ay = _belt_cy + _slide_offset + _bob;
    var _col_idx = assembly[_ai];
    draw_set_colour(all_colors[_col_idx]);
    draw_circle(_ax, _ay, _belt_circle_r, false);
    draw_set_colour($ffffff);
    draw_circle(_ax, _ay, _belt_circle_r, true);
    _ai += 1;
}
while (_ai < max_assembly) {
    var _ax = _belt_start_x + _ai * _belt_spacing;
    draw_set_colour($444444);
    draw_circle(_ax, _belt_cy, _belt_circle_r, true);
    _ai += 1;
}

// === RING FX ===
var _rfi = 0;
while (_rfi < array_length(ring_fx)) {
    var _ring = ring_fx[_rfi];
    var _ring_alpha = _ring.timer / _ring.max_timer;
    draw_set_alpha(_ring_alpha);
    draw_set_colour(_ring.color);
    draw_circle(_ring.x + _sx, _ring.y + _sy, _ring.radius, true);
    draw_circle(_ring.x + _sx, _ring.y + _sy, max(0, _ring.radius - 2), true);
    draw_set_alpha(1.0);
    _rfi += 1;
}

// === STATION BUTTONS (square factory-style) ===
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var _si = 0;
while (_si < array_length(station_buttons)) {
    var _btn = station_buttons[_si];
    var _cx = (_btn.x1 + _btn.x2) * 0.5;
    var _cy = (_btn.y1 + _btn.y2) * 0.5;
    var _bw = (_btn.x2 - _btn.x1) * 0.5;
    var _bh = (_btn.y2 - _btn.y1) * 0.5;

    var _flash = 0;
    if (_btn.color_idx < 5) _flash = station_flash[_btn.color_idx];
    var _flash_scale = 1.0;
    if (_flash > 0) _flash_scale = 1.0 + (_flash / 12.0) * 0.15;

    var _dw = _bw * _flash_scale;
    var _dh = _bh * _flash_scale;

    // Flash glow
    if (_flash > 0) {
        draw_set_alpha(_flash / 12.0 * 0.4);
        draw_set_colour($ffffff);
        draw_rectangle(_cx - _dw - 4, _cy - _dh - 4, _cx + _dw + 4, _cy + _dh + 4, false);
        draw_set_alpha(1.0);
    }

    // Button body (square)
    draw_set_colour(all_colors[_btn.color_idx]);
    draw_rectangle(_cx - _dw, _cy - _dh, _cx + _dw, _cy + _dh, false);

    // Double border (factory look)
    draw_set_colour($ffffff);
    draw_rectangle(_cx - _dw, _cy - _dh, _cx + _dw, _cy + _dh, true);
    draw_rectangle(_cx - _dw + 3, _cy - _dh + 3, _cx + _dw - 3, _cy + _dh - 3, true);

    // Corner rivets
    draw_set_colour($dddddd);
    var _rivet_r = max(2, _dw * 0.08);
    draw_circle(_cx - _dw + 6, _cy - _dh + 6, _rivet_r, false);
    draw_circle(_cx + _dw - 6, _cy - _dh + 6, _rivet_r, false);
    draw_circle(_cx - _dw + 6, _cy + _dh - 6, _rivet_r, false);
    draw_circle(_cx + _dw - 6, _cy + _dh - 6, _rivet_r, false);

    // Color initial
    draw_set_colour($ffffff);
    var _initial = string_char_at(color_names[_btn.color_idx], 1);
    draw_text_ext_transformed(_cx, _cy, _initial, 0, 100, _hud_scale * 1.2 * _flash_scale, _hud_scale * 1.2 * _flash_scale, 0);

    _si += 1;
}

// === UNDO, SHIP & CLEAR BUTTONS ===
// Undo
if (array_length(assembly) > 0) {
    draw_set_colour($3a2244);
} else {
    draw_set_colour($1a1a2e);
}
draw_rectangle(undo_btn.x1, undo_btn.y1, undo_btn.x2, undo_btn.y2, false);
draw_set_colour($aaaaaa);
draw_rectangle(undo_btn.x1, undo_btn.y1, undo_btn.x2, undo_btn.y2, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour($ffffff);
var _undo_cx = (undo_btn.x1 + undo_btn.x2) * 0.5;
var _undo_cy = (undo_btn.y1 + undo_btn.y2) * 0.5;
draw_text_ext_transformed(_undo_cx, _undo_cy, "UNDO", 0, _w, _hud_scale * 0.8, _hud_scale * 0.8, 0);

// Ship — match check
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

if (wrong_ship_timer > 0) {
    draw_set_colour($3c4ce7);
} else if (_has_match) {
    var _pulse = 0.85 + sin(current_time * 0.01) * 0.15;
    draw_set_alpha(_pulse);
    draw_set_colour($71cc2e);
} else {
    draw_set_colour($3e2116);
}
draw_rectangle(ship_btn.x1, ship_btn.y1, ship_btn.x2, ship_btn.y2, false);
draw_set_alpha(1.0);
draw_set_colour($ffffff);
draw_rectangle(ship_btn.x1, ship_btn.y1, ship_btn.x2, ship_btn.y2, true);
var _ship_cx = (ship_btn.x1 + ship_btn.x2) * 0.5;
var _ship_cy = (ship_btn.y1 + ship_btn.y2) * 0.5;
draw_text_ext_transformed(_ship_cx, _ship_cy, "SHIP", 0, _w, _hud_scale * 1.1, _hud_scale * 1.1, 0);

// Clear
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

// === RED FLASH OVERLAY ===
if (red_flash_timer > 0) {
    draw_set_alpha((red_flash_timer / red_flash_max) * 0.3);
    draw_set_colour($0000cc);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);
}

// === FREEZE TINT ===
if (freeze_timer > 0) {
    draw_set_alpha(0.08);
    draw_set_colour($ffcc88);
    draw_rectangle(_pad * 0.5, order_area_y - 4, _w - _pad * 0.5, order_area_y + order_area_h + 4, false);
    draw_set_alpha(1.0);
}

// === TUTORIAL OVERLAY ===
if (!tutorial_done && game_state == 1) {
    draw_set_colour($000000);
    draw_set_alpha(0.85);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_set_colour($0fc4f1);
    draw_text_ext_transformed(_w * 0.5, _h * 0.18, "ASSEMBLY LINE", 0, _w, _hud_scale * 2.0, _hud_scale * 2.0, 0);

    draw_set_colour($ffffff);
    var _tut_scale = _hud_scale * 0.9;
    var _tut_y = _h * 0.32;
    var _tut_gap = _hud_scale * 28;

    draw_set_colour($db9834);
    draw_text_ext_transformed(_w * 0.5, _tut_y, "1", 0, _w, _tut_scale * 1.3, _tut_scale * 1.3, 0);
    draw_set_colour($ffffff);
    draw_text_ext_transformed(_w * 0.5, _tut_y + _tut_gap * 0.6, "TAP stations to add colors", 0, _w, _tut_scale, _tut_scale, 0);

    draw_set_colour($71cc2e);
    draw_text_ext_transformed(_w * 0.5, _tut_y + _tut_gap * 1.8, "2", 0, _w, _tut_scale * 1.3, _tut_scale * 1.3, 0);
    draw_set_colour($ffffff);
    draw_text_ext_transformed(_w * 0.5, _tut_y + _tut_gap * 2.4, "MATCH the order recipe", 0, _w, _tut_scale, _tut_scale, 0);

    draw_set_colour($3c4ce7);
    draw_text_ext_transformed(_w * 0.5, _tut_y + _tut_gap * 3.6, "3", 0, _w, _tut_scale * 1.3, _tut_scale * 1.3, 0);
    draw_set_colour($ffffff);
    draw_text_ext_transformed(_w * 0.5, _tut_y + _tut_gap * 4.2, "TAP SHIP to deliver!", 0, _w, _tut_scale, _tut_scale, 0);

    var _blink = (current_time mod 1000) < 600;
    if (_blink) {
        draw_set_colour($aaaaaa);
        draw_text_ext_transformed(_w * 0.5, _h * 0.82, "Tap to start", 0, _w, _tut_scale * 0.9, _tut_scale * 0.9, 0);
    }
}

// === POWER-UP SELECTION OVERLAY ===
if (powerup_state == 1) {
    draw_set_colour($000000);
    draw_set_alpha(0.8);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour($0fc4f1);
    draw_text_ext_transformed(_w * 0.5, _h * 0.15, "LEVEL UP!", 0, _w, _hud_scale * 2.0, _hud_scale * 2.0, 0);
    draw_set_colour($ffffff);
    draw_text_ext_transformed(_w * 0.5, _h * 0.27, "Choose a power-up:", 0, _w, _hud_scale * 0.9, _hud_scale * 0.9, 0);

    // Card 1
    var _c1 = powerup_choices[0];
    draw_set_colour(powerup_colors[_c1]);
    draw_set_alpha(0.3);
    draw_rectangle(powerup_card_1.x1, powerup_card_1.y1, powerup_card_1.x2, powerup_card_1.y2, false);
    draw_set_alpha(1.0);
    draw_set_colour(powerup_colors[_c1]);
    draw_rectangle(powerup_card_1.x1, powerup_card_1.y1, powerup_card_1.x2, powerup_card_1.y2, true);
    draw_rectangle(powerup_card_1.x1 + 2, powerup_card_1.y1 + 2, powerup_card_1.x2 - 2, powerup_card_1.y2 - 2, true);

    var _c1_cx = (powerup_card_1.x1 + powerup_card_1.x2) * 0.5;
    var _c1_cy = (powerup_card_1.y1 + powerup_card_1.y2) * 0.5;
    draw_set_colour($ffffff);
    draw_text_ext_transformed(_c1_cx, _c1_cy - _hud_scale * 12, powerup_names[_c1], 0, powerup_card_1.x2 - powerup_card_1.x1 - 10, _hud_scale * 1.0, _hud_scale * 1.0, 0);
    draw_set_colour($cccccc);
    draw_text_ext_transformed(_c1_cx, _c1_cy + _hud_scale * 10, powerup_descs[_c1], _hud_scale * 14, powerup_card_1.x2 - powerup_card_1.x1 - 10, _hud_scale * 0.65, _hud_scale * 0.65, 0);

    // Card 2
    var _c2 = powerup_choices[1];
    draw_set_colour(powerup_colors[_c2]);
    draw_set_alpha(0.3);
    draw_rectangle(powerup_card_2.x1, powerup_card_2.y1, powerup_card_2.x2, powerup_card_2.y2, false);
    draw_set_alpha(1.0);
    draw_set_colour(powerup_colors[_c2]);
    draw_rectangle(powerup_card_2.x1, powerup_card_2.y1, powerup_card_2.x2, powerup_card_2.y2, true);
    draw_rectangle(powerup_card_2.x1 + 2, powerup_card_2.y1 + 2, powerup_card_2.x2 - 2, powerup_card_2.y2 - 2, true);

    var _c2_cx = (powerup_card_2.x1 + powerup_card_2.x2) * 0.5;
    var _c2_cy = (powerup_card_2.y1 + powerup_card_2.y2) * 0.5;
    draw_set_colour($ffffff);
    draw_text_ext_transformed(_c2_cx, _c2_cy - _hud_scale * 12, powerup_names[_c2], 0, powerup_card_2.x2 - powerup_card_2.x1 - 10, _hud_scale * 1.0, _hud_scale * 1.0, 0);
    draw_set_colour($cccccc);
    draw_text_ext_transformed(_c2_cx, _c2_cy + _hud_scale * 10, powerup_descs[_c2], _hud_scale * 14, powerup_card_2.x2 - powerup_card_2.x1 - 10, _hud_scale * 0.65, _hud_scale * 0.65, 0);
}

// === LOADING ===
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

// === GAME OVER ===
if (game_state == 2) {
    draw_set_colour($000000);
    draw_set_alpha(0.75);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_set_colour($3c4ce7);
    draw_text_ext_transformed(_w * 0.5, _h * 0.22, "GAME OVER", 0, _w, _hud_scale * 2, _hud_scale * 2, 0);

    draw_set_colour($ffffff);
    var _stat_scale = _hud_scale * 1.0;
    var _stat_y = _h * 0.34;
    var _stat_gap = _hud_scale * 20;
    draw_text_ext_transformed(_w * 0.5, _stat_y, "Score: " + string(final_score), 0, _w, _stat_scale, _stat_scale, 0);

    if (best_score > 0) {
        if (final_score >= best_score) {
            draw_set_colour($0fc4f1);
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

    if (game_over_tap_delay <= 0) {
        var _blink = (current_time mod 1000) < 600;
        if (_blink) {
            draw_set_colour($aaaaaa);
            draw_text_ext_transformed(_w * 0.5, _h * 0.78, "Tap to restart", 0, _w, _stat_scale * 0.9, _stat_scale * 0.9, 0);
        }
    }
}

// Reset
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour($ffffff);
draw_set_alpha(1.0);
