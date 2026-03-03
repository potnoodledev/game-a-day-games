
// Cache window size
ww = window_get_width();
hh = window_get_height();

// Play area (below HUD bar)
var _hud_h = hh * 0.08;
play_ox = ww * 0.02;
play_oy = _hud_h + hh * 0.02;
play_w = ww * 0.96;
play_h = hh - play_oy - hh * 0.02;

// ========== TITLE STATE ==========
if (game_state == 1) {
    title_pulse += 0.05;
    if (device_mouse_check_button_pressed(0, mb_left)) {
        // Start new round
        game_state = 2;
        // Set crew count based on round
        crew_count = min(4 + ((round_num - 1) div 3), crew_max);
        // Set timer based on round
        round_timer_max = max(360, 600 - (round_num - 1) * 24); // 20s down to 12s
        round_timer = round_timer_max;
        // Initialize crewmates
        impostor_id = irandom(crew_count - 1);
        imp_kill_cd = imp_kill_cd_max;
        imp_stalk_target = -1;
        imp_near_vent = false;
        kill_active = false;

        for (var _i = 0; _i < crew_max; _i++) {
            crew_alive[_i] = (_i < crew_count);
            if (_i < crew_count) {
                // Place in random rooms
                crew_room_id[_i] = irandom(room_count - 1);
                var _rx = play_ox + room_nx[crew_room_id[_i]] * play_w;
                var _ry = play_oy + room_ny[crew_room_id[_i]] * play_h;
                var _rw = room_nw[crew_room_id[_i]] * play_w;
                var _rh = room_nh[crew_room_id[_i]] * play_h;
                crew_x[_i] = _rx + _rw * 0.3 + random(_rw * 0.4);
                crew_y[_i] = _ry + _rh * 0.3 + random(_rh * 0.4);
                crew_tx[_i] = crew_x[_i];
                crew_ty[_i] = crew_y[_i];
                crew_spd[_i] = 1.0 + random(0.5);
                crew_ai[_i] = "idle";
                crew_ai_timer[_i] = irandom_range(30, 90);
                crew_task_progress[_i] = 0;
                crew_task_target[_i] = -1;
                crew_bobble[_i] = random(6.28);
            }
        }
        // Clear task occupancy
        for (var _i = 0; _i < task_count; _i++) {
            task_occupied[_i] = -1;
        }
    }
    exit;
}

// ========== MEETING STATE ==========
if (game_state == 3) {
    meeting_timer -= 1;
    meeting_flash = max(0, meeting_flash - 0.03);
    if (meeting_timer <= 0) {
        game_state = 4;
        result_timer = result_duration;
        // Determine result
        if (meeting_accused == impostor_id) {
            meeting_result = 1;
            var _base = 100 * round_num;
            var _time_bonus = floor((round_timer / round_timer_max) * 50 * round_num);
            var _streak_bonus = streak * 25;
            var _gained = _base + _time_bonus + _streak_bonus;
            points += _gained;
            streak += 1;
            score_popup = "+" + string(_gained);
            score_popup_timer = 90;
        } else {
            meeting_result = -1;
            lives -= 1;
            streak = 0;
        }
    }
    exit;
}

// ========== RESULT STATE ==========
if (game_state == 4) {
    result_timer -= 1;
    score_popup_timer = max(0, score_popup_timer - 1);
    if (result_timer <= 0) {
        if (meeting_result == 1) {
            // Won the round — next round
            round_num += 1;
            game_state = 1; // back to title briefly, auto-starts
        } else {
            // Lost a life
            if (lives <= 0) {
                game_state = 5; // game over
                api_submit_score(points, undefined);
            } else {
                game_state = 1; // retry
            }
        }
    }
    exit;
}

// ========== GAME OVER ==========
if (game_state == 5) {
    if (device_mouse_check_button_pressed(0, mb_left)) {
        // Reset
        points = 0;
        round_num = 1;
        lives = 3;
        streak = 0;
        game_state = 1;
    }
    exit;
}

// ========== PLAYING STATE ==========
if (game_state != 2) exit;

// Kill animation
if (kill_active) {
    kill_timer -= 1;
    if (kill_timer <= 0) {
        kill_active = false;
        // Impostor killed someone — player loses a life
        lives -= 1;
        streak = 0;
        if (lives <= 0) {
            game_state = 5;
            api_submit_score(points, undefined);
        } else {
            // Restart round
            game_state = 1;
        }
    }
    exit;
}

// Timer countdown
round_timer -= 1;
if (round_timer <= 0) {
    // Time's up — impostor wins
    lives -= 1;
    streak = 0;
    if (lives <= 0) {
        game_state = 5;
        api_submit_score(points, undefined);
    } else {
        game_state = 1;
    }
    exit;
}

// Impostor kill cooldown
imp_kill_cd = max(0, imp_kill_cd - 1);

// ---- Crewmate AI ----
for (var _i = 0; _i < crew_count; _i++) {
    if (!crew_alive[_i]) continue;

    crew_bobble[_i] += 0.15;

    var _is_imp = (_i == impostor_id);

    // Compute current room bounds (absolute)
    var _cr = crew_room_id[_i];
    var _rx = play_ox + room_nx[_cr] * play_w;
    var _ry = play_oy + room_ny[_cr] * play_h;
    var _rw = room_nw[_cr] * play_w;
    var _rh = room_nh[_cr] * play_h;

    // AI state machine
    if (crew_ai[_i] == "idle") {
        crew_ai_timer[_i] -= 1;
        if (crew_ai_timer[_i] <= 0) {
            // Decide next action
            if (_is_imp) {
                // Impostor decision
                var _roll = irandom(100);
                // Difficulty scaling — higher rounds = less obvious tells
                var _vent_chance = max(5, 25 - round_num * 2);
                var _stalk_chance = 15 + min(round_num * 2, 20);

                if (_roll < _vent_chance && !imp_near_vent) {
                    // Go to a vent
                    crew_ai[_i] = "walking";
                    var _v = irandom(vent_count - 1);
                    var _vr = vent_room[_v];
                    var _vrx = play_ox + room_nx[_vr] * play_w;
                    var _vry = play_oy + room_ny[_vr] * play_h;
                    var _vrw = room_nw[_vr] * play_w;
                    var _vrh = room_nh[_vr] * play_h;
                    crew_tx[_i] = _vrx + vent_lx[_v] * _vrw;
                    crew_ty[_i] = _vry + vent_ly[_v] * _vrh;
                    crew_room_id[_i] = _vr;
                    crew_ai_timer[_i] = -1; // walk until arrive
                } else if (_roll < _vent_chance + _stalk_chance && imp_kill_cd <= 0) {
                    // Stalk a crewmate
                    var _target = -1;
                    var _tries = 0;
                    while (_target == -1 && _tries < 10) {
                        var _t = irandom(crew_count - 1);
                        if (_t != _i && crew_alive[_t]) _target = _t;
                        _tries += 1;
                    }
                    if (_target != -1) {
                        imp_stalk_target = _target;
                        crew_ai[_i] = "stalking";
                        crew_ai_timer[_i] = irandom_range(90, 180);
                    } else {
                        crew_ai[_i] = "walking";
                        crew_tx[_i] = _rx + _rw * 0.2 + random(_rw * 0.6);
                        crew_ty[_i] = _ry + _rh * 0.2 + random(_rh * 0.6);
                        crew_ai_timer[_i] = -1;
                    }
                } else {
                    // Fake a task
                    var _best_task = -1;
                    var _tries = 0;
                    while (_best_task == -1 && _tries < 10) {
                        var _t = irandom(task_count - 1);
                        if (task_occupied[_t] == -1) _best_task = _t;
                        _tries += 1;
                    }
                    if (_best_task != -1) {
                        crew_task_target[_i] = _best_task;
                        task_occupied[_best_task] = _i;
                        var _tr = task_room[_best_task];
                        var _trx = play_ox + room_nx[_tr] * play_w;
                        var _try2 = play_oy + room_ny[_tr] * play_h;
                        var _trw = room_nw[_tr] * play_w;
                        var _trh = room_nh[_tr] * play_h;
                        crew_tx[_i] = _trx + task_lx[_best_task] * _trw;
                        crew_ty[_i] = _try2 + task_ly[_best_task] * _trh;
                        crew_room_id[_i] = _tr;
                        crew_ai[_i] = "walking";
                        crew_ai_timer[_i] = -1;
                    } else {
                        // Just wander
                        crew_ai[_i] = "walking";
                        crew_tx[_i] = _rx + _rw * 0.2 + random(_rw * 0.6);
                        crew_ty[_i] = _ry + _rh * 0.2 + random(_rh * 0.6);
                        crew_ai_timer[_i] = -1;
                    }
                }
            } else {
                // Innocent crewmate — go do a task
                var _best_task = -1;
                var _tries = 0;
                while (_best_task == -1 && _tries < 10) {
                    var _t = irandom(task_count - 1);
                    if (task_occupied[_t] == -1) _best_task = _t;
                    _tries += 1;
                }
                if (_best_task != -1) {
                    crew_task_target[_i] = _best_task;
                    task_occupied[_best_task] = _i;
                    var _tr = task_room[_best_task];
                    var _trx = play_ox + room_nx[_tr] * play_w;
                    var _try2 = play_oy + room_ny[_tr] * play_h;
                    var _trw = room_nw[_tr] * play_w;
                    var _trh = room_nh[_tr] * play_h;
                    crew_tx[_i] = _trx + task_lx[_best_task] * _trw;
                    crew_ty[_i] = _try2 + task_ly[_best_task] * _trh;
                    crew_room_id[_i] = _tr;
                    crew_ai[_i] = "walking";
                    crew_ai_timer[_i] = -1;
                } else {
                    // Wander
                    crew_ai[_i] = "walking";
                    var _nr = irandom(room_count - 1);
                    var _nrx = play_ox + room_nx[_nr] * play_w;
                    var _nry = play_oy + room_ny[_nr] * play_h;
                    var _nrw = room_nw[_nr] * play_w;
                    var _nrh = room_nh[_nr] * play_h;
                    crew_tx[_i] = _nrx + _nrw * 0.2 + random(_nrw * 0.6);
                    crew_ty[_i] = _nry + _nrh * 0.2 + random(_nrh * 0.6);
                    crew_room_id[_i] = _nr;
                    crew_ai_timer[_i] = -1;
                }
            }
        }
    }

    if (crew_ai[_i] == "walking") {
        var _dx = crew_tx[_i] - crew_x[_i];
        var _dy = crew_ty[_i] - crew_y[_i];
        var _dist = sqrt(_dx * _dx + _dy * _dy);
        var _move_spd = crew_spd[_i] * min(play_w, play_h) * 0.003;
        if (_dist > _move_spd) {
            crew_x[_i] += (_dx / _dist) * _move_spd;
            crew_y[_i] += (_dy / _dist) * _move_spd;
        } else {
            crew_x[_i] = crew_tx[_i];
            crew_y[_i] = crew_ty[_i];
            // Arrived at destination
            if (crew_task_target[_i] != -1) {
                // Start doing task
                if (_is_imp) {
                    crew_ai[_i] = "faking";
                    // Impostor fakes faster on higher rounds (less obvious)
                    var _fake_time = max(30, 60 - round_num * 3);
                    crew_ai_timer[_i] = _fake_time;
                } else {
                    crew_ai[_i] = "tasking";
                    crew_ai_timer[_i] = irandom_range(90, 150);
                }
                crew_task_progress[_i] = 0;
            } else {
                // Check if impostor arrived near vent
                if (_is_imp) {
                    var _at_vent = false;
                    for (var _v = 0; _v < vent_count; _v++) {
                        var _vr = vent_room[_v];
                        var _vrx = play_ox + room_nx[_vr] * play_w;
                        var _vry = play_oy + room_ny[_vr] * play_h;
                        var _vrw = room_nw[_vr] * play_w;
                        var _vrh = room_nh[_vr] * play_h;
                        var _vx = _vrx + vent_lx[_v] * _vrw;
                        var _vy = _vry + vent_ly[_v] * _vrh;
                        if (point_distance(crew_x[_i], crew_y[_i], _vx, _vy) < play_w * 0.03) {
                            _at_vent = true;
                            break;
                        }
                    }
                    if (_at_vent) {
                        crew_ai[_i] = "venting";
                        // Higher rounds = shorter vent pauses (harder to spot)
                        var _vent_time = max(20, 60 - round_num * 4);
                        crew_ai_timer[_i] = _vent_time;
                        imp_near_vent = true;
                    } else {
                        crew_ai[_i] = "idle";
                        crew_ai_timer[_i] = irandom_range(20, 60);
                    }
                } else {
                    crew_ai[_i] = "idle";
                    crew_ai_timer[_i] = irandom_range(20, 60);
                }
            }
        }
    }

    if (crew_ai[_i] == "tasking") {
        crew_ai_timer[_i] -= 1;
        crew_task_progress[_i] = 1.0 - (crew_ai_timer[_i] / 120.0);
        crew_task_progress[_i] = clamp(crew_task_progress[_i], 0, 1);
        if (crew_ai_timer[_i] <= 0) {
            crew_task_progress[_i] = 0;
            if (crew_task_target[_i] != -1) {
                task_occupied[crew_task_target[_i]] = -1;
                crew_task_target[_i] = -1;
            }
            crew_ai[_i] = "idle";
            crew_ai_timer[_i] = irandom_range(30, 90);
        }
    }

    if (crew_ai[_i] == "faking") {
        crew_ai_timer[_i] -= 1;
        // Impostor progress fills faster then stops early
        var _fake_max = max(30, 60 - round_num * 3);
        crew_task_progress[_i] = 1.0 - (crew_ai_timer[_i] / _fake_max);
        // Cap at partial fill — the tell!
        var _max_fill = min(0.9, 0.3 + round_num * 0.06);
        crew_task_progress[_i] = clamp(crew_task_progress[_i], 0, _max_fill);
        if (crew_ai_timer[_i] <= 0) {
            crew_task_progress[_i] = 0;
            if (crew_task_target[_i] != -1) {
                task_occupied[crew_task_target[_i]] = -1;
                crew_task_target[_i] = -1;
            }
            crew_ai[_i] = "idle";
            crew_ai_timer[_i] = irandom_range(20, 50);
        }
    }

    if (crew_ai[_i] == "venting") {
        crew_ai_timer[_i] -= 1;
        if (crew_ai_timer[_i] <= 0) {
            imp_near_vent = false;
            crew_ai[_i] = "idle";
            crew_ai_timer[_i] = irandom_range(30, 60);
        }
    }

    if (crew_ai[_i] == "stalking") {
        // Follow the target
        if (imp_stalk_target != -1 && crew_alive[imp_stalk_target]) {
            crew_tx[_i] = crew_x[imp_stalk_target];
            crew_ty[_i] = crew_y[imp_stalk_target];
            var _dx = crew_tx[_i] - crew_x[_i];
            var _dy = crew_ty[_i] - crew_y[_i];
            var _dist = sqrt(_dx * _dx + _dy * _dy);
            var _move_spd = crew_spd[_i] * min(play_w, play_h) * 0.003;
            if (_dist > _move_spd * 2) {
                crew_x[_i] += (_dx / _dist) * _move_spd * 1.2;
                crew_y[_i] += (_dy / _dist) * _move_spd * 1.2;
            }
            // Close enough to kill?
            var _kill_dist = min(play_w, play_h) * 0.04;
            if (_dist < _kill_dist && imp_kill_cd <= 0) {
                // KILL!
                crew_alive[imp_stalk_target] = false;
                kill_active = true;
                kill_timer = 60;
                kill_x = crew_x[imp_stalk_target];
                kill_y = crew_y[imp_stalk_target];
                kill_victim = imp_stalk_target;
                imp_kill_cd = imp_kill_cd_max;
                imp_stalk_target = -1;
                crew_ai[_i] = "idle";
                crew_ai_timer[_i] = 30;
            }
        }
        crew_ai_timer[_i] -= 1;
        if (crew_ai_timer[_i] <= 0) {
            imp_stalk_target = -1;
            crew_ai[_i] = "idle";
            crew_ai_timer[_i] = irandom_range(30, 60);
        }
    }
}

// ---- Tap detection ----
if (device_mouse_check_button_pressed(0, mb_left)) {
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _crew_r = min(play_w, play_h) * 0.025;
    var _tap_r = _crew_r * 2.5; // generous tap area

    var _tapped = -1;
    var _best_dist = _tap_r;

    for (var _i = 0; _i < crew_count; _i++) {
        if (!crew_alive[_i]) continue;
        var _d = point_distance(_mx, _my, crew_x[_i], crew_y[_i]);
        if (_d < _best_dist) {
            _best_dist = _d;
            _tapped = _i;
        }
    }

    if (_tapped != -1) {
        // Emergency meeting!
        meeting_accused = _tapped;
        meeting_timer = meeting_duration;
        meeting_flash = 1.0;
        game_state = 3;
    }
}

// Score popup decay
score_popup_timer = max(0, score_popup_timer - 1);
