// ========================================
// GEM FORGE — Step_0.gml (Game Logic)
// ========================================

// --- Loading State ---
if (game_state == 0) {
    if (state_loaded) {
        if (state_data != undefined) {
            try {
                points = state_data.p;
                round_num = state_data.rn;
                round_score = state_data.rs;
                target_score = state_data.ts;
                moves_left = state_data.ml;
                max_moves = state_data.mm;
                for (var _c = 0; _c < GF_COLS; _c++)
                    for (var _r = 0; _r < GF_ROWS; _r++)
                        grid[_c][_r] = state_data.g[_c][_r];
                active_mods = state_data.am;
                mod_bomb_count = state_data.mbc;
                mod_lightning_count = state_data.mlc;
                mod_mult_count = state_data.mmc;
                mod_cascade_count = state_data.mcc;
                mod_extra_moves = state_data.mem;
                // Restore num_colors
                if (variable_struct_exists(state_data, "nc"))
                    num_colors = state_data.nc;
                // Restore special gem grid
                if (variable_struct_exists(state_data, "sp")) {
                    for (var _c = 0; _c < GF_COLS; _c++)
                        for (var _r = 0; _r < GF_ROWS; _r++)
                            special[_c][_r] = state_data.sp[_c][_r];
                }
                game_state = 1;
                alarm[0] = room_speed * 20;
            } catch (_ex) {
                points = 0;
                round_num = 1;
                round_score = 0;
                target_score = GF_BASE_TARGET;
                moves_left = GF_BASE_MOVES;
                max_moves = GF_BASE_MOVES;
                num_colors = 5;
                active_mods = [];
                mod_bomb_count = 0;
                mod_lightning_count = 0;
                mod_mult_count = 0;
                mod_cascade_count = 0;
                mod_extra_moves = 0;
                fill_grid_cascade();
                game_state = 1;
                alarm[0] = room_speed * 20;
            }
        } else {
            fill_grid_cascade();
            game_state = 1;
            alarm[0] = room_speed * 20;
        }
    }
    exit;
}

// --- Update Popups (always) ---
for (var _i = array_length(popups) - 1; _i >= 0; _i--) {
    popups[_i].y -= 1.5;
    popups[_i].t--;
    if (popups[_i].t <= 0) array_delete(popups, _i, 1);
}
if (combo_timer > 0) combo_timer--;
if (round_msg_timer > 0) round_msg_timer--;

// Update FX
for (var _i = array_length(fx) - 1; _i >= 0; _i--) {
    fx[_i].t++;
    if (fx[_i].t >= fx[_i].mt) array_delete(fx, _i, 1);
}

// Update shake
if (shake_timer > 0) {
    shake_timer--;
    var _fac = min(shake_timer / 5, 1);
    shake_x = random_range(-shake_intensity, shake_intensity) * _fac;
    shake_y = random_range(-shake_intensity, shake_intensity) * _fac;
    if (shake_timer <= 0) { shake_x = 0; shake_y = 0; shake_intensity = 0; }
}

// Update confetti
for (var _i = array_length(confetti) - 1; _i >= 0; _i--) {
    confetti[_i].x += confetti[_i].vx;
    confetti[_i].y += confetti[_i].vy;
    confetti[_i].vy += 0.08;
    confetti[_i].rot += confetti[_i].rs;
    confetti[_i].life--;
    if (confetti[_i].life <= 0 || confetti[_i].y > scr_h + 50)
        array_delete(confetti, _i, 1);
}

// --- Playing State ---
if (game_state == 1) {

    var _fall_spd = max(cell_size * 0.15, 6);

    // SWAP animation
    if (anim_state == 1) {
        swap_progress += GF_SWAP_SPD;
        if (swap_progress >= 1) {
            swap_progress = 1;
            var _tmp = grid[swap_c1][swap_r1];
            grid[swap_c1][swap_r1] = grid[swap_c2][swap_r2];
            grid[swap_c2][swap_r2] = _tmp;
            var _stmp = special[swap_c1][swap_r1];
            special[swap_c1][swap_r1] = special[swap_c2][swap_r2];
            special[swap_c2][swap_r2] = _stmp;
            if (find_and_mark_matches()) {
                moves_left--;
                spawn_match_fx();
                combo_count = 0;
                score_matches();
                anim_state = 2;
                clear_timer = GF_CLEAR_FRAMES;
            } else {
                _tmp = grid[swap_c1][swap_r1];
                grid[swap_c1][swap_r1] = grid[swap_c2][swap_r2];
                grid[swap_c2][swap_r2] = _tmp;
                _stmp = special[swap_c1][swap_r1];
                special[swap_c1][swap_r1] = special[swap_c2][swap_r2];
                special[swap_c2][swap_r2] = _stmp;
                swap_failed = true;
                swap_progress = 0;
                anim_state = 5;
            }
        }
    }

    // REVERSE SWAP (failed)
    if (anim_state == 5) {
        swap_progress += GF_SWAP_SPD;
        if (swap_progress >= 1) {
            anim_state = 0;
        }
    }

    // CLEAR animation
    if (anim_state == 2) {
        clear_timer--;
        var _t = clear_timer / GF_CLEAR_FRAMES;
        for (var _c = 0; _c < GF_COLS; _c++)
            for (var _r = 0; _r < GF_ROWS; _r++)
                if (marked[_c][_r]) gem_scale[_c][_r] = _t;
        if (clear_timer <= 0) {
            spawn_clear_pops();
            remove_marked();
            apply_gravity();
            anim_state = 3;
        }
    }

    // FALL animation
    if (anim_state == 3) {
        var _settled = true;
        for (var _c = 0; _c < GF_COLS; _c++) {
            for (var _r = 0; _r < GF_ROWS; _r++) {
                if (gem_y_off[_c][_r] < 0) {
                    gem_y_off[_c][_r] = min(gem_y_off[_c][_r] + _fall_spd, 0);
                    if (gem_y_off[_c][_r] < 0) _settled = false;
                }
            }
        }
        if (_settled) {
            if (find_and_mark_matches()) {
                combo_count++;
                spawn_match_fx();
                score_matches();
                anim_state = 2;
                clear_timer = GF_CLEAR_FRAMES;
            } else {
                combo_count = 0;
                anim_state = 0;
                if (round_score >= target_score) {
                    check_round_end();
                } else if (moves_left <= 0) {
                    check_round_end();
                } else if (!has_valid_moves()) {
                    fill_grid();
                    round_msg = "No moves! Reshuffled";
                    round_msg_timer = 40;
                }
            }
        }
    }

    // === Input (only when idle) ===
    if (anim_state == 0) {
        if (mouse_check_button_pressed(mb_left)) {
            touch_sx = device_mouse_x_to_gui(0);
            touch_sy = device_mouse_y_to_gui(0);
            touch_col = floor((touch_sx - grid_x) / cell_size);
            touch_row = floor((touch_sy - grid_y) / cell_size);
            touching = true;
        }

        if (mouse_check_button_released(mb_left) && touching) {
            touching = false;
            var _ex = device_mouse_x_to_gui(0);
            var _ey = device_mouse_y_to_gui(0);
            var _dx = _ex - touch_sx;
            var _dy = _ey - touch_sy;

            if (touch_col >= 0 && touch_col < GF_COLS && touch_row >= 0 && touch_row < GF_ROWS) {
                if (abs(_dx) > cell_size * 0.3 || abs(_dy) > cell_size * 0.3) {
                    // Swipe
                    var _sc = touch_col;
                    var _sr = touch_row;
                    var _dc, _dr;
                    if (abs(_dx) > abs(_dy)) {
                        _dc = _sc + sign(_dx);
                        _dr = _sr;
                    } else {
                        _dc = _sc;
                        _dr = _sr + sign(_dy);
                    }
                    if (_dc >= 0 && _dc < GF_COLS && _dr >= 0 && _dr < GF_ROWS) {
                        swap_c1 = _sc; swap_r1 = _sr;
                        swap_c2 = _dc; swap_r2 = _dr;
                        swap_progress = 0;
                        swap_failed = false;
                        anim_state = 1;
                        sel_col = -1; sel_row = -1;
                    }
                } else {
                    // Tap
                    var _tc = touch_col;
                    var _tr = touch_row;
                    if (sel_col == -1) {
                        sel_col = _tc;
                        sel_row = _tr;
                    } else if (_tc == sel_col && _tr == sel_row) {
                        sel_col = -1;
                        sel_row = -1;
                    } else if (abs(_tc - sel_col) + abs(_tr - sel_row) == 1) {
                        swap_c1 = sel_col; swap_r1 = sel_row;
                        swap_c2 = _tc; swap_r2 = _tr;
                        swap_progress = 0;
                        swap_failed = false;
                        anim_state = 1;
                        sel_col = -1; sel_row = -1;
                    } else {
                        sel_col = _tc;
                        sel_row = _tr;
                    }
                }
            }
        }
    }
}

// --- Celebration (tap to continue) ---
if (game_state == 5 && round_msg_timer <= 0) {
    if (mouse_check_button_pressed(mb_left)) {
        generate_cards();
        game_state = 3;
    }
}

// --- Card Selection ---
if (game_state == 3) {
    if (mouse_check_button_pressed(mb_left)) {
        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);
        var _card_w = scr_w * 0.85;
        var _card_h = cell_size * 1.4;
        var _gap = cell_size * 0.3;
        var _total_h = 3 * _card_h + 2 * _gap;
        var _start_y = (scr_h - _total_h) * 0.5;
        var _cx = (scr_w - _card_w) * 0.5;

        for (var _i = 0; _i < array_length(card_options); _i++) {
            var _cy = _start_y + _i * (_card_h + _gap);
            if (_mx >= _cx && _mx <= _cx + _card_w && _my >= _cy && _my <= _cy + _card_h) {
                selected_card = _i;
                card_anim_timer = 45;
                game_state = 6;
                break;
            }
        }
    }
}

// --- Card Animation ---
if (game_state == 6) {
    card_anim_timer--;
    if (card_anim_timer <= 0) {
        apply_mod(card_options[selected_card]);
        start_next_round();
    }
}

// --- Game Over ---
if (game_state == 4) {
    if (!score_submitted) {
        score_submitted = true;
        api_submit_score(points, function(_s, _o, _r, _p) {});
    }
    if (mouse_check_button_pressed(mb_left)) {
        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);
        var _btn_w = scr_w * 0.5;
        var _btn_h = cell_size * 1.0;
        var _bx = (scr_w - _btn_w) * 0.5;
        var _by = scr_h * 0.65;
        if (_mx >= _bx && _mx <= _bx + _btn_w && _my >= _by && _my <= _by + _btn_h) {
            reset_game();
        }
    }
}
