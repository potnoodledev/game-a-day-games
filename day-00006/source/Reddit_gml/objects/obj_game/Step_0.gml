
if (tap_cooldown > 0) tap_cooldown--;

// === STATE 0: TITLE ===
if (game_state == 0) {
    if (mouse_check_button_pressed(mb_left)) {
        reset_game();
        start_wave();
        game_state = 1;
    }
}

// === STATE 1: PLAYING ===
else if (game_state == 1) {

    // --- Spawn customers (gated by wave) ---
    if (wave_spawned < wave_total) {
        spawn_timer--;
        if (spawn_timer <= 0) {
            spawn_customer();
            wave_spawned++;
            spawn_interval = max(80, 180 - difficulty * 12);
            spawn_timer = spawn_interval;
        }
    }

    // --- Handle tap ---
    if (mouse_check_button_pressed(mb_left) && tap_cooldown <= 0) {
        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);
        var _gw = display_get_gui_width();
        var _gh = display_get_gui_height();

        // Layout must match Draw_64
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

        // --- Check queue tap ---
        var _tapped_queue = false;
        var _queue_slot_h = _table_area_h / queue_max;

        for (var _i = 0; _i < queue_count; _i++) {
            var _qy = _table_area_top + _i * _queue_slot_h;
            if (_mx >= _queue_x && _mx <= _queue_x + _queue_w
                && _my >= _qy && _my <= _qy + _queue_slot_h) {
                // Tapped queue slot _i
                if (selected_queue == _i) {
                    // Deselect
                    selected_queue = -1;
                } else {
                    // Select (or switch)
                    selected_queue = _i;
                }
                _tapped_queue = true;
                tap_cooldown = 8;
                break;
            }
        }

        // --- Check table tap ---
        if (!_tapped_queue) {
            for (var _i = 0; _i < 6; _i++) {
                // Skip locked tables
                if (_i >= tables_unlocked) continue;

                var _col = _i mod 3;
                var _row = _i div 3;
                var _tx = _table_left + _col * (_table_w + _pad);
                var _ty = _table_area_top + _row * (_table_h + _pad);

                if (_mx >= _tx && _mx <= _tx + _table_w && _my >= _ty && _my <= _ty + _table_h) {

                    // Compute which seat quadrant was tapped
                    var _seat_col = (_mx - _tx < _table_w * 0.5) ? 0 : 1;
                    var _seat_row = (_my - _ty < _table_h * 0.5) ? 0 : 1;
                    var _si = _seat_row * 2 + _seat_col;

                    // Skip locked seats
                    if (_si >= table_seats[_i]) {
                        // If queue selected, just deselect
                        if (selected_queue >= 0) selected_queue = -1;
                        break;
                    }

                    if (selected_queue >= 0) {
                        // --- Two-tap seating flow ---
                        if (table_state[_i][_si] == 0) {
                            // Empty seat: seat the selected customer
                            seat_customer(selected_queue, _i, _si);
                            tap_cooldown = 8;
                        } else if (table_state[_i][_si] == 1) {
                            // Waiting for order -> send to kitchen
                            var _slot = -1;
                            if (!kitchen_occupied[0]) _slot = 0;
                            else if (!kitchen_occupied[1]) _slot = 1;

                            if (_slot >= 0) {
                                kitchen_occupied[_slot] = true;
                                kitchen_table[_slot] = _i;
                                kitchen_seat[_slot] = _si;
                                kitchen_food[_slot] = table_food[_i][_si];
                                var _cook = 120 + difficulty * 8;
                                if (_cook > 240) _cook = 240;
                                kitchen_cook_time[_slot] = _cook;
                                kitchen_progress[_slot] = 0;
                                table_state[_i][_si] = 2;
                                tap_cooldown = 8;
                            }
                            selected_queue = -1;
                        } else if (table_state[_i][_si] == 4) {
                            // Ready to pay -> collect tip
                            var _ratio = table_patience[_i][_si] / table_max_patience[_i][_si];
                            var _tip = 1;
                            if (_ratio > 0.6) _tip = 3;
                            else if (_ratio > 0.3) _tip = 2;

                            combo++;
                            if (combo >= 3) _tip += 1;
                            if (combo >= 6) _tip += 1;

                            points += _tip;
                            customers_served++;
                            wave_served++;

                            spawn_float_text(_mx, _my, $"+{_tip}", make_colour_rgb(255, 215, 0), 45);

                            table_state[_i][_si] = 0;
                            tap_cooldown = 8;
                            selected_queue = -1;
                        } else {
                            // Other occupied state — just deselect
                            selected_queue = -1;
                        }
                    } else {
                        // --- No selection: normal table actions ---
                        // Waiting for order -> send to kitchen
                        if (table_state[_i][_si] == 1) {
                            var _slot = -1;
                            if (!kitchen_occupied[0]) _slot = 0;
                            else if (!kitchen_occupied[1]) _slot = 1;

                            if (_slot >= 0) {
                                kitchen_occupied[_slot] = true;
                                kitchen_table[_slot] = _i;
                                kitchen_seat[_slot] = _si;
                                kitchen_food[_slot] = table_food[_i][_si];
                                var _cook = 120 + difficulty * 8;
                                if (_cook > 240) _cook = 240;
                                kitchen_cook_time[_slot] = _cook;
                                kitchen_progress[_slot] = 0;
                                table_state[_i][_si] = 2;
                                tap_cooldown = 8;
                            }
                        }
                        // Ready to pay -> collect tip
                        else if (table_state[_i][_si] == 4) {
                            var _ratio = table_patience[_i][_si] / table_max_patience[_i][_si];
                            var _tip = 1;
                            if (_ratio > 0.6) _tip = 3;
                            else if (_ratio > 0.3) _tip = 2;

                            combo++;
                            if (combo >= 3) _tip += 1;
                            if (combo >= 6) _tip += 1;

                            points += _tip;
                            customers_served++;
                            wave_served++;

                            spawn_float_text(_mx, _my, $"+{_tip}", make_colour_rgb(255, 215, 0), 45);

                            table_state[_i][_si] = 0;
                            tap_cooldown = 8;
                        }
                    }
                    break;
                }
            }
        }
    }

    // --- Update kitchen ---
    for (var _i = 0; _i < 2; _i++) {
        if (kitchen_occupied[_i]) {
            kitchen_progress[_i]++;
            if (kitchen_progress[_i] >= kitchen_cook_time[_i]) {
                var _t = kitchen_table[_i];
                var _s = kitchen_seat[_i];
                if (table_state[_t][_s] == 2) {
                    table_state[_t][_s] = 3;
                    table_eat_timer[_t][_s] = 90;
                }
                kitchen_occupied[_i] = false;
                kitchen_table[_i] = -1;
                kitchen_seat[_i] = -1;
            }
        }
    }

    // --- Update tables (nested: table x seat) ---
    for (var _i = 0; _i < 6; _i++) {
        if (_i >= tables_unlocked) continue;
        for (var _j = 0; _j < table_seats[_i]; _j++) {
            // Drain patience (waiting or in kitchen)
            if (table_state[_i][_j] == 1 || table_state[_i][_j] == 2) {
                table_patience[_i][_j]--;
                if (table_patience[_i][_j] <= 0) {
                    table_state[_i][_j] = 0;
                    lives--;
                    combo = 0;
                    wave_lost++;
                    shake_amount = 6;

                    // Clear kitchen slot if this seat had an order cooking
                    for (var _k = 0; _k < 2; _k++) {
                        if (kitchen_occupied[_k] && kitchen_table[_k] == _i && kitchen_seat[_k] == _j) {
                            kitchen_occupied[_k] = false;
                            kitchen_table[_k] = -1;
                            kitchen_seat[_k] = -1;
                        }
                    }

                    if (lives <= 0) {
                        game_state = 2;
                        api_submit_score(points, undefined);
                    }
                }
            }

            // Eating countdown
            if (table_state[_i][_j] == 3) {
                table_eat_timer[_i][_j]--;
                if (table_eat_timer[_i][_j] <= 0) {
                    table_state[_i][_j] = 4;
                }
            }
        }
    }

    // --- Update queue patience ---
    var _qi = 0;
    while (_qi < queue_count) {
        queue_patience[_qi]--;
        if (queue_patience[_qi] <= 0) {
            // Customer leaves queue — lose life, reset combo
            lives--;
            combo = 0;
            wave_lost++;
            shake_amount = 6;

            // Fix selected_queue index after removal
            if (selected_queue == _qi) {
                selected_queue = -1;
            } else if (selected_queue > _qi) {
                selected_queue--;
            }

            // Compact queue arrays
            for (var _j = _qi; _j < queue_count - 1; _j++) {
                queue_food[_j] = queue_food[_j + 1];
                queue_avatar[_j] = queue_avatar[_j + 1];
                queue_patience[_j] = queue_patience[_j + 1];
                queue_max_patience[_j] = queue_max_patience[_j + 1];
            }
            queue_count--;

            if (lives <= 0) {
                game_state = 2;
                api_submit_score(points, undefined);
                break;
            }
            // Don't increment _qi — the next customer slid into this slot
        } else {
            _qi++;
        }
    }

    // --- Wave completion check (only if still alive) ---
    if (game_state == 1 && wave_spawned >= wave_total && queue_count == 0) {
        var _all_tables_clear = true;
        for (var _i = 0; _i < tables_unlocked; _i++) {
            for (var _j = 0; _j < table_seats[_i]; _j++) {
                if (table_state[_i][_j] != 0) { _all_tables_clear = false; break; }
            }
            if (!_all_tables_clear) break;
        }
        var _all_kitchen_clear = true;
        for (var _i = 0; _i < 2; _i++) {
            if (kitchen_occupied[_i]) { _all_kitchen_clear = false; break; }
        }
        if (_all_tables_clear && _all_kitchen_clear) {
            game_state = 3;
        }
    }
}

// === STATE 3: WAVE SUMMARY ===
else if (game_state == 3) {
    if (mouse_check_button_pressed(mb_left)) {
        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);
        var _gw = display_get_gui_width();
        var _gh = display_get_gui_height();
        var _ss = max(1, _gh / 500);

        // Buy table button hitbox (must match Draw_64 layout)
        var _bought = false;
        if (tables_unlocked < 6) {
            var _btn_w = _gw * 0.55;
            var _btn_h = _ss * 28;
            var _btn_x = _gw * 0.5 - _btn_w * 0.5;
            var _btn_y = _gh * 0.53 - _btn_h * 0.5;

            if (_mx >= _btn_x && _mx <= _btn_x + _btn_w
                && _my >= _btn_y && _my <= _btn_y + _btn_h
                && points >= table_cost) {
                points -= table_cost;
                tables_unlocked++;
                table_cost = 20 * tables_unlocked;
                _bought = true;
            }
        }

        // Seat upgrade row hitbox (at 63% height)
        if (!_bought) {
            var _row_w = _gw * 0.7;
            var _row_x = _gw * 0.5 - _row_w * 0.5;
            var _row_y = _gh * 0.63 - _ss * 14;
            var _row_h = _ss * 28;
            var _box_w = _row_w / 6;

            if (_mx >= _row_x && _mx <= _row_x + _row_w
                && _my >= _row_y && _my <= _row_y + _row_h) {
                // Which table box was tapped?
                var _ti = floor((_mx - _row_x) / _box_w);
                if (_ti >= 0 && _ti < tables_unlocked) {
                    var _cur_seats = table_seats[_ti];
                    if (_cur_seats < 4) {
                        var _seat_cost = 10 * _cur_seats;
                        if (points >= _seat_cost) {
                            points -= _seat_cost;
                            table_seats[_ti]++;
                            _bought = true;
                        }
                    }
                }
            }
        }

        // If didn't buy, tap advances to next wave
        if (!_bought) {
            wave++;
            clear_all_entities();
            start_wave();
            game_state = 1;
        }
    }
}

// === STATE 2: GAME OVER ===
else if (game_state == 2) {
    if (mouse_check_button_pressed(mb_left)) {
        points = 0;
        reset_game();
        start_wave();
        game_state = 1;
    }
}
