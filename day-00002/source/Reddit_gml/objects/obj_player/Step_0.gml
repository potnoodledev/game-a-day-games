
var _w = window_get_width();
var _h = window_get_height();

// Keep player at bottom of screen
y = _h - 60;

// Keyboard input
var _input_left = keyboard_check(ord("A")) || keyboard_check(vk_left);
var _input_right = keyboard_check(ord("D")) || keyboard_check(vk_right);
var _input_h = _input_right - _input_left;

// Touch input from obj_game
if (instance_exists(obj_game)) {
	if (obj_game.touch_left) _input_h = -1;
	if (obj_game.touch_right) _input_h = 1;
}

// Move player
x += _input_h * player_speed;

// Clamp to screen bounds
x = clamp(x, 32, _w - 32);
