// Move obstacle down (toward the player)
y += fall_speed;

// Update speed from game controller
if (instance_exists(obj_game)) {
    fall_speed = obj_game.game_speed;
}
