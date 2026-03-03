
var _w = window_get_width();
var _h = window_get_height();
window_width = _w;
window_height = _h;

// Background hue cycle
bg_hue += 0.3;
if (bg_hue >= 360) bg_hue -= 360;

// Title pulse
title_pulse += 0.05;

// Stripe animation
stripe_offset += scroll_speed * 0.5;
if (stripe_offset > 40) stripe_offset -= 40;

// Update blob particles
for (var _i = 0; _i < blob_count; _i++) {
    blob_x[_i] += sin(current_time * 0.002 + _i) * blob_spd[_i];
    blob_y[_i] += cos(current_time * 0.003 + _i * 1.7) * blob_spd[_i];
    if (blob_x[_i] > 40) blob_x[_i] = -40;
    if (blob_x[_i] < -40) blob_x[_i] = 40;
    if (blob_y[_i] > 40) blob_y[_i] = -40;
    if (blob_y[_i] < -40) blob_y[_i] = 40;
}

// ============ STATE MACHINE ============

// --- STATE 0: LOADING ---
if (game_state == 0) {
    // Waiting for api_load_state callback
}

// --- STATE 1: TITLE SCREEN ---
else if (game_state == 1) {
    title_stars_timer += 1;

    if (device_mouse_check_button_pressed(0, mb_left)) {
        // Generate first round
        game_state = 2;
        troops = 10;
        current_gate = 0;
        scroll_y = 0;

        // Generate gates for this round
        var _pair_count = 6 + min(round_num - 1, 6);
        if (_pair_count > gate_max) _pair_count = gate_max;
        gate_count = _pair_count;

        // Difficulty parameters
        var _base_enemy = 20 + round_num * 15 + round_num * round_num * 3;

        // Generate gate pairs
        for (var _g = 0; _g < gate_count; _g++) {
            gate_y[_g] = -200 - _g * gate_spacing;
            gate_passed[_g] = false;
            gate_choice[_g] = -1;

            // Decide gate types based on round difficulty
            var _difficulty = round_num;
            var _roll_left = irandom(100);
            var _roll_right = irandom(100);

            // Left gate
            if (_difficulty <= 2 || _roll_left < 50) {
                // Mostly good gates early
                if (irandom(100) < 70) {
                    gate_left_op[_g] = 0; // add
                    gate_left_val[_g] = irandom_range(3, 8 + round_num * 2);
                } else {
                    gate_left_op[_g] = 2; // multiply
                    gate_left_val[_g] = irandom_range(2, 3);
                }
            } else {
                // Mix in bad gates
                var _type = irandom(3);
                if (_type == 0) {
                    gate_left_op[_g] = 0;
                    gate_left_val[_g] = irandom_range(2, 6);
                } else if (_type == 1) {
                    gate_left_op[_g] = 1; // subtract
                    gate_left_val[_g] = irandom_range(2, 5 + round_num);
                } else if (_type == 2) {
                    gate_left_op[_g] = 2;
                    gate_left_val[_g] = irandom_range(2, 4);
                } else {
                    gate_left_op[_g] = 3; // divide
                    gate_left_val[_g] = irandom_range(2, 3);
                }
            }

            // Right gate - try to make it different from left
            if (_difficulty <= 2 || _roll_right < 50) {
                if (irandom(100) < 70) {
                    gate_right_op[_g] = 0;
                    gate_right_val[_g] = irandom_range(3, 8 + round_num * 2);
                } else {
                    gate_right_op[_g] = 2;
                    gate_right_val[_g] = irandom_range(2, 3);
                }
            } else {
                var _type = irandom(3);
                if (_type == 0) {
                    gate_right_op[_g] = 0;
                    gate_right_val[_g] = irandom_range(2, 6);
                } else if (_type == 1) {
                    gate_right_op[_g] = 1;
                    gate_right_val[_g] = irandom_range(2, 5 + round_num);
                } else if (_type == 2) {
                    gate_right_op[_g] = 2;
                    gate_right_val[_g] = irandom_range(2, 4);
                } else {
                    gate_right_op[_g] = 3;
                    gate_right_val[_g] = irandom_range(2, 3);
                }
            }

            // Ensure at least one gate per pair is positive
            if (_g < 2) {
                // First two gates always have a good option
                gate_left_op[_g] = 0;
                gate_left_val[_g] = irandom_range(5, 10 + round_num * 2);
            }
        }

        // Set enemy troops - scale with round
        enemy_troops = _base_enemy;

        // Ensure solvable: simulate optimal path
        var _sim_troops = 10;
        for (var _g = 0; _g < gate_count; _g++) {
            // Simulate picking the better gate
            var _left_result = _sim_troops;
            if (gate_left_op[_g] == 0) _left_result = _sim_troops + gate_left_val[_g];
            else if (gate_left_op[_g] == 1) _left_result = _sim_troops - gate_left_val[_g];
            else if (gate_left_op[_g] == 2) _left_result = _sim_troops * gate_left_val[_g];
            else if (gate_left_op[_g] == 3) _left_result = floor(_sim_troops / gate_left_val[_g]);

            var _right_result = _sim_troops;
            if (gate_right_op[_g] == 0) _right_result = _sim_troops + gate_right_val[_g];
            else if (gate_right_op[_g] == 1) _right_result = _sim_troops - gate_right_val[_g];
            else if (gate_right_op[_g] == 2) _right_result = _sim_troops * gate_right_val[_g];
            else if (gate_right_op[_g] == 3) _right_result = floor(_sim_troops / gate_right_val[_g]);

            _sim_troops = max(_left_result, _right_result);
            if (_sim_troops < 1) _sim_troops = 1;
        }

        // Adjust enemy to be beatable (70-90% of optimal)
        var _ratio = random_range(0.6, 0.85);
        enemy_troops = max(10, floor(_sim_troops * _ratio));

        // Scroll speed scales with round
        scroll_speed = 2 + min(round_num * 0.3, 3);

        // Fake progress
        fake_progress = 0;
        fake_progress_target = random_range(0.3, 0.7);
    }
}

// --- STATE 2: RUNNING ---
else if (game_state == 2) {
    // Scroll gates down
    for (var _g = 0; _g < gate_count; _g++) {
        gate_y[_g] += scroll_speed;
    }
    scroll_y += scroll_speed;

    // Update fake progress bar
    var _progress_per_gate = 1.0 / gate_count;
    fake_progress = current_gate * _progress_per_gate;

    // Swipe input
    if (device_mouse_check_button_pressed(0, mb_left)) {
        touch_start_x = device_mouse_x_to_gui(0);
        touch_start_y = device_mouse_y_to_gui(0);
        touch_active = true;
    }

    if (touch_active && device_mouse_check_button_released(0, mb_left)) {
        var _dx = device_mouse_x_to_gui(0) - touch_start_x;
        if (abs(_dx) > swipe_threshold) {
            if (_dx < 0) pending_swipe = -1;
            else pending_swipe = 1;
        }
        touch_active = false;
    }

    // Also allow tapping left/right half of screen as alternative to swipe
    if (device_mouse_check_button_pressed(0, mb_left)) {
        var _tap_x = device_mouse_x_to_gui(0);
        if (_tap_x < _w * 0.4) pending_swipe = -1;
        else if (_tap_x > _w * 0.6) pending_swipe = 1;
    }

    // Check if next gate has reached the player
    if (current_gate < gate_count) {
        var _army_y = _h * 0.78;
        var _gate_screen_y = gate_y[current_gate];

        if (_gate_screen_y >= _army_y - 30) {
            // Gate reached the player - apply choice
            var _picked = -1;

            if (pending_swipe == -1) {
                _picked = 0; // left
            } else if (pending_swipe == 1) {
                _picked = 1; // right
            }

            // If no swipe, auto-pick randomly (penalty for indecision)
            if (_picked == -1) {
                _picked = irandom(1);
            }

            // Consume the swipe
            pending_swipe = 0;

            gate_choice[current_gate] = _picked;
            gate_passed[current_gate] = true;

            // Apply gate math
            var _op = 0;
            var _val = 0;
            if (_picked == 0) {
                _op = gate_left_op[current_gate];
                _val = gate_left_val[current_gate];
            } else {
                _op = gate_right_op[current_gate];
                _val = gate_right_val[current_gate];
            }

            var _old_troops = troops;
            if (_op == 0) troops += _val;
            else if (_op == 1) troops -= _val;
            else if (_op == 2) troops *= _val;
            else if (_op == 3) troops = floor(troops / max(_val, 1));

            if (troops < 1) troops = 1;

            // Score popup
            var _diff = troops - _old_troops;
            if (_diff > 0) {
                score_popup = "+" + string(_diff);
            } else if (_diff < 0) {
                score_popup = string(_diff);
            } else {
                score_popup = "=";
            }
            score_popup_timer = 40;

            current_gate += 1;
        }
    }

    // All gates passed - enter battle
    if (current_gate >= gate_count) {
        // Check if all gates have scrolled past
        var _last_gate_y = gate_y[gate_count - 1];
        if (_last_gate_y > _h * 0.5) {
            game_state = 3;
            battle_timer = 0;
            battle_clash_x = _w * 0.5;
            battle_clash_y = _h * 0.45;

            if (troops >= enemy_troops) {
                battle_result = 1; // win
            } else {
                battle_result = -1; // lose
            }
        }
    }

    // Decrement score popup timer
    if (score_popup_timer > 0) score_popup_timer -= 1;
}

// --- STATE 3: BATTLE ---
else if (game_state == 3) {
    battle_timer += 1;

    if (battle_timer >= battle_duration) {
        game_state = 4;
        result_timer = 0;

        if (battle_result == 1) {
            // Win - award points
            var _base_pts = enemy_troops * round_num;
            var _surplus = max(0, troops - enemy_troops) * 10;
            var _round_bonus = 500 * round_num;
            var _earned = _base_pts + _surplus + _round_bonus;
            points += _earned;
            score_popup = "+" + string(_earned);
            score_popup_timer = 90;
        } else {
            // Lose
            lives -= 1;
            score_popup = "ELIMINATED!";
            score_popup_timer = 90;
        }
    }
}

// --- STATE 4: RESULT ---
else if (game_state == 4) {
    result_timer += 1;

    if (score_popup_timer > 0) score_popup_timer -= 1;

    if (result_timer > 60 && device_mouse_check_button_pressed(0, mb_left)) {
        if (battle_result == 1) {
            // Next round
            round_num += 1;
            troops = 10;
            current_gate = 0;
            scroll_y = 0;
            game_state = 1; // back to title briefly to generate next round
        } else {
            if (lives <= 0) {
                // Game over
                game_state = 5;
                api_submit_score(points, function(_status, _ok, _result) {});
            } else {
                // Retry same round
                troops = 10;
                current_gate = 0;
                scroll_y = 0;
                game_state = 1;
            }
        }
    }
}

// --- STATE 5: GAME OVER ---
else if (game_state == 5) {
    if (device_mouse_check_button_pressed(0, mb_left)) {
        // Check if tap is on the fake "rate 5 stars" area or anywhere really
        round_num = 1;
        lives = 3;
        points = 0;
        troops = 10;
        game_state = 1;
    }
}
