// --- Responsive layout ---
var _ww = max(1, window_get_width());
var _wh = max(1, window_get_height());
play_w = _ww;
play_h = _wh;
play_ox = 0;
play_oy = 0;

// --- Tile sizing ---
var _tile_w = min(play_w, play_h) * 0.12;
var _tile_h = _tile_w * 0.6;
var _height_px = _tile_h * 0.7;

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
        // Spawn next wave
        wave_num++;
        var _enemy_count = min(wave_num + 1, 5);
        var _hp_bonus = floor((wave_num - 1) / 2);
        var _atk_bonus = floor((wave_num - 1) / 3);

        var _spawn_positions_gx = [5, 6, 6, 5, 4];
        var _spawn_positions_gy = [0, 1, 0, 1, 0];

        for (var _i = 0; _i < _enemy_count; _i++) {
            var _idx = unit_count;
            if (_idx >= max_units) break;

            var _cls = 3; // Goblin
            if (_i >= 2) _cls = 4; // EnemyArcher for 3rd+ enemy

            // Check spawn position isn't occupied
            var _sgx = _spawn_positions_gx[_i];
            var _sgy = _spawn_positions_gy[_i];

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
            unit_count++;
        }

        // Reset player unit turn flags
        for (var _i = 0; _i < unit_count; _i++) {
            if (unit_team[_i] == 0 && unit_alive[_i]) {
                unit_acted[_i] = false;
                unit_moved[_i] = false;
            }
        }

        active_unit = -1;
        ct_running = true;
        game_state = 2;
    }
    exit;
}

// --- Game over ---
if (game_state == 5) {
    if (device_mouse_check_button_pressed(0, mb_left)) {
        // Reset game
        game_restart();
    }
    exit;
}

// --- Animating ---
if (game_state == 3) {
    anim_timer--;
    if (anim_timer <= 0) {
        game_state = 2;

        // After attack animation, check for kills
        if (anim_type == 2) {
            // Check for dead units -> crystals
            for (var _i = 0; _i < unit_count; _i++) {
                if (unit_alive[_i] == false && unit_hp[_i] <= 0) {
                    // Already dead, check if crystal not yet dropped
                    // Mark hp as -999 to indicate crystal dropped
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
                    // Heal
                    unit_hp[_au] = min(unit_hp[_au] + 2, unit_max_hp[_au]);
                    crystal_timer[_c] = 0;
                    // Popup
                    if (popup_count < 16) {
                        var _sx = play_ox + play_w * 0.5 + (unit_gx[_au] - unit_gy[_au]) * _tile_w * 0.5;
                        var _sy = play_oy + 80 + (unit_gx[_au] + unit_gy[_au]) * _tile_h * 0.5 - tile_height[unit_gx[_au] * grid_w + unit_gy[_au]] * _height_px - 20;
                        popup_x[popup_count] = _sx;
                        popup_y[popup_count] = _sy;
                        popup_val[popup_count] = 2;
                        popup_timer[popup_count] = 40;
                        popup_is_heal[popup_count] = true;
                        popup_count++;
                    }
                }
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
            // Wave clear
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
        // Remove by swapping with last
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
        // Resolve spell
        var _src = charge_source[_ci];
        var _tgt = charge_target[_ci];
        if (unit_alive[_src] && unit_alive[_tgt]) {
            var _dmg = max(1, unit_atk[_src] - unit_def[_tgt]);
            // Height bonus for mage
            var _src_h = tile_height[unit_gx[_src] * grid_w + unit_gy[_src]];
            var _tgt_h = tile_height[unit_gx[_tgt] * grid_w + unit_gy[_tgt]];
            if (_src_h > _tgt_h) _dmg++;

            unit_hp[_tgt] -= _dmg;
            camera_shake = 6;

            // Popup
            if (popup_count < 16) {
                var _sx = play_ox + play_w * 0.5 + (unit_gx[_tgt] - unit_gy[_tgt]) * _tile_w * 0.5;
                var _sy = play_oy + 80 + (unit_gx[_tgt] + unit_gy[_tgt]) * _tile_h * 0.5 - tile_height[unit_gx[_tgt] * grid_w + unit_gy[_tgt]] * _height_px - 20;
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
        // Remove charge
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

    // Tick CT
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
        menu_option = 0;
        ct_running = false;

        // If enemy, do AI
        if (unit_team[_best] == 1) {
            // --- Enemy AI ---
            var _au = _best;
            var _nearest = -1;
            var _nearest_dist = 9999;

            // Find nearest player unit
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
                // Check if can attack from current position
                var _can_attack_now = (_nearest_dist <= unit_atk_range[_au]);

                if (!_can_attack_now) {
                    // Move toward target
                    var _best_move_gx = unit_gx[_au];
                    var _best_move_gy = unit_gy[_au];
                    var _best_move_dist = _nearest_dist;

                    for (var _dx = -unit_move_range[_au]; _dx <= unit_move_range[_au]; _dx++) {
                        for (var _dy = -unit_move_range[_au]; _dy <= unit_move_range[_au]; _dy++) {
                            if (abs(_dx) + abs(_dy) > unit_move_range[_au]) continue;
                            var _ngx = unit_gx[_au] + _dx;
                            var _ngy = unit_gy[_au] + _dy;
                            if (_ngx < 0 || _ngx >= grid_w || _ngy < 0 || _ngy >= grid_h) continue;

                            // Height check
                            var _cur_h = tile_height[unit_gx[_au] * grid_w + unit_gy[_au]];
                            var _new_h = tile_height[_ngx * grid_w + _ngy];
                            if (abs(_cur_h - _new_h) > 1) continue;

                            // Occupied check
                            var _occupied = false;
                            for (var _k = 0; _k < unit_count; _k++) {
                                if (unit_alive[_k] && _k != _au && unit_gx[_k] == _ngx && unit_gy[_k] == _ngy) {
                                    _occupied = true;
                                    break;
                                }
                            }
                            if (_occupied) continue;

                            var _d2 = abs(_ngx - unit_gx[_nearest]) + abs(_ngy - unit_gy[_nearest]);

                            // Archers prefer high ground
                            var _score = _d2;
                            if (unit_class[_au] == 4 && _new_h > _cur_h) _score -= 2;

                            if (_score < _best_move_dist) {
                                _best_move_dist = _score;
                                _best_move_gx = _ngx;
                                _best_move_gy = _ngy;
                            }
                        }
                    }

                    // Move
                    if (_best_move_gx != unit_gx[_au] || _best_move_gy != unit_gy[_au]) {
                        // Update facing
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

                    // Recalc distance after move
                    _nearest_dist = abs(unit_gx[_au] - unit_gx[_nearest]) + abs(unit_gy[_au] - unit_gy[_nearest]);
                    _can_attack_now = (_nearest_dist <= unit_atk_range[_au]);
                }

                if (_can_attack_now) {
                    // Attack
                    var _tgt = _nearest;
                    var _dmg = max(1, unit_atk[_au] - unit_def[_tgt]);

                    // Height bonus
                    var _src_h = tile_height[unit_gx[_au] * grid_w + unit_gy[_au]];
                    var _tgt_h = tile_height[unit_gx[_tgt] * grid_w + unit_gy[_tgt]];
                    if (_src_h > _tgt_h) _dmg++;

                    // Backstab check
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

                    // Face target
                    var _adx = unit_gx[_tgt] - unit_gx[_au];
                    var _ady = unit_gy[_tgt] - unit_gy[_au];
                    if (abs(_adx) >= abs(_ady)) {
                        unit_facing[_au] = (_adx > 0) ? 2 : 0;
                    } else {
                        unit_facing[_au] = (_ady > 0) ? 1 : 3;
                    }

                    // Popup
                    if (popup_count < 16) {
                        var _sx = play_ox + play_w * 0.5 + (unit_gx[_tgt] - unit_gy[_tgt]) * _tile_w * 0.5;
                        var _sy = play_oy + 80 + (unit_gx[_tgt] + unit_gy[_tgt]) * _tile_h * 0.5 - tile_height[unit_gx[_tgt] * grid_w + unit_gy[_tgt]] * _height_px - 20;
                        popup_x[popup_count] = _sx;
                        popup_y[popup_count] = _sy;
                        popup_val[popup_count] = _dmg;
                        popup_timer[popup_count] = 50;
                        popup_is_heal[popup_count] = false;
                        popup_count++;
                    }

                    if (unit_hp[_tgt] <= 0) {
                        unit_alive[_tgt] = false;
                        if (unit_team[_tgt] == 0) {
                            // Player unit killed by enemy
                        }
                    }

                    anim_type = 2;
                    anim_unit = _au;
                    game_state = 3;
                    anim_timer = 20;
                    active_unit = -1;
                    ct_running = true;
                    exit;
                }
            }

            // End enemy turn
            game_state = 3;
            anim_timer = 15;
            active_unit = -1;
            ct_running = true;
            exit;
        }
    }
    exit;
}

// --- Player turn ---
if (active_unit < 0 || unit_team[active_unit] != 0) exit;

var _au = active_unit;
var _tap = device_mouse_check_button_pressed(0, mb_left);
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);

// --- Convert tap to grid ---
var _tap_gx = -1;
var _tap_gy = -1;
if (_tap) {
    var _rel_x = _mx - play_ox - play_w * 0.5;
    var _rel_y = _my - play_oy - 80;

    // Try each tile and find closest match
    var _best_dist = 9999;
    for (var _gx = 0; _gx < grid_w; _gx++) {
        for (var _gy = 0; _gy < grid_h; _gy++) {
            var _sx = ((_gx - _gy) * _tile_w * 0.5);
            var _sy = ((_gx + _gy) * _tile_h * 0.5) - tile_height[_gx * grid_w + _gy] * _height_px;
            var _dx = _rel_x - _sx;
            var _dy = _rel_y - _sy;
            // Check if point is inside the diamond
            var _ix = abs(_dx) / (_tile_w * 0.5);
            var _iy = abs(_dy) / (_tile_h * 0.5);
            if (_ix + _iy <= 1.0) {
                var _d = abs(_dx) + abs(_dy);
                if (_d < _best_dist) {
                    _best_dist = _d;
                    _tap_gx = _gx;
                    _tap_gy = _gy;
                }
            }
        }
    }
}

// --- Action menu handling ---
if (turn_phase == 0) {
    // Menu: Move / Attack / Wait
    var _menu_x = play_w - 140;
    var _menu_y = play_h - 200;
    var _menu_item_h = 36;

    if (_tap) {
        for (var _m = 0; _m < 3; _m++) {
            var _my1 = _menu_y + 30 + _m * _menu_item_h;
            if (_mx >= _menu_x && _mx <= _menu_x + 130 && _my >= _my1 && _my <= _my1 + _menu_item_h) {
                if (_m == 0 && !unit_moved[_au]) {
                    // Move
                    turn_phase = 1;
                    // Calculate valid moves (BFS)
                    valid_move_count = 0;
                    var _range = unit_move_range[_au];
                    for (var _dx = -_range; _dx <= _range; _dx++) {
                        for (var _dy = -_range; _dy <= _range; _dy++) {
                            if (abs(_dx) + abs(_dy) > _range) continue;
                            if (_dx == 0 && _dy == 0) continue;
                            var _ngx = unit_gx[_au] + _dx;
                            var _ngy = unit_gy[_au] + _dy;
                            if (_ngx < 0 || _ngx >= grid_w || _ngy < 0 || _ngy >= grid_h) continue;

                            var _cur_h = tile_height[unit_gx[_au] * grid_w + unit_gy[_au]];
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
                } else if (_m == 1 && !unit_acted[_au]) {
                    // Attack
                    turn_phase = 2;
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
                } else if (_m == 2) {
                    // Wait - end turn
                    active_unit = -1;
                    ct_running = true;
                }
            }
        }
    }

    // Tap on tile to show unit info
    if (_tap && _tap_gx >= 0) {
        info_unit = -1;
        for (var _i = 0; _i < unit_count; _i++) {
            if (unit_alive[_i] && unit_gx[_i] == _tap_gx && unit_gy[_i] == _tap_gy) {
                info_unit = _i;
                break;
            }
        }
    }
}

// --- Move phase ---
if (turn_phase == 1) {
    if (_tap && _tap_gx >= 0) {
        var _key = _tap_gx * grid_w + _tap_gy;
        var _valid = false;
        for (var _i = 0; _i < valid_move_count; _i++) {
            if (valid_moves[_i] == _key) { _valid = true; break; }
        }
        if (_valid) {
            // Update facing
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
            turn_phase = 0;

            game_state = 3;
            anim_timer = 12;
        } else {
            // Cancel back to menu
            turn_phase = 0;
        }
    }
}

// --- Attack phase ---
if (turn_phase == 2) {
    if (_tap && _tap_gx >= 0) {
        var _hit = -1;
        for (var _i = 0; _i < valid_attack_count; _i++) {
            var _tgt = valid_attacks[_i];
            if (unit_gx[_tgt] == _tap_gx && unit_gy[_tgt] == _tap_gy) {
                _hit = _tgt;
                break;
            }
        }

        if (_hit >= 0) {
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
                    charge_timer[charge_count] = 60; // ~1 second delay
                    charge_count++;
                }
                unit_acted[_au] = true;
                turn_phase = 0;
                // Don't end turn yet, can still move if hasn't
                if (unit_moved[_au]) {
                    active_unit = -1;
                    ct_running = true;
                }
            } else {
                // Direct attack
                var _dmg = max(1, unit_atk[_au] - unit_def[_hit]);

                // Height bonus
                var _src_h = tile_height[unit_gx[_au] * grid_w + unit_gy[_au]];
                var _tgt_h = tile_height[unit_gx[_hit] * grid_w + unit_gy[_hit]];
                if (_src_h > _tgt_h) _dmg++;

                // Archer gets extra height bonus
                if (unit_class[_au] == 2 && _src_h > _tgt_h) _dmg++;

                // Backstab check
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

                // Popup
                if (popup_count < 16) {
                    var _sx = play_ox + play_w * 0.5 + (unit_gx[_hit] - unit_gy[_hit]) * _tile_w * 0.5;
                    var _sy = play_oy + 80 + (unit_gx[_hit] + unit_gy[_hit]) * _tile_h * 0.5 - tile_height[unit_gx[_hit] * grid_w + unit_gy[_hit]] * _height_px - 20;
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
                game_state = 3;
                anim_timer = 20;

                // End turn after attack
                active_unit = -1;
                ct_running = true;
            }
        } else {
            // Cancel
            turn_phase = 0;
        }
    }
}
