// --- Responsive layout ---
var _ww = max(1, window_get_width());
var _wh = max(1, window_get_height());
play_w = _ww;
play_h = _wh;
play_ox = 0;
play_oy = 0;

// --- Tile sizing ---
var _tile_w = min(play_w, play_h) * 0.16;
var _tile_h = _tile_w * 0.6;
var _height_px = _tile_h * 0.8;

// --- Title screen ---
if (game_state == 1) {
    title_pulse += 0.05;
    if (device_mouse_check_button_pressed(0, mb_left)) {
        game_state = 2;
        ct_running = true;
    }
    exit;
}

// --- Wave clear ---
if (game_state == 4) {
    wave_clear_timer--;
    if (wave_clear_timer <= 0) {
        // Heal all alive player units by 2 HP
        for (var _i = 0; _i < unit_count; _i++) {
            if (unit_alive[_i] && unit_team[_i] == 0) {
                var _heal = min(2, unit_max_hp[_i] - unit_hp[_i]);
                if (_heal > 0) {
                    unit_hp[_i] += _heal;
                    // Show green heal popup
                    if (popup_count < 16) {
                        var _sx = play_ox + play_w * 0.5 + (unit_gx[_i] - unit_gy[_i]) * _tile_w * 0.5;
                        var _sy = play_oy + 120 + (unit_gx[_i] + unit_gy[_i]) * _tile_h * 0.5 - tile_height[unit_gx[_i] * grid_w + unit_gy[_i]] * _height_px - 20;
                        popup_x[popup_count] = _sx;
                        popup_y[popup_count] = _sy;
                        popup_val[popup_count] = _heal;
                        popup_timer[popup_count] = 40;
                        popup_is_heal[popup_count] = true;
                        popup_count++;
                    }
                }
            }
        }

        // Transition to level-up screen
        camera_shake = 0;
        game_state = 6;
        levelup_phase = 0;
        levelup_unit = -1;
        levelup_selected = -1;
    }
    exit;
}

// --- Level-up screen ---
if (game_state == 6) {
    var _tap = device_mouse_check_button_pressed(0, mb_left);
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    if (levelup_phase == 0) {
        // Phase 0: pick a unit to upgrade
        if (_tap) {
            // Count alive player units
            var _alive_players = 0;
            for (var _i = 0; _i < unit_count; _i++) {
                if (unit_alive[_i] && unit_team[_i] == 0) _alive_players++;
            }

            var _card_w = min(140, (_ww * 0.8) / max(1, _alive_players));
            var _card_h = 160;
            var _total_w = _alive_players * _card_w + (_alive_players - 1) * 10;
            var _start_x = (_ww - _total_w) * 0.5;
            var _card_y = _wh * 0.4;

            var _pidx = 0;
            for (var _i = 0; _i < unit_count; _i++) {
                if (!unit_alive[_i] || unit_team[_i] != 0) continue;
                var _cx2 = _start_x + _pidx * (_card_w + 10);
                if (_mx >= _cx2 && _mx <= _cx2 + _card_w && _my >= _card_y && _my <= _card_y + _card_h) {
                    levelup_unit = _i;
                    levelup_phase = 1;
                    levelup_selected = -1;

                    // Generate 3 random distinct upgrade IDs (0-8)
                    levelup_opt0 = irandom(8);
                    levelup_opt1 = irandom(7);
                    if (levelup_opt1 >= levelup_opt0) levelup_opt1++;
                    levelup_opt2 = irandom(6);
                    if (levelup_opt2 >= min(levelup_opt0, levelup_opt1)) levelup_opt2++;
                    if (levelup_opt2 >= max(levelup_opt0, levelup_opt1)) levelup_opt2++;
                    break;
                }
                _pidx++;
            }
        }
    } else if (levelup_phase == 1) {
        // Phase 1: pick an upgrade
        if (_tap) {
            var _card_w2 = min(180, _ww * 0.28);
            var _card_h2 = 100;
            var _total_w2 = 3 * _card_w2 + 2 * 10;
            var _start_x2 = (_ww - _total_w2) * 0.5;
            var _card_y2 = _wh * 0.45;

            for (var _opt = 0; _opt < 3; _opt++) {
                var _ox = _start_x2 + _opt * (_card_w2 + 10);
                if (_mx >= _ox && _mx <= _ox + _card_w2 && _my >= _card_y2 && _my <= _card_y2 + _card_h2) {
                    if (levelup_selected == _opt) {
                        // Confirm — apply upgrade
                        var _uid = levelup_unit;
                        var _upg = levelup_opt0;
                        if (_opt == 1) _upg = levelup_opt1;
                        if (_opt == 2) _upg = levelup_opt2;

                        if (_upg == 0) { unit_max_hp[_uid] += 2; unit_hp[_uid] = min(unit_hp[_uid] + 2, unit_max_hp[_uid]); }
                        else if (_upg == 1) { unit_atk[_uid] += 1; }
                        else if (_upg == 2) { unit_def[_uid] += 1; }
                        else if (_upg == 3) { unit_move_range[_uid] += 1; }
                        else if (_upg == 4) { unit_atk_range[_uid] += 1; }
                        else if (_upg == 5) { unit_spd[_uid] += 1; }
                        else if (_upg == 6) { unit_hp[_uid] = unit_max_hp[_uid]; }
                        else if (_upg == 7) { unit_atk[_uid] += 1; unit_spd[_uid] += 1; }
                        else if (_upg == 8) { unit_def[_uid] += 1; unit_max_hp[_uid] += 2; unit_hp[_uid] = min(unit_hp[_uid] + 2, unit_max_hp[_uid]); }

                        // --- Spawn next wave ---
                        wave_num++;

                        // Wave recipes
                        var _wave_idx = (wave_num - 1) % 6;
                        var _recipe_count = 2;
                        // recipe: array of class IDs per slot
                        var _r0 = 3; var _r1 = 3; var _r2 = 3; var _r3 = 3; var _r4 = 3;

                        if (_wave_idx == 0) { _recipe_count = 2; _r0 = 3; _r1 = 3; }
                        else if (_wave_idx == 1) { _recipe_count = 3; _r0 = 3; _r1 = 3; _r2 = 4; }
                        else if (_wave_idx == 2) { _recipe_count = 3; _r0 = 3; _r1 = 4; _r2 = 4; }
                        else if (_wave_idx == 3) { _recipe_count = 4; _r0 = 3; _r1 = 3; _r2 = 3; _r3 = 4; }
                        else if (_wave_idx == 4) { _recipe_count = 4; _r0 = 3; _r1 = 3; _r2 = 4; _r3 = 4; }
                        else { _recipe_count = 5; _r0 = 3; _r1 = 4; _r2 = 3; _r3 = 4; _r4 = 3; }

                        var _hp_bonus = floor((wave_num - 1) / 2);
                        var _atk_bonus = floor((wave_num - 1) / 3);

                        // Rotate spawn zone
                        var _zone = (wave_num - 1) % 4;
                        var _zone0_gx = [5, 6, 6, 5, 4]; var _zone0_gy = [0, 1, 0, 1, 0];
                        var _zone1_gx = [0, 1, 0, 1, 2]; var _zone1_gy = [0, 0, 1, 1, 0];
                        var _zone2_gx = [5, 6, 5, 6, 4]; var _zone2_gy = [5, 5, 6, 6, 6];
                        var _zone3_gx = [2, 3, 4, 3, 2]; var _zone3_gy = [0, 0, 0, 1, 1];

                        for (var _i = 0; _i < _recipe_count; _i++) {
                            // Find a dead slot or expand
                            var _idx = -1;
                            for (var _s = 0; _s < unit_count; _s++) {
                                if (!unit_alive[_s]) { _idx = _s; break; }
                            }
                            if (_idx == -1) {
                                if (unit_count >= max_units) break;
                                _idx = unit_count;
                                unit_count++;
                            }

                            var _cls = _r0;
                            if (_i == 1) _cls = _r1;
                            if (_i == 2) _cls = _r2;
                            if (_i == 3) _cls = _r3;
                            if (_i == 4) _cls = _r4;

                            var _sgx = 3; var _sgy = 0;
                            if (_zone == 0) { _sgx = _zone0_gx[_i]; _sgy = _zone0_gy[_i]; }
                            else if (_zone == 1) { _sgx = _zone1_gx[_i]; _sgy = _zone1_gy[_i]; }
                            else if (_zone == 2) { _sgx = _zone2_gx[_i]; _sgy = _zone2_gy[_i]; }
                            else { _sgx = _zone3_gx[_i]; _sgy = _zone3_gy[_i]; }

                            // Skip if occupied
                            var _blocked = false;
                            for (var _k = 0; _k < unit_count; _k++) {
                                if (unit_alive[_k] && _k != _idx && unit_gx[_k] == _sgx && unit_gy[_k] == _sgy) {
                                    _blocked = true; break;
                                }
                            }
                            if (_blocked) continue;

                            unit_gx[_idx] = _sgx;
                            unit_gy[_idx] = _sgy;
                            unit_class[_idx] = _cls;
                            unit_team[_idx] = 1;
                            unit_alive[_idx] = true;
                            unit_facing[_idx] = 0;
                            unit_hp[_idx] = class_hp[_cls] + _hp_bonus;
                            unit_max_hp[_idx] = class_hp[_cls] + _hp_bonus;
                            unit_atk[_idx] = class_atk[_cls] + _atk_bonus;
                            unit_def[_idx] = class_def[_cls];
                            unit_move_range[_idx] = class_mov[_cls];
                            unit_atk_range[_idx] = class_rng[_cls];
                            unit_spd[_idx] = class_spd[_cls];
                            unit_ct[_idx] = 0;
                            unit_acted[_idx] = false;
                            unit_moved[_idx] = false;
                        }

                        active_unit = -1;
                        ct_running = true;
                        game_state = 2;
                    } else {
                        levelup_selected = _opt;
                    }
                    break;
                }
            }
        }
    }
    exit;
}

// --- Game over ---
if (game_state == 5) {
    if (device_mouse_check_button_pressed(0, mb_left)) {
        game_restart();
    }
    exit;
}

// --- Animating ---
if (game_state == 3) {
    anim_timer--;
    if (anim_timer <= 0) {
        game_state = 2;

        // After attack animation, check for kills -> crystals
        if (anim_type == 2) {
            for (var _i = 0; _i < unit_count; _i++) {
                if (unit_alive[_i] == false && unit_hp[_i] <= 0) {
                    if (unit_hp[_i] > -999) {
                        if (crystal_count < 12) {
                            crystal_gx[crystal_count] = unit_gx[_i];
                            crystal_gy[crystal_count] = unit_gy[_i];
                            crystal_timer[crystal_count] = 300;
                            crystal_count++;
                        }
                        unit_hp[_i] = -999;
                    }
                }
            }
        }

        // After move, check crystal pickup
        if (anim_type == 1 && anim_unit >= 0) {
            var _au = anim_unit;
            for (var _c = 0; _c < crystal_count; _c++) {
                if (crystal_gx[_c] == unit_gx[_au] && crystal_gy[_c] == unit_gy[_au] && crystal_timer[_c] > 0) {
                    unit_hp[_au] = min(unit_hp[_au] + 2, unit_max_hp[_au]);
                    crystal_timer[_c] = 0;
                    if (popup_count < 16) {
                        var _sx = play_ox + play_w * 0.5 + (unit_gx[_au] - unit_gy[_au]) * _tile_w * 0.5;
                        var _sy = play_oy + 120 + (unit_gx[_au] + unit_gy[_au]) * _tile_h * 0.5 - tile_height[unit_gx[_au] * grid_w + unit_gy[_au]] * _height_px - 20;
                        popup_x[popup_count] = _sx;
                        popup_y[popup_count] = _sy;
                        popup_val[popup_count] = 2;
                        popup_timer[popup_count] = 40;
                        popup_is_heal[popup_count] = true;
                        popup_count++;
                    }
                }
            }

            // After moving, recalc valid tiles for this unit
            if (_au == active_unit && unit_team[_au] == 0) {
                // Recalculate attack targets from new position
                valid_attack_count = 0;
                var _range = unit_atk_range[_au];
                for (var _j = 0; _j < unit_count; _j++) {
                    if (!unit_alive[_j] || unit_team[_j] == unit_team[_au]) continue;
                    var _d = abs(unit_gx[_au] - unit_gx[_j]) + abs(unit_gy[_au] - unit_gy[_j]);
                    if (_d <= _range) {
                        valid_attacks[valid_attack_count] = _j;
                        valid_attack_count++;
                    }
                }
                valid_move_count = 0; // Already moved
            }
        }

        // Check win/lose conditions
        var _player_alive = 0;
        var _enemy_alive = 0;
        for (var _i = 0; _i < unit_count; _i++) {
            if (unit_alive[_i]) {
                if (unit_team[_i] == 0) _player_alive++;
                else _enemy_alive++;
            }
        }

        if (_player_alive == 0) {
            game_state = 5;
            api_submit_score(points, undefined);
        } else if (_enemy_alive == 0) {
            points += wave_num * 100;
            game_state = 4;
            wave_clear_timer = 90;
        }
    }
    exit;
}

if (game_state != 2) exit;

// --- Damage popups update ---
for (var _i = popup_count - 1; _i >= 0; _i--) {
    popup_timer[_i]--;
    popup_y[_i] -= 0.8;
    if (popup_timer[_i] <= 0) {
        popup_count--;
        popup_x[_i] = popup_x[popup_count];
        popup_y[_i] = popup_y[popup_count];
        popup_val[_i] = popup_val[popup_count];
        popup_timer[_i] = popup_timer[popup_count];
        popup_is_heal[_i] = popup_is_heal[popup_count];
    }
}

// --- Crystal timers ---
for (var _i = 0; _i < crystal_count; _i++) {
    if (crystal_timer[_i] > 0) crystal_timer[_i]--;
}

// --- Camera shake decay ---
if (camera_shake > 0) camera_shake *= 0.9;
if (camera_shake < 0.5) camera_shake = 0;

// --- Charge queue ---
for (var _ci = charge_count - 1; _ci >= 0; _ci--) {
    charge_timer[_ci]--;
    if (charge_timer[_ci] <= 0) {
        var _src = charge_source[_ci];
        var _tgt = charge_target[_ci];
        if (unit_alive[_src] && unit_alive[_tgt]) {
            var _dmg = max(1, unit_atk[_src] - unit_def[_tgt]);
            var _src_h = tile_height[unit_gx[_src] * grid_w + unit_gy[_src]];
            var _tgt_h = tile_height[unit_gx[_tgt] * grid_w + unit_gy[_tgt]];
            if (_src_h > _tgt_h) _dmg++;

            unit_hp[_tgt] -= _dmg;
            camera_shake = 6;

            if (popup_count < 16) {
                var _sx = play_ox + play_w * 0.5 + (unit_gx[_tgt] - unit_gy[_tgt]) * _tile_w * 0.5;
                var _sy = play_oy + 120 + (unit_gx[_tgt] + unit_gy[_tgt]) * _tile_h * 0.5 - tile_height[unit_gx[_tgt] * grid_w + unit_gy[_tgt]] * _height_px - 20;
                popup_x[popup_count] = _sx;
                popup_y[popup_count] = _sy;
                popup_val[popup_count] = _dmg;
                popup_timer[popup_count] = 50;
                popup_is_heal[popup_count] = false;
                popup_count++;
            }

            if (unit_hp[_tgt] <= 0) {
                unit_alive[_tgt] = false;
                if (unit_team[_tgt] == 1) points += 25;
            }
        }
        charge_count--;
        charge_source[_ci] = charge_source[charge_count];
        charge_target[_ci] = charge_target[charge_count];
        charge_timer[_ci] = charge_timer[charge_count];
    }
}

// --- CT System ---
if (ct_running && active_unit == -1) {
    var _best = -1;
    var _best_ct = -1;

    for (var _i = 0; _i < unit_count; _i++) {
        if (unit_alive[_i]) {
            unit_ct[_i] += unit_spd[_i];
            if (unit_ct[_i] >= 100 && unit_ct[_i] > _best_ct) {
                _best_ct = unit_ct[_i];
                _best = _i;
            }
        }
    }

    if (_best >= 0) {
        active_unit = _best;
        unit_ct[_best] = 0;
        unit_acted[_best] = false;
        unit_moved[_best] = false;
        turn_phase = 0;
        ct_running = false;
        selected_tile_gx = -1;
        selected_tile_gy = -1;

        // --- Calculate valid moves + attacks immediately ---
        // Valid moves
        valid_move_count = 0;
        var _range = unit_move_range[_best];
        for (var _dx = -_range; _dx <= _range; _dx++) {
            for (var _dy = -_range; _dy <= _range; _dy++) {
                if (abs(_dx) + abs(_dy) > _range) continue;
                if (_dx == 0 && _dy == 0) continue;
                var _ngx = unit_gx[_best] + _dx;
                var _ngy = unit_gy[_best] + _dy;
                if (_ngx < 0 || _ngx >= grid_w || _ngy < 0 || _ngy >= grid_h) continue;

                var _cur_h = tile_height[unit_gx[_best] * grid_w + unit_gy[_best]];
                var _new_h = tile_height[_ngx * grid_w + _ngy];
                if (abs(_cur_h - _new_h) > 1) continue;

                var _occ = false;
                for (var _k = 0; _k < unit_count; _k++) {
                    if (unit_alive[_k] && unit_gx[_k] == _ngx && unit_gy[_k] == _ngy) {
                        _occ = true;
                        break;
                    }
                }
                if (_occ) continue;

                valid_moves[valid_move_count] = _ngx * grid_w + _ngy;
                valid_move_count++;
            }
        }

        // Valid attacks
        valid_attack_count = 0;
        var _atk_range = unit_atk_range[_best];
        for (var _j = 0; _j < unit_count; _j++) {
            if (!unit_alive[_j] || unit_team[_j] == unit_team[_best]) continue;
            var _d = abs(unit_gx[_best] - unit_gx[_j]) + abs(unit_gy[_best] - unit_gy[_j]);
            if (_d <= _atk_range) {
                valid_attacks[valid_attack_count] = _j;
                valid_attack_count++;
            }
        }

        // If enemy, do AI
        if (unit_team[_best] == 1) {
            var _au = _best;
            var _nearest = -1;
            var _nearest_dist = 9999;

            for (var _j = 0; _j < unit_count; _j++) {
                if (unit_alive[_j] && unit_team[_j] == 0) {
                    var _d = abs(unit_gx[_au] - unit_gx[_j]) + abs(unit_gy[_au] - unit_gy[_j]);
                    if (_d < _nearest_dist) {
                        _nearest_dist = _d;
                        _nearest = _j;
                    }
                }
            }

            if (_nearest >= 0) {
                var _can_attack_now = (_nearest_dist <= unit_atk_range[_au]);

                if (!_can_attack_now) {
                    var _best_move_gx = unit_gx[_au];
                    var _best_move_gy = unit_gy[_au];
                    var _best_move_dist = _nearest_dist;

                    for (var _dx = -unit_move_range[_au]; _dx <= unit_move_range[_au]; _dx++) {
                        for (var _dy = -unit_move_range[_au]; _dy <= unit_move_range[_au]; _dy++) {
                            if (abs(_dx) + abs(_dy) > unit_move_range[_au]) continue;
                            var _ngx = unit_gx[_au] + _dx;
                            var _ngy = unit_gy[_au] + _dy;
                            if (_ngx < 0 || _ngx >= grid_w || _ngy < 0 || _ngy >= grid_h) continue;

                            var _cur_h = tile_height[unit_gx[_au] * grid_w + unit_gy[_au]];
                            var _new_h = tile_height[_ngx * grid_w + _ngy];
                            if (abs(_cur_h - _new_h) > 1) continue;

                            var _occupied = false;
                            for (var _k = 0; _k < unit_count; _k++) {
                                if (unit_alive[_k] && _k != _au && unit_gx[_k] == _ngx && unit_gy[_k] == _ngy) {
                                    _occupied = true;
                                    break;
                                }
                            }
                            if (_occupied) continue;

                            var _d2 = abs(_ngx - unit_gx[_nearest]) + abs(_ngy - unit_gy[_nearest]);
                            var _score = _d2;
                            if (unit_class[_au] == 4 && _new_h > _cur_h) _score -= 2;

                            if (_score < _best_move_dist) {
                                _best_move_dist = _score;
                                _best_move_gx = _ngx;
                                _best_move_gy = _ngy;
                            }
                        }
                    }

                    if (_best_move_gx != unit_gx[_au] || _best_move_gy != unit_gy[_au]) {
                        var _fdx = _best_move_gx - unit_gx[_au];
                        var _fdy = _best_move_gy - unit_gy[_au];
                        if (abs(_fdx) >= abs(_fdy)) {
                            unit_facing[_au] = (_fdx > 0) ? 2 : 0;
                        } else {
                            unit_facing[_au] = (_fdy > 0) ? 1 : 3;
                        }

                        anim_type = 1;
                        anim_unit = _au;
                        anim_start_gx = unit_gx[_au];
                        anim_start_gy = unit_gy[_au];
                        anim_end_gx = _best_move_gx;
                        anim_end_gy = _best_move_gy;

                        unit_gx[_au] = _best_move_gx;
                        unit_gy[_au] = _best_move_gy;
                    }

                    _nearest_dist = abs(unit_gx[_au] - unit_gx[_nearest]) + abs(unit_gy[_au] - unit_gy[_nearest]);
                    _can_attack_now = (_nearest_dist <= unit_atk_range[_au]);
                }

                if (_can_attack_now) {
                    var _tgt = _nearest;
                    var _dmg = max(1, unit_atk[_au] - unit_def[_tgt]);

                    var _src_h = tile_height[unit_gx[_au] * grid_w + unit_gy[_au]];
                    var _tgt_h = tile_height[unit_gx[_tgt] * grid_w + unit_gy[_tgt]];
                    if (_src_h > _tgt_h) _dmg++;

                    var _behind = false;
                    var _fdx2 = unit_gx[_au] - unit_gx[_tgt];
                    var _fdy2 = unit_gy[_au] - unit_gy[_tgt];
                    if (unit_facing[_tgt] == 0 && _fdx2 > 0) _behind = true;
                    if (unit_facing[_tgt] == 2 && _fdx2 < 0) _behind = true;
                    if (unit_facing[_tgt] == 3 && _fdy2 > 0) _behind = true;
                    if (unit_facing[_tgt] == 1 && _fdy2 < 0) _behind = true;
                    if (_behind) _dmg++;

                    unit_hp[_tgt] -= _dmg;
                    camera_shake = 6;

                    var _adx = unit_gx[_tgt] - unit_gx[_au];
                    var _ady = unit_gy[_tgt] - unit_gy[_au];
                    if (abs(_adx) >= abs(_ady)) {
                        unit_facing[_au] = (_adx > 0) ? 2 : 0;
                    } else {
                        unit_facing[_au] = (_ady > 0) ? 1 : 3;
                    }

                    if (popup_count < 16) {
                        var _sx = play_ox + play_w * 0.5 + (unit_gx[_tgt] - unit_gy[_tgt]) * _tile_w * 0.5;
                        var _sy = play_oy + 120 + (unit_gx[_tgt] + unit_gy[_tgt]) * _tile_h * 0.5 - tile_height[unit_gx[_tgt] * grid_w + unit_gy[_tgt]] * _height_px - 20;
                        popup_x[popup_count] = _sx;
                        popup_y[popup_count] = _sy;
                        popup_val[popup_count] = _dmg;
                        popup_timer[popup_count] = 50;
                        popup_is_heal[popup_count] = false;
                        popup_count++;
                    }

                    if (unit_hp[_tgt] <= 0) {
                        unit_alive[_tgt] = false;
                    }

                    anim_type = 2;
                    anim_unit = _au;
                    anim_attack_target = _tgt;
                    game_state = 3;
                    anim_timer = 20;
                    anim_timer_max = 20;
                    active_unit = -1;
                    ct_running = true;
                    exit;
                }
            }

            // End enemy turn
            game_state = 3;
            anim_timer = 15;
            anim_timer_max = 15;
            active_unit = -1;
            ct_running = true;
            exit;
        }
    }
    exit;
}

// --- Player turn: direct tap interaction ---
if (active_unit < 0 || unit_team[active_unit] != 0) exit;

var _au = active_unit;

// --- Auto-end turn if no moves and no attacks available ---
if (valid_move_count == 0 && valid_attack_count == 0) {
    active_unit = -1;
    ct_running = true;
    exit;
}

var _tap = device_mouse_check_button_pressed(0, mb_left);
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);

// --- Check "End Turn" button tap ---
if (_tap) {
    var _btn_w = 110;
    var _btn_h = 40;
    var _btn_x = play_w - _btn_w - 12;
    var _btn_y = play_h - _btn_h - 12;
    if (_mx >= _btn_x && _mx <= _btn_x + _btn_w && _my >= _btn_y && _my <= _btn_y + _btn_h) {
        active_unit = -1;
        ct_running = true;
        exit;
    }
}

// --- Convert tap to grid ---
var _tap_gx = -1;
var _tap_gy = -1;
if (_tap) {
    var _rel_x = _mx - play_ox - play_w * 0.5;
    var _rel_y = _my - play_oy - 80;

    // Find nearest tile center to tap point (no strict diamond check — more forgiving for touch)
    var _best_dist = 9999;
    for (var _gx = 0; _gx < grid_w; _gx++) {
        for (var _gy = 0; _gy < grid_h; _gy++) {
            var _sx = ((_gx - _gy) * _tile_w * 0.5);
            var _sy = ((_gx + _gy) * _tile_h * 0.5) - tile_height[_gx * grid_w + _gy] * _height_px;
            var _dx = abs(_rel_x - _sx) / (_tile_w * 0.5);
            var _dy = abs(_rel_y - _sy) / (_tile_h * 0.5);
            var _d = _dx + _dy;
            if (_d < _best_dist && _d < 1.5) {
                _best_dist = _d;
                _tap_gx = _gx;
                _tap_gy = _gy;
            }
        }
    }
}

if (!_tap || _tap_gx < 0) exit;

// --- Check what's on the tapped tile ---
// Is it an enemy we can attack?
var _tapped_enemy = -1;
for (var _i = 0; _i < valid_attack_count; _i++) {
    var _tgt = valid_attacks[_i];
    if (unit_gx[_tgt] == _tap_gx && unit_gy[_tgt] == _tap_gy) {
        _tapped_enemy = _tgt;
        break;
    }
}

// Is it a valid move tile?
var _tapped_move = false;
var _move_key = _tap_gx * grid_w + _tap_gy;
for (var _i = 0; _i < valid_move_count; _i++) {
    if (valid_moves[_i] == _move_key) { _tapped_move = true; break; }
}

// Update info_unit for any unit on tapped tile
info_unit = -1;
for (var _i = 0; _i < unit_count; _i++) {
    if (unit_alive[_i] && unit_gx[_i] == _tap_gx && unit_gy[_i] == _tap_gy) {
        info_unit = _i;
        break;
    }
}

// --- Tap-to-select, tap-again-to-confirm ---
var _is_confirm = (selected_tile_gx == _tap_gx && selected_tile_gy == _tap_gy);

if (_is_confirm) {
    // Second tap on same tile — confirm action
    selected_tile_gx = -1;
    selected_tile_gy = -1;

    // --- Priority: attack enemy > move to tile ---
    if (_tapped_enemy >= 0 && !unit_acted[_au]) {
        var _hit = _tapped_enemy;

        // Face target
        var _adx = unit_gx[_hit] - unit_gx[_au];
        var _ady = unit_gy[_hit] - unit_gy[_au];
        if (abs(_adx) >= abs(_ady)) {
            unit_facing[_au] = (_adx > 0) ? 2 : 0;
        } else {
            unit_facing[_au] = (_ady > 0) ? 1 : 3;
        }

        // BlackMage: charge spell
        if (unit_class[_au] == 1) {
            if (charge_count < 8) {
                charge_source[charge_count] = _au;
                charge_target[charge_count] = _hit;
                charge_timer[charge_count] = 60;
                charge_count++;
            }
            unit_acted[_au] = true;
            if (unit_moved[_au]) {
                active_unit = -1;
                ct_running = true;
            } else {
                valid_attack_count = 0;
            }
        } else {
            // Direct attack
            var _dmg = max(1, unit_atk[_au] - unit_def[_hit]);

            var _src_h = tile_height[unit_gx[_au] * grid_w + unit_gy[_au]];
            var _tgt_h = tile_height[unit_gx[_hit] * grid_w + unit_gy[_hit]];
            if (_src_h > _tgt_h) _dmg++;
            if (unit_class[_au] == 2 && _src_h > _tgt_h) _dmg++;

            var _behind = false;
            var _fdx2 = unit_gx[_au] - unit_gx[_hit];
            var _fdy2 = unit_gy[_au] - unit_gy[_hit];
            if (unit_facing[_hit] == 0 && _fdx2 > 0) _behind = true;
            if (unit_facing[_hit] == 2 && _fdx2 < 0) _behind = true;
            if (unit_facing[_hit] == 3 && _fdy2 > 0) _behind = true;
            if (unit_facing[_hit] == 1 && _fdy2 < 0) _behind = true;
            if (_behind) _dmg++;

            unit_hp[_hit] -= _dmg;
            camera_shake = 6;

            if (popup_count < 16) {
                var _sx = play_ox + play_w * 0.5 + (unit_gx[_hit] - unit_gy[_hit]) * _tile_w * 0.5;
                var _sy = play_oy + 120 + (unit_gx[_hit] + unit_gy[_hit]) * _tile_h * 0.5 - tile_height[unit_gx[_hit] * grid_w + unit_gy[_hit]] * _height_px - 20;
                popup_x[popup_count] = _sx;
                popup_y[popup_count] = _sy;
                popup_val[popup_count] = _dmg;
                popup_timer[popup_count] = 50;
                popup_is_heal[popup_count] = false;
                popup_count++;
            }

            if (unit_hp[_hit] <= 0) {
                unit_alive[_hit] = false;
                if (unit_team[_hit] == 1) points += 25;
            }

            unit_acted[_au] = true;
            anim_type = 2;
            anim_unit = _au;
            anim_attack_target = _hit;
            game_state = 3;
            anim_timer = 20;
            anim_timer_max = 20;

            active_unit = -1;
            ct_running = true;
        }
    } else if (_tapped_move && !unit_moved[_au]) {
        var _fdx = _tap_gx - unit_gx[_au];
        var _fdy = _tap_gy - unit_gy[_au];
        if (abs(_fdx) >= abs(_fdy)) {
            unit_facing[_au] = (_fdx > 0) ? 2 : 0;
        } else {
            unit_facing[_au] = (_fdy > 0) ? 1 : 3;
        }

        anim_type = 1;
        anim_unit = _au;
        anim_start_gx = unit_gx[_au];
        anim_start_gy = unit_gy[_au];
        anim_end_gx = _tap_gx;
        anim_end_gy = _tap_gy;

        unit_gx[_au] = _tap_gx;
        unit_gy[_au] = _tap_gy;
        unit_moved[_au] = true;
        valid_move_count = 0;

        game_state = 3;
        anim_timer = 12;
        anim_timer_max = 12;
        anim_attack_target = -1;
    }
} else {
    // First tap — select this tile
    if (_tapped_enemy >= 0 || _tapped_move) {
        selected_tile_gx = _tap_gx;
        selected_tile_gy = _tap_gy;
    } else {
        // Tapped a non-actionable tile — deselect
        selected_tile_gx = -1;
        selected_tile_gy = -1;
    }
}
