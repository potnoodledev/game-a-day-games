
// === Voxel Miner — Step_0 (Player Movement + Cave-In + Ladders) ===
if (game_state == 0) exit;

// --- Animations ---
lava_pulse += 0.05;
sparkle_time += 0.08;
if (tap_cooldown > 0) tap_cooldown--;
if (combo_timer > 0) combo_timer--;
if (flash_alpha > 0) flash_alpha = max(0, flash_alpha - 0.02);
if (shake_amount > 0) shake_amount = max(0, shake_amount - 0.3);
if (collapse_flash > 0) collapse_flash = max(0, collapse_flash - 0.015);

// --- Animate Player Visual Position ---
var _fall_speed = 0.35;
var _move_speed = 0.4;
if (abs(player_draw_row - player_row) > 0.05) {
    player_draw_row += clamp(player_row - player_draw_row, -_fall_speed, _fall_speed);
} else {
    player_draw_row = player_row;
}
if (abs(player_draw_col - player_col) > 0.05) {
    player_draw_col += clamp(player_col - player_draw_col, -_move_speed, _move_speed);
} else {
    player_draw_col = player_col;
}
var _player_animating = (abs(player_draw_row - player_row) > 0.05 || abs(player_draw_col - player_col) > 0.05);

// --- Update Particles ---
for (var _i = p_count - 1; _i >= 0; _i--) {
    p_x[_i] += p_vx[_i];
    p_y[_i] += p_vy[_i];
    p_vy[_i] += 0.3;
    p_life[_i] -= 0.03;
    if (p_life[_i] <= 0) {
        p_count--;
        p_x[_i] = p_x[p_count];
        p_y[_i] = p_y[p_count];
        p_vx[_i] = p_vx[p_count];
        p_vy[_i] = p_vy[p_count];
        p_col[_i] = p_col[p_count];
        p_life[_i] = p_life[p_count];
    }
}

// --- Update Float Text ---
for (var _i = f_count - 1; _i >= 0; _i--) {
    f_y[_i] -= 1.5;
    f_life[_i] -= 0.02;
    if (f_life[_i] <= 0) {
        f_count--;
        f_x[_i] = f_x[f_count];
        f_y[_i] = f_y[f_count];
        f_text[_i] = f_text[f_count];
        f_col[_i] = f_col[f_count];
        f_life[_i] = f_life[f_count];
    }
}

// === COLLAPSING STATE — Cave-In Sequence ===
if (collapsing) {
    var _changed = false;
    for (var _c = 0; _c < grid_cols; _c++) {
        for (var _r = grid_rows - 2; _r >= 0; _r--) {
            var _b = grid[_c][_r];
            // Ladders don't fall during cave-in (they're structural)
            if (_b != EMPTY && _b != BEDROCK && _b != LAVA && _b != LADDER && grid[_c][_r + 1] == EMPTY) {
                grid[_c][_r + 1] = _b;
                durability[_c][_r + 1] = durability[_c][_r];
                grid[_c][_r] = EMPTY;
                durability[_c][_r] = 0;
                _changed = true;
            }
        }
    }

    if (!_changed) {
        // Settling done — check if player is crushed
        if (grid[player_col][player_row] != EMPTY && grid[player_col][player_row] != LADDER) {
            flash_alpha = 0.6;
            shake_amount = 10;

            var _ppx = grid_ox + player_col * cell_size + cell_size * 0.5;
            var _ppy = grid_oy + player_draw_row * cell_size - scroll_y + cell_size * 0.5;
            for (var _p = 0; _p < 15; _p++) {
                if (p_count < p_max) {
                    p_x[p_count] = _ppx;
                    p_y[p_count] = _ppy;
                    p_vx[p_count] = random_range(-6, 6);
                    p_vy[p_count] = random_range(-8, -2);
                    p_col[p_count] = merge_colour(c_red, c_orange, random(1));
                    p_life[p_count] = 1.0;
                    p_count++;
                }
            }

            if (f_count < f_max) {
                f_x[f_count] = _ppx;
                f_y[f_count] = _ppy;
                f_text[f_count] = "CRUSHED!";
                f_col[f_count] = c_red;
                f_life[f_count] = 1.0;
                f_count++;
            }

            // Death animation init (cave-in crush)
            death_x = grid_ox + player_col * cell_size + cell_size * 0.5;
            death_y = grid_oy + player_draw_row * cell_size - scroll_y + cell_size * 0.5;
            death_hat_x = death_x;
            death_hat_y = death_y - cell_size * 0.3;
            death_hat_vx = random_range(-3, 3);
            death_hat_vy = random_range(-8, -5);
            death_hat_rot = 0;
            death_pick_x = death_x + player_facing * cell_size * 0.4;
            death_pick_y = death_y;
            death_pick_vx = player_facing * random_range(2, 5);
            death_pick_vy = random_range(-6, -3);
            death_pick_rot = 0;
            death_ghost_y = 0;

            game_state = 2;
            gameover_timer = 0;
            collapsing = false;
            api_submit_score(points, undefined);
            api_save_state(max_depth, { points: points }, undefined);
            exit;
        }

        // Apply player gravity after collapse (LADDER = solid ground)
        while (player_row < grid_rows - 1 && grid[player_col][player_row + 1] == EMPTY) {
            player_row++;
        }

        collapse_timer = collapse_max;
        stalactite_speed *= 1.3;
        collapsing = false;
    }
    exit;
}

// --- Game Over: tap to restart ---
if (game_state == 2) {
    gameover_timer++;

    // Animate hat flying off
    death_hat_x += death_hat_vx;
    death_hat_y += death_hat_vy;
    death_hat_vy += 0.2;
    death_hat_rot += death_hat_vx * 3;

    // Animate pickaxe flying off
    death_pick_x += death_pick_vx;
    death_pick_y += death_pick_vy;
    death_pick_vy += 0.25;
    death_pick_rot += death_pick_vx * 5;

    // Ghost rises after short delay
    if (gameover_timer > 15) {
        death_ghost_y += 1.2;
    }
    if (gameover_timer > 60) {
        var _restart = device_mouse_check_button_pressed(0, mb_left);
        if (!_restart) _restart = keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter);
        if (_restart) {
            points = 0;
            prev_points = 0;
            lives = 3;
            combo_type = -1;
            combo_count = 0;
            combo_timer = 0;
            max_depth = 0;
            scroll_y = 0;
            scroll_target = 0;
            collapsing = false;
            collapse_timer = collapse_max;
            collapse_flash = 0;
            shake_amount = 0;
            stalactite_y = -3;
            stalactite_speed = 0.008;
            stalactite_prev_row = -3;
            player_col = 5;
            player_row = 1;
            player_draw_col = 5;
            player_draw_row = 1;
            player_facing = 1;
            p_count = 0;
            f_count = 0;
            flash_alpha = 0;
            gameover_timer = 0;
            gen_grid();
            game_state = 1;
        }
    }
    exit;
}

// === PLAYING STATE ===
if (game_state != 1) exit;

// --- Stalactite Advance ---
stalactite_y += stalactite_speed;
// Crush based on tip position (solid zone ends at stalactite_y+1, tips extend 0.7 below that)
var _new_crush_row = floor(stalactite_y + 1.7);
if (_new_crush_row > stalactite_prev_row) {
    for (var _cr = stalactite_prev_row + 1; _cr <= _new_crush_row; _cr++) {
        if (_cr >= 0 && _cr < grid_rows) {
            for (var _cc = 0; _cc < grid_cols; _cc++) {
                var _cb = grid[_cc][_cr];
                if (_cb != EMPTY) {
                    // Spawn colored debris particles per crushed block
                    var _bpx = grid_ox + _cc * cell_size + cell_size * 0.5;
                    var _bpy = grid_oy + _cr * cell_size - scroll_y + cell_size * 0.5;
                    var _bcol = block_color[_cb];
                    for (var _bp = 0; _bp < 3; _bp++) {
                        if (p_count < p_max) {
                            p_x[p_count] = _bpx + random_range(-cell_size * 0.3, cell_size * 0.3);
                            p_y[p_count] = _bpy + random_range(-cell_size * 0.3, cell_size * 0.3);
                            p_vx[p_count] = random_range(-2, 2);
                            p_vy[p_count] = random_range(2, 6);
                            p_col[p_count] = merge_colour(_bcol, c_white, random(0.3));
                            p_life[p_count] = 0.8;
                            p_count++;
                        }
                    }
                }
                grid[_cc][_cr] = EMPTY;
                durability[_cc][_cr] = 0;
            }
        }
    }
    stalactite_prev_row = _new_crush_row;
}
// Stalactite rumble — subtle constant shake that grows as it gets closer
var _stala_proximity = max(0, 1.0 - (player_row - stalactite_y) / 10.0);
shake_amount = max(shake_amount, _stala_proximity * 1.5);

// Check if stalactite tips reached player (solid at +1, tips at +1.7)
if (stalactite_y + 1.7 >= player_row) {
    flash_alpha = 0.6;
    shake_amount = 10;
    var _ppx = grid_ox + player_col * cell_size + cell_size * 0.5;
    var _ppy = grid_oy + player_draw_row * cell_size - scroll_y + cell_size * 0.5;
    for (var _p = 0; _p < 15; _p++) {
        if (p_count < p_max) {
            p_x[p_count] = _ppx;
            p_y[p_count] = _ppy;
            p_vx[p_count] = random_range(-6, 6);
            p_vy[p_count] = random_range(-8, -2);
            p_col[p_count] = merge_colour(col_stalactite, c_white, random(0.5));
            p_life[p_count] = 1.0;
            p_count++;
        }
    }
    if (f_count < f_max) {
        f_x[f_count] = _ppx;
        f_y[f_count] = _ppy;
        f_text[f_count] = "CRUSHED!";
        f_col[f_count] = col_stalactite_tip;
        f_life[f_count] = 1.0;
        f_count++;
    }
    // Death animation init (stalactite crush)
    death_x = _ppx;
    death_y = _ppy;
    death_hat_x = death_x;
    death_hat_y = death_y - cell_size * 0.3;
    death_hat_vx = random_range(-3, 3);
    death_hat_vy = random_range(-8, -5);
    death_hat_rot = 0;
    death_pick_x = death_x + player_facing * cell_size * 0.4;
    death_pick_y = death_y;
    death_pick_vx = player_facing * random_range(2, 5);
    death_pick_vy = random_range(-6, -3);
    death_pick_rot = 0;
    death_ghost_y = 0;

    game_state = 2;
    gameover_timer = 0;
    api_submit_score(points, undefined);
    api_save_state(max_depth, { points: points }, undefined);
    exit;
}

// --- Cave-In Timer ---
collapse_timer--;

if (collapse_timer < 180 && collapse_timer > 0) {
    shake_amount = max(shake_amount, (1 - collapse_timer / 180) * 4);
}

if (collapse_timer <= 0) {
    collapsing = true;
    collapse_flash = 1.0;
    shake_amount = 8;
    exit;
}

// --- Player Gravity (LADDER = solid ground) ---
while (player_row < grid_rows - 1 && grid[player_col][player_row + 1] == EMPTY) {
    player_row++;
}

// --- Input: Tap + Keyboard (disabled while animating) ---
var _input_dir_x = 0;
var _input_dir_y = 0;
var _has_input = false;

if (!_player_animating && tap_cooldown <= 0) {
    if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) {
        _input_dir_x = -1;
        _has_input = true;
    }
    else if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) {
        _input_dir_x = 1;
        _has_input = true;
    }
    else if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
        _input_dir_y = -1;
        _has_input = true;
    }
    else if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
        _input_dir_y = 1;
        _has_input = true;
    }

    if (!_has_input && device_mouse_check_button_pressed(0, mb_left)) {
        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);

        if (_my >= hud_h + 20) {
            var _player_sx = grid_ox + player_draw_col * cell_size + cell_size * 0.5;
            var _player_sy = grid_oy + player_draw_row * cell_size - scroll_y + cell_size * 0.5;
            var _tdx = _mx - _player_sx;
            var _tdy = _my - _player_sy;

            if (abs(_tdx) > abs(_tdy)) {
                if (_tdx < 0) _input_dir_x = -1;
                else _input_dir_x = 1;
            } else {
                if (_tdy < 0) _input_dir_y = -1;
                else _input_dir_y = 1;
            }
            _has_input = true;
        }
    }
}

// --- Process Movement / Mining ---
if (_has_input) {
    var _target_col = player_col + _input_dir_x;
    var _target_row = player_row + _input_dir_y;
    var _moving_up = (_input_dir_y == -1);

    // Track facing direction for sprite
    if (_input_dir_x != 0) player_facing = _input_dir_x;

    if (_target_col >= 0 && _target_col < grid_cols && _target_row >= 0 && _target_row < grid_rows) {
        var _block = grid[_target_col][_target_row];

        // Player can walk through EMPTY and LADDER cells
        if (_block == EMPTY || _block == LADDER) {
            var _old_row = player_row;
            player_col = _target_col;
            player_row = _target_row;

            // Moving up: place ladder at old position to prevent falling back
            if (_moving_up && grid[_target_col][_old_row] == EMPTY) {
                grid[_target_col][_old_row] = LADDER;
            }

            // Apply gravity (ladders count as solid ground)
            if (!_moving_up) {
                while (player_row < grid_rows - 1 && grid[player_col][player_row + 1] == EMPTY) {
                    player_row++;
                }
            }

            var _d = player_row - 2;
            if (_d > max_depth) {
                max_depth = _d;
                level = max_depth;
            }

            tap_cooldown = 3;
        }
        else if (_block != BEDROCK) {
            // --- Mine block ---
            var _px = grid_ox + _target_col * cell_size + cell_size * 0.5;
            var _py = grid_oy + _target_row * cell_size - scroll_y + cell_size * 0.5;

            if (_block == LAVA) {
                lives--;
                flash_alpha = 0.4;

                for (var _p = 0; _p < 10; _p++) {
                    if (p_count < p_max) {
                        p_x[p_count] = _px;
                        p_y[p_count] = _py;
                        p_vx[p_count] = random_range(-4, 4);
                        p_vy[p_count] = random_range(-6, -1);
                        p_col[p_count] = merge_colour(c_red, c_orange, random(1));
                        p_life[p_count] = 1.0;
                        p_count++;
                    }
                }

                if (f_count < f_max) {
                    f_x[f_count] = _px;
                    f_y[f_count] = _py;
                    f_text[f_count] = "LAVA!";
                    f_col[f_count] = c_red;
                    f_life[f_count] = 1.0;
                    f_count++;
                }

                grid[_target_col][_target_row] = EMPTY;
                combo_type = -1;
                combo_count = 0;

                if (lives <= 0) {
                    // Death animation init (lava)
                    death_x = grid_ox + player_col * cell_size + cell_size * 0.5;
                    death_y = grid_oy + player_draw_row * cell_size - scroll_y + cell_size * 0.5;
                    death_hat_x = death_x;
                    death_hat_y = death_y - cell_size * 0.3;
                    death_hat_vx = random_range(-3, 3);
                    death_hat_vy = random_range(-8, -5);
                    death_hat_rot = 0;
                    death_pick_x = death_x + player_facing * cell_size * 0.4;
                    death_pick_y = death_y;
                    death_pick_vx = player_facing * random_range(2, 5);
                    death_pick_vy = random_range(-6, -3);
                    death_pick_rot = 0;
                    death_ghost_y = 0;

                    game_state = 2;
                    gameover_timer = 0;
                    api_submit_score(points, undefined);
                    api_save_state(max_depth, { points: points }, undefined);
                }
            }
            else {
                // Decrement durability
                durability[_target_col][_target_row]--;

                if (durability[_target_col][_target_row] <= 0) {
                    // Block breaks!
                    var _depth_mult = 1.0;
                    var _d = _target_row - 2;
                    if (_d >= 35) _depth_mult = 2.0;
                    else if (_d >= 20) _depth_mult = 1.5;

                    if (_block == combo_type && combo_timer > 0) {
                        combo_count++;
                    } else {
                        combo_type = _block;
                        combo_count = 1;
                    }
                    combo_timer = 180;

                    var _combo_mult = 1;
                    if (combo_count >= 8) _combo_mult = 4;
                    else if (combo_count >= 5) _combo_mult = 3;
                    else if (combo_count >= 3) _combo_mult = 2;

                    var _score = floor(block_pts[_block] * _depth_mult * _combo_mult);
                    points += _score;

                    if (_d > max_depth) {
                        max_depth = _d;
                        level = max_depth;
                    }

                    for (var _p = 0; _p < 8; _p++) {
                        if (p_count < p_max) {
                            p_x[p_count] = _px + random_range(-cell_size * 0.3, cell_size * 0.3);
                            p_y[p_count] = _py + random_range(-cell_size * 0.3, cell_size * 0.3);
                            p_vx[p_count] = random_range(-3, 3);
                            p_vy[p_count] = random_range(-5, -1);
                            p_col[p_count] = merge_colour(block_color[_block], c_white, random(0.3));
                            p_life[p_count] = 1.0;
                            p_count++;
                        }
                    }

                    if (f_count < f_max) {
                        f_x[f_count] = _px;
                        f_y[f_count] = _py - cell_size * 0.5;
                        var _txt = "+" + string(_score);
                        if (_combo_mult > 1) _txt += " x" + string(_combo_mult);
                        f_text[f_count] = _txt;
                        f_col[f_count] = block_color_top[_block];
                        f_life[f_count] = 1.0;
                        f_count++;
                    }

                    grid[_target_col][_target_row] = EMPTY;
                    durability[_target_col][_target_row] = 0;
                }
                else {
                    // Block damaged but not broken — spark particles
                    for (var _p = 0; _p < 4; _p++) {
                        if (p_count < p_max) {
                            p_x[p_count] = _px;
                            p_y[p_count] = _py;
                            p_vx[p_count] = random_range(-2, 2);
                            p_vy[p_count] = random_range(-3, -1);
                            p_col[p_count] = merge_colour(block_color[_block], c_white, 0.5);
                            p_life[p_count] = 0.5;
                            p_count++;
                        }
                    }
                    if (f_count < f_max) {
                        f_x[f_count] = _px;
                        f_y[f_count] = _py;
                        f_text[f_count] = "*CRACK*";
                        f_col[f_count] = merge_colour(block_color[_block], c_white, 0.5);
                        f_life[f_count] = 0.5;
                        f_count++;
                    }
                }
            }

            // Only move/apply gravity if block was actually broken or is lava
            var _block_gone = (grid[_target_col][_target_row] == EMPTY);
            if (_block_gone && _moving_up) {
                if (grid[player_col][player_row] == EMPTY) {
                    grid[player_col][player_row] = LADDER;
                    durability[player_col][player_row] = 1;
                }
                player_row = _target_row;
            } else if (_block_gone && !_moving_up) {
                while (player_row < grid_rows - 1 && grid[player_col][player_row + 1] == EMPTY) {
                    player_row++;
                }
            }

            tap_cooldown = 5;
        }
    }
}

// --- Scrolling (follow player visual position) ---
scroll_target = player_draw_row * cell_size - window_height * 0.45;
scroll_target = clamp(scroll_target, 0, (grid_rows - visible_rows) * cell_size);
scroll_y = lerp(scroll_y, scroll_target, 0.08);
