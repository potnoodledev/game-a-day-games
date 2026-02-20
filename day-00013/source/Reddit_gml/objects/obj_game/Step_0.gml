
// === STATE 0: LOADING ===
if (game_state == 0) {
    if (state_loaded) {
        game_state = 1;
        var _diff_idx = min(level - 1, array_length(diff_table) - 1);
        var _diff = diff_table[_diff_idx];
        num_colors = _diff[0];
        order_spawn_rate = _diff[3] * 60;
        order_spawn_timer = 180; // 3 second warm-up
    }
    exit;
}

// === STATE 2: GAME OVER ===
if (game_state == 2) {
    if (game_over_tap_delay > 0) game_over_tap_delay -= 1;
    if (game_over_tap_delay <= 0 && device_mouse_check_button_pressed(0, mb_left)) {
        game_state = 1;
        points = 0;
        level = 1;
        lives = 3;
        combo = 1;
        combo_timer = 0;
        combo_floor = 1;
        max_combo = 1;
        orders_completed = 0;
        orders = [];
        assembly = [];
        assembly_slide = [];
        popups = [];
        ring_fx = [];
        complete_fx = [];
        smoke_particles = [];
        score_submitted = false;
        orders_for_next_level = 5;
        shake_timer = 0;
        shake_x = 0;
        shake_y = 0;
        red_flash_timer = 0;
        wrong_ship_timer = 0;
        belt_full_timer = 0;
        freeze_timer = 0;
        powerup_state = 0;
        station_flash = [0, 0, 0, 0, 0];
        shipping_timer = 0;
        shipping_order = undefined;
        overflow_active = false;
        frenzy_active = false;
        var _diff = diff_table[0];
        num_colors = _diff[0];
        order_spawn_rate = _diff[3] * 60;
        order_spawn_timer = 180; // 3 second warm-up
        new_color_timer = 0;
        new_color_idx = -1;
        layout_dirty = true;
    }
    exit;
}

// === STATE 1: PLAYING ===

// --- Always update visual effects ---
if (shake_timer > 0) {
    shake_timer -= 1;
    shake_x = irandom_range(-shake_intensity, shake_intensity) * (shake_timer / 10);
    shake_y = irandom_range(-shake_intensity, shake_intensity) * (shake_timer / 10);
} else {
    shake_x = 0;
    shake_y = 0;
}
if (red_flash_timer > 0) red_flash_timer -= 1;
if (wrong_ship_timer > 0) wrong_ship_timer -= 1;
if (belt_full_timer > 0) belt_full_timer -= 1;
if (freeze_timer > 0) freeze_timer -= 1;
if (new_color_timer > 0) new_color_timer -= 1;

var _fi = 0;
while (_fi < 5) {
    if (station_flash[_fi] > 0) station_flash[_fi] -= 1;
    _fi += 1;
}
// Assembly slide-in
var _si = 0;
while (_si < array_length(assembly_slide)) {
    if (assembly_slide[_si] != 0) {
        assembly_slide[_si] = assembly_slide[_si] * 0.7;
        if (abs(assembly_slide[_si]) < 1) assembly_slide[_si] = 0;
    }
    _si += 1;
}

// Ring FX
var _ri = array_length(ring_fx) - 1;
while (_ri >= 0) {
    ring_fx[_ri].timer -= 1;
    ring_fx[_ri].radius += (ring_fx[_ri].max_radius - ring_fx[_ri].radius) * 0.15;
    if (ring_fx[_ri].timer <= 0) array_delete(ring_fx, _ri, 1);
    _ri -= 1;
}

// Completion FX
var _cfi = array_length(complete_fx) - 1;
while (_cfi >= 0) {
    complete_fx[_cfi].timer -= 1;
    if (complete_fx[_cfi].timer <= 0) array_delete(complete_fx, _cfi, 1);
    _cfi -= 1;
}

// Smoke particles
smoke_spawn_timer -= 1;
if (smoke_spawn_timer <= 0 && window_width > 0) {
    smoke_spawn_timer = 6 + irandom(6);
    var _pad = max(8, window_width * 0.03);
    array_push(smoke_particles, {
        x: _pad + irandom(floor(window_width - _pad * 2)),
        y: belt_area_y + belt_area_h,
        alpha: 0.15 + random(0.1),
        size: 2 + random(3),
        vy: -0.3 - random(0.4)
    });
}
var _spi = array_length(smoke_particles) - 1;
while (_spi >= 0) {
    smoke_particles[_spi].y += smoke_particles[_spi].vy;
    smoke_particles[_spi].alpha -= 0.003;
    if (smoke_particles[_spi].alpha <= 0) array_delete(smoke_particles, _spi, 1);
    _spi -= 1;
}

// Popups
var _pi = array_length(popups) - 1;
while (_pi >= 0) {
    popups[_pi].timer -= 1;
    popups[_pi].y -= 0.5;
    if (popups[_pi].timer <= 0) array_delete(popups, _pi, 1);
    _pi -= 1;
}

// Conveyor
conveyor_offset = (conveyor_offset + 1) mod 20;

// --- Tutorial overlay ---
if (!tutorial_done) {
    if (device_mouse_check_button_pressed(0, mb_left)) {
        tutorial_done = true;
    }
    exit;
}

// --- Power-up selection mode ---
if (powerup_state == 1) {
    if (device_mouse_check_button_pressed(0, mb_left)) {
        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);
        var _selected = -1;

        if (_mx >= powerup_card_1.x1 && _mx <= powerup_card_1.x2 && _my >= powerup_card_1.y1 && _my <= powerup_card_1.y2) {
            _selected = 0;
        }
        if (_mx >= powerup_card_2.x1 && _mx <= powerup_card_2.x2 && _my >= powerup_card_2.y1 && _my <= powerup_card_2.y2) {
            _selected = 1;
        }

        if (_selected >= 0) {
            var _choice = powerup_choices[_selected];

            // Apply power-up
            if (_choice == 0) {
                // OVERFLOW: belt wraps around
                overflow_active = true;
                array_push(popups, {x: window_width * 0.5, y: window_height * 0.4, text: "OVERFLOW!", color: $0fc4f1, timer: 90, max_timer: 90});
            }
            if (_choice == 1) {
                lives = min(lives + 1, max_lives); // EXTRA LIFE
                array_push(popups, {x: window_width * 0.5, y: window_height * 0.4, text: "+1 LIFE!", color: $3c4ce7, timer: 90, max_timer: 90});
            }
            if (_choice == 2) {
                // FRENZY: combo x3+ spawns bonus orders
                frenzy_active = true;
                array_push(popups, {x: window_width * 0.5, y: window_height * 0.4, text: "FRENZY!", color: $00d4ff, timer: 90, max_timer: 90});
            }
            if (_choice == 3) {
                freeze_timer = 300; // FREEZE: 5 seconds
                array_push(popups, {x: window_width * 0.5, y: window_height * 0.4, text: "FROZEN!", color: $db9834, timer: 90, max_timer: 90});
            }

            // Advance level
            level += 1;
            orders_for_next_level += 5;
            var _prev_colors = num_colors;

            // Compute difficulty — table for levels 1-5, formula for 6+
            if (level <= array_length(diff_table)) {
                var _new_diff = diff_table[level - 1];
                num_colors = _new_diff[0];
                order_spawn_rate = _new_diff[3] * 60;
            } else {
                // Infinite scaling past level 5
                num_colors = 5;
                var _past = level - 5;
                var _spawn_sec = max(1.5, 2.0 - _past * 0.08);
                order_spawn_rate = _spawn_sec * 60;
            }

            // Detect new color added
            if (num_colors > _prev_colors) {
                new_color_idx = num_colors - 1;
                new_color_timer = 150; // 2.5s announcement
                // Grace period: freeze timers briefly
                freeze_timer = max(freeze_timer, 120);
            }

            layout_dirty = true;
            powerup_state = 0;

            array_push(popups, {x: window_width * 0.5, y: window_height * 0.5, text: "LEVEL " + string(level) + "!", color: $ffffff, timer: 120, max_timer: 120});
        }
    }
    exit;
}

// --- Normal gameplay ---

// Update order timers (skip if frozen)
var _i = array_length(orders) - 1;
while (_i >= 0) {
    if (freeze_timer <= 0 && orders[_i] != shipping_order) {
        orders[_i].timer -= 1;
    }
    if (orders[_i].timer <= 0) {
        lives -= 1;
        red_flash_timer = red_flash_max;
        shake_timer = 10;
        shake_intensity = 4;
        var _pop_x = window_width * 0.5;
        var _pop_y = order_area_y + _i * order_row_h + order_row_h * 0.5;
        array_push(popups, {x: _pop_x, y: _pop_y, text: "EXPIRED!", color: $3c4ce7, timer: 90, max_timer: 90});
        combo = combo_floor;
        combo_timer = 0;
        array_delete(orders, _i, 1);
    }
    _i -= 1;
}

// Sort orders by timer (most urgent first) — bubble sort, max 4 items
var _k = 0;
while (_k < array_length(orders) - 1) {
    if (orders[_k].timer > orders[_k + 1].timer) {
        var _temp = orders[_k];
        orders[_k] = orders[_k + 1];
        orders[_k + 1] = _temp;
    }
    _k += 1;
}

// Spawn new orders
order_spawn_timer -= 1;
if (order_spawn_timer <= 0 && array_length(orders) < max_orders) {
    // Compute recipe length and timer — table for 1-5, formula for 6+
    var _max_len = 2;
    var _timer_sec = 15;
    if (level <= array_length(diff_table)) {
        var _diff = diff_table[level - 1];
        _max_len = _diff[1];
        _timer_sec = _diff[2];
    } else {
        var _past = level - 5;
        _max_len = min(max_assembly, 5 + floor(_past / 3));
        _timer_sec = max(5, 8 - _past * 0.4);
    }
    var _recipe_len = 2 + irandom(_max_len - 2);

    var _recipe = [];
    var _j = 0;
    while (_j < _recipe_len) {
        array_push(_recipe, irandom(num_colors - 1));
        _j += 1;
    }

    var _timer_frames = _timer_sec * 60;
    var _reward = _recipe_len * 10 + irandom(5);

    var _is_bonus = (irandom(99) < 15);
    if (_is_bonus) {
        _timer_frames = floor(_timer_frames * 0.6);
        _reward = _reward * 3;
    }

    // Random product name
    var _pname = product_prefixes[irandom(array_length(product_prefixes) - 1)] + " " + product_suffixes[irandom(array_length(product_suffixes) - 1)];

    var _order = {
        recipe: _recipe,
        timer: _timer_frames,
        max_timer: _timer_frames,
        reward: _reward,
        is_bonus: _is_bonus,
        name: _pname
    };
    array_push(orders, _order);
    order_spawn_timer = order_spawn_rate;
}

// Combo timer
if (combo > combo_floor) {
    combo_timer -= 1;
    if (combo_timer <= 0) {
        combo = combo_floor;
    }
}

// --- Shipping animation ---
if (shipping_timer > 0) {
    shipping_timer -= 1;
    if (shipping_timer <= 0) {
        // Find shipping order (may have moved due to sorting)
        var _del_idx = -1;
        var _oi = 0;
        while (_oi < array_length(orders)) {
            if (orders[_oi] == shipping_order) {
                _del_idx = _oi;
                break;
            }
            _oi += 1;
        }

        var _order = shipping_order;
        var _base_reward = _order.reward;
        var _level_mult = 1.0 + (level - 1) * 0.1;
        var _time_ratio = _order.timer / _order.max_timer;
        var _speed_bonus = 0;
        if (_time_ratio > 0.5) {
            _speed_bonus = floor(_base_reward * 0.5);
        }
        var _earned = floor((_base_reward + _speed_bonus) * combo * _level_mult);
        points += _earned;

        // Screen shake + ring FX
        shake_timer = 8;
        shake_intensity = 3;
        var _ring_x = window_width * 0.5;
        var _ring_y = belt_area_y + belt_area_h * 0.5;
        array_push(ring_fx, {x: _ring_x, y: _ring_y, radius: 10, max_radius: 80, timer: 20, max_timer: 20, color: $71cc2e});
        if (_order.is_bonus) {
            array_push(ring_fx, {x: _ring_x, y: _ring_y, radius: 10, max_radius: 120, timer: 25, max_timer: 25, color: $0fc4f1});
        }

        if (_del_idx >= 0) {
            array_push(complete_fx, {row_y: order_area_y + _del_idx * order_row_h, timer: 20, max_timer: 20});
        }

        // Popup
        var _pop_x = window_width * 0.5;
        var _pop_y = belt_area_y + belt_area_h * 0.5;
        var _pop_text = "+" + string(_earned);
        if (_speed_bonus > 0) _pop_text += " FAST!";
        if (_order.is_bonus) _pop_text += " BONUS!";
        array_push(popups, {x: _pop_x, y: _pop_y, text: _pop_text, color: $0fc4f1, timer: 90, max_timer: 90});

        // Increase combo
        combo = min(combo + 1, 4);
        if (combo > max_combo) max_combo = combo;
        combo_timer = combo_max_timer;
        if (combo >= 3) {
            array_push(popups, {x: _pop_x, y: _pop_y - 30, text: "COMBO x" + string(combo) + "!", color: $71cc2e, timer: 60, max_timer: 60});
        }

        if (_del_idx >= 0) array_delete(orders, _del_idx, 1);
        orders_completed += 1;
        assembly = [];
        assembly_slide = [];
        shipping_order = undefined;

        // Frenzy: combo x3+ spawns a bonus order
        if (frenzy_active && combo >= 3 && array_length(orders) < max_orders) {
            var _fr_recipe = [];
            var _fj = 0;
            while (_fj < 2) {
                array_push(_fr_recipe, irandom(num_colors - 1));
                _fj += 1;
            }
            var _fr_timer = 5 * 60;
            var _fr_name = product_prefixes[irandom(array_length(product_prefixes) - 1)] + " " + product_suffixes[irandom(array_length(product_suffixes) - 1)];
            array_push(orders, {
                recipe: _fr_recipe,
                timer: _fr_timer,
                max_timer: _fr_timer,
                reward: 50,
                is_bonus: true,
                name: _fr_name
            });
        }

        // Level up → power-up selection
        if (orders_completed >= orders_for_next_level) {
            powerup_state = 1;
            var _p1 = irandom(3);
            var _p2 = irandom(2);
            if (_p2 >= _p1) _p2 += 1;
            powerup_choices = [_p1, _p2];
        }
    }
}

// --- Touch input (blocked during shipping) ---
if (shipping_timer <= 0 && device_mouse_check_button_pressed(0, mb_left)) {
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    // Station buttons
    var _s = 0;
    while (_s < array_length(station_buttons)) {
        var _btn = station_buttons[_s];
        if (_mx >= _btn.x1 && _mx <= _btn.x2 && _my >= _btn.y1 && _my <= _btn.y2) {
            if (array_length(assembly) < max_assembly) {
                array_push(assembly, _btn.color_idx);
                array_push(assembly_slide, -60);
                station_flash[_btn.color_idx] = 12;
            } else if (overflow_active) {
                // Overflow: push oldest item off, add new one
                array_delete(assembly, 0, 1);
                array_delete(assembly_slide, 0, 1);
                array_push(assembly, _btn.color_idx);
                array_push(assembly_slide, -60);
                station_flash[_btn.color_idx] = 12;
            } else {
                belt_full_timer = 15;
                array_push(popups, {x: window_width * 0.5, y: belt_area_y + belt_area_h * 0.5, text: "BELT FULL!", color: $3c4ce7, timer: 40, max_timer: 40});
            }
            break;
        }
        _s += 1;
    }

    // SHIP button
    if (_mx >= ship_btn.x1 && _mx <= ship_btn.x2 && _my >= ship_btn.y1 && _my <= ship_btn.y2) {
        if (array_length(assembly) > 0) {
            var _match_idx = -1;
            var _oi = 0;
            while (_oi < array_length(orders)) {
                var _recipe = orders[_oi].recipe;
                if (array_length(_recipe) == array_length(assembly)) {
                    var _match = true;
                    var _ri = 0;
                    while (_ri < array_length(_recipe)) {
                        if (assembly[_ri] != _recipe[_ri]) {
                            _match = false;
                            break;
                        }
                        _ri += 1;
                    }
                    if (_match) {
                        _match_idx = _oi;
                        break;
                    }
                }
                _oi += 1;
            }

            if (_match_idx >= 0) {
                // Start shipping animation instead of instant clear
                shipping_order = orders[_match_idx];
                shipping_timer = 25;
            } else {
                // Wrong ship penalty
                wrong_ship_timer = 15;
                shake_timer = 6;
                shake_intensity = 3;
                var _pi2 = 0;
                while (_pi2 < array_length(orders)) {
                    orders[_pi2].timer -= 120;
                    if (orders[_pi2].timer < 1) orders[_pi2].timer = 1;
                    _pi2 += 1;
                }
                array_push(popups, {x: window_width * 0.5, y: belt_area_y, text: "NO MATCH! -2s", color: $3c4ce7, timer: 60, max_timer: 60});
            }
        }
    }

    // UNDO button
    if (_mx >= undo_btn.x1 && _mx <= undo_btn.x2 && _my >= undo_btn.y1 && _my <= undo_btn.y2) {
        if (array_length(assembly) > 0) {
            array_pop(assembly);
            array_pop(assembly_slide);
        }
    }

    // CLEAR button
    if (_mx >= clear_btn.x1 && _mx <= clear_btn.x2 && _my >= clear_btn.y1 && _my <= clear_btn.y2) {
        assembly = [];
        assembly_slide = [];
    }
}

// --- Check game over ---
if (lives <= 0) {
    game_state = 2;
    final_score = points;
    final_level = level;
    final_orders = orders_completed;
    final_combo = max_combo;
    if (points > best_score) best_score = points;
    game_over_tap_delay = 90;
    if (!score_submitted) {
        score_submitted = true;
        api_submit_score(points, undefined);
        api_save_state(level, { points: points, level: level, lives: 0, orders_completed: orders_completed, combo: combo, best_score: best_score, tutorial_done: tutorial_done }, undefined);
    }
}
