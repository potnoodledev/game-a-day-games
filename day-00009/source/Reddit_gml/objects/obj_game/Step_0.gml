
// === PILATES FLOW — Step_0 ===
// States: 0=title, 1=preview, 2=pose_intro, 3=minigame, 4=result, 5=gameover
// Scoring: continuous — points accumulate every frame based on performance

if (tap_cooldown > 0) tap_cooldown--;
if (bal_tap_cooldown > 0) bal_tap_cooldown--;

var _gw = window_width;
var _gh = window_height;
if (_gw <= 0 || _gh <= 0) exit;

// === Animate stick figure (always) ===
for (var _i = 0; _i < 22; _i++) {
    fig_current[_i] += (fig_target[_i] - fig_current[_i]) * fig_lerp_speed;
    fig_display[_i] = fig_current[_i];
}

// === Update particles ===
var _j = 0;
while (_j < part_count) {
    part_life[_j]--;
    part_y[_j] -= 0.0015;
    if (part_life[_j] <= 0) {
        part_count--;
        if (_j < part_count) {
            part_x[_j] = part_x[part_count];
            part_y[_j] = part_y[part_count];
            part_text[_j] = part_text[part_count];
            part_life[_j] = part_life[part_count];
            part_max_life[_j] = part_max_life[part_count];
            part_col[_j] = part_col[part_count];
        }
    } else {
        _j++;
    }
}

if (shake > 0) shake -= 0.6;
if (flash_timer > 0) flash_timer--;

// === Session timer (ticks during active gameplay: states 2-4) ===
if (game_state >= 2 && game_state <= 4) {
    session_timer--;
    if (session_timer <= 0) {
        // Time's up!
        session_timer = 0;
        run_score = floor(score_accum);
        if (run_score > points) {
            points = run_score;
            level = poses_completed;
        }
        game_state = 5;
        tap_cooldown = 30;
        shake = 10;
        if (points > 0) {
            api_submit_score(points, function(_s, _o, _r, _p) {});
        }
    }
}

// ==============================
//  STATE 0: TITLE
// ==============================
if (game_state == 0) {
    if (mouse_check_button_pressed(mb_left) && tap_cooldown <= 0) {
        tap_cooldown = 15;

        // Reset game
        run_score = 0;
        score_accum = 0;
        poses_completed = 0;
        difficulty = 1.0;
        session_timer = session_max;
        part_count = 0;
        part_x = []; part_y = []; part_text = [];
        part_life = []; part_max_life = []; part_col = [];

        // Shuffle pose queue (Fisher-Yates)
        pose_queue = [1, 2, 3, 4, 5, 6, 7];
        for (var _i = 6; _i > 0; _i--) {
            var _swp = irandom(_i);
            var _tmp = pose_queue[_i];
            pose_queue[_i] = pose_queue[_swp];
            pose_queue[_swp] = _tmp;
        }
        pose_queue_idx = 0;

        // Start preview: show upcoming poses
        preview_pose_idx = 0;
        preview_timer = preview_pose_hold;
        array_copy(fig_target, 0, all_poses[pose_queue[0]], 0, 22);
        fig_lerp_speed = 0.1;
        game_state = 1;
    }
}

// ==============================
//  STATE 1: SESSION PREVIEW
// ==============================
else if (game_state == 1) {
    preview_timer--;
    if (preview_timer <= 0) {
        preview_pose_idx++;
        if (preview_pose_idx >= array_length(pose_queue)) {
            // Preview done — start first pose
            current_pose_id = pose_queue[0];
            pose_queue_idx = 1;
            array_copy(fig_target, 0, all_poses[current_pose_id], 0, 22);
            fig_lerp_speed = 0.06;
            intro_timer = 90;
            game_state = 2;
        } else {
            // Show next pose in preview
            array_copy(fig_target, 0, all_poses[pose_queue[preview_pose_idx]], 0, 22);
            fig_lerp_speed = 0.12;
            preview_timer = preview_pose_hold;
        }
    }
}

// ==============================
//  STATE 2: POSE INTRO
// ==============================
else if (game_state == 2) {
    intro_timer--;
    if (intro_timer <= 0) {
        // Initialize the minigame for this pose
        minigame_type = pose_types[current_pose_id];
        mg_phase = 0;
        mg_result = -1;

        if (minigame_type == 0) {
            // HOLD: setup ring phase
            hold_setup_timer = 60;
            hold_timer = 0;
            hold_max = round(180 / difficulty);
            hold_holding = false;
            hold_wait_timer = 90;
        }
        else if (minigame_type == 1) {
            // BREATHE
            br_phase = 0;
            br_speed = (2 * pi) / (br_cycle_frames / difficulty);
            br_radius = br_center;
            br_prev_radius = br_center;
            br_crossing_active = false;
            br_crossing_timer = 0;
            br_crossing_tapped = false;
            br_crossings_done = 0;
            br_hits = 0;
            br_timer = 0;
            br_duration = round(br_cycle_frames * br_total_cycles / difficulty);
        }
        else if (minigame_type == 2) {
            // BALANCE
            bal_x = 0;
            bal_vel = 0.006 * (random(1) > 0.5 ? 1 : -1);
            bal_timer = round(bal_duration / max(1, difficulty * 0.8));
            bal_zone_frames = 0;
            bal_tap_cooldown = 0;
        }

        game_state = 3;
    }
}

// ==============================
//  STATE 3: MINIGAME ACTIVE
// ==============================
else if (game_state == 3) {

    // --- HOLD MINIGAME ---
    if (minigame_type == 0) {
        if (mg_phase == 0) {
            hold_setup_timer--;
            if (hold_setup_timer <= 0) {
                mg_phase = 1;
            }
        }
        else if (mg_phase == 1) {
            if (!hold_holding) {
                hold_wait_timer--;
                if (mouse_check_button_pressed(mb_left)) {
                    hold_holding = true;
                    hold_timer = 0;
                }
                else if (hold_wait_timer <= 0) {
                    mg_result = 0;
                    mg_phase = 2;
                }
            }
            else {
                if (mouse_check_button(mb_left)) {
                    hold_timer++;

                    // Continuous scoring while holding
                    var _frac = hold_timer / hold_max;
                    if (_frac >= hold_green_start && _frac <= hold_green_end) {
                        score_accum += 0.12; // ~7.2 pts/sec in green
                    } else if (_frac >= 0.3) {
                        score_accum += 0.05; // ~3 pts/sec in yellow
                    } else {
                        score_accum += 0.02; // ~1.2 pts/sec in red
                    }
                    run_score = floor(score_accum);

                    // Add wobble to figure
                    var _wobble = min(hold_timer / hold_max * 2.5, 2.0);
                    for (var _i = 0; _i < 22; _i++) {
                        fig_display[_i] = fig_current[_i] + sin(current_time * 0.012 + _i * 0.8) * _wobble * 0.06;
                    }

                    if (hold_timer >= hold_max) {
                        mg_result = 0;
                        mg_phase = 2;
                    }
                }
                else {
                    // Released! Evaluate for feedback text
                    var _frac = hold_timer / hold_max;
                    if (_frac >= hold_green_start && _frac <= hold_green_end) {
                        mg_result = 3;
                    }
                    else if (_frac >= 0.3 && _frac < hold_green_start) {
                        mg_result = 2;
                    }
                    else if (_frac >= hold_green_end && _frac < 0.95) {
                        mg_result = 1;
                    }
                    else {
                        mg_result = 1;
                        if (_frac < 0.15) mg_result = 0;
                    }
                    mg_phase = 2;
                }
            }
        }
        else if (mg_phase == 2) {
            game_state = 4;
            result_timer = 40;
        }
    }

    // --- BREATHE MINIGAME ---
    else if (minigame_type == 1) {
        br_timer++;
        br_prev_radius = br_radius;
        br_phase += br_speed;
        br_radius = br_center + br_amplitude * sin(br_phase);

        // Base points just for being in the minigame
        score_accum += 0.02;
        run_score = floor(score_accum);

        // Detect crossing of target ring
        if (!br_crossing_active) {
            var _prev_diff = br_prev_radius - br_target;
            var _cur_diff = br_radius - br_target;
            if ((_prev_diff < 0 && _cur_diff >= 0) || (_prev_diff > 0 && _cur_diff <= 0)) {
                br_crossing_active = true;
                br_crossing_timer = round(br_window / difficulty);
                br_crossing_tapped = false;
                br_crossings_done++;
            }
        }

        if (br_crossing_active) {
            br_crossing_timer--;
            if (mouse_check_button_pressed(mb_left) && !br_crossing_tapped) {
                br_crossing_tapped = true;
                br_hits++;
                flash_timer = 5;

                // Score based on timing accuracy (higher timer = tapped sooner = better)
                var _window_max = max(1, round(br_window / difficulty));
                var _timing = br_crossing_timer / _window_max;
                if (_timing > 0.6) {
                    score_accum += 5; // perfect timing
                    array_push(part_x, 0.5); array_push(part_y, 0.35);
                    array_push(part_text, "+5"); array_push(part_life, 30);
                    array_push(part_max_life, 30); array_push(part_col, gold_col);
                    part_count++;
                } else if (_timing > 0.3) {
                    score_accum += 3; // good
                    array_push(part_x, 0.5); array_push(part_y, 0.35);
                    array_push(part_text, "+3"); array_push(part_life, 30);
                    array_push(part_max_life, 30); array_push(part_col, zone_green);
                    part_count++;
                } else {
                    score_accum += 2; // late but hit
                    array_push(part_x, 0.5); array_push(part_y, 0.35);
                    array_push(part_text, "+2"); array_push(part_life, 30);
                    array_push(part_max_life, 30); array_push(part_col, zone_yellow);
                    part_count++;
                }
                run_score = floor(score_accum);
            }
            if (br_crossing_timer <= 0) {
                br_crossing_active = false;
            }
        }

        // Animate figure chest with breathing
        var _chest_expand = sin(br_phase) * 0.15;
        fig_display[2] = fig_current[2];
        fig_display[3] = fig_current[3] - _chest_expand;

        // Check if done
        if (br_timer >= br_duration) {
            var _total = max(1, br_crossings_done);
            var _ratio = br_hits / _total;
            if (_ratio >= 0.9) mg_result = 3;
            else if (_ratio >= 0.65) mg_result = 2;
            else if (_ratio >= 0.4) mg_result = 1;
            else mg_result = 0;

            game_state = 4;
            result_timer = 40;
        }
    }

    // --- BALANCE MINIGAME ---
    else if (minigame_type == 2) {
        bal_timer--;

        bal_vel += random_range(-0.001, 0.001) * difficulty;
        bal_x += bal_vel;

        if (bal_x > 1.0) { bal_x = 1.0; bal_vel = -abs(bal_vel) * 0.5; }
        if (bal_x < -1.0) { bal_x = -1.0; bal_vel = abs(bal_vel) * 0.5; }

        if (mouse_check_button_pressed(mb_left) && bal_tap_cooldown <= 0) {
            bal_tap_cooldown = 10;
            bal_vel = -bal_vel * 0.7;
            bal_vel -= sign(bal_x) * 0.003;
        }

        // Continuous scoring based on proximity to center
        if (abs(bal_x) < bal_zone_size * 0.4) {
            score_accum += 0.10; // tight center: ~6 pts/sec
        } else if (abs(bal_x) < bal_zone_size) {
            score_accum += 0.05; // center zone: ~3 pts/sec
        } else {
            score_accum += 0.01; // outside: ~0.6 pts/sec
        }
        run_score = floor(score_accum);

        if (abs(bal_x) < bal_zone_size) {
            bal_zone_frames++;
        }

        // Tilt figure
        var _tilt = bal_x * 0.4;
        for (var _i = 0; _i < 22; _i += 2) {
            fig_display[_i] = fig_current[_i] + _tilt;
        }

        // Check if done
        if (bal_timer <= 0) {
            var _total = round(bal_duration / max(1, difficulty * 0.8));
            var _ratio = bal_zone_frames / max(1, _total);
            if (_ratio >= 0.6) mg_result = 3;
            else if (_ratio >= 0.4) mg_result = 2;
            else if (_ratio >= 0.2) mg_result = 1;
            else mg_result = 0;

            game_state = 4;
            result_timer = 40;
        }
    }
}

// ==============================
//  STATE 4: POSE RESULT (feedback only — no score changes)
// ==============================
else if (game_state == 4) {
    result_timer--;

    // Set feedback text on first frame
    if (result_timer == 39) {
        if (mg_result == 3) {
            result_text = "PERFECT!";
            result_col = gold_col;
            flash_timer = 10;
        }
        else if (mg_result == 2) {
            result_text = "GREAT!";
            result_col = zone_green;
        }
        else if (mg_result == 1) {
            result_text = "GOOD";
            result_col = zone_yellow;
        }
        else {
            result_text = "MISS";
            result_col = zone_red;
            shake = 8;
        }
        poses_completed++;
        difficulty = 1.0 + floor(poses_completed / 2) * 0.2;

        // Update high score
        run_score = floor(score_accum);
        if (run_score > points) {
            points = run_score;
            level = poses_completed;
        }

        // Particle for result
        array_push(part_x, 0.5);
        array_push(part_y, 0.3);
        array_push(part_text, result_text);
        array_push(part_life, 40);
        array_push(part_max_life, 40);
        array_push(part_col, result_col);
        part_count++;
    }

    if (result_timer <= 0) {
        // Always go to next pose (no lives — timer ends the game)
        if (pose_queue_idx >= array_length(pose_queue)) {
            pose_queue = [1, 2, 3, 4, 5, 6, 7];
            for (var _i = 6; _i > 0; _i--) {
                var _swp = irandom(_i);
                var _tmp = pose_queue[_i];
                pose_queue[_i] = pose_queue[_swp];
                pose_queue[_swp] = _tmp;
            }
            pose_queue_idx = 0;
        }

        current_pose_id = pose_queue[pose_queue_idx];
        pose_queue_idx++;
        array_copy(fig_target, 0, all_poses[current_pose_id], 0, 22);
        fig_lerp_speed = 0.06;
        intro_timer = 60;
        game_state = 2;
    }
}

// ==============================
//  STATE 5: GAME OVER
// ==============================
else if (game_state == 5) {
    if (mouse_check_button_pressed(mb_left) && tap_cooldown <= 0) {
        tap_cooldown = 15;
        array_copy(fig_target, 0, all_poses[0], 0, 22);
        fig_lerp_speed = 0.08;
        game_state = 0;
    }
}
