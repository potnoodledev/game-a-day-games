
// Move pipe to the left
x -= pipe_speed;

// Destroy if off-screen (well past left edge)
if (x < -200) {
    instance_destroy();
}

// Check if cat passed this pipe (only bottom pipe scores)
if (!is_top && !scored && instance_exists(obj_player)) {
    if (obj_player.x > x + (sprite_width * image_xscale)) {
        scored = true;
        with (obj_game) {
            if (game_state == 1) { // playing
                current_score += 1;
                if (current_score > points) {
                    points = current_score;
                }
            }
        }
    }
}
