
// === STATE 0: LOADING ===
if (game_state == 0) {
    if (state_loaded) {
        game_state = 1;
        // Apply difficulty for current level
        var _diff_idx = min(level - 1, array_length(diff_table) - 1);
        var _diff = diff_table[_diff_idx];
        num_colors = _diff[0];
        order_spawn_rate = _diff[3] * 60;
        order_spawn_timer = 60; // first order in 1 second
    }
    exit;
}

// === STATE 2: GAME OVER ===
if (game_state == 2) {
    if (game_over_tap_delay > 0) {
        game_over_tap_delay -= 1;
    }
    if (game_over_tap_delay <= 0 && device_mouse_check_button_pressed(0, mb_left)) {
        // Restart
        game_state = 1;
        points = 0;
        level = 1;
        lives = 3;
        combo = 1;
        combo_timer = 0;
        orders_completed = 0;
        orders = [];
        assembly = [];
        assembly_slide = [];
        popups = [];
        score_submitted = false;
        orders_for_next_level = 5;
        shake_timer = 0;
        shake_x = 0;
        shake_y = 0;
        red_flash_timer = 0;
        wrong_ship_timer = 0;
        station_flash = [0, 0, 0, 0, 0];
        var _diff = diff_table[0];
        num_colors = _diff[0];
        order_spawn_rate = _diff[3] * 60;
        order_spawn_timer = 60;
        layout_dirty = true;
    }
    exit;
}

// === STATE 1: PLAYING ===

// --- Update screen effects ---
if (shake_timer > 0) {
    shake_timer -= 1;
    shake_x = irandom_range(-shake_intensity, shake_intensity) * (shake_timer / 10);
    shake_y = irandom_range(-shake_intensity, shake_intensity) * (shake_timer / 10);
} else {
    shake_x = 0;
    shake_y = 0;
}

if (red_flash_timer > 0) {
    red_flash_timer -= 1;
}

if (wrong_ship_timer > 0) {
    wrong_ship_timer -= 1;
}

// --- Update station flash timers ---
var _fi = 0;
while (_fi < 5) {
    if (station_flash[_fi] > 0) {
        station_flash[_fi] -= 1;
    }
    _fi += 1;
}

// --- Update assembly slide-in ---
var _si = 0;
while (_si < array_length(assembly_slide)) {
    if (assembly_slide[_si] != 0) {
        assembly_slide[_si] = assembly_slide[_si] * 0.7; // lerp toward 0
        if (abs(assembly_slide[_si]) < 1) {
            assembly_slide[_si] = 0;
        }
    }
    _si += 1;
}

// --- Update order timers ---
var _i = array_length(orders) - 1;
while (_i >= 0) {
    orders[_i].timer -= 1;
    if (orders[_i].timer <= 0) {
        // Order expired — lose a life
        lives -= 1;
        // Red flash
        red_flash_timer = red_flash_max;
        // Shake
        shake_timer = 10;
        shake_intensity = 4;
        // Popup
        var _pop_x = window_width * 0.5;
        var _pop_y = order_area_y + _i * order_row_h + order_row_h * 0.5;
        array_push(popups, {x: _pop_x, y: _pop_y, text: "EXPIRED!", color: $3c4ce7, timer: 90, max_timer: 90});
        // Reset combo
        combo = 1;
        combo_timer = 0;
        array_delete(orders, _i, 1);
    }
    _i -= 1;
}

// --- Spawn new orders ---
order_spawn_timer -= 1;
if (order_spawn_timer <= 0 && array_length(orders) < max_orders) {
    // Generate recipe
    var _diff_idx = min(level - 1, array_length(diff_table) - 1);
    var _diff = diff_table[_diff_idx];
    var _max_len = _diff[1];
    var _timer_sec = _diff[2];
    var _recipe_len = 2 + irandom(_max_len - 2);

    var _recipe = [];
    var _j = 0;
    while (_j < _recipe_len) {
        array_push(_recipe, irandom(num_colors - 1));
        _j += 1;
    }

    var _timer_frames = _timer_sec * 60;
    var _reward = _recipe_len * 10 + irandom(5);

    // Bonus order: 15% chance, shorter timer, 3x reward
    var _is_bonus = (irandom(99) < 15);
    if (_is_bonus) {
        _timer_frames = floor(_timer_frames * 0.6);
        _reward = _reward * 3;
    }

    var _order = {
        recipe: _recipe,
        timer: _timer_frames,
        max_timer: _timer_frames,
        reward: _reward,
        is_bonus: _is_bonus
    };
    array_push(orders, _order);

    order_spawn_timer = order_spawn_rate;
}

// --- Combo timer ---
if (combo > 1) {
    combo_timer -= 1;
    if (combo_timer <= 0) {
        combo = 1;
    }
}

// --- Touch input ---
if (device_mouse_check_button_pressed(0, mb_left)) {
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    // Check station buttons
    var _s = 0;
    while (_s < array_length(station_buttons)) {
        var _btn = station_buttons[_s];
        if (_mx >= _btn.x1 && _mx <= _btn.x2 && _my >= _btn.y1 && _my <= _btn.y2) {
            if (array_length(assembly) < max_assembly) {
                array_push(assembly, _btn.color_idx);
                // Slide-in from below
                array_push(assembly_slide, -60);
                // Flash feedback
                station_flash[_btn.color_idx] = 12;
            }
            break;
        }
        _s += 1;
    }

    // Check SHIP button
    if (_mx >= ship_btn.x1 && _mx <= ship_btn.x2 && _my >= ship_btn.y1 && _my <= ship_btn.y2) {
        if (array_length(assembly) > 0) {
            // Try to match assembly to an order
            var _match_idx = -1;
            var _oi = 0;
            while (_oi < array_length(orders)) {
                var _recipe = orders[_oi].recipe;
                if (array_length(_recipe) == array_length(assembly)) {
                    var _match = true;
                    var _ri = 0;
                    while (_ri < array_length(_recipe)) {
                        if (_recipe[_ri] != assembly[_ri]) {
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
                // Complete the order!
                var _order = orders[_match_idx];
                var _base_reward = _order.reward;

                // Level bonus: +10% per level
                var _level_mult = 1.0 + (level - 1) * 0.1;

                // Quick completion bonus: extra if >50% timer remaining
                var _time_ratio = _order.timer / _order.max_timer;
                var _speed_bonus = 0;
                if (_time_ratio > 0.5) {
                    _speed_bonus = floor(_base_reward * 0.5);
                }

                var _earned = floor((_base_reward + _speed_bonus) * combo * _level_mult);
                points += _earned;

                // Screen shake on ship
                shake_timer = 8;
                shake_intensity = 3;

                // Popup
                var _pop_x = window_width * 0.5;
                var _pop_y = belt_area_y + belt_area_h * 0.5;
                var _pop_text = "+" + string(_earned);
                if (_speed_bonus > 0) {
                    _pop_text += " FAST!";
                }
                if (_order.is_bonus) {
                    _pop_text += " BONUS!";
                }
                array_push(popups, {x: _pop_x, y: _pop_y, text: _pop_text, color: $0fc4f1, timer: 90, max_timer: 90});

                // Increase combo
                combo = min(combo + 1, 4);
                combo_timer = combo_max_timer;
                if (combo >= 3) {
                    array_push(popups, {x: _pop_x, y: _pop_y - 30, text: "COMBO x" + string(combo) + "!", color: $71cc2e, timer: 60, max_timer: 60});
                }

                // Remove order
                array_delete(orders, _match_idx, 1);
                orders_completed += 1;

                // Clear assembly
                assembly = [];
                assembly_slide = [];

                // Check level up
                if (orders_completed >= orders_for_next_level) {
                    level += 1;
                    orders_for_next_level += 5;
                    var _new_diff_idx = min(level - 1, array_length(diff_table) - 1);
                    var _new_diff = diff_table[_new_diff_idx];
                    num_colors = _new_diff[0];
                    order_spawn_rate = _new_diff[3] * 60;
                    layout_dirty = true;

                    array_push(popups, {x: window_width * 0.5, y: window_height * 0.5, text: "LEVEL " + string(level) + "!", color: $ffffff, timer: 120, max_timer: 120});
                }
            } else {
                // WRONG SHIP — no match found! Penalty: deduct 2s from all orders
                wrong_ship_timer = 15;
                shake_timer = 6;
                shake_intensity = 3;
                var _pi = 0;
                while (_pi < array_length(orders)) {
                    orders[_pi].timer -= 120; // 2 seconds penalty
                    if (orders[_pi].timer < 1) {
                        orders[_pi].timer = 1;
                    }
                    _pi += 1;
                }
                array_push(popups, {x: window_width * 0.5, y: belt_area_y, text: "NO MATCH! -2s", color: $3c4ce7, timer: 60, max_timer: 60});
            }
        }
    }

    // Check UNDO button
    if (_mx >= undo_btn.x1 && _mx <= undo_btn.x2 && _my >= undo_btn.y1 && _my <= undo_btn.y2) {
        if (array_length(assembly) > 0) {
            array_pop(assembly);
            array_pop(assembly_slide);
        }
    }

    // Check CLEAR button
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
    final_combo = combo;
    if (points > best_score) {
        best_score = points;
    }
    game_over_tap_delay = 90;

    if (!score_submitted) {
        score_submitted = true;
        api_submit_score(points, undefined);
        api_save_state(level, { points: points, level: level, lives: 0, orders_completed: orders_completed, combo: combo, best_score: best_score }, undefined);
    }
}

// --- Update popups ---
var _pi = array_length(popups) - 1;
while (_pi >= 0) {
    popups[_pi].timer -= 1;
    popups[_pi].y -= 0.5;
    if (popups[_pi].timer <= 0) {
        array_delete(popups, _pi, 1);
    }
    _pi -= 1;
}

// --- Conveyor animation ---
conveyor_offset = (conveyor_offset + 1) mod 20;
