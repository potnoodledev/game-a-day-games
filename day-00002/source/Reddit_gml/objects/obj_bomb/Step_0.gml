
y += fall_speed;
wobble += wobble_speed;
x += sin(degtorad(wobble)) * 1.5;

// Check if hit player
if (instance_exists(obj_player)) {
	var _dist = point_distance(x, y, obj_player.x, obj_player.y);
	if (_dist < 48) {
		with (obj_game) {
			points = max(0, points - 3);
			coins_missed += 1;
		}
		instance_destroy();
		exit;
	}
}

// Off screen - no penalty for dodging bombs
if (y > window_get_height() + 32) {
	instance_destroy();
}
