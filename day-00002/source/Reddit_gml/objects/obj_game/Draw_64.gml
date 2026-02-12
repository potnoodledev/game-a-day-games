
var _w = window_get_width();
var _h = window_get_height();

draw_set_font(fnt_default);

// Score (top left)
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_yellow);
draw_text_ext_transformed(10, 10, $"Coins: {points}", 20, _w, 2, 2, 0);

// Misses (top right)
draw_set_halign(fa_right);
var _miss_text = "";
for (var _i = 0; _i < max_misses; _i++) {
	if (_i < coins_missed) _miss_text += "X ";
	else _miss_text += "O ";
}
draw_set_colour(c_red);
draw_text_ext_transformed(_w - 10, 10, _miss_text, 20, _w, 2, 2, 0);

// Title (top center)
draw_set_halign(fa_center);
draw_set_colour(c_white);
draw_text_ext_transformed(_w * 0.5, 10, "COIN RAIN", 20, _w, 1.5, 1.5, 0);

// Touch zone indicators
if (game_active && !game_over) {
	draw_set_alpha(0.08);
	draw_set_colour(c_white);
	draw_rectangle(0, _h * 0.3, _w * 0.4, _h, false);
	draw_rectangle(_w * 0.6, _h * 0.3, _w, _h, false);
	draw_set_alpha(1);

	// Arrow hints
	draw_set_colour(c_gray);
	draw_set_halign(fa_center);
	draw_set_valign(fa_bottom);
	draw_text_ext_transformed(_w * 0.2, _h - 10, "<", 0, _w, 3, 3, 0);
	draw_text_ext_transformed(_w * 0.8, _h - 10, ">", 0, _w, 3, 3, 0);
}

// Game over
if (game_over) {
	draw_set_alpha(0.7);
	draw_set_colour(c_black);
	draw_rectangle(0, 0, _w, _h, false);
	draw_set_alpha(1);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	draw_set_colour(c_red);
	draw_text_ext_transformed(_w * 0.5, _h * 0.3, "GAME OVER", 0, _w, 4, 4, 0);

	draw_set_colour(c_yellow);
	draw_text_ext_transformed(_w * 0.5, _h * 0.45, $"Coins: {coins_caught}", 0, _w, 2.5, 2.5, 0);

	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.55, $"Total Score: {points}", 0, _w, 2, 2, 0);

	draw_set_colour(c_lime);
	draw_text_ext_transformed(_w * 0.5, _h * 0.72, "Tap to Play Again", 0, _w, 2, 2, 0);
}
