
// Decrease move cooldown
if (move_cooldown > 0) move_cooldown--;

// === STATE 0: TITLE SCREEN ===
if (game_state == 0) {
    if (mouse_check_button_pressed(mb_left) || keyboard_check_pressed(vk_space)) {
        game_state = 1;
    }
}

// === STATE 1: PLAYING ===
else if (game_state == 1) {
    var _dir = -1; // -1 = no input

    // Arrow key input
    if (move_cooldown <= 0) {
        if (keyboard_check_pressed(vk_left))  _dir = 0;
        if (keyboard_check_pressed(vk_right)) _dir = 1;
        if (keyboard_check_pressed(vk_up))    _dir = 2;
        if (keyboard_check_pressed(vk_down))  _dir = 3;
    }

    // Swipe input (touch / mouse drag)
    if (mouse_check_button_pressed(mb_left)) {
        touch_active = true;
        touch_sx = device_mouse_x_to_gui(0);
        touch_sy = device_mouse_y_to_gui(0);
    }

    if (touch_active && mouse_check_button_released(mb_left)) {
        touch_active = false;
        var _ex = device_mouse_x_to_gui(0);
        var _ey = device_mouse_y_to_gui(0);
        var _dx = _ex - touch_sx;
        var _dy = _ey - touch_sy;

        // Only register swipe if above threshold
        if (abs(_dx) > swipe_threshold || abs(_dy) > swipe_threshold) {
            if (abs(_dx) > abs(_dy)) {
                // Horizontal swipe
                _dir = (_dx > 0) ? 1 : 0; // right or left
            } else {
                // Vertical swipe
                _dir = (_dy > 0) ? 3 : 2; // down or up
            }
        }
    }

    // Execute move
    if (_dir >= 0 && move_cooldown <= 0) {
        var _earned = slide_and_merge(_dir);
        if (_earned >= 0) {
            // Valid move happened
            points += _earned;
            spawn_atom();
            move_cooldown = 4; // brief cooldown to prevent double-moves

            // Check for game over
            if (!can_move()) {
                game_state = 2;
                api_submit_score(points, undefined);
            }
        }
    }
}

// === STATE 2: GAME OVER ===
else if (game_state == 2) {
    if (mouse_check_button_pressed(mb_left) || keyboard_check_pressed(vk_space)) {
        // Reset and start new game
        reset_game();
        points = 0;
        game_state = 1;
    }
}
