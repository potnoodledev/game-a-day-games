
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
        popups = [];
        score_submitted = false;
        orders_for_next_level = 5;
        var _diff = diff_table[0];
        num_colors = _diff[0];
        order_spawn_rate = _diff[3] * 60;
        order_spawn_timer = 60;
        layout_dirty = true;
    }
    exit;
}

// === STATE 1: PLAYING ===

// --- Update order timers ---
var _i = array_length(orders) - 1;
while (_i >= 0) {
    orders[_i].timer -= 1;
    if (orders[_i].timer <= 0) {
        // Order expired — lose a life
        lives -= 1;
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

    var _order = {
        recipe: _recipe,
        timer: _timer_frames,
        max_timer: _timer_frames,
        reward: _reward
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
            }
            break;
        }
        _s += 1;
    }

    // Check SHIP button
    if (_mx >= ship_btn.x1 && _mx <= ship_btn.x2 && _my >= ship_btn.y1 && _my <= ship_btn.y2) {
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

            // Popup
            var _pop_x = window_width * 0.5;
            var _pop_y = belt_area_y + belt_area_h * 0.5;
            var _pop_text = "+" + string(_earned);
            if (_speed_bonus > 0) {
                _pop_text += " FAST!";
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
        }
    }

    // Check CLEAR button
    if (_mx >= clear_btn.x1 && _mx <= clear_btn.x2 && _my >= clear_btn.y1 && _my <= clear_btn.y2) {
        assembly = [];
    }
}

// --- Check game over ---
if (lives <= 0) {
    game_state = 2;
    final_score = points;
    final_level = level;
    final_orders = orders_completed;
    final_combo = combo;
    game_over_tap_delay = 90;

    if (!score_submitted) {
        score_submitted = true;
        api_submit_score(points, undefined);
        api_save_state(level, { points: points, level: level, lives: 0, orders_completed: orders_completed, combo: combo }, undefined);
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
