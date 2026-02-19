// ========================================
// GAME OF LIFE — Step_0.gml (Rogue-like)
// ========================================

// --- Wait for state load ---
if (game_state == 0) {
    if (state_loaded) {
        // Each game starts fresh — best score tracked on leaderboard
        // Don't restore points from state (avoids HTML5 obfuscation issues
        // where state_data.points silently returns undefined)
        points = 0;
        level = 0;
        calc_layout();
        start_round();
        alarm[0] = room_speed * 15;
    }
    exit;
}

// --- Popup update ---
for (var _i = array_length(popups) - 1; _i >= 0; _i--) {
    popups[_i].y -= 0.8;
    popups[_i].t--;
    if (popups[_i].t <= 0) {
        array_delete(popups, _i, 1);
    }
}

// --- Transition timer ---
if (transition_timer > 0) {
    transition_timer--;
    exit;
}

// =========================================
// STATE: PLACING
// =========================================
if (game_state == 1) {
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    var _col = floor((_mx - grid_offset_x) / cell_size);
    var _row = floor((_my - grid_offset_y) / cell_size);
    var _on_grid = (_col >= 0 && _col < grid_cols && _row >= 0 && _row < grid_rows);

    // Touch press
    if (device_mouse_check_button_pressed(0, mb_left)) {
        // Check GO button
        if (_mx >= go_btn_x && _mx <= go_btn_x + go_btn_w
            && _my >= btn_y && _my <= btn_y + btn_h) {
            if (cells_placed > 0) {
                sim_generation = 0;
                sim_population = count_population();
                sim_peak_population = sim_population;
                sim_stable_count = 0;
                sim_last_pop = sim_population;
                sim_timer = 0;
                sim_fast = false;
                game_state = 2;
            }
        }
        // Check CLEAR button
        else if (_mx >= clr_btn_x && _mx <= clr_btn_x + clr_btn_w
                 && _my >= btn_y && _my <= btn_y + btn_h) {
            clear_grid();
        }
        // Grid painting (not on walls)
        else if (_on_grid && !is_wall(_col, _row)) {
            var _current = grid_get(_col, _row);
            if (_current == 1) {
                touch_painting = 0;
                grid_set(_col, _row, 0);
                cells_placed--;
            } else if (cells_placed < cell_budget) {
                touch_painting = 1;
                grid_set(_col, _row, 1);
                cells_placed++;
            }
            last_toggled_col = _col;
            last_toggled_row = _row;
        }
    }

    // Touch drag (continue painting)
    if (device_mouse_check_button(0, mb_left) && touch_painting != -1) {
        if (_on_grid && !is_wall(_col, _row)
            && (_col != last_toggled_col || _row != last_toggled_row)) {
            if (touch_painting == 1 && grid_get(_col, _row) == 0 && cells_placed < cell_budget) {
                grid_set(_col, _row, 1);
                cells_placed++;
                last_toggled_col = _col;
                last_toggled_row = _row;
            } else if (touch_painting == 0 && grid_get(_col, _row) == 1) {
                grid_set(_col, _row, 0);
                cells_placed--;
                last_toggled_col = _col;
                last_toggled_row = _row;
            }
        }
    }

    // Touch released
    if (device_mouse_check_button_released(0, mb_left)) {
        touch_painting = -1;
        last_toggled_col = -1;
        last_toggled_row = -1;
    }
}

// =========================================
// STATE: SIMULATING
// =========================================
if (game_state == 2) {
    // Tap to fast-forward
    if (device_mouse_check_button_pressed(0, mb_left)) {
        sim_fast = !sim_fast;
    }

    var _spd = sim_fast ? 1 : sim_speed;
    sim_timer++;
    if (sim_timer >= _spd) {
        sim_timer = 0;
        sim_step();

        // End: all cells dead
        if (sim_population == 0) {
            end_round();
        }
        // End: max generations
        else if (sim_generation >= sim_max_gens) {
            end_round();
        }
        // End: stable pattern (no change for 20 gens)
        else if (sim_stable_count >= 20) {
            end_round();
        }
    }
}

// =========================================
// STATE: POWER-UP SELECTION
// =========================================
if (game_state == 3) {
    if (device_mouse_check_button_pressed(0, mb_left)) {
        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);

        // Card 1
        if (_mx >= card_x && _mx <= card_x + card_w
            && _my >= card1_y && _my <= card1_y + card_h) {
            apply_powerup(powerup_options[0]);
            start_round();
        }
        // Card 2
        else if (_mx >= card_x && _mx <= card_x + card_w
                 && _my >= card2_y && _my <= card2_y + card_h) {
            apply_powerup(powerup_options[1]);
            start_round();
        }
    }
}

// =========================================
// STATE: GAME OVER
// =========================================
if (game_state == 4) {
    if (!score_submitted) {
        score_submitted = true;
        api_submit_score(points, function(_status, _ok, _result, _payload) {});
    }

    if (device_mouse_check_button_pressed(0, mb_left)) {
        reset_game();
    }
}
