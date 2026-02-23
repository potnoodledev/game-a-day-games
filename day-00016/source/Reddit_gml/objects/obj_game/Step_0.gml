/// Step_0 — Game logic (Wave System)

if (game_state == 0) exit;

// ========================
// COMMON: Update cosmetics
// ========================
for (var _i = array_length(score_popups) - 1; _i >= 0; _i--) {
    score_popups[_i].y -= 1.5;
    score_popups[_i].alpha -= 0.018;
    if (score_popups[_i].alpha <= 0) {
        array_delete(score_popups, _i, 1);
    }
}

for (var _i = array_length(falling_objects) - 1; _i >= 0; _i--) {
    falling_objects[_i].vy += 0.5;
    falling_objects[_i].y += falling_objects[_i].vy;
    falling_objects[_i].rot += falling_objects[_i].spin;
    if (falling_objects[_i].y > window_height + 200) {
        array_delete(falling_objects, _i, 1);
    }
}

// ========================
// STATE 1: WAVE INTRO
// ========================
if (game_state == 1) {
    intro_timer--;
    if (intro_timer <= 0) {
        game_state = 2;
    }
}

// ========================
// STATE 2: PLAYING
// ========================
if (game_state == 2) {

    // How many shapes remaining in this wave
    var _remaining = array_length(wave_shapes) - wave_index;

    // --- Input: tap to drop ---
    if (!drop_active && _remaining > 0 && device_mouse_check_button_pressed(0, mb_left)) {
        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);

        if (_my > window_height * 0.22) {
            var _next = wave_shapes[wave_index];
            wave_index++;

            var _target_x_off = clamp((_mx - beam_cx) / beam_half, -0.88, 0.88);

            drop_active = true;
            drop_type_idx = _next.type_idx;
            drop_weight = _next.weight;
            drop_x = beam_cx + _target_x_off * beam_half;
            drop_y = window_height * 0.05;
            drop_target_x_off = _target_x_off;
            drop_speed = window_height * 0.04;
        }
    }

    // --- Update dropping object ---
    if (drop_active) {
        drop_y += drop_speed;

        var _d = drop_target_x_off * beam_half;
        var _obj_hh = unit_size * obj_cfg_h_mult[drop_type_idx] * 0.5;
        var _surface_y = beam_cy + _d * sin(beam_angle) - cos(beam_angle) * (beam_thickness * 0.5 + _obj_hh);

        if (drop_y >= _surface_y) {
            drop_active = false;

            // Combo check
            if (abs(beam_angle) < combo_safe) {
                combo++;
            } else {
                combo = 0;
            }
            multiplier = min(3, 1 + (combo div 5));

            // Score
            total_placed++;
            var _base_score = 10 * wave;
            var _center_bonus = 0;
            if (abs(drop_target_x_off) < 0.15) _center_bonus = 5 * wave;
            var _earned = (_base_score + _center_bonus) * multiplier;
            points += _earned;

            // Add object to beam
            array_push(objects_on_beam, {
                type_idx: drop_type_idx,
                weight: drop_weight,
                x_off: drop_target_x_off,
            });

            // Landing impulse
            beam_angular_vel += drop_target_x_off * drop_weight * 0.004;

            // Score popup
            array_push(score_popups, {
                x: drop_x,
                y: _surface_y - unit_size,
                text: "+" + string(_earned),
                alpha: 1.0,
            });

            // Check if all shapes placed — start hold phase
            if (wave_index >= array_length(wave_shapes) ) {
                game_state = 3;
                hold_timer = hold_duration;
            }
        }
    }

    // --- Physics ---
    var _net_torque = 0;
    for (var _i = 0; _i < array_length(objects_on_beam); _i++) {
        _net_torque += objects_on_beam[_i].weight * objects_on_beam[_i].x_off;
    }
    _net_torque += wind_force;

    beam_angular_vel += _net_torque * torque_factor;
    beam_angular_vel *= phys_damping;
    beam_angle += beam_angular_vel;

    // Slide objects
    var _diff_slide = slide_factor * (1 + wave * 0.02);
    for (var _i = 0; _i < array_length(objects_on_beam); _i++) {
        var _obj = objects_on_beam[_i];
        var _sm = obj_cfg_slide[_obj.type_idx];
        _obj.x_off += sin(beam_angle) * _diff_slide * _sm / max(_obj.weight, 0.5);
    }

    // Collision resolution
    for (var _i = 0; _i < array_length(objects_on_beam) - 1; _i++) {
        for (var _j = _i + 1; _j < array_length(objects_on_beam); _j++) {
            if (objects_on_beam[_j].x_off < objects_on_beam[_i].x_off) {
                var _tmp = objects_on_beam[_i];
                objects_on_beam[_i] = objects_on_beam[_j];
                objects_on_beam[_j] = _tmp;
            }
        }
    }
    for (var _i = 0; _i < array_length(objects_on_beam) - 1; _i++) {
        var _a = objects_on_beam[_i];
        var _b = objects_on_beam[_i + 1];
        var _min_dist = (obj_cfg_w_mult[_a.type_idx] + obj_cfg_w_mult[_b.type_idx]) * 0.1 * 1.05;
        var _actual = _b.x_off - _a.x_off;
        if (_actual < _min_dist) {
            var _push = (_min_dist - _actual) * 0.5;
            _a.x_off -= _push;
            _b.x_off += _push;
        }
    }

    // Objects falling off beam
    for (var _i = array_length(objects_on_beam) - 1; _i >= 0; _i--) {
        var _obj = objects_on_beam[_i];
        if (abs(_obj.x_off) > 1.05) {
            var _fd = _obj.x_off * beam_half;
            array_push(falling_objects, {
                type_idx: _obj.type_idx,
                weight: _obj.weight,
                x: beam_cx + _fd * cos(beam_angle),
                y: beam_cy + _fd * sin(beam_angle),
                vy: 2,
                rot: beam_angle,
                spin: sign(_obj.x_off) * 0.06,
            });
            array_delete(objects_on_beam, _i, 1);
        }
    }

    // Tip check — game over
    if (abs(beam_angle) > max_angle) {
        game_state = 5;
        tip_timer = 90;
        // All objects fall off
        for (var _i = 0; _i < array_length(objects_on_beam); _i++) {
            var _obj = objects_on_beam[_i];
            var _fd = _obj.x_off * beam_half;
            array_push(falling_objects, {
                type_idx: _obj.type_idx,
                weight: _obj.weight,
                x: beam_cx + _fd * cos(beam_angle),
                y: beam_cy + _fd * sin(beam_angle),
                vy: random_range(-3, 1),
                rot: beam_angle,
                spin: random_range(-0.08, 0.08),
            });
        }
        objects_on_beam = [];
        drop_active = false;
    }

    // Wind gusts (wave 5+)
    wind_timer--;
    if (wind_timer <= 0) {
        if (wave >= 5) {
            wind_force = random_range(-0.3, 0.3) * (1 + (wave - 5) * 0.15);
            wind_timer = irandom_range(90, 240);
        } else {
            wind_timer = 60;
            wind_force = 0;
        }
    }
    wind_force *= 0.992;
}

// ========================
// STATE 3: HOLDING (3s balance)
// ========================
if (game_state == 3) {

    // Physics continues during hold
    var _net_torque = 0;
    for (var _i = 0; _i < array_length(objects_on_beam); _i++) {
        _net_torque += objects_on_beam[_i].weight * objects_on_beam[_i].x_off;
    }
    _net_torque += wind_force;

    beam_angular_vel += _net_torque * torque_factor;
    beam_angular_vel *= phys_damping;
    beam_angle += beam_angular_vel;

    // Slide
    var _diff_slide = slide_factor * (1 + wave * 0.02);
    for (var _i = 0; _i < array_length(objects_on_beam); _i++) {
        var _obj = objects_on_beam[_i];
        var _sm = obj_cfg_slide[_obj.type_idx];
        _obj.x_off += sin(beam_angle) * _diff_slide * _sm / max(_obj.weight, 0.5);
    }

    // Collision
    for (var _i = 0; _i < array_length(objects_on_beam) - 1; _i++) {
        for (var _j = _i + 1; _j < array_length(objects_on_beam); _j++) {
            if (objects_on_beam[_j].x_off < objects_on_beam[_i].x_off) {
                var _tmp = objects_on_beam[_i];
                objects_on_beam[_i] = objects_on_beam[_j];
                objects_on_beam[_j] = _tmp;
            }
        }
    }
    for (var _i = 0; _i < array_length(objects_on_beam) - 1; _i++) {
        var _a = objects_on_beam[_i];
        var _b = objects_on_beam[_i + 1];
        var _min_dist = (obj_cfg_w_mult[_a.type_idx] + obj_cfg_w_mult[_b.type_idx]) * 0.1 * 1.05;
        var _actual = _b.x_off - _a.x_off;
        if (_actual < _min_dist) {
            var _push = (_min_dist - _actual) * 0.5;
            _a.x_off -= _push;
            _b.x_off += _push;
        }
    }

    // Fall-off check
    for (var _i = array_length(objects_on_beam) - 1; _i >= 0; _i--) {
        var _obj = objects_on_beam[_i];
        if (abs(_obj.x_off) > 1.05) {
            var _fd = _obj.x_off * beam_half;
            array_push(falling_objects, {
                type_idx: _obj.type_idx,
                weight: _obj.weight,
                x: beam_cx + _fd * cos(beam_angle),
                y: beam_cy + _fd * sin(beam_angle),
                vy: 2,
                rot: beam_angle,
                spin: sign(_obj.x_off) * 0.06,
            });
            array_delete(objects_on_beam, _i, 1);
        }
    }

    // Wind during hold too
    wind_timer--;
    if (wind_timer <= 0) {
        if (wave >= 5) {
            wind_force = random_range(-0.3, 0.3) * (1 + (wave - 5) * 0.15);
            wind_timer = irandom_range(90, 240);
        } else {
            wind_timer = 60;
            wind_force = 0;
        }
    }
    wind_force *= 0.992;

    // Tip check — game over
    if (abs(beam_angle) > max_angle) {
        game_state = 5;
        tip_timer = 90;
        for (var _i = 0; _i < array_length(objects_on_beam); _i++) {
            var _obj = objects_on_beam[_i];
            var _fd = _obj.x_off * beam_half;
            array_push(falling_objects, {
                type_idx: _obj.type_idx,
                weight: _obj.weight,
                x: beam_cx + _fd * cos(beam_angle),
                y: beam_cy + _fd * sin(beam_angle),
                vy: random_range(-3, 1),
                rot: beam_angle,
                spin: random_range(-0.08, 0.08),
            });
        }
        objects_on_beam = [];
    }

    // Countdown
    hold_timer--;
    if (hold_timer <= 0) {
        // Wave cleared!
        game_state = 4;
        clear_timer = 120;

        // Wave clear bonus
        var _bonus = 50 * wave;
        points += _bonus;
        array_push(score_popups, {
            x: beam_cx,
            y: beam_cy - beam_half * 0.4,
            text: "WAVE CLEAR +" + string(_bonus),
            alpha: 2.0,
        });
    }
}

// ========================
// STATE 4: WAVE CLEAR
// ========================
if (game_state == 4) {
    clear_timer--;
    if (clear_timer <= 0) {
        // Advance to next wave
        wave++;
        combo = 0;
        multiplier = 1;
        beam_angle = 0;
        beam_angular_vel = 0;
        objects_on_beam = [];
        falling_objects = [];
        drop_active = false;
        wind_force = 0;
        wind_timer = 300;

        // Generate new wave shapes
        wave_shapes = [];
        wave_index = 0;
        var _count = min(2 + wave, 12);
        var _max_type = 1;
        if (wave >= 2) _max_type = 2;
        if (wave >= 3) _max_type = 3;
        if (wave >= 4) _max_type = 4;
        if (wave >= 6) _max_type = 5;

        var _weight_var = 0.2 + wave * 0.05;
        for (var _i = 0; _i < _count; _i++) {
            var _tidx = irandom(_max_type - 1);
            var _wvar = random_range(-_weight_var, _weight_var);
            array_push(wave_shapes, {
                type_idx: _tidx,
                weight: max(0.5, obj_cfg_weight[_tidx] + _wvar),
            });
        }

        // Show intro for next wave
        game_state = 1;
        intro_timer = 120;
    }
}

// ========================
// STATE 5: GAME OVER
// ========================
if (game_state == 5) {
    beam_angular_vel += sign(beam_angle) * 0.002;
    beam_angular_vel *= 0.98;
    beam_angle += beam_angular_vel;
    beam_angle = clamp(beam_angle, -1.5, 1.5);

    tip_timer--;
    if (tip_timer <= 0) {
        // Submit score and wait for tap
        tip_timer = -1;
        api_submit_score(points, function(_s, _o, _r, _p) {});
    }

    if (tip_timer < 0 && device_mouse_check_button_pressed(0, mb_left)) {
        // Restart from wave 1
        game_state = 1;
        intro_timer = 120;
        points = 0;
        wave = 1;
        total_placed = 0;
        combo = 0;
        multiplier = 1;
        beam_angle = 0;
        beam_angular_vel = 0;
        objects_on_beam = [];
        falling_objects = [];
        score_popups = [];
        drop_active = false;
        wind_force = 0;
        wind_timer = 300;

        wave_shapes = [];
        wave_index = 0;
        var _count = 3;
        for (var _i = 0; _i < _count; _i++) {
            var _tidx = 0;
            var _wvar = random_range(-0.2, 0.2);
            array_push(wave_shapes, {
                type_idx: _tidx,
                weight: max(0.5, obj_cfg_weight[_tidx] + _wvar),
            });
        }
    }
}
