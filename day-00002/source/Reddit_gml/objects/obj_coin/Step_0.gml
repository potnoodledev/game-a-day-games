
y += fall_speed;
spin += spin_speed;

// Check if caught by player
if (instance_exists(obj_player)) {
	var _dist = point_distance(x, y, obj_player.x, obj_player.y);
	if (_dist < 48) {
		with (obj_game) {
			points += 1;
			coins_caught += 1;
		}
		instance_destroy();
		exit;
	}
}

// Check if fell off screen
if (y > window_get_height() + 32) {
	with (obj_game) {
		coins_missed += 1;
	}
	instance_destroy();
}
