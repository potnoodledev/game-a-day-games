
// Update screen dimensions
screen_w = window_get_width();
screen_h = window_get_height();

// Position cat at start if in waiting state
if (game_state == 0) {
    if (instance_exists(obj_player)) {
        obj_player.x = screen_w * cat_start_x_frac;
        obj_player.y = screen_h * cat_start_y_frac;
    }
}

// Handle input: keyboard (spacebar/up) OR mouse/touch (tap anywhere)
var _input = keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_up) || mouse_check_button_pressed(mb_left);

if (_input) {
    if (game_state == 0) {
        game_start();
    } else if (game_state == 1) {
        if (instance_exists(obj_player)) {
            obj_player.vy = obj_player.flap_power;
        }
    } else if (game_state == 2) {
        if (death_timer <= 0) {
            game_restart();
        }
    }
}

// Playing state logic
if (game_state == 1) {
    // Spawn pipes
    pipe_timer += 1;
    if (pipe_timer >= pipe_interval) {
        pipe_timer = 0;
        spawn_pipe_pair();
    }

    // Increase difficulty based on score
    var _new_passed = current_score;
    if (_new_passed > pipes_passed) {
        pipes_passed = _new_passed;

        // Shrink gap (harder)
        pipe_gap = max(min_pipe_gap, pipe_gap - gap_shrink_rate);

        // Speed up slightly every 5 pipes
        if (pipes_passed mod 5 == 0) {
            pipe_speed = min(6, pipe_speed + 0.25);
            pipe_interval = max(55, pipe_interval - 3);
        }
    }
}

// Dead state: countdown before restart allowed
if (game_state == 2) {
    death_timer = max(0, death_timer - 1);
}
