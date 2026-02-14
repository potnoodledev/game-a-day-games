
if (tap_cooldown > 0) tap_cooldown--;
if (enemy_hurt_timer > 0) enemy_hurt_timer--;
if (player_hurt_timer > 0) player_hurt_timer--;
if (merge_flash_timer > 0) merge_flash_timer--;
if (shake_amount > 0) shake_amount *= 0.85;
if (shake_amount < 0.5) shake_amount = 0;

// Update floating text
for (var _i = 0; _i < fx_max; _i++) {
    if (fx_life[_i] > 0) {
        fx_life[_i]--;
        fx_y[_i] -= 0.8;
    }
}

// === STATE 0: TITLE ===
if (game_state == 0) {
    if (mouse_check_button_pressed(mb_left)) {
        points = 0;
        reset_game();
        game_state = 1;
    }
}

// === STATE 1: PLAYING ===
else if (game_state == 1) {
    if (mouse_check_button_pressed(mb_left) && tap_cooldown <= 0) {
        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);
        var _gw = display_get_gui_width();
        var _gh = display_get_gui_height();

        // Grid layout (must match Draw_64)
        var _grid_avail_h = _gh * 0.40;
        var _cell_size = min((_gw * 0.9) / grid_size, _grid_avail_h / grid_size);
        var _grid_w = _cell_size * grid_size;
        var _grid_top = _gh * 0.32;
        var _grid_left = (_gw - _grid_w) * 0.5;

        // Check if tap is within grid bounds
        var _grid_right = _grid_left + grid_size * _cell_size;
        var _grid_bottom = _grid_top + grid_size * _cell_size;

        if (_mx >= _grid_left && _mx < _grid_right && _my >= _grid_top && _my < _grid_bottom) {
            var _col = floor((_mx - _grid_left) / _cell_size);
            var _row = floor((_my - _grid_top) / _cell_size);

            // Clamp
            if (_col < 0) _col = 0;
            if (_col >= grid_size) _col = grid_size - 1;
            if (_row < 0) _row = 0;
            if (_row >= grid_size) _row = grid_size - 1;

            var _idx = _row * grid_size + _col;

            // Only place on empty cells
            if (grid_type[_idx] == -1) {
                // Place current tile
                grid_type[_idx] = current_tile_type;
                grid_level[_idx] = current_tile_level;

                // Check for merges (recursive chain)
                do_merge(_idx);

                // Check if enemy died
                check_enemy_dead();

                // Enemy attacks player
                enemy_attack();

                // Check player death
                if (player_hp <= 0) {
                    game_state = 2;
                    api_submit_score(points, undefined);
                } else {
                    // Roll next tile
                    roll_next_tile();

                    // Check grid full
                    if (check_grid_full()) {
                        game_state = 2;
                        api_submit_score(points, undefined);
                    }
                }

                tap_cooldown = 6;
            }
        }
    }
}

// === STATE 2: GAME OVER ===
else if (game_state == 2) {
    if (mouse_check_button_pressed(mb_left)) {
        points = 0;
        reset_game();
        game_state = 1;
    }
}
