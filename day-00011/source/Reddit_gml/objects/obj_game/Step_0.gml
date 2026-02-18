// ========================================
// RICOCHET — Step_0.gml
// ========================================

// --- Wait for state load ---
if (game_state == 0) {
    if (state_loaded) {
        if (state_data != undefined) {
            try {
                points = state_data.points;
                round_num = state_data.round_num;
                level = state_data.level;
            } catch (_ex) {
                points = 0;
                round_num = 0;
                level = 0;
            }
        }
        calc_layout();
        start_round();
        alarm[0] = room_speed * 20;
    }
    exit;
}

// --- Screen shake update ---
if (shake_timer > 0) {
    shake_timer--;
    var _i = shake_intensity * (shake_timer / max(shake_timer + 5, 1));
    shake_x = random_range(-_i, _i);
    shake_y = random_range(-_i, _i);
    if (shake_timer <= 0) {
        shake_x = 0;
        shake_y = 0;
    }
}

// --- FX update ---
for (var _i = array_length(fx) - 1; _i >= 0; _i--) {
    fx[_i].t++;
    if (fx[_i].t >= fx[_i].mt) {
        array_delete(fx, _i, 1);
    }
}

// --- Popup update ---
for (var _i = array_length(popups) - 1; _i >= 0; _i--) {
    popups[_i].y -= 1.2;
    popups[_i].t--;
    if (popups[_i].t <= 0) {
        array_delete(popups, _i, 1);
    }
}

// --- Combo timer ---
if (combo_timer > 0) {
    combo_timer--;
    if (combo_timer <= 0) {
        combo_count = 0;
        combo_text = "";
    }
}

// --- Round message timer ---
if (round_msg_timer > 0) round_msg_timer--;

// --- Target pulse ---
for (var _i = 0; _i < array_length(targets); _i++) {
    if (targets[_i].pulse > 0) targets[_i].pulse -= 0.05;
}

// =========================================
// STATE: AIMING
// =========================================
if (game_state == 1) {
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    if (device_mouse_check_button_pressed(0, mb_left)) {
        aim_active = true;
        aim_sx = _mx;
        aim_sy = _my;
    }

    if (aim_active && device_mouse_check_button(0, mb_left)) {
        var _dx = aim_sx - _mx;
        var _dy = aim_sy - _my;
        var _dist = sqrt(_dx * _dx + _dy * _dy);
        if (_dist > 5) {
            aim_angle = point_direction(0, 0, _dx, _dy);
            aim_power = clamp(_dist / 100, 0.3, 1);
        }
    }

    if (aim_active && device_mouse_check_button_released(0, mb_left)) {
        aim_active = false;
        var _dx = aim_sx - _mx;
        var _dy = aim_sy - _my;
        var _dist = sqrt(_dx * _dx + _dy * _dy);
        if (_dist > 20) {
            var _angle = point_direction(0, 0, _dx, _dy);
            launch_ball(_angle);
        }
    }
}

// =========================================
// STATE: BALL MOVING
// =========================================
if (game_state == 2) {
    // Move ball
    ball_x += ball_vx;
    ball_y += ball_vy;

    // Trail
    array_push(ball_trail, [ball_x, ball_y]);
    if (array_length(ball_trail) > 20) array_delete(ball_trail, 0, 1);

    // Wall bounces
    reflect_ball_wall();

    // Obstacle bounces
    for (var _i = 0; _i < array_length(obstacles); _i++) {
        reflect_ball_obstacle(
            obstacles[_i].x1, obstacles[_i].y1,
            obstacles[_i].x2, obstacles[_i].y2
        );
    }

    // Target hits
    check_target_hits();

    // Check if all targets hit (stop ball immediately)
    if (all_targets_hit()) {
        on_ball_stop();
    }
    // Check max bounces
    else if (ball_bounces >= RC_MAX_BOUNCES) {
        on_ball_stop();
    }
}

// =========================================
// STATE: ROUND COMPLETE
// =========================================
if (game_state == 3) {
    // Wait for tap to start next round
    if (device_mouse_check_button_pressed(0, mb_left)) {
        start_round();
    }
}

// =========================================
// STATE: GAME OVER
// =========================================
if (game_state == 4) {
    // Submit score once
    if (!score_submitted) {
        score_submitted = true;
        api_submit_score(points, function(_status, _ok, _result, _payload) {});
    }

    // Wait for tap to restart
    if (device_mouse_check_button_pressed(0, mb_left)) {
        reset_game();
    }
}
